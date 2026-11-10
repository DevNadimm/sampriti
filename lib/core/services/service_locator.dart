import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dio_service.dart';
import 'package:sampriti/core/config/api_endpoints.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await _registerCore();
}

Future<void> _registerCore() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  sl.registerSingletonAsync<DioService>(() async {
    final service = DioService();
    await service.initAuthToken();
    return service;
  });
  sl.registerLazySingleton(() => ApiEndpoints());
}

/// Usage inside Repository:
/// final DioService _dio = getIt<DioService>();
/// ? The same instance will always be used across the app.

/// When login succeeds and the token is set, all repositories will use it:
/// getIt<DioService>().setAuthToken(token);
/// ? Set once, automatically applied everywhere.

/// On logout:
/// getIt<DioService>().clearAuthToken();
/// ? Removes the Authorization header for all future requests.
