import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/public_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../../widgets/marine_visuals.dart';
import '../beach_detail/beach_detail_screen.dart';
import '../forecast/forecast_screen.dart';
import '../more/more_screen.dart';
import '../map/map_screen.dart';
import '../beaches/beaches_screen.dart';
import '../sos/sos_screen.dart';

class AdvisoryScreen extends StatelessWidget {
  const AdvisoryScreen({super.key});
  Widget _page(String title, Widget body) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: body,
  );
  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    final advisory = data.snapshot?.advisory;
    final actions = <(IconData, String, Widget)>[
      (Icons.waves, 'Current Weather', const CurrentWeatherScreen()),
      (
        Icons.schedule,
        'Hourly Forecast',
        _page('Hourly Forecast', const ForecastScreen()),
      ),
      (
        Icons.calendar_month,
        'Daily Forecast',
        _page('Daily Forecast', const ForecastScreen(initialDaily: true)),
      ),
      (
        Icons.map_outlined,
        'Map View',
        _page('Marine Weather Map', const MapScreen()),
      ),
      (
        Icons.beach_access_outlined,
        'Beaches',
        _page('Beaches in Lianga', const BeachesScreen()),
      ),
      (
        Icons.health_and_safety_outlined,
        'Safety Tips',
        const SafetyTipsScreen(),
      ),
    ];
    return RefreshIndicator(
      onRefresh: data.load,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              SizedBox(
                height:
                    270 + (MediaQuery.textScalerOf(context).scale(1) - 1) * 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CoastalPhoto(),
                    const Positioned(
                      right: 8,
                      bottom: 5,
                      child: Text(
                        'Illustrative scenery',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x10002244), Color(0xB000294A)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: LocationStrip(
                        onTap: () =>
                            openMainPage(context, const CurrentWeatherScreen()),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 30,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stay Informed,\nStay Safe',
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Marine weather information\nfor safer coastal activities.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 2 : 3;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: actions
                          .map(
                            (action) => SizedBox(
                              width:
                                  (constraints.maxWidth - 8 * (columns - 1)) /
                                  columns,
                              child: Material(
                                color: Colors.white,
                                elevation: 2,
                                shadowColor: const Color(0x18004E70),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => openMainPage(context, action.$3),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 14,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          action.$1,
                                          size: 31,
                                          color: SeaColors.ocean,
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          action.$2,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: SeaColors.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4248),
                    minimumSize: const Size(48, 52),
                  ),
                  onPressed: () =>
                      openMainPage(context, const SosScreen(standalone: true)),
                  icon: const Icon(Icons.phone_in_talk),
                  label: const Text('SOS Emergency Contacts'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DataNotices(),
                    if (advisory != null)
                      AdvisoryCard(
                        advisory: advisory,
                        outdated: data.outdated,
                        demo: data.isDemo,
                      )
                    else if (!data.loading)
                      const EmptyState(
                        'Advisory unavailable',
                        'Check local authorities for current guidance.',
                      ),
                    const SizedBox(height: 12),
                    const Notice(
                      'One regional advisory covers Lianga. Conditions may vary at individual beaches.',
                    ),
                    const SectionTitle('Explore the coast'),
                    ...?data.snapshot?.beaches.map(
                      (beach) => BeachTile(
                        beach,
                        onTap: () => openBeach(context, beach.id),
                      ),
                    ),
                    const Attribution(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
