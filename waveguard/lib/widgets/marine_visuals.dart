import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SeaMark extends StatelessWidget {
  const SeaMark({this.size = 36, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'WaveGuard wave logo',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SeaMarkPainter()),
    ),
  );
}

class _SeaMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);
    final circle = Path()..addOval(const Rect.fromLTWH(1, 1, 98, 98));
    canvas.clipPath(circle);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF00468D), Color(0xFF009DE9)],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-4, 65)
        ..cubicTo(18, 69, 20, 22, 55, 24)
        ..cubicTo(76, 25, 83, 40, 81, 49)
        ..cubicTo(64, 24, 45, 42, 51, 58)
        ..cubicTo(56, 78, 84, 78, 104, 61)
        ..lineTo(104, 82)
        ..cubicTo(62, 100, 37, 55, -4, 78)
        ..close(),
      Paint()..color = Colors.white,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-5, 84)
        ..cubicTo(34, 56, 65, 108, 105, 77)
        ..lineTo(105, 100)
        ..lineTo(-5, 100)
        ..close(),
      Paint()..color = const Color(0xFF59D6F0),
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 1,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CoastalPhoto extends StatelessWidget {
  const CoastalPhoto({this.alignment = Alignment.center, super.key});
  final Alignment alignment;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/coastal-background.png',
    fit: BoxFit.cover,
    alignment: alignment,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => const ColoredBox(color: SeaColors.ocean),
  );
}

class LocationStrip extends StatelessWidget {
  const LocationStrip({
    this.onTap,
    this.refresh,
    this.dropdown = false,
    super.key,
  });
  final bool dropdown;
  final VoidCallback? onTap, refresh;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFEAF6FF),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: SeaColors.ocean, size: 28),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lianga, Surigao del Sur',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: SeaColors.ink,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '8.6336° N, 126.0947° E',
                    style: TextStyle(fontSize: 11, color: SeaColors.muted),
                  ),
                ],
              ),
            ),
            if (refresh != null)
              IconButton(
                tooltip: 'Refresh marine conditions',
                onPressed: refresh,
                icon: const Icon(Icons.refresh, color: SeaColors.ocean),
              )
            else if (onTap != null)
              Icon(
                dropdown ? Icons.keyboard_arrow_down : Icons.chevron_right,
                color: SeaColors.ocean,
                size: 21,
              ),
          ],
        ),
      ),
    ),
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile(this.icon, this.value, this.label, {super.key});
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SeaColors.mist),
    ),
    child: Column(
      children: [
        Icon(icon, color: SeaColors.ocean, size: 29),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SeaColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
}

class SeaIcon extends StatelessWidget {
  const SeaIcon(this.icon, {this.color = SeaColors.ocean, super.key});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, Color.lerp(color, SeaColors.ink, .22)!],
      ),
    ),
    child: Icon(icon, color: Colors.white, size: 25),
  );
}
