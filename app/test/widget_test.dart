import 'package:dailydeen/app_state.dart';
import 'package:dailydeen/main.dart';
import 'package:dailydeen/screens/shell.dart';
import 'package:dailydeen/services/quran_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AppState> pumpApp(WidgetTester tester, {bool onboarded = true, bool splash = false}) async {
    await tester.runAsync(() => QuranRepository.instance.ensureLoaded());
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    state.settings.onboarded = onboarded;
    state.settings.userName = 'Hassan';
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    shellTab.value = Tabs.home;
    await tester.pumpWidget(DailyDeenApp(state: state, showSplash: splash));
    await tester.pump();
    return state;
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  testWidgets('Splash then onboarding on first launch', (tester) async {
    await pumpApp(tester, onboarded: false, splash: true);
    expect(find.text('Daily Deen'), findsWidgets);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Your Islamic Daily Companion'), findsOneWidget);
  });

  testWidgets('Onboarding: skip opens the app', (tester) async {
    final state = await pumpApp(tester, onboarded: false);
    await tester.tap(find.byKey(const Key('onboarding_skip')));
    await tester.pumpAndSettle();
    expect(state.settings.onboarded, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Onboarding: name is saved', (tester) async {
    final state = await pumpApp(tester, onboarded: false);
    state.settings.userName = '';
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('onboarding_next')));
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byKey(const Key('onboarding_name')), 'Ali');
    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();
    expect(state.settings.userName, 'Ali');
    expect(state.settings.onboarded, isTrue);
    expect(find.textContaining('Ali'), findsWidgets);
  });

  testWidgets('Home shows greeting, progress, next prayer and checklist', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Assalamu Alaikum, Hassan'), findsOneWidget);
    expect(find.text('Next Prayer'), findsOneWidget);
    expect(find.byKey(const Key('countdown')), findsOneWidget);
    expect(find.byKey(const Key('home_prayer_fajr')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('routine_wudu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routine_wudu')), findsOneWidget);
  });

  testWidgets('Tapping a routine check marks it done and updates progress', (tester) async {
    final state = await pumpApp(tester);
    await tester.ensureVisible(find.byKey(const Key('routine_check_wudu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('routine_check_wudu')));
    await tester.pumpAndSettle();
    expect(state.day(state.today).done.contains('wudu'), isTrue);
    expect(state.completion(state.today).$1, 1);
  });

  testWidgets('Quick card opens morning azkar', (tester) async {
    await pumpApp(tester);
    await tester.ensureVisible(find.byKey(const Key('quick_morning')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick_morning')));
    await tester.pumpAndSettle();
    expect(find.text('Morning Azkar'), findsWidgets);
    expect(find.byKey(const Key('zikr_morning_0')), findsOneWidget);
  });

  testWidgets('All tabs open without errors', (tester) async {
    await pumpApp(tester);
    for (final label in ['Namaz', 'Quran', 'Azkar', 'Progress', 'Home']) {
      await openTab(tester, label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Namaz: recording a status', (tester) async {
    final state = await pumpApp(tester);
    await openTab(tester, 'Namaz');
    await tester.ensureVisible(find.byKey(const Key('prayer_fajr')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prayer_fajr')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('status_fajr_jamaat')));
    await tester.pumpAndSettle();
    expect(state.day(state.today).prayer('fajr'), PrayerStatus.jamaat);
    await tester.tap(find.byKey(const Key('header_tab_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('header_tab_2')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tasbeeh counter increments, decrements and changes target', (tester) async {
    final state = await pumpApp(tester);
    await openTab(tester, 'Azkar');
    await tester.tap(find.byKey(const Key('header_tab_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tasbeeh_tap')));
    await tester.tap(find.byKey(const Key('tasbeeh_plus')));
    await tester.pump();
    expect(state.day(state.today).dhikr['subhanallah'], 2);
    await tester.tap(find.byKey(const Key('tasbeeh_minus')));
    await tester.pump();
    expect(state.day(state.today).dhikr['subhanallah'], 1);
    await tester.tap(find.byKey(const Key('target_33')));
    await tester.pump();
    expect(state.dhikrTarget('subhanallah', 100), 33);
  });

  testWidgets('Quran: page counter and surah list', (tester) async {
    final state = await pumpApp(tester);
    await openTab(tester, 'Quran');
    await tester.runAsync(() => QuranRepository.instance.ensureLoaded());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quran_plus')));
    await tester.pump();
    expect(state.day(state.today).quranPages, 1);
    expect(find.byKey(const Key('surah_1')), findsOneWidget);
  });

  testWidgets('Quran reader opens Al-Fatihah with Arabic and translations', (tester) async {
    final state = await pumpApp(tester);
    await openTab(tester, 'Quran');
    await tester.runAsync(() async {
      await QuranRepository.instance.ensureLoaded();
      await QuranRepository.instance.ayahs(1);
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('surah_1')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'reader still loading');
    expect(find.byKey(const Key('ayah_1_1')), findsOneWidget);
    expect(find.textContaining('praise is [due] to Allah'), findsOneWidget);
    expect(state.lastRead, const QuranRef(1, 1));
  });

  testWidgets('Quran data: 114 surahs, 30 juz, 604 pages', (tester) async {
    await tester.runAsync(() async {
      final repo = QuranRepository.instance;
      await repo.ensureLoaded();
      expect(repo.surahs.length, 114);
      expect(repo.juzStarts.length, 30);
      expect(repo.pageStarts.length, 604);
      expect(repo.juzOf(2, 142), 2);
      expect(repo.pageOf(2, 255), 42);
      expect(repo.pageOf(114, 6), 604);
      final baqarah = await repo.ayahs(2);
      expect(baqarah.length, 286);
      var total = 0;
      for (final s in repo.surahs) {
        total += s.ayahs;
      }
      expect(total, 6236);
    });
  });

  testWidgets('Switching to Urdu works and is RTL', (tester) async {
    final state = await pumpApp(tester);
    state.settings.urdu = true;
    state.saveSettings();
    await tester.pumpAndSettle();
    expect(find.textContaining('السلام علیکم'), findsOneWidget);
    final dir = Directionality.of(tester.element(find.textContaining('السلام علیکم')));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('Settings screen and sub-screens open', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Language'), findsOneWidget);
    for (final key in ['settings_notifications', 'settings_prayer', 'settings_backup']) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Routine planner: add an activity', (tester) async {
    final state = await pumpApp(tester);
    await tester.ensureVisible(find.byKey(const Key('more_features')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('more_features')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Routine Planner'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('routine_add')));
    await tester.pumpAndSettle();
    // Validation: empty name is rejected
    await tester.ensureVisible(find.byKey(const Key('activity_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity_save')));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('activity_name')), 'Morning walk');
    await tester.ensureVisible(find.byKey(const Key('activity_save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity_save')));
    await tester.pumpAndSettle();
    expect(state.allItems.any((i) => i.en == 'Morning walk'), isTrue);
    await tester.tap(find.byKey(const Key('routine_edit_toggle')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('More features screens open', (tester) async {
    await pumpApp(tester);
    await tester.ensureVisible(find.byKey(const Key('more_features')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('more_features')));
    await tester.pumpAndSettle();
    for (final label in ['Islamic Calendar', 'Sadaqah Tracker', 'Habit Goals', 'Daily Muhasaba', 'Dua Library']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Muhasaba saves notes', (tester) async {
    final state = await pumpApp(tester);
    await tester.ensureVisible(find.byKey(const Key('more_features')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('more_features')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Muhasaba'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('muhasaba_good_deeds')), 'Helped a neighbour');
    await tester.pump();
    expect(state.day(state.today).muhasaba['good_deeds'], 'Helped a neighbour');
    await tester.tap(find.byKey(const Key('rating_4')));
    await tester.pump();
    expect(state.day(state.today).muhasaba['rating'], '4');
  });

  testWidgets('Dark mode renders home', (tester) async {
    final state = await pumpApp(tester);
    state.settings.themeMode = ThemeMode.dark;
    state.saveSettings();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Small screen has no overflow on main tabs', (tester) async {
    await pumpApp(tester);
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpAndSettle();
    for (final label in ['Namaz', 'Quran', 'Azkar', 'Progress', 'Home']) {
      await openTab(tester, label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });
}
