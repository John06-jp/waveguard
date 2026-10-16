import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_preferences.dart';
import '../../services/auth_service.dart';
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
  Widget build(BuildContext context) => const SettingsScreen(embedded: true);
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
  const SettingsScreen({this.embedded = false, super.key});
  final bool embedded;
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
  void _info(BuildContext context, String title, String message) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferences>();
    final session = context.watch<SessionProvider>();
    Widget row(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap, {
      Color? color,
    }) => ListTile(
      leading: Icon(icon, color: color ?? SeaColors.ink, size: 25),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color ?? SeaColors.ink,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? const Color(0xFF718BAA),
      ),
      onTap: onTap,
    );
    Widget group(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF657FA4),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: SeaColors.mist,
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
    void account() => _info(
      context,
      'Account Settings',
      session.profile == null
          ? 'You are exploring as a guest. Sign in to access your WaveGuard account.'
          : 'Signed in as ${session.profile!.email}. Contact the project administrator to update account information.',
    );
    final body = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE5F1FF), Color(0xFFF5FAFF)],
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
                child: ColoredBox(color: Color(0x5500417A)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 26),
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
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage your account, preferences, and app settings.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .9),
              borderRadius: BorderRadius.circular(22),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              leading: const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF78AFF0),
                child: Icon(Icons.person, color: Colors.white, size: 38),
              ),
              title: Text(
                session.profile == null
                    ? 'Guest explorer'
                    : 'WaveGuard account',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SeaColors.ink,
                ),
              ),
              subtitle: Text(
                session.profile?.email ??
                    'Explore regional coastal information',
              ),
              trailing: const Icon(Icons.chevron_right, color: SeaColors.ocean),
              onTap: account,
            ),
          ),
          group('GENERAL', [
            row(
              Icons.person_outline,
              'Account Settings',
              'View your account information',
              account,
            ),
            SwitchListTile(
              secondary: const Icon(
                Icons.notifications_outlined,
                color: SeaColors.ink,
              ),
              title: const Text(
                'Notifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Alert preference; delivery not connected.',
                style: TextStyle(fontSize: 12),
              ),
              value: prefs.alerts,
              onChanged: prefs.setAlerts,
            ),
            row(
              Icons.location_on_outlined,
              'Location',
              'Lianga, Surigao del Sur',
              () => _info(
                context,
                'Regional location',
                'Lianga is the fixed study area. Device-location tracking is not used.',
              ),
            ),
          ]),
          group('PREFERENCES', [
            row(
              Icons.thermostat_outlined,
              'Units',
              prefs.imperial ? 'Imperial (ft, mph)' : 'Metric (m, km/h)',
              () => _units(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Metric')),
                  ButtonSegment(value: true, label: Text('Imperial')),
                ],
                selected: {prefs.imperial},
                onSelectionChanged: (values) => prefs.setImperial(values.first),
              ),
            ),
            row(
              Icons.language,
              'Language',
              'English',
              () => _info(
                context,
                'Language',
                'English is the available language for this research prototype.',
              ),
            ),
            row(
              Icons.palette_outlined,
              'App Theme',
              'Coastal light',
              () => _info(
                context,
                'App Theme',
                'WaveGuard currently uses the coastal light theme.',
              ),
            ),
          ]),
          group('DATA & STORAGE', [
            row(
              Icons.download_outlined,
              'Offline Maps',
              'Map connection and availability',
              () => _info(
                context,
                'Offline Maps',
                'Downloading map regions is not available. The map needs a connection; saved beach and advisory records remain accessible when available.',
              ),
            ),
            row(
              Icons.storage_outlined,
              'Manage Data',
              'Saved regional information',
              () => _info(
                context,
                'Manage Data',
                'WaveGuard keeps the latest available regional records on this device. Pull down on Home or Forecast to refresh.',
              ),
            ),
          ]),
          group('SUPPORT', [
            row(
              Icons.help_outline,
              'Help & FAQs',
              'Find answers to common questions',
              () => _info(
                context,
                'Help & FAQs',
                'Forecasts cover the Lianga region. Pull down to refresh. Outdated data is labeled. Beach warnings describe stored records. Use SOS to view configured emergency contacts.',
              ),
            ),
            row(
              Icons.shield_outlined,
              'Privacy Policy',
              'Privacy information for this prototype',
              () => _info(
                context,
                'Privacy information',
                'WaveGuard does not request GPS location. Preferences and cached regional data are saved on this device. Connected accounts use Firebase Authentication. A published privacy policy has not yet been supplied by the project team.',
              ),
            ),
            row(
              Icons.description_outlined,
              'Terms of Service',
              'Research prototype information',
              () => _info(
                context,
                'Prototype use',
                'WaveGuard is a research and information prototype. Regional forecasts are not an official swimming advisory. Follow local authorities. Published terms have not yet been supplied by the project team.',
              ),
            ),
            row(
              Icons.info_outline,
              'About WaveGuard',
              'Version 1.0.0',
              () => openMainPage(context, const AboutScreen()),
            ),
            row(
              Icons.health_and_safety_outlined,
              'Safety Tips',
              'Prepare before heading to the water',
              () => openMainPage(context, const SafetyTipsScreen()),
            ),
            row(
              Icons.history,
              'Advisory history',
              'Past regional statuses',
              () => openMainPage(
                context,
                Scaffold(
                  appBar: AppBar(title: const Text('Advisory history')),
                  body: const HistoryScreen(),
                ),
              ),
            ),
            row(
              Icons.map_outlined,
              'Historical Incident Map',
              'Explore recorded incidents',
              () => openMainPage(
                context,
                Scaffold(
                  appBar: AppBar(title: const Text('Historical Incident Map')),
                  body: const MapScreen(incidentsOnly: true),
                ),
              ),
            ),
            row(
              Icons.sos,
              'SOS & Emergency Contacts',
              'Emergency calling options',
              () => openMainPage(context, const SosScreen(standalone: true)),
            ),
          ]),
          if (prefs.saveError != null) Notice(prefs.saveError!, warning: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFDDE5)),
              ),
              child: row(
                Icons.logout,
                session.guest ? 'Back to login' : 'Log Out',
                '',
                () async {
                  try {
                    await session.leave();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not sign out. Please try again.',
                          ),
                        ),
                      );
                    }
                  }
                },
                color: SeaColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    return embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: body,
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
