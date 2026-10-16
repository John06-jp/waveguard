import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waveguard/app.dart';
import 'package:waveguard/providers/public_data_provider.dart';
import 'package:waveguard/services/auth_service.dart';
import 'package:waveguard/services/bootstrap.dart';
import 'support/fakes.dart';

final previewKey = GlobalKey();
Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        previewKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/qa/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'Get Started precedes login; five tabs persist across forecast and beach details',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const fontPath = String.fromEnvironment('QA_FONT_FILE');
      if (fontPath.isNotEmpty) {
        await tester.runAsync(() async {
          final font = FontLoader('Roboto')
            ..addFont(
              File(
                fontPath,
              ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
            );
          await font.load();
          final icons = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await icons.load();
        });
      }
      await tester.pumpWidget(
        RepaintBoundary(
          key: previewKey,
          child: WaveGuardApp(
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
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await capture(tester, 'get-started');
      await tester.ensureVisible(find.text('Get Started'));
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
      await tester.ensureVisible(find.text('Continue as guest'));
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();
      for (final label in ['Home', 'Forecast', 'Map', 'Beaches', 'More']) {
        expect(find.text(label), findsOneWidget);
      }
      await capture(tester, 'home');
      await tester.tap(find.text('Forecast'));
      await tester.pumpAndSettle();
      expect(find.text('The next 48 hours'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      final previous = tester.widget<Slider>(find.byType(Slider)).value;
      await tester.drag(find.byType(Slider), const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider)).value, isNot(previous));
      await capture(tester, 'hourly');
      await tester.tap(find.text('7-Day'));
      await tester.pumpAndSettle();
      expect(find.text('Seven days at sea'), findsOneWidget);
      await capture(tester, 'daily');
      await tester.tap(find.text('Beaches'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample beach'));
      await tester.pumpAndSettle();
      expect(find.text('Beach information'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Settings'));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.text('Imperial'));
      await tester.pumpAndSettle();
      await capture(tester, 'settings');
      await tester.tap(find.text('Forecast'));
      await tester.pumpAndSettle();
      expect(find.text('Seven days at sea'), findsOneWidget);
      expect(find.textContaining('ft'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
