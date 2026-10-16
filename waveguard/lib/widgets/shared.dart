import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/public_data.dart';
import '../providers/public_data_provider.dart';
import '../services/external_actions.dart';
import '../theme/app_theme.dart';
import 'marine_visuals.dart';

String stamp(DateTime date) {
  // Lianga uses Philippine Standard Time, independent of device timezone.
  final d = date.toUtc().add(const Duration(hours: 8));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} PHT';
}

extension LevelStyle on AdvisoryLevel {
  String get label => switch (this) {
    AdvisoryLevel.safe => 'Safe',
    AdvisoryLevel.caution => 'Caution',
    AdvisoryLevel.dangerous => 'Dangerous',
  };
  IconData get icon => switch (this) {
    AdvisoryLevel.safe => Icons.check_circle_outline,
    AdvisoryLevel.caution => Icons.warning_amber_rounded,
    AdvisoryLevel.dangerous => Icons.dangerous_outlined,
  };
  Color get color => switch (this) {
    AdvisoryLevel.safe => const Color(0xFF146348),
    AdvisoryLevel.caution => const Color(0xFF80500A),
    AdvisoryLevel.dangerous => SeaColors.danger,
  };
  Color get background => switch (this) {
    AdvisoryLevel.safe => const Color(0xFFE3F3EC),
    AdvisoryLevel.caution => const Color(0xFFFFF1D5),
    AdvisoryLevel.dangerous => const Color(0xFFFCE6E9),
  };
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SeaMark(size: 34),
      const SizedBox(width: 12),
      const Flexible(
        child: Text(
          'WaveGuard',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.8,
            color: SeaColors.ink,
          ),
        ),
      ),
    ],
  );
}

class PageBody extends StatelessWidget {
  const PageBody({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: children,
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(
    this.message, {
    this.icon = Icons.info_outline,
    this.warning = false,
    super.key,
  });
  final String message;
  final IconData icon;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF1D5) : SeaColors.mist,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: warning ? const Color(0xFF80500A) : SeaColors.ink,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: warning ? const Color(0xFF704409) : SeaColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class DataNotices extends StatelessWidget {
  const DataNotices({super.key});
  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data.isDemo)
          const Notice(
            'Demo preview · Sample statuses, beach locations, warnings, and incidents. Do not use for safety decisions.',
            icon: Icons.science_outlined,
          ),
        if (data.offline)
          Notice(
            data.snapshot == null
                ? 'No connection. No saved information is available.'
                : 'No connection. Showing saved information.',
            icon: Icons.wifi_off,
            warning: true,
          ),
        if (data.outdated)
          const Notice(
            'Outdated · The advisory could not be verified as current. Check with local authorities.',
            icon: Icons.update,
            warning: true,
          ),
        if (data.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.error!,
                  style: const TextStyle(color: SeaColors.danger),
                ),
                TextButton.icon(
                  onPressed: data.loading ? null : data.load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        if (data.cacheWarning != null)
          Notice(data.cacheWarning!, warning: true),
        if (data.loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.subtitle, super.key});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(subtitle!),
          ),
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.level, {super.key});
  final AdvisoryLevel level;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: level.background,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(level.icon, size: 18, color: level.color),
        const SizedBox(width: 5),
        Text(
          level.label,
          style: TextStyle(fontWeight: FontWeight.w700, color: level.color),
        ),
      ],
    ),
  );
}

class AdvisoryCard extends StatelessWidget {
  const AdvisoryCard({
    required this.advisory,
    this.outdated = false,
    this.demo = false,
    super.key,
  });
  final RegionalAdvisory advisory;
  final bool outdated, demo;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: advisory.level.background,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: advisory.level.color.withValues(alpha: .2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          demo ? 'Sample regional advisory' : 'Lianga regional advisory',
          style: TextStyle(color: advisory.level.color),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(advisory.level.icon, color: advisory.level.color, size: 38),
            Text(
              advisory.level.label,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: advisory.level.color),
            ),
            if (outdated)
              const Chip(
                label: Text('Outdated'),
                avatar: Icon(Icons.update, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          advisory.recommendation,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: advisory.level.color,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Source updated ${stamp(advisory.updatedAt)}',
          style: TextStyle(fontSize: 12, color: advisory.level.color),
        ),
      ],
    ),
  );
}

class CantilWarning extends StatelessWidget {
  const CantilWarning({super.key});
  @override
  Widget build(BuildContext context) => const Notice(
    'Cantil warning · Sudden underwater drop. Follow posted warnings and local guidance.',
    icon: Icons.warning_amber_rounded,
    warning: true,
  );
}

class BeachTile extends StatelessWidget {
  const BeachTile(this.beach, {required this.onTap, super.key});
  final Beach beach;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    color: Colors.white,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: const SizedBox(
          width: 66,
          height: 66,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CoastalPhoto(alignment: Alignment.centerLeft),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: Color(0x99003257),
                  child: Text(
                    'Illustration',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      title: Text(
        beach.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: SeaColors.ink,
        ),
      ),
      subtitle: Text(
        beach.hasCantil
            ? 'Cantil · Sudden-drop warning'
            : 'Lianga, Surigao del Sur',
      ),
      trailing: Icon(
        beach.hasCantil ? Icons.warning_amber_rounded : Icons.chevron_right,
        color: beach.hasCantil ? const Color(0xFF80500A) : SeaColors.ocean,
      ),
      onTap: onTap,
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.message, {
    this.icon = Icons.inbox_outlined,
    super.key,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 10),
    child: Column(
      children: [
        Icon(icon, size: 40, color: SeaColors.muted),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class Attribution extends StatelessWidget {
  const Attribution({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      children: [
        TextButton(
          onPressed: () async {
            final opened = await context.read<ExternalActions>().open(
              Uri.parse('https://open-meteo.com/'),
            );
            if (!opened && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open Open-Meteo.')),
              );
            }
          },
          child: const Text('Weather data attribution: Open-Meteo'),
        ),
        const Text(
          'Regional guidance. Always follow local authorities.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
