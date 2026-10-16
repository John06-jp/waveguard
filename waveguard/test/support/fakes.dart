import 'package:waveguard/models/public_data.dart';
import 'package:waveguard/repositories/public_repository.dart';
import 'package:waveguard/services/snapshot_cache.dart';
import 'package:waveguard/services/external_actions.dart';

final testNow = DateTime.utc(2026, 10, 16, 8);
PublicSnapshot fixture({DateTime? sourceTime, bool demo = true}) =>
    PublicSnapshot(
      advisory: RegionalAdvisory(
        level: AdvisoryLevel.caution,
        recommendation: 'Sample guidance.',
        updatedAt: sourceTime ?? testNow,
        waveHeight: 1.6,
        windSpeed: 18,
        wavePeriod: 7.2,
      ),
      beaches: const [
        Beach(
          id: 'sample',
          name: 'Sample beach',
          description: 'Fictional fixture.',
          latitude: 8.62,
          longitude: 126.1,
          hasCantil: true,
        ),
      ],
      incidents: const [],
      history: [StatusHistoryEntry(AdvisoryLevel.caution, testNow)],
      fetchedAt: testNow,
      isDemo: demo,
    );

class FakeRepository implements PublicRepository {
  FakeRepository({this.demo = true});
  final bool demo;
  PublicSnapshot? result;
  RepositoryFailure? failure;
  @override
  bool get isDemo => demo;
  @override
  Future<PublicSnapshot> fetch() async {
    if (failure != null) throw failure!;
    return result ?? fixture(demo: demo);
  }
}

class MemoryCache implements SnapshotCache {
  PublicSnapshot? value;
  bool failWrites = false;
  @override
  Future<PublicSnapshot?> read() async => value;
  @override
  Future<void> write(PublicSnapshot snapshot) async {
    if (failWrites) throw StateError('Storage full');
    value = snapshot;
  }
}

class FakeExternalActions implements ExternalActions {
  final List<Uri> opened = [];
  bool succeeds = true;
  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeeds;
  }
}
