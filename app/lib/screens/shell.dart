import 'package:flutter/material.dart';

import '../app_state.dart';
import 'azkar_screen.dart';
import 'home_screen.dart';
import 'namaz_screen.dart';
import 'progress_screen.dart';
import 'quran_screen.dart';

/// Tab indexes of the bottom navigation.
class Tabs {
  static const home = 0;
  static const namaz = 1;
  static const quran = 2;
  static const azkar = 3;
  static const progress = 4;
}

/// Current bottom-navigation tab. Any screen (including pushed routes) can
/// switch tabs with [ShellScope.go].
final ValueNotifier<int> shellTab = ValueNotifier<int>(Tabs.home);

class ShellScope {
  static void go(BuildContext context, int tab) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    shellTab.value = tab;
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int get _index => shellTab.value;

  void _onTab() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    shellTab.value = Tabs.home;
    shellTab.addListener(_onTab);
  }

  @override
  void dispose() {
    shellTab.removeListener(_onTab);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    const pages = [HomeScreen(), NamazScreen(), QuranScreen(), AzkarScreen(), ProgressScreen()];

    return PopScope(
        canPop: _index == Tabs.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) shellTab.value = Tabs.home;
        },
        child: Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            height: 68,
            onDestinationSelected: (i) => shellTab.value = i,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: s.t('nav_home')),
              NavigationDestination(icon: const Icon(Icons.mosque_outlined), selectedIcon: const Icon(Icons.mosque), label: s.t('nav_namaz')),
              NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: s.t('nav_quran')),
              NavigationDestination(icon: const Icon(Icons.auto_awesome_outlined), selectedIcon: const Icon(Icons.auto_awesome), label: s.t('nav_azkar')),
              NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights), label: s.t('nav_progress')),
            ],
          ),
        ),
    );
  }
}
