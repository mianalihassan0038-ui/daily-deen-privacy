import 'package:dailydeen/app_state.dart';
import 'package:dailydeen/main.dart';
import 'package:dailydeen/screens/shell.dart';
import 'package:dailydeen/services/schedule.dart';
import 'package:dailydeen/services/prayer_times.dart';
import 'package:dailydeen/services/quran_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// Fixes the app clock at [after] + [minutes] today so the schedule state
  /// is deterministic (default: 30 minutes after Fajr).
  void setClock(AppState state, {PrayerName after = PrayerName.fajr, int minutes = 30}) {
    clock = DateTime.now;
    final t = state.prayerTimes(state.today)[after].toLocal().add(Duration(minutes: minutes));
    clock = () => t;
  }

  tearDown(() => clock = DateTime.now);

  Future<AppState> pumpApp(WidgetTester tester, {bool onboarded = true, bool splash = false, PrayerName after = PrayerName.fajr, int minutes = 30}) async {
    await tester.runAsync(() => QuranRepository.instance.ensureLoaded());
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    setClock(state, after: after, minutes: minutes);
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

  testWidgets('Home shows greeting, score, current activity and sections', (tester) async {
    final state = await pumpApp(tester);
    expect(find.textContaining('Assalamu Alaikum, Hassan'), findsOneWidget);
    expect(find.byKey(const Key('score_card')), findsOneWidget);
    expect(find.byKey(const Key('now_card')), findsOneWidget);
    expect(find.byKey(const Key('countdown')), findsOneWidget);
    // 30 min after Fajr: Fajr is the current activity.
    expect(state.scheduleFor(state.today).firstWhere((e) => e.isOpen).item.id, 'fajr');
    expect(find.descendant(of: find.byKey(const Key('now_card')), matching: find.byKey(const Key('now_cta'))), findsOneWidget);
    expect(find.byKey(const Key('home_prayer_fajr')), findsOneWidget);
    // Morning azkar is available now, evening azkar is not shown as open.
    expect(find.descendant(of: find.byKey(const Key('now_section')), matching: find.byKey(const Key('routine_morning_azkar'))),
        findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('now_section')), matching: find.byKey(const Key('routine_evening_azkar'))),
        findsNothing);
    expect(state.activityState(state.itemById('morning_azkar')!, state.today), ActivityState.active);
  });

  testWidgets('After Dhuhr: missed morning items are in the collapsible Earlier section', (tester) async {
    final state = await pumpApp(tester, after: PrayerName.dhuhr, minutes: 30);
    expect(state.activityState(state.itemById('morning_azkar')!, state.today), ActivityState.missed);
    await tester.ensureVisible(find.byKey(const Key('earlier_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('routine_morning_azkar')), findsNothing);
    await tester.tap(find.byKey(const Key('earlier_toggle')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('earlier_section')), matching: find.byKey(const Key('routine_morning_azkar'))),
        findsOneWidget);
  });

  testWidgets('Tapping a routine check marks it done and updates the score', (tester) async {
    final state = await pumpApp(tester);
    final before = state.scoreFor(state.today).done;
    await tester.ensureVisible(find.byKey(const Key('routine_check_morning_azkar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('routine_check_morning_azkar')));
    await tester.pumpAndSettle();
    expect(state.isDone(state.today, state.itemById('morning_azkar')!), isTrue);
    expect(state.scoreFor(state.today).done, before + 1);
    expect(state.completedTime(state.today, 'morning_azkar'), isNotNull);
  });

  testWidgets('Upcoming activities are locked and cannot be completed', (tester) async {
    final state = await pumpApp(tester);
    final evening = state.itemById('evening_azkar')!;
    expect(state.activityState(evening, state.today), ActivityState.upcoming);
    expect(state.toggleItem(state.today, evening), isFalse);
    expect(state.isDone(state.today, evening), isFalse);
    await tester.ensureVisible(find.byKey(const Key('upcoming_section')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('upcoming_section')), matching: find.byIcon(Icons.lock_outline)),
        findsWidgets);
  });

  testWidgets('Locked prayer cannot be recorded before its time', (tester) async {
    final state = await pumpApp(tester);
    await openTab(tester, 'Namaz');
    await tester.ensureVisible(find.byKey(const Key('prayer_asr')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prayer_asr')));
    await tester.pumpAndSettle();
    final chip = find.byKey(const Key('status_asr_jamaat'));
    if (chip.evaluate().isNotEmpty) {
      await tester.tap(chip, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(state.day(state.today).prayer('asr'), PrayerStatus.none);
    expect(state.setPrayer(state.today, 'asr', PrayerStatus.jamaat), isFalse);
  });

  testWidgets('Evening: morning azkar missed, evening azkar active', (tester) async {
    final state = await pumpApp(tester, after: PrayerName.asr, minutes: 20);
    expect(state.activityState(state.itemById('morning_azkar')!, state.today), ActivityState.missed);
    expect(state.activityState(state.itemById('evening_azkar')!, state.today), ActivityState.active);
    expect(find.descendant(of: find.byKey(const Key('now_section')), matching: find.byKey(const Key('routine_evening_azkar'))),
        findsOneWidget);
  });

  testWidgets('Urdu RTL and dark mode render the home screen', (tester) async {
    final state = await pumpApp(tester);
    state.settings.urdu = true;
    state.settings.themeMode = ThemeMode.dark;
    state.saveSettings();
    await tester.pumpAndSettle();
    expect(Directionality.of(tester.element(find.byKey(const Key('now_card')))), TextDirection.rtl);
    expect(Theme.of(tester.element(find.byKey(const Key('now_card')))).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Counted tasks complete automatically and show progress', (tester) async {
    final state = await pumpApp(tester);
    final today = state.today;
    for (var i = 0; i < 50; i++) {
      state.incrementDhikr(today, 'durood@m');
    }
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('routine_m_durood')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('routine_m_durood')), matching: find.text('50/100')), findsOneWidget);
    for (var i = 0; i < 50; i++) {
      state.incrementDhikr(today, 'durood@m');
    }
    state.addPages(today, state.settings.quranTarget);
    await tester.pumpAndSettle();
    expect(state.isDone(today, state.itemById('m_durood')!), isTrue);
    expect(state.isDone(today, state.itemById('quran_daily')!), isTrue);
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
    await tester.pump();
    // The Quran text future was created in a real-async zone; let it deliver.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
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
      expect(baqarah[254].indoPak, isNotEmpty);
      expect(baqarah[0].text(true), isNot(baqarah[0].text(false)));
      expect(repo.rukuOf(2, 8), (2, 3)); // 2nd ruku of Baqarah, 3rd ruku of Para 1
      expect(repo.rukuOf(1, 1), (1, 1));
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

  testWidgets('Daily plan screen: mark items and start chilla', (tester) async {
    final state = await pumpApp(tester, after: PrayerName.isha, minutes: 30);
    await tester.ensureVisible(find.byKey(const Key('open_daily_plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_daily_plan')));
    await tester.pumpAndSettle();
    expect(find.text('My Chilla'), findsWidgets);
    await tester.ensureVisible(find.byKey(const Key('report_check_waqiah')));
    await tester.tap(find.byKey(const Key('report_check_waqiah')));
    await tester.pumpAndSettle();
    expect(state.day(state.today).done.contains('waqiah'), isTrue);
    await tester.ensureVisible(find.byKey(const Key('report_check_e_kalima1')));
    await tester.tap(find.byKey(const Key('report_check_e_kalima1')));
    await tester.pumpAndSettle();
    expect(state.day(state.today).done.contains('e_kalima1'), isTrue);
    state.startChilla(state.today);
    await tester.pumpAndSettle();
    expect(find.text('Chilla: 01'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily plan fits a small screen in Urdu', (tester) async {
    final state = await pumpApp(tester);
    state.settings.urdu = true;
    state.saveSettings();
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open_daily_plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_daily_plan')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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
    // Any overflow is reported by the framework with the offending widget.
    for (final label in ['Namaz', 'Quran', 'Azkar', 'Progress', 'Home']) {
      await openTab(tester, label);
    }
  });
}
