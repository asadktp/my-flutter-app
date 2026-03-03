import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/organization_model.dart';

class OrganizationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OrganizationModel? _organization;
  OrganizationModel? get organization => _organization;

  String? _organizationId;

  // ── Load & stream org data from Firestore ────────────────────────────────
  void loadOrganization(String orgId) {
    if (orgId.isEmpty) return;
    if (_organizationId == orgId) return; // Already subscribed
    _organizationId = orgId;

    _firestore.collection('organizations').doc(orgId).snapshots().listen((
      snap,
    ) {
      if (snap.exists) {
        _organization = OrganizationModel.fromJson(snap.data()!, snap.id);
        notifyListeners();
      }
    });
  }

  // ── Update org fields in Firestore ────────────────────────────────────────
  Future<void> updateOrganization({
    required String name,
    required String address,
    required String contactNumber,
    required String email,
    String? registrationNumber,
    String? whatsappNumber,
    String? country,
    String? state,
    String? district,
    String? pinCode,
  }) async {
    if (_organizationId == null || _organizationId!.isEmpty) return;

    await _firestore.collection('organizations').doc(_organizationId).set({
      'name': name,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
      'registrationNumber': registrationNumber,
      'whatsappNumber': whatsappNumber,
      'country': country,
      'state': state,
      'district': district,
      'pinCode': pinCode,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Upload Logo to Firebase Storage ───────────────────────────────────────
  Future<String?> uploadLogo(Uint8List imageBytes) async {
    if (_organizationId == null || _organizationId!.isEmpty) return null;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('organizations')
          .child(_organizationId!)
          .child('branding')
          .child('logo.jpg');

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save URL to Firestore
      await _firestore.collection('organizations').doc(_organizationId).update({
        'logoUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      debugPrint('[OrganizationProvider] Image upload error: $e');
      return null;
    }
  }

  // Convenience getters (empty string if not yet loaded)
  String get orgName => _organization?.name ?? '';
  String get orgAddress => _organization?.address ?? '';
  String get orgContact => _organization?.contactNumber ?? '';
  String get orgEmail => _organization?.email ?? '';
  String get orgRegNumber => _organization?.registrationNumber ?? '';

  void clear() {
    _organization = null;
    _organizationId = null;
    notifyListeners();
  }
}
