import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:we_care/screens/issue/issue_detail.dart';
import 'package:we_care/screens/report.dart';
import 'package:we_care/services/services.dart';
import 'package:we_care/utils/colors.dart';

class IssueScreen extends StatefulWidget {
  const IssueScreen({super.key});

  @override
  State<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<IssueScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> issues = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchIssues();
  }

  Future<void> fetchIssues() async {
    try {
      final res = await supabase
          .from('issues')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        issues = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Fetch error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String> formatDetails(Map<String, dynamic> issue) async {
    final createdAt = issue['created_at'];
    final location = issue['location'];

    String date = "";
    String city = "";

    if (createdAt != null) {
      final dt = DateTime.parse(createdAt);
      date = "${dt.day} ${_month(dt.month)} ${dt.year}";
    }

    if (location != null) {
      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        city = await getCityFromLatLng(lat, lng);
      }
    }

    return "$date • $city";
  }

  String _month(int m) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          "Issues",
          style: TextStyle(color: darkGreen, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(IconlyBroken.plus),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
              );
              fetchIssues();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issue = issues[index];

                final followUp = issue['follow_up'] ?? {};
                final isVerified = issue['status'] == "Verified";
                final hasAfterImage =
                    followUp['after_image'] != null &&
                    followUp['after_image'] != "";

                return SizedBox(
                  height: 240,
                  child: Stack(
                    children: [
                      // ================= BASE CARD (BEFORE) =================
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IssueDetailScreen(issue: issue),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.network(
                                  issue['before_image'] ?? "",
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned.fill(
                                child: Container(color: Colors.black45),
                              ),

                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // TOP
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          StatusChip(
                                            issue: issue,
                                            supabase: supabase,
                                            refresh: fetchIssues,
                                          ),
                                          const Row(
                                            children: [
                                              const Icon(
                                                IconlyLight.bookmark,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // BOTTOM
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  issue['title'] ?? "",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  "Reported by ${issue['created_by']?.substring(0, 6) ?? ""}",
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                FutureBuilder<String>(
                                                  future: formatDetails(issue),
                                                  builder: (context, snapshot) {
                                                    return Text(
                                                      snapshot.data ??
                                                          "Loading...",
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 13,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),

                                          // 🔥 KEEP ACTIONS
                                          Row(
                                            children: [
                                              LikeButton(
                                                issue: issue,
                                                supabase: supabase,
                                                refresh: fetchIssues,
                                              ),
                                              const SizedBox(width: 8),
                                              CommentButton(
                                                issue: issue,
                                                supabase: supabase,
                                                refresh: fetchIssues,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ================= OVERLAY RESOLUTION CARD =================
                      if (isVerified && hasAfterImage)
                        Positioned(
                          top: 32, // 👈 pushed slightly down
                          left: 16,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8, bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  // AFTER IMAGE
                                  Positioned.fill(
                                    child: Image.network(
                                      followUp['after_image'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  // GRADIENT
                                  Positioned.fill(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black87,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // VERIFIED BADGE
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "Verified",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 🔥 SAME STRUCTURE AS BASE CARD
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                    child: Row(
                                      children: [
                                        // TEXT SIDE
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                issue['title'] ?? "",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),

                                              // 🔥 description replaces old subtitle
                                              if (followUp['description'] !=
                                                  null)
                                                Text(
                                                  followUp['description'],
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                ),

                                              const SizedBox(height: 4),

                                              Text(
                                                "Resolved by ${followUp['resolved_by'] ?? ""}",
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 🔥 SAME ACTION BUTTONS
                                        Row(
                                          children: [
                                            LikeButton(
                                              issue: issue,
                                              supabase: supabase,
                                              refresh: fetchIssues,
                                            ),
                                            const SizedBox(width: 8),
                                            CommentButton(
                                              issue: issue,
                                              supabase: supabase,
                                              refresh: fetchIssues,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

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
    final verify = canVerify(issue, userData);

    return InkWell(
      onTap: verify
          ? () {
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
            }
          : null,
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

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null && mounted) {
      setState(() => image = picked);
    }
  }

  // ================= SUBMIT =================
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

      String path = 'after/$fileName';

      // ✅ WEB vs MOBILE upload
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

      // ===== UPDATE DB =====
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Issue")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📸 IMAGE PREVIEW (FIXED)
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: image != null
                    ? kIsWeb
                          ? Image.network(image!.path, fit: BoxFit.cover)
                          : Image.file(File(image!.path), fit: BoxFit.cover)
                    : const Center(child: Text("Tap to capture after image")),
              ),
            ),

            const SizedBox(height: 20),

            // 📝 DESCRIPTION
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Work description"),
            ),

            const SizedBox(height: 20),

            // 👤 AUTO INFO
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Resolved by: ${widget.userName}"),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Role: ${widget.role}"),
            ),

            const Spacer(),

            // 🚀 SUBMIT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Verification"),
              ),
            ),
          ],
        ),
      ),
    );
  }
} //////////////////////////////////////////////////////////
// LIKE BUTTON (FIXED)
//////////////////////////////////////////////////////////

class LikeButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final List votes = issue['up_vote'] ?? [];

    final isLiked = votes.any((v) {
      if (v is Map) return v['user'] == user?.email;
      if (v is String) return v == user?.id;
      return false;
    });

    return InkWell(
      onTap: () async {
        List updated = [];

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

        if (isLiked) {
          updated.removeWhere((v) => v['user'] == user?.email);
        } else {
          updated.add({
            "user": user?.email,
            "created_at": DateTime.now().toIso8601String(),
          });
        }

        await supabase
            .from('issues')
            .update({'up_vote': updated, 'up_vote_count': updated.length})
            .eq('id', issue['id']);

        refresh();
      },
      child: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: Colors.white,
        size: 16,
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
    return InkWell(
      onTap: () {
        final controller = TextEditingController();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Add Comment"),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () async {
                  final user = supabase.auth.currentUser;

                  final newComment = {
                    "user": user?.email,
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
                child: const Text("Post"),
              ),
            ],
          ),
        );
      },
      child: const Icon(IconlyLight.more_square, color: Colors.white, size: 16),
    );
  }
}
