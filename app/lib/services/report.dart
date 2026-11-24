import '../app_state.dart';
import '../data/routine.dart';
import '../strings.dart';

/// Activities shown in the daily report, grouped as in the user's chilla format.
const reportTilawat = ['yaseen', 'waqiah', 'mulk'];
const reportMorning = ['m_istighfar', 'm_durood', 'm_kalima1', 'm_kalima3', 'm_lailaha'];
const reportEvening = ['e_istighfar', 'e_durood', 'e_kalima1', 'e_kalima3', 'e_lailaha'];

/// Important surahs of [date]: Surah Al-Kahf joins the daily three on Fridays.
List<String> reportTilawatOn(DateTime date) =>
    [...reportTilawat, if (date.weekday == DateTime.friday) 'kahf'];

String reportPrayerStatus(PrayerStatus st, bool urdu) => switch (st) {
      PrayerStatus.jamaat => urdu ? 'باجماعت' : 'With Jamaat',
      PrayerStatus.alone => urdu ? 'انفرادی' : 'Alone',
      PrayerStatus.qaza => urdu ? 'قضا' : 'Qaza',
      PrayerStatus.missed => urdu ? 'رہ گئی' : 'Missed',
      PrayerStatus.none => '—',
    };

/// Short label of a report activity without the "(Morning)" / "(Evening)" suffix.
String reportItemName(RoutineItem item, bool urdu) {
  final n = item.name(urdu);
  final i = n.indexOf(' (');
  return i > 0 ? n.substring(0, i) : n;
}

/// "✅", "❌" or "45/100" for one activity.
String reportMark(AppState state, DateTime date, RoutineItem item) {
  if (state.isDone(date, item)) return '✅';
  if (item.dhikrKey != null) {
    final c = state.day(date).dhikr[item.dhikrKey!] ?? 0;
    if (c > 0) return '$c/${state.dhikrTarget(item.dhikrKey!, item.dhikrTarget)}';
  }
  return '❌';
}

String _two(int n) => n.toString().padLeft(2, '0');

/// WhatsApp-ready daily report in the chilla format.
String buildDailyReport(AppState state, DateTime date, {required bool urdu}) {
  final rec = state.day(date);
  final chilla = state.chillaOn(date);
  final b = StringBuffer();
  final dateText = '${_two(date.day)}-${_two(date.month)}-${date.year}';
  final weekday = (urdu ? weekdaysUr : weekdaysEn)[date.weekday - 1];

  b.writeln(urdu ? 'تاریخ : $dateText ($weekday)' : 'Date : $dateText ($weekday)');
  if (chilla != null) {
    b.writeln(urdu ? 'چلہ : ${_two(chilla.$1)}     دن : ${_two(chilla.$2)}' : 'Chilla : ${_two(chilla.$1)}     Day : ${_two(chilla.$2)}');
  }
  b.writeln();
  b.writeln(urdu ? '*نمازیں*' : '*Prayers*');
  for (final k in prayerKeys) {
    b.writeln('${state.s.t(k).padRight(10)}  ${reportPrayerStatus(rec.prayer(k), urdu)}');
  }

  void section(String title, List<String> ids, {bool bullets = false}) {
    final items = ids.map(state.itemById).whereType<RoutineItem>().toList();
    if (items.isEmpty) return;
    b.writeln();
    b.writeln(title);
    for (final it in items) {
      b.writeln('${bullets ? '- ' : ''}${reportItemName(it, urdu)}  ${reportMark(state, date, it)}');
    }
  }

  section(urdu ? '*تلاوت*' : '*Tilawat*', reportTilawatOn(date));
  section(urdu ? '*تسبیحات:* صبح' : '*Tasbeehat:* Morning', reportMorning, bullets: true);
  section(urdu ? '*تسبیحات:* شام' : '*Tasbeehat:* Evening', reportEvening, bullets: true);
  return b.toString().trimRight();
}


