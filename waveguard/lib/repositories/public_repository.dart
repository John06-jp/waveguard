import '../models/public_data.dart';

abstract interface class PublicRepository {
  bool get isDemo;
  Future<PublicSnapshot> fetch();
}

class RepositoryFailure implements Exception {
  const RepositoryFailure(this.message, {this.offline = false});
  final String message;
  final bool offline;
}

/// Fictional fixtures for UI review, never operational safety information.
class DemoPublicRepository implements PublicRepository {
  @override
  bool get isDemo => true;
  @override
  Future<PublicSnapshot> fetch() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now().toUtc();
    return PublicSnapshot(
      advisory: RegionalAdvisory(
        level: AdvisoryLevel.caution,
        recommendation:
            'Sample recommendation: postpone swimming when waves are rough. Follow local authorities.',
        updatedAt: now.subtract(const Duration(minutes: 12)),
        waveHeight: 1.6,
        windSpeed: 18,
        wavePeriod: 7.2,
      ),
      beaches: const [
        Beach(
          id: 'demo-north',
          name: 'North shore (sample)',
          description:
              'Fictional beach for previewing advisories and sudden-drop warnings. Location and warning are unverified.',
          latitude: 8.647,
          longitude: 126.101,
          hasCantil: true,
        ),
        Beach(
          id: 'demo-bay',
          name: 'Bay beach (sample)',
          description:
              'Fictional beach for interface review. The absence of a cantil flag is not a safety assessment.',
          latitude: 8.623,
          longitude: 126.101,
          hasCantil: false,
        ),
        Beach(
          id: 'demo-south',
          name: 'South shore (sample)',
          description:
              'Fictional beach entry. Replace with verified local information before use.',
          latitude: 8.599,
          longitude: 126.09,
          hasCantil: true,
        ),
      ],
      incidents: [
        Incident(
          id: 'demo-incident',
          beachId: 'demo-north',
          type: 'Training example',
          summary:
              'Fictional incident for demonstrating the interface. This is not an actual incident record.',
          date: now.subtract(const Duration(days: 2)),
          latitude: 8.646,
          longitude: 126.103,
        ),
      ],
      history: List.generate(
        25,
        (i) => StatusHistoryEntry(
          i < 6
              ? AdvisoryLevel.caution
              : i < 12
              ? AdvisoryLevel.dangerous
              : AdvisoryLevel.safe,
          now.subtract(Duration(hours: i * 3)),
        ),
      ),
      fetchedAt: now,
      isDemo: true,
    );
  }
}
