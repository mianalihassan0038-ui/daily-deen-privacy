enum RoutineSection { earlyMorning, day, night }

/// Category used for icons/colours and the "Select activity category" option.
enum RoutineCategory { prayer, nafl, quran, azkar, dhikr, dua, health, study, family, work, other }

/// One item of the daily Islamic routine (mamoolat).
class RoutineItem {
  final String id;
  final String en;
  final String ur;
  final String targetEn;
  final String targetUr;
  final RoutineSection section;

  /// Suggested time label, e.g. "4:00 AM" or "After Fajr".
  final String timeEn;
  final String timeUr;

  /// Exact time in minutes after midnight (null = use the label / prayer time).
  final int? timeMinutes;

  /// If set, this item is one of the five farz prayers (fajr, dhuhr, ...).
  final String? prayerKey;

  /// If set, completing this many counts of [dhikrKey] in the Tasbeeh
  /// screen automatically ticks this item.
  final String? dhikrKey;
  final int dhikrTarget;

  /// Only shown on Fridays (e.g. Surah Al-Kahf).
  final bool fridayOnly;
  final bool optional;
  final bool custom;

  /// Weekdays (1 = Monday ... 7 = Sunday) on which the item repeats.
  /// Empty = every day.
  final Set<int> days;
  final bool reminder;
  final bool enabled;
  final RoutineCategory category;

  const RoutineItem({
    required this.id,
    required this.en,
    required this.ur,
    required this.section,
    this.targetEn = '',
    this.targetUr = '',
    this.timeEn = '',
    this.timeUr = '',
    this.timeMinutes,
    this.prayerKey,
    this.dhikrKey,
    this.dhikrTarget = 0,
    this.fridayOnly = false,
    this.optional = false,
    this.custom = false,
    this.days = const {},
    this.reminder = false,
    this.enabled = true,
    this.category = RoutineCategory.other,
  });

  String name(bool urdu) => urdu ? ur : en;
  String target(bool urdu) => urdu ? targetUr : targetEn;

  /// Time label: exact time if set, otherwise the descriptive label.
  String time(bool urdu) {
    if (timeMinutes != null) return formatMinutes(timeMinutes!, urdu: urdu);
    return urdu ? timeUr : timeEn;
  }

  /// Does this item apply on [date]?
  bool appliesOn(DateTime date) {
    if (!enabled) return false;
    if (fridayOnly && days.isEmpty) return date.weekday == DateTime.friday;
    return days.isEmpty || days.contains(date.weekday);
  }

  RoutineItem copyWith({
    String? en,
    String? ur,
    String? targetEn,
    String? targetUr,
    RoutineSection? section,
    int? timeMinutes,
    bool clearTime = false,
    Set<int>? days,
    bool? reminder,
    bool? enabled,
    RoutineCategory? category,
    bool? optional,
  }) {
    return RoutineItem(
      id: id,
      en: en ?? this.en,
      ur: ur ?? this.ur,
      section: section ?? this.section,
      targetEn: targetEn ?? this.targetEn,
      targetUr: targetUr ?? this.targetUr,
      timeEn: timeEn,
      timeUr: timeUr,
      timeMinutes: clearTime ? null : (timeMinutes ?? this.timeMinutes),
      prayerKey: prayerKey,
      dhikrKey: dhikrKey,
      dhikrTarget: dhikrTarget,
      fridayOnly: fridayOnly,
      optional: optional ?? this.optional,
      custom: custom,
      days: days ?? this.days,
      reminder: reminder ?? this.reminder,
      enabled: enabled ?? this.enabled,
      category: category ?? this.category,
    );
  }

  /// Full serialisation (routine v2).
  Map<String, dynamic> toJson() => {
        'id': id,
        'en': en,
        'ur': ur,
        'section': section.index,
        'target': targetEn,
        'targetUr': targetUr,
        'timeEn': timeEn,
        'timeUr': timeUr,
        if (timeMinutes != null) 'time': timeMinutes,
        if (prayerKey != null) 'prayer': prayerKey,
        if (dhikrKey != null) 'dhikr': dhikrKey,
        'dhikrTarget': dhikrTarget,
        'friday': fridayOnly,
        'optional': optional,
        'custom': custom,
        'days': days.toList(),
        'reminder': reminder,
        'enabled': enabled,
        'cat': category.index,
      };

