import 'package:dailydeen/app_state.dart';
import 'package:dailydeen/data/routine.dart';
import 'package:dailydeen/services/hijri.dart';
import 'package:dailydeen/services/prayer_times.dart';
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

  test('Hijri conversion', () {
    final h = HijriDate.fromGregorian(DateTime(2026, 2, 18));
    expect(h.month, 9); // Ramadan 1447
    expect(h.year, 1447);
    final h2 = HijriDate.fromGregorian(DateTime(2026, 11, 16));
    expect(h2.year, 1448);
    expect(h2.month, 6);
  });

  group('AppState', () {
    late AppState state;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      state = await AppState.load();
    });

    test('toggle routine item and completion', () {
      final today = state.today;
      final item = defaultRoutine.firstWhere((i) => i.id == 'wudu');
      final (d0, total) = state.completion(today);
      expect(d0, 0);
      expect(total, greaterThan(20));
      state.toggleItem(today, item);
      expect(state.isDone(today, item), isTrue);
      expect(state.completion(today).$1, 1);
      state.toggleItem(today, item);
      expect(state.isDone(today, item), isFalse);
    });

    test('prayer routine item maps to prayer status', () {
      final today = state.today;
      final fajr = defaultRoutine.firstWhere((i) => i.id == 'fajr');
      state.toggleItem(today, fajr);
      expect(state.day(today).prayer('fajr'), PrayerStatus.alone);
      state.setPrayer(today, 'fajr', PrayerStatus.jamaat);
      expect(state.isDone(today, fajr), isTrue);
      state.setPrayer(today, 'fajr', PrayerStatus.missed);
      expect(state.isDone(today, fajr), isFalse);
    });

    test('dhikr reaching target ticks routine item', () {
      final today = state.today;
      for (var i = 0; i < 99; i++) {
        state.incrementDhikr(today, 'durood');
      }
      expect(state.day(today).done.contains('durood_100'), isFalse);
      state.incrementDhikr(today, 'durood');
      expect(state.day(today).done.contains('durood_100'), isTrue);
    });

    test('quran pages, target and khatam rollover', () {
      final today = state.today;
      state.addPages(today, 4);
      expect(state.day(today).done.contains('quran_daily'), isTrue);
      state.addPages(today, 600);
      expect(state.khatamCount, 1);
      expect(state.khatamPages, 0);
    });

    test('data persists across reload', () async {
      final today = state.today;
      state.setPrayer(today, 'isha', PrayerStatus.jamaat);
      state.settings.urdu = true;
      state.saveSettings();
      final reloaded = await AppState.load();
      expect(reloaded.day(today).prayer('isha'), PrayerStatus.jamaat);
      expect(reloaded.settings.urdu, isTrue);
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
  });
}
