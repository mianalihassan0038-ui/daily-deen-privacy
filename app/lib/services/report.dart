import '../app_state.dart';
import '../data/routine.dart';
import '../strings.dart';

/// Activities shown in the daily report, grouped as in the user's chilla format.
const reportTilawat = ['yaseen', 'waqiah', 'mulk'];
const reportMorning = ['m_istighfar', 'm_durood', 'm_kalima1', 'm_kalima3'];
const reportEvening = ['e_istighfar', 'e_durood', 'e_kalima1', 'e_kalima3'];

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

  section(urdu ? '*تلاوت*' : '*Tilawat*', reportTilawat);
  section(urdu ? '*تسبیحات:* صبح' : '*Tasbeehat:* Morning', reportMorning, bullets: true);
  section(urdu ? '*تسبیحات:* شام' : '*Tasbeehat:* Evening', reportEvening, bullets: true);
  return b.toString().trimRight();
}
