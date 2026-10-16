import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/marine_forecast.dart';
import '../repositories/marine_repository.dart';

class MarineProvider extends ChangeNotifier {
  MarineProvider(this.repository, {this.storage});
  final MarineRepository repository;
  final SharedPreferences? storage;
  MarineForecast? forecast;
  bool loading = false, saved = false, _disposed = false;
  String? error;
  String get _key => 'marine.v1.${repository.isDemo ? 'demo' : 'live'}';
  bool get outdated =>
      saved ||
      error != null ||
      (forecast != null &&
          DateTime.now().toUtc().difference(forecast!.fetchedAt) >
              const Duration(hours: 1));
  Future<void> load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    _notify();
    if (forecast == null) {
      try {
        final cached = storage?.getString(_key);
        if (cached != null) {
          final result = MarineForecast.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
          );
          if (result.isDemo == repository.isDemo) {
            forecast = result;
            saved = true;
            _notify();
          }
        }
      } catch (_) {
        /* Ignore invalid cache and request fresh information. */
      }
    }
    try {
      forecast = await repository.fetch();
      saved = false;
      try {
        await storage?.setString(_key, jsonEncode(forecast!.toJson()));
      } catch (_) {
        /* Keep fresh data in memory. */
      }
    } catch (_) {
      error = 'Marine data could not refresh. Check your connection and retry.';
    } finally {
      loading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