  static RoutineItem fromJson(Map<String, dynamic> j) {
    int idx(String k, int len, int def) {
      final v = (j[k] as num?)?.toInt() ?? def;
      return (v >= 0 && v < len) ? v : def;
    }

    final en = (j['en'] as String?) ?? '';
    final target = (j['target'] as String?) ?? '';
    return RoutineItem(
      id: j['id'] as String,
      en: en,
      ur: (j['ur'] as String?) ?? en,
      section: RoutineSection.values[idx('section', RoutineSection.values.length, 1)],
      targetEn: target,
      targetUr: (j['targetUr'] as String?) ?? target,
      timeEn: (j['timeEn'] as String?) ?? '',
      timeUr: (j['timeUr'] as String?) ?? '',
      timeMinutes: (j['time'] as num?)?.toInt(),
      prayerKey: j['prayer'] as String?,
      dhikrKey: j['dhikr'] as String?,
      dhikrTarget: (j['dhikrTarget'] as num?)?.toInt() ?? 0,
      fridayOnly: j['friday'] as bool? ?? false,
      optional: j['optional'] as bool? ?? false,
      custom: j['custom'] as bool? ?? true,
      days: ((j['days'] as List?) ?? []).map((e) => (e as num).toInt()).where((d) => d >= 1 && d <= 7).toSet(),
      reminder: j['reminder'] as bool? ?? false,
      enabled: j['enabled'] as bool? ?? true,
      category: RoutineCategory.values[idx('cat', RoutineCategory.values.length, RoutineCategory.other.index)],
    );
  }

  /// Legacy (v1) custom item format.
  static RoutineItem customFromJson(Map<String, dynamic> j) => RoutineItem(
        id: j['id'] as String,
        en: j['en'] as String,
        ur: (j['ur'] as String?) ?? (j['en'] as String),
        section: RoutineSection.values[((j['section'] as int?) ?? 1).clamp(0, 2)],
        targetEn: (j['target'] as String?) ?? '',
        targetUr: (j['target'] as String?) ?? '',
        custom: true,
      );
}

String formatMinutes(int minutes, {bool urdu = false}) {
  final h24 = (minutes ~/ 60) % 24;
  final m = (minutes % 60).toString().padLeft(2, '0');
  var h = h24 % 12;
  if (h == 0) h = 12;
  final ampm = h24 < 12 ? (urdu ? 'صبح' : 'AM') : (urdu ? 'شام' : 'PM');
  return '$h:$m $ampm';
}

const prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

