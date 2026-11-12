import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String startDate; // DB format: YYYY-MM-DD
  final double budget;
  final String status; // 'active' or 'completed'
  final List<String> memberNos; // Selected shareholder member numbers, e.g. ['S101', 'S102']
  final String createdAt;
  final String updatedAt;

  const ProjectModel({
    required this.id,
    required this.name,
    this.description = '',
    this.startDate = '',
    this.budget = 0.0,
    this.status = 'active',
    this.memberNos = const [],
    this.createdAt = '',
    this.updatedAt = '',
  });

  /// Display date in UI (dd/MM/yyyy)
  String get uiStartDate => DateFormatter.ddMMyyyy(startDate);

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  String get statusTitle => isActive ? 'চলমান' : 'সমাপ্ত';

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? startDate,
    double? budget,
    String? status,
    List<String>? memberNos,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      memberNos: memberNos ?? this.memberNos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'description': description.trim(),
        'startDate': DateFormatter.yyyyMMdd(startDate),
        'budget': budget,
        'status': status,
        'memberNos': memberNos,
        'createdAt': createdAt.isNotEmpty ? createdAt : DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

  factory ProjectModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawMembers = map['memberNos'];
    List<String> members = [];
    if (rawMembers is List) {
      members = rawMembers.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    return ProjectModel(
      id: docId ?? map['id']?.toString() ?? '',
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      startDate: (map['startDate'] ?? '').toString(),
      budget: (map['budget'] is num) ? (map['budget'] as num).toDouble() : 0.0,
      status: (map['status'] ?? 'active').toString(),
      memberNos: members,
      createdAt: (map['createdAt'] ?? '').toString(),
      updatedAt: (map['updatedAt'] ?? '').toString(),
    );
  }

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ProjectModel.fromMap(data, doc.id);
  }
}
