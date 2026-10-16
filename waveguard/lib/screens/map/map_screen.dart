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
import '../beach_detail/beach_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _tileError = false, _mapReady = false;
  int _attempt = 0;
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
    final incidents = data.snapshot?.incidents ?? <Incident>[];
    return PageBody(
      children: [
        Text(
          'Find your stretch of coast',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        const Text('Lianga, Surigao del Sur · No location tracking'),
        const SizedBox(height: 16),
        const DataNotices(),
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
                        ...beaches.map(
                          (beach) => Marker(
                            point: LatLng(beach.latitude, beach.longitude),
                            width: 52,
                            height: 52,
                            child: IconButton.filled(
                              tooltip: beach.name,
                              onPressed: () => openBeach(context, beach.id),
                              icon: const Icon(Icons.beach_access, size: 25),
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
        const SectionTitle(
          'Beaches',
          subtitle: 'Blue markers: beaches. Red markers: incident records.',
        ),
        if (beaches.isEmpty && !data.loading)
          const EmptyState(
            'No beach records',
            'Beach markers will appear when verified records are available.',
          ),
        ...beaches.map(
          (beach) =>
              BeachTile(beach, onTap: () => openBeach(context, beach.id)),
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
