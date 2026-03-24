// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:spot_it/screens/admin/profile_verification.dart';
import 'package:spot_it/screens/issue/create_issue.dart';
import 'package:svg_flutter/svg.dart';
import 'package:spot_it/screens/admin/analytics_dashboard.dart';
import 'package:spot_it/screens/first.dart';
import 'package:spot_it/screens/issue/issue_screen.dart';
import 'package:spot_it/screens/onboard/register_login.dart';
import 'package:spot_it/screens/profile/edit_profile.dart';
import 'package:spot_it/screens/profile/profile_screen.dart';
import 'package:spot_it/screens/profile/verify_me.dart';
import 'package:spot_it/screens/splash.dart';
import 'package:spot_it/utils/colors.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  await Supabase.initialize(
    url: 'https://poelrmrksvtixrusvjuo.supabase.co',
    anonKey: 'sb_publishable_YN4mrKoziel0Qyp9Cj6_jQ_B76-_6xs',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/registerOrLogin': (context) => const RegisterLoginScreen(),
        '/home': (context) => const HomePage(),
        '/editProfile': (context) => const EditProfileScreen(),
        '/verifyMe': (context) => const VerifyMe(),
        '/adminVerify': (context) => const AdminVerificationScreen(),

        '/analytics': (context) => const AdminDashboardScreen(),
      },
      theme: ThemeData(
        primaryColor: darkGreen,
        secondaryHeaderColor: const Color(0xFF9262BF),
        hintColor: const Color(0xFF20706B),
        scaffoldBackgroundColor: primaryWhite,
        cardColor: const Color(0xFFFFFFFF),
        // inputDecorationTheme: InputDecorationTheme(
        //   fillColor: const Color(0xFFf2f2f2),
        //   filled: true,
        //   enabledBorder: OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(8),
        //     borderSide: const BorderSide(color: primaryBlack, width: 0.9),
        //   ),
        //   focusedBorder: OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(8),
        //     borderSide: const BorderSide(color: darkGreen, width: 1.5),
        //   ),
        //   labelStyle: const TextStyle(
        //     fontSize: 14,
        //     fontWeight: FontWeight.w400,
        //     color: primaryBlack,
        //   ),
        //   prefixIconConstraints: const BoxConstraints(
        //     minWidth: 40,
        //     minHeight: 40,
        //   ),
        //   suffixIconColor: primaryBlack,
        // ),
        // appBarTheme: const AppBarTheme(
        //   elevation: 0,
        //   backgroundColor: primaryWhite,
        //   titleTextStyle: TextStyle(
        //     fontWeight: FontWeight.w700,
        //     color: primaryBlack,
        //     fontSize: 24,
        //     fontFamily: "Poppins",
        //   ),
        // ),
        // snackBarTheme: const SnackBarThemeData(
        //   backgroundColor: darkGreen,
        //   contentTextStyle: TextStyle(color: primaryWhite),
        //   actionTextColor: primaryBlack,
        //   behavior: SnackBarBehavior.floating,
        //   insetPadding: EdgeInsets.all(8.0),
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.all(Radius.circular(8)),
        //   ),
        // ),
        // buttonTheme: const ButtonThemeData(
        //   buttonColor: darkGreen,
        //   textTheme: ButtonTextTheme.primary,
        // ),
        // fontFamily: 'Poppins',
        // colorScheme: const ColorScheme(
        //   primary: darkGreen,
        //   secondary: Color(0xFF9262BF),
        //   surface: Color(0xFFFFFFFF),
        //   background: Color(0xFFFFFFFF),
        //   error: Colors.red,
        //   onPrimary: Colors.white,
        //   onSecondary: Colors.white,
        //   onSurface: Color(0xFF121212),
        //   onBackground: Color(0xFF121212),
        //   onError: Colors.white,
        //   brightness: Brightness.light,
        // ).copyWith(background: Color(0xFFFFFFFF)),
        // textTheme: const TextTheme(
        //   bodyMedium: TextStyle(color: primaryBlack, fontSize: 18),
        //   bodySmall: TextStyle(
        //     color: primaryBlack,
        //     fontSize: 14,
        //     fontWeight: FontWeight.w400,
        //   ),
        //),
      ),

      // home: StreamBuilder<User?>(
      //   stream: FirebaseAuth.instance.authStateChanges(),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.active) {
      //       final user = snapshot.data;
      //       if (user != null) {
      //         return const SplashScreen(nextPage: HomePage());
      //       } else {
      //         return const SplashScreen(nextPage: RegisterLoginScreen());
      //       }
      //     } else {
      //       return const CircularProgressIndicator();
      //     }
      //   },
      // ),
      // initialRoute: '/',
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [const IssueScreen(), const ProfileScreen()];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddPressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 0,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? darkGreen.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(isSelected ? activeIcon : icon, color: darkGreen, size: 26),

            // 🔥 TEXT APPEARS ONLY WHEN ACTIVE
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isSelected ? 1 : 0,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      // 🔥 FLOATING + BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        backgroundColor: darkGreen,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔥 CUSTOM NAV BAR
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: IconlyBroken.search,
              activeIcon: IconlyBold.search,
              label: "Issues",
            ),

            const SizedBox(width: 50), // space for FAB

            _buildNavItem(
              index: 1,
              icon: IconlyBroken.profile,
              activeIcon: IconlyBold.profile,
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            const Padding(
              padding: EdgeInsets.only(left: 25, right: 25),
              child: Row(
                children: [
                  Text(
                    "Fix in",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                  Text(
                    " one blink",
                    style: TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            const Padding(
              padding: EdgeInsets.only(left: 25, right: 25),
              child: Text(
                "Navigating crisis with confidence",
                style: TextStyle(color: Colors.black, fontSize: 18),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Image.asset(
                "assets/images/card.png",
                width: 500,
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;
  final VoidCallback? toggleVisibility;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    required this.controller,
    this.toggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryBlack),
        hintText: hintText,
        // filled: true,
        // fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 10,
        ),
        suffixIcon: (hintText == "Confirm Password" || hintText == "Password")
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: obscureText ? primaryGrey : darkGreen,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryGrey),
          borderRadius: BorderRadius.circular(7),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryBlack),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile",
          style: TextStyle(
            // fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F7F8B),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 25, right: 25),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(color: Colors.white),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                "assets/images/profile.png",
                // width: 300,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const RegisterLoginScreen(),
                    ),
                  );
                },
                child: Image.asset("assets/images/logout.png"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
