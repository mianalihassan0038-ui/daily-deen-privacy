// Generates Play Store screenshots (run with --update-goldens in CI).
import 'dart:io';

import 'package:dailydeen/app_state.dart';
import 'package:dailydeen/data/routine.dart';
import 'package:dailydeen/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final roboto = FontLoader('Roboto');
  final icons = FontLoader('MaterialIcons');
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    final data = Future.value(ByteData.sublistView(f.readAsBytesSync()));
    if (name.startsWith('Roboto-')) roboto.addFont(data);
    if (name.startsWith('MaterialIcons-Regular')) icons.addFont(data);
  }
  await roboto.load();
  await icons.load();
}

void main() {
  setUpAll(_loadFonts);

  Future<AppState> setup(WidgetTester tester, {bool urdu = false}) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.settings.urdu = urdu;
    state.settings.themeMode = ThemeMode.light;
    final today = state.today;
    // Sample data so the screenshots look realistic.
    for (var i = 1; i <= 6; i++) {
      final d = today.subtract(Duration(days: i));
      for (final k in prayerKeys) {
        state.setPrayer(d, k, i.isEven ? PrayerStatus.jamaat : PrayerStatus.alone);
      }
      for (final item in defaultRoutine.take(8 + i * 2)) {
        if (item.prayerKey == null) state.setDone(d, item.id, true);
      }
    }
    state.setPrayer(today, 'fajr', PrayerStatus.jamaat);
    state.setPrayer(today, 'dhuhr', PrayerStatus.alone);
    for (final id in ['wake', 'wudu', 'tahajjud', 'dua_istighfar', 'tilawat_fajr', 'morning_azkar', 'kursi_morning']) {
      state.setDone(today, id, true);
    }
    state.incrementDhikr(today, 'subhanallah', by: 67);
    state.incrementDhikr(today, 'durood', by: 100);
    state.addPages(today, 3);
    state.addPages(today.subtract(const Duration(days: 1)), 240);
    for (var j = 1; j <= 12; j++) {
      state.toggleJuz(j);
    }

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(DailyDeenApp(state: state));
    await tester.pumpAndSettle();
    return state;
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('screenshots', (tester) async {
    await setup(tester);
    await shot(tester, '1_home');
    for (final (label, name) in [('Namaz', '2_namaz'), ('Quran', '3_quran'), ('Tasbeeh', '4_tasbeeh'), ('Progress', '5_progress')]) {
      await tester.tap(find.text(label).last);
      await shot(tester, name);
    }
  });

  testWidgets('urdu screenshot', (tester) async {
    await setup(tester, urdu: true);
    await shot(tester, '6_home_urdu');
  });
}
