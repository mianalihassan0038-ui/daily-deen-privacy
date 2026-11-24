import 'dart:convert';
import 'dart:io';

import 'package:dailydeen/app_state.dart';
import 'package:dailydeen/data/azkar.dart';
import 'package:dailydeen/data/routine.dart';
import 'package:dailydeen/screens/qibla_screen.dart';
import 'package:dailydeen/screens/quran_reader_screen.dart';
import 'package:dailydeen/services/hijri.dart';
import 'package:dailydeen/services/prayer_times.dart';
import 'package:dailydeen/services/notifications.dart';
import 'package:dailydeen/services/report.dart';
import 'package:dailydeen/services/schedule.dart';
import 'package:dailydeen/strings.dart';
import 'package:dailydeen/version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A time late in [d] when every activity of the day has started.
DateTime lateIn(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59);

void main() {
  group('Prayer times (Karachi, 16 Nov 2026, Hanafi)', () {
    final calc = PrayerCalculator(lat: 24.8607, lng: 67.0011, method: CalcMethod.karachi, hanafiAsr: true);
    final t = calc.forDate(DateTime(2026, 11, 16));
    // Expected local (PKT, UTC+5): Fajr 05:29, Sunrise 06:48, Dhuhr 12:17, Asr 16:08, Maghrib 17:44, Isha 19:03
    String pkt(DateTime d) {
      final x = d.toUtc().add(const Duration(hours: 5));
      return '${x.hour.toString().padLeft(2, '0')}:${x.minute.toString().padLeft(2, '0')}';
    }

    int minutes(String hhmm) => int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3));

    void near(PrayerName p, String expected) {
      final diff = (minutes(pkt(t[p])) - minutes(expected)).abs();
      expect(diff <= 3, isTrue, reason: '$p was ${pkt(t[p])}, expected ~$expected');
    }

    test('fajr', () => near(PrayerName.fajr, '05:29'));
    test('sunrise', () => near(PrayerName.sunrise, '06:48'));
    test('dhuhr', () => near(PrayerName.dhuhr, '12:17'));
    test('asr', () => near(PrayerName.asr, '16:08'));
    test('maghrib', () => near(PrayerName.maghrib, '17:44'));
    test('isha', () => near(PrayerName.isha, '19:03'));

    test('order is correct', () {
      final order = PrayerName.values.map((p) => t[p]).toList();
      for (var i = 1; i < order.length; i++) {
        expect(order[i].isAfter(order[i - 1]), isTrue);
      }
    });
  });

  test('high latitude (Calgary, June) still gives ordered times', () {
    final calc = PrayerCalculator(lat: 51.0447, lng: -114.0719, method: CalcMethod.isna, hanafiAsr: false);
    final t = calc.forDate(DateTime(2026, 6, 21));
    final order = PrayerName.values.map((p) => t[p]).toList();
    for (var i = 1; i < order.length; i++) {
      expect(order[i].isAfter(order[i - 1]), isTrue, reason: '${PrayerName.values[i]}');
    }
  });

  group('Hijri', () {
    test('conversion', () {
      final h = HijriDate.fromGregorian(DateTime(2026, 2, 18));
      expect(h.month, 9); // Ramadan 1447
      expect(h.year, 1447);
      final h2 = HijriDate.fromGregorian(DateTime(2026, 11, 16));
      expect(h2.year, 1448);
      expect(h2.month, 6);
    });

    test('round trip Gregorian -> Hijri -> Gregorian', () {
      var d = DateTime(2024, 1, 1);
      for (var i = 0; i < 800; i++) {
        final h = HijriDate.fromGregorian(d);
        expect(h.toGregorian(), d, reason: '$d -> ${h.year}-${h.month}-${h.day}');
        d = DateTime(d.year, d.month, d.day + 1);
      }
    });

    test('month length is 29 or 30', () {
      for (var m = 1; m <= 12; m++) {
        final len = HijriDate(1448, m, 1).monthLength;
        expect(len == 29 || len == 30, isTrue);
      }
    });

    test('adjustment shifts the date', () {
      final base = HijriDate.fromGregorian(DateTime(2026, 11, 16));
      final plus = HijriDate.fromGregorian(DateTime(2026, 11, 16), adjustDays: 1);
      expect(plus.toGregorian(adjustDays: 1), DateTime(2026, 11, 16));
      expect(plus == base, isFalse);
    });
  });

  group('Qibla', () {
    test('bearing from Karachi and London', () {
      expect(qiblaBearing(24.8607, 67.0011), closeTo(267.7, 0.5));
      expect(qiblaBearing(51.5074, -0.1278), closeTo(119.0, 0.5));
    });

    test('heading from flat phone pointing north is ~0', () {
      // Phone flat (gravity on +z), magnetic field pointing north (+y) and down.
      final h = headingFrom([0, 0, 9.8], [0, 20, -40]);
      expect(h, isNotNull);
      expect(h! < 1 || h > 359, isTrue, reason: 'heading $h');
    });
  });

  group('Azkar data', () {
    test('every zikr has text, transliteration, translations and a reference', () {
      final ids = <String>{};
      for (final e in azkar.entries) {
        expect(e.value, isNotEmpty, reason: '${e.key}');
        for (final z in e.value) {
          expect(z.arabic.trim(), isNotEmpty, reason: z.id);
          expect(z.translit.trim(), isNotEmpty, reason: z.id);
          expect(z.en.trim(), isNotEmpty, reason: z.id);
          expect(z.ur.trim(), isNotEmpty, reason: z.id);
          expect(z.reference.trim(), isNotEmpty, reason: z.id);
          expect(z.count, greaterThan(0), reason: z.id);
          expect(z.arabic.contains('{{'), isFalse, reason: z.id);
          ids.add(z.id);
        }
      }
      expect(ids.length, greaterThan(30));
      expect(dailyDuaPool, isNotEmpty);
    });

    test('all 8 categories exist', () {
      expect(azkar.keys.toSet(), AzkarType.values.toSet());
      expect(azkarTypeNames.keys.toSet(), AzkarType.values.toSet());
    });
  });

  group('AppState', () {
    late AppState state;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      state = await AppState.load();
    });

    test('toggle routine item and completion', () {
      final today = state.today;
      final item = state.itemById('wudu')!;
      final (d0, total) = state.completion(today, now: lateIn(today));
      expect(d0, 0);
      expect(total, greaterThan(20));
      state.toggleItem(today, item, now: lateIn(today));
      expect(state.isDone(today, item), isTrue);
      expect(state.completion(today, now: lateIn(today)).$1, 1);
      state.toggleItem(today, item, now: lateIn(today));
      expect(state.isDone(today, item), isFalse);
    });

    test('skipped items are not counted', () {
      final today = state.today;
      final item = state.itemById('wudu')!;
      final total = state.completion(today, now: lateIn(today)).$2;
      state.toggleSkip(today, item);
      expect(state.isSkipped(today, item), isTrue);
      expect(state.completion(today, now: lateIn(today)).$2, total - 1);
      state.toggleItem(today, item, now: lateIn(today)); // completing un-skips
      expect(state.isSkipped(today, item), isFalse);
      expect(state.isDone(today, item), isTrue);
    });

    test('prayer routine item maps to prayer status', () {
      final today = state.today;
      final fajr = state.itemById('fajr')!;
      state.toggleItem(today, fajr, now: lateIn(today));
      expect(state.day(today).prayer('fajr'), PrayerStatus.alone);
      state.setPrayer(today, 'fajr', PrayerStatus.jamaat, now: lateIn(today));
      expect(state.isDone(today, fajr), isTrue);
      state.setPrayer(today, 'fajr', PrayerStatus.missed, now: lateIn(today));
      expect(state.isDone(today, fajr), isFalse);
    });

    test('prayers are never marked automatically', () {
      final rec = state.day(state.today);
      for (final k in prayerKeys) {
        expect(rec.prayer(k), PrayerStatus.none);
      }
    });

    test('witr toggles the witr routine item', () {
      final today = state.today;
      state.toggleSunnah(today, 'witr', now: lateIn(today));
      expect(state.witrDone(today), isTrue);
      expect(state.isDone(today, state.itemById('witr')!), isTrue);
      state.toggleSunnah(today, 'witr', now: lateIn(today));
      expect(state.witrDone(today), isFalse);
    });

    test('dhikr reaching target ticks routine item', () {
      final today = state.today;
      for (var i = 0; i < 99; i++) {
        state.incrementDhikr(today, 'durood@m');
      }
      expect(state.isDone(today, state.itemById('m_durood')!), isFalse);
      state.incrementDhikr(today, 'durood@m');
      expect(state.isDone(today, state.itemById('m_durood')!), isTrue);
      expect(state.isDone(today, state.itemById('e_durood')!), isFalse, reason: 'evening is counted separately');
      state.incrementDhikr(today, 'durood@m', by: -1);
      expect(state.isDone(today, state.itemById('m_durood')!), isFalse);
    });

    test('quran pages, target and khatam rollover', () {
      final today = state.today;
      state.addPages(today, 4);
      expect(state.isDone(today, state.itemById('quran_daily')!), isTrue);
      state.addPages(today, 600);
      expect(state.khatamCount, 1);
      expect(state.khatamPages, 0);
    });

    test('page read toggle counts towards today', () {
      state.togglePageRead(10);
      expect(state.readPages.contains(10), isTrue);
      expect(state.day(state.today).quranPages, 1);
      state.togglePageRead(10);
      expect(state.readPages.contains(10), isFalse);
      expect(state.day(state.today).quranPages, 0);
    });

    test('bookmarks, favourites and last read persist', () async {
      state.toggleBookmark(2, 255);
      state.toggleFavouriteAyah(1, 1);
      state.setLastRead(18, 10);
      final reloaded = await AppState.load();
      expect(reloaded.isBookmarked(2, 255), isTrue);
      expect(reloaded.isFavouriteAyah(1, 1), isTrue);
      expect(reloaded.lastRead, const QuranRef(18, 10));
      expect(reloaded.readingHistory.first['s'], 18);
    });

    test('data persists across reload', () async {
      final today = state.today;
      state.setPrayer(today, 'isha', PrayerStatus.jamaat, now: lateIn(today));
      state.settings.urdu = true;
      state.settings.userName = 'Hassan';
      state.saveSettings();
      await state.flush();
      final reloaded = await AppState.load();
      expect(reloaded.day(today).prayer('isha'), PrayerStatus.jamaat);
      expect(reloaded.settings.urdu, isTrue);
      expect(reloaded.settings.userName, 'Hassan');
    });

    test('date change does not erase previous records', () {
      final yesterday = state.today.subtract(const Duration(days: 1));
      state.setDone(yesterday, 'wudu', true);
      expect(state.day(state.today).done.contains('wudu'), isFalse);
      expect(state.day(yesterday).done.contains('wudu'), isTrue);
    });

    test('streak counts days with all 5 prayers', () {
      final today = state.today;
      for (var i = 1; i <= 3; i++) {
        final d = today.subtract(Duration(days: i));
        for (final k in prayerKeys) {
          state.setPrayer(d, k, PrayerStatus.alone);
        }
      }
      expect(state.currentStreak(), 3);
      for (final k in prayerKeys) {
        state.setPrayer(today, k, PrayerStatus.jamaat, now: lateIn(today));
      }
      expect(state.currentStreak(), 4);
      expect(state.bestStreak(), 4);
    });

    test('prayer offsets shift times', () {
      final base = state.prayerTimes(state.today)[PrayerName.asr];
      state.setPrayerOffset('asr', 5);
      expect(state.prayerTimes(state.today)[PrayerName.asr].difference(base).inMinutes, 5);
      state.setPrayerOffset('asr', 500);
      expect(state.settings.prayerOffsets['asr'], 60);
    });

    test('user can set their own prayer time', () {
      state.setFixedPrayerTime('fajr', 5 * 60 + 30);
      final t = state.prayerTimes(state.today)[PrayerName.fajr].toLocal();
      expect(t.hour, 5);
      expect(t.minute, 30);
      expect(state.hasFixedTime('fajr'), isTrue);
      state.setFixedPrayerTime('fajr', null);
      expect(state.hasFixedTime('fajr'), isFalse);
    });

    test('routine add, edit, reorder, delete, repeat days', () {
      final today = state.today;
      final item = RoutineItem(
        id: 'custom_x',
        en: 'Exercise',
        ur: 'Exercise',
        section: RoutineSection.day,
        timeMinutes: 7 * 60,
        custom: true,
        category: RoutineCategory.health,
      );
      state.addRoutineItem(item);
      expect(state.routineFor(today).any((i) => i.id == 'custom_x'), isTrue);
      state.updateRoutineItem(item.copyWith(days: {today.weekday == 1 ? 2 : 1}));
      expect(state.routineFor(today).any((i) => i.id == 'custom_x'), isFalse);
      final idx = state.allItems.indexWhere((i) => i.id == 'custom_x');
      state.reorderRoutine(idx, 0);
      expect(state.allItems.first.id, 'custom_x');
      state.deleteRoutineItem('custom_x');
      expect(state.itemById('custom_x'), isNull);
    });

    test('templates save and apply', () {
      state.saveTemplate('Normal');
      state.deleteRoutineItem('yaseen');
      expect(state.itemById('yaseen'), isNull);
      state.applyTemplate('Normal');
      expect(state.itemById('yaseen'), isNotNull);
    });

    test('Friday-only item only on Friday', () {
      var d = state.today;
      while (d.weekday != DateTime.friday) {
        d = d.add(const Duration(days: 1));
      }
      expect(state.routineFor(d).any((i) => i.id == 'kahf'), isTrue);
      expect(state.routineFor(d.add(const Duration(days: 1))).any((i) => i.id == 'kahf'), isFalse);
    });

    test('habits and sadaqah', () {
      state.addHabit('Charity', 2);
      final id = state.settings.habits.first.id;
      state.changeHabit(state.today, id, 1);
      state.changeHabit(state.today, id, -5);
      expect(state.day(state.today).habits[id], 0);
      state.addSadaqah(state.today, 100, 'masjid');
      state.addSadaqah(state.today, 50.5, '');
      expect(state.sadaqahOn(state.today), 150.5);
      expect(state.sadaqahInMonth(state.today.year, state.today.month), 150.5);
      state.deleteSadaqah(state.sadaqah.first.id);
      expect(state.sadaqahOn(state.today), 100);
    });

    test('chilla day and number', () {
      expect(state.chillaOn(state.today), isNull);
      state.startChilla(state.today.subtract(const Duration(days: 44)));
      expect(state.chillaOn(state.today), (2, 5));
      state.startChilla(state.today);
      expect(state.chillaOn(state.today), (1, 1));
    });

    test('daily report has prayers, tilawat and morning/evening tasbeehat', () {
      final today = state.today;
      state.startChilla(today);
      for (final k in prayerKeys) {
        state.setPrayer(today, k, PrayerStatus.jamaat, now: lateIn(today));
      }
      state.setDone(today, 'yaseen', true, now: lateIn(today));
      for (var i = 0; i < 100; i++) {
        state.incrementDhikr(today, 'kalima3@e');
      }
      final ur = buildDailyReport(state, today, urdu: true);
      expect(ur, contains('چلہ : 01'));
      expect(ur, contains('باجماعت'));
      expect(ur, contains('*تلاوت*'));
      expect(ur, contains('سورۃ الواقعہ'));
      expect(ur, contains('*تسبیحات:* صبح'));
      expect(ur, contains('*تسبیحات:* شام'));
      final en = buildDailyReport(state, today, urdu: false);
      expect(en, contains('Third Kalima  ✅'));
      expect(en, contains('Surah Yaseen  ✅'));
      expect(en, contains('Surah Al-Waqiah  ❌'));
    });

    test('muhasaba fields are stored per day', () {
      state.setMuhasaba(state.today, 'goals', 'Pray Fajr in masjid');
      expect(state.day(state.today).muhasaba['goals'], 'Pray Fajr in masjid');
      state.setMuhasaba(state.today, 'goals', '  ');
      expect(state.day(state.today).muhasaba.containsKey('goals'), isFalse);
    });

    test('category stats', () {
      final today = state.today;
      for (final k in prayerKeys) {
        state.setPrayer(today, k, PrayerStatus.alone, now: lateIn(today));
      }
      state.setDone(today, 'morning_azkar', true, now: lateIn(today));
      final st = state.categoryStats([today]);
      expect(st['namaz'], 1.0);
      expect(st['azkar'], 0.5);
    });

    test('backup export / import round trip', () async {
      final today = state.today;
      state.setPrayer(today, 'fajr', PrayerStatus.jamaat, now: lateIn(today));
      state.addSadaqah(today, 20, 'x');
      await state.flush();
      final backup = jsonDecode(jsonEncode(state.exportData())) as Map<String, dynamic>;

      SharedPreferences.setMockInitialValues({});
      final fresh = await AppState.load();
      expect(fresh.day(today).prayer('fajr'), PrayerStatus.none);
      expect(await fresh.importData(backup), isTrue);
      expect(fresh.day(today).prayer('fajr'), PrayerStatus.jamaat);
      expect(fresh.sadaqahOn(today), 20);
      expect(await fresh.importData({'app': 'other'}), isFalse);
    });
  });

  test('saved v2 routine gets new chilla items', () async {
    final old = defaultRoutine.where((i) => !newDefaultIds.contains(i.id)).map((e) => e.toJson()).toList();
    SharedPreferences.setMockInitialValues({
      'settings': jsonEncode({'onboarded': true, 'routine': old}),
    });
    final state = await AppState.load();
    for (final id in newDefaultIds) {
      expect(state.itemById(id), isNotNull, reason: id);
    }
    final ids = state.allItems.map((e) => e.id).toList();
    expect(ids.indexOf('awabeen'), ids.indexOf('maghrib') + 1);
    expect(ids.indexOf('waqiah'), ids.indexOf('awabeen') + 1);
    expect(ids.indexOf('m_istighfar'), ids.indexOf('tasbeeh_100') + 1);
  });

  test('v1 settings migrate to the new routine model', () async {
    final v1 = {
      'urdu': false,
      'city': 1,
      'notifications': true,
      'tahajjud': false,
      'disabled': ['yaseen'],
      'custom': [
        {'id': 'custom_1', 'en': 'Read hadith', 'ur': 'Read hadith', 'section': 2, 'target': '1'}
      ],
      'onboarded': true,
    };
    SharedPreferences.setMockInitialValues({
      'settings': jsonEncode(v1),
      'day_${dayKey(DateTime.now())}': jsonEncode({
        'done': ['wudu'],
        'prayers': {'fajr': 2},
        'sunnah': [],
        'quran': 3,
        'dhikr': {},
        'azkar': {},
        'note': 'old note',
      }),
    });
    final state = await AppState.load();
    expect(state.settings.onboarded, isTrue);
    expect(state.itemById('yaseen')!.enabled, isFalse);
    expect(state.itemById('custom_1')!.en, 'Read hadith');
    expect(state.settings.notif['tahajjud'], isFalse);
    final rec = state.day(state.today);
    expect(rec.done.contains('wudu'), isTrue);
    expect(rec.prayer('fajr'), PrayerStatus.jamaat);
    expect(rec.quranPages, 3);
    expect(rec.note, 'old note');
  });

  group('Daily Deen 3.0 schedule engine', () {
    late AppState state;
    late DateTime today;
    late DayPrayerTimes times;
    DateTime at(PrayerName p, [int minutes = 0]) => times[p].toLocal().add(Duration(minutes: minutes));

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      state = await AppState.load();
      today = state.today;
      times = state.prayerTimes(today);
    });

    test('prayer windows follow the next boundary', () {
      ActivityWindow w(String id) => state.windowOf(state.itemById(id)!, today);
      expect(w('fajr').start, at(PrayerName.fajr));
      expect(w('fajr').end, at(PrayerName.sunrise));
      expect(w('dhuhr').end, at(PrayerName.asr));
      expect(w('asr').end, at(PrayerName.maghrib));
      expect(w('maghrib').end, at(PrayerName.isha));
      final next = state.prayerTimes(today.add(const Duration(days: 1)))[PrayerName.fajr].toLocal();
      expect(w('isha').end, next);
      expect(w('morning_azkar').start, at(PrayerName.fajr));
      expect(w('evening_azkar').start, at(PrayerName.asr));
      expect(w('ishraq').start, at(PrayerName.sunrise, 20));
    });

    test('future prayers are locked, current one can be recorded', () {
      final now = at(PrayerName.dhuhr, 10);
      expect(state.canRecordPrayer(today, 'dhuhr', now: now), isTrue);
      expect(state.canRecordPrayer(today, 'asr', now: now), isFalse);
      expect(state.setPrayer(today, 'asr', PrayerStatus.jamaat, now: now), isFalse);
      expect(state.day(today).prayer('asr'), PrayerStatus.none);
      expect(state.setPrayer(today, 'dhuhr', PrayerStatus.jamaat, now: now), isTrue);
      // A future date is always locked; a past date is editable.
      final tomorrow = today.add(const Duration(days: 1));
      expect(state.setPrayer(tomorrow, 'fajr', PrayerStatus.alone, now: now), isFalse);
      final yesterday = today.subtract(const Duration(days: 1));
      expect(state.setPrayer(yesterday, 'isha', PrayerStatus.qaza, now: now), isTrue);
    });

    test('states: upcoming, active, in progress, completed, missed, skipped', () {
      final morning = state.itemById('morning_azkar')!;
      final durood = state.itemById('m_durood')!;
      expect(state.activityState(morning, today, now: at(PrayerName.fajr, -5)), ActivityState.upcoming);
      expect(state.toggleItem(today, morning, now: at(PrayerName.fajr, -5)), isFalse);
      expect(state.activityState(morning, today, now: at(PrayerName.fajr, 5)), ActivityState.active);
      expect(state.activityState(morning, today, now: at(PrayerName.dhuhr, 1)), ActivityState.missed);
      state.incrementDhikr(today, 'durood@m');
      expect(state.activityState(durood, today, now: at(PrayerName.fajr, 5)), ActivityState.inProgress);
      expect(state.toggleItem(today, morning, now: at(PrayerName.fajr, 5)), isTrue);
      expect(state.activityState(morning, today, now: at(PrayerName.dhuhr, 1)), ActivityState.completed);
      final yaseen = state.itemById('yaseen')!;
      state.toggleSkip(today, yaseen);
      expect(state.activityState(yaseen, today, now: at(PrayerName.dhuhr, 1)), ActivityState.skipped);
    });

    test('unrecorded past prayer counts as missed', () {
      final yesterday = today.subtract(const Duration(days: 1));
      expect(state.effectivePrayerStatus(yesterday, 'fajr'), PrayerStatus.missed);
      expect(state.scoreFor(yesterday).farzMissed, 5);
    });

    test('score: only started items count; optional never lowers farz/routine', () {
      final now = at(PrayerName.fajr, 30);
      final s0 = state.scoreFor(today, now: now);
      expect(s0.farzDue, 1, reason: 'only Fajr has started');
      state.setPrayer(today, 'fajr', PrayerStatus.jamaat, now: now);
      final s1 = state.scoreFor(today, now: now);
      expect(s1.farz, 1.0);
      expect(s1.farzJamaat, 1);
      final tasbeeh = state.itemById('tasbeeh_100')!;
      expect(tasbeeh.optional, isTrue);
      // Missing an optional activity changes neither Farz nor Routine.
      expect(s1.routineDue, s0.routineDue);
      expect(s1.optionalDone, 0);
      for (var i = 0; i < 100; i++) {
        state.incrementDhikr(today, 'subhanallah');
      }
      final s2 = state.scoreFor(today, now: now);
      expect(s2.optionalDone, 1);
      expect(s2.farz, s1.farz);
      expect(s2.routine, s1.routine);
    });

    test('qaza is tracked separately from on-time prayers', () {
      final yesterday = today.subtract(const Duration(days: 1));
      state.setPrayer(yesterday, 'fajr', PrayerStatus.qaza);
      state.setPrayer(yesterday, 'dhuhr', PrayerStatus.jamaat);
      state.setPrayer(yesterday, 'asr', PrayerStatus.alone);
      final sc = state.scoreFor(yesterday);
      expect(sc.farzQaza, 1);
      expect(sc.farzJamaat, 1);
      expect(sc.farzOnTime, 1);
      expect(sc.farzMissed, 2);
    });

    test('dhikr target change, reset and undo recalculate completion', () {
      final item = state.itemById('m_istighfar')!;
      for (var i = 0; i < 50; i++) {
        state.incrementDhikr(today, item.dhikrKey!);
      }
      expect(state.isDone(today, item), isFalse);
      state.setDhikrTarget(item.dhikrKey!, 50);
      expect(state.isDone(today, item), isTrue);
      final prev = state.resetDhikr(today, item.dhikrKey!);
      expect(prev, 50);
      expect(state.isDone(today, item), isFalse);
      state.restoreDhikr(today, item.dhikrKey!, prev);
      expect(state.isDone(today, item), isTrue);
    });

    test('quran target change recalculates and khatam full reset', () {
      final item = state.itemById('quran_daily')!;
      state.addPages(today, 3);
      state.setQuranTarget(3);
      expect(state.isDone(today, item), isTrue);
      state.setQuranTarget(5);
      expect(state.isDone(today, item), isFalse);
      state.addPages(today, 604);
      expect(state.khatamCount, 1);
      state.resetKhatam();
      expect(state.khatamCount, 1);
      state.resetKhatamFull();
      expect(state.khatamCount, 0);
      expect(state.khatamPages, 0);
    });

    test('duplicate bookmarks are not stored', () {
      state.toggleBookmark(2, 255);
      state.toggleBookmark(2, 255);
      state.toggleBookmark(2, 255);
      expect(state.isBookmarked(2, 255), isTrue);
    });

    test('invalid backup is rejected and data is kept', () async {
      state.setPrayer(today.subtract(const Duration(days: 1)), 'fajr', PrayerStatus.jamaat);
      await state.flush();
      final good = jsonDecode(jsonEncode(state.exportData())) as Map<String, dynamic>;
      expect(AppState.validateBackup(good), isNull);
      final bad = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
      (bad['data'] as Map)['settings'] = '{not json';
      expect(await state.importDataSafe(bad), isNotNull);
      expect(state.day(today.subtract(const Duration(days: 1))).prayer('fajr'), PrayerStatus.jamaat);
      final future = Map<String, dynamic>.of(good)..['version'] = AppState.backupVersion + 1;
      expect(await state.importDataSafe(future), isNotNull);
      expect(await state.importDataSafe(good), isNull);
    });

    test('old routine data (v2) migrates and keeps ids', () async {
      final old = [
        for (final it in defaultRoutine.take(10)) {...it.toJson()}..remove('anchor'),
        {'id': 'custom_1', 'en': 'Walk', 'ur': 'Walk', 'section': 1, 'time': 7 * 60, 'custom': true},
      ];
      SharedPreferences.setMockInitialValues({
        'settings': jsonEncode({'routine': old, 'rv': 2, 'onboarded': true}),
      });
      final migrated = await AppState.load();
      expect(migrated.itemById('custom_1'), isNotNull);
      expect(migrated.itemById('m_kalima3'), isNotNull, reason: 'new defaults added');
      final w = migrated.windowOf(migrated.itemById('custom_1')!, migrated.today);
      expect(w.start, migrated.today.add(const Duration(hours: 7)));
    });

    test('custom prayer-relative schedule is used and persisted', () async {
      final item = state.itemById('yaseen')!;
      state.updateRoutineItem(item.copyWith(anchor: 'maghrib', startOffset: 5, endAnchor: 'isha', endOffset: -5));
      await state.flush();
      final w = state.windowOf(state.itemById('yaseen')!, today);
      expect(w.start, at(PrayerName.maghrib, 5));
      expect(w.end, at(PrayerName.isha, -5));
      final reloaded = await AppState.load();
      expect(reloaded.itemById('yaseen')!.anchor, 'maghrib');
      expect(reloaded.itemById('yaseen')!.endOffset, -5);
    });

    test('yesterday\'s Isha is carried over before Fajr', () {
      final yesterday = today.subtract(const Duration(days: 1));
      final early = at(PrayerName.fajr, -20);
      final carried = state.carriedOver(now: early).map((e) => e.item.id).toList();
      expect(carried, contains('isha'));
      expect(state.setPrayer(yesterday, 'isha', PrayerStatus.alone, now: early), isTrue);
      expect(state.carriedOver(now: early).map((e) => e.item.id), isNot(contains('isha')));
      expect(state.carriedOver(now: at(PrayerName.fajr, 10)), isEmpty);
    });

    test('day change on resume notifies and reschedules', () {
      var calls = 0;
      state.onScheduleChanged = (_) => calls++;
      state.onResume(now: DateTime.now());
      expect(calls, 0);
      state.onResume(now: DateTime.now().add(const Duration(days: 1)));
      expect(calls, 1);
    });

    test('schedule phases are in day order', () {
      expect(ScheduleEngine.phaseOf(at(PrayerName.fajr, -30), times), DayPhase.earlyMorning);
      expect(ScheduleEngine.phaseOf(at(PrayerName.fajr, 5), times), DayPhase.afterFajr);
      expect(ScheduleEngine.phaseOf(at(PrayerName.asr, 5), times), DayPhase.afterAsr);
      expect(ScheduleEngine.phaseOf(at(PrayerName.isha, 5), times), DayPhase.afterIsha);
    });

    test('version shown in the app matches pubspec', () {
      final pub = File('pubspec.yaml').readAsStringSync();
      final m = RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(pub)!;
      expect(appVersion, m.group(1));
    });

    test('all new 3.0 strings exist', () {
      for (final k in ['locked_until', 'prayer_locked', 'counter_completed_hint', 'not_recorded', 'starts_in', 'farz',
        'routine', 'optional', 'phase_afterIsha', 'retry', 'sehri', 'iftar', 'exact_alarms']) {
        expect(S.has(k), isTrue, reason: k);
      }
    });
  });

  group('Daily Deen 3.1 remaining tasks', () {
    late AppState state;
    late DateTime today;
    late DayPrayerTimes times;
    DateTime at(PrayerName p, [int minutes = 0]) => times[p].toLocal().add(Duration(minutes: minutes));
    DateTime clockAt(int h, int m) => DateTime(today.year, today.month, today.day, h, m);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      state = await AppState.load();
      today = state.today;
      times = state.prayerTimes(today);
    });

    test('azkar mode: after prayer (+offset) is never marked missed', () {
      state.setAzkarSchedule('morning_azkar', const AzkarSchedule.afterPrayer('fajr', offset: 15));
      final it = state.itemById('morning_azkar')!;
      expect(AzkarSchedule.of(it), const AzkarSchedule.afterPrayer('fajr', offset: 15));
      expect(state.windowOf(it, today).start, at(PrayerName.fajr, 15));
      expect(state.activityState(it, today, now: at(PrayerName.fajr, 10)), ActivityState.upcoming);
      expect(state.activityState(it, today, now: at(PrayerName.fajr, 20)), ActivityState.active);
      expect(state.activityState(it, today, now: lateIn(today)), ActivityState.active, reason: 'no expiry');
    });

    test('azkar mode: fixed time', () {
      state.setAzkarSchedule('evening_azkar', const AzkarSchedule.fixed(17 * 60));
      final it = state.itemById('evening_azkar')!;
      expect(state.windowOf(it, today).start, clockAt(17, 0));
      expect(state.activityState(it, today, now: clockAt(16, 59)), ActivityState.upcoming);
      expect(state.activityState(it, today, now: clockAt(23, 0)), ActivityState.active);
    });

    test('azkar mode: time window becomes missed only after the window', () {
      state.setAzkarSchedule('morning_azkar', const AzkarSchedule.window(7 * 60, 10 * 60));
      final it = state.itemById('morning_azkar')!;
      final w = state.windowOf(it, today);
      expect(w.start, clockAt(7, 0));
      expect(w.end, clockAt(10, 0));
      expect(state.activityState(it, today, now: clockAt(6, 59)), ActivityState.upcoming);
      expect(state.activityState(it, today, now: clockAt(9, 59)), ActivityState.active);
      expect(state.activityState(it, today, now: clockAt(10, 0)), ActivityState.missed);
      // A window crossing midnight ends the next day.
      state.setAzkarSchedule('sleep_azkar', const AzkarSchedule.window(22 * 60, 60));
      final sw = state.windowOf(state.itemById('sleep_azkar')!, today);
      expect(sw.end, clockAt(1, 0).add(const Duration(days: 1)));
    });

    test('azkar schedule persists and resets to the default', () async {
      final def = state.itemById('morning_azkar')!;
      state.setAzkarSchedule('morning_azkar', const AzkarSchedule.fixed(8 * 60));
      await state.flush();
      final reloaded = await AppState.load();
      expect(AzkarSchedule.of(reloaded.itemById('morning_azkar')!), const AzkarSchedule.fixed(8 * 60));
      expect(reloaded.itemById('morning_azkar')!.id, 'morning_azkar');
      reloaded.setAzkarSchedule('morning_azkar', null);
      final back = reloaded.itemById('morning_azkar')!;
      expect(AzkarSchedule.of(back), isNull);
      expect(back.anchor, isNull);
      expect(back.timeMinutes, def.timeMinutes);
    });

    test('routine undo restores state, time and score', () {
      final now = at(PrayerName.fajr, 30);
      final it = state.itemById('morning_azkar')!;
      final other = state.itemById('kursi_morning')!;
      state.toggleItem(today, other, now: now);
      final before = state.scoreFor(today, now: now);
      final snap = state.snapshotOf(today, it);
      expect(state.toggleItem(today, it, now: now), isTrue);
      expect(state.scoreFor(today, now: now).done, before.done + 1);
      state.restoreSnapshot(today, snap);
      expect(state.isDone(today, it), isFalse);
      expect(state.completedTime(today, it.id), isNull);
      expect(state.scoreFor(today, now: now).done, before.done);
      expect(state.isDone(today, other), isTrue, reason: 'undo must not touch other activities');
      expect(state.day(today).done.where((e) => e == 'kursi_morning').length, 1);
    });

    test('undo of a prayer restores its previous status', () {
      final now = at(PrayerName.dhuhr, 10);
      final dhuhr = state.itemById('dhuhr')!;
      final snap = state.snapshotOf(today, dhuhr);
      state.setPrayer(today, 'dhuhr', PrayerStatus.jamaat, now: now);
      state.restoreSnapshot(today, snap);
      expect(state.day(today).prayer('dhuhr'), PrayerStatus.none);
    });

    test('counter-linked undo never changes the counter', () {
      final now = at(PrayerName.fajr, 30);
      final it = state.itemById('m_durood')!;
      for (var i = 0; i < 40; i++) {
        state.incrementDhikr(today, 'durood@m');
      }
      final snap = state.snapshotOf(today, it);
      expect(state.toggleItem(today, it, now: now), isTrue, reason: 'manual mark');
      expect(state.isDone(today, it), isTrue);
      state.restoreSnapshot(today, snap);
      expect(state.isDone(today, it), isFalse);
      expect(state.day(today).dhikr['durood@m'], 40);
      // Completed by the counter: toggling off is refused and changes nothing.
      for (var i = 0; i < 60; i++) {
        state.incrementDhikr(today, 'durood@m');
      }
      final at0 = state.day(today).completedAt['m_durood'];
      expect(state.toggleItem(today, it, now: now), isFalse);
      expect(state.day(today).dhikr['durood@m'], 100);
      expect(state.day(today).completedAt['m_durood'], at0);
    });

    test('reports: day / week / month use the scoring service', () {
      final y = today.subtract(const Duration(days: 1));
      for (final k in prayerKeys) {
        state.setPrayer(y, k, k == 'fajr' ? PrayerStatus.qaza : PrayerStatus.jamaat);
      }
      state.setDone(y, 'morning_azkar', true);
      state.day(y).quranPages = state.settings.quranTarget;
      final week = buildRangeReport(state, state.daysBetween(today.subtract(const Duration(days: 6)), today),
          now: lateIn(today));
      expect(week.jamaat, 4);
      expect(week.qaza, 1);
      expect(week.morning, 1);
      expect(week.quranTargetDays, 1);
      expect(week.perPrayer['dhuhr']!.$1, 1);
      final ys = state.scoreFor(y);
      final yr = buildRangeReport(state, [y]);
      expect(yr.farz, ys.farz);
      expect(yr.overall, ys.overall);
      final day = buildRangeReport(state, [today], now: lateIn(today));
      expect(day.days, 1);
      final month = buildRangeReport(state, state.daysBetween(DateTime(today.year, today.month, 1), today));
      expect(month.days, greaterThanOrEqualTo(1));
    });

    test('chilla: completed, partial, missed days; missed never resets', () {
      final start = today.subtract(const Duration(days: 3));
      state.startChilla(start);
      void complete(DateTime d) {
        for (final k in prayerKeys) {
          state.setPrayer(d, k, PrayerStatus.jamaat, now: lateIn(today));
        }
        for (final id in [...reportTilawat, ...reportMorning, ...reportEvening]) {
          state.setDone(d, id, true, now: lateIn(today));
        }
      }

      complete(start);
      state.setPrayer(start.add(const Duration(days: 1)), 'fajr', PrayerStatus.alone);
      complete(start.add(const Duration(days: 3)));
      final sum = chillaSummary(state, now: lateIn(today))!;
      expect(sum.days[0].state, ChillaDayState.completed);
      expect(sum.days[1].state, ChillaDayState.partial);
      expect(sum.days[2].state, ChillaDayState.missed);
      expect(sum.days[3].state, ChillaDayState.completed);
      expect(sum.days[4].state, ChillaDayState.upcoming);
      expect(sum.currentDay, 4);
      expect(sum.completedDays, 2);
      expect(sum.streak, 1);
      expect(sum.bestStreak, 1);
      expect(state.settings.chillaStart, dayKey(start), reason: 'missed day does not reset');
      expect(sum.end, start.add(const Duration(days: 39)));
    });

    test('notification plan: azkar schedule, no duplicates, only future', () {
      state.setAzkarSchedule('morning_azkar', const AzkarSchedule.afterPrayer('fajr', offset: 15));
      // Also flag it as a routine reminder: it must still be planned once.
      state.updateRoutineItem(state.itemById('morning_azkar')!.copyWith(reminder: true));
      final now = at(PrayerName.fajr, -20);
      final plan = NotificationService.plan(state, now: now);
      expect(plan.map((r) => r.id).toSet().length, plan.length, reason: 'unique ids');
      expect(plan.map((r) => '${r.title}|${r.when.toUtc().millisecondsSinceEpoch ~/ 60000}').toSet().length,
          plan.length, reason: 'no duplicate reminders');
      expect(plan.every((r) => r.when.isAfter(now)), isTrue);
      final morning = plan.where((r) => r.id == 1200).single;
      expect(morning.when, at(PrayerName.fajr, 15));
      expect(plan.where((r) => r.title == state.s.t('morning_azkar') && r.when == at(PrayerName.fajr, 15)).length, 1);
      // Rescheduling later drops reminders that are now in the past.
      final later = NotificationService.plan(state, now: at(PrayerName.fajr, 20));
      expect(later.any((r) => r.id == 1200), isFalse);
      expect(later.any((r) => r.id == 0), isFalse, reason: "today's Fajr already passed");
    });

    test('notifications off plans nothing', () {
      state.settings.notifications = false;
      expect(NotificationService.plan(state), isEmpty);
    });

    test('timezone / clock change on resume triggers a reschedule', () {
      var calls = 0;
      state.onScheduleChanged = (_) => calls++;
      final t = clock();
      state.onResume(now: t);
      expect(calls, 0);
      state.onResume(now: t.add(const Duration(hours: 7)));
      expect(calls, 1, reason: 'clock moved (TIME_SET) or long background');
      expect(state.settings.autoTimezone, isTrue);
      state.settings.autoTimezone = false;
      state.saveSettings();
      expect(state.settings.toJson()['autoTz'], isFalse);
    });

    test('older backups import and keep ids and data', () async {
      final y = today.subtract(const Duration(days: 1));
      state.setPrayer(y, 'asr', PrayerStatus.jamaat);
      state.addRoutineItem(RoutineItem(id: 'custom_walk', en: 'Walk', ur: 'Walk', section: RoutineSection.day));
      await state.flush();
      final backup = jsonDecode(jsonEncode(state.exportData())) as Map<String, dynamic>;
      backup['version'] = 2; // an older backup format
      final settings = jsonDecode((backup['data'] as Map)['settings'] as String) as Map<String, dynamic>;
      settings.remove('autoTz');
      settings.remove('exact');
      (backup['data'] as Map)['settings'] = jsonEncode(settings);
      SharedPreferences.setMockInitialValues({});
      final fresh = await AppState.load();
      expect(await fresh.importDataSafe(backup), isNull);
      expect(fresh.day(y).prayer('asr'), PrayerStatus.jamaat);
      expect(fresh.allItems.map((e) => e.id).toList(), state.allItems.map((e) => e.id).toList());
      expect(fresh.settings.autoTimezone, isTrue);
    });
  });

  group('Daily Deen 3.2', () {
    test('awabeen nawafil after Maghrib', () async {
      SharedPreferences.setMockInitialValues({});
      final state = await AppState.load();
      final it = state.itemById('awabeen')!;
      expect(it.optional, isTrue);
      final times = state.prayerTimes(state.today);
      final w = state.windowOf(it, state.today);
      expect(w.start, times[PrayerName.maghrib].toLocal().add(const Duration(minutes: 5)));
      expect(w.end, times[PrayerName.isha].toLocal());
      // Saved v3 routines get Awabeen added without touching other items.
      final old = [for (final d in defaultRoutine.where((e) => e.id != 'awabeen')) d.toJson()];
      SharedPreferences.setMockInitialValues({
        'settings': jsonEncode({'routine': old, 'rv': 3, 'onboarded': true}),
      });
      final migrated = await AppState.load();
      expect(migrated.itemById('awabeen'), isNotNull);
      final ids = migrated.allItems.map((e) => e.id).toList();
      expect(ids.indexOf('awabeen'), ids.indexOf('maghrib') + 1);
      expect(ids.where((e) => e == 'awabeen').length, 1);
    });

    test('new azkar: categories, unique ids, extras keep old progress', () {
      expect(azkar[AzkarType.salah]!.length, greaterThanOrEqualTo(10));
      expect(azkar[AzkarType.kalimas]!.length, 6);
      final ids = <String>{};
      for (final list in azkar.values) {
        for (final z in list) {
          ids.add(z.id);
          expect(z.arabic.trim(), isNotEmpty, reason: z.id);
          expect(z.en.trim(), isNotEmpty, reason: z.id);
          expect(z.ur.trim(), isNotEmpty, reason: z.id);
          expect(z.count, greaterThan(0));
        }
      }
      expect(ids.contains('sayyid_istighfar'), isTrue);
      expect(ids.contains('after_adhan'), isTrue);
      // 3.4: morning/evening follow equranlibrary chapters 1 and 2 exactly,
      // every item counts; sleep keeps its 7 core items + optional extras.
      final m = azkar[AzkarType.morning]!;
      final e = azkar[AzkarType.evening]!;
      expect(m.length, 40);
      expect(e.length, 38);
      expect(coreAzkarIndices(AzkarType.morning).length, 40);
      expect(coreAzkarIndices(AzkarType.evening).length, 38);
      expect(coreAzkarIndices(AzkarType.sleep).length, 7);
      expect(azkar[AzkarType.sleep]!.any((z) => z.extra), isTrue);
      for (final list in [m, e]) {
        expect(list.map((z) => z.id).toSet().length, list.length, reason: 'unique ids');
      }
      expect([m.first.id, m[1].id, m[2].id, m[4].id], ['four_words', 'kursi', 'three_quls', 'la_yadurru']);
      expect([m[19].id, m[20].id, m[35].id, m.last.id], ['subhan_bihamdihi', 'ashhaduka_m', 'rum_17_19', 'ikfini_2']);
      expect([e[18].id, e[19].id, e[32].id, e[33].id, e.last.id],
          ['ashhaduka_e', 'subhan_bihamdihi', 'ala_nafsi', 'rabbiyallah', 'adada_ma_khalaqa']);
      expect(m[5].arabic, contains('الْمَصِيرُ'));
      expect(e[5].arabic, contains('النُّشُورُ'));
      expect(m[2].count, 3);
      final counts = <String, int>{for (var i = 0; i < m.length; i++) 'morning_$i': m[i].count};
      expect(coreAzkarDone(AzkarType.morning, (k) => counts[k] ?? 0), 40);
    });
  });

  group('Daily Deen 3.3 Quran resume', () {
    test('each surah keeps its own position and it persists', () async {
      SharedPreferences.setMockInitialValues({'lastRead': '2:120'});
      final state = await AppState.load();
      expect(state.resumeAyah(2), 120, reason: 'migrated from the old single last-read');
      state.setLastRead(18, 40);
      state.setLastRead(1, 5);
      expect(state.resumeAyah(2), 120);
      expect(state.resumeAyah(18), 40);
      expect(state.resumeAyah(36), 1);
      final reloaded = await AppState.load();
      expect(reloaded.resumeAyah(18), 40);
      expect(reloaded.lastRead, const QuranRef(1, 5));
    });

    test('session pages read', () {
      final session = QuranSession(const QuranRef(2, 30), 7);
      expect(session.pagesRead, 0);
      session.record(2, 30, 7);
      expect(session.pagesRead, 0);
      session.record(2, 50, 9);
      expect(session.pagesRead, 3);
    });
  });
}
