import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class VerifyMe extends StatefulWidget {
  const VerifyMe({super.key});

  @override
  State<VerifyMe> createState() => _VerifyMeState();
}

class _VerifyMeState extends State<VerifyMe> {
  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();
  final supabase = Supabase.instance.client;

  final TextEditingController motivationController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  final ImagePicker picker = ImagePicker();

  XFile? file;
  bool loading = false;

  // ================= PICK FILE =================
  Future<void> pickFile() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null && mounted) {
      setState(() => file = picked);
    }
  }

  // ================= SUBMIT =================
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (file == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload document")));
      return;
    }

    setState(() => loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final fileName =
          "verification_${user.id}_${DateTime.now().millisecondsSinceEpoch}.${path.extension(file!.path)}";

      final filePath = "docs/$fileName";

      // ===== UPLOAD =====
      if (kIsWeb) {
        final bytes = await file!.readAsBytes();
        await supabase.storage
            .from('verification')
            .uploadBinary(filePath, bytes);
      } else {
        await supabase.storage
            .from('verification')
            .upload(filePath, File(file!.path));
      }

      final fileUrl = supabase.storage
          .from('verification')
          .getPublicUrl(filePath);

      // ===== INSERT INTO DB =====
      await supabase.from('verification').insert({
        'user_id': user.id,
        'user_name': box.read('userData')['name'], // ✅ NEW FIELD
        'motivation': motivationController.text.trim(),
        'experience': experienceController.text.trim(),
        'document_url': fileUrl,
        'status': 'pending',
        'comments': '',
      });
      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Verification submitted ✅")));
    } catch (e) {
      if (!mounted) return;
      print(e);
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
      appBar: AppBar(title: const Text('Get Verified')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= MOTIVATION =================
                    const Text(
                      "What inspires you to volunteer on this platform*",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: motivationController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Start typing here...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 20),

                    // ================= EXPERIENCE =================
                    const Text(
                      "Share past experiences that made a meaningful impact*",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: experienceController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Start typing here...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),

                    const SizedBox(height: 20),

                    // ================= DOCUMENT =================
                    const Text(
                      "Official Organizational Document",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: pickFile,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              file != null
                                  ? "Selected"
                                  : "Tap to upload document",
                            ),
                            const Icon(Icons.upload_file),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= BUTTON =================
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Apply'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
