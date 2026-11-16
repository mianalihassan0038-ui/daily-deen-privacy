enum RoutineSection { earlyMorning, day, night }

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

  const RoutineItem({
    required this.id,
    required this.en,
    required this.ur,
    required this.section,
    this.targetEn = '',
    this.targetUr = '',
    this.timeEn = '',
    this.timeUr = '',
    this.prayerKey,
    this.dhikrKey,
    this.dhikrTarget = 0,
    this.fridayOnly = false,
    this.optional = false,
    this.custom = false,
  });

  String name(bool urdu) => urdu ? ur : en;
  String target(bool urdu) => urdu ? targetUr : targetEn;
  String time(bool urdu) => urdu ? timeUr : timeEn;

  Map<String, dynamic> toJson() => {'id': id, 'en': en, 'ur': ur, 'section': section.index, 'target': targetEn};

  static RoutineItem customFromJson(Map<String, dynamic> j) => RoutineItem(
        id: j['id'] as String,
        en: j['en'] as String,
        ur: (j['ur'] as String?) ?? (j['en'] as String),
        section: RoutineSection.values[(j['section'] as int?) ?? 1],
        targetEn: (j['target'] as String?) ?? '',
        targetUr: (j['target'] as String?) ?? '',
        custom: true,
      );
}

const prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

