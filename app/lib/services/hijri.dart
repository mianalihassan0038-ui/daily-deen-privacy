/// Simple arithmetic (tabular / Kuwaiti) Hijri calendar conversion.
/// May differ by +/- 1 day from local moon sighting, so the app has an
/// adjustment setting.
class HijriDate {
  final int year;
  final int month;
  final int day;
  const HijriDate(this.year, this.month, this.day);

  static const monthsEn = [
    'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani", 'Jumada al-Ula', 'Jumada al-Akhirah',
    'Rajab', "Sha'ban", 'Ramadan', 'Shawwal', "Dhu al-Qa'dah", 'Dhu al-Hijjah',
  ];
  static const monthsUr = [
    'محرم', 'صفر', 'ربیع الاول', 'ربیع الثانی', 'جمادی الاولیٰ', 'جمادی الثانی',
    'رجب', 'شعبان', 'رمضان', 'شوال', 'ذوالقعدہ', 'ذوالحجہ',
  ];

  static HijriDate fromGregorian(DateTime date, {int adjustDays = 0}) {
    final g = DateTime(date.year, date.month, date.day).add(Duration(days: adjustDays));
    final a = (14 - g.month) ~/ 12;
    final yy = g.year + 4800 - a;
    final mm = g.month + 12 * a - 3;
    final jd = g.day + (153 * mm + 2) ~/ 5 + 365 * yy + yy ~/ 4 - yy ~/ 100 + yy ~/ 400 - 32045;
    var l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) + (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) - (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
    final m = (24 * l) ~/ 709;
    final d = l - (709 * m) ~/ 24;
    final y = 30 * n + j - 30;
    return HijriDate(y, m, d);
  }

  String format(bool urdu) {
    final name = urdu ? monthsUr[month - 1] : monthsEn[month - 1];
    return urdu ? '$day $name $year ھ' : '$day $name $year AH';
  }
}
