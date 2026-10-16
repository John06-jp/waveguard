import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/public_data.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

abstract interface class AuthService {
  bool get configured;
  Stream<UserProfile?> get changes;
  Future<void> login(String email, String password);
  Future<void> register(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> signOut();
}

class UnconfiguredAuthService implements AuthService {
  @override
  bool get configured => false;
  @override
  Stream<UserProfile?> get changes => Stream.value(null);
  Never _unavailable() => throw const AuthFailure(
    'Account access is not configured yet. Continue as guest to explore the preview.',
  );
  @override
  Future<void> login(String email, String password) async => _unavailable();
  @override
  Future<void> register(String email, String password) async => _unavailable();
  @override
  Future<void> resetPassword(String email) async => _unavailable();
  @override
  Future<void> signOut() async {}
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this.auth);
  final FirebaseAuth auth;
  @override
  bool get configured => true;
  @override
  Stream<UserProfile?> get changes =>
      auth.idTokenChanges().asyncMap((user) async {
        if (user == null) return null;
        // Privileges are read from signed server-issued custom claims only.
        final token = await user.getIdTokenResult();
        final role = switch (token.claims?['role']) {
          'admin' => UserRole.admin,
          'mdrrmo' => UserRole.mdrrmo,
          _ => UserRole.user,
        };
        return UserProfile(user.uid, user.email ?? '', role);
      });
  Future<void> _perform(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Email or password is incorrect.',
        'email-already-in-use' =>
          'An account already uses this email. Try logging in.',
        'weak-password' =>
          'Choose a stronger password with at least 8 characters.',
        'invalid-email' => 'Enter a valid email address.',
        'network-request-failed' =>
          'No connection. Check your internet and try again.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'user-disabled' =>
          'This account is disabled. Contact your administrator.',
        _ => 'Account access is unavailable. Please try again.',
      });
    } catch (_) {
      throw const AuthFailure(
        'Account access is unavailable. Please try again.',
      );
    }
  }

  @override
  Future<void> login(String email, String password) => _perform(() async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  });
  @override
  Future<void> register(String email, String password) => _perform(() async {
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  });
  @override
  Future<void> resetPassword(String email) =>
      _perform(() => auth.sendPasswordResetEmail(email: email));
  @override
  Future<void> signOut() => _perform(auth.signOut);
}

class SessionProvider extends ChangeNotifier {
  SessionProvider(this.service);
  final AuthService service;
  UserProfile? profile;
  bool guest = false;
  bool get entered => profile != null || guest;
  void update(UserProfile? value) {
    profile = value;
    notifyListeners();
  }

  void enterGuest() {
    guest = true;
    notifyListeners();
  }

  Future<void> leave() async {
    await service.signOut();
    guest = false;
    profile = null;
    notifyListeners();
  }
}
