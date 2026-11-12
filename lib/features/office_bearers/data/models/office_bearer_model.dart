import 'package:cloud_firestore/cloud_firestore.dart';

/// Posts shown in the dropdown. Keep in sync with the committee structure.
const List<String> kOfficePosts = [
  'সভাপতি',
  'সহ-সভাপতি',
  'সাধারণ সম্পাদক',
  'যুগ্ম সাধারণ সম্পাদক',
  'অর্থ সম্পাদক',
  'সাংগঠনিক সম্পাদক',
  'সদস্য',
];

/// One office-bearer record. Stored in Firestore collection `office_bearers`.
class OfficeBearerModel {
  final String id;
  final String post; // পদ
  final String memberNo; // সদস্য (optional, from members list)
  final String name; // নাম (used when not a member, or as override)
  final String termStart; // মেয়াদ শুরু (free text: year or date)
  final String termEnd; // মেয়াদ শেষ; '' = বর্তমান
  final String remark; // মন্তব্য
  final String createdAt;
  final String updatedAt;

  const OfficeBearerModel({
    this.id = '',
    required this.post,
    this.memberNo = '',
    this.name = '',
    this.termStart = '',
    this.termEnd = '',
    this.remark = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  bool get isCurrent => termEnd.trim().isEmpty;

  String get termLabel {
    final s = termStart.trim();
    final e = termEnd.trim();
    if (s.isEmpty && e.isEmpty) return '—';
    return '${s.isEmpty ? '—' : s} – ${e.isEmpty ? 'বর্তমান' : e}';
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();
    return {
      'post': post,
      'memberNo': memberNo.trim(),
      'name': name.trim(),
      'termStart': termStart.trim(),
      'termEnd': termEnd.trim(),
      'remark': remark.trim(),
      'createdAt': createdAt.isNotEmpty ? createdAt : now,
      'updatedAt': now,
      'schema': 1,
    };
  }

  factory OfficeBearerModel.fromMap(Map<String, dynamic> m, [String? docId]) => OfficeBearerModel(
        id: docId ?? (m['id'] as String?) ?? '',
        post: (m['post'] as String?) ?? '',
        memberNo: (m['memberNo'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        termStart: (m['termStart'] as String?) ?? '',
        termEnd: (m['termEnd'] as String?) ?? '',
        remark: (m['remark'] as String?) ?? '',
        createdAt: (m['createdAt'] as String?) ?? '',
        updatedAt: (m['updatedAt'] as String?) ?? '',
      );

  factory OfficeBearerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OfficeBearerModel.fromMap(data, doc.id);
  }
}
