import 'package:cloud_firestore/cloud_firestore.dart';

class InstitutionIncomeModel {
  final String id;
  final String organizationId;
  final double amount;
  final String incomeCategory;
  final String? description;
  final DateTime incomeDate;
  final DateTime createdAt;
  final String createdBy; // Admin UID

  InstitutionIncomeModel({
    required this.id,
    required this.organizationId,
    required this.amount,
    required this.incomeCategory,
    this.description,
    required this.incomeDate,
    required this.createdAt,
    required this.createdBy,
  });

  factory InstitutionIncomeModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return InstitutionIncomeModel(
      id: id,
      organizationId: json['organizationId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      incomeCategory: json['incomeCategory'] ?? '',
      description: json['description'],
      incomeDate: (json['incomeDate'] as Timestamp).toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'amount': amount,
      'incomeCategory': incomeCategory,
      'description': description,
      'incomeDate': Timestamp.fromDate(incomeDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
