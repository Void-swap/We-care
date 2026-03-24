import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:spot_it/utils/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _navigateBasedOnUser();

    // Navigate to the next page after 3 seconds
    // Timer(Duration(seconds: 3), () {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(builder: (context) => widget.nextPage),
    //   );
    // });
  }

  Future<void> _navigateBasedOnUser() async {
    await Future.delayed(const Duration(seconds: 3));
    final user = box.read('userData');

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/registerOrLogin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   automaticallyImplyLeading: false,
      //   title: const Text(
      //     "Profile",
      //     style: TextStyle(
      //       // fontSize: 16,
      //       fontWeight: FontWeight.w600,
      //       color: Color(0xFF1F7F8B),
      //     ),
      //   ),
      // ),
      body: Container(
        padding: const EdgeInsets.only(left: 25, right: 25),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(254, 254, 254, 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/logo/logo.png",
              // width: 150,
              // height: 150,
              // fit: BoxFit.fill,
            ),
            const SizedBox(height: 20),

            // const Text(
            //   'WeCare',
            //   style: TextStyle(
            //     color: darkGreen,
            //     fontSize: 30,
            //     fontWeight: FontWeight.w500,
            //     // letterSpacing: 3,
            //   ),
            //   textAlign: TextAlign.center,
            // ),
            const SizedBox(height: 5),
            const Text(
              'Navigating crisis with confidence',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            // const SizedBox(
            //   height: 10,
            // ),
            // GestureDetector(
            //   onTap: () {
            //     Navigator.of(context).pushReplacement(
            //       MaterialPageRoute(builder: (context) => SignIn()),
            //     );
            //   },
            //   child: Image.asset("assets/images/logout.png"),
            // ),
          ],
        ),
      ),
    );
  }
}
