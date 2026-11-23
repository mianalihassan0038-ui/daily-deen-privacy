// Generates screenshots of the main screens (run with --update-goldens in CI).
import 'dart:io';

import 'package:dailydeen/app_state.dart';
import 'package:dailydeen/data/azkar.dart';
import 'package:dailydeen/data/routine.dart';
import 'package:dailydeen/main.dart';
import 'package:dailydeen/screens/azkar_schedule_screen.dart';
import 'package:dailydeen/screens/azkar_screen.dart';
import 'package:dailydeen/screens/chilla_screen.dart';
import 'package:dailydeen/services/schedule.dart';
import 'package:dailydeen/screens/more_screen.dart';
import 'package:dailydeen/screens/quran_reader_screen.dart';
import 'package:dailydeen/screens/report_screen.dart';
import 'package:dailydeen/screens/routine_screen.dart';
import 'package:dailydeen/screens/settings_screen.dart';
import 'package:dailydeen/screens/shell.dart';
import 'package:dailydeen/services/prayer_times.dart';
import 'package:dailydeen/services/quran_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final dir = Directory('$root/bin/cache/artifacts/material_fonts');
    if (dir.existsSync()) {
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
  }
  final naskh = FontLoader('NotoNaskhArabic');
  for (final f in ['assets/fonts/NotoNaskhArabic-Regular.ttf', 'assets/fonts/NotoNaskhArabic-Bold.ttf']) {
    naskh.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await naskh.load();
  final urdu = FontLoader('NotoNastaliqUrdu');
  for (final f in ['assets/fonts/NotoNastaliqUrdu-Regular.ttf', 'assets/fonts/NotoNastaliqUrdu-Bold.ttf']) {
    urdu.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await urdu.load();
  final indoPak = FontLoader('KFGQPCNastaleeq');
  indoPak.addFont(Future.value(ByteData.sublistView(File('assets/fonts/KFGQPC-Nastaleeq.otf').readAsBytesSync())));
  await indoPak.load();
  final fraunces = FontLoader('Fraunces');
  for (final f in ['assets/fonts/Fraunces-SemiBold.ttf', 'assets/fonts/Fraunces-Bold.ttf']) {
    fraunces.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await fraunces.load();
  // Serif headings fall back to Naskh's Latin glyphs in tests.
  final serif = FontLoader('serif');
  serif.addFont(Future.value(ByteData.sublistView(File('assets/fonts/NotoNaskhArabic-Bold.ttf').readAsBytesSync())));
  await serif.load();
}

void main() {
  setUpAll(_loadFonts);

  Future<AppState> setup(WidgetTester tester, {bool urdu = false, bool dark = false}) async {
    await tester.runAsync(() async {
      await QuranRepository.instance.ensureLoaded();
      await QuranRepository.instance.ayahs(1);
    });
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.settings
      ..urdu = urdu
      ..themeMode = dark ? ThemeMode.dark : ThemeMode.light
      ..onboarded = true
      ..userName = 'Hassan'
      ..cityIndex = 1;
    // Deterministic time: 20 minutes after Asr.
    clock = DateTime.now;
    final at = state.prayerTimes(state.today)[PrayerName.asr].toLocal().add(const Duration(minutes: 20));
    clock = () => at;
    addTearDown(() => clock = DateTime.now);
    final today = state.today;
    for (var i = 1; i <= 20; i++) {
      final d = today.subtract(Duration(days: i));
      for (final k in prayerKeys) {
        state.setPrayer(d, k, i % 7 == 0 ? PrayerStatus.qaza : (i.isEven ? PrayerStatus.jamaat : PrayerStatus.alone));
      }
      for (final item in defaultRoutine.take(6 + (i % 5) * 4)) {
        if (item.prayerKey == null) state.setDone(d, item.id, true);
      }
      state.day(d).quranPages = 2 + i % 4;
    }
    state.setPrayer(today, 'fajr', PrayerStatus.jamaat);
    state.setPrayer(today, 'dhuhr', PrayerStatus.alone);
    for (final id in ['wake', 'wudu', 'tahajjud', 'dua_istighfar', 'tilawat_fajr', 'morning_azkar', 'kursi_morning']) {
      state.setDone(today, id, true);
    }
    state.addPages(today, 3);
    for (var i = 0; i < 33; i++) {
      state.incrementDhikr(today, 'subhanallah');
    }
    state.setLastRead(2, 255);
    state.saveSettings();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    return state;
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  Future<void> tab(WidgetTester tester, int index) async {
    shellTab.value = index;
    await tester.pumpAndSettle();
  }

  Future<void> push(WidgetTester tester, Widget w) async {
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => w));
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    final suffix = dark ? '_dark' : '';
    testWidgets('main tabs$suffix', (tester) async {
      final state = await setup(tester, dark: dark);
      await tester.pumpWidget(DailyDeenApp(state: state, showSplash: false));
      await tab(tester, Tabs.home);
      await shot(tester, '01_home$suffix');
      await tab(tester, Tabs.namaz);
      await shot(tester, '02_namaz$suffix');
      await tab(tester, Tabs.quran);
      await shot(tester, '03_quran$suffix');
      azkarSubTab.value = 0;
      await tab(tester, Tabs.azkar);
      await shot(tester, '04_azkar$suffix');
      azkarSubTab.value = 1;
      await tester.pumpAndSettle();
      await shot(tester, '05_tasbeeh$suffix');
      await tab(tester, Tabs.progress);
      await shot(tester, '06_progress$suffix');
      await tab(tester, Tabs.home);
    });
  }

  testWidgets('secondary screens', (tester) async {
    final state = await setup(tester);
    await tester.pumpWidget(DailyDeenApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await push(tester, const RoutineScreen());
    await shot(tester, '07_routine');
    await push(tester, const SettingsScreen());
    await shot(tester, '08_settings');
    await push(tester, const MoreFeaturesScreen());
    await shot(tester, '09_more');
    await push(tester, const AzkarDetailScreen(type: AzkarType.morning));
    await shot(tester, '10_morning_azkar');
  });

  testWidgets('3.1 screens', (tester) async {
    final state = await setup(tester);
    state.startChilla(state.today.subtract(const Duration(days: 17)));
    state.setAzkarSchedule('morning_azkar', const AzkarSchedule.afterPrayer('fajr', offset: 15));
    await tester.pumpWidget(DailyDeenApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await push(tester, const AzkarScheduleEditScreen(id: 'morning_azkar'));
    await shot(tester, '15_azkar_schedule');
    await push(tester, const ChillaScreen());
    await shot(tester, '16_chilla');
    await push(tester, const SettingsScreen());
    final notif = find.text('Notifications');
    if (notif.evaluate().isNotEmpty) await tester.tap(notif.first);
    await shot(tester, '17_notification_settings');
  });

  testWidgets('splash and onboarding', (tester) async {
    final state = await setup(tester);
    state.settings.onboarded = false;
    await tester.pumpWidget(DailyDeenApp(state: state));
    await tester.pump(const Duration(milliseconds: 1300));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/00_splash.png'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '00_onboarding');
  });

  testWidgets('daily plan urdu', (tester) async {
    final state = await setup(tester, urdu: true);
    state.startChilla(state.today);
    for (final k in prayerKeys) {
      state.setPrayer(state.today, k, PrayerStatus.jamaat);
    }
    state.setDone(state.today, 'yaseen', true);
    state.setDone(state.today, 'm_istighfar', true);
    await tester.pumpWidget(DailyDeenApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await push(tester, const ReportScreen());
    await shot(tester, '12_daily_plan_urdu');
  });

  testWidgets('quran reader', (tester) async {
    for (final urdu in [false, true]) {
      final state = await setup(tester, urdu: urdu);
      await tester.pumpWidget(DailyDeenApp(state: state, showSplash: false));
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator).first).push(
            MaterialPageRoute(builder: (_) => const QuranReaderScreen(surah: 1)),
          );
      await tester.pump();
      // Quran text future comes from a real-async zone; let it deliver.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await shot(tester, urdu ? '14_reader_urdu' : '13_reader');
    }
  });

  testWidgets('mushaf baqarah', (tester) async {
    final state = await setup(tester, urdu: true);
    await tester.pumpWidget(DailyDeenApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await tester.runAsync(() => QuranRepository.instance.ayahs(2));
    tester.state<NavigatorState>(find.byType(Navigator).first).push(
          MaterialPageRoute(builder: (_) => const QuranReaderScreen(surah: 2)),
        );
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await shot(tester, '18_mushaf_baqarah');
    state.settings.quranMushaf = false;
    state.saveSettings();
    await shot(tester, '19_translation_view');
  });

  testWidgets('urdu home', (tester) async {
    final state = await setup(tester, urdu: true);
    await tester.pumpWidget(DailyDeenApp(state: state, showSplash: false));
    await shot(tester, '11_home_urdu');
  });
}
