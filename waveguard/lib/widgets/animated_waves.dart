import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

final waveRouteObserver = RouteObserver<ModalRoute<void>>();

class AnimatedWaves extends StatefulWidget {
  const AnimatedWaves({super.key});
  @override
  State<AnimatedWaves> createState() => _AnimatedWavesState();
}

class _AnimatedWavesState extends State<AnimatedWaves>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );
  ModalRoute<void>? _route;
  bool _visible = true;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      waveRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) waveRouteObserver.subscribe(this, route);
    }
    _sync();
  }

  void _sync() {
    if (_visible &&
        _active &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didPushNext() {
    _visible = false;
    _sync();
  }

  @override
  void didPopNext() {
    _visible = true;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    waveRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WavePainter(_controller),
          size: const Size(double.infinity, 160),
        ),
      ),
    ),
  );
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;
  @override
  void paint(Canvas canvas, Size size) {
    for (var layer = 0; layer < 3; layer++) {
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width + 4; x += 4) {
        final y =
            size.height * (.37 + layer * .17) +
            math.sin(
                  x / size.width * math.pi * 2 +
                      animation.value * math.pi * 2 * (layer + 1) +
                      layer,
                ) *
                (12 - layer * 2);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = SeaColors.ocean.withValues(alpha: .05 + layer * .035),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.animation != animation;
}
