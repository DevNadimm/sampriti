// import 'package:in_app_update/in_app_update.dart';
// import 'package:flutter/material.dart';
//
// class AppUpdateService {
//   static Future<void> checkForUpdate(BuildContext context) async {
//     try {
//       final info = await InAppUpdate.checkForUpdate();
//
//       await Future.delayed(const Duration(seconds: 2));
//
//       if (info.updateAvailability == UpdateAvailability.updateAvailable) {
//
//         // ✅ Flexible update (non-critical)
//         await InAppUpdate.startFlexibleUpdate();
//         await InAppUpdate.completeFlexibleUpdate();
//
//         // ⚠️ OR Immediate update (critical)
//         await InAppUpdate.performImmediateUpdate();
//
//         debugPrint("✅ Update completed successfully!");
//       } else {
//         debugPrint("ℹ️ No update available.");
//       }
//     } catch (e) {
//       debugPrint("❌ Failed to check for update: $e");
//     }
//   }
// }
