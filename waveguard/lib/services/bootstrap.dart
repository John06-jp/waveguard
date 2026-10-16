import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/public_data_provider.dart';
import '../models/public_data.dart';
import '../repositories/public_repository.dart';
import '../repositories/firestore_public_repository.dart';
import 'app_config.dart';
import 'auth_service.dart';
import 'snapshot_cache.dart';

class AppDependencies {
  const AppDependencies({
    required this.data,
    required this.auth,
    this.startupMessage,
  });
  final PublicDataProvider data;
  final AuthService auth;
  final String? startupMessage;
}

Future<AppDependencies> bootstrap() async {
  PublicRepository repository = DemoPublicRepository();
  AuthService auth = UnconfiguredAuthService();
  String? message;
  if (AppConfig.firebaseEnabled) {
    repository = UnavailablePublicRepository();
    try {
      if ([
        AppConfig.apiKey,
        AppConfig.appId,
        AppConfig.senderId,
        AppConfig.projectId,
      ].any((e) => e.isEmpty)) {
        throw StateError('Missing Firebase configuration');
      }
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: AppConfig.apiKey,
          appId: AppConfig.appId,
          messagingSenderId: AppConfig.senderId,
          projectId: AppConfig.projectId,
        ),
      ).timeout(const Duration(seconds: 15));
      repository = FirestorePublicRepository(FirebaseFirestore.instance);
      auth = FirebaseAuthService(FirebaseAuth.instance);
    } catch (_) {
      message =
          'Online services could not start. Account access and new advisories are unavailable.';
    }
  }
  SnapshotCache cache;
  try {
    cache = PreferencesSnapshotCache(
      await SharedPreferences.getInstance(),
      repository.isDemo ? 'demo' : 'live.${AppConfig.projectId}',
    );
  } catch (_) {
    cache = _UnavailableCache();
  }
  return AppDependencies(
    data: PublicDataProvider(
      repository,
      cache,
      freshness: Duration(
        minutes: AppConfig.freshnessMinutes > 0
            ? AppConfig.freshnessMinutes
            : 60,
      ),
    ),
    auth: auth,
    startupMessage: message,
  );
}

class _UnavailableCache implements SnapshotCache {
  @override
  Future<PublicSnapshot?> read() async =>
      throw StateError('Local storage unavailable');
  @override
  Future<void> write(PublicSnapshot snapshot) async =>
      throw StateError('Local storage unavailable');
}
