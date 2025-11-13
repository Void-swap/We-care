import 'package:flutter/material.dart';
import 'package:we_care/utils/colors.dart';

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          "Home",
          style: TextStyle(
            // fontSize: 16,
            fontWeight: FontWeight.w500,
            color: darkGreen,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Image.asset(
                "assets/images/card.png",
                width: 500,
                fit: BoxFit.fill,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "How to Report an Issue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            const ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text("Locate the Issue"),
              subtitle: Text("Find the exact spot on the map."),
            ),
            const ListTile(
              leading: Icon(Icons.camera_alt_outlined),
              title: Text("Capture a Photo"),
              subtitle: Text("Take a picture for clarity."),
            ),
            const ListTile(
              leading: Icon(Icons.description_outlined),
              title: Text("Describe the Problem"),
              subtitle: Text("Share your thoughts and details."),
            ),

            const SizedBox(height: 30),
            const Text(
              "Your Impact Matters",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const ListTile(
              leading: Icon(Icons.verified, color: Colors.green),
              title: Text("300+ Issues Resolved"),
              subtitle: Text("Together we are making our city safer."),
            ),
            const ListTile(
              leading: Icon(Icons.people, color: Colors.blue),
              title: Text("Join 2,000+ Engaged Citizens"),
              subtitle: Text("Be part of a movement for a better community."),
            ),
          ],
        ),
      ),
    );
  }
}
