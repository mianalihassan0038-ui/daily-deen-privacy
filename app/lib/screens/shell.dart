import 'package:flutter/material.dart';

import '../app_state.dart';
import 'home_screen.dart';
import 'namaz_screen.dart';
import 'progress_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';
import 'tasbeeh_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final titles = [s.t('app_name'), s.t('nav_namaz'), s.t('quran_tracker'), s.t('tasbeeh'), s.t('progress')];
    final pages = const [HomeScreen(), NamazScreen(), QuranScreen(), TasbeehScreen(), ProgressScreen()];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index], style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            key: const Key('settings_button'),
            tooltip: s.t('settings'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: s.t('nav_home')),
          NavigationDestination(icon: const Icon(Icons.mosque_outlined), selectedIcon: const Icon(Icons.mosque), label: s.t('nav_namaz')),
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book), label: s.t('nav_quran')),
          NavigationDestination(icon: const Icon(Icons.touch_app_outlined), selectedIcon: const Icon(Icons.touch_app), label: s.t('nav_tasbeeh')),
          NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights), label: s.t('nav_progress')),
        ],
      ),
    );
  }
}
