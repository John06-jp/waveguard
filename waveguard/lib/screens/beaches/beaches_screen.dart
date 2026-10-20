import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/public_data.dart';
import '../../providers/public_data_provider.dart';
import '../../providers/marine_provider.dart';
import '../../services/app_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/marine_visuals.dart';
import '../../widgets/shared.dart';
import '../beach_detail/beach_detail_screen.dart';
import '../map/map_screen.dart';

class BeachesScreen extends StatefulWidget {
  const BeachesScreen({this.onMap, super.key});
  final VoidCallback? onMap;
  @override
  State<BeachesScreen> createState() => _BeachesScreenState();
}

class _BeachesScreenState extends State<BeachesScreen> {
  String _query = '';
  int _filter = 0;
  bool _reverse = false;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    final beaches =
        (data.snapshot?.beaches ?? <Beach>[])
            .where(
              (beach) =>
                  beach.name.toLowerCase().contains(_query.toLowerCase()) &&
                  (_filter == 0 ||
                      (_filter == 1 ? beach.hasCantil : !beach.hasCantil)),
            )
            .toList()
          ..sort(
            (a, b) =>
                _reverse ? b.name.compareTo(a.name) : a.name.compareTo(b.name),
          );
    return RefreshIndicator(
      onRefresh: data.load,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE7F2FF), Color(0xFFF7FBFF)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Stack(
              children: [
                const Positioned.fill(
                  child: CoastalPhoto(alignment: Alignment.topRight),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xDD004B8D), Color(0x22004B8D)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          SeaMark(size: 36),
                          SizedBox(width: 10),
                          Text(
                            'WaveGuard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Beaches',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Discover coastal areas and check regional marine conditions.',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xF5F7FBFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final search = TextField(
                        controller: _search,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search beaches...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _search.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      );
                      final map = TextButton.icon(
                        onPressed:
                            widget.onMap ??
                            () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text('Coastal Map'),
                                  ),
                                  body: const MapScreen(),
                                ),
                              ),
                            ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Map View'),
                      );
                      return constraints.maxWidth < 360 ||
                              MediaQuery.textScalerOf(context).scale(1) > 1.3
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [search, map],
                            )
                          : Row(
                              children: [
                                Expanded(child: search),
                                const SizedBox(width: 8),
                                map,
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final item in [
                        (0, 'All'),
                        (1, 'Cantil warning'),
                        (2, 'No cantil flag'),
                      ])
                        ChoiceChip(
                          label: Text(item.$2),
                          selected: _filter == item.$1,
                          selectedColor: const Color(0xFF007AFF),
                          labelStyle: TextStyle(
                            color: _filter == item.$1
                                ? Colors.white
                                : SeaColors.ink,
                          ),
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _filter = item.$1),
                        ),
                      PopupMenuButton<bool>(
                        tooltip: 'Sort beaches',
                        initialValue: _reverse,
                        onSelected: (value) => setState(() => _reverse = value),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: false,
                            child: Text('Name A to Z'),
                          ),
                          PopupMenuItem(
                            value: true,
                            child: Text('Name Z to A'),
                          ),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sort, color: SeaColors.ocean),
                              SizedBox(width: 5),
                              Text('Sort'),
                              Icon(Icons.expand_more),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const DataNotices(),
                  if (beaches.isEmpty && !data.loading)
                    EmptyState(
                      _query.isNotEmpty || _filter != 0
                          ? 'No matching beaches'
                          : 'No beaches available',
                      _query.isNotEmpty || _filter != 0
                          ? 'Try another name or select All.'
                          : 'Verified beach records will appear here when available.',
                    ),
                  for (final beach in beaches) _BeachCard(beach: beach),
                  const Notice(
                    'Conditions are regional, not beach-specific. A missing cantil flag does not establish that a beach is safe.',
                  ),
                  const Attribution(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeachCard extends StatelessWidget {
  const _BeachCard({required this.beach});
  final Beach beach;
  @override
  Widget build(BuildContext context) {
    final current = context.watch<MarineProvider>().forecast?.current;
    final units = context.watch<AppPreferences>();
    final information = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  beach.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: SeaColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: SeaColors.ocean),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.location_on, size: 15, color: SeaColors.ocean),
              SizedBox(width: 3),
              Expanded(
                child: Text(
                  'Lianga, Surigao del Sur',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            beach.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: beach.hasCantil ? const Color(0xFFFFEAB0) : SeaColors.mist,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  beach.hasCantil
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  size: 15,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    beach.hasCantil
                        ? 'Cantil warning'
                        : 'No cantil flag recorded',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Regional marine conditions',
            style: TextStyle(fontSize: 10, color: SeaColors.muted),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _reading(
                Icons.waves,
                units.height(current?.height),
                const Color(0xFF0087FF),
              ),
              _reading(
                Icons.explore_outlined,
                current?.direction == null
                    ? 'Unavailable'
                    : '${current!.direction!.round()}\u00b0',
                const Color(0xFF00A69C),
              ),
              _reading(
                Icons.schedule,
                current?.period == null
                    ? 'Unavailable'
                    : '${current!.period!.toStringAsFixed(1)} s',
                const Color(0xFFE59A00),
              ),
            ],
          ),
        ],
      ),
    );
    final photo = Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/onboarding/backgrounds/onboarding_bg3.png',
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xAA00395A),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'Illustrative photo',
              style: TextStyle(color: Colors.white, fontSize: 9),
            ),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openBeach(context, beach.id),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 170, child: photo),
                      information,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * .34,
                        height: 240,
                        child: photo,
                      ),
                      Expanded(child: information),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _reading(IconData icon, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 11, color: SeaColors.ink)),
      ],
    ),
  );
}
