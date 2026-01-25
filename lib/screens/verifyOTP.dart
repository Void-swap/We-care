import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:we_care/screens/form.dart';
import 'package:we_care/utils/colors.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final supabase = Supabase.instance.client;

  // 🔥 Supabase is sending 8-digit OTP in your project
  final int otpLength = 8;

  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  bool _loading = false;
  bool _resending = false;
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(otpLength, (_) => FocusNode());

    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_secondsLeft == 0) return false;
      if (mounted) setState(() => _secondsLeft--);
      return true;
    });
  }

  String get _otpCode =>
      _controllers.map((controller) => controller.text).join();

  // 🔹 VERIFY OTP
  Future<void> _verifyOtp() async {
    if (_otpCode.length != otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter the complete 8-digit code"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await supabase.auth.verifyOTP(
        type: OtpType.email,
        token: _otpCode,
        email: widget.email,
      );

      final user = res.user;

      if (user != null) {
        // 🔥 Set password after verification
        final box = GetStorage();
        final pendingPassword = box.read('pendingPassword');

        if (pendingPassword != null) {
          await supabase.auth.updateUser(
            UserAttributes(password: pendingPassword),
          );

          box.remove('pendingPassword');
          box.remove('pendingEmail');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        // 👉 Go to role selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(email: widget.email),
          ),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid code: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🔹 RESEND OTP
  Future<void> _resendOtp() async {
    setState(() => _resending = true);

    try {
      await supabase.auth.signInWithOtp(
        email: widget.email,
        shouldCreateUser: false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new code has been sent to your email'),
          backgroundColor: Colors.green,
        ),
      );

      _startTimer();
    } finally {
      setState(() => _resending = false);
    }
  }

  void _showLottieAnimation(BuildContext context, String animationType) {
    showDialog(
      barrierColor: Colors.transparent,
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Lottie.asset(
              'assets/lottie/$animationType.json',
              width: 300,
              height: 300,
              repeat: false,
              onLoaded: (composition) {
                _showLottieAnimation(context, 'confetti');

                // Use the composition duration to delay closing
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context).pop();
                });
              },
            ),
          ),
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // 🔹 BRAND
              const Text(
                "Spot It",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: darkGreen,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Verify your email",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: primaryBlack,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Enter the 8-digit code we sent to",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),

              Text(
                widget.email,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: primaryBlack,
                ),
              ),

              const SizedBox(height: 40),

              // 🔹 OTP GRID (WRAPS NICELY ON SMALL SCREENS)
              Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: List.generate(otpLength, (index) {
                    return _OtpBox(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      autoFocus: index == 0,
                      onChanged: (value) {
                        if (value.isNotEmpty && index < otpLength - 1) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    );
                  }),
                ),
              ),

              const SizedBox(height: 40),

              // 🔹 VERIFY BUTTON
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _loading ? null : _verifyOtp,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Verify & continue",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),

              const SizedBox(height: 24),

              // 🔹 RESEND
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        "Resend code in $_secondsLeft seconds",
                        style: const TextStyle(color: Colors.black45),
                      )
                    : TextButton(
                        onPressed: _resending ? null : _resendOtp,
                        child: Text(
                          _resending ? "Sending..." : "Resend code",
                          style: const TextStyle(
                            color: darkGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔹 SINGLE OTP BOX
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autoFocus;
  final Function(String) onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.autoFocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 54,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autoFocus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.grey.shade100,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black26),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: darkGreen, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
