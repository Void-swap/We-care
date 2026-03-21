import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:we_care/main.dart';
import 'package:we_care/screens/onboard/verifyOTP.dart';
import 'package:we_care/utils/colors.dart';

class RegisterLoginScreen extends StatefulWidget {
  const RegisterLoginScreen({super.key});

  @override
  State<RegisterLoginScreen> createState() => _RegisterLoginScreenState();
}

class _RegisterLoginScreenState extends State<RegisterLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final supabase = Supabase.instance.client; // 🔥 Supabase client

  bool _isRegisterMode = false;
  final box = GetStorage();
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _authenticate(BuildContext context) async {
    if (_isRegisterMode) {
      // 🔹 REGISTER FLOW

      if (_passwordController.text != _confirmPasswordController.text) {
        _showLottieAnimation(context, 'error');
        await Future.delayed(const Duration(seconds: 3));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match.'),
            backgroundColor: primaryRed,
          ),
        );
        return;
      }

      try {
        // 🔥 SEND OTP & CREATE USER IF NOT EXISTS
        await supabase.auth.signInWithOtp(
          email: _emailController.text.trim(),
          shouldCreateUser: true,
        );

        // Save email + password temporarily (we'll set password after OTP)
        box.write('pendingEmail', _emailController.text.trim());
        box.write('pendingPassword', _passwordController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email. Please verify.'),
            backgroundColor: Colors.green,
          ),
        );

        // 👉 GO TO OTP SCREEN
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerifyOtpScreen(email: _emailController.text.trim()),
          ),
        );
      } on AuthException catch (e) {
        _showLottieAnimation(context, 'error');

        String errorMessage;
        if (e.message.contains('already registered')) {
          errorMessage = "User already exists.";
        } else {
          errorMessage = "Failed to send OTP: ${e.message}";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } catch (e) {
        _showLottieAnimation(context, 'error');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // 🔹 LOGIN FLOW

      try {
        // 🔥 SUPABASE LOGIN
        final res = await supabase.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        final user = res.user;

        if (user != null) {
          _showLottieAnimation(context, 'success');
          await Future.delayed(const Duration(seconds: 3));

          String uid = user.id;

          // 🔥 FETCH USER FROM SUPABASE DB
          final userData = await supabase
              .from('users')
              .select()
              .eq('id', uid)
              .maybeSingle();

          if (userData != null) {
            box.write('userData', userData);
            Navigator.pushReplacementNamed(context, "/home");
          } else {
            _showLottieAnimation(context, 'error');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User does not exist in database.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } on AuthException catch (e) {
        _showLottieAnimation(context, 'error');

        String errorMessage;
        if (e.message.contains('Invalid login credentials')) {
          errorMessage = "Incorrect email or password.";
        } else if (e.message.contains('Email not confirmed')) {
          errorMessage = "Please verify your email before logging in.";
        } else if (e.message.contains('Network')) {
          errorMessage =
              "No internet connection. Please check your connection.";
        } else {
          errorMessage = "Failed to sign in: ${e.message}";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      } catch (e) {
        _showLottieAnimation(context, 'error');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign in: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // void _authenticate(BuildContext context) async {
  //   if (_isRegisterMode) {
  //     if (_passwordController.text != _confirmPasswordController.text) {
  //       _showLottieAnimation(context, 'error');

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Passwords do not match.'),
  //           backgroundColor: primaryRed,
  //         ),
  //       );
  //       return;
  //     }

  //     try {
  //       // _showLottieAnimation(context, 'confetti');
  //       print(_emailController.text);
  //       UserCredential userCredential = await _auth
  //           .createUserWithEmailAndPassword(
  //             email: _emailController.text,
  //             password: _passwordController.text,
  //           );

  //       final User? user = userCredential.user;
  //       if (user != null) {
  //         String email = user.email ?? '';

  //         // Check if the user exists in Firestore
  //         final userDoc = FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(email);
  //         final userSnapshot = await userDoc.get();
  //         if (userSnapshot.exists) {
  //           // User exists
  //           final userData = userSnapshot.data();
  //           if (userData != null) {
  //             _showLottieAnimation(context, 'tickAnimation');

  //             box.write('userData', userData);
  //             Navigator.pushReplacementNamed(context, "/home");
  //           }
  //         } else {
  //           box.write('userEmail', email);
  //           print('User registered: ${userCredential.user?.email}');
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //               content: Text('Registered successfully!'),
  //               backgroundColor: Colors.green,
  //             ),
  //           );
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(
  //               builder: (context) => RoleSelectionScreen(email: email),
  //             ),
  //           );
  //         }
  //       }
  //     } catch (e) {
  //       print(_emailController.text);

  //       _showLottieAnimation(context, 'error');

  //       print('Failed to register: $e');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to register: ${e.toString()}'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } else {
  //     // Handle login
  //     try {
  //       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
  //         email: _emailController.text,
  //         password: _passwordController.text,
  //       );

  //       final User? user = userCredential.user;
  //       if (user != null) {
  //         _showLottieAnimation(context, 'tickAnimation');

  //         String uid = user.uid ?? '';

  //         final userDoc = FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(uid);
  //         final userSnapshot = await userDoc.get();
  //         if (userSnapshot.exists) {
  //           final userData = userSnapshot.data();
  //           if (userData != null) {
  //             box.write('userData', userData);
  //             Navigator.pushReplacementNamed(context, "/home");
  //           }
  //         } else {
  //           _showLottieAnimation(context, 'error');

  //           print('User does not exist in Firestore');
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(
  //               content: Text('User does not exist.'),
  //               backgroundColor: Colors.red,
  //             ),
  //           );
  //         }
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       _showLottieAnimation(context, 'error');

  //       String errorMessage;
  //       if (e.code == 'user-not-found') {
  //         errorMessage = "User does not exist.";
  //       } else if (e.code == 'wrong-password') {
  //         errorMessage = "Incorrect password.";
  //       } else if (e.code == 'network-request-failed') {
  //         errorMessage =
  //             "No internet connection. Please check your connection.";
  //       } else {
  //         errorMessage = "Failed to sign in: ${e.message}";
  //       }
  //       print('Failed to sign in: $e');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
  //       );
  //     } catch (e) {
  //       _showLottieAnimation(context, 'error');

  //       print('Failed to sign in: $e');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to sign in: ${e.toString()}'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  Future<void> _showLottieAnimation(
    BuildContext context,
    String animationType,
  ) async {
    showDialog(
      barrierColor: Colors.transparent,
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Lottie.asset(
              'assets/lottie/$animationType.json',
              width: 250,
              height: 250,
              repeat: false,
            ),
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 3));

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Text(
                  _isRegisterMode ? "Register to Spot It" : "Login to Spot It",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isRegisterMode
                      ? "Welcome please enter your detail"
                      : "Welcome back please enter your detail",
                  style: const TextStyle(color: primaryBlack),
                ),
                const SizedBox(height: 35),
                CustomTextField(
                  hintText: 'Email',
                  icon: IconlyBroken.message,
                  controller: _emailController,
                  obscureText: false,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: 'Password',
                  icon: IconlyBroken.lock,
                  controller: _passwordController,
                  obscureText: !_isConfirmPasswordVisible,

                  toggleVisibility: _toggleConfirmPasswordVisibility,
                ),
                if (_isRegisterMode) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    hintText: "Confirm Password",
                    icon: IconlyBroken.lock,
                    controller: _confirmPasswordController,
                    //  obscureText: true,
                    obscureText: !_isPasswordVisible,
                    toggleVisibility: _togglePasswordVisibility,
                  ),
                ],
                if (!_isRegisterMode) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot password?",
                        style: TextStyle(
                          // fontSize: 26,
                          // fontWeight: FontWeight.w500,
                          color: primaryRed,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _authenticate(context),

                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (_) => const HomePage()),
                  // );
                  child: Text(
                    _isRegisterMode ? "Create account" : "Sign in",
                    style: const TextStyle(color: primaryWhite),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegisterMode
                          ? "Already have an account?"
                          : "New to Spot It?",
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isRegisterMode = !_isRegisterMode;
                        });
                      },
                      child: Text(
                        _isRegisterMode ? " Sign in" : " Create account",
                        style: const TextStyle(
                          color: darkGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                buildSocialButton("Continue with Google", Icons.g_mobiledata),
                const SizedBox(height: 10),
                buildSocialButton("Continue with Apple", Icons.apple),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSocialButton(String text, IconData icon) {
    return OutlinedButton.icon(
      icon: Icon(icon, color: Colors.black),
      label: Text(text, style: const TextStyle(color: Colors.black)),
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        side: const BorderSide(color: Colors.black12),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {},
    );
  }
}
