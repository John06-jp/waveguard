import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/marine_visuals.dart';
import '../sos/sos_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({required this.onContinue, super.key});
  final VoidCallback onContinue;
  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final _controller = PageController();
  int _index = 0;
  static const _titles = [
    'Welcome to\nWaveGuard',
    'Monitor\nMarine Conditions',
    'Explore\nCoastal Areas',
    'Stay Informed,\nStay Prepared',
  ];
  static const _subtitles = [
    'Know the Waves Before You Go',
    'Understand the Ocean',
    'Discover Your Destination',
    'Your Coastal Companion',
  ];
  static const _descriptions = [
    'Explore regional marine weather information for Lianga, Surigao del Sur, before visiting coastal areas.',
    'View current and forecast wave height, direction, and period. Check timestamps and the latest regional advisory.',
    'Browse maps, beach information, cantil warnings, and recorded incidents to help plan your visit.',
    'Find marine advisories, water safety guidance, and configured emergency contacts whenever you need them.',
  ];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: 4,
              onPageChanged: (page) => setState(() => _index = page),
              itemBuilder: (context, page) => LayoutBuilder(
                builder: (context, constraints) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  final heroHeight =
                      (constraints.maxHeight * (largeText ? .48 : .64)).clamp(
                        250.0,
                        610.0,
                      );
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: heroHeight,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipPath(
                                clipper: const _WaveEdge(),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      'assets/onboarding/backgrounds/onboarding_bg${page + 1}.png',
                                      fit: BoxFit.cover,
                                      excludeFromSemantics: true,
                                      errorBuilder: (_, _, _) =>
                                          const CoastalPhoto(),
                                    ),
                                    const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x33003F79),
                                            Color(0x00006CA5),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        28,
                                        MediaQuery.paddingOf(context).top + 72,
                                        28,
                                        38,
                                      ),
                                      child: _hero(page),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: MediaQuery.paddingOf(context).top + 12,
                                right: 16,
                                child: TextButton(
                                  onPressed: widget.onContinue,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(56, 48),
                                  ),
                                  child: const Text(
                                    'Skip',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight - heroHeight)
                                .clamp(0, double.infinity),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
                            child: Column(
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    _titles[page],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                      color: SeaColors.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _subtitles[page],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: SeaColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _descriptions[page],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: SeaColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Page ${_index + 1} of 4',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (page) {
                        return Semantics(
                          selected: page == _index,
                          button: true,
                          label: 'Go to page ${page + 1}',
                          child: InkWell(
                            onTap: () => _go(page),
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              width: 28,
                              height: 40,
                              child: Center(
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: page == _index
                                        ? SeaColors.ocean
                                        : const Color(0xFFD6E5F2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _index == 0 ? null : () => _go(_index - 1),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: FilledButton(
                          onPressed: _index == 3
                              ? widget.onContinue
                              : () => _go(_index + 1),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _index == 3 ? 'Get Started' : 'Next',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _hero(int page) {
    if (page == 0) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SeaMark(size: 110),
              const SizedBox(height: 18),
              const Text(
                'WaveGuard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Marine Weather Information System',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    if (page == 1 || page == 2) {
      return Image.asset(
        'assets/onboarding/illustrations/${page == 1 ? 'illustration_weather' : 'illustration_map'}.png',
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => Icon(
          page == 1 ? Icons.waves : Icons.map,
          size: 130,
          color: Colors.white,
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _featureCard(
                      'icon_safety',
                      'Safety Tips',
                      'Prepare for coastal activities.',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _featureCard(
                      'icon_conditions',
                      'Marine Advisories',
                      'Check regional guidance.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Material(
                color: const Color(0xF5FF424E),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SosScreen(standalone: true),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.phone_in_talk,
                          color: Colors.white,
                          size: 42,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'SOS Emergency Contacts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Quick access to configured local contacts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard(String asset, String title, String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xF2FFFFFF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Image.asset(
          'assets/onboarding/icons/$asset.png',
          height: 50,
          width: 50,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const Icon(
            Icons.health_and_safety,
            color: SeaColors.ocean,
            size: 42,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: SeaColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: SeaColors.muted),
        ),
      ],
    ),
  );
}

class _WaveEdge extends CustomClipper<Path> {
  const _WaveEdge();
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 28)
    ..cubicTo(
      size.width * .35,
      size.height - 38,
      size.width * .55,
      size.height + 15,
      size.width,
      size.height - 25,
    )
    ..lineTo(size.width, 0)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
