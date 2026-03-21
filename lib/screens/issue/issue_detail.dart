import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:we_care/utils/colors.dart';
import 'package:we_care/utils/reusable_component.dart';

class IssueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final supabase = Supabase.instance.client;

  late Map<String, dynamic> issue;

  @override
  void initState() {
    super.initState();
    issue = widget.issue;
  }

  Future<void> refresh() async {
    final res = await supabase
        .from('issues')
        .select()
        .eq('id', issue['id'])
        .single();

    if (!mounted) return;

    setState(() {
      issue = res;
    });
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

    // if (location != null) {
    //   final lat = (location['latitude'] as num?)?.toDouble();
    //   final lng = (location['longitude'] as num?)?.toDouble();
    //   if (lat != null && lng != null) {
    //     city = await getCityFromLatLng(lat, lng);
    //   }
    // }

    return "$date";
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
    final location = issue['location'] ?? {};
    final lat = (location['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (location['longitude'] as num?)?.toDouble() ?? 0;

    final status = issue['status'] ?? "Pending";
    final comments = issue['comments'] ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),

      appBar: AppBar(
        title: const Text("Issue Detail"),
        backgroundColor: Colors.white,
        actions: const [Icon(IconlyLight.send), SizedBox(width: 12)],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= CONTENT =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusProgressBar(
                    status: status,
                  ), // ================= HERO CARD =================
                  const SizedBox(height: 10),

                  Container(
                    height: 220,
                    child: Card(
                      elevation: 4,
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      StatusChip(
                                        issue: issue,
                                        supabase: supabase,
                                        refresh: refresh,
                                      ),
                                      const Icon(
                                        IconlyLight.bookmark,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),

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
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                              ),
                                            ),
                                            Text(
                                              "Reported by ${issue['created_by'] ?? ""}",
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Row(
                                        children: [
                                          LikeButton(
                                            issue: issue,
                                            supabase: supabase,
                                            refresh: refresh,
                                          ),
                                          const SizedBox(width: 8),
                                          CommentButton(
                                            issue: issue,
                                            supabase: supabase,
                                            refresh: refresh,
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

                  const SizedBox(height: 10),

                  _infoCard(
                    icon: IconlyBold.paper,
                    title: "DESCRIPTION",
                    value: issue['description'] ?? "",
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(IconlyBold.calendar, color: darkGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("REPORTED DATE"),
                              FutureBuilder<String>(
                                future: formatDetails(issue),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data ?? "Loading...",
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= SUPPORT =================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PUBLIC SUPPORT",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "${issue['up_vote_count'] ?? 0}",
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Upvotes",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "${comments.length}",
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Comments",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        if (comments.isNotEmpty)
                          _infoCard(
                            icon: IconlyBold.profile,
                            title: comments.last['user'] ?? "",
                            value: comments.last['text'] ?? "",
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= MAP =================
                  Text("    LOCATION"), const SizedBox(height: 10),

                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.251),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(lat, lng),
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                            subdomains: const ['a', 'b', 'c', 'd'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat, lng),
                                child: const Icon(
                                  Icons.location_on,
                                  color: darkGreen,
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: darkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  value,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Color _statusColor(String status) {
    switch (status) {
      case "Assigned":
        return Colors.blue;
      case "Resolved":
        return Colors.orange;
      case "Verified":
        return Colors.green;
      default:
        return Colors.red;
    }
  }
}

class StatusProgressBar extends StatelessWidget {
  final String status;

  const StatusProgressBar({super.key, required this.status});

  final List<String> steps = const [
    "Pending",
    "Assigned",
    "Resolved",
    "Verified",
  ];

  Color getStepColor(String step) {
    switch (step) {
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

  int getCurrentIndex() {
    final index = steps.indexOf(status);
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = getCurrentIndex();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth - 24;
        final stepWidth = totalWidth / (steps.length - 1);

        return Stack(
          alignment: Alignment.center,
          children: [
            // 🔗 BASE LINE (CENTERED PERFECTLY)
            Positioned(
              left: 12,
              right: 12,
              top: 10, // 👈 EXACT CENTER OF DOT (18px / 2)
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // 🔗 COLORED SEGMENTS
            Positioned(
              left: 12,
              top: 10,
              child: Row(
                children: List.generate(steps.length - 1, (index) {
                  final isActive = index < currentIndex;

                  return Container(
                    width: stepWidth,
                    height: 3,
                    decoration: BoxDecoration(
                      color: isActive
                          ? getStepColor(steps[index + 1])
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),

            // 🔵 DOTS + LABELS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(steps.length, (index) {
                final step = steps[index];
                final isCompleted = index < currentIndex;
                final isCurrent = index == currentIndex;
                final stepColor = getStepColor(step);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔵 DOT
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isCompleted || isCurrent)
                              ? stepColor.withOpacity(0.7)
                              : Colors.white,
                          border: Border.all(color: stepColor, width: 2),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: stepColor.withOpacity(0.7),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: isCompleted || isCurrent
                            ? const Icon(
                                Icons.check,
                                size: 15,
                                color: primaryWhite,
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 🔤 LABEL
                    Text(
                      step,
                      style: TextStyle(
                        fontSize: 11,
                        color: stepColor,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
