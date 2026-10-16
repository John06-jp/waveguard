import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waveguard/providers/marine_provider.dart';
import 'package:waveguard/repositories/marine_repository.dart';
import 'package:waveguard/services/app_preferences.dart';

void main() {
  final payload = <String, dynamic>{
    'latitude': 8.63,
    'longitude': 126.1,
    'current': {
      'time': 1792108800,
      'wave_height': .8,
      'wave_direction': 70,
      'wave_period': 8,
    },
    'hourly': {
      'time': [1792108800, 1792112400],
      'wave_height': [.8, null],
      'wave_direction': [70, 72],
      'wave_period': [8, 8.1],
    },
    'daily': {
      'time': [1792108800],
      'wave_height_max': [1.1],
      'wave_direction_dominant': [75],
      'wave_period_max': [8.5],
    },
  };
  test('marine timestamps are UTC and missing values remain unavailable', () {
    final result = parseOpenMeteo(payload);
    expect(result.current!.time.isUtc, isTrue);
    expect(result.hourly.last.height, isNull);
    expect(result.daily.single.height, 1.1);
    expect(result.isDemo, isFalse);
  });
  test(
    'live request asks for seven days and current/hourly/daily values',
    () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['forecast_days'], '7');
        expect(request.url.queryParameters['timeformat'], 'unixtime');
        expect(request.url.queryParameters['timezone'], 'Asia/Manila');
        return http.Response(jsonEncode(payload), 200);
      });
      final result = await OpenMeteoMarineRepository(client: client).fetch();
      expect(result.current!.height, .8);
      client.close();
    },
  );
  test(
    'failed live refresh restores live cache without relabeling it fresh',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await SharedPreferences.getInstance();
      await storage.setString(
        'marine.v1.live',
        jsonEncode(parseOpenMeteo(payload).toJson()),
      );
      final client = MockClient((_) async => http.Response('unavailable', 503));
      final data = MarineProvider(
        OpenMeteoMarineRepository(client: client),
        storage: storage,
      );
      await data.load();
      expect(data.forecast!.isDemo, isFalse);
      expect(data.outdated, isTrue);
      expect(data.error, isNotNull);
      data.dispose();
      client.close();
    },
  );
  test('onboarding and unit choices persist across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();
    final settings = AppPreferences(storage);
    await settings.finishOnboarding();
    await settings.setImperial(true);
    await settings.setAlerts(true);
    final restored = AppPreferences(storage);
    expect(restored.onboardingComplete, isTrue);
    expect(restored.imperial, isTrue);
    expect(restored.alerts, isTrue);
    expect(restored.height(1), '3.28 ft');
    settings.dispose();
    restored.dispose();
  });
}
