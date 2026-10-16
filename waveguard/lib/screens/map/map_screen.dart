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
        Text(
          widget.incidentsOnly
              ? 'Historical Incident Map'
              : 'Marine weather map',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        const Text('Lianga, Surigao del Sur · No location tracking'),
        const SizedBox(height: 16),
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
            height: 330,
            child: Stack(
              children: [
                FlutterMap(
                  key: ValueKey(_attempt),
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
                                width: 52,
                                height: 52,
                                child: IconButton.filled(
                                  tooltip: beach.name,
                                  onPressed: () => openBeach(context, beach.id),
                                  icon: const Icon(
                                    Icons.beach_access,
                                    size: 25,
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
