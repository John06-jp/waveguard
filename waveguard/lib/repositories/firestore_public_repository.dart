import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/public_data.dart';
import 'public_repository.dart';

class FirestorePublicRepository implements PublicRepository {
  FirestorePublicRepository(this.firestore);
  final FirebaseFirestore firestore;
  @override
  bool get isDemo => false;

  Map<String, dynamic> _json(Map<String, dynamic> data) => data.map(
    (key, value) => MapEntry(
      key,
      value is Timestamp ? value.toDate().toUtc().toIso8601String() : value,
    ),
  );

  @override
  Future<PublicSnapshot> fetch() async {
    try {
      const server = GetOptions(source: Source.server);
      final results = await Future.wait([
        firestore.doc('public/current').get(server),
        firestore.collection('beaches').get(server),
        firestore
            .collection('incidents')
            .orderBy('date', descending: true)
            .limit(100)
            .get(server),
        firestore
            .collection('statusHistory')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime.now().toUtc().subtract(const Duration(hours: 72)),
              ),
            )
            .orderBy('timestamp', descending: true)
            .limit(500)
            .get(server),
      ]).timeout(const Duration(seconds: 20));
      final current = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      List<Map<String, dynamic>> rows(int index) =>
          (results[index] as QuerySnapshot<Map<String, dynamic>>).docs
              .map((doc) => _json({...doc.data(), 'id': doc.id}))
              .toList();
      return PublicSnapshot(
        advisory: current.exists
            ? RegionalAdvisory.fromJson(_json(current.data()!))
            : null,
        beaches: rows(1).map(Beach.fromJson).toList(),
        incidents: rows(2).map(Incident.fromJson).toList(),
        history: rows(3).map(StatusHistoryEntry.fromJson).toList(),
        fetchedAt: DateTime.now().toUtc(),
        isDemo: false,
      );
    } on FirebaseException catch (e) {
      throw RepositoryFailure(
        e.code == 'unavailable'
            ? 'No connection. Showing saved information when available.'
            : 'Public information is unavailable. Please retry.',
        offline: e.code == 'unavailable',
      );
    } catch (_) {
      throw const RepositoryFailure(
        'Could not load public information. Check the connection and retry.',
      );
    }
  }
}

class UnavailablePublicRepository implements PublicRepository {
  @override
  bool get isDemo => false;
  @override
  Future<PublicSnapshot> fetch() async => throw const RepositoryFailure(
    'The information service could not start. Restart the app or try again later.',
  );
}
