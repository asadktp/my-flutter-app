import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherModel {
  final String id;
  final String organizationId;
  final String name;
  final double defaultSalary;
  final DateTime createdAt;

  TeacherModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.defaultSalary,
    required this.createdAt,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json, String id) {
    return TeacherModel(
      id: id,
      organizationId: json['organizationId'] ?? '',
      name: json['name'] ?? '',
      defaultSalary: (json['defaultSalary'] ?? 0).toDouble(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'name': name,
      'defaultSalary': defaultSalary,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  TeacherModel copyWith({String? name, double? defaultSalary}) {
    return TeacherModel(
      id: id,
      organizationId: organizationId,
      name: name ?? this.name,
      defaultSalary: defaultSalary ?? this.defaultSalary,
      createdAt: createdAt,
    );
  }
}
