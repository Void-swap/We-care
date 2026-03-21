import 'dart:io';
import 'package:faker/faker.dart' hide Image;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:we_care/main.dart';
import 'package:we_care/services/services.dart';
import 'package:we_care/utils/colors.dart';
import 'package:latlong2/latlong.dart';

void logg(String msg) {
  debugPrint("🧠 [ReportIssue] $msg");
}

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final box = GetStorage();

  final _descriptionController = TextEditingController();
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  XFile? _image;
  Position? _position;
  String? _address;

  bool _loading = false;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ================= LOCATION =================
  Future<void> _initLocation() async {
    logg("📍 Starting location fetch");

    if (!mounted) return;

    setState(() => _loadingLocation = true);

    try {
      final permission = await Geolocator.requestPermission();
      logg("Permission: $permission");

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Location permission denied");
      }

      final pos = await Geolocator.getCurrentPosition();
      logg("Position: ${pos.latitude}, ${pos.longitude}");

      _position = pos;

      String finalAddress = "Unknown";

      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );

        logg("Placemarks count: ${placemarks.length}");

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          // 🔥 SAFE EXTRACTION
          final area = (p.subLocality != null && p.subLocality!.isNotEmpty)
              ? p.subLocality
              : (p.locality != null && p.locality!.isNotEmpty)
              ? p.locality
              : null;

          final city = (p.locality != null && p.locality!.isNotEmpty)
              ? p.locality
              : (p.administrativeArea != null &&
                    p.administrativeArea!.isNotEmpty)
              ? p.administrativeArea
              : null;

          // 🔥 BUILD ADDRESS
          if (area != null && city != null) {
            finalAddress = "$area, $city";
          } else if (city != null) {
            finalAddress = city;
          } else {
            finalAddress = "Lat: ${pos.latitude}, Lng: ${pos.longitude}";
          }
        } else {
          finalAddress = "Lat: ${pos.latitude}, Lng: ${pos.longitude}";
        }
      } catch (e) {
        logg("⚠️ Geocoding failed: $e");

        // 🔥 HARD FALLBACK (no crash)
        finalAddress = "Kharghar";
      }

      _address = finalAddress;

      logg("✅ Final Address: $_address");

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      logg("❌ Location error: $e");
      if (!mounted) return;
      _showSnack("Location error: $e");
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  // ================= IMAGE =================
  Future<void> _pickImage() async {
    logg("📸 Opening camera");

    final picked = await _picker.pickImage(source: ImageSource.camera);

    if (picked == null) {
      logg("❌ No image selected");
      return;
    }

    logg("✅ Image selected: ${picked.path}");

    if (mounted) setState(() => _image = picked);
  }

  // ================= SNACK =================
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= SUBMIT =================
  Future<void> _submit() async {
    // _addingDummyData();
    logg("🚀 Submit started");
    final userName = box.read('userData')['name'];

    if (!_formKey.currentState!.validate()) {
      logg("❌ Form invalid");
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    logg("Image: $_image");
    logg("Position: $_position");
    logg("Address: $_address");

    if (_image == null) {
      logg("❌ Image NULL");
      messenger.showSnackBar(
        const SnackBar(content: Text("Please capture a photo")),
      );
      return;
    }

    if (_position == null) {
      logg("❌ Position NULL");
      messenger.showSnackBar(
        const SnackBar(content: Text("Location not available")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      logg("User: $user");

      if (user == null) throw Exception("User not logged in");

      final issueId = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = "$issueId-${path.basename(_image!.path)}";

      logg("IssueID: $issueId");
      logg("FileName: $fileName");

      // ===== STORAGE DEBUG =====
      logg("Using bucket: issues");
      logg("Uploading to path: reports/$fileName");

      if (kIsWeb) {
        final bytes = await _image!.readAsBytes();
        logg("Web upload - bytes length: ${bytes.length}");

        final res = await supabase.storage
            .from('issues')
            .uploadBinary('reports/$fileName', bytes);

        logg("Upload response: $res");
      } else {
        final file = File(_image!.path);
        logg("Mobile upload - file exists: ${file.existsSync()}");

        final res = await supabase.storage
            .from('issues')
            .upload('reports/$fileName', file);

        logg("Upload response: $res");
      }

      logg("✅ Upload completed");

      final imageUrl = supabase.storage
          .from('issues')
          .getPublicUrl('reports/$fileName');

      logg("Image URL: $imageUrl");

      // ===== DATA =====
      final issueData = {
        'id': issueId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'before_image': imageUrl,
        'location': {
          'latitude': _position!.latitude,
          'longitude': _position!.longitude,
          'address': _address,
        },
        'images': [imageUrl],
        'created_by': userName,
        'creator_role': 'Citizen',
        'category': _selectedCategory,
        'classification': _selectedClassification,
        'status': 'Pending',
        'up_vote': [],
        'up_vote_count': 0,
        'assigned_to': {
          'type': '',
          'id': '',
          'self_assigned': false,
          'assigned_at': null,
        },
        'follow_up': {
          'resolved_by': '',
          'resolver_role': '',
          'after_image': '',
          'description': '',
          'verified': false,
        },
        'comments': [],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      logg("📦 Inserting into DB...");
      logg("Payload: $issueData");

      final response = await supabase.from('issues').insert(issueData);

      logg("✅ DB Insert Response: $response");

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text("Issue reported successfully ✅")),
      );

      navigator.pop();
    } catch (e, st) {
      logg("❌ ERROR: $e");
      logg("STACK: $st");

      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =================== FAKE DATA ==============
  Future<void> _addingDummyData() async {
    logg("🚀 FINAL REALISTIC SEED (STABLE IMAGES)");

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final names = [
        "Aarav Mehta",
        "Riya Sharma",
        "Kabir Khan",
        "Ananya Iyer",
        "Rahul Verma",
        "Sneha Patil",
        "Arjun Reddy",
        "Neha Gupta",
      ];

      // 🔥 PERFECTLY MATCHED ISSUE + IMAGE
      final issueTemplates = [
        {
          "title": "Severe pothole damaging vehicles",
          "desc":
              "A large pothole has formed in the middle of the road causing inconvenience and vehicle damage.",
          "image":
              "https://poelrmrksvtixrusvjuo.supabase.co/storage/v1/object/public/issues/reports/1774094322790-eb9a0d46-9968-425a-b915-3d668d15f125",
        },
        {
          "title": "Streetlight not working at night",
          "desc":
              "The streetlight in this area has stopped working making the road unsafe at night.",
          "image":
              "https://poelrmrksvtixrusvjuo.supabase.co/storage/v1/object/public/issues/reports/1774094311832-36ee4ff8-8bdb-4452-b6cf-2dcfb00be954",
        },
        {
          "title": "Water leakage flooding the road",
          "desc":
              "Continuous leakage from underground pipeline is causing water accumulation on the street.",
          "image":
              "https://poelrmrksvtixrusvjuo.supabase.co/storage/v1/object/public/issues/reports/1774094300479-c3b566b3-8bae-415c-9d78-2e7502cb4561",
        },
        {
          "title": "Garbage dumped along beach side",
          "desc":
              "Waste accumulation near the beach is creating hygiene and environmental concerns.",
          "image":
              "https://poelrmrksvtixrusvjuo.supabase.co/storage/v1/object/public/issues/reports/1774002716545-ee7506ec-854b-4531-b708-1a3071b8d952",
        },
      ];

      final locations = [
        {"city": "Mumbai", "lat": 19.0760, "lng": 72.8777},
        {"city": "Pune", "lat": 18.5204, "lng": 73.8567},
        {"city": "Bangalore", "lat": 12.9716, "lng": 77.5946},
        {"city": "Delhi", "lat": 28.6139, "lng": 77.2090},
      ];

      final statuses = ["Pending", "Assigned", "Resolved", "Verified"];

      for (int i = 0; i < 15; i++) {
        final issueId =
            DateTime.now().millisecondsSinceEpoch.toString() + i.toString();

        final template = issueTemplates[i % issueTemplates.length];
        final loc = locations[i % locations.length];
        final name = names[i % names.length];
        final status = statuses[i % statuses.length];

        // 🔥 REALISTIC UPVOTES
        final upVotes = List.generate(
          (i + 2) * 2,
          (index) => {
            "user": names[index % names.length],
            "created_at": DateTime.now()
                .subtract(Duration(hours: index * 3))
                .toIso8601String(),
          },
        );

        // 🔥 COMMENTS
        final comments = [
          {
            "user": "Rahul Verma",
            "text": "This needs urgent fixing.",
            "created_at": DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String(),
          },
          {
            "user": "Sneha Patil",
            "text": "Facing this issue regularly!",
            "created_at": DateTime.now()
                .subtract(const Duration(hours: 6))
                .toIso8601String(),
          },
        ];

        // 🔥 ASSIGNED LOGIC
        final assignedTo = status != "Pending"
            ? {
                "type": "NGO",
                "id": "UrbanCare NGO",
                "self_assigned": true,
                "assigned_at": DateTime.now()
                    .subtract(const Duration(days: 2))
                    .toIso8601String(),
              }
            : {
                "type": '',
                "id": '',
                "self_assigned": false,
                "assigned_at": null,
              };

        // 🔥 FOLLOW UP (RESOLVED / VERIFIED)
        final followUp = (status == "Resolved" || status == "Verified")
            ? {
                "resolved_by": "City Repair Team",
                "resolver_role": "Field Engineer",
                "after_image": template['image'], // 🔥 SAME IMAGE SAFE
                "description":
                    "Issue has been successfully resolved and area restored.",
                "verified": status == "Verified",
              }
            : {
                "resolved_by": '',
                "resolver_role": '',
                "after_image": '',
                "description": '',
                "verified": false,
              };

        final issueData = {
          'id': issueId,
          'title': template['title'],
          'description': template['desc'],
          'before_image': template['image'],
          'location': {
            'latitude': loc['lat'],
            'longitude': loc['lng'],
            'address': loc['city'],
          },
          'images': [template['image']],
          'created_by': name,
          'creator_role': 'Citizen',
          'category': 'Infrastructure',
          'classification': 'Community',
          'status': status,
          'up_vote': upVotes,
          'up_vote_count': upVotes.length,
          'assigned_to': assignedTo,
          'follow_up': followUp,
          'comments': comments,
          'created_at': DateTime.now()
              .subtract(Duration(days: i))
              .toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await supabase.from('issues').insert(issueData);

        logg("✅ Inserted issue $i (${template['title']})");
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text("🔥 Realistic issues with stable images added"),
        ),
      );

      Navigator.pop(context);
    } catch (e, st) {
      logg("❌ ERROR: $e");
      logg("STACK: $st");

      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _selectedCategory;
  String? _selectedClassification;

  final List<String> categories = [
    "Pothole",
    "Garbage",
    "Streetlight",
    "Water Leakage",
    "Drainage",
    "Traffic Signal",
    "Road Damage",
    "Public Safety",
  ];

  final List<String> classifications = [
    "Community Level",
    "Hybrid Level",
    "State Level",
  ];
  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Issue"),
        backgroundColor: Colors.white,
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ================= IMAGE =================
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade200,
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: kIsWeb
                            ? Image.network(_image!.path, fit: BoxFit.cover)
                            : Image.file(File(_image!.path), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt, size: 40),
                          SizedBox(height: 8),
                          Text("Capture Issue"),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= INPUTS =================
            Column(
              children: [
                CustomTextField(
                  hintText: "Issue Title",
                  icon: IconlyLight.edit,
                  controller: _titleController,
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  hintText: "Describe the issue...",
                  icon: IconlyLight.document,
                  controller: _descriptionController,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ================= CATEGORY =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text("Select Category"),
                decoration: const InputDecoration(border: InputBorder.none),
                items: categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (v) => v == null ? "Select category" : null,
              ),
            ),

            const SizedBox(height: 15),

            // ================= CLASSIFICATION =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedClassification,
                hint: const Text("Select Classification"),
                decoration: const InputDecoration(border: InputBorder.none),
                items: classifications
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedClassification = val),
                validator: (v) => v == null ? "Select classification" : null,
              ),
            ),

            const SizedBox(height: 20),

            // ================= LOCATION =================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(IconlyLight.location),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _loadingLocation
                        ? const Text("Fetching location...")
                        : Text(_address ?? "Location unavailable"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            if (_position?.latitude != null || _position?.longitude != null)
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGrey,
                      blurRadius: 0.5,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        _position!.latitude,
                        _position!.longitude,
                      ),
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
                            point: LatLng(
                              _position!.latitude,
                              _position!.longitude,
                            ),
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

            const SizedBox(height: 30),

            // ================= SUBMIT =================
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Issue",
                        style: TextStyle(color: primaryWhite),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
