import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:svg_flutter/svg.dart';
import 'package:we_care/screens/first.dart';
import 'package:we_care/screens/issue.dart';
import 'package:we_care/screens/signIn.dart';
import 'package:we_care/screens/splash.dart';
import 'package:we_care/utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    //for APP initialize in main & web in future
    options: const FirebaseOptions(
      apiKey: "AIzaSyBG4zVqMJ7sd6ZvGKkryAdf2be0mdYkGh4",
      projectId: "signin-signup-60421",
      messagingSenderId: "100706700423",
      appId: "1:100706700423:web:5b454d27f516f5836d7c22",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user != null) {
              return const SplashScreen(nextPage: HomePage());
            } else {
              return const SplashScreen(nextPage: SignInScreen());
            }
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
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

  final List<Widget> _pages = [InitialScreen(), IssueScreen(), ProfilePage()];

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
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: const Row(
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
            Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: const Text(
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

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryBlack),
        hintText: hintText,
        // filled: true,
        // fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 10,
        ),
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
                    MaterialPageRoute(builder: (context) => SignInScreen()),
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
