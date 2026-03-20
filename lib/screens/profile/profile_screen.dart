import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:we_care/utils/colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final user = box.read('userData') ?? {};

    final name = user['name'] ?? "User";
    final role = user['role'] ?? "Citizen";
    final email = user['email'] ?? "";
    final address = user['address'] ?? "Not set";
    final contact = user['contacts'] ?? "";
    final verification = user['is_verified'] ?? "Not Applied";
    final interests = List<String>.from(user['interests'] ?? []);
    final issues = List.from(user['issue_created'] ?? []);
    final resolved = List.from(user['issue_resolved'] ?? []);
    final badges = List.from(user['badges'] ?? []);

    return Scaffold(
      backgroundColor: primaryWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: darkGreen)),
        actions: const [Icon(IconlyLight.setting, color: darkGreen)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey[300],
                    image: user['profile_pic'] != ""
                        ? DecorationImage(
                            image: NetworkImage(user['profile_pic']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user['profile_pic'] == ""
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            color: darkGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.5),

                            borderRadius: const BorderRadius.all(
                              Radius.circular(5),
                            ),
                            border: Border.all(width: 1, color: primaryGreen),
                          ),

                          child: Text(
                            role,
                            style: const TextStyle(
                              color: darkGreen,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Text(
                    //   "Verification: $verification",
                    //   style: const TextStyle(color: Colors.red),
                    // ),
                    // const SizedBox(height: 6),
                    const Text(
                      "“Committed to a better neighborhood.”",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: GestureDetector(
                    onTap: () {
                      if (verification == "Not Applied") {
                        Navigator.pushNamed(context, '/verifyMe');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Already Applied')),
                        );
                      }
                    },
                    child: verification == "Verified"
                        ? Image.asset("assets/images/verified.png", height: 28)
                        : Image.asset(
                            "assets/images/notVerified.png",
                            height: 28,
                          ),
                  ),
                ),
              ],
            ),

            // const SizedBox(height: 16),

            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: const Color(0xFF0E3B2E),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            //   onPressed: () {
            //     Navigator.pushNamed(context, "/editProfile");
            //   },
            //   child: const Text(
            //     "Edit Profile",
            //     style: TextStyle(color: primaryWhite),
            //   ),
            // ),
            const SizedBox(height: 20),

            // ================= IDENTITY =================
            _card(
              title: "Identity & Location",
              child: Column(
                children: [
                  _rowItem(IconlyBold.location, "Address", address),
                  _rowItem(IconlyBold.message, "Email", email),
                  _rowItem(IconlyBold.call, "Contact", contact),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= STATS =================
            _card(
              title: "Impact Metrics",
              child: Row(
                children: [
                  _statBox(issues.length.toString(), "Issues Reported"),
                  const SizedBox(width: 12),
                  _statBox(
                    resolved.isEmpty ? "0%" : "${resolved.length}",
                    // : "${((resolved.length / (issues.length == 0 ? 1 : issues.length)) * 100).toInt()}%",
                    "Resolution Rate",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= BADGES =================
            _card(
              title: "Achievements",
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _achievementBlock(
                          title: "Member",
                          subtitle: "Since Day One",
                          icon: IconlyBold.star,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _achievementBlock(
                          title: (user['is_verified'] ?? "") == "Verified"
                              ? "Verified"
                              : "Pending",
                          subtitle: "Verified Trusted Citizen",
                          icon: (user['is_verified'] ?? "") == "Verified"
                              ? IconlyBold.tick_square
                              : IconlyLight.shield_fail,
                          color: darkGreen,
                        ),
                      ),
                    ],
                  ),

                  // const SizedBox(height: 16),

                  // 🔥 BADGES
                  // if (badges.isEmpty) const Text("No achievements yet"),
                  // else
                  //   Wrap(
                  //     spacing: 10,
                  //     runSpacing: 10,
                  //     children: badges
                  //         .map((b) => _miniBadge(b.toString()))
                  //         .toList(),
                  //   ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ================= INTERESTS =================
            _card(
              title: "CORE INTERESTS",
              child: Wrap(
                spacing: 8,
                children: interests
                    .map(
                      (i) => Chip(
                        label: Text(i),
                        backgroundColor: Colors.grey[300],
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ================= VERIFICATION =================
            if (verification == "Not Applied")
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ACTION REQUIRED",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Identity verification is required to participate in official actions.",
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text("APPLY FOR VERIFICATION"),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // ================= ACTIVITY =================
            _card(
              title: "ACTIVITY FEED",
              child: Column(
                children: [
                  ...issues.map((e) => _activity("Reported issue")),
                  ...resolved.map((e) => _activity("Resolved issue")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _rowItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color.fromRGBO(158, 158, 158, 0.8),
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: primaryBlack),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        height: 110,
        width: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkGreen,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activity(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 3, height: 30, color: Colors.black),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

Widget _achievementBlock({
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
}) {
  return Container(
    height: 110,
    width: 110,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // 🔥 ICON TOP RIGHT (modern feel)
        Icon(icon, color: Colors.white, size: 26),
        SizedBox(height: 5),
        // 🔥 TEXT BOTTOM LEFT
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}