/// (done, total) of the chilla tasks for [date]: 5 prayers, tilawat and
/// morning/evening tasbeehat.
(int, int) chillaProgress(AppState state, DateTime date) {
  final rec = state.day(date);
  var done = prayerKeys.where((k) => isPrayed(rec.prayer(k))).length;
  var total = prayerKeys.length;
  for (final id in [...reportTilawatOn(date), ...reportMorning, ...reportEvening]) {
    final it = state.itemById(id);
    if (it == null) continue;
    total++;
    if (state.isDone(date, it)) done++;
  }
  return (done, total);
}

// ---------------------------------------------------------------------------
// Reports dashboard (all scores come from ScoringService via state.scoreFor)
// ---------------------------------------------------------------------------

/// Aggregated statistics for a range of days.
class RangeReport {
  final int days; // days counted (days before the app was used are skipped)
  final double farz, routine, optional, overall; // averages 0..1
  final int jamaat, alone, qaza, missed;
  final int pages, quranTargetDays;
  final int morning, evening, sleep; // azkar completed days
  final List<(DateTime, double)> daily; // overall score per counted day
  final Map<String, (int, int)> perPrayer; // prayer key -> (prayed, due)
  const RangeReport({
    this.perPrayer = const {},
    this.days = 0,
    this.farz = 0,
    this.routine = 0,
    this.optional = 0,
    this.overall = 0,
    this.jamaat = 0,
    this.alone = 0,
    this.qaza = 0,
    this.missed = 0,
    this.pages = 0,
    this.quranTargetDays = 0,
    this.morning = 0,
    this.evening = 0,
    this.sleep = 0,
    this.daily = const [],
  });
}

/// Builds the dashboard numbers for [days]. Today is always counted; past
/// days only when they have a record (so the time before the app was
/// installed does not count as missed). Future days are ignored.
RangeReport buildRangeReport(AppState state, List<DateTime> days, {DateTime? now}) {
  final t = now ?? clock();
  final today = DateTime(t.year, t.month, t.day);
  var n = 0, jamaat = 0, alone = 0, qaza = 0, missed = 0, pages = 0, targetDays = 0, m = 0, e = 0, sl = 0;
  var farz = 0.0, routine = 0.0, optional = 0.0, overall = 0.0;
  final daily = <(DateTime, double)>[];
  final prayed = {for (final k in prayerKeys) k: 0};
  final due = {for (final k in prayerKeys) k: 0};
  final target = state.settings.quranTarget;
  bool doneId(DateTime d, String id) {
    final it = state.itemById(id);
    return it != null && state.isDone(d, it);
  }

  for (final raw in days) {
    final d = DateTime(raw.year, raw.month, raw.day);
    if (d.isAfter(today)) continue;
    if (d != today && !state.hasRecord(d)) continue;
    final sc = state.scoreFor(d, now: t);
    n++;
    farz += sc.farz;
    routine += sc.routine;
    optional += sc.optional;
    overall += sc.overall;
    jamaat += sc.farzJamaat;
    alone += sc.farzOnTime;
    qaza += sc.farzQaza;
    missed += sc.farzMissed;
    final rec = state.day(d);
    for (final k in prayerKeys) {
      if (d == today && !state.canRecordPrayer(d, k, now: t)) continue;
      due[k] = due[k]! + 1;
      if (isPrayed(rec.prayer(k))) prayed[k] = prayed[k]! + 1;
    }
    pages += rec.quranPages;
    if (target > 0 && rec.quranPages >= target) targetDays++;
    if (doneId(d, 'morning_azkar')) m++;
    if (doneId(d, 'evening_azkar')) e++;
    if (doneId(d, 'sleep_azkar')) sl++;
    daily.add((d, sc.overall));
  }
  double avg(double v) => n == 0 ? 0 : v / n;
  return RangeReport(
    days: n,
    farz: avg(farz),
    routine: avg(routine),
    optional: avg(optional),
    overall: avg(overall),
    jamaat: jamaat,
    alone: alone,
    qaza: qaza,
    missed: missed,
    pages: pages,
    quranTargetDays: targetDays,
    morning: m,
    evening: e,
    sleep: sl,
    daily: daily,
    perPrayer: {for (final k in prayerKeys) k: (prayed[k]!, due[k]!)},
  );
}

