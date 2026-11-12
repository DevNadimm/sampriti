import 'package:cloud_firestore/cloud_firestore.dart';

/// One announcement document in the `announcements` collection.
class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.createdAt,
    this.updatedAt,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AnnouncementModel(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      // serverTimestamp is null until the write is confirmed by the server.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Fields written on save. `createdAt` is only set for new documents.
  Map<String, dynamic> toMap({required bool isNew}) {
    return {
      'title': title.trim(),
      'body': body.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
