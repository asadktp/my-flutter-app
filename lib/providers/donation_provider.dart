import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation_model.dart';
import '../models/user_model.dart';

class DonationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DonationModel> _donations = [];
  List<DonationModel> get donations => _donations;

  UserModel? _activeUser;

  // Called to update the scoped parameters bridging Auth config
  void updateAuth(UserModel? user) {
    if (_activeUser?.id != user?.id ||
        _activeUser?.organizationId != user?.organizationId) {
      _activeUser = user;
      _listenToDonations();
    }
  }

  void _listenToDonations() {
    if (_activeUser == null || _activeUser!.organizationId == null) {
      _donations = [];
      notifyListeners();
      return;
    }

    Query query = _firestore
        .collection('donations')
        .where('organizationId', isEqualTo: _activeUser!.organizationId);

    // If collector, only see their own mappings
    if (_activeUser!.role == 'collector') {
      query = query.where('collectorId', isEqualTo: _activeUser!.id);
    }

    query.snapshots().listen((snapshot) {
      _donations = snapshot.docs
          .map(
            (doc) => DonationModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // Enforce client-side sorting as composite index might be missing initially
      _donations.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    });
  }

  List<DonationModel> getDonationsByCollector(String collectorId) {
    return donations.where((d) => d.collectorId == collectorId).toList();
  }

  // Stats
  double get todayCollection {
    final now = DateTime.now();
    return donations
        .where(
          (d) =>
              d.date.year == now.year &&
              d.date.month == now.month &&
              d.date.day == now.day,
        )
        .fold(0.0, (acc, item) => acc + item.amount);
  }

  double get thisMonthCollection {
    final now = DateTime.now();
    return donations
        .where((d) => d.date.year == now.year && d.date.month == now.month)
        .fold(0.0, (acc, item) => acc + item.amount);
  }

  double get thisYearCollection {
    final now = DateTime.now();
    return donations
        .where((d) => d.date.year == now.year)
        .fold(0.0, (acc, item) => acc + item.amount);
  }

  double get totalCollection {
    return donations.fold(0.0, (acc, item) => acc + item.amount);
  }

  int get uniqueDonorsCount {
    return donations
        .map(
          (d) => '${d.donorName.trim().toLowerCase()}_${d.donorMobile.trim()}',
        )
        .toSet()
        .length;
  }

  // CRUD
  Future<void> addDonation(DonationModel donation) async {
    // Force collector role for security rules compliance
    if (_activeUser?.role != 'collector') {
      throw Exception('Only collectors can create donations');
    }

    final newDonation = DonationModel(
      id: donation.id,
      organizationId: donation.organizationId,
      collectorId: donation.collectorId,
      createdByRole: 'collector',
      donorName: donation.donorName,
      donorMobile: donation.donorMobile,
      amount: donation.amount,
      paymentMode: donation.paymentMode,
      donationType: donation.donationType,
      date: donation.date,
      receiptNo: donation.receiptNo,
      createdAt: DateTime.now(),
      email: donation.email,
      address: donation.address,
      collectorName: donation.collectorName,
      organizationName: donation.organizationName,
    );

    final batch = _firestore.batch();
    final donationRef = _firestore.collection('donations').doc(newDonation.id);
    final orgRef = _firestore
        .collection('organizations')
        .doc(newDonation.organizationId);

    batch.set(donationRef, newDonation.toJson());
    batch.update(orgRef, {
      'totalCollection': FieldValue.increment(newDonation.amount),
      'donationsCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Disable update/delete as per core rules
  Future<void> updateDonation(DonationModel donation) async {
    throw Exception('Updating donations is disabled for security.');
  }

  Future<void> deleteDonation(String id) async {
    throw Exception('Deleting donations is disabled for security.');
  }

  // Filter & Search
  List<DonationModel> searchByMobile(String query) {
    if (query.isEmpty) return donations;
    return donations.where((d) => d.donorMobile.contains(query)).toList();
  }

  List<DonationModel> searchByName(String query) {
    if (query.isEmpty) return donations;
    return donations
        .where((d) => d.donorName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
