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
    final g = DateTime(date.year, date.month, date.day + adjustDays);
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

  /// Gregorian date of this Hijri date (inverse of [fromGregorian]).
  DateTime toGregorian({int adjustDays = 0}) {
    final jd = (11 * year + 3) ~/ 30 + 354 * year + 30 * month - (month - 1) ~/ 2 + day + 1948440 - 385;
    var l = jd + 68569;
    final n = (4 * l) ~/ 146097;
    l = l - (146097 * n + 3) ~/ 4;
    final i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    final j = (80 * l) ~/ 2447;
    final d = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    final m = j + 2 - 12 * l;
    final y = 100 * (n - 49) + i + l;
    return DateTime(y, m, d - adjustDays);
  }

  /// Number of days in this Hijri month (29 or 30, tabular calendar).
  int get monthLength {
    final first = HijriDate(year, month, 1).toGregorian();
    final next = (month == 12 ? HijriDate(year + 1, 1, 1) : HijriDate(year, month + 1, 1)).toGregorian();
    return DateTime.utc(next.year, next.month, next.day).difference(DateTime.utc(first.year, first.month, first.day)).inDays;
  }

  String monthName(bool urdu) => urdu ? monthsUr[month - 1] : monthsEn[month - 1];

  String format(bool urdu) {
    final name = monthName(urdu);
    return urdu ? '$day $name $year ھ' : '$day $name $year AH';
  }

  @override
  bool operator ==(Object other) => other is HijriDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// Well-known dates of the Islamic year (month, day, English, Urdu).
const List<(int, int, String, String)> islamicEvents = [
  (1, 1, 'Islamic New Year', 'اسلامی نیا سال'),
  (1, 10, 'Day of Ashura', 'یومِ عاشورہ'),
  (9, 1, 'First day of Ramadan', 'رمضان کا آغاز'),
  (9, 21, 'Last ten nights of Ramadan begin', 'رمضان کے آخری عشرے کا آغاز'),
  (10, 1, 'Eid al-Fitr', 'عید الفطر'),
  (12, 1, 'First ten days of Dhul Hijjah', 'ذوالحجہ کے پہلے دس دن'),
  (12, 8, 'Hajj begins (Day of Tarwiyah)', 'حج کا آغاز (یومِ ترویہ)'),
  (12, 9, 'Day of Arafah', 'یومِ عرفہ'),
  (12, 10, 'Eid al-Adha', 'عید الاضحیٰ'),
];
