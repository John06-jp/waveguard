import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waveguard/app.dart';
import 'package:waveguard/models/public_data.dart';
import 'package:waveguard/providers/public_data_provider.dart';
import 'package:waveguard/services/auth_service.dart';
import 'package:waveguard/services/bootstrap.dart';
import 'support/fakes.dart';

class ControlledAuth implements AuthService {
  final controller = StreamController<UserProfile?>.broadcast();
  final loginResult = Completer<void>();
  int attempts = 0;
  String? resetEmail;
  @override
  bool get configured => true;
  @override
  Stream<UserProfile?> get changes async* {
    yield null;
    yield* controller.stream;
  }

  @override
  Future<void> login(String email, String password) {
    attempts++;
    return loginResult.future;
  }

  @override
  Future<void> register(String email, String password) async {}
  @override
  Future<void> resetPassword(String email) async {
    resetEmail = email;
  }

  @override
  Future<void> signOut() async {
    controller.add(null);
  }
}

Future<void> open(WidgetTester tester, ControlledAuth auth) async {
  await tester.pumpWidget(
    WaveGuardApp(
      dependencies: AppDependencies(
        data: PublicDataProvider(
          FakeRepository(),
          MemoryCache(),
          clock: () => testNow,
        ),
        auth: auth,
      ),
      splashDuration: Duration.zero,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.ensureVisible(find.text('Get Started'));
  await tester.tap(find.text('Get Started'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> press(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('login blocks duplicates and displays authentication failure', (
    tester,
  ) async {
    final auth = ControlledAuth();
    await open(tester, auth);
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await press(tester, find.widgetWithText(FilledButton, 'Login'));
    expect(auth.attempts, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    auth.loginResult.completeError(
      const AuthFailure('Email or password is incorrect.'),
    );
    await tester.pump();
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.controller.close();
  });
  testWidgets('trusted session update enters app and exposes role in account', (
    tester,
  ) async {
    final auth = ControlledAuth();
    await open(tester, auth);
    auth.controller.add(
      const UserProfile('trusted-user', 'officer@example.com', UserRole.mdrrmo),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sample regional advisory'), findsOneWidget);
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Account role: mdrrmo'), findsOneWidget);
    expect(find.textContaining('Management tools are outside'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.controller.close();
  });
  testWidgets(
    'reset validates email and reports request without claiming account exists',
    (tester) async {
      final auth = ControlledAuth();
      await open(tester, auth);
      await press(tester, find.text('Forgot password?'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.enterText(
        find.byType(TextFormField).last,
        'user@example.com',
      );
      await press(tester, find.text('Send reset link'));
      await tester.pump();
      expect(auth.resetEmail, 'user@example.com');
      expect(find.textContaining('If an account exists'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await auth.controller.close();
    },
  );
}
