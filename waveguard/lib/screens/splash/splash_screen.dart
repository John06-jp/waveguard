import 'package:flutter/material.dart';
import '../../widgets/marine_visuals.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        const CoastalPhoto(alignment: Alignment.centerRight),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x22003869), Color(0xCC002D4D)],
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SeaMark(size: 120),
                  const SizedBox(height: 20),
                  const Text(
                    'WaveGuard',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Marine Weather Information System',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 58),
                  const SizedBox.square(
                    dimension: 42,
                    child: CircularProgressIndicator(
                      color: Color(0xFF8CDBFF),
                      strokeWidth: 3,
                      semanticsLabel: 'Opening WaveGuard',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading marine data...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
