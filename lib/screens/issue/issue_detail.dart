import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class IssueDetailScreen extends StatelessWidget {
  final Map<String, dynamic> issue;

  const IssueDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final location = issue['location'] ?? {};
    final lat = (location['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (location['longitude'] as num?)?.toDouble() ?? 0;

    final status = issue['status'] ?? "Pending";

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
            // ================= HERO IMAGE =================
            Stack(
              children: [
                Image.network(
                  issue['before_image'] ?? "",
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                // STATUS CHIP
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            // ================= CONTENT =================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📍 ADDRESS
                  Row(
                    children: [
                      const Icon(IconlyLight.location, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location['address'] ?? "Unknown location",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🧠 TITLE
                  Text(
                    issue['title'] ?? "",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0E3B2E),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= DESCRIPTION =================
                  _card(
                    title: "Description",
                    child: Text(
                      issue['description'] ?? "",
                      style: const TextStyle(height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= ASSIGNED =================
                  _infoCard(
                    icon: IconlyLight.work,
                    title: "Assigned Department",
                    value: issue['assigned_to']?['type'] ?? "Unassigned",
                  ),

                  const SizedBox(height: 12),

                  _infoCard(
                    icon: IconlyLight.calendar,
                    title: "Reported Date",
                    value: issue['created_at'] ?? "",
                  ),

                  const SizedBox(height: 20),

                  // ================= SUPPORT =================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E3B2E),
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

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Upvote Issue"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= MAP =================
                  _card(
                    title: "Location Map",
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 15,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat, lng),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Lat: $lat, Lng: $lng",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 10),
          child,
        ],
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
          Icon(icon),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
