import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spot_it/main.dart';
import 'package:spot_it/screens/issue/issue_detail.dart';
import 'package:spot_it/screens/issue/create_issue.dart';
import 'package:spot_it/services/services.dart';
import 'package:spot_it/utils/colors.dart';

//////////////////////////////////////////////////////////
// STATUS CHIP
//////////////////////////////////////////////////////////
class StatusChip extends StatelessWidget {
  final Map<String, dynamic> issue;
  final SupabaseClient supabase;
  final Function refresh;

  const StatusChip({
    super.key,
    required this.issue,
    required this.supabase,
    required this.refresh,
  });

  bool canVerify(Map issue, Map userData) {
    return issue['status'] == "Resolved" &&
        userData['role'] == "Field Engineer";
  }

  bool canAssign(Map issue, Map userData) {
    try {
      if (issue['status'] != "Pending") return false;
      if (userData['role'] != "NGO") return false;

      final createdAt = DateTime.parse(issue['created_at']);
      return DateTime.now().difference(createdAt).inDays >= 7;
    } catch (_) {
      return false;
    }
  }

  bool canResolve(Map issue, Map userData) {
    try {
      if (issue['status'] != "Assigned") return false;

      final assignedName = issue['assigned_to']?['id'];
      final currentUserName = userData['name'];

      return assignedName != null && assignedName == currentUserName;
    } catch (_) {
      return false;
    }
  }

  // bool canSetResolve(Map issue, Map userData) {
  //   return issue['status'] == "Assigned" &&
  // }

