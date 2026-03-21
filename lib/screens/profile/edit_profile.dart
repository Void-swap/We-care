import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:we_care/main.dart';
import 'package:we_care/utils/colors.dart';
import 'package:we_care/utils/reusable_component.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final box = GetStorage();
  final supabase = Supabase.instance.client;

  final ImagePicker picker = ImagePicker();

  // controllers
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController addressController;
  late TextEditingController contactController;
  late TextEditingController interestController;

  Map user = {};
  XFile? image;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    user = box.read('userData') ?? {};

    nameController = TextEditingController(text: user['name']);
    descController = TextEditingController(text: user['description']);
    addressController = TextEditingController(text: user['address']);
    contactController = TextEditingController(text: user['contacts']);
    interestController = TextEditingController();
  }

  // ================= IMAGE PICK =================
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => image = picked);
    }
  }

  // ================= UPDATE =================
  Future<void> updateProfile() async {
    setState(() => loading = true);

    try {
      final uid = user['id'];

      String profileUrl = user['profile_pic'] ?? "";

      // 🔥 upload image if changed
      if (image != null) {
        final path = "profile/$uid-${DateTime.now().millisecondsSinceEpoch}";

        if (kIsWeb) {
          final bytes = await image!.readAsBytes();
          await supabase.storage.from('issues').uploadBinary(path, bytes);
        } else {
          await supabase.storage.from('issues').upload(path, File(image!.path));
        }

        profileUrl = supabase.storage.from('issues').getPublicUrl(path);
      }

      // 🔥 interests handling
      List interests = List.from(user['interests'] ?? []);
      if (interestController.text.isNotEmpty) {
        interests.add(interestController.text);
      }

      // 🔥 updated data
      final updatedUser = {
        ...user,
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'address': addressController.text.trim(),
        'contacts': contactController.text.trim(),
        'profile_pic': profileUrl,
        'interests': interests,
      };

      // ✅ UPDATE SUPABASE
      await supabase.from('users').update(updatedUser).eq('id', uid);

      // ✅ UPDATE LOCAL
      box.write('userData', updatedUser);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully ✅")),
      );
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
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= PROFILE PIC =================
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 45,
                backgroundImage: image != null
                    ? kIsWeb
                          ? NetworkImage(image!.path)
                          : FileImage(File(image!.path)) as ImageProvider
                    : (user['profile_pic'] != ""
                          ? NetworkImage(user['profile_pic'])
                          : null),
                child: image == null && user['profile_pic'] == ""
                    ? const Icon(IconlyLight.camera, size: 30)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            // ================= EDITABLE =================
            CustomTextField(
              hintText: "Name",
              icon: IconlyLight.profile,
              controller: nameController,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              hintText: "Description",
              icon: IconlyLight.message,
              controller: descController,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              hintText: "Address",
              icon: IconlyLight.location,
              controller: addressController,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              hintText: "Contact",
              icon: IconlyLight.call,
              controller: contactController,
            ),

            const SizedBox(height: 12),

            CustomTextField(
              hintText: "Add Interest",
              icon: IconlyLight.discovery,
              controller: interestController,
            ),

            const SizedBox(height: 20),

            // ================= NON EDITABLE =================
            _readOnlyTile("Email", user['email']),
            _readOnlyTile("Role", user['role']),
            _readOnlyTile(
              "Issues Created",
              (user['issue_created'] ?? []).length.toString(),
            ),
            _readOnlyTile(
              "Issues Resolved",
              (user['issue_resolved'] ?? []).length.toString(),
            ),

            const SizedBox(height: 12),

            // badges
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Badges",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),

            Wrap(
              spacing: 6,
              children: (user['badges'] ?? [])
                  .map<Widget>((b) => Chip(label: Text(b.toString())))
                  .toList(),
            ),

            const SizedBox(height: 30),

            // ================= SAVE =================
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: loading ? null : updateProfile,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const CustomButton(
                        name: "Save Changes",
                        color: darkGreen,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= READ ONLY =================
  Widget _readOnlyTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            value ?? "",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
