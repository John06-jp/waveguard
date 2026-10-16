import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/public_data.dart';
import '../providers/public_data_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'advisory/advisory_screen.dart';
import 'forecast/forecast_screen.dart';
import 'beaches/beaches_screen.dart';
import 'more/more_screen.dart';
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
  final _keys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  final _canPop = List.filled(5, false);
  List<Widget> get _screens => [
    AdvisoryScreen(onAccount: _account, onSelectTab: _selectTab),
    const ForecastScreen(),
    const MapScreen(),
    const BeachesScreen(),
    const MoreScreen(),
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

  void _selectTab(int index) => setState(() {
    _index = index;
    _visited.add(index);
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PublicDataProvider>();
    return PopScope(
      canPop: _index == 0 && !_canPop[_index],
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navigator = _keys[_index].currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        } else if (_index != 0) {
          _selectTab(0);
        }
      },
      child: Scaffold(
        appBar:
            (_canPop[_index] ||
                _index == 0 ||
                _index == 1 ||
                _index == 2 ||
                _index == 4)
            ? null
            : AppBar(
                title: _index == 0
                    ? const Brand()
                    : Text(
                        const [
                          'Home',
                          'Marine Forecast',
                          'Marine Weather Map',
                          'Beaches in Lianga',
                          'More',
                        ][_index],
                      ),
                actions: [
                  IconButton(
                    tooltip: 'Refresh public information',
                    onPressed: data.loading ? null : data.load,
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: 'SOS',
                    onPressed: () => _keys[_index].currentState?.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SosScreen(standalone: true),
                      ),
                    ),
                    icon: const Icon(Icons.sos, color: SeaColors.danger),
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
              5,
              (i) => _visited.contains(i)
                  ? TickerMode(
                      enabled: _index == i,
                      child: Navigator(
                        key: _keys[i],
                        observers: [
                          _TabObserver(() {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(
                                  () => _canPop[i] =
                                      _keys[i].currentState?.canPop() ?? false,
                                );
                              }
                            });
                          }),
                        ],
                        onGenerateRoute: (_) => MaterialPageRoute<void>(
                          builder: (_) => _screens[i],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF003653),
          indicatorColor: const Color(0xFF0067BC),
          height: 68,
          selectedIndex: _index,
          onDestinationSelected: _selectTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined, color: Colors.white),
              label: 'Forecast',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.white),
              label: 'Map',
            ),
            NavigationDestination(
              icon: Icon(Icons.beach_access_outlined, color: Colors.white),
              label: 'Beaches',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz, color: Colors.white),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

class _TabObserver extends NavigatorObserver {
  _TabObserver(this.changed);
  final VoidCallback changed;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      changed();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => changed();
}