const List<RoutineItem> defaultRoutine = [
  // ---------- Early morning ----------
  RoutineItem(id: 'wake', en: 'Wake up', ur: 'جاگنا', section: RoutineSection.earlyMorning,
      timeEn: '4:00 AM', timeUr: 'صبح 4:00', targetEn: 'Wake up early', targetUr: 'جلدی اٹھنا'),
  RoutineItem(id: 'wudu', en: 'Wudu', ur: 'وضو', section: RoutineSection.earlyMorning,
      timeEn: '4:05 AM', timeUr: 'صبح 4:05', targetEn: 'Complete', targetUr: 'مکمل'),
  RoutineItem(id: 'tahajjud', en: 'Tahajjud', ur: 'تہجد', section: RoutineSection.earlyMorning,
      timeEn: '4:10 AM', timeUr: 'صبح 4:10', targetEn: '2–8 Rakat', targetUr: '2 تا 8 رکعت', optional: true),
  RoutineItem(id: 'dua_istighfar', en: 'Dua & Istighfar', ur: 'دعا اور استغفار', section: RoutineSection.earlyMorning,
      timeEn: '4:30 AM', timeUr: 'صبح 4:30', targetEn: '5 minutes', targetUr: '5 منٹ'),
  RoutineItem(id: 'tilawat_fajr', en: 'Quran Tilawat', ur: 'تلاوتِ قرآن', section: RoutineSection.earlyMorning,
      timeEn: '4:40 AM', timeUr: 'صبح 4:40', targetEn: '1–2 pages', targetUr: '1 تا 2 صفحات'),
  RoutineItem(id: 'fajr', en: 'Fajr Namaz', ur: 'نمازِ فجر', section: RoutineSection.earlyMorning,
      timeEn: 'Fajr time', timeUr: 'فجر کا وقت', targetEn: '2 Sunnah + 2 Farz', targetUr: '2 سنت + 2 فرض', prayerKey: 'fajr'),
  RoutineItem(id: 'morning_azkar', en: 'Morning Azkar', ur: 'صبح کے اذکار', section: RoutineSection.earlyMorning,
      timeEn: 'After Fajr', timeUr: 'فجر کے بعد', targetEn: 'Complete', targetUr: 'مکمل'),
  RoutineItem(id: 'kursi_morning', en: 'Ayat-ul-Kursi', ur: 'آیت الکرسی', section: RoutineSection.earlyMorning,
      timeEn: 'After Fajr', timeUr: 'فجر کے بعد', targetEn: '1 time', targetUr: '1 مرتبہ'),
  RoutineItem(id: 'tasbeeh_100', en: 'Tasbeeh (SubhanAllah)', ur: 'تسبیح (سبحان اللہ)', section: RoutineSection.earlyMorning,
      timeEn: 'After Fajr', timeUr: 'فجر کے بعد', targetEn: '100 times', targetUr: '100 مرتبہ',
      dhikrKey: 'subhanallah', dhikrTarget: 100),
  RoutineItem(id: 'yaseen', en: 'Surah Yaseen', ur: 'سورۃ یٰسین', section: RoutineSection.earlyMorning,
      timeEn: 'Morning', timeUr: 'صبح', targetEn: 'Optional target', targetUr: 'اختیاری ہدف', optional: true),

  // ---------- Day ----------
  RoutineItem(id: 'ishraq', en: 'Ishraq Namaz', ur: 'نمازِ اشراق', section: RoutineSection.day,
      timeEn: 'After sunrise', timeUr: 'طلوعِ آفتاب کے بعد', targetEn: 'Optional', targetUr: 'اختیاری', optional: true),
  RoutineItem(id: 'chasht', en: 'Chasht Namaz', ur: 'نمازِ چاشت', section: RoutineSection.day,
      timeEn: 'Forenoon', timeUr: 'چاشت', targetEn: 'Optional', targetUr: 'اختیاری', optional: true),
  RoutineItem(id: 'dhuhr', en: 'Dhuhr Namaz', ur: 'نمازِ ظہر', section: RoutineSection.day,
      timeEn: 'Dhuhr time', timeUr: 'ظہر کا وقت', targetEn: '4 Sunnah + 4 Farz + 2 Sunnah', targetUr: '4 سنت + 4 فرض + 2 سنت', prayerKey: 'dhuhr'),
  RoutineItem(id: 'quran_daily', en: 'Daily Quran', ur: 'روزانہ قرآن', section: RoutineSection.day,
      timeEn: 'Daytime', timeUr: 'دن میں', targetEn: '2–4 pages', targetUr: '2 تا 4 صفحات'),
  RoutineItem(id: 'durood_100', en: 'Durood Shareef', ur: 'درود شریف', section: RoutineSection.day,
      timeEn: 'Anytime', timeUr: 'کسی بھی وقت', targetEn: '100 times', targetUr: '100 مرتبہ',
      dhikrKey: 'durood', dhikrTarget: 100),
  RoutineItem(id: 'astaghfar_100', en: 'Astaghfar', ur: 'استغفار', section: RoutineSection.day,
      timeEn: 'Anytime', timeUr: 'کسی بھی وقت', targetEn: '100 times', targetUr: '100 مرتبہ',
      dhikrKey: 'astaghfirullah', dhikrTarget: 100),
  RoutineItem(id: 'asr', en: 'Asr Namaz', ur: 'نمازِ عصر', section: RoutineSection.day,
      timeEn: 'Asr time', timeUr: 'عصر کا وقت', targetEn: '4 Sunnah (optional) + 4 Farz', targetUr: '4 سنت (اختیاری) + 4 فرض', prayerKey: 'asr'),
  RoutineItem(id: 'evening_azkar', en: 'Evening Azkar', ur: 'شام کے اذکار', section: RoutineSection.day,
      timeEn: 'After Asr', timeUr: 'عصر کے بعد', targetEn: 'Complete', targetUr: 'مکمل'),
  RoutineItem(id: 'kahf', en: 'Surah Al-Kahf', ur: 'سورۃ الکہف', section: RoutineSection.day,
      timeEn: 'Friday', timeUr: 'جمعہ', targetEn: 'Friday target', targetUr: 'جمعہ کا ہدف', fridayOnly: true),

  // ---------- Evening & night ----------
  RoutineItem(id: 'maghrib', en: 'Maghrib Namaz', ur: 'نمازِ مغرب', section: RoutineSection.night,
      timeEn: 'Maghrib time', timeUr: 'مغرب کا وقت', targetEn: '3 Farz + 2 Sunnah', targetUr: '3 فرض + 2 سنت', prayerKey: 'maghrib'),
  RoutineItem(id: 'tilawat_night', en: 'Quran Tilawat', ur: 'تلاوتِ قرآن', section: RoutineSection.night,
      timeEn: 'Evening', timeUr: 'شام', targetEn: 'Daily target', targetUr: 'روزانہ ہدف'),
  RoutineItem(id: 'isha', en: 'Isha Namaz', ur: 'نمازِ عشاء', section: RoutineSection.night,
      timeEn: 'Isha time', timeUr: 'عشاء کا وقت', targetEn: '4 Farz + 2 Sunnah', targetUr: '4 فرض + 2 سنت', prayerKey: 'isha'),
  RoutineItem(id: 'witr', en: 'Witr', ur: 'وتر', section: RoutineSection.night,
      timeEn: 'After Isha', timeUr: 'عشاء کے بعد', targetEn: '3 Rakat', targetUr: '3 رکعت'),
  RoutineItem(id: 'kursi_night', en: 'Ayat-ul-Kursi', ur: 'آیت الکرسی', section: RoutineSection.night,
      timeEn: 'Before sleep', timeUr: 'سونے سے پہلے', targetEn: '1 time', targetUr: '1 مرتبہ'),
  RoutineItem(id: 'baqarah_last2', en: 'Last 2 Ayat of Surah Baqarah', ur: 'سورۃ البقرہ کی آخری 2 آیات', section: RoutineSection.night,
      timeEn: 'Night', timeUr: 'رات', targetEn: '1 time', targetUr: '1 مرتبہ'),
  RoutineItem(id: 'mulk', en: 'Surah Al-Mulk', ur: 'سورۃ الملک', section: RoutineSection.night,
      timeEn: 'Before sleep', timeUr: 'سونے سے پہلے', targetEn: '1 time', targetUr: '1 مرتبہ'),
  RoutineItem(id: 'sleep_azkar', en: 'Before-sleep Azkar', ur: 'سونے سے پہلے کے اذکار', section: RoutineSection.night,
      timeEn: 'Before sleep', timeUr: 'سونے سے پہلے', targetEn: 'Complete', targetUr: 'مکمل'),
  RoutineItem(id: 'muhasaba', en: 'Daily Muhasaba', ur: 'روزانہ محاسبہ', section: RoutineSection.night,
      timeEn: 'Before sleep', timeUr: 'سونے سے پہلے', targetEn: 'Review your day', targetUr: 'اپنے دن کا جائزہ'),
];
