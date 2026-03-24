import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spot_it/screens/admin/analytics_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spot_it/screens/issue/issue_detail.dart';
import 'package:spot_it/screens/issue/create_issue.dart';
import 'package:spot_it/services/services.dart';
import 'package:spot_it/utils/colors.dart';
import 'package:spot_it/utils/reusable_component.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';

class IssueScreen extends StatefulWidget {
  const IssueScreen({super.key});

  @override
  State<IssueScreen> createState() => _IssueScreenState();
}

class _IssueScreenState extends State<IssueScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> issues = [];
  bool loading = true;
  final ScreenshotController screenshotController = ScreenshotController();
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
    String city = location["address"];

    if (createdAt != null) {
      final dt = DateTime.parse(createdAt);
      date = "${dt.day} ${_month(dt.month)} ${dt.year}";
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

  Future<void> shareIssueCard(Map<String, dynamic> issue) async {
    final text =
        "🚧 Civic Issue Reported\n\n"
        "${issue['title']}\n"
        "📍 ${issue['location']?['address'] ?? ''}\n\n"
        "Reported via WeCare";

    await Share.share(text);
    // try {
    //   final image = await screenshotController.capture();

    //   if (image == null) return;

    //   final directory = await getTemporaryDirectory();
    //   final filePath = '${directory.path}/issue.png';

    //   final file = File(filePath);
    //   await file.writeAsBytes(image);

    //   final text =
    //       "🚧 Civic Issue Reported\n\n"
    //       "${issue['title']}\n"
    //       "📍 ${issue['location']?['address'] ?? ''}\n\n"
    //       "Reported via WeCare";

    //   await Share.shareXFiles([XFile(filePath)], text: text);
    // } catch (e) {
    //   debugPrint("Share error: $e");
    // }
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
            icon: const Icon(IconlyBroken.chart),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              );
              fetchIssues();
            },
          ),
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
          SizedBox(width: 20),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
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
                                child: IssueImageSlider(
                                  beforeImage: issue['before_image'] ?? "",
                                  afterImage: followUp['after_image'],
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(color: Colors.black45),
                                ),
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
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () =>
                                                    shareIssueCard(issue),
                                                child: const Icon(
                                                  IconlyLight.send,
                                                  color: Colors.white,
                                                ),
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

                      // // ================= OVERLAY RESOLUTION CARD =================
                      // if (isVerified && hasAfterImage)
                      //   Positioned(
                      //     top: 32, // 👈 pushed slightly down
                      //     left: 16,
                      //     right: 0,
                      //     bottom: 0,
                      //     child: Container(
                      //       margin: const EdgeInsets.only(right: 8, bottom: 8),
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(16),
                      //         boxShadow: const [
                      //           BoxShadow(
                      //             color: Colors.black26,
                      //             blurRadius: 10,
                      //             offset: Offset(0, 4),
                      //           ),
                      //         ],
                      //       ),
                      //       child: ClipRRect(
                      //         borderRadius: BorderRadius.circular(16),
                      //         child: Stack(
                      //           children: [
                      //             // AFTER IMAGE
                      //             Positioned.fill(
                      //               child: Image.network(
                      //                 followUp['after_image'],
                      //                 fit: BoxFit.cover,
                      //               ),
                      //             ),

                      //             // GRADIENT
                      //             Positioned.fill(
                      //               child: Container(
                      //                 decoration: const BoxDecoration(
                      //                   gradient: LinearGradient(
                      //                     colors: [
                      //                       Colors.transparent,
                      //                       Colors.black87,
                      //                     ],
                      //                     begin: Alignment.topCenter,
                      //                     end: Alignment.bottomCenter,
                      //                   ),
                      //                 ),
                      //               ),
                      //             ),

                      //             // VERIFIED BADGE
                      //             StatusChip(
                      //               issue: issue,
                      //               supabase: supabase,
                      //               refresh: fetchIssues,
                      //             ),

                      //             // 🔥 SAME STRUCTURE AS BASE CARD
                      //             Positioned(
                      //               left: 12,
                      //               right: 12,
                      //               bottom: 12,
                      //               child: Row(
                      //                 children: [
                      //                   // TEXT SIDE
                      //                   Expanded(
                      //                     child: Column(
                      //                       crossAxisAlignment:
                      //                           CrossAxisAlignment.start,
                      //                       children: [
                      //                         Text(
                      //                           issue['title'] ?? "",
                      //                           maxLines: 1,
                      //                           overflow: TextOverflow.ellipsis,
                      //                           style: const TextStyle(
                      //                             color: Colors.white,
                      //                             fontSize: 18,
                      //                             fontWeight: FontWeight.w500,
                      //                           ),
                      //                         ),
                      //                         const SizedBox(height: 4),

                      //                         // 🔥 description replaces old subtitle
                      //                         if (followUp['description'] !=
                      //                             null)
                      //                           Text(
                      //                             followUp['description'],
                      //                             maxLines: 1,
                      //                             overflow:
                      //                                 TextOverflow.ellipsis,
                      //                             style: const TextStyle(
                      //                               color: Colors.white70,
                      //                               fontSize: 14,
                      //                             ),
                      //                           ),

                      //                         const SizedBox(height: 4),

                      //                         Text(
                      //                           "Resolved by ${followUp['resolved_by'] ?? ""}",
                      //                           style: const TextStyle(
                      //                             color: Colors.white70,
                      //                             fontSize: 12,
                      //                           ),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                   ),

                      //                   // 🔥 SAME ACTION BUTTONS
                      //                   Row(
                      //                     children: [
                      //                       LikeButton(
                      //                         issue: issue,
                      //                         supabase: supabase,
                      //                         refresh: fetchIssues,
                      //                       ),
                      //                       const SizedBox(width: 8),
                      //                       CommentButton(
                      //                         issue: issue,
                      //                         supabase: supabase,
                      //                         refresh: fetchIssues,
                      //                       ),
                      //                       const SizedBox(width: 8),
                      //                     ],
                      //                   ),
                      //                 ],
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class IssueImageSlider extends StatefulWidget {
  final String beforeImage;
  final String? afterImage;

  const IssueImageSlider({
    super.key,
    required this.beforeImage,
    this.afterImage,
  });

  @override
  State<IssueImageSlider> createState() => _IssueImageSliderState();
}

class _IssueImageSliderState extends State<IssueImageSlider> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();

    if (widget.afterImage != null && widget.afterImage!.isNotEmpty) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        _controller.animateToPage(
          1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAfter = widget.afterImage != null && widget.afterImage!.isNotEmpty;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView(
          controller: _controller,
          onPageChanged: (i) => setState(() => _index = i),
          children: [
            Image.network(widget.beforeImage, fit: BoxFit.cover),
            if (hasAfter) Image.network(widget.afterImage!, fit: BoxFit.cover),
          ],
        ),

        if (hasAfter)
          Positioned(
            bottom: 10,
            child: Row(
              children: List.generate(2, (i) {
                return AnimatedContainer(
                  curve: Curves.linear,
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 36 : 16,
                  height: _index == i ? 6 : 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    color: _index == i ? darkGreen : Colors.white54,
                    shape: BoxShape.rectangle,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
