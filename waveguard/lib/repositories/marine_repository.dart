import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/marine_forecast.dart';

abstract interface class MarineRepository {
  bool get isDemo;
  Future<MarineForecast> fetch();
}

class DemoMarineRepository implements MarineRepository {
  @override
  bool get isDemo => true;
  @override
  Future<MarineForecast> fetch() async {
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(now.year, now.month, now.day, now.hour);
    final hourly = List.generate(
      168,
      (i) => MarinePoint(
        start.add(Duration(hours: i)),
        .65 + .4 * math.sin(i / 8) + .15 * math.cos(i / 3),
        (68 + i % 35).toDouble(),
        7.2 + math.sin(i / 12),
      ),
    );
    final daily = List.generate(
      7,
      (i) => MarinePoint(
        start.add(Duration(days: i)),
        .9 + .3 * math.sin(i),
        (70 + i * 3).toDouble(),
        8.2 + .2 * i,
      ),
    );
    return MarineForecast(
      current: hourly.first,
      hourly: hourly,
      daily: daily,
      fetchedAt: now,
      isDemo: true,
    );
  }
}

class OpenMeteoMarineRepository implements MarineRepository {
  OpenMeteoMarineRepository({http.Client? client})
    : client = client ?? http.Client();
  final http.Client client;
  @override
  bool get isDemo => false;
  @override
  Future<MarineForecast> fetch() async {
    final uri = Uri.https('marine-api.open-meteo.com', '/v1/marine', {
      'latitude': '8.6336',
      'longitude': '126.0947',
      'current': 'wave_height,wave_direction,wave_period',
      'hourly': 'wave_height,wave_direction,wave_period',
      'daily': 'wave_height_max,wave_direction_dominant,wave_period_max',
      'forecast_days': '7',
      'timezone': 'Asia/Manila',
      'timeformat': 'unixtime',
    });
    final response = await client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('Marine service unavailable');
    }
    return parseOpenMeteo(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

MarineForecast parseOpenMeteo(Map<String, dynamic> j) {
  DateTime time(dynamic value) => DateTime.fromMillisecondsSinceEpoch(
    (value as num).toInt() * 1000,
    isUtc: true,
  );
  double? value(dynamic v) => v is num && v.isFinite ? v.toDouble() : null;
  List<MarinePoint> rows(String key, List<String> fields) {
    final block = j[key] as Map<String, dynamic>?;
    if (block == null) return [];
    final times = block['time'] as List;
    double? at(String field, int i) {
      final values = block[field] as List?;
      return values != null && i < values.length ? value(values[i]) : null;
    }

    return List.generate(
      times.length,
      (i) => MarinePoint(
        time(times[i]),
        at(fields[0], i),
        at(fields[1], i),
        at(fields[2], i),
      ),
    );
  }

  final current = j['current'] as Map<String, dynamic>?;
  return MarineForecast(
    current: current == null
        ? null
        : MarinePoint(
            time(current['time']),
            value(current['wave_height']),
            value(current['wave_direction']),
            value(current['wave_period']),
          ),
    hourly: rows('hourly', ['wave_height', 'wave_direction', 'wave_period']),
    daily: rows('daily', [
      'wave_height_max',
      'wave_direction_dominant',
      'wave_period_max',
    ]),
    fetchedAt: DateTime.now().toUtc(),
    isDemo: false,
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
  );
}
