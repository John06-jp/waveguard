import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/marine_forecast.dart';
import '../../providers/marine_provider.dart';
import '../../providers/public_data_provider.dart';
import '../../services/app_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../../widgets/marine_visuals.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({this.initialDaily = false, super.key});
  final bool initialDaily;
  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  late bool _daily = widget.initialDaily;
  int _selected = 0, _metric = 0;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<MarineProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MarineProvider>();
    final units = context.watch<AppPreferences>();
    final now = DateTime.now().toUtc();
    final points = _daily
        ? data.forecast?.daily ?? <MarinePoint>[]
        : data.forecast?.hourly
                  .where(
                    (p) =>
                        !p.time.isBefore(
                          now.subtract(const Duration(hours: 1)),
                        ) &&
                        p.time.isBefore(now.add(const Duration(hours: 48))),
                  )
                  .take(48)
                  .toList() ??
              <MarinePoint>[];
    final selected = points.isEmpty
        ? null
        : points[_selected.clamp(0, points.length - 1)];
    double? value(MarinePoint p) => _metric == 0
        ? p.height == null
              ? null
              : p.height! * (units.imperial ? 3.28084 : 1)
        : _metric == 1
        ? p.direction
        : p.period;
    String display(MarinePoint p) => _metric == 0
        ? units.height(p.height)
        : '${value(p)?.toStringAsFixed(1) ?? 'Unavailable'}${value(p) == null
              ? ''
              : _metric == 1
              ? '°'
              : ' s'}';
    return RefreshIndicator(
      onRefresh: data.load,
      child: PageBody(
        children: [
          const MarineHeader(
            title: 'Marine Forecast',
            subtitle: 'Plan ahead with regional marine weather data.',
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? SeaColors.ocean
                    : Colors.white,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : SeaColors.ink,
              ),
            ),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.waves),
                label: Text('Hourly'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.calendar_month),
                label: Text('7-Day'),
              ),
            ],
            selected: {_daily},
            onSelectionChanged: (selection) => setState(() {
              _daily = selection.first;
              _selected = 0;
            }),
          ),
          const SizedBox(height: 10),
          const MarineNotices(),
          _CurrentForecastCard(current: data.forecast?.current),
          const SizedBox(height: 12),
          Text(
            _daily
                ? '7-Day Marine Forecast'
                : 'Hourly Marine Forecast (Next 48 Hours)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Wave height', 'Direction', 'Period']
                .asMap()
                .entries
                .map(
                  (entry) => ChoiceChip(
                    label: Text(entry.value),
                    selected: _metric == entry.key,
                    onSelected: (_) => setState(() => _metric = entry.key),
                  ),
                )
                .toList(),
          ),
          if (points.isEmpty && !data.loading)
            const EmptyState(
              'Forecast unavailable',
              'No marine values are available in this time window. Retry to check for updates.',
            ),
          if (selected != null) ...[
            const SizedBox(height: 12),
            Text(
              display(selected),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(stamp(selected.time)),
            const SizedBox(height: 12),
            Semantics(
              label:
                  'Forecast chart. Use the slider below to inspect each ${_daily ? 'day' : 'hour'}.',
              child: SizedBox(
                height: 170,
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    onTapDown: (details) => setState(
                      () => _selected =
                          (details.localPosition.dx /
                                  constraints.maxWidth *
                                  (points.length - 1))
                              .round()
                              .clamp(0, points.length - 1),
                    ),
                    onPanUpdate: (details) => setState(
                      () => _selected =
                          (details.localPosition.dx /
                                  constraints.maxWidth *
                                  (points.length - 1))
                              .round()
                              .clamp(0, points.length - 1),
                    ),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _ForecastPainter(
                        points.map(value).toList(),
                        _selected.clamp(0, points.length - 1),
                        _daily,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (points.length > 1)
              Slider(
                value: _selected.clamp(0, points.length - 1).toDouble(),
                min: 0,
                max: (points.length - 1).toDouble(),
                divisions: points.length - 1,
                semanticFormatterCallback: (v) =>
                    '${stamp(points[v.round()].time)}, ${display(points[v.round()])}',
                onChanged: (value) => setState(() => _selected = value.round()),
              ),
            Text(
              _daily
                  ? 'Daily maximum height and period; dominant direction.'
                  : 'Tap the chart or move the slider to inspect an hour.',
            ),
            SectionTitle(
              _daily ? 'Daily Marine Forecast' : 'Hourly Marine Forecast',
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFEBF4FC),
                ),
                headingRowHeight: 44,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                horizontalMargin: 12,
                headingTextStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SeaColors.ink,
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 11,
                  color: SeaColors.ink,
                ),
                columns: [
                  const DataColumn(label: Text('Time (PHT)')),
                  DataColumn(label: Text('Height (${units.lengthUnit})')),
                  const DataColumn(label: Text('Direction')),
                  const DataColumn(label: Text('Period')),
                ],
                rows: points
                    .map(
                      (p) => DataRow(
                        selected: p == selected,
                        onSelectChanged: (_) =>
                            setState(() => _selected = points.indexOf(p)),
                        cells: [
                          DataCell(Text(compactTime(p.time, daily: _daily))),
                          DataCell(Text(units.height(p.height))),
                          DataCell(
                            Text(
                              p.direction == null
                                  ? 'Unavailable'
                                  : '${p.direction!.round()}°',
                            ),
                          ),
                          DataCell(
                            Text(
                              p.period == null
                                  ? 'Unavailable'
                                  : '${p.period!.toStringAsFixed(1)} s',
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const Attribution(),
        ],
      ),
    );
  }
}

class MarineNotices extends StatelessWidget {
  const MarineNotices({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<MarineProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.repository.isDemo)
          const Notice(
            'Demo marine forecast · Fictional values for interface review.',
          ),
        if (data.outdated && data.forecast != null)
          const Notice(
            'Saved or outdated marine data. Refresh before relying on the forecast.',
            warning: true,
          ),
        if (data.loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (data.error != null) ...[
          Notice(data.error!, warning: true),
          TextButton.icon(
            onPressed: data.loading ? null : data.load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry marine data'),
          ),
        ],
        if (data.forecast != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Retrieved ${stamp(data.forecast!.fetchedAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class CurrentWeatherScreen extends StatefulWidget {
  const CurrentWeatherScreen({super.key});
  @override
  State<CurrentWeatherScreen> createState() => _CurrentWeatherScreenState();
}

class _CurrentWeatherScreenState extends State<CurrentWeatherScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<MarineProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MarineProvider>();
    final current = data.forecast?.current;
    final units = context.watch<AppPreferences>();
    return Scaffold(
      appBar: AppBar(title: const Text('Current Marine Weather')),
      body: RefreshIndicator(
        onRefresh: data.load,
        child: PageBody(
          children: [
            LocationStrip(refresh: data.loading ? null : data.load),
            const SizedBox(height: 10),
            const MarineNotices(),
            if (current == null && !data.loading)
              const EmptyState(
                'Current conditions unavailable',
                'Retry to request the latest marine data.',
              ),
            if (current != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0055AC), Color(0xFF007E90)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Current Marine Conditions',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.waves,
                          size: 52,
                          color: Color(0xFF50D2FF),
                        ),
                        const SizedBox(width: 18),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                units.height(current.height),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 31,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Modelled marine conditions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'This is not a swimming advisory.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Valid at ${stamp(current.time)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final items = [
                    MetricTile(
                      Icons.explore_outlined,
                      current.direction == null
                          ? 'Unavailable'
                          : '${current.direction!.round()}\u00b0',
                      'Wave Direction',
                    ),
                    MetricTile(
                      Icons.schedule,
                      current.period == null
                          ? 'Unavailable'
                          : '${current.period!.toStringAsFixed(1)} s',
                      'Wave Period',
                    ),
                    MetricTile(
                      Icons.air,
                      units.height(current.windWaveHeight),
                      'Wind Wave Height',
                    ),
                  ];
                  final wideText =
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: items
                        .map(
                          (tile) => SizedBox(
                            width: wideText
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 12) / 3,
                            child: tile,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SectionTitle('Additional information'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SeaColors.mist),
                ),
                child: Column(
                  children: [
                    _reading(
                      'Sea temperature',
                      current.seaTemperature == null
                          ? 'Unavailable'
                          : '${current.seaTemperature!.toStringAsFixed(1)} \u00b0C',
                    ),
                    const Divider(),
                    _reading(
                      'Data source',
                      data.repository.isDemo
                          ? 'Demo sample'
                          : 'Open-Meteo Marine',
                    ),
                    const Divider(),
                    _reading('Forecast area', 'Regional Lianga'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Notice(
              'Check the regional advisory and local warnings before coastal activities.',
            ),
            const Attribution(),
          ],
        ),
      ),
    );
  }

  Widget _reading(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: SeaColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

String compactTime(DateTime time, {bool daily = false}) {
  final d = time.toUtc().add(const Duration(hours: 8));
  return '${d.month}/${d.day}${daily ? '' : ' ${d.hour.toString().padLeft(2, '0')}:00'}';
}

class _ForecastPainter extends CustomPainter {
  _ForecastPainter(this.values, this.selected, this.bars);
  final List<double?> values;
  final int selected;
  final bool bars;
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue =
        values.whereType<double>().fold<double>(1, math.max) * 1.15;
    final paint = Paint()
      ..color = SeaColors.mist
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = 8 + (size.height - 16) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final path = Path();
    bool connected = false;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == null) {
        connected = false;
        continue;
      }
      final x = bars
          ? (i + .5) / values.length * size.width
          : values.length == 1
          ? size.width / 2
          : i / (values.length - 1) * size.width;
      final y = size.height - 8 - values[i]! / maxValue * (size.height - 16);
      if (bars) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              x - size.width / values.length * .28,
              y,
              x + size.width / values.length * .28,
              size.height - 8,
            ),
            const Radius.circular(4),
          ),
          Paint()..color = i == selected ? SeaColors.ink : SeaColors.ocean,
        );
      } else {
        if (connected) {
          path.lineTo(x, y);
        } else {
          path.moveTo(x, y);
        }
        connected = true;
        canvas.drawCircle(
          Offset(x, y),
          i == selected ? 6 : 2.5,
          Paint()..color = i == selected ? SeaColors.ink : SeaColors.ocean,
        );
      }
    }
    if (!bars) {
      if (values.isNotEmpty && values.every((v) => v != null)) {
        final area = Path.from(path)
          ..lineTo(size.width, size.height - 8)
          ..lineTo(0, size.height - 8)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x660087FF), Color(0x080087FF)],
            ).createShader(Offset.zero & size),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = SeaColors.ocean
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ForecastPainter oldDelegate) => true;
}

class _CurrentForecastCard extends StatelessWidget {
  const _CurrentForecastCard({required this.current});
  final MarinePoint? current;
  @override
  Widget build(BuildContext context) {
    final units = context.watch<AppPreferences>();
    final advisory = context.watch<PublicDataProvider>().snapshot?.advisory;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Today's Marine Conditions",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (current != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                stamp(current!.time),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth >= 330 &&
                      MediaQuery.textScalerOf(context).scale(1) <= 1.3
                  ? 4
                  : 2;
              final cards = [
                MarineMetricCard(
                  Icons.waves,
                  units.height(current?.height),
                  'Wave Height',
                  const Color(0xFF0087FF),
                ),
                MarineMetricCard(
                  Icons.explore_outlined,
                  current?.direction == null
                      ? 'Unavailable'
                      : '${current!.direction!.round()}\u00b0',
                  'Wave Direction',
                  const Color(0xFF09A39E),
                ),
                MarineMetricCard(
                  Icons.schedule,
                  current?.period == null
                      ? 'Unavailable'
                      : '${current!.period!.toStringAsFixed(1)} s',
                  'Wave Period',
                  const Color(0xFFDA9100),
                ),
                MarineMetricCard(
                  Icons.air,
                  units.height(current?.windWaveHeight),
                  'Wind Wave Height',
                  const Color(0xFF8846D7),
                ),
              ];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 8) /
                            columns,
                        child: card,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: advisory?.level.background ?? SeaColors.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  advisory?.level.icon ?? Icons.info_outline,
                  color: advisory?.level.color ?? SeaColors.ocean,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advisory == null
                            ? 'Regional advisory unavailable'
                            : '${advisory.level.label} \u00b7 Regional advisory',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: SeaColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Marine conditions are regional. This is not a swimming advisory.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
