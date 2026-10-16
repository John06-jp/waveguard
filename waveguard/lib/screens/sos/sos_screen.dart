import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_config.dart';
import '../../services/external_actions.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../../widgets/marine_visuals.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({
    this.standalone = false,
    this.phone = AppConfig.emergencyPhone,
    super.key,
  });
  final bool standalone;
  final String phone;
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _busy = false;
  String? _message;
  bool get _configured =>
      RegExp(r'^\+?[0-9][0-9 ()-]{5,19}$').hasMatch(widget.phone);
  bool _validPhone(String value) =>
      RegExp(r'^\+?[0-9][0-9 ()-]{5,19}$').hasMatch(value);
  Future<void> _confirm([String? number]) async {
    final selectedPhone = number ?? widget.phone;
    final configured = _validPhone(selectedPhone);
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          configured
              ? 'Open the phone dialer?'
              : 'Emergency contact unavailable',
        ),
        content: Text(
          configured
              ? 'The phone dialer will open with $selectedPhone. You must place the call yourself. WaveGuard does not send your location or an emergency report.'
              : 'A verified MDRRMO number has not been supplied for this build. This button cannot contact responders. Use your phone to call a known local emergency contact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(configured ? 'Cancel' : 'Close'),
          ),
          if (configured)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open dialer'),
            ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final phone = selectedPhone.replaceAll(RegExp(r'[^+0-9]'), '');
    final opened = await context.read<ExternalActions>().open(
      Uri(scheme: 'tel', path: phone),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = opened
          ? 'Phone dialer opened. Place the call in your phone app. No emergency report was sent.'
          : 'Could not open the phone dialer. Call $selectedPhone manually from your phone.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final contacts = <(String, String, IconData)>[
      ('MDRRMO - Lianga', widget.phone, Icons.waves),
      (
        'Philippine Coast Guard',
        AppConfig.coastGuardPhone,
        Icons.sailing_outlined,
      ),
      ('PNP - Lianga', AppConfig.policePhone, Icons.local_police_outlined),
      (
        'Rural Health Unit',
        AppConfig.healthUnitPhone,
        Icons.health_and_safety_outlined,
      ),
    ];
    final body = PageBody(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5E7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SeaIcon(Icons.phone_in_talk, color: Color(0xFFFF454E)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency assistance',
                      style: TextStyle(
                        color: SeaColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'In case of emergency, contact the authorities immediately.',
                      style: TextStyle(color: SeaColors.danger, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...contacts.map((contact) {
          final available = _validPhone(contact.$2);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              leading: SeaIcon(
                contact.$3,
                color: contact.$3 == Icons.health_and_safety_outlined
                    ? const Color(0xFFEB8A16)
                    : SeaColors.ocean,
              ),
              title: Text(
                contact.$1,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SeaColors.ink,
                  fontSize: 14,
                ),
              ),
              subtitle: available
                  ? SelectableText(contact.$2)
                  : const Text(
                      'Verified contact pending',
                      style: TextStyle(fontSize: 12),
                    ),
              trailing: IconButton(
                tooltip: contact.$1 == 'MDRRMO - Lianga'
                    ? 'Call MDRRMO'
                    : 'Call ${contact.$1}',
                onPressed: available && !_busy
                    ? () => _confirm(contact.$2)
                    : null,
                icon: const Icon(Icons.phone, color: SeaColors.ocean),
              ),
            ),
          );
        }),
        if (!_configured)
          OutlinedButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.info_outline),
            label: const Text('SOS options'),
          ),
        if (_busy) const LinearProgressIndicator(),
        if (_message != null)
          Semantics(liveRegion: true, child: Notice(_message!, warning: true)),
        const SizedBox(height: 10),
        const Notice(
          'Verify current local numbers with your LGU. Contacts marked pending cannot be called from this app.',
        ),
        const Notice(
          'Calls open your phone dialer after confirmation. WaveGuard does not send your location, dispatch rescue, or submit an emergency report.',
          icon: Icons.location_off_outlined,
        ),
      ],
    );
    return widget.standalone
        ? Scaffold(
            appBar: AppBar(title: const Text('Emergency Contacts')),
            body: body,
          )
        : body;
  }
}
