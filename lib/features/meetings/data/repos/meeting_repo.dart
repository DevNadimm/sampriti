import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/features/meetings/data/models/meeting_model.dart';

/// Each meeting is stored as its own document in `meetings`.
class MeetingRepo {
  static final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'meetings';

  /// Newest meeting first.
  static Future<List<MeetingModel>> getMeetings() async {
    try {
      final snap = await _firestore.collection(_collection).orderBy('date', descending: true).get();
      return snap.docs.map((d) => MeetingModel.fromFirestore(d)).toList();
    } catch (e) {
      throw ApiException(message: 'সভার তালিকা লোড করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Creates a new meeting, or updates an existing one by id. Admin only.
  static Future<void> saveMeeting(MeetingModel meeting) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'সভার তথ্য সংরক্ষণের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }
    try {
      final data = meeting.toMap();
      if (meeting.id.isEmpty) {
        await _firestore.collection(_collection).add(data);
      } else {
        await _firestore.collection(_collection).doc(meeting.id).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      throw ApiException(message: 'সভার তথ্য সংরক্ষণ করা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Admin only.
  static Future<void> deleteMeeting(String id) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'সভা মুছে ফেলার অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw ApiException(message: 'সভা মুছে ফেলা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }
}
