import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waveguard/models/public_data.dart';
import 'package:waveguard/providers/public_data_provider.dart';
import 'package:waveguard/repositories/public_repository.dart';
import 'package:waveguard/services/snapshot_cache.dart';
import 'support/fakes.dart';

void main() {
  late FakeRepository repository;
  late MemoryCache cache;
  late PublicDataProvider data;
  setUp(() {
    repository = FakeRepository();
    cache = MemoryCache();
    data = PublicDataProvider(repository, cache, clock: () => testNow);
  });
  tearDown(() => data.dispose());
  test(
    'source timestamp determines staleness after successful fetch',
    () async {
      repository.result = fixture(
        sourceTime: testNow.subtract(const Duration(hours: 2)),
      );
      await data.load();
      expect(data.outdated, isTrue);
      expect(data.snapshot!.fetchedAt, testNow);
    },
  );
  test('fresh result is saved without changing source timestamp', () async {
    await data.load();
    expect(data.outdated, isFalse);
    expect(cache.value!.advisory!.updatedAt, testNow);
  });
  test('offline cache retains advisory marked outdated', () async {
    cache.value = fixture();
    repository.failure = const RepositoryFailure(
      'No connection',
      offline: true,
    );
    await data.load();
    expect(data.snapshot!.advisory!.level, AdvisoryLevel.caution);
    expect(data.offline, isTrue);
    expect(data.outdated, isTrue);
  });
  test('offline without cache never invents an advisory', () async {
    repository.failure = const RepositoryFailure(
      'No connection',
      offline: true,
    );
    await data.load();
    expect(data.snapshot, isNull);
    expect(data.offline, isTrue);
    expect(data.error, isNotNull);
  });
  test('retry clears refresh failure after recovery', () async {
    await data.load();
    repository.failure = const RepositoryFailure('Refresh failed');
    await data.load();
    expect(data.outdated, isTrue);
    repository.failure = null;
    await data.load();
    expect(data.outdated, isFalse);
    expect(data.error, isNull);
  });
  test('storage failure does not discard successful fetch', () async {
    cache.failWrites = true;
    await data.load();
    expect(data.snapshot, isNotNull);
    expect(data.cacheWarning, isNotNull);
    expect(data.outdated, isFalse);
  });
  test('demo cache cannot appear in live mode', () async {
    final live = PublicDataProvider(
      FakeRepository(demo: false)
        ..failure = const RepositoryFailure('Offline', offline: true),
      MemoryCache()..value = fixture(),
    );
    await live.load();
    expect(live.snapshot, isNull);
    live.dispose();
  });
  test('persistent cache round trip is isolated by mode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final demo = PreferencesSnapshotCache(prefs, 'demo');
    await demo.write(fixture());
    final restored = await demo.read();
    expect(restored!.beaches.single.hasCantil, isTrue);
    expect(restored.advisory!.updatedAt, testNow);
    expect(await PreferencesSnapshotCache(prefs, 'live').read(), isNull);
  });
}