  Color getColor(String status) {
    switch (status) {
      case "Assigned":
        return Colors.blue.shade400;
      case "Resolved":
        return Colors.orange.shade400;
      case "Verified":
        return Colors.green.shade400;
      default:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final userData = box.read('userData') ?? {};
    final userName = userData['name'] ?? "Unknown";
    final role = userData['role'] ?? "";

    final status = issue['status'] ?? "Pending";
    final eligibleAssign = canAssign(issue, userData);
    final eligibleResolve = canResolve(issue, userData);

    final verify = canVerify(issue, userData);
    return InkWell(
      onTap: () {
        print("Assign: $eligibleAssign");
        print("Resolve: $eligibleResolve");
        print("Verify: $verify");
        print("Status: ${issue['status']}");
        print("Role: ${userData['role']}");
        if (eligibleAssign) {
          showDialog(
            context: context,
            builder: (_) => ActionDialog(
              image: "svg/woman.svg",
              title: "Take ownership?",
              subtitle:
                  "This issue has been pending.\nStart working on it now.",

              secondaryText: "Not now",
              onSecondary: () => Navigator.pop(context),

              primaryText: "Assign me",
              onPrimary: () async {
                Navigator.pop(context);

                final user = supabase.auth.currentUser;

                await supabase
                    .from('issues')
                    .update({
                      'status': 'Assigned',
                      'assigned_to': {
                        'type': 'NGO',
                        'id': userName,
                        'user_id': user?.id,
                        'self_assigned': true,
                        'assigned_at': DateTime.now().toIso8601String(),
                      },
                    })
                    .eq('id', issue['id']);

                refresh();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You're now assigned ✅")),
                );
              },
            ),
            // );
            // showDialog(
            //   context: context,
            //   builder: (_) => AlertDialog(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(16),
            //     ),
            //     title: const Text(
            //       "Take ownership of this issue?",
            //       style: TextStyle(fontWeight: FontWeight.w600),
            //     ),
            //     content: const Text(
            //       "This issue has been pending for a while.\n"
            //       "Assign it to yourself and start working on it.",
            //     ),
            //     actions: [
            //       TextButton(
            //         onPressed: () => Navigator.pop(context),
            //         child: const Text("Not now"),
            //       ),
            //       ElevatedButton(
            //         onPressed: () async {
            //           Navigator.pop(context);

            //           final user = supabase.auth.currentUser;

            //           await supabase
            //               .from('issues')
            //               .update({
            //                 'status': 'Assigned',
            //                 'assigned_to': {
            //                   'type': 'NGO',
            //                   'id': userName,
            //                   'user_id': user?.id,
            //                   'self_assigned': true,
            //                   'assigned_at': DateTime.now().toIso8601String(),
            //                 },
            //               })
            //               .eq('id', issue['id']);

            //           refresh();

            //           ScaffoldMessenger.of(context).showSnackBar(
            //             const SnackBar(content: Text("You're now assigned ✅")),
            //           );
            //         },
            //         child: const Text("Assign to me"),
            //       ),
            //     ],
            //   ),
          );
        }
        // ================= RESOLVE =================
        else if (eligibleResolve) {
          showDialog(
            context: context,
            builder: (_) => ActionDialog(
              image: "svg/checklist.svg",
              title: "Mark this issue as resolved?",

              subtitle: "Are you sure you want to mark and send for auditing",
              secondaryText: "Not yet",
              onSecondary: () => Navigator.pop(context),

              primaryText: "Mark resolved",
              onPrimary: () async {
                Navigator.pop(context);

                final user = supabase.auth.currentUser;

                await supabase
                    .from('issues')
                    .update({
                      'status': 'Resolved',
                      'follow_up': {
                        'resolved_by': userName,
                        'resolver_role': 'NGO',
                        'after_image': '',
                        'description': '',
                        'verified': false,
                      },
                    })
                    .eq('id', issue['id']);

                refresh();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Marked as resolved 🚀")),
                );
              },
            ),
          );
          // showDialog(
          //   context: context,
          //   builder: (_) => AlertDialog(
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(16),
          //     ),
          //     title: const Text(
          //       "Mark this issue as resolved?",
          //       style: TextStyle(fontWeight: FontWeight.w600),
          //     ),
          //     content: const Text(
          //       "Are you sure you want to mark this issue as resolved?\n\n"
          //       "It will be sent for verification and auditing before final closure.",
          //     ),
          //     actions: [
          //       TextButton(
          //         onPressed: () => Navigator.pop(context),
          //         child: const Text("Not yet"),
          //       ),
          //       ElevatedButton(
          //         onPressed: () async {
          //           Navigator.pop(context);

          //           final user = supabase.auth.currentUser;

          //           await supabase
          //               .from('issues')
          //               .update({
          //                 'status': 'Resolved',
          //                 'follow_up': {
          //                   'resolved_by': userName,
          //                   'resolver_role': 'NGO',
          //                   'after_image': '',
          //                   'description': '',
          //                   'verified': false,
          //                 },
          //               })
          //               .eq('id', issue['id']);

          //           refresh();

          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text("Marked as resolved 🚀")),
          //           );
          //         },
          //         child: const Text("Mark as resolved"),
          //       ),
          //     ],
          //   ),
          // );
        } else if (verify)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerificationFormScreen(
                issue: issue,
                supabase: supabase,
                userName: userName,
                role: role,
                refresh: refresh,
              ),
            ),
          );
      },

      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all(width: 1, color: getColor(status)),

          color: getColor(status).withOpacity(0.5),
        ),
        child: Text(
          verify ? "Verify" : status,
          style: const TextStyle(color: primaryWhite, fontSize: 12),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////
// VERIFICATION FORM SCREEN
//////////////////////////////////////////////////////////
class VerificationFormScreen extends StatefulWidget {
  final Map<String, dynamic> issue;
  final SupabaseClient supabase;
  final String userName;
  final String role;
  final Function refresh;

  const VerificationFormScreen({
    super.key,
    required this.issue,
    required this.supabase,
    required this.userName,
    required this.role,
    required this.refresh,
  });

  @override
  State<VerificationFormScreen> createState() => _VerificationFormScreenState();
}

class _VerificationFormScreenState extends State<VerificationFormScreen> {
  final TextEditingController descController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  XFile? image;
  bool loading = false;

  // 📸 CAMERA ONLY
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null && mounted) {
      setState(() => image = picked);
    }
  }

  // 🚀 SUBMIT
  Future<void> submit() async {
    if (image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Capture after image")));
      return;
    }

    setState(() => loading = true);

    try {
      final issueId = widget.issue['id'];
      final fileName =
          "after_$issueId-${DateTime.now().millisecondsSinceEpoch}";
      final path = 'after/$fileName';

      // ✅ upload
      if (kIsWeb) {
        final bytes = await image!.readAsBytes();
        await widget.supabase.storage.from('issues').uploadBinary(path, bytes);
      } else {
        await widget.supabase.storage
            .from('issues')
            .upload(path, File(image!.path));
      }

      final imageUrl = widget.supabase.storage
          .from('issues')
          .getPublicUrl(path);

      // ✅ update db
      await widget.supabase
          .from('issues')
          .update({
            'status': 'Verified',
            'follow_up': {
              'resolved_by': widget.userName,
              'resolver_role': widget.role,
              'after_image': imageUrl,
              'description': descController.text,
              'verified': true,
            },
          })
          .eq('id', issueId);

      widget.refresh();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Verification submitted ✅")));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // 🎨 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Issue"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ================= IMAGE =================
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.shade200,
              ),
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: kIsWeb
                          ? Image.network(image!.path, fit: BoxFit.cover)
                          : Image.file(File(image!.path), fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt, size: 40),
                        SizedBox(height: 8),
                        Text("Capture After Image"),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // ================= DESCRIPTION =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Describe the work done...",
                border: InputBorder.none,
                prefixIcon: Icon(IconlyLight.document),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ================= INFO CARD =================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(IconlyLight.profile),
                    const SizedBox(width: 8),
                    Text("Resolved by: ${widget.userName}"),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(IconlyLight.work),
                    const SizedBox(width: 8),
                    Text("Role: ${widget.role}"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ================= SUBMIT =================
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: loading ? null : submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Submit Verification",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
// LIKE BUTTON (FIXED)
//////////////////////////////////////////////////////////

class LikeButton extends StatefulWidget {
  final Map<String, dynamic> issue;
  final SupabaseClient supabase;
  final Function refresh;

  const LikeButton({
    super.key,
    required this.issue,
    required this.supabase,
    required this.refresh,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late List votes;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();

    final user = widget.supabase.auth.currentUser;
    votes = List.from(widget.issue['up_vote'] ?? []);

    isLiked = votes.any((v) {
      if (v is Map) return v['user'] == user?.email;
      if (v is String) return v == user?.id;
      return false;
    });
  }

  Future<void> _toggleLike() async {
    final user = widget.supabase.auth.currentUser;

    List updated = [];

    // normalize votes
    for (var v in votes) {
      if (v is Map) {
        updated.add(v);
      } else if (v is String) {
        updated.add({
          "user": v,
          "created_at": DateTime.now().toIso8601String(),
        });
      }
    }

    // toggle logic
    if (isLiked) {
      updated.removeWhere((v) => v['user'] == user?.email);
    } else {
      updated.add({
        "user": user?.email,
        "created_at": DateTime.now().toIso8601String(),
      });
    }

    // 🔥 INSTANT UI UPDATE (this was missing)
    setState(() {
      votes = updated;
      isLiked = !isLiked;
    });

    // 🔥 BACKEND UPDATE
    await widget.supabase
        .from('issues')
        .update({'up_vote': updated, 'up_vote_count': updated.length})
        .eq('id', widget.issue['id']);

    // optional refresh (kept same as your flow)
    widget.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleLike,
      child: Icon(
        isLiked ? IconlyBold.heart : IconlyLight.heart,
        color: Colors.white,
      ),
    );
  }
}
//////////////////////////////////////////////////////////
// COMMENT
//////////////////////////////////////////////////////////

class CommentButton extends StatelessWidget {
  final Map<String, dynamic> issue;
  final SupabaseClient supabase;
  final Function refresh;

  const CommentButton({
    super.key,
    required this.issue,
    required this.supabase,
    required this.refresh,
  });

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    return InkWell(
      onTap: () {
        final controller = TextEditingController();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text(
              "Add Comment",
              style: TextStyle(color: darkGreen, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  hintText: "Type your comment here...",
                  icon: IconlyLight.paper,
                  controller: controller,
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final user = box.read('userData')['name'];

                    final newComment = {
                      "user": user,
                      "text": controller.text,
                      "created_at": DateTime.now().toIso8601String(),
                    };

                    final List comments = issue['comments'] ?? [];
                    comments.add(newComment);

                    await supabase
                        .from('issues')
                        .update({'comments': comments})
                        .eq('id', issue['id']);

                    Navigator.pop(context);
                    refresh();
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(name: "Post", color: darkGreen),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: const Icon(IconlyLight.more_square, color: Colors.white),
    );
  }
}

//////////////////////////////////////////////////////////
// Action
//////////////////////////////////////////////////////////
class ActionDialog extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;

  final String primaryText;
  final VoidCallback onPrimary;

  final String secondaryText;
  final VoidCallback onSecondary;

  const ActionDialog({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.primaryText,
    required this.onPrimary,
    required this.secondaryText,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 IMAGE (top visual)
            SvgPicture.asset(
              image,
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),

            // 🧠 TITLE
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            // 📄 SUBTITLE
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // 🔘 BUTTONS
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onSecondary,
                    child: CustomButton(
                      name: secondaryText,
                      color: primaryWhite,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onPrimary,
                    child: CustomButton(name: primaryText, color: darkGreen),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////
// Buttom
//////////////////////////////////////////////////////////
class CustomButton extends StatelessWidget {
  final String name;
  final Color color;
  const CustomButton({super.key, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      // width: 109,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Make width as wide as text
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color == darkGreen ? primaryWhite : primaryBlack,
                height: (24 / 16),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// showDialog(
//   context: context,
//   builder: (_) => ActionDialog(
//     image: "https://cdn-icons-png.flaticon.com/512/942/942748.png",
//     title: "Take ownership?",
//     subtitle: "This issue has been pending.\nStart working on it now.",
    
//     secondaryText: "Not now",
//     onSecondary: () => Navigator.pop(context),

//     primaryText: "Assign to me",
//     onPrimary: () async {
//       Navigator.pop(context);

//       final user = supabase.auth.currentUser;

//       await supabase.from('issues').update({
//         'status': 'Assigned',
//         'assigned_to': {
//           'type': 'NGO',
//           'id': userName,
//           'user_id': user?.id,
//           'self_assigned': true,
//           'assigned_at': DateTime.now().toIso8601String(),
//         },
//       }).eq('id', issue['id']);

//       refresh();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("You're now assigned ✅")),
//       );
//     },
//   ),
// );