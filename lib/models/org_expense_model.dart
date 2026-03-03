import 'package:cloud_firestore/cloud_firestore.dart';

class OrgExpenseModel {
  final String id;
  final String organizationId;
  final double amount;
  final String expenseCategory;
  final String? description;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String createdBy; // Admin UID

  OrgExpenseModel({
    required this.id,
    required this.organizationId,
    required this.amount,
    required this.expenseCategory,
    this.description,
    required this.expenseDate,
    required this.createdAt,
    required this.createdBy,
  });

  factory OrgExpenseModel.fromJson(Map<String, dynamic> json, String id) {
    return OrgExpenseModel(
      id: id,
      organizationId: json['organizationId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      expenseCategory: json['expenseCategory'] ?? '',
      description: json['description'],
      expenseDate: (json['expenseDate'] as Timestamp).toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'amount': amount,
      'expenseCategory': expenseCategory,
      'description': description,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
