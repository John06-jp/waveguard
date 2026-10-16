import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_waves.dart';
import '../../widgets/shared.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({required this.onContinue, super.key});
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 200,
          child: AnimatedWaves(),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Brand(),
                    const SizedBox(height: 36),
                    const Icon(
                      Icons.waves_rounded,
                      size: 100,
                      color: SeaColors.ocean,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Stay informed.\nStay safe by the sea.',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Explore regional marine conditions in Lianga before your next coastal activity.',
                      style: TextStyle(fontSize: 17, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const _Feature(
                      Icons.waves,
                      'Understand the conditions',
                      'Current waves, hourly trends, and a seven-day outlook.',
                    ),
                    const _Feature(
                      Icons.beach_access,
                      'Know the coast',
                      'Beach information, cantil warnings, and incident locations.',
                    ),
                    const _Feature(
                      Icons.sos,
                      'Keep help within reach',
                      'Emergency contact options and practical safety reminders.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: onContinue,
                      child: const Text('Get Started'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Next: log in, create an account, or continue as a guest.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Regional information does not replace local warnings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.description);
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: SeaColors.ocean, size: 27),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(description),
            ],
          ),
        ),
      ],
    ),
  );
}
