import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/core/utils/helpers/hash_helper.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';

class MembersRepo {
  static final _firestore = FirebaseFirestore.instance;
  static const String _collection = 'members';

  /// Fetch all members.
  /// If logged-in user is a shareholder, strictly returns ONLY their own record.
  static Future<List<MemberModel>> getMembers({bool bypassSecurity = false}) async {
    if (!bypassSecurity) {
      final role = await AppPreferences.getUserRole();
      if (role == 'shareholder') {
        final myNo = (await AppPreferences.getMemberNo()).trim().toUpperCase();
        if (myNo.isNotEmpty) {
          final me = await getMemberByNo(myNo, bypassSecurity: true);
          return me != null ? [me] : [];
        }
      }
    }

    try {
      final snap = await _firestore.collection(_collection).orderBy('no').get();
      return snap.docs.map((doc) => MemberModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ApiException(
        message: 'ইন্টারনেট সংযোগ নেই বা সদস্য তালিকা লোড করা সম্ভব হয়নি। অনুগ্রহ করে ইন্টারনেট সংযোগ চেক করে পুনরায় চেষ্টা করুন।',
      );
    }
  }

  /// Get single member by share number.
  /// Validates that shareholders can only access their own profile.
  static Future<MemberModel?> getMemberByNo(String no, {bool bypassSecurity = false}) async {
    final cleanNo = no.trim().toUpperCase();

    if (!bypassSecurity) {
      final role = await AppPreferences.getUserRole();
      if (role == 'shareholder') {
        final myNo = (await AppPreferences.getMemberNo()).trim().toUpperCase();
        if (myNo.isNotEmpty && cleanNo != myNo) {
          // Access Denied: Shareholder cannot inspect other members' details
          return null;
        }
      }
    }

    try {
      final doc = await _firestore.collection(_collection).doc(cleanNo).get();
      if (doc.exists) {
        return MemberModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw ApiException(
        message: 'ইন্টারনেট সংযোগ বিচ্ছিন্ন অথবা সদস্য তথ্য পাওয়া যায়নি।',
      );
    }
  }

  /// Add or update member (Admin Only)
  static Future<void> saveMember(MemberModel member) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'সদস্য তথ্য পরিবর্তনের অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    try {
      await _firestore
          .collection(_collection)
          .doc(member.no)
          .set(member.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw ApiException(message: 'সদস্য তথ্য সংরক্ষণ ব্যর্থ হয়েছে: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Delete member (Admin Only)
  static Future<void> deleteMember(String no) async {
    final role = await AppPreferences.getUserRole();
    if (role == 'shareholder') {
      throw ApiException(message: 'সদস্য মুছে ফেলার অনুমতি নেই (শুধুমাত্র অ্যাডমিন)');
    }

    try {
      await _firestore.collection(_collection).doc(no).delete();
    } catch (e) {
      throw ApiException(message: 'সদস্য মুছে ফেলা সম্ভব হয়নি: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Update PIN for member (Admin Only)
  static Future<void> setMemberPin(String no, String newPin) async {
    final role = await AppPreferences.getUserRole();
    if (role != 'admin') {
      throw ApiException(message: 'শুধুমাত্র অ্যাডমিন সদস্যের পিন সেট বা পরিবর্তন করতে পারেন');
    }

    final cleanNo = no.trim().toUpperCase();
    final cleanPin = newPin.trim();

    if (cleanPin.length < 4) {
      throw ApiException(message: 'পিন কমপক্ষে ৪ ডিজিটের হতে হবে');
    }

    final hash = HashHelper.fastHash('$cleanNo|$cleanPin');
    try {
      await _firestore.collection(_collection).doc(cleanNo).set({
        'pin': hash,
        'plainPin': cleanPin,
      }, SetOptions(merge: true));
    } catch (e) {
      throw ApiException(message: 'পিন আপডেট ব্যর্থ হয়েছে: ইন্টারনেট সংযোগ চেক করুন।');
    }
  }

  /// Bulk generate 4-digit PINs for all members without a PIN (or for all members if all=true)
  static Future<int> generateBulkPins({bool all = false}) async {
    final role = await AppPreferences.getUserRole();
    if (role != 'admin') {
      throw ApiException(message: 'শুধুমাত্র অ্যাডমিন বাল্ক পিন তৈরি করতে পারেন');
    }

    final members = await getMembers(bypassSecurity: true);
    final batch = _firestore.batch();
    int count = 0;
    final random = Random.secure();

    for (final m in members) {
      if (all || m.pin == null || m.pin!.isEmpty || m.plainPin == null || m.plainPin!.isEmpty) {
        // Generate secure 4-digit numeric PIN (1000 - 9999)
        final pin = (1000 + random.nextInt(9000)).toString();
        final hash = HashHelper.fastHash('${m.no}|$pin');
        final docRef = _firestore.collection(_collection).doc(m.no);
        batch.set(
          docRef,
          {
            'pin': hash,
            'plainPin': pin,
          },
          SetOptions(merge: true),
        );
        count++;
      }
    }

    if (count > 0) {
      try {
        await batch.commit();
      } catch (e) {
        throw ApiException(message: 'বাল্ক পিন সংরক্ষণ ব্যর্থ হয়েছে: ইন্টারনেট সংযোগ চেক করুন');
      }
    }

    return count;
  }

  /// Auto generate next member number (e.g. S121 if last is S120)
  static Future<String> getNextMemberNo() async {
    final members = await getMembers();
    int maxNum = 100;
    for (final m in members) {
      final digits = m.no.replaceAll(RegExp(r'[^0-9]'), '');
      final parsed = int.tryParse(digits) ?? 0;
      if (parsed > maxNum) maxNum = parsed;
    }
    return 'S${maxNum + 1}';
  }
}
