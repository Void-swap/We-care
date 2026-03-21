// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:svg_flutter/svg.dart';
import 'package:we_care/screens/first.dart';
import 'package:we_care/screens/issue/issue_screen.dart';
import 'package:we_care/screens/onboard/register_login.dart';
import 'package:we_care/screens/profile/edit_profile.dart';
import 'package:we_care/screens/profile/profile_screen.dart';
import 'package:we_care/screens/profile/verify_me.dart';
import 'package:we_care/screens/splash.dart';
import 'package:we_care/utils/colors.dart';
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
        '/analytics': (context) => const VerifyMe(),
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

  final List<Widget> _pages = [
    const InitialScreen(),
    const IssueScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        items: [
          _buildNavItem(IconlyBroken.home, IconlyBold.home, 'Home', 0),
          _buildNavItem(IconlyBroken.search, IconlyBold.search, 'Search', 1),
          _buildNavItem(
            IconlyBroken.profile,
            IconlyBold.profile,
            'Settings',
            2,
          ),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        // selectedItemColor: Colors.blue,
        // unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData broken,
    IconData bold,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      backgroundColor: Colors.white,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? bold : broken, size: 30, color: darkGreen),

          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 15),
              height: 5,
              width: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: darkGreen,
              ),
            ),
        ],
      ),
      label: "",
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
