import 'dart:math' as math;

/// The five daily prayers plus sunrise (used for display / Ishraq timing).
enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

enum CalcMethod { karachi, mwl, isna, egypt, ummAlQura }

class MethodParams {
  final double fajrAngle;
  final double ishaAngle;

  /// If > 0, Isha is this many minutes after Maghrib instead of an angle.
  final int ishaMinutes;
  const MethodParams(this.fajrAngle, this.ishaAngle, [this.ishaMinutes = 0]);
}

const Map<CalcMethod, MethodParams> methodParams = {
  CalcMethod.karachi: MethodParams(18, 18),
  CalcMethod.mwl: MethodParams(18, 17),
  CalcMethod.isna: MethodParams(15, 15),
  CalcMethod.egypt: MethodParams(19.5, 17.5),
  CalcMethod.ummAlQura: MethodParams(18.5, 0, 90),
};

/// Prayer times for one day. All values are absolute instants (UTC based),
/// call `.toLocal()` to show them in the device time zone.
class DayPrayerTimes {
  final Map<PrayerName, DateTime> times;
  const DayPrayerTimes(this.times);

  DateTime operator [](PrayerName p) => times[p]!;
}

/// Astronomical prayer time calculator (based on the well known
/// PrayTimes.org algorithm). Works fully offline.
class PrayerCalculator {
  final double lat;
  final double lng;
  final CalcMethod method;

  /// true = Hanafi Asr (shadow factor 2), false = Shafi'i/standard (factor 1)
  final bool hanafiAsr;

  PrayerCalculator({
    required this.lat,
    required this.lng,
    this.method = CalcMethod.karachi,
    this.hanafiAsr = true,
  });

  static double _d2r(double d) => d * math.pi / 180.0;
  static double _r2d(double r) => r * 180.0 / math.pi;

  static double _fix(double a, double b) {
    a = a - b * (a / b).floorToDouble();
    return a < 0 ? a + b : a;
  }

  static double julian(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floorToDouble() +
        (30.6001 * (month + 1)).floorToDouble() +
        day +
        b -
        1524.5;
  }

  /// Returns [declination, equationOfTime].
  static List<double> _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = _fix(357.529 + 0.98560028 * d, 360);
    final q = _fix(280.459 + 0.98564736 * d, 360);
    final l = _fix(q + 1.915 * math.sin(_d2r(g)) + 0.020 * math.sin(_d2r(2 * g)), 360);
    final e = 23.439 - 0.00000036 * d;
    var ra = _r2d(math.atan2(math.cos(_d2r(e)) * math.sin(_d2r(l)), math.cos(_d2r(l)))) / 15;
    ra = _fix(ra, 24);
    final eqt = q / 15 - ra;
    final decl = _r2d(math.asin(math.sin(_d2r(e)) * math.sin(_d2r(l))));
    return [decl, eqt];
  }

  DayPrayerTimes forDate(DateTime date) {
    final y = date.year, m = date.month, d = date.day;
    final jd = julian(y, m, d) - lng / (15 * 24);
    final params = methodParams[method]!;

    double midDay(double t) {
      final eqt = _sunPosition(jd + t)[1];
      return _fix(12 - eqt, 24);
    }

    double sunAngleTime(double angle, double t, {bool ccw = false}) {
      final decl = _sunPosition(jd + t)[0];
      final noon = midDay(t);
      final c = (-math.sin(_d2r(angle)) - math.sin(_d2r(decl)) * math.sin(_d2r(lat))) /
          (math.cos(_d2r(decl)) * math.cos(_d2r(lat)));
      if (c > 1 || c < -1) return double.nan;
      final p = _r2d(math.acos(c)) / 15;
      return ccw ? noon - p : noon + p;
    }

    double asrTime(double factor, double t) {
      final decl = _sunPosition(jd + t)[0];
      final angle = -_r2d(math.atan(1 / (factor + math.tan(_d2r((lat - decl).abs())))));
      return sunAngleTime(angle, t);
    }

    var fajr = 5.0, sunrise = 6.0, dhuhr = 12.0, asr = 13.0, maghrib = 18.0, isha = 18.0;
    for (var i = 0; i < 2; i++) {
      final nf = sunAngleTime(params.fajrAngle, fajr / 24, ccw: true);
      final ns = sunAngleTime(0.833, sunrise / 24, ccw: true);
      final nd = midDay(dhuhr / 24);
      final na = asrTime(hanafiAsr ? 2 : 1, asr / 24);
      final nm = sunAngleTime(0.833, maghrib / 24);
      final ni = params.ishaMinutes > 0 ? double.nan : sunAngleTime(params.ishaAngle, isha / 24);
      fajr = nf.isNaN ? fajr : nf;
      sunrise = ns.isNaN ? sunrise : ns;
      dhuhr = nd;
      asr = na.isNaN ? asr : na;
      maghrib = nm.isNaN ? maghrib : nm;
      isha = ni.isNaN ? isha : ni;
    }

    // High latitude adjustment (angle based) - keeps Fajr/Isha sensible in
    // places like Canada / UK during summer.
    final night = _fix(sunrise - maghrib, 24);
    final fajrPortion = params.fajrAngle / 60 * night;
    if (_fix(sunrise - fajr, 24) > fajrPortion) fajr = sunrise - fajrPortion;
    if (params.ishaMinutes > 0) {
      isha = maghrib + params.ishaMinutes / 60;
    } else {
      final ishaPortion = params.ishaAngle / 60 * night;
      if (_fix(isha - maghrib, 24) > ishaPortion) isha = maghrib + ishaPortion;
    }

    dhuhr += 1 / 60; // 1 minute safety after zawal

    final base = DateTime.utc(y, m, d);
    DateTime toInstant(double hours) {
      final utcHours = hours - lng / 15;
      return base.add(Duration(seconds: (utcHours * 3600).round()));
    }

    return DayPrayerTimes({
      PrayerName.fajr: toInstant(fajr),
      PrayerName.sunrise: toInstant(sunrise),
      PrayerName.dhuhr: toInstant(dhuhr),
      PrayerName.asr: toInstant(asr),
      PrayerName.maghrib: toInstant(maghrib),
      PrayerName.isha: toInstant(isha),
    });
  }

  /// Next upcoming prayer (sunrise excluded) after [now].
  MapEntry<PrayerName, DateTime> nextPrayer(DateTime now) {
    for (var offset = 0; offset < 2; offset++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
      final t = forDate(day);
      for (final p in [PrayerName.fajr, PrayerName.dhuhr, PrayerName.asr, PrayerName.maghrib, PrayerName.isha]) {
        if (t[p].isAfter(now.toUtc())) return MapEntry(p, t[p]);
      }
    }
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return MapEntry(PrayerName.fajr, forDate(tomorrow)[PrayerName.fajr]);
  }
}
