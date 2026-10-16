// Run with flutter test tool/export_onboarding_assets_test.dart --dart-define=EXPORT_FONT_FILE=<Roboto regular font path>.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waveguard/widgets/marine_visuals.dart';

class _Asset {
  const _Asset(this.path, this.size, this.widget);
  final String path;
  final Size size;
  final Widget widget;
}

Widget _symbol(IconData icon, Color color, double size) =>
    Icon(icon, color: color, size: size);
Widget _button(String label, {bool outline = false, bool arrow = true}) =>
    Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: outline
              ? Border.all(color: const Color(0xFF87C2FF), width: 3)
              : null,
          color: outline ? Colors.white : null,
          gradient: outline
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF008CFC), Color(0xFF0058AD)],
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: outline ? const Color(0xFF0068D0) : Colors.white,
                fontSize: label.length > 8 ? 50 : 60,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (arrow) ...[
              const SizedBox(width: 30),
              Icon(
                Icons.arrow_forward,
                size: 60,
                color: outline ? const Color(0xFF0068D0) : Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
void main() {
  testWidgets('export individual onboarding PNG assets', (tester) async {
    const fontPath = String.fromEnvironment('EXPORT_FONT_FILE');
    if (fontPath.isEmpty) {
      throw StateError(
        'Pass EXPORT_FONT_FILE pointing to the Flutter SDK roboto-regular.ttf.',
      );
    }
    await tester.runAsync(() async {
      final font = FontLoader('Roboto')
        ..addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
      final boldPath = fontPath.replaceFirst('regular.ttf', 'bold.ttf');
      if (await File(boldPath).exists()) {
        font.addFont(File(boldPath).readAsBytes().then(ByteData.sublistView));
      }
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    const blue = Color(0xFF008CF3);
    final assets = <_Asset>[
      const _Asset('icons/wave_logo.png', Size(512, 512), SeaMark(size: 512)),
      const _Asset(
        'icons/icon_welcome.png',
        Size(512, 512),
        CustomPaint(painter: _OceanShape()),
      ),
      _Asset(
        'icons/icon_conditions.png',
        const Size(512, 512),
        Stack(
          children: [
            Positioned(
              top: 20,
              right: 18,
              child: _symbol(
                Icons.wb_sunny_rounded,
                const Color(0xFFFFC51B),
                290,
              ),
            ),
            Positioned(
              bottom: 30,
              left: 10,
              child: _symbol(Icons.cloud_rounded, blue, 420),
            ),
          ],
        ),
      ),
      _Asset(
        'icons/icon_map.png',
        const Size(512, 512),
        Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 0,
              child: _symbol(Icons.map_rounded, const Color(0xFF20B7D5), 480),
            ),
            Positioned(
              top: 4,
              right: 70,
              child: _symbol(
                Icons.location_on_rounded,
                const Color(0xFFFF6847),
                290,
              ),
            ),
          ],
        ),
      ),
      _Asset(
        'icons/icon_safety.png',
        const Size(512, 512),
        Stack(
          alignment: Alignment.center,
          children: [
            _symbol(Icons.shield_rounded, const Color(0xFF007ADD), 490),
            _symbol(Icons.check_rounded, Colors.white, 260),
          ],
        ),
      ),
      _Asset('ui/btn_next.png', const Size(600, 200), _button('Next')),
      _Asset(
        'ui/btn_back.png',
        const Size(600, 200),
        _button('Back', outline: true, arrow: false),
      ),
      _Asset(
        'ui/btn_get_started.png',
        const Size(600, 200),
        _button('Get Started'),
      ),
      const _Asset(
        'ui/btn_skip.png',
        Size(300, 100),
        Center(
          child: Text(
            'Skip',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 60,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0076E8),
            ),
          ),
        ),
      ),
      _Asset(
        'ui/indicator_dots.png',
        const Size(400, 80),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            4,
            (i) => Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 0 ? blue : const Color(0xFFD7ECFF),
              ),
            ),
          ),
        ),
      ),
      const _Asset(
        'ui/card_wave.png',
        Size(1080, 300),
        CustomPaint(painter: _Ribbon()),
      ),
      const _Asset(
        'effects/wave_ribbon.png',
        Size(1920, 1080),
        CustomPaint(painter: _Ribbon(ribbon: true)),
      ),
      _Asset(
        'app/app_icon.png',
        const Size(1024, 1024),
        Container(
          padding: const EdgeInsets.all(140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(220),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFDAF2FF)],
            ),
          ),
          child: const SeaMark(size: 744),
        ),
      ),
      _Asset(
        'app/app_icon_dark.png',
        const Size(1024, 1024),
        Container(
          padding: const EdgeInsets.all(140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(220),
            gradient: const LinearGradient(
              colors: [Color(0xFF004A7B), Color(0xFF002844)],
            ),
          ),
          child: const SeaMark(size: 744),
        ),
      ),
    ];
    for (final asset in assets) {
      tester.view.physicalSize = asset.size;
      tester.view.devicePixelRatio = 1;
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Roboto'),
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: asset.size.width,
                height: asset.size.height,
                child: asset.widget,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('assets/onboarding/${asset.path}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _OceanShape extends CustomPainter {
  const _OceanShape();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final wave = Path()
      ..moveTo(4, 64)
      ..cubicTo(22, 61, 25, 17, 59, 16)
      ..cubicTo(81, 16, 87, 34, 82, 44)
      ..cubicTo(69, 26, 48, 39, 52, 57)
      ..cubicTo(56, 79, 80, 75, 97, 63)
      ..lineTo(97, 80)
      ..cubicTo(63, 101, 39, 59, 4, 80)
      ..close();
    canvas.drawPath(
      wave,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF003F9F), Color(0xFF04BFFF)],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(5, 84)
        ..cubicTo(36, 67, 65, 104, 96, 83)
        ..lineTo(96, 91)
        ..cubicTo(62, 110, 32, 76, 5, 94)
        ..close(),
      Paint()..color = const Color(0xFF008BDD),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Ribbon extends CustomPainter {
  const _Ribbon({this.ribbon = false});
  final bool ribbon;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final y = size.height * (ribbon ? .32 + i * .07 : .28 + i * .12);
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * .35,
          y - size.height * .35,
          size.width * .55,
          y + size.height * .4,
          size.width,
          y,
        );
      if (ribbon) {
        path.cubicTo(
          size.width * .6,
          y + size.height * .6,
          size.width * .3,
          y - size.height * .1,
          0,
          y + size.height * .2,
        );
      } else {
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = [
            const Color(0x557AD7FF),
            const Color(0x7747C8FF),
            const Color(0x555BBEE8),
          ][i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
