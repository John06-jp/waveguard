import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waveguard/app.dart';
import 'package:waveguard/providers/public_data_provider.dart';
import 'package:waveguard/screens/sos/sos_screen.dart';
import 'package:waveguard/services/auth_service.dart';
import 'package:waveguard/services/bootstrap.dart';
import 'package:waveguard/services/external_actions.dart';
import 'support/fakes.dart';

Future<void> openApp(WidgetTester tester) async {
  await tester.pumpWidget(
    WaveGuardApp(
      dependencies: AppDependencies(
        data: PublicDataProvider(
          FakeRepository(),
          MemoryCache(),
          clock: () => testNow,
        ),
        auth: UnconfiguredAuthService(),
      ),
      externalActions: FakeExternalActions(),
      splashDuration: Duration.zero,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.ensureVisible(find.text('Get Started'));
  await tester.tap(find.text('Get Started'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets('login validates inputs and toggles password visibility', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Login'));
    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    await tapVisible(tester, find.byTooltip('Show password'));
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('guest opens beach detail, history, and SOS', (tester) async {
    await openApp(tester);
    await tapVisible(tester, find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Sample regional advisory'), findsOneWidget);
    await tapVisible(tester, find.text('Sample beach'));
    await tester.pumpAndSettle();
    expect(find.text('Beach information'), findsOneWidget);
    expect(find.textContaining('Sudden underwater drop'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Advisory history'));
    await tester.pumpAndSettle();
    expect(find.text('The coast over time'), findsOneWidget);
    await tester.tap(find.byTooltip('SOS'));
    await tester.pumpAndSettle();
    expect(find.text('Emergency assistance'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('SOS works before login without implying delivery', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(tester, find.text('Emergency assistance'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('SOS options'));
    await tester.pumpAndSettle();
    expect(find.text('Emergency contact unavailable'), findsOneWidget);
    expect(find.text('Open dialer'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('dialer requires confirmation and failure shows fallback', (
    tester,
  ) async {
    final external = FakeExternalActions()..succeeds = false;
    await tester.pumpWidget(
      Provider<ExternalActions>.value(
        value: external,
        child: const MaterialApp(home: SosScreen(phone: '+639000000000')),
      ),
    );
    await tester.tap(find.text('Call MDRRMO'));
    await tester.pumpAndSettle();
    expect(external.opened, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(external.opened, isEmpty);
    await tester.tap(find.text('Call MDRRMO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialer'));
    await tester.pumpAndSettle();
    expect(external.opened.single.scheme, 'tel');
    await tester.scrollUntilVisible(
      find.textContaining('Could not open the phone dialer'),
      200,
    );
    expect(
      find.textContaining('Could not open the phone dialer'),
      findsOneWidget,
    );
  });
  testWidgets('small screen and large text remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openApp(tester);
    await tapVisible(tester, find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
