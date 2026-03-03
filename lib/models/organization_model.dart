import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationModel {
  final String id;
  final String name;
  final String address;
  final String registrationNumber;
  final String contactNumber;
  final String email;
  final String status; // 'active', 'expired', 'suspended'
  final String
  subscriptionStatus; // Legacy mapping: 'Active', 'Expired', 'Pending'
  final String subscriptionPlan; // 'Monthly', 'Yearly'
  final DateTime subscriptionStartDate;
  final DateTime subscriptionEndDate;
  final DateTime createdAt;
  final String? logoUrl;
  final String? whatsappNumber;

  // New Fields for Sync
  final String country;
  final String state;
  final String district;
  final String pinCode;
  final String adminName;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.registrationNumber,
    required this.contactNumber,
    required this.email,
    required this.status,
    required this.subscriptionStatus,
    required this.subscriptionPlan,
    required this.subscriptionStartDate,
    required this.subscriptionEndDate,
    required this.createdAt,
    this.logoUrl,
    this.whatsappNumber,
    this.country = 'India',
    this.state = '',
    this.district = '',
    this.pinCode = '',
    this.adminName = '',
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json, String id) {
    return OrganizationModel(
      id: id,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      email: json['email'] ?? '',
      status:
          json['status'] ??
          (json['subscriptionStatus'] == 'Expired' ? 'expired' : 'active'),
      subscriptionStatus: json['subscriptionStatus'] ?? 'Pending',
      subscriptionPlan: json['subscriptionPlan'] ?? 'Monthly',
      subscriptionStartDate:
          (json['subscriptionStartDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      subscriptionEndDate:
          (json['subscriptionEndDate'] as Timestamp?)?.toDate() ??
          (json['subscriptionExpiry'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      logoUrl: json['logoUrl'],
      whatsappNumber: json['whatsappNumber'],
      country: json['country'] ?? 'India',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      pinCode: json['pinCode'] ?? '',
      adminName: json['adminName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'registrationNumber': registrationNumber,
      'contactNumber': contactNumber,
      'email': email,
      'status': status,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStartDate': Timestamp.fromDate(subscriptionStartDate),
      'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'logoUrl': logoUrl,
      'whatsappNumber': whatsappNumber,
      'country': country,
      'state': state,
      'district': district,
      'pinCode': pinCode,
      'adminName': adminName,
    };
  }
}
