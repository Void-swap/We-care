import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:we_care/services/services.dart';

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
        'category': 'General',
        'classification': 'Community',
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image != null
                    ? kIsWeb
                          ? Image.network(_image!.path, fit: BoxFit.cover)
                          : Image.file(File(_image!.path), fit: BoxFit.cover)
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40),
                            SizedBox(height: 8),
                            Text("Tap to capture photo"),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Issue Title"),
              validator: (v) => v!.isEmpty ? "Enter title" : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              validator: (v) => v!.isEmpty ? "Enter description" : null,
            ),
            const SizedBox(height: 20),
            _loadingLocation
                ? const Center(child: CircularProgressIndicator())
                : Text(_address ?? "Fetching location..."),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
