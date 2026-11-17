import '../app_state.dart';
import '../data/routine.dart';
import 'schedule.dart';

/// Daily routine score
/// ===================
/// Three separate metrics are kept:
///  * Farz     – the five obligatory prayers whose time has started.
///  * Routine  – enabled, non-optional activities (excluding prayers) whose
///               window has started.
///  * Optional – optional activities (Tahajjud, Ishraq, Chasht, ...) whose
///               window has started. Shown separately; never lowers the others.
///
/// Rules: future/locked activities are excluded from the denominator (for
/// today); skipped, disabled and non-applicable activities are excluded;
/// "in progress" earns nothing until its target is reached; a past day uses
/// that day's whole schedule.
///
/// Overall = average of the Farz and Routine percentages (each weighted 50%).
/// If one of them has nothing due yet, the other one is used alone.
/// This is a personal routine-progress metric, not a measure of faith.
class DayScore {
  final int farzDone, farzDue, farzOnTime, farzJamaat, farzQaza, farzMissed;
  final int routineDone, routineDue, routineMissed;
  final int optionalDone, optionalDue;
  final int skipped, active, upcoming;

  const DayScore({
    this.farzDone = 0,
    this.farzDue = 0,
    this.farzOnTime = 0,
    this.farzJamaat = 0,
    this.farzQaza = 0,
    this.farzMissed = 0,
    this.routineDone = 0,
    this.routineDue = 0,
    this.routineMissed = 0,
    this.optionalDone = 0,
    this.optionalDue = 0,
    this.skipped = 0,
    this.active = 0,
    this.upcoming = 0,
  });

  double get farz => farzDue == 0 ? 0 : farzDone / farzDue;
  double get routine => routineDue == 0 ? 0 : routineDone / routineDue;
  double get optional => optionalDue == 0 ? 0 : optionalDone / optionalDue;

  double get overall {
    if (farzDue == 0 && routineDue == 0) return 0;
    if (farzDue == 0) return routine;
    if (routineDue == 0) return farz;
    return (farz + routine) / 2;
  }

  /// Completed / due for farz + routine together (used for simple "x of y").
  int get done => farzDone + routineDone;
  int get due => farzDue + routineDue;
  int get missed => farzMissed + routineMissed;
}

class ScoringService {
  static DayScore score(AppState state, DateTime date, {DateTime? now}) {
    final t = now ?? clock();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(t.year, t.month, t.day);
    if (day.isAfter(today)) return const DayScore();
    final rec = state.day(day);

    var farzDone = 0, farzDue = 0, onTime = 0, jamaat = 0, qaza = 0, farzMissed = 0;
    for (final k in prayerKeys) {
      final item = state.itemById(k) ?? defaultRoutine.firstWhere((e) => e.id == k);
      final w = state.windowOf(item, day);
      final st = rec.prayer(k);
      final started = !t.isBefore(w.start);
      if (!started) continue;
      farzDue++;
      switch (st) {
        case PrayerStatus.alone:
          farzDone++;
          onTime++;
        case PrayerStatus.jamaat:
          farzDone++;
          onTime++;
          jamaat++;
        case PrayerStatus.qaza:
          farzDone++;
          qaza++;
        case PrayerStatus.missed:
          farzMissed++;
        case PrayerStatus.none:
          if (!t.isBefore(w.end)) farzMissed++;
      }
    }

    var rDone = 0, rDue = 0, rMissed = 0, oDone = 0, oDue = 0, skipped = 0, active = 0, upcoming = 0;
    for (final item in state.routineFor(day)) {
      if (item.prayerKey != null) continue;
      final s = state.activityState(item, day, now: t);
      if (s == ActivityState.skipped) {
        skipped++;
        continue;
      }
      if (s == ActivityState.upcoming) {
        upcoming++;
        continue;
      }
      final done = s == ActivityState.completed;
      if (s == ActivityState.active || s == ActivityState.inProgress) active++;
      if (item.optional) {
        oDue++;
        if (done) oDone++;
      } else {
        rDue++;
        if (done) rDone++;
        if (s == ActivityState.missed) rMissed++;
      }
    }

    return DayScore(
      farzDone: farzDone,
      farzDue: farzDue,
      farzOnTime: onTime,
      farzJamaat: jamaat,
      farzQaza: qaza,
      farzMissed: farzMissed,
      routineDone: rDone,
      routineDue: rDue,
      routineMissed: rMissed,
      optionalDone: oDone,
      optionalDue: oDue,
      skipped: skipped,
      active: active,
      upcoming: upcoming,
    );
  }
}