const List<RoutineItem> defaultRoutine = [
  // ---------- Early morning ----------
  RoutineItem(id: 'wake', en: 'Wake up', ur: 'جاگنا', section: RoutineSection.earlyMorning,
      timeEn: '4:00 AM', timeUr: 'صبح 4:00', timeMinutes: 240, targetEn: 'Wake up early', targetUr: 'جلدی اٹھنا',
      category: RoutineCategory.health),
  RoutineItem(id: 'wudu', en: 'Wudu', ur: 'وضو', section: RoutineSection.earlyMorning,
      timeEn: '4:05 AM', timeUr: 'صبح 4:05', timeMinutes: 245, targetEn: 'Complete', targetUr: 'مکمل',
      category: RoutineCategory.prayer),
  RoutineItem(id: 'tahajjud', en: 'Tahajjud', ur: 'تہجد', section: RoutineSection.earlyMorning,
      timeEn: '4:15 AM', timeUr: 'صبح 4:15', timeMinutes: 255, targetEn: '2–8 Rakat', targetUr: '2 تا 8 رکعت', optional: true,
      category: RoutineCategory.nafl),
  RoutineItem(id: 'dua_istighfar', en: 'Dua & Istighfar', ur: 'دعا اور استغفار', section: RoutineSection.earlyMorning,
      timeEn: '4:30 AM', timeUr: 'صبح 4:30', timeMinutes: 270, targetEn: '5 minutes', targetUr: '5 منٹ',
      category: RoutineCategory.dua),
  RoutineItem(id: 'tilawat_fajr', en: 'Quran Tilawat', ur: 'تلاوتِ قرآن', section: RoutineSection.earlyMorning,
      timeEn: '5:00 AM', timeUr: 'صبح 5:00', timeMinutes: 300, targetEn: '1–2 pages', targetUr: '1 تا 2 صفحات',
      category: RoutineCategory.quran),
  RoutineItem(id: 'fajr', en: 'Fajr Namaz', ur: 'نمازِ فجر', section: RoutineSection.earlyMorning,
      timeEn: 'Fajr time', timeUr: 'فجر کا وقت', targetEn: '2 Sunnah + 2 Farz', targetUr: '2 سنت + 2 فرض', prayerKey: 'fajr',
      category: RoutineCategory.prayer),
  RoutineItem(id: 'morning_azkar', en: 'Morning Azkar', ur: 'صبح کے اذکار', section: RoutineSection.earlyMorning,
      timeEn: 'After Fajr', timeUr: 'فجر کے بعد', targetEn: 'Complete', targetUr: 'مکمل', category: RoutineCategory.azkar),
  RoutineItem(id: 'kursi_morning', en: 'Ayat-ul-Kursi', ur: 'آیت الکرسی', section: RoutineSection.earlyMorning,
      timeEn: 'After Fajr', timeUr: 'فجر کے بعد', targetEn: '1 time', targetUr: '1 مرتبہ', category: RoutineCategory.quran),
  RoutineItem(id: 'tasbeeh_100', en: 'Tasbeeh (SubhanAllah)', ur: 'تسبیح (سبحان اللہ)', section: RoutineSection.earlyMorning,
      timeEn: 'After Fajr', timeUr: 'فجر کے بعد', targetEn: '100 times', targetUr: '100 مرتبہ',
      dhikrKey: 'subhanallah', dhikrTarget: 100, category: RoutineCategory.dhikr),
  RoutineItem(id: 'yaseen', en: 'Surah Yaseen', ur: 'سورۃ یٰسین', section: RoutineSection.earlyMorning,
      timeEn: 'Morning', timeUr: 'صبح', targetEn: 'Optional target', targetUr: 'اختیاری ہدف', optional: true,
      category: RoutineCategory.quran),

  // ---------- Day ----------
  RoutineItem(id: 'ishraq', en: 'Ishraq Namaz', ur: 'نمازِ اشراق', section: RoutineSection.day,
      timeEn: 'After sunrise', timeUr: 'طلوعِ آفتاب کے بعد', targetEn: 'Optional', targetUr: 'اختیاری', optional: true,
      category: RoutineCategory.nafl),
  RoutineItem(id: 'chasht', en: 'Chasht Namaz', ur: 'نمازِ چاشت', section: RoutineSection.day,
      timeEn: 'Forenoon', timeUr: 'چاشت', targetEn: 'Optional', targetUr: 'اختیاری', optional: true,
      category: RoutineCategory.nafl),
  RoutineItem(id: 'dhuhr', en: 'Dhuhr Namaz', ur: 'نمازِ ظہر', section: RoutineSection.day,
      timeEn: 'Dhuhr time', timeUr: 'ظہر کا وقت', targetEn: '4 Sunnah + 4 Farz + 2 Sunnah', targetUr: '4 سنت + 4 فرض + 2 سنت', prayerKey: 'dhuhr',
      category: RoutineCategory.prayer),
  RoutineItem(id: 'quran_daily', en: 'Daily Quran', ur: 'روزانہ قرآن', section: RoutineSection.day,
      timeEn: 'Daytime', timeUr: 'دن میں', targetEn: 'Daily page target', targetUr: 'روزانہ صفحات کا ہدف',
      category: RoutineCategory.quran),
  RoutineItem(id: 'durood_100', en: 'Durood Shareef', ur: 'درود شریف', section: RoutineSection.day,
      timeEn: 'Anytime', timeUr: 'کسی بھی وقت', targetEn: '100 times', targetUr: '100 مرتبہ',
      dhikrKey: 'durood', dhikrTarget: 100, category: RoutineCategory.dhikr),
  RoutineItem(id: 'astaghfar_100', en: 'Astaghfar', ur: 'استغفار', section: RoutineSection.day,
      timeEn: 'Anytime', timeUr: 'کسی بھی وقت', targetEn: '100 times', targetUr: '100 مرتبہ',
      dhikrKey: 'astaghfirullah', dhikrTarget: 100, category: RoutineCategory.dhikr),
  RoutineItem(id: 'asr', en: 'Asr Namaz', ur: 'نمازِ عصر', section: RoutineSection.day,
      timeEn: 'Asr time', timeUr: 'عصر کا وقت', targetEn: '4 Sunnah (optional) + 4 Farz', targetUr: '4 سنت (اختیاری) + 4 فرض', prayerKey: 'asr',
      category: RoutineCategory.prayer),
  RoutineItem(id: 'evening_azkar', en: 'Evening Azkar', ur: 'شام کے اذکار', section: RoutineSection.day,
      timeEn: 'After Asr', timeUr: 'عصر کے بعد', targetEn: 'Complete', targetUr: 'مکمل', category: RoutineCategory.azkar),
  RoutineItem(id: 'kahf', en: 'Surah Al-Kahf', ur: 'سورۃ الکہف', section: RoutineSection.day,
      timeEn: 'Friday', timeUr: 'جمعہ', targetEn: 'Friday target', targetUr: 'جمعہ کا ہدف', fridayOnly: true, days: {5},
      category: RoutineCategory.quran),

  // ---------- Evening & night ----------
  RoutineItem(id: 'maghrib', en: 'Maghrib Namaz', ur: 'نمازِ مغرب', section: RoutineSection.night,
      timeEn: 'Maghrib time', timeUr: 'مغرب کا وقت', targetEn: '3 Farz + 2 Sunnah', targetUr: '3 فرض + 2 سنت', prayerKey: 'maghrib',
      category: RoutineCategory.prayer),
  RoutineItem(id: 'tilawat_night', en: 'Quran Tilawat', ur: 'تلاوتِ قرآن', section: RoutineSection.night,
      timeEn: 'Evening', timeUr: 'شام', targetEn: 'Daily target', targetUr: 'روزانہ ہدف', category: RoutineCategory.quran),
  RoutineItem(id: 'isha', en: 'Isha Namaz', ur: 'نمازِ عشاء', section: RoutineSection.night,
      timeEn: 'Isha time', timeUr: 'عشاء کا وقت', targetEn: '4 Farz + 2 Sunnah', targetUr: '4 فرض + 2 سنت', prayerKey: 'isha',
      category: RoutineCategory.prayer),
  RoutineItem(id: 'witr', en: 'Witr', ur: 'وتر', section: RoutineSection.night,
      timeEn: 'After Isha', timeUr: 'عشاء کے بعد', targetEn: '3 Rakat', targetUr: '3 رکعت', category: RoutineCategory.prayer),
  RoutineItem(id: 'kursi_night', en: 'Ayat-ul-Kursi', ur: 'آیت الکرسی', section: RoutineSection.night,
      timeEn: 'Before sleep', timeUr: 'سونے سے پہلے', targetEn: '1 time', targetUr: '1 مرتبہ', category: RoutineCategory.quran),
  RoutineItem(id: 'baqarah_last2', en: 'Last 2 Ayat of Surah Baqarah', ur: 'سورۃ البقرہ کی آخری 2 آیات', section: RoutineSection.night,
      timeEn: 'Night', timeUr: 'رات', targetEn: '1 time', targetUr: '1 مرتبہ', category: RoutineCategory.quran),
  RoutineItem(id: 'mulk', en: 'Surah Al-Mulk', ur: 'سورۃ الملک', section: RoutineSection.night,
      timeEn: 'Before sleep', timeUr: 'سونے سے پہلے', targetEn: '1 time', targetUr: '1 مرتبہ', category: RoutineCategory.quran),
  RoutineItem(id: 'sleep_azkar', en: 'Before-sleep Azkar', ur: 'سونے سے پہلے کے اذکار', section: RoutineSection.night,
      timeEn: 'Before sleep', timeUr: 'سونے سے پہلے', targetEn: 'Complete', targetUr: 'مکمل', category: RoutineCategory.azkar),
  RoutineItem(id: 'muhasaba', en: 'Daily Muhasaba', ur: 'روزانہ محاسبہ', section: RoutineSection.night,
      timeEn: 'Before sleep', timeUr: 'سونے سے پہلے', targetEn: 'Review your day', targetUr: 'اپنے دن کا جائزہ',
      category: RoutineCategory.other),
];
