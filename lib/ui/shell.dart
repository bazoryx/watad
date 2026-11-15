import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'widgets/common.dart';

/// One layout that adapts to the window: bottom bar on phones and the outer
/// foldable screen; side rail with two-pane screens on the inner screen.
/// Switching happens live when the device is folded or unfolded, and the
/// selected tab is kept.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) AppScope.read(context).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pages = const [HomeScreen(), CalendarScreen(), SettingsScreen()];
    final body = IndexedStack(index: _index, children: pages);
    void select(int i) => setState(() => _index = i);

    if (!isWide(context)) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: select,
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: s.home),
            NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: s.calendar),
            NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: s.settings),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: select,
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 16),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: WColors.deepGreen, borderRadius: BorderRadius.circular(12)),
              child: const Text('و',
                  style: TextStyle(
                      color: WColors.goldLight, fontSize: 22, fontWeight: FontWeight.w700)),
            ),
          ),
          destinations: [
            NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: Text(s.home)),
            NavigationRailDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: Text(s.calendar)),
            NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(s.settings)),
          ],
        ),
        const VerticalDivider(width: 1, color: WColors.line),
        Expanded(child: body),
      ]),
    );
  }
}