// ---------------------------------------------------------------------------
// Chilla (40 days)
// ---------------------------------------------------------------------------

enum ChillaDayState { completed, partial, missed, today, upcoming }

class ChillaDay {
  final int number; // 1..40
  final DateTime date;
  final int done, total;
  final ChillaDayState state;
  const ChillaDay(this.number, this.date, this.done, this.total, this.state);
  double get ratio => total == 0 ? 0 : done / total;
}

class ChillaSummary {
  final int chillaNumber;
  final DateTime start, end; // end = day 40
  final List<ChillaDay> days;
  final int currentDay; // 1..40, 0 before start, 41 after the end
  const ChillaSummary(this.chillaNumber, this.start, this.end, this.days, this.currentDay);

  int get completedDays => days.where((d) => d.state == ChillaDayState.completed).length;
  int get partialDays => days.where((d) => d.state == ChillaDayState.partial).length;
  int get missedDays => days.where((d) => d.state == ChillaDayState.missed).length;
  double get progress => completedDays / 40;

  /// Consecutive completed days ending today (or yesterday if today is not
  /// complete yet). A missed day only breaks the streak; nothing is reset.
  /// Longest run of completed days in this chilla.
  int get bestStreak {
    var best = 0, run = 0;
    for (final d in days) {
      if (d.state == ChillaDayState.completed) {
        run++;
        if (run > best) best = run;
      } else if (d.state != ChillaDayState.today) {
        run = 0;
      }
    }
    return best;
  }

  int get streak {
    var n = 0;
    for (var j = days.length - 1; j >= 0; j--) {
      final st = days[j].state;
      if (st == ChillaDayState.upcoming || st == ChillaDayState.today) continue;
      if (st != ChillaDayState.completed) break;
      n++;
    }
    return n;
  }
}

/// The current chilla (the one containing [now], or the last one started)
/// with a state for each of its 40 days. Returns null if no chilla started.
ChillaSummary? chillaSummary(AppState state, {DateTime? now}) {
  final startRaw = DateTime.tryParse(state.settings.chillaStart ?? '');
  if (startRaw == null) return null;
  final t = now ?? clock();
  final today = DateTime(t.year, t.month, t.day);
  final cur = state.chillaOn(today);
  final number = cur?.$1 ?? 1;
  final first = DateTime(startRaw.year, startRaw.month, startRaw.day + (number - 1) * 40);
  final days = <ChillaDay>[];
  for (var i = 0; i < 40; i++) {
    final d = DateTime(first.year, first.month, first.day + i);
    final (done, total) = d.isAfter(today) ? (0, 0) : chillaProgress(state, d);
    final ChillaDayState st;
    if (d.isAfter(today)) {
      st = ChillaDayState.upcoming;
    } else if (total > 0 && done >= total) {
      st = ChillaDayState.completed;
    } else if (d == today) {
      st = ChillaDayState.today;
    } else if (done > 0) {
      st = ChillaDayState.partial;
    } else {
      st = ChillaDayState.missed;
    }
    days.add(ChillaDay(i + 1, d, done, total, st));
  }
  final diff = DateTime.utc(today.year, today.month, today.day).difference(DateTime.utc(first.year, first.month, first.day)).inDays;
  final currentDay = diff < 0 ? 0 : (diff >= 40 ? 41 : diff + 1);
  return ChillaSummary(number, first, DateTime(first.year, first.month, first.day + 39), days, currentDay);
}
