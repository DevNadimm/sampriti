import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/office_bearers/data/models/office_bearer_model.dart';

class OfficeBearerRepo {
  static final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'office_bearers';

  /// Current first, then by post order.
  static Future<List<OfficeBearerModel>> getAll() async {
    try {
      final snap = await _firestore.collection(_collection).get();
      final list = snap.docs.map((d) => OfficeBearerModel.fromFirestore(d)).toList();
      list.sort((a, b) {
        if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
        final pa = kOfficePosts.indexOf(a.post);
        final pb = kOfficePosts.indexOf(b.post);
        return (pa < 0 ? 999 : pa).compareTo(pb < 0 ? 999 : pb);
      });
      return list;
    } catch (e) {
      throw ApiException(message: 'দায়িত্বশীলদের তালিকা লোড করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Admin only. Creates a new record, or updates by id.
  static Future<void> save(OfficeBearerModel b) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'দায়িত্বশীল তথ্য পরিবর্তনের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }
    if (b.name.trim().isEmpty && b.memberNo.trim().isEmpty) {
      throw ApiException(message: 'সদস্য নির্বাচন করুন অথবা নাম লিখুন');
    }
    try {
      final data = b.toMap();
      if (b.id.isEmpty) {
        await _firestore.collection(_collection).add(data);
      } else {
        await _firestore.collection(_collection).doc(b.id).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      throw ApiException(message: 'দায়িত্বশীল তথ্য সংরক্ষণ করা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Admin only.
  static Future<void> delete(String id) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'মুছে ফেলার অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw ApiException(message: 'মুছে ফেলা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }
}
