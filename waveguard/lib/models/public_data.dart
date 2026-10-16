enum AdvisoryLevel { safe, caution, dangerous }

enum UserRole { user, mdrrmo, admin }

class UserProfile {
  const UserProfile(this.id, this.email, this.role);
  final String id, email;
  final UserRole role;
}

class RegionalAdvisory {
  const RegionalAdvisory({
    required this.level,
    required this.recommendation,
    required this.updatedAt,
    required this.waveHeight,
    required this.windSpeed,
    required this.wavePeriod,
  });
  final AdvisoryLevel level;
  final String recommendation;
  final DateTime updatedAt;
  final double waveHeight, windSpeed, wavePeriod;
  factory RegionalAdvisory.fromJson(Map<String, dynamic> j) => RegionalAdvisory(
    level: AdvisoryLevel.values.byName(j['status'] as String),
    recommendation: j['recommendation'] as String,
    updatedAt: DateTime.parse(j['updatedAt'] as String).toUtc(),
    waveHeight: (j['waveHeight'] as num).toDouble(),
    windSpeed: (j['windSpeed'] as num).toDouble(),
    wavePeriod: (j['wavePeriod'] as num).toDouble(),
  );
  Map<String, dynamic> toJson() => {
    'status': level.name,
    'recommendation': recommendation,
    'updatedAt': updatedAt.toIso8601String(),
    'waveHeight': waveHeight,
    'windSpeed': windSpeed,
    'wavePeriod': wavePeriod,
  };
}

class Beach {
  const Beach({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.hasCantil,
  });
  final String id, name, description;
  final double latitude, longitude;
  final bool hasCantil;
  factory Beach.fromJson(Map<String, dynamic> j) => Beach(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String,
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    hasCantil: j['hasCantil'] as bool,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'hasCantil': hasCantil,
  };
}

class Incident {
  const Incident({
    required this.id,
    required this.beachId,
    required this.type,
    required this.summary,
    required this.date,
    this.latitude,
    this.longitude,
  });
  final String id, beachId, type, summary;
  final DateTime date;
  final double? latitude, longitude;
  factory Incident.fromJson(Map<String, dynamic> j) => Incident(
    id: j['id'] as String,
    beachId: j['beachId'] as String,
    type: j['type'] as String,
    summary: j['summary'] as String,
    date: DateTime.parse(j['date'] as String).toUtc(),
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'beachId': beachId,
    'type': type,
    'summary': summary,
    'date': date.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };
}

class StatusHistoryEntry {
  const StatusHistoryEntry(this.level, this.timestamp);
  final AdvisoryLevel level;
  final DateTime timestamp;
  factory StatusHistoryEntry.fromJson(Map<String, dynamic> j) =>
      StatusHistoryEntry(
        AdvisoryLevel.values.byName(j['status'] as String),
        DateTime.parse(j['timestamp'] as String).toUtc(),
      );
  Map<String, dynamic> toJson() => {
    'status': level.name,
    'timestamp': timestamp.toIso8601String(),
  };
}

class PublicSnapshot {
  const PublicSnapshot({
    required this.advisory,
    required this.beaches,
    required this.incidents,
    required this.history,
    required this.fetchedAt,
    required this.isDemo,
  });
  final RegionalAdvisory? advisory;
  final List<Beach> beaches;
  final List<Incident> incidents;
  final List<StatusHistoryEntry> history;
  final DateTime fetchedAt;
  final bool isDemo;
  factory PublicSnapshot.fromJson(Map<String, dynamic> j) => PublicSnapshot(
    advisory: j['advisory'] == null
        ? null
        : RegionalAdvisory.fromJson(
            Map<String, dynamic>.from(j['advisory'] as Map),
          ),
    beaches: (j['beaches'] as List)
        .map((e) => Beach.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    incidents: (j['incidents'] as List)
        .map((e) => Incident.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    history: (j['history'] as List)
        .map(
          (e) =>
              StatusHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    fetchedAt: DateTime.parse(j['fetchedAt'] as String).toUtc(),
    isDemo: j['isDemo'] as bool,
  );
  Map<String, dynamic> toJson() => {
    'advisory': advisory?.toJson(),
    'beaches': beaches.map((e) => e.toJson()).toList(),
    'incidents': incidents.map((e) => e.toJson()).toList(),
    'history': history.map((e) => e.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
    'isDemo': isDemo,
  };
}
