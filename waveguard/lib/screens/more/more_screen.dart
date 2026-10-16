import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_preferences.dart';
import '../../services/external_actions.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
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
        const Scaffold(body: SafeArea(child: MapScreen(incidentsOnly: true))),
      ),
      _link(
        context,
        Icons.history,
        'Advisory history',
        'Past regional statuses',
        const Scaffold(body: SafeArea(child: HistoryScreen())),
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
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(
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
    appBar: AppBar(title: const Text('Safety Tips')),
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
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(
                Icons.health_and_safety_outlined,
                color: SeaColors.ocean,
              ),
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
  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<AppPreferences>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: PageBody(
        children: [
          const SectionTitle('Regional location'),
          const ListTile(
            leading: Icon(Icons.location_on_outlined),
            title: Text('Lianga, Surigao del Sur'),
            subtitle: Text('Fixed regional forecast area. GPS is not used.'),
          ),
          const SectionTitle('Units'),
          RadioGroup<bool>(
            groupValue: preferences.imperial,
            onChanged: (value) {
              if (value != null) preferences.setImperial(value);
            },
            child: const Column(
              children: [
                RadioListTile<bool>(
                  value: false,
                  title: Text('Metric'),
                  subtitle: Text('Metres and kilometres per hour'),
                ),
                RadioListTile<bool>(
                  value: true,
                  title: Text('Imperial'),
                  subtitle: Text('Feet and miles per hour'),
                ),
              ],
            ),
          ),
          const SectionTitle('Notifications'),
          SwitchListTile(
            value: preferences.alerts,
            onChanged: preferences.setAlerts,
            title: const Text('Marine alert preference'),
            subtitle: const Text(
              'Save your preference on this device. Notification delivery is not connected yet.',
            ),
          ),
          if (preferences.saveError != null)
            Notice(preferences.saveError!, warning: true),
          const SectionTitle('Location preferences'),
          const Notice(
            'All screens use the Lianga regional location. Beach-specific forecasts and device-location tracking are outside this study scope.',
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
        const Center(child: Brand()),
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
