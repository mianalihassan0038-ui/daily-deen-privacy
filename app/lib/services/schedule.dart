import '../data/routine.dart';
import 'prayer_times.dart';

/// Smart Daily Schedule Engine
/// ===========================
/// The single source of truth for *when* an activity can be done. Home,
/// Routine, Namaz, notifications, reports and the daily score all use it.
///
/// Every activity has a window [start, end):
///  * before `start`  -> Upcoming (locked, cannot be completed)
///  * inside window   -> Active / In progress
///  * after `end`     -> Missed (if not completed or skipped)
///
/// A window is described by a [ScheduleSpec]: a start anchor (a prayer time,
/// a fixed clock time or the start of the day) plus an offset, and an end
/// anchor plus an offset. These are application defaults for tracking, not
/// religious rulings, and users can change them per activity.

enum ActivityState { upcoming, active, inProgress, completed, missed, skipped }

/// Phases used as headings in the daily timeline.
enum DayPhase { earlyMorning, afterFajr, morning, afternoon, afterAsr, afterMaghrib, afterIsha }

const scheduleAnchors = ['fixed', 'day', 'fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
const scheduleEndAnchors = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha', 'midnight', 'next_fajr'];

/// Extra end anchors used by the Azkar scheduler:
///  * 'clock' – end at a clock time ([ScheduleSpec.endOffset] = minutes after
///    midnight; an end before the start means the next day),
///  * 'none'  – no expiry: the activity stays available until midnight and is
///    never marked missed.
const extraEndAnchors = ['clock', 'none'];

class ScheduleSpec {
  final String anchor; // see [scheduleAnchors]
  final int startOffset; // minutes
  final String endAnchor; // see [scheduleEndAnchors]
  final int endOffset; // minutes
  const ScheduleSpec(this.anchor, this.endAnchor, {this.startOffset = 0, this.endOffset = 0});

  @override
  String toString() => 'ScheduleSpec($anchor+$startOffset -> $endAnchor+$endOffset)';
}

/// Built-in schedules for the default activities (by id).
const Map<String, ScheduleSpec> defaultSchedules = {
  // Before Fajr
  'wake': ScheduleSpec('fixed', 'fajr'),
  'wudu': ScheduleSpec('fixed', 'fajr'),
  'tahajjud': ScheduleSpec('fixed', 'fajr'),
  'dua_istighfar': ScheduleSpec('fixed', 'fajr'),
  'tilawat_fajr': ScheduleSpec('fixed', 'dhuhr'),
  // Prayers: from their time until the next boundary
  'fajr': ScheduleSpec('fajr', 'sunrise'),
  'dhuhr': ScheduleSpec('dhuhr', 'asr'),
  'asr': ScheduleSpec('asr', 'maghrib'),
  'maghrib': ScheduleSpec('maghrib', 'isha'),
  'isha': ScheduleSpec('isha', 'next_fajr'),
  // After Fajr (morning window ends at Dhuhr by default)
  'morning_azkar': ScheduleSpec('fajr', 'dhuhr'),
  'kursi_morning': ScheduleSpec('fajr', 'dhuhr'),
  'tasbeeh_100': ScheduleSpec('fajr', 'dhuhr'),
  'm_istighfar': ScheduleSpec('fajr', 'dhuhr'),
  'm_durood': ScheduleSpec('fajr', 'dhuhr'),
  'm_kalima1': ScheduleSpec('fajr', 'dhuhr'),
  'm_kalima3': ScheduleSpec('fajr', 'dhuhr'),
  'm_lailaha': ScheduleSpec('fajr', 'dhuhr'),
  'yaseen': ScheduleSpec('fajr', 'dhuhr'),
  // Forenoon
  'ishraq': ScheduleSpec('sunrise', 'dhuhr', startOffset: 20, endOffset: -10),
  'chasht': ScheduleSpec('sunrise', 'dhuhr', startOffset: 90, endOffset: -10),
  // Any time today
  'quran_daily': ScheduleSpec('day', 'midnight'),
  'durood_100': ScheduleSpec('day', 'midnight'),
  'astaghfar_100': ScheduleSpec('day', 'midnight'),
  'kahf': ScheduleSpec('day', 'maghrib'), // Friday, until after Asr
  // After Asr (evening window ends at Maghrib by default)
  'evening_azkar': ScheduleSpec('asr', 'maghrib'),
  'e_istighfar': ScheduleSpec('asr', 'maghrib'),
  'e_durood': ScheduleSpec('asr', 'maghrib'),
  'e_kalima1': ScheduleSpec('asr', 'maghrib'),
  'e_kalima3': ScheduleSpec('asr', 'maghrib'),
  'e_lailaha': ScheduleSpec('asr', 'maghrib'),
  // After Maghrib
  'waqiah': ScheduleSpec('maghrib', 'midnight'),
  'awabeen': ScheduleSpec('maghrib', 'isha', startOffset: 5),
  'tilawat_night': ScheduleSpec('maghrib', 'midnight'),
  // After Isha / before sleep (until next Fajr)
  'witr': ScheduleSpec('isha', 'next_fajr'),
  'kursi_night': ScheduleSpec('isha', 'next_fajr'),
  'baqarah_last2': ScheduleSpec('isha', 'next_fajr'),
  'mulk': ScheduleSpec('isha', 'next_fajr'),
  'sleep_azkar': ScheduleSpec('isha', 'next_fajr'),
  'muhasaba': ScheduleSpec('isha', 'next_fajr'),
};

class ActivityWindow {
  final DateTime start; // local time
  final DateTime end; // local time (exclusive)
  /// False for flexible activities without an expiry: they are never missed.
  final bool expires;
  const ActivityWindow(this.start, this.end, {this.expires = true});

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  @override
  String toString() => 'ActivityWindow($start -> $end)';
}

class ScheduleEngine {
  /// Effective schedule of [item]: user override > built-in default > derived.
  static ScheduleSpec specOf(RoutineItem item) {
    if (item.anchor != null) {
      return ScheduleSpec(item.anchor!, item.endAnchor ?? 'midnight',
          startOffset: item.startOffset, endOffset: item.endOffset);
    }
    final d = defaultSchedules[item.id];
    if (d != null) {
      // A default fixed-time activity whose time the user removed becomes all-day.
      if (d.anchor == 'fixed' && item.timeMinutes == null) return ScheduleSpec('day', d.endAnchor);
      return d;
    }
    if (item.prayerKey != null) return defaultSchedules[item.prayerKey!]!;
    if (item.timeMinutes != null) return const ScheduleSpec('fixed', 'midnight');
    return const ScheduleSpec('day', 'midnight');
  }

  static DateTime _prayer(DayPrayerTimes t, String key) {
    final p = PrayerName.values.firstWhere((e) => e.name == key);
    return t[p].toLocal();
  }

  static DateTime _dayStart(DateTime date) => DateTime(date.year, date.month, date.day);
  static DateTime _midnight(DateTime date) => DateTime(date.year, date.month, date.day + 1);

  /// Window of [item] on [date]. [today] are the prayer times of [date] and
  /// [tomorrow] those of the following day (for windows ending at next Fajr).
  static ActivityWindow window(RoutineItem item, DateTime date, DayPrayerTimes today, DayPrayerTimes tomorrow) {
    final spec = specOf(item);
    DateTime start;
    switch (spec.anchor) {
      case 'fixed':
        start = _dayStart(date).add(Duration(minutes: item.timeMinutes ?? 0));
      case 'day':
        start = _dayStart(date);
      default:
        start = _prayer(today, spec.anchor);
    }
    start = start.add(Duration(minutes: spec.startOffset));

    DateTime end;
    switch (spec.endAnchor) {
      case 'none':
        return ActivityWindow(start, _midnight(date).isAfter(start) ? _midnight(date) : start.add(const Duration(hours: 1)),
            expires: false);
      case 'clock':
        end = _dayStart(date).add(Duration(minutes: spec.endOffset));
        if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
        return ActivityWindow(start, end);
      case 'midnight':
        end = _midnight(date);
      case 'next_fajr':
        end = _prayer(tomorrow, 'fajr');
      default:
        end = _prayer(today, spec.endAnchor);
    }
    end = end.add(Duration(minutes: spec.endOffset));

    // A fixed-time activity set *after* its end anchor (e.g. "Wake up 6:00"
    // with Fajr at 5:30) stays open until midnight instead of being instantly
    // missed.
    if (!end.isAfter(start)) end = _midnight(date);
    return ActivityWindow(start, end);
  }

  /// State of an activity given its window and completion data.
  static ActivityState stateOf({
    required ActivityWindow window,
    required DateTime now,
    required bool done,
    required bool skipped,
    bool hasProgress = false,
  }) {
    if (done) return ActivityState.completed;
    if (skipped) return ActivityState.skipped;
    if (now.isBefore(window.start)) return ActivityState.upcoming;
    if (!now.isBefore(window.end) && window.expires) return ActivityState.missed;
    return hasProgress ? ActivityState.inProgress : ActivityState.active;
  }

  /// Phase heading for an activity starting at [start].
  static DayPhase phaseOf(DateTime start, DayPrayerTimes t) {
    final fajr = _prayer(t, 'fajr');
    final sunrise = _prayer(t, 'sunrise');
    final dhuhr = _prayer(t, 'dhuhr');
    final asr = _prayer(t, 'asr');
    final maghrib = _prayer(t, 'maghrib');
    final isha = _prayer(t, 'isha');
    if (start.isBefore(fajr)) return DayPhase.earlyMorning;
    if (start.isBefore(sunrise.add(const Duration(minutes: 15)))) return DayPhase.afterFajr;
    if (start.isBefore(dhuhr)) return DayPhase.morning;
    if (start.isBefore(asr)) return DayPhase.afternoon;
    if (start.isBefore(maghrib)) return DayPhase.afterAsr;
    if (start.isBefore(isha)) return DayPhase.afterMaghrib;
    return DayPhase.afterIsha;
  }
}


// ---------------------------------------------------------------------------
// Azkar scheduling
// ---------------------------------------------------------------------------

/// How an Azkar activity is scheduled. Only the timing is stored (on the
/// routine item); the Azkar content itself is untouched.
enum AzkarMode { afterPrayer, fixed, window }

const azkarPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

class AzkarSchedule {
  final AzkarMode mode;
  final String prayer; // afterPrayer
  final int offset; // afterPrayer: minutes after the prayer (reminder offset)
  final int start; // fixed / window: minutes after midnight
  final int end; // window: minutes after midnight (before start = next day)
  const AzkarSchedule.afterPrayer(this.prayer, {this.offset = 0})
      : mode = AzkarMode.afterPrayer,
        start = 0,
        end = 0;
  const AzkarSchedule.fixed(this.start)
      : mode = AzkarMode.fixed,
        prayer = 'fajr',
        offset = 0,
        end = 0;
  const AzkarSchedule.window(this.start, this.end)
      : mode = AzkarMode.window,
        prayer = 'fajr',
        offset = 0;

  /// The user's Azkar schedule stored on [item], or null when the item uses
  /// the built-in default schedule.
  static AzkarSchedule? of(RoutineItem item) {
    final a = item.anchor;
    if (a == null) return null;
    if (item.endAnchor == 'none' && azkarPrayers.contains(a)) return AzkarSchedule.afterPrayer(a, offset: item.startOffset);
    if (a == 'fixed' && item.endAnchor == 'none' && item.timeMinutes != null) return AzkarSchedule.fixed(item.timeMinutes!);
    if (a == 'fixed' && item.endAnchor == 'clock' && item.timeMinutes != null) {
      return AzkarSchedule.window(item.timeMinutes!, item.endOffset);
    }
    return null;
  }

  /// [item] with this schedule applied (id and all other data unchanged).
  RoutineItem applyTo(RoutineItem item) => switch (mode) {
        AzkarMode.afterPrayer =>
          item.copyWith(anchor: prayer, startOffset: offset, endAnchor: 'none', endOffset: 0),
        AzkarMode.fixed =>
          item.copyWith(anchor: 'fixed', timeMinutes: start, startOffset: 0, endAnchor: 'none', endOffset: 0),
        AzkarMode.window =>
          item.copyWith(anchor: 'fixed', timeMinutes: start, startOffset: 0, endAnchor: 'clock', endOffset: end),
      };

  @override
  bool operator ==(Object other) =>
      other is AzkarSchedule &&
      other.mode == mode &&
      other.prayer == prayer &&
      other.offset == offset &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(mode, prayer, offset, start, end);
}

/// Activities that get the dedicated Azkar scheduler.
bool isAzkarItem(RoutineItem item) =>
    item.prayerKey == null &&
    (item.category == RoutineCategory.azkar || item.category == RoutineCategory.dhikr || item.id.endsWith('_azkar'));
