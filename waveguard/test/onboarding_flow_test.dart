import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waveguard/screens/onboarding/get_started_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all 24 individual PNG assets are included in the Flutter bundle',
    () async {
      final entries =
          jsonDecode(
                await File(
                  'assets/onboarding/asset-manifest.json',
                ).readAsString(),
              )
              as List;
      expect(entries, hasLength(24));
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final entry in entries) {
        final key = 'assets/onboarding/${entry['path']}';
        expect(manifest.listAssets(), contains(key), reason: key);
        final data = await rootBundle.load(key);
        expect(data.getUint32(0), 0x89504e47, reason: key);
      }
    },
  );
  testWidgets('swipe, dots, Back, and Skip work before login', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: GetStartedScreen(onContinue: () => completed++)),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Back'))
          .onPressed,
      isNull,
    );
    await tester.drag(find.byType(PageView), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(find.text('Monitor\nMarine Conditions'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to\nWaveGuard'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Go to page 4'));
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Skip').hitTestable().first);
    await tester.pump();
    expect(completed, 1);
  });
  testWidgets('all slides support a small display with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(home: GetStartedScreen(onContinue: () {})),
    );
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Get Started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
