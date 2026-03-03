import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String organizationId;
  final String collectorId;
  final String createdByRole;
  final String donorName;
  final String donorMobile;
  final double amount;
  final String paymentMode;
  final String? donationType;
  final DateTime date;
  final String receiptNo;
  final DateTime createdAt;

  // Kept for backward compatibility or display
  final String? email;
  final String? address;
  final String? collectorName;
  final String? organizationName;

  DonationModel({
    required this.id,
    required this.organizationId,
    required this.collectorId,
    this.createdByRole = 'collector',
    required this.donorName,
    required this.donorMobile,
    required this.amount,
    required this.paymentMode,
    this.donationType,
    required this.date,
    required this.receiptNo,
    required this.createdAt,
    this.email,
    this.address,
    this.collectorName,
    this.organizationName,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json, String id) {
    return DonationModel(
      id: id,
      organizationId: json['organizationId'] ?? '',
      collectorId: json['collectorId'] ?? '',
      createdByRole: json['createdByRole'] ?? 'collector',
      donorName: json['donorName'] ?? '',
      donorMobile: json['donorMobile'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMode: json['paymentMode'] ?? '',
      donationType: json['donationType'],
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      receiptNo: json['receiptNumber'] ?? json['receiptNo'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      email: json['email'],
      address: json['address'],
      collectorName: json['collectorName'],
      organizationName: json['organizationName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'collectorId': collectorId,
      'createdByRole': createdByRole,
      'donorName': donorName,
      'donorMobile': donorMobile,
      'amount': amount,
      'paymentMode': paymentMode,
      'donationType': donationType,
      'date': Timestamp.fromDate(date),
      'receiptNumber': receiptNo,
      'createdAt': Timestamp.fromDate(createdAt),
      'email': email,
      'address': address,
      'collectorName': collectorName,
      'organizationName': organizationName,
    };
  }
}
