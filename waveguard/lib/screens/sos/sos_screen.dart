import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_config.dart';
import '../../services/external_actions.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared.dart';

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
  Future<void> _confirm() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _configured
              ? 'Open the phone dialer?'
              : 'Emergency contact unavailable',
        ),
        content: Text(
          _configured
              ? 'The phone dialer will open with ${widget.phone}. You must place the call yourself. WaveGuard does not send your location or an emergency report.'
              : 'A verified MDRRMO number has not been supplied for this build. This button cannot contact responders. Use your phone to call a known local emergency contact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_configured ? 'Cancel' : 'Close'),
          ),
          if (_configured)
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
    final phone = widget.phone.replaceAll(RegExp(r'[^+0-9]'), '');
    final opened = await context.read<ExternalActions>().open(
      Uri(scheme: 'tel', path: phone),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = opened
          ? 'Phone dialer opened. Place the call in your phone app. No emergency report was sent.'
          : 'Could not open the phone dialer. Call ${widget.phone} manually from your phone.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = PageBody(
      children: [
        Text(
          'Emergency assistance',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        const Text(
          'If you are in danger, move to a safer place if possible and contact local responders.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 28),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: SeaColors.danger,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                onPressed: _busy ? null : _confirm,
                child: Column(
                  children: [
                    const Icon(Icons.sos, size: 64),
                    const SizedBox(height: 8),
                    Text(
                      _busy
                          ? 'Opening…'
                          : _configured
                          ? 'Call MDRRMO'
                          : 'SOS options',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Notice(
          _configured
              ? 'Opens your phone dialer after confirmation. A call still needs to be placed.'
              : 'Calling is unavailable until a verified emergency number is configured.',
          warning: !_configured,
          icon: Icons.phone_outlined,
        ),
        if (_message != null)
          Semantics(liveRegion: true, child: Notice(_message!, warning: true)),
        const SectionTitle('Emergency contact'),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lianga MDRRMO',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _configured ? widget.phone : 'Verified number not supplied',
                  style: const TextStyle(fontSize: 20, color: SeaColors.ink),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep a verified local emergency contact saved in your phone.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Notice(
          'WaveGuard does not track your location or dispatch rescue services. Tell responders where you are.',
          icon: Icons.location_off_outlined,
        ),
      ],
    );
    return widget.standalone
        ? Scaffold(
            appBar: AppBar(title: const Text('SOS')),
            body: body,
          )
        : body;
  }
}
