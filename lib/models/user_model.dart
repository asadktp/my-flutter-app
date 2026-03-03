import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String role;
  String? organizationId;
  String fullName;
  String mobile;
  String? email;
  String? governmentIdNumber;
  String? designation;
  String? address;
  String status; // 'active' | 'blocked'
  String? profileImageUrl; // mutable — updated after image upload
  final DateTime createdAt;

  final String? username;
  final String? organizationName;

  UserModel({
    required this.id,
    required this.role,
    this.organizationId,
    required this.fullName,
    required this.mobile,
    this.email,
    this.governmentIdNumber,
    this.designation,
    this.address,
    this.status = 'active',
    this.profileImageUrl,
    required this.createdAt,
    this.username,
    this.organizationName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      role: json['role'] ?? 'collector',
      organizationId: json['organizationId'],
      fullName: json['fullName'] ?? json['name'] ?? '',
      mobile: json['mobile'] ?? json['mobileNumber'] ?? '',
      email: json['email'],
      governmentIdNumber: json['governmentIdNumber'],
      designation: json['designation'],
      address: json['address'],
      status:
          json['status'] ??
          (json['isDeleted'] == true
              ? 'blocked'
              : (json['isBlocked'] == true ? 'blocked' : 'active')),
      profileImageUrl: json['profileImageUrl'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      username: json['username'],
      organizationName: json['organizationName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'organizationId': organizationId,
      'fullName': fullName,
      'name': fullName,
      'mobile': mobile,
      'email': email,
      'governmentIdNumber': governmentIdNumber,
      'designation': designation,
      'address': address,
      'status': status,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'username': username,
      'organizationName': organizationName,
    };
  }

  String get name => fullName;
}
