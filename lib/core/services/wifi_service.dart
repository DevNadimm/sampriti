import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WifiService {
  WifiService._();

  static final WifiService instance = WifiService._();

  final NetworkInfo _networkInfo = NetworkInfo();

  /// Get current Wi-Fi SSID
  Future<String?> getWifiName() async {
    try {
      final name = await _networkInfo.getWifiName();
      return name?.replaceAll('"', '').trim();
    } catch (e) {
      debugPrint("WiFi name error: $e");
      return null;
    }
  }

  /// Get current Wi-Fi BSSID
  Future<String?> getWifiBSSID() async {
    try {
      final bssid = await _networkInfo.getWifiBSSID();
      return bssid?.toLowerCase().trim();
    } catch (e) {
      debugPrint("WiFi BSSID error: $e");
      return null;
    }
  }

  /// Wi-Fi Attendance Validation
  Future<bool> isAllowedWifi({
    required String allowedSSID,
    required String allowedBSSID,
  }) async {
    final wifiName = await getWifiName();
    final wifiBSSID = await getWifiBSSID();

    debugPrint("Current WiFi — SSID: $wifiName, BSSID: $wifiBSSID");

    return wifiName == allowedSSID && wifiBSSID == allowedBSSID.toLowerCase();
  }
}
