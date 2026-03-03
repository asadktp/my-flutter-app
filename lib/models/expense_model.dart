import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String organizationId;
  final String collectorId;
  final String? collectorName;
  final double amount;
  final String category;
  final String? description;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String status;

  ExpenseModel({
    required this.id,
    required this.organizationId,
    required this.collectorId,
    this.collectorName,
    required this.amount,
    required this.category,
    this.description,
    required this.expenseDate,
    required this.createdAt,
    this.status = 'pending',
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json, String id) {
    return ExpenseModel(
      id: id,
      organizationId: json['organizationId'] ?? '',
      collectorId: json['collectorId'] ?? '',
      collectorName: json['collectorName'],
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      description: json['description'],
      expenseDate:
          (json['expenseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'collectorId': collectorId,
      'collectorName': collectorName,
      'amount': amount,
      'category': category,
      'description': description,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
