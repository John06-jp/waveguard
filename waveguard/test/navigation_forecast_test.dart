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
  final images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    await Future.wait(
      images.map(
        (element) => precacheImage((element.widget as Image).image, element),
      ),
    );
  });
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
      expect(find.text('Welcome to\nWaveGuard'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await capture(tester, 'get-started-1');
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Back'))
            .onPressed,
        isNull,
      );
      for (var page = 1; page < 4; page++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        await capture(tester, 'get-started-${page + 1}');
      }
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Explore\nCoastal Areas'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Get Started'));
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
      await capture(tester, 'login');
      await tester.ensureVisible(find.text('Continue as guest'));
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();
      for (final label in ['Home', 'Forecast', 'Map', 'Beaches', 'More']) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      await capture(tester, 'home');
      await tester.tap(find.text('Lianga, Surigao del Sur'));
      await tester.pumpAndSettle();
      expect(find.text('Select location'), findsOneWidget);
      await tester.tap(find.text('Use Lianga'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No alerts are available'), findsOneWidget);
      Navigator.of(
        tester.element(find.textContaining('No alerts are available')),
      ).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Current Weather'));
      await tester.pumpAndSettle();
      expect(find.text('Current Marine Conditions'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await capture(tester, 'current-weather');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forecast'));
      await tester.pumpAndSettle();
      await capture(tester, 'forecast-overview');
      await tester.scrollUntilVisible(find.byType(Slider), 250);
      expect(
        find.text('Hourly Marine Forecast (Next 48 Hours)'),
        findsOneWidget,
      );
      expect(find.byType(Slider), findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(find.byType(Slider)),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      final previous = tester.widget<Slider>(find.byType(Slider)).value;
      await tester.drag(find.byType(Slider), const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<Slider>(find.byType(Slider)).value, isNot(previous));
      await capture(tester, 'hourly');
      await tester.scrollUntilVisible(
        find.text('7-Day'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('7-Day'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('7-Day Marine Forecast'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('7-Day Marine Forecast'), findsOneWidget);
      await capture(tester, 'daily');
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Beaches'),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, 'beaches');
      final search = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Search beaches...',
      );
      await tester.enterText(search, 'no matching beach');
      await tester.pumpAndSettle();
      expect(find.text('No matching beaches'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No cantil flag'));
      await tester.pumpAndSettle();
      expect(find.text('No matching beaches'), findsOneWidget);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample beach'));
      await tester.pumpAndSettle();
      expect(find.text('Beach information'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await capture(tester, 'settings-overview');
      await tester.scrollUntilVisible(
        find.text('Units'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Units'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(RadioListTile<bool>, 'Imperial'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await capture(tester, 'settings');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Safety Tips'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('Safety Tips'));
      await tester.pumpAndSettle();
      await capture(tester, 'safety-tips');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('About WaveGuard'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('About WaveGuard'));
      await tester.pumpAndSettle();
      await capture(tester, 'about');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('SOS & Emergency Contacts'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('SOS & Emergency Contacts'));
      await tester.pumpAndSettle();
      await capture(tester, 'emergency-contacts');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forecast'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('7-Day Marine Forecast'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('7-Day Marine Forecast'), findsOneWidget);
      expect(find.textContaining('ft'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
