import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/public_data.dart';

abstract interface class SnapshotCache {
  Future<PublicSnapshot?> read();
  Future<void> write(PublicSnapshot snapshot);
}

class PreferencesSnapshotCache implements SnapshotCache {
  PreferencesSnapshotCache(this.preferences, this.namespace);
  final SharedPreferences preferences;
  final String namespace;
  String get _key => 'waveguard.snapshot.v1.$namespace';
  @override
  Future<PublicSnapshot?> read() async {
    try {
      final value = preferences.getString(_key);
      return value == null
          ? null
          : PublicSnapshot.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(PublicSnapshot snapshot) async {
    if (!await preferences.setString(_key, jsonEncode(snapshot.toJson()))) {
      throw StateError('Cache write failed');
    }
  }
}
