// user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _box = GetStorage();

  // //get user info from UID
  // Future<Map<String, dynamic>?> getUserInfo(String uid) async {
  //   try {
  //     DocumentSnapshot userDoc = await _firestore
  //         .collection('users')
  //         .doc(uid)
  //         .get();
  //     if (userDoc.exists) {
  //       return userDoc.data() as Map<String, dynamic>?;
  //     } else {
  //       return null; // User not found
  //     }
  //   } catch (e) {
  //     print('Error fetching user info: $e');
  //     return null; // Handle error appropriately
  //   }
  // }

  // Method to fetch user data
  Map<String, dynamic>? getUserData() {
    final userData = _box.read('userData');
    return userData != null ? Map<String, dynamic>.from(userData) : null;
  }

  // Example method to fetch a specific field
  String getUserName() {
    final userData = getUserData();
    return userData?['name'] ?? 'no name';
  }

  String getUserProfilePic() {
    final userData = getUserData();
    return userData?['profilePic'] ?? 'not pfp';
  }

  String getUserUID() {
    final userData = getUserData();
    return userData?['uid'] ?? 'No UID';
  }
}

Future<String> getWebImageUrl(String gsPath) async {
  final ref = FirebaseStorage.instance.ref().child(gsPath);
  return await ref.getDownloadURL(); // gives you https link
}

Future<String> getCityFromLatLng(double? lat, double? lng) async {
  try {
    // 🔒 NULL SAFETY FIRST
    if (lat == null || lng == null) {
      return "Unknown location";
    }

    final placemarks = await placemarkFromCoordinates(lat, lng);

    if (placemarks.isEmpty) {
      return "Unknown location";
    }

    final place = placemarks.first;

    // 🔥 SAFE FALLBACK CHAIN
    final city = (place.locality != null && place.locality!.isNotEmpty)
        ? place.locality
        : (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty)
        ? place.subAdministrativeArea
        : (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
        ? place.administrativeArea
        : null;

    return city ?? "Unknown location";
  } catch (e) {
    debugPrint("❌ City fetch error: $e");
    return "Unknown location";
  }
}

Future<String?> getCurrentCity() async {
  try {
    debugPrint("📍 Fetching current city...");

    // ✅ Permission
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return "Location denied";
    }

    // ✅ Position
    final pos = await Geolocator.getCurrentPosition();

    debugPrint("📍 Lat: ${pos.latitude}, Lng: ${pos.longitude}");

    // ✅ Geocoding
    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    if (placemarks.isEmpty) return "Unknown";

    final p = placemarks.first;

    // 🔥 DIRECT CITY (SAFE FALLBACK CHAIN)
    final city = (p.locality != null && p.locality!.isNotEmpty)
        ? p.locality
        : (p.subAdministrativeArea != null &&
              p.subAdministrativeArea!.isNotEmpty)
        ? p.subAdministrativeArea
        : (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
        ? p.administrativeArea
        : "Unknown";

    debugPrint("✅ City: $city");

    return city;
  } catch (e) {
    debugPrint("❌ City fetch error: $e");
    return "Unknown";
  }
}
