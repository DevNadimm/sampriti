import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/announcements/data/models/announcement_model.dart';

/// Each announcement is stored as its own document in `announcements`.
class AnnouncementRepo {
  static final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'announcements';

  /// Live stream of announcements, newest first. Updates arrive automatically
  /// whenever the database changes, so admin and shareholder views stay in sync.
  static Stream<List<AnnouncementModel>> watchAnnouncements() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AnnouncementModel.fromFirestore).toList());
  }

  /// Creates a new announcement, or updates an existing one by id. Admin only.
  static Future<void> saveAnnouncement(AnnouncementModel item) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'ঘোষণা সংরক্ষণের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }
    final isNew = item.id.isEmpty;
    try {
      final data = item.toMap(isNew: isNew);
      if (isNew) {
        await _firestore.collection(_collection).add(data);
      } else {
        await _firestore.collection(_collection).doc(item.id).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      throw ApiException(message: 'ঘোষণা সংরক্ষণ করা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Admin only.
  static Future<void> deleteAnnouncement(String id) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'ঘোষণা মুছে ফেলার অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw ApiException(message: 'ঘোষণা মুছে ফেলা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }
}
