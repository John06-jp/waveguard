import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/marine_forecast.dart';
import '../../providers/marine_provider.dart';
import '../../services/app_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

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
          Text(
            _daily ? 'Seven days at sea' : 'The next 48 hours',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('Lianga regional marine forecast'),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Hourly')),
              ButtonSegment(value: true, label: Text('7-Day')),
            ],
            selected: {_daily},
            onSelectionChanged: (selection) => setState(() {
              _daily = selection.first;
              _selected = 0;
            }),
          ),
          const SizedBox(height: 16),
          const MarineNotices(),
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
            const SizedBox(height: 20),
            Text(
              display(selected),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(stamp(selected.time)),
            const SizedBox(height: 12),
            Semantics(
              label:
                  'Forecast chart. Use the slider below to inspect each ${_daily ? 'day' : 'hour'}.',
              child: SizedBox(
                height: 180,
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
            const SectionTitle('Forecast data'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
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
                          DataCell(Text(stamp(p.time))),
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
      appBar: AppBar(title: const Text('Current marine weather')),
      body: RefreshIndicator(
        onRefresh: data.load,
        child: PageBody(
          children: [
            Text(
              'Lianga, Surigao del Sur',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text('Regional forecast point · 8.6336° N, 126.0947° E'),
            const SizedBox(height: 20),
            const MarineNotices(),
            if (current == null && !data.loading)
              const EmptyState(
                'Current conditions unavailable',
                'Retry to request the latest marine data.',
              ),
            if (current != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: SeaColors.ocean,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.waves, color: Colors.white, size: 42),
                    const SizedBox(height: 14),
                    Text(
                      units.height(current.height),
                      style: const TextStyle(
                        fontSize: 38,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Wave height',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Valid at ${stamp(current.time)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.explore_outlined),
                title: const Text('Wave direction'),
                trailing: Text(
                  current.direction == null
                      ? 'Unavailable'
                      : '${current.direction!.round()}°',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Wave period'),
                trailing: Text(
                  current.period == null
                      ? 'Unavailable'
                      : '${current.period!.toStringAsFixed(1)} s',
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Notice(
              'Marine conditions are model estimates, not an official swimming advisory. Check the separate regional advisory and local warnings.',
            ),
            const Attribution(),
          ],
        ),
      ),
    );
  }
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
