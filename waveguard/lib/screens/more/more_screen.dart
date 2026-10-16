import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_preferences.dart';
import '../../services/external_actions.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../../widgets/marine_visuals.dart';
import '../history/history_screen.dart';
import '../map/map_screen.dart';
import '../sos/sos_screen.dart';

void openMainPage(BuildContext context, Widget screen) =>
    Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => screen));

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Text(
        'More from WaveGuard',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 20),
      _link(
        context,
        Icons.sos,
        'SOS & Emergency Contacts',
        'Emergency calling options',
        const SosScreen(standalone: true),
      ),
      _link(
        context,
        Icons.history_edu,
        'Historical Incident Map',
        'Explore recorded incidents',
        Scaffold(
          appBar: AppBar(title: const Text('Historical Incident Map')),
          body: const SafeArea(child: MapScreen(incidentsOnly: true)),
        ),
      ),
      _link(
        context,
        Icons.history,
        'Advisory history',
        'Past regional statuses',
        Scaffold(
          appBar: AppBar(title: const Text('Advisory history')),
          body: const SafeArea(child: HistoryScreen()),
        ),
      ),
      _link(
        context,
        Icons.health_and_safety_outlined,
        'Safety Tips',
        'Prepare before heading to the water',
        const SafetyTipsScreen(),
      ),
      _link(
        context,
        Icons.settings_outlined,
        'Settings',
        'Units, alerts, and regional location',
        const SettingsScreen(),
      ),
      _link(
        context,
        Icons.info_outline,
        'About WaveGuard',
        'Data sources and application details',
        const AboutScreen(),
      ),
    ],
  );
  Widget _link(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget page,
  ) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      leading: SeaIcon(
        icon,
        color: icon == Icons.sos ? SeaColors.danger : SeaColors.ocean,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openMainPage(context, page),
    ),
  );
}

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Water Safety Tips')),
    body: PageBody(
      children: [
        Text(
          'Prepare for the coast',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const Notice(
          'Follow posted beach warnings and instructions from local authorities. This screen provides general reminders.',
        ),
        ...const [
          (
            'Check before you go',
            'Check marine forecasts and the latest local advisories before coastal activities.',
          ),
          (
            'Respect rough water',
            'Avoid entering rough water. Stay away from exposed shoreline edges during high waves.',
          ),
          (
            'Watch for cantil',
            'Sudden underwater drop-offs can occur close to shore. Follow marked boundaries and local guidance.',
          ),
          (
            'Prepare your equipment',
            'Use an appropriate life jacket for boating and keep emergency contacts available.',
          ),
          (
            'Look out for one another',
            'Avoid swimming alone and supervise children near water. Seek trained assistance in an emergency.',
          ),
        ].map(
          (tip) => Card(
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              leading: const SeaIcon(Icons.health_and_safety_outlined),
              title: Text(tip.$1),
              subtitle: Text(tip.$2),
            ),
          ),
        ),
        const SectionTitle('Official guidance'),
        TextButton(
          onPressed: () async {
            final ok = await context.read<ExternalActions>().open(
              Uri.parse('https://www.pagasa.dost.gov.ph/'),
            );
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open PAGASA.')),
              );
            }
          },
          child: const Text('Open PAGASA weather and marine advisories'),
        ),
        const Text(
          'Verified Lianga MDRRMO guidance will be added when provided by the project team.',
        ),
      ],
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  void _units(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => Consumer<AppPreferences>(
      builder: (context, preferences, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RadioGroup<bool>(
            groupValue: preferences.imperial,
            onChanged: (value) {
              if (value != null) preferences.setImperial(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Display units',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const RadioListTile<bool>(
                  value: false,
                  title: Text('Metric'),
                  subtitle: Text('Metres and kilometres per hour'),
                ),
                const RadioListTile<bool>(
                  value: true,
                  title: Text('Imperial'),
                  subtitle: Text('Feet and miles per hour'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferences>();
    Widget row(
      IconData icon,
      String title,
      String subtitle, {
      VoidCallback? onTap,
    }) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: SeaIcon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right, color: SeaColors.ocean),
        onTap: onTap,
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        children: [
          row(
            Icons.location_on,
            'Select Default Location',
            'Lianga, Surigao del Sur',
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Regional location'),
                content: const Text(
                  'Lianga is the fixed study area. Device-location tracking is not used.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
          row(
            Icons.straighten,
            'Units',
            prefs.imperial ? 'Imperial (ft, mph)' : 'Metric (m, km/h)',
            onTap: () => _units(context),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: SwitchListTile(
              secondary: const SeaIcon(
                Icons.notifications,
                color: Color(0xFFFF494E),
              ),
              value: prefs.alerts,
              onChanged: prefs.setAlerts,
              title: const Text(
                'Notifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Marine alert preference. Delivery not connected.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          row(
            Icons.update,
            'Data Update Interval',
            'On screen open and manual refresh',
          ),
          row(Icons.palette_outlined, 'App Theme', 'Coastal light'),
          row(Icons.language, 'Language', 'English'),
          if (prefs.saveError != null) Notice(prefs.saveError!, warning: true),
          const SizedBox(height: 12),
          const Notice(
            'Units and alert preferences are saved on this device. Forecasts remain regional; no GPS permission is required.',
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About WaveGuard')),
    body: PageBody(
      children: [
        const Center(child: SeaMark(size: 80)),
        const SizedBox(height: 8),
        Text(
          'WaveGuard',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        const Text(
          'Marine Weather Information System',
          textAlign: TextAlign.center,
        ),
        const Text('Version 1.0.0', textAlign: TextAlign.center),
        const SectionTitle('Built for Lianga'),
        const Text(
          'WaveGuard presents regional marine conditions, coastal information, and stored advisories for research and informational use. Follow local authorities for official safety instructions.',
        ),
        const SectionTitle('Marine data'),
        Table(
          border: const TableBorder(
            horizontalInside: BorderSide(color: SeaColors.mist),
          ),
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1.6)},
          children: const [
            TableRow(
              children: [
                Padding(padding: EdgeInsets.all(8), child: Text('Provider')),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Open-Meteo Marine API'),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(padding: EdgeInsets.all(8), child: Text('Model')),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Best Match selection'),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(padding: EdgeInsets.all(8), child: Text('Resolution')),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Depends on upstream model'),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(padding: EdgeInsets.all(8), child: Text('Refresh')),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Screen open / manual'),
                ),
              ],
            ),
          ],
        ),
        const Text(
          'Live forecast mode uses the Open-Meteo Marine Weather API with Best Match model selection. Current values are model estimates. Coverage and update timing depend on the upstream model; retrieved time is shown separately from the valid time.',
        ),
        const SectionTitle('Regional advisory model'),
        const Text(
          'Regional safety classifications are read from the project backend. The proposed Random Forest prediction model runs outside this app. Its training, evaluation, and validated performance must be documented by the research team before live use.',
        ),
        const SectionTitle('Beaches and incidents'),
        const Text(
          'Cantil flags and incident summaries are stored project records. Demo records are fictional; verified local records must be supplied before operational use.',
        ),
        const Attribution(),
      ],
    ),
  );
}
