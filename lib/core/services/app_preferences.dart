import 'package:sampriti/core/config/preference_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sampriti/core/utils/enums/subscription_gate_type.dart';

class AppPreferences {
  AppPreferences._();

  /// Access Token
  static Future<String> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.accessToken) ?? '';
  }

  static Future<void> setAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.accessToken, token);
  }

  static Future<void> removeAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PreferenceKeys.accessToken);
  }

  /// Remember Me
  static Future<bool> isRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PreferenceKeys.isRememberMe) ?? false;
  }

  static Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.isRememberMe, value);
  }

  /// First Time User
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PreferenceKeys.isFirstTime) ?? true;
  }

  static Future<void> setFirstTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.isFirstTime, value);
  }

  /// User Role
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userRole) ?? '';
  }

  static Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.userRole, role);
  }

  /// Member No (for Shareholder)
  static Future<String> getMemberNo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.memberNo) ?? '';
  }

  static Future<void> setMemberNo(String no) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.memberNo, no);
  }

  /// User Name
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userName) ?? 'User';
  }

  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.userName, name);
  }

  /// User ID
  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PreferenceKeys.userId) ?? 0;
  }

  static Future<void> setUserId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PreferenceKeys.userId, id);
  }

  /// User Email
  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userEmail) ?? '';
  }

  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.userEmail, email);
  }

  /// User Phone
  static Future<String> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userPhone) ?? '';
  }

  static Future<void> setUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.userPhone, phone);
  }

  /// User Address
  static Future<String> getUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userAddress) ?? '';
  }

  static Future<void> setUserAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.userAddress, address);
  }

  /// User Photo
  static Future<String> getUserPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userPhoto) ?? '';
  }

  static Future<void> setUserPhoto(String photo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.userPhoto, photo);
  }

  // ---------------------------------------------
  // Subscription
  // ---------------------------------------------

  /// Subscription Plan ID
  static Future<int> getSubscriptionPlanId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PreferenceKeys.subscriptionPlanId) ?? 0;
  }

  static Future<void> setSubscriptionPlanId(int planId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PreferenceKeys.subscriptionPlanId, planId);
  }

  /// Subscription Plan Name (e.g. "Starter", "Pro", "Pro Yearly")
  static Future<String> getSubscriptionPlanName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.subscriptionPlanName) ?? '';
  }

  static Future<void> setSubscriptionPlanName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.subscriptionPlanName, name);
  }

  /// Subscription Status: "active", "expired", "trial", "cancelled", or "none"
  static Future<String> getSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.subscriptionStatus) ?? 'none';
  }

  static Future<void> setSubscriptionStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.subscriptionStatus, status);
  }

  /// Subscription Start Date
  static Future<String?> getSubscriptionStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.subscriptionStartDate);
  }

  static Future<void> setSubscriptionStartDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.subscriptionStartDate, date);
  }

  /// Subscription Expiry Date
  static Future<String?> getSubscriptionExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.subscriptionExpiryDate);
  }

  static Future<void> setSubscriptionExpiryDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.subscriptionExpiryDate, date);
  }

  /// Determines the current subscription gate state.
  static Future<SubscriptionGateType> getGateType() async {
    final status = await getSubscriptionStatus();
    final expiry = await getSubscriptionExpiryDate();

    if (status == 'none') return SubscriptionGateType.none;

    if (status == 'pending_verification') {
      return SubscriptionGateType.pending;
    }

    if (status == 'expired') return SubscriptionGateType.expired;

    if (status == 'cancelled') return SubscriptionGateType.cancelled;

    if (expiry == null) {
      setSubscriptionStatus('expired');
      return SubscriptionGateType.expired;
    }

    final isValid = DateTime.parse(expiry).isAfter(DateTime.now());

    if (!isValid) {
      setSubscriptionStatus('expired');
      return SubscriptionGateType.expired;
    }

    return SubscriptionGateType.ok;
  }

  /// Saves all subscription fields in one call � call this right after a
  /// successful subscribe/renew API response.
  static Future<void> saveSubscription({
    required int planId,
    required String planName,
    required String startDate,
    required String expiryDate,
    String status = 'active',
  }) async {
    await setSubscriptionPlanId(planId);
    await setSubscriptionPlanName(planName);
    await setSubscriptionStartDate(startDate);
    await setSubscriptionExpiryDate(expiryDate);
    await setSubscriptionStatus(status);
  }

  /// Clears only subscription-related data (e.g. on plan cancellation or
  /// downgrade), leaving auth/profile data untouched.
  static Future<void> clearSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PreferenceKeys.subscriptionPlanId);
    await prefs.remove(PreferenceKeys.subscriptionPlanName);
    await prefs.remove(PreferenceKeys.subscriptionStartDate);
    await prefs.remove(PreferenceKeys.subscriptionExpiryDate);
    await prefs.remove(PreferenceKeys.subscriptionStatus);
  }

  /// Clear all preferences (e.g., on logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}