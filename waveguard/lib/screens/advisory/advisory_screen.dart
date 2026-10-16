import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/public_data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../beach_detail/beach_detail_screen.dart';

class AdvisoryScreen extends StatelessWidget {
  const AdvisoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    final snapshot = data.snapshot;
    final advisory = snapshot?.advisory;
    return RefreshIndicator(
      onRefresh: data.load,
      child: PageBody(
        children: [
          const Text(
            'A little awareness.\nA safer day by the sea.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -.7,
              color: SeaColors.ink,
            ),
          ),
          const SizedBox(height: 18),
          const DataNotices(),
          if (advisory != null) ...[
            AdvisoryCard(
              advisory: advisory,
              outdated: data.outdated,
              demo: data.isDemo,
            ),
            const SectionTitle('Behind the advisory'),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Condition(
                    Icons.waves,
                    'Wave height',
                    '${advisory.waveHeight.toStringAsFixed(1)} m',
                    constraints.maxWidth,
                  ),
                  _Condition(
                    Icons.air,
                    'Wind speed',
                    '${advisory.windSpeed.toStringAsFixed(0)} km/h',
                    constraints.maxWidth,
                  ),
                  _Condition(
                    Icons.timer_outlined,
                    'Wave period',
                    '${advisory.wavePeriod.toStringAsFixed(1)} s',
                    constraints.maxWidth,
                  ),
                ],
              ),
            ),
          ] else if (!data.loading)
            const EmptyState(
              'Advisory unavailable',
              'There is no current regional status to display. Check with local authorities.',
              icon: Icons.waves,
            ),
          const SizedBox(height: 16),
          const Notice(
            'One regional advisory covers Lianga. Conditions can vary at individual beaches.',
          ),
          const SectionTitle(
            'Explore the coast',
            subtitle: 'Check local warnings before heading to the water.',
          ),
          if (snapshot != null && snapshot.beaches.isNotEmpty)
            ...snapshot.beaches.map(
              (beach) =>
                  BeachTile(beach, onTap: () => openBeach(context, beach.id)),
            )
          else if (!data.loading)
            const EmptyState(
              'No beaches available',
              'Beach information will appear when records are available.',
            ),
          const Attribution(),
        ],
      ),
    );
  }
}

class _Condition extends StatelessWidget {
  const _Condition(this.icon, this.label, this.value, this.availableWidth);
  final IconData icon;
  final String label, value;
  final double availableWidth;
  @override
  Widget build(BuildContext context) => Container(
    width:
        availableWidth < 340 || MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? availableWidth
        : (availableWidth - 16) / 3,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: SeaColors.ocean),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SeaColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    ),
  );
}
