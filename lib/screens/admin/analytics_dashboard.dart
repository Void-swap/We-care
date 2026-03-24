import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:spot_it/utils/colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;

  int totalIssues = 0;
  int resolvedIssues = 0;
  Duration avgResolutionTime = Duration.zero;
  double avgLikes = 0;
  double avgComments = 0;
  Map<String, int> categoryCount = {};

  // 🗺️ STORE ALL MARKERS
  List<Marker> issueMarkers = [];

  // 📍 MUMBAI DEFAULT
  static const LatLng mumbaiCenter = LatLng(19.0760, 72.8777);

  final List<Color> chartColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      final data = await supabase.from('issues').select();

      totalIssues = data.length;

      Duration totalDuration = Duration.zero;
      int resolvedCount = 0;

      num totalLikes = 0;
      num totalComments = 0;

      Map<String, int> tempCategory = {};
      List<Marker> tempMarkers = [];

      for (var issue in data) {
        // CATEGORY
        String category = issue['category'] ?? 'Other';
        tempCategory[category] = (tempCategory[category] ?? 0) + 1;

        //ENgagement
        totalLikes += issue['up_vote_count'] ?? 0;

        final comments = issue['comments'] ?? [];
        totalComments += comments.length;

        // 📍 MAP MARKERS
        final loc = issue['location'];
        if (loc != null &&
            loc['latitude'] != null &&
            loc['longitude'] != null) {
          tempMarkers.add(
            Marker(
              point: LatLng(loc['latitude'], loc['longitude']),
              width: 40,
              height: 40,
              child: const Icon(
                IconlyBold.location,
                color: darkGreen,
                size: 30,
              ),
            ),
          );
        }

        // RESOLUTION TIME
        if (issue['status'] == 'Resolved') {
          final createdAt = DateTime.parse(issue['created_at']);
          final updatedAt = DateTime.parse(issue['updated_at']);

          final diff = updatedAt.difference(createdAt);
          if (diff.isNegative) continue;

          totalDuration += diff;
          resolvedCount++;
        }
      }

      resolvedIssues = resolvedCount;

      avgResolutionTime = resolvedCount == 0
          ? Duration.zero
          : Duration(
              milliseconds: totalDuration.inMilliseconds ~/ resolvedCount,
            );

      avgLikes = totalIssues == 0 ? 0 : totalLikes / totalIssues;
      avgComments = totalIssues == 0 ? 0 : totalComments / totalIssues;

      categoryCount = tempCategory;
      issueMarkers = tempMarkers;

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  String formatDays(Duration d) {
    if (d == Duration.zero) return "0";
    return "${d.inDays}";
  }

  Widget buildCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPieChart() {
    final total = categoryCount.values.fold(0, (a, b) => a + b);

    int index = 0;

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: categoryCount.entries.map((e) {
            final percent = (e.value / total) * 100;
            final color = chartColors[index++ % chartColors.length];

            return PieChartSectionData(
              color: color,
              value: e.value.toDouble(),
              title: "${percent.toStringAsFixed(0)}%",
              radius: 70,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildLegend() {
    int index = 0;

    return Column(
      children: categoryCount.entries.map((e) {
        final color = chartColors[index++ % chartColors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(e.key),
              const Spacer(),
              Text(e.value.toString()),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🗺️ MAP SECTION
  Widget buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Issue Map",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 12),

        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: mumbaiCenter, // ✅ Mumbai default
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),

                MarkerLayer(
                  markers: issueMarkers.isNotEmpty
                      ? issueMarkers
                      : [
                          // fallback marker if no data
                          const Marker(
                            point: mumbaiCenter,
                            width: 40,
                            height: 40,
                            child: Icon(IconlyBold.location, color: darkGreen),
                          ),
                        ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: darkGreen),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "KPIs",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Issues: ${totalIssues.toString()}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  resolvedIssues.toString(),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Resolved",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  (totalIssues - resolvedIssues).toString(),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Pending",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  //NSM
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
                          "North Star Metrics",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Text(
                                  formatDays(avgResolutionTime) + " Days",
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Total Turn Around Rate",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),

                            // Column(
                            //   children: [
                            //     Text(
                            //       (totalIssues - resolvedIssues).toString(),
                            //       style: const TextStyle(
                            //         fontSize: 36,
                            //         color: Colors.white,
                            //         fontWeight: FontWeight.bold,
                            //       ),
                            //     ),
                            //     const Text(
                            //       "Pending",
                            //       style: TextStyle(color: Colors.white70),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  //Engagement
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
                          "Engagement",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      IconlyBold.heart,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      avgLikes.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                const Text(
                                  "Avg Likes",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      IconlyBold.more_square,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      avgComments.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Avg Comments",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Row(
                  //   children: [
                  //     buildCard(
                  //       "Total Issues",
                  //       totalIssues.toString(),
                  //       Colors.blue,
                  //     ),
                  //     buildCard(
                  //       "Resolved",
                  //       resolvedIssues.toString(),
                  //       Colors.green,
                  //     ),
                  //   ],
                  // ),
                  // Row(
                  //   children: [
                  //     buildCard(
                  //       "Avg Days",
                  //       formatDays(avgResolutionTime),
                  //       Colors.orange,
                  //     ),
                  //     buildCard(
                  //       "Pending",
                  //       (totalIssues - resolvedIssues).toString(),
                  //       Colors.red,
                  //     ),
                  //   ],
                  // ),
                  // 🗺️ NEW MAP SECTION
                  buildMapSection(), const SizedBox(height: 20),

                  // 📊 PIE
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Category Distribution",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        buildPieChart(),
                        const SizedBox(height: 16),
                        buildLegend(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
