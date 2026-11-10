// NOTE: Service account private keys should not be bundled inside client mobile apps.
// FCM notification triggers should ideally be handled via a secure backend server.
// Kept commented out to protect credentials and allow clean build across environments.

// import 'package:googleapis_auth/auth_io.dart';
// import 'package:sampriti/core/config/service_account_key.dart';
//
// class AccessTokenGenerator {
//   static Future<String> generateAccessToken() async {
//     final scopes = [
//       "https://www.googleapis.com/auth/firebase.messaging",
//     ];
//     final client = await clientViaServiceAccount(
//       ServiceAccountCredentials.fromJson(serviceAccountKey),
//       scopes,
//     );
//     final accessToken = client.credentials.accessToken.data;
//     return accessToken;
//   }
// }
