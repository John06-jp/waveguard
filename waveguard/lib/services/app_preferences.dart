import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences([this.storage]) {
    imperial = storage?.getBool('units.imperial') ?? false;
    alerts = storage?.getBool('alerts.preference') ?? false;
    onboardingComplete = storage?.getBool('onboarding.v2.complete') ?? false;
  }
  final SharedPreferences? storage;
  bool imperial = false, alerts = false, onboardingComplete = false;
  String? saveError;
  String get lengthUnit => imperial ? 'ft' : 'm';
  String height(double? value) => value == null
      ? 'Unavailable'
      : '${(imperial ? value * 3.28084 : value).toStringAsFixed(2)} $lengthUnit';
  String wind(double value) =>
      '${(imperial ? value / 1.609344 : value).toStringAsFixed(0)} ${imperial ? 'mph' : 'km/h'}';
  Future<void> _save(String key, bool value) async {
    saveError = null;
    try {
      if (storage != null && !await storage!.setBool(key, value)) {
        throw StateError('Storage unavailable');
      }
    } catch (_) {
      saveError = 'Your preference could not be saved for the next visit.';
    }
    notifyListeners();
  }

  Future<void> setImperial(bool value) async {
    imperial = value;
    notifyListeners();
    await _save('units.imperial', value);
  }

  Future<void> setAlerts(bool value) async {
    alerts = value;
    notifyListeners();
    await _save('alerts.preference', value);
  }

  Future<void> finishOnboarding() async {
    onboardingComplete = true;
    notifyListeners();
    await _save('onboarding.v2.complete', true);
  }
}
