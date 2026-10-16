import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/public_data.dart';
import '../repositories/public_repository.dart';
import '../services/snapshot_cache.dart';

class PublicDataProvider extends ChangeNotifier {
  PublicDataProvider(
    this.repository,
    this.cache, {
    this.freshness = const Duration(hours: 1),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now {
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => notifyListeners(),
    );
  }
  final PublicRepository repository;
  final SnapshotCache cache;
  final Duration freshness;
  final DateTime Function() clock;
  Timer? _timer;
  bool _disposed = false;
  PublicSnapshot? snapshot;
  bool loading = false, offline = false, refreshFailed = false;
  String? error, cacheWarning;
  bool get isDemo => repository.isDemo;
  bool get outdated {
    final timestamp = snapshot?.advisory?.updatedAt;
    if (timestamp == null) return false;
    final age = clock().toUtc().difference(timestamp);
    return refreshFailed ||
        offline ||
        age > freshness ||
        age < const Duration(minutes: -5);
  }

  Future<void> load() async {
    if (loading || _disposed) return;
    loading = true;
    error = null;
    _notify();
    if (snapshot == null) {
      try {
        final cached = await cache.read();
        if (cached != null && cached.isDemo == repository.isDemo) {
          snapshot = cached;
          refreshFailed = true;
          _notify();
        }
      } catch (_) {
        /* Cache is optional; still attempt a server read. */
      }
    }
    try {
      final result = await repository.fetch();
      if (result.isDemo != repository.isDemo) {
        throw const RepositoryFailure(
          'Data source did not match this app mode.',
        );
      }
      snapshot = result;
      offline = false;
      refreshFailed = false;
      cacheWarning = null;
      try {
        await cache.write(result);
      } catch (_) {
        cacheWarning = 'Updated data could not be saved for offline use.';
      }
    } on RepositoryFailure catch (failure) {
      offline = failure.offline;
      refreshFailed = true;
      error = failure.message;
    } catch (_) {
      refreshFailed = true;
      error = 'Could not load public information. Please retry.';
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
    _timer?.cancel();
    super.dispose();
  }
}
