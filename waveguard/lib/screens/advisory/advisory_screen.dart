import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/public_data.dart';
import '../../providers/public_data_provider.dart';
import '../../providers/marine_provider.dart';
import '../../services/app_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../../widgets/marine_visuals.dart';
import '../beach_detail/beach_detail_screen.dart';
import '../forecast/forecast_screen.dart';
import '../more/more_screen.dart';
import '../map/map_screen.dart';
import '../beaches/beaches_screen.dart';
import '../sos/sos_screen.dart';

class AdvisoryScreen extends StatefulWidget {
  const AdvisoryScreen({this.onAccount, this.onSelectTab, super.key});
  final VoidCallback? onAccount;
  final ValueChanged<int>? onSelectTab;
  @override
  State<AdvisoryScreen> createState() => _AdvisoryScreenState();
}

class _AdvisoryScreenState extends State<AdvisoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<MarineProvider>().load();
    });
  }

  Future<void> _refresh() => Future.wait([
    context.read<PublicDataProvider>().load(),
    context.read<MarineProvider>().load(),
  ]);
  Widget _page(String title, Widget body) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: body,
  );
  void _location() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.location_on, color: SeaColors.ocean),
              title: Text('Lianga, Surigao del Sur'),
              subtitle: Text('8.6336? N, 126.0947? E'),
              trailing: Icon(Icons.check_circle, color: SeaColors.ocean),
            ),
            const Text(
              'Lianga is the available regional study area. No device location is collected.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Use Lianga'),
            ),
          ],
        ),
      ),
    ),
  );
  void _notifications() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            const Notice(
              'No alerts are available. Notification delivery is not connected yet.',
              icon: Icons.notifications_none,
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openMainPage(context, const SettingsScreen());
              },
              child: const Text('Notification settings'),
            ),
          ],
        ),
      ),
    ),
  );
  void _advisoryDetails() {
    final data = context.read<PublicDataProvider>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.snapshot?.advisory != null)
                AdvisoryCard(
                  advisory: data.snapshot!.advisory!,
                  outdated: data.outdated,
                  demo: data.isDemo,
                )
              else
                const EmptyState(
                  'Advisory unavailable',
                  'Check local authorities for current guidance.',
                ),
              const SizedBox(height: 12),
              const Notice(
                'Regional information is not a beach-specific swimming clearance.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    final marine = context.watch<MarineProvider>();
    final units = context.watch<AppPreferences>();
    final current = marine.forecast?.current;
    final advisory = data.snapshot?.advisory;
    final beaches = data.snapshot?.beaches ?? <Beach>[];
    final hour = DateTime.now().toUtc().add(const Duration(hours: 8)).hour;
    final greeting = hour < 12
        ? 'Good Morning!'
        : hour < 18
        ? 'Good Afternoon!'
        : 'Good Evening!';
    final actions = <(IconData, String, Color, VoidCallback)>[
      (
        Icons.waves,
        'Hourly Forecast',
        SeaColors.ocean,
        () => openMainPage(
          context,
          _page('Hourly Forecast', const ForecastScreen()),
        ),
      ),
      (
        Icons.calendar_month,
        '7-Day Forecast',
        const Color(0xFF11B97B),
        () => openMainPage(
          context,
          _page('Daily Forecast', const ForecastScreen(initialDaily: true)),
        ),
      ),
      (
        Icons.map_outlined,
        'Map View',
        const Color(0xFFFF5366),
        () => widget.onSelectTab != null
            ? widget.onSelectTab!(2)
            : openMainPage(
                context,
                _page('Marine Weather Map', const MapScreen()),
              ),
      ),
      (
        Icons.beach_access_outlined,
        'Beaches',
        const Color(0xFFF49A16),
        () => _allBeaches(),
      ),
    ];
    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.35;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: enlarged ? 900 : 650,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const CoastalPhoto(alignment: Alignment.centerLeft),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0, .5, 1],
                              colors: [
                                Color(0xD000417E),
                                Color(0x35004366),
                                SeaColors.foam,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      MediaQuery.paddingOf(context).top + 8,
                      12,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Tooltip(
                                message: 'Account',
                                child: InkWell(
                                  onTap: widget.onAccount,
                                  borderRadius: BorderRadius.circular(10),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        SeaMark(size: 34),
                                        SizedBox(width: 9),
                                        Flexible(
                                          child: Text(
                                            'WaveGuard',
                                            style: TextStyle(
                                              fontSize: 23,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Notifications',
                              onPressed: _notifications,
                              icon: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LocationStrip(onTap: _location, dropdown: true),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Stay Informed,\nStay Safe',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: Colors.white,
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
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xE5003B61),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFB8E3F9)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x25002143),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runSpacing: 5,
                                children: [
                                  const Text(
                                    'Current Marine Conditions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    current == null
                                        ? 'Awaiting data'
                                        : 'Valid ${stamp(current.time)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              InkWell(
                                onTap: () => openMainPage(
                                  context,
                                  const CurrentWeatherScreen(),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.waves,
                                      color: Color(0xFF28C3FF),
                                      size: 40,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          units.height(current?.height),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 29,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const Text(
                                          'Wave Height',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (advisory != null)
                                      StatusChip(advisory.level),
                                    IconButton(
                                      tooltip: 'Current Weather',
                                      onPressed: () => openMainPage(
                                        context,
                                        const CurrentWeatherScreen(),
                                      ),
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: Colors.white,
                                        size: 21,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (marine.loading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: LinearProgressIndicator(),
                                ),
                              if (marine.repository.isDemo || data.isDemo)
                                const Padding(
                                  padding: EdgeInsets.only(top: 9),
                                  child: Text(
                                    'Demo preview: sample conditions and advisory',
                                    style: TextStyle(
                                      color: Color(0xFFFFE0A2),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              if (marine.outdated || data.outdated)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Outdated data - refresh before use',
                                    style: TextStyle(
                                      color: Color(0xFFFFE0A2),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final readings = [
                                    (
                                      Icons.explore_outlined,
                                      current?.direction == null
                                          ? 'Unavailable'
                                          : '${current!.direction!.round()}\u00b0',
                                      'Wave Direction',
                                    ),
                                    (
                                      Icons.schedule,
                                      current?.period == null
                                          ? 'Unavailable'
                                          : '${current!.period!.toStringAsFixed(1)} s',
                                      'Wave Period',
                                    ),
                                    (
                                      Icons.air,
                                      units.height(current?.windWaveHeight),
                                      'Wind Wave Height',
                                    ),
                                  ];
                                  return Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: readings
                                        .map(
                                          (reading) => Container(
                                            width: enlarged
                                                ? constraints.maxWidth
                                                : (constraints.maxWidth - 12) /
                                                      3,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0x9900719F),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(
                                                  reading.$1,
                                                  color: const Color(
                                                    0xFFB5E3FF,
                                                  ),
                                                  size: 29,
                                                ),
                                                const SizedBox(height: 7),
                                                Text(
                                                  reading.$2,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  reading.$3,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Quick Access',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final count = enlarged ? 2 : 4;
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: actions
                                        .map(
                                          (action) => SizedBox(
                                            width:
                                                (constraints.maxWidth -
                                                    8 * (count - 1)) /
                                                count,
                                            child: Material(
                                              color: Colors.white,
                                              elevation: 2,
                                              shadowColor: const Color(
                                                0x18004769,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: InkWell(
                                                onTap: action.$4,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 13,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      Icon(
                                                        action.$1,
                                                        color: action.$3,
                                                        size: 31,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        action.$2,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: SeaColors.ink,
                                                          fontWeight:
                                                              FontWeight.w700,
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
                              const SizedBox(height: 14),
                              Material(
                                color:
                                    advisory?.level.background ??
                                    SeaColors.mist,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: _advisoryDetails,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          advisory?.level.icon ??
                                              Icons.info_outline,
                                          color:
                                              advisory?.level.color ??
                                              SeaColors.ocean,
                                          size: 30,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                advisory == null
                                                    ? 'Advisory unavailable'
                                                    : '${advisory.level.label} regional advisory',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      advisory?.level.color ??
                                                      SeaColors.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                advisory?.recommendation ??
                                                    'Check local authorities for current guidance.',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (data.outdated)
                                                const Text(
                                                  'Outdated',
                                                  style: TextStyle(
                                                    color: SeaColors.danger,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: SeaColors.ocean,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Beaches in Lianga',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _allBeaches,
                                    child: const Text('See All'),
                                  ),
                                ],
                              ),
                              const Text(
                                'Regional beach records; no location tracking.',
                                style: TextStyle(fontSize: 10),
                              ),
                              const SizedBox(height: 10),
                              if (beaches.isEmpty)
                                const EmptyState(
                                  'No beaches available',
                                  'Verified records will appear here.',
                                )
                              else
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: beaches
                                        .map((beach) => _beachCard(beach))
                                        .toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF424E),
                            padding: const EdgeInsets.symmetric(vertical: 17),
                          ),
                          onPressed: () => openMainPage(
                            context,
                            const SosScreen(standalone: true),
                          ),
                          icon: const Icon(Icons.phone_in_talk),
                          label: const Text('SOS Emergency Contacts'),
                        ),
                        const SizedBox(height: 12),
                        if (marine.error != null)
                          Notice(marine.error!, warning: true),
                        const DataNotices(),
                        const Text(
                          'Illustrative coastal imagery. Regional forecasts are not a beach-specific swimming clearance.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10),
                        ),
                        const Attribution(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xF7FFFFFF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: SeaColors.mist),
    ),
    child: child,
  );
  void _allBeaches() {
    if (widget.onSelectTab != null) {
      widget.onSelectTab!(3);
    } else {
      openMainPage(context, _page('Beaches in Lianga', const BeachesScreen()));
    }
  }

  Widget _beachCard(Beach beach) => Padding(
    padding: const EdgeInsets.only(right: 9, bottom: 4),
    child: SizedBox(
      width: 145,
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x20004675),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openBeach(context, beach.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 82,
                child: CoastalPhoto(alignment: Alignment.centerLeft),
              ),
              Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beach.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SeaColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: beach.hasCantil
                                  ? const Color(0xFFFFE8AB)
                                  : SeaColors.mist,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              beach.hasCantil
                                  ? 'Cantil warning'
                                  : 'No beach status',
                              style: TextStyle(
                                fontSize: 9,
                                color: beach.hasCantil
                                    ? const Color(0xFF795002)
                                    : SeaColors.ink,
                              ),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: SeaColors.ocean,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
