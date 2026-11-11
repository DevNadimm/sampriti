import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sampriti/core/exceptions/api_exception.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/core/utils/helpers/hash_helper.dart';
import 'package:sampriti/features/auth/data/models/user_session_model.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';

class AuthRepo {
  static final _firestore = FirebaseFirestore.instance;

  /// Admin Login via Password
  /// Strictly verified against Cloud Firestore settings/org_config (adminPwHash)
  /// No hardcoded passwords, no default backdoors.
  static Future<UserSessionModel> adminLogin(String password) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      throw ApiException(message: 'পাসওয়ার্ড লিখুন');
    }

    String expectedHash = '';
    try {
      final doc = await _firestore.collection('settings').doc('org_config').get();
      if (doc.exists && doc.data()?['adminPwHash'] != null) {
        expectedHash = (doc.data()!['adminPwHash'] as String).trim();
      }
    } catch (e) {
      throw ApiException(message: 'ইন্টারনেট সংযোগ নেই বা সার্ভার সমস্যা। অনুগ্রহ করে ইন্টারনেট চেক করে আবার চেষ্টা করুন।');
    }

    if (expectedHash.isEmpty) {
      throw ApiException(
        message: 'অ্যাডমিন অ্যাকাউন্ট কনফিগার করা নেই। অনুগ্রহ করে ডাটাবেজ অ্যাডমিনের সাথে যোগাযোগ করুন।',
      );
    }

    // Compare strictly against Firestore adminPwHash
    final inputFastHash = HashHelper.fastHash(trimmed);
    final inputSha256 = HashHelper.sha256Hash(trimmed);
    final isMatch = (inputFastHash == expectedHash) || (inputSha256 == expectedHash);

    if (!isMatch) {
      throw ApiException(message: 'অ্যাডমিন পাসওয়ার্ড ভুল হয়েছে');
    }

    await AppPreferences.setUserRole('admin');
    await AppPreferences.setMemberNo('');

    return const UserSessionModel(
      role: UserRole.admin,
      name: 'অ্যাডমিন',
    );
  }

  /// Change Admin Password (Requires current password & high validation)
  static Future<void> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentTrimmed = currentPassword.trim();
    final newTrimmed = newPassword.trim();

    if (currentTrimmed.isEmpty || newTrimmed.isEmpty) {
      throw ApiException(message: 'বর্তমান ও নতুন উভয় পাসওয়ার্ড প্রদান করুন');
    }

    // 1. Verify current password directly from Firestore
    String expectedHash = '';
    try {
      final doc = await _firestore.collection('settings').doc('org_config').get();
      if (doc.exists && doc.data()?['adminPwHash'] != null) {
        expectedHash = (doc.data()!['adminPwHash'] as String).trim();
      }
    } catch (_) {
      throw ApiException(message: 'ইন্টারনেট সংযোগ নেই বা সার্ভারে সমস্যা হয়েছে');
    }

    if (expectedHash.isEmpty) {
      throw ApiException(
        message: 'ডাটাবেজে কোনো সংরক্ষিত অ্যাডমিন পাসওয়ার্ড পাওয়া যায়নি।',
      );
    }

    final isCurrentMatch = (HashHelper.fastHash(currentTrimmed) == expectedHash) ||
        (HashHelper.sha256Hash(currentTrimmed) == expectedHash);

    if (!isCurrentMatch) {
      throw ApiException(message: 'বর্তমান পাসওয়ার্ডটি সঠিক নয়');
    }

    // 2. High validation on new password
    if (newTrimmed.length < 8) {
      throw ApiException(message: 'নতুন পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে');
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(newTrimmed);
    final hasLower = RegExp(r'[a-z]').hasMatch(newTrimmed);
    final hasDigit = RegExp(r'[0-9]').hasMatch(newTrimmed);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(newTrimmed);

    if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
      throw ApiException(
        message: 'পাসওয়ার্ডে অবশ্যই বড় হাতের অক্ষর (A-Z), ছোট হাতের অক্ষর (a-z), সংখ্যা (0-9) এবং বিশেষ চিহ্ন (!@# ইত্যাদি) থাকতে হবে',
      );
    }

    // 3. Save new hashed password to Firestore
    try {
      final newHash = HashHelper.fastHash(newTrimmed);
      await _firestore.collection('settings').doc('org_config').set({
        'adminPwHash': newHash,
      }, SetOptions(merge: true));
    } catch (e) {
      throw ApiException(message: 'পাসওয়ার্ড সংরক্ষণ ব্যর্থ হয়েছে: ইন্টারনেট সংযোগ চেক করুন');
    }
  }

  /// Shareholder Login via Share No + 4-6 digit PIN
  static Future<UserSessionModel> shareholderLogin({
    required String shareNo,
    required String pin,
  }) async {
    final cleanNo = shareNo.trim().toUpperCase();
    final cleanPin = pin.trim();

    if (cleanNo.isEmpty || cleanPin.isEmpty) {
      throw ApiException(message: 'শেয়ার নম্বর ও পিন উভয়ই লিখুন');
    }

    MemberModel? member;

    // 1. Fetch from Firestore
    try {
      final doc = await _firestore.collection('members').doc(cleanNo).get();
      if (doc.exists) {
        member = MemberModel.fromFirestore(doc);
      }
    } catch (e) {
      throw ApiException(message: 'ইন্টারনেট সংযোগ নেই বা সার্ভারে সমস্যা হয়েছে। অনুগ্রহ করে ইন্টারনেট চেক করুন।');
    }

    if (member == null) {
      throw ApiException(message: 'শেয়ার নং ($cleanNo) পাওয়া যায়নি');
    }

    // 2. Verify PIN
    if (member.pin != null && member.pin!.isNotEmpty) {
      final expectedHash = HashHelper.fastHash('$cleanNo|$cleanPin');
      final isPinMatch = (member.pin == expectedHash);

      if (!isPinMatch) {
        throw ApiException(message: 'শেয়ার নম্বর বা পিন ভুল হয়েছে');
      }
    } else {
      throw ApiException(
        message: 'আপনার অ্যাকাউন্টে লগইন পিন সেট করা নেই। অনুগ্রহ করে অ্যাডমিনের সাথে যোগাযোগ করে আপনার পিন সংগ্রহ করুন।',
      );
    }

    await AppPreferences.setUserRole('shareholder');
    await AppPreferences.setMemberNo(member.no);
    await AppPreferences.setUserName(member.displayName);
    await AppPreferences.setUserPhoto(member.photo ?? '');

    return UserSessionModel(
      role: UserRole.shareholder,
      memberNo: member.no,
      name: member.displayName,
      photoUrl: member.photo,
    );
  }

  /// Check existing session on Splash
  static Future<UserSessionModel?> checkSession() async {
    final role = await AppPreferences.getUserRole();
    if (role == 'admin') {
      return const UserSessionModel(
        role: UserRole.admin,
        name: 'অ্যাডমিন',
      );
    } else if (role == 'shareholder') {
      final memberNo = await AppPreferences.getMemberNo();
      final name = await AppPreferences.getUserName();
      final photo = await AppPreferences.getUserPhoto();
      if (memberNo.isNotEmpty) {
        return UserSessionModel(
          role: UserRole.shareholder,
          memberNo: memberNo,
          name: name.isNotEmpty ? name : memberNo,
          photoUrl: photo.isNotEmpty ? photo : null,
        );
      }
    }
    return null;
  }

  /// Logout
  static Future<void> logout() async {
    await AppPreferences.setUserRole('');
    await AppPreferences.setMemberNo('');
    await AppPreferences.setUserPhoto('');
  }
}
