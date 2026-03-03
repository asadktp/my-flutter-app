import 'package:cloud_firestore/cloud_firestore.dart';

class SalaryPaymentModel {
  final String id;
  final String organizationId;
  final String teacherId;
  final String teacherName;
  final double defaultSalary;
  final double paidAmount;
  final DateTime paymentDate;
  final String month; // e.g. "March 2026"
  final String? note;
  final String paymentMode; // Cash / Online / UPI / Check
  final DateTime createdAt;
  final String createdBy;

  SalaryPaymentModel({
    required this.id,
    required this.organizationId,
    required this.teacherId,
    required this.teacherName,
    required this.defaultSalary,
    required this.paidAmount,
    required this.paymentDate,
    required this.month,
    this.note,
    this.paymentMode = 'Cash',
    required this.createdAt,
    required this.createdBy,
  });

  factory SalaryPaymentModel.fromJson(Map<String, dynamic> json, String id) {
    return SalaryPaymentModel(
      id: id,
      organizationId: json['organizationId'] ?? '',
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      defaultSalary: (json['defaultSalary'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      paymentDate: (json['paymentDate'] as Timestamp).toDate(),
      month: json['month'] ?? '',
      note: json['note'],
      paymentMode: json['paymentMode'] ?? 'Cash',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'defaultSalary': defaultSalary,
      'paidAmount': paidAmount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'month': month,
      'note': note,
      'paymentMode': paymentMode,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
