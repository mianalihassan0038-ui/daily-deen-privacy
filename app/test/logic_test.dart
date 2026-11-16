import 'dart:convert';

import 'package:dailydeen/app_state.dart';
import 'package:dailydeen/data/azkar.dart';
import 'package:dailydeen/data/routine.dart';
import 'package:dailydeen/screens/qibla_screen.dart';
import 'package:dailydeen/services/hijri.dart';
import 'package:dailydeen/services/prayer_times.dart';
import 'package:dailydeen/services/report.dart';
import 'package:dailydeen/strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final (d0, total) = state.completion(today);
      expect(d0, 0);
      expect(total, greaterThan(20));
      state.toggleItem(today, item);
      expect(state.isDone(today, item), isTrue);
      expect(state.completion(today).$1, 1);
      state.toggleItem(today, item);
      expect(state.isDone(today, item), isFalse);
    });

    test('skipped items are not counted', () {
      final today = state.today;
      final item = state.itemById('wudu')!;
      final total = state.completion(today).$2;
      state.toggleSkip(today, item);
      expect(state.isSkipped(today, item), isTrue);
      expect(state.completion(today).$2, total - 1);
      state.toggleItem(today, item); // completing un-skips
      expect(state.isSkipped(today, item), isFalse);
      expect(state.isDone(today, item), isTrue);
    });

    test('prayer routine item maps to prayer status', () {
      final today = state.today;
      final fajr = state.itemById('fajr')!;
      state.toggleItem(today, fajr);
      expect(state.day(today).prayer('fajr'), PrayerStatus.alone);
      state.setPrayer(today, 'fajr', PrayerStatus.jamaat);
      expect(state.isDone(today, fajr), isTrue);
      state.setPrayer(today, 'fajr', PrayerStatus.missed);
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
      state.toggleSunnah(today, 'witr');
      expect(state.witrDone(today), isTrue);
      expect(state.isDone(today, state.itemById('witr')!), isTrue);
      state.toggleSunnah(today, 'witr');
      expect(state.witrDone(today), isFalse);
    });

    test('dhikr reaching target ticks routine item', () {
      final today = state.today;
      for (var i = 0; i < 99; i++) {
        state.incrementDhikr(today, 'durood@m');
      }
      expect(state.day(today).done.contains('m_durood'), isFalse);
      state.incrementDhikr(today, 'durood@m');
      expect(state.day(today).done.contains('m_durood'), isTrue);
      expect(state.day(today).done.contains('e_durood'), isFalse, reason: 'evening is counted separately');
      state.incrementDhikr(today, 'durood@m', by: -1);
      expect(state.day(today).done.contains('m_durood'), isFalse);
    });

    test('quran pages, target and khatam rollover', () {
      final today = state.today;
      state.addPages(today, 4);
      expect(state.day(today).done.contains('quran_daily'), isTrue);
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
      state.setPrayer(today, 'isha', PrayerStatus.jamaat);
      state.settings.urdu = true;
      state.settings.userName = 'Hassan';
      state.saveSettings();
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
        state.setPrayer(today, k, PrayerStatus.jamaat);
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
        state.setPrayer(today, k, PrayerStatus.jamaat);
      }
      state.setDone(today, 'yaseen', true);
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
        state.setPrayer(today, k, PrayerStatus.alone);
      }
      state.setDone(today, 'morning_azkar', true);
      final st = state.categoryStats([today]);
      expect(st['namaz'], 1.0);
      expect(st['azkar'], 0.5);
    });

    test('backup export / import round trip', () async {
      final today = state.today;
      state.setPrayer(today, 'fajr', PrayerStatus.jamaat);
      state.addSadaqah(today, 20, 'x');
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
}
