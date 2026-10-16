class MarinePoint {
  const MarinePoint(this.time, this.height, this.direction, this.period);
  final DateTime time;
  final double? height, direction, period;
  factory MarinePoint.fromJson(Map<String, dynamic> j) => MarinePoint(
    DateTime.parse(j['time'] as String),
    (j['height'] as num?)?.toDouble(),
    (j['direction'] as num?)?.toDouble(),
    (j['period'] as num?)?.toDouble(),
  );
  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'height': height,
    'direction': direction,
    'period': period,
  };
}

class MarineForecast {
  const MarineForecast({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.fetchedAt,
    required this.isDemo,
    this.latitude = 8.6336,
    this.longitude = 126.0947,
  });
  final MarinePoint? current;
  final List<MarinePoint> hourly, daily;
  final DateTime fetchedAt;
  final bool isDemo;
  final double latitude, longitude;
  factory MarineForecast.fromJson(Map<String, dynamic> j) => MarineForecast(
    current: j['current'] == null
        ? null
        : MarinePoint.fromJson(Map<String, dynamic>.from(j['current'] as Map)),
    hourly: (j['hourly'] as List)
        .map((e) => MarinePoint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    daily: (j['daily'] as List)
        .map((e) => MarinePoint.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    fetchedAt: DateTime.parse(j['fetchedAt'] as String),
    isDemo: j['isDemo'] as bool,
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
  );
  Map<String, dynamic> toJson() => {
    'current': current?.toJson(),
    'hourly': hourly.map((e) => e.toJson()).toList(),
    'daily': daily.map((e) => e.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
    'isDemo': isDemo,
    'latitude': latitude,
    'longitude': longitude,
  };
}
