import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/public_data_provider.dart';
import 'services/auth_service.dart';
import 'services/bootstrap.dart';
import 'services/external_actions.dart';
import 'theme/app_theme.dart';
import 'widgets/animated_waves.dart';
import 'widgets/shared.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_shell.dart';

class WaveGuardApp extends StatelessWidget {
  const WaveGuardApp({
    required this.dependencies,
    this.externalActions,
    this.splashDuration = const Duration(milliseconds: 900),
    super.key,
  });
  final AppDependencies dependencies;
  final ExternalActions? externalActions;
  final Duration splashDuration;
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<PublicDataProvider>(
        lazy: false,
        create: (_) => dependencies.data..load(),
      ),
      Provider<AuthService>.value(value: dependencies.auth),
      Provider<ExternalActions>.value(
        value: externalActions ?? PlatformExternalActions(),
      ),
      ChangeNotifierProvider(create: (_) => SessionProvider(dependencies.auth)),
    ],
    child: MaterialApp(
      title: 'WaveGuard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      navigatorObservers: [waveRouteObserver],
      home: _EntryGate(
        duration: splashDuration,
        startupMessage: dependencies.startupMessage,
      ),
    ),
  );
}

class _EntryGate extends StatefulWidget {
  const _EntryGate({required this.duration, this.startupMessage});
  final Duration duration;
  final String? startupMessage;
  @override
  State<_EntryGate> createState() => _EntryGateState();
}

class _EntryGateState extends State<_EntryGate> {
  Timer? _timer;
  StreamSubscription<dynamic>? _subscription;
  bool _splashDone = false, _sessionReady = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) setState(() => _splashDone = true);
    });
    final session = context.read<SessionProvider>();
    _subscription = session.service.changes.listen(
      (profile) {
        if (!mounted) return;
        session.update(profile);
        setState(() => _sessionReady = true);
      },
      onError: (Object error) {
        if (mounted) setState(() => _sessionReady = true);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (!_splashDone || !_sessionReady) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Brand(),
              SizedBox(height: 24),
              CircularProgressIndicator(semanticsLabel: 'Opening WaveGuard'),
            ],
          ),
        ),
      );
    }
    return session.entered
        ? const MainShell()
        : AuthScreen(startupMessage: widget.startupMessage);
  }
}
