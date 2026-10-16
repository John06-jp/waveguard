import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/public_data.dart';
import '../providers/public_data_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'advisory/advisory_screen.dart';
import 'history/history_screen.dart';
import 'map/map_screen.dart';
import 'sos/sos_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final Set<int> _visited = {0};
  final _screens = const [
    AdvisoryScreen(),
    MapScreen(),
    HistoryScreen(),
    SosScreen(),
  ];
  Future<void> _account() async {
    final session = context.read<SessionProvider>();
    final profile = session.profile;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                profile?.email ?? 'Browsing as guest',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (profile != null) Text('Account role: ${profile.role.name}'),
              if (profile != null && profile.role != UserRole.user)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Notice(
                    'This app provides public coastal information. Management tools are outside this Android frontend.',
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await session.leave();
                  } on AuthFailure catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
                child: Text(profile == null ? 'Go to login' : 'Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Brand(),
          actions: [
            IconButton(
              tooltip: 'Refresh public information',
              onPressed: data.loading ? null : data.load,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Account',
              onPressed: _account,
              icon: const Icon(Icons.account_circle_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: IndexedStack(
            index: _index,
            children: List.generate(
              4,
              (i) => _visited.contains(i)
                  ? TickerMode(enabled: _index == i, child: _screens[i])
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() {
            _index = index;
            _visited.add(index);
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.waves_outlined),
              selectedIcon: Icon(Icons.waves),
              label: 'Advisory',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Map',
            ),
            NavigationDestination(icon: Icon(Icons.history), label: 'History'),
            NavigationDestination(
              icon: Icon(Icons.sos, color: SeaColors.danger),
              label: 'SOS',
            ),
          ],
        ),
      ),
    );
  }
}
