import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/public_data.dart';
import '../../providers/public_data_provider.dart';
import '../../services/app_config.dart';
import '../../services/external_actions.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../../widgets/marine_visuals.dart';
import '../../providers/marine_provider.dart';
import '../../services/app_preferences.dart';
import '../beach_detail/beach_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({this.incidentsOnly = false, super.key});
  final bool incidentsOnly;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _tileError = false, _mapReady = false;
  int _attempt = 0;
  Beach? _selectedBeach;
  final _mapController = MapController();
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String? _incidentType;
  @override
  void initState() {
    super.initState();
    if (!widget.incidentsOnly) {
      Future.microtask(() {
        if (mounted) context.read<MarineProvider>().load();
      });
    }
  }

  void _failed() {
    if (_tileError || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tileError = true);
    });
  }

  void _incident(Incident incident) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(incident.type, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(stamp(incident.date)),
            const SizedBox(height: 14),
            Text(incident.summary),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openBeach(this.context, incident.beachId);
              },
              child: const Text('View beach information'),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    final beaches = data.snapshot?.beaches ?? <Beach>[];
    final allIncidents = data.snapshot?.incidents ?? <Incident>[];
    final incidents = allIncidents
        .where((i) => _incidentType == null || i.type == _incidentType)
        .toList();
    final marine = context.watch<MarineProvider>();
    return PageBody(
      children: [
        if (!widget.incidentsOnly) ...[
          const MarineHeader(
            title: 'Coastal Map',
            subtitle: 'Explore beaches and regional marine conditions.',
          ),
          const SizedBox(height: 12),
        ],
        const DataNotices(),
        if (widget.incidentsOnly) ...[
          const Notice(
            'Past incidents are records, not a forecast of present danger.',
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All types'),
                selected: _incidentType == null,
                onSelected: (_) => setState(() => _incidentType = null),
              ),
              ...allIncidents
                  .map((i) => i.type)
                  .toSet()
                  .map(
                    (type) => ChoiceChip(
                      label: Text(type),
                      selected: _incidentType == type,
                      onSelected: (_) => setState(() => _incidentType = type),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: (MediaQuery.sizeOf(context).height * .70).clamp(430, 680),
            child: Stack(
              children: [
                FlutterMap(
                  key: ValueKey(_attempt),
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(8.625, 126.093),
                    initialZoom: 12,
                    minZoom: 8,
                    maxZoom: 18,
                    onMapReady: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _mapReady = true);
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppConfig.tileUrl,
                      userAgentPackageName: 'com.example.waveguard',
                      errorTileCallback: (_, _, _) => _failed(),
                    ),
                    MarkerLayer(
                      markers: [
                        if (!widget.incidentsOnly)
                          Marker(
                            point: LatLng(
                              marine.forecast?.latitude ?? 8.6336,
                              marine.forecast?.longitude ?? 126.0947,
                            ),
                            width: 52,
                            height: 52,
                            child: IconButton.filled(
                              tooltip: 'Regional marine forecast point',
                              style: IconButton.styleFrom(
                                backgroundColor: SeaColors.ink,
                              ),
                              icon: const Icon(Icons.waves),
                              onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                builder: (_) => SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Lianga marine forecast',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        if (marine.forecast?.isDemo ?? true)
                                          const Text('Demo forecast values'),
                                        Text(
                                          context.read<AppPreferences>().height(
                                            marine.forecast?.current?.height,
                                          ),
                                        ),
                                        const Text(
                                          'Regional sea-grid point; not a beach-specific assessment.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ...beaches
                            .where(
                              (b) =>
                                  !widget.incidentsOnly ||
                                  incidents.any((i) => i.beachId == b.id),
                            )
                            .map(
                              (beach) => Marker(
                                point: LatLng(beach.latitude, beach.longitude),
                                width: 145,
                                height: 70,
                                child: Semantics(
                                  selected: _selectedBeach?.id == beach.id,
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _selectedBeach = beach),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                _selectedBeach?.id == beach.id
                                                ? SeaColors.ink
                                                : SeaColors.ocean,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.beach_access,
                                            color: Colors.white,
                                            size: 23,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          child: Text(
                                            beach.name,
                                            style: const TextStyle(
                                              color: SeaColors.ink,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ...incidents
                            .where(
                              (i) => i.latitude != null && i.longitude != null,
                            )
                            .map(
                              (incident) => Marker(
                                point: LatLng(
                                  incident.latitude!,
                                  incident.longitude!,
                                ),
                                width: 48,
                                height: 48,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: SeaColors.danger,
                                  ),
                                  tooltip: incident.type,
                                  onPressed: () => _incident(incident),
                                  icon: const Icon(Icons.priority_high),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
                if (!widget.incidentsOnly)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 136,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Color(0x20002D4C), blurRadius: 12),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lianga',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: SeaColors.ink,
                            ),
                          ),
                          Text(
                            context.watch<AppPreferences>().height(
                              marine.forecast?.current?.height,
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: SeaColors.ink,
                            ),
                          ),
                          Text(
                            marine.forecast?.current?.period == null
                                ? 'Period unavailable'
                                : '${marine.forecast!.current!.period!.toStringAsFixed(1)} s',
                          ),
                          if (marine.repository.isDemo)
                            const Text(
                              'Sample forecast',
                              style: TextStyle(
                                fontSize: 10,
                                color: SeaColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  top: 140,
                  child: Material(
                    color: Colors.white,
                    elevation: 3,
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Zoom in',
                          onPressed: !_mapReady
                              ? null
                              : () => _mapController.move(
                                  _mapController.camera.center,
                                  (_mapController.camera.zoom + 1).clamp(8, 18),
                                ),
                          icon: const Icon(Icons.add, color: SeaColors.ink),
                        ),
                        IconButton(
                          tooltip: 'Zoom out',
                          onPressed: !_mapReady
                              ? null
                              : () => _mapController.move(
                                  _mapController.camera.center,
                                  (_mapController.camera.zoom - 1).clamp(8, 18),
                                ),
                          icon: const Icon(Icons.remove, color: SeaColors.ink),
                        ),
                        IconButton(
                          tooltip: 'Center on Lianga',
                          onPressed: !_mapReady
                              ? null
                              : () => _mapController.move(
                                  const LatLng(8.6336, 126.0947),
                                  12,
                                ),
                          icon: const Icon(
                            Icons.center_focus_strong,
                            color: SeaColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!widget.incidentsOnly &&
                    (_selectedBeach != null || beaches.isNotEmpty))
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: _BeachMapPreview(
                      beach: _selectedBeach ?? beaches.first,
                    ),
                  ),
                if (!_mapReady)
                  const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading map',
                    ),
                  ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              final opened = await context.read<ExternalActions>().open(
                Uri.parse(AppConfig.tileAttributionUrl),
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open map attribution.'),
                  ),
                );
              }
            },
            child: Text(
              AppConfig.tileAttribution,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        if (_tileError) ...[
          const Notice(
            'Map tiles could not load. Beach information remains available below.',
            warning: true,
            icon: Icons.map_outlined,
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _tileError = false;
              _mapReady = false;
              _attempt++;
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry map'),
          ),
        ],
        if (!widget.incidentsOnly)
          const SectionTitle(
            'Beaches',
            subtitle: 'Blue markers: beaches. Red markers: incident records.',
          ),
        if (!widget.incidentsOnly && beaches.isEmpty && !data.loading)
          const EmptyState(
            'No beach records',
            'Beach markers will appear when verified records are available.',
          ),
        ...beaches
            .where((b) => !widget.incidentsOnly)
            .map(
              (beach) =>
                  BeachTile(beach, onTap: () => openBeach(context, beach.id)),
            ),
        if (widget.incidentsOnly && incidents.isEmpty && !data.loading)
          const EmptyState(
            'No incident records',
            'No public incidents match this filter.',
          ),
        if (incidents.isNotEmpty) ...[
          const SectionTitle('Incident records'),
          ...incidents.map(
            (incident) => ListTile(
              leading: const Icon(
                Icons.report_outlined,
                color: SeaColors.danger,
              ),
              title: Text(incident.type),
              subtitle: Text(stamp(incident.date)),
              onTap: () => _incident(incident),
            ),
          ),
        ],
      ],
    );
  }
}

class _BeachMapPreview extends StatelessWidget {
  const _BeachMapPreview({required this.beach});
  final Beach beach;
  @override
  Widget build(BuildContext context) {
    final marine = context.watch<MarineProvider>();
    final current = marine.forecast?.current;
    final units = context.watch<AppPreferences>();
    return Material(
      color: Colors.white,
      elevation: 5,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SeaColors.mist,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.beach_access, color: SeaColors.ocean),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    beach.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'View beach details',
                  onPressed: () => openBeach(context, beach.id),
                  icon: const Icon(Icons.chevron_right, color: SeaColors.ocean),
                ),
              ],
            ),
            if (beach.hasCantil)
              const Text(
                'Cantil warning \u00b7 sudden drop-off',
                style: TextStyle(
                  color: SeaColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              marine.repository.isDemo
                  ? 'Sample regional marine conditions'
                  : 'Regional marine conditions',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                Text('Waves ${units.height(current?.height)}'),
                Text(
                  current?.direction == null
                      ? 'Direction unavailable'
                      : 'Direction ${current!.direction!.round()}\u00b0',
                ),
                Text(
                  current?.period == null
                      ? 'Period unavailable'
                      : 'Period ${current!.period!.toStringAsFixed(1)} s',
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Regional values; not a beach-specific safety assessment.',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
