import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/cities.dart';
import 'data/routine.dart';
import 'services/prayer_times.dart';
import 'services/schedule.dart';
import 'services/scoring.dart';
import 'strings.dart';

/// Stored prayer status. Labels in the UI:
/// none = Pending, alone = On time, jamaat = On time with Jamaat,
/// qaza = Delayed (Qaza), missed = Missed.
enum PrayerStatus { none, alone, jamaat, qaza, missed }

bool isPrayed(PrayerStatus s) => s == PrayerStatus.alone || s == PrayerStatus.jamaat || s == PrayerStatus.qaza;

/// Keys of the individually switchable reminders.
const notifKeys = [
  'tahajjud',
  'fajr',
  'dhuhr',
  'asr',
  'maghrib',
  'isha',
  'quran',
  'morning_azkar',
  'evening_azkar',
  'sleep_azkar',
  'routine',
];

/// Everything recorded for one calendar day.
class DayRecord {
  final Set<String> done;
  final Set<String> skipped;
  final Map<String, PrayerStatus> prayers;
  final Set<String> sunnah;
  int quranPages;
  final Map<String, int> dhikr;
  final Map<String, int> azkar;
  final Map<String, int> habits;
  final Map<String, String> muhasaba;

  /// Completion time (HH:mm, local) per activity / prayer id.
  final Map<String, String> completedAt;
  String note;

  DayRecord({
    Set<String>? done,
    Set<String>? skipped,
    Map<String, PrayerStatus>? prayers,
    Set<String>? sunnah,
    this.quranPages = 0,
    Map<String, int>? dhikr,
    Map<String, int>? azkar,
    Map<String, int>? habits,
    Map<String, String>? muhasaba,
    Map<String, String>? completedAt,
    this.note = '',
  })  : done = done ?? <String>{},
        skipped = skipped ?? <String>{},
        prayers = prayers ?? <String, PrayerStatus>{},
        sunnah = sunnah ?? <String>{},
        dhikr = dhikr ?? <String, int>{},
        azkar = azkar ?? <String, int>{},
        habits = habits ?? <String, int>{},
        muhasaba = muhasaba ?? <String, String>{},
        completedAt = completedAt ?? <String, String>{};

  PrayerStatus prayer(String key) => prayers[key] ?? PrayerStatus.none;

  int get farzPrayed => prayerKeys.where((k) => isPrayed(prayer(k))).length;

  int get totalDhikr => dhikr.values.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
        'done': done.toList(),
        if (skipped.isNotEmpty) 'skipped': skipped.toList(),
        'prayers': prayers.map((k, v) => MapEntry(k, v.index)),
        'sunnah': sunnah.toList(),
        'quran': quranPages,
        'dhikr': dhikr,
        'azkar': azkar,
        if (habits.isNotEmpty) 'habits': habits,
        if (muhasaba.isNotEmpty) 'muhasaba': muhasaba,
        if (completedAt.isNotEmpty) 'at': completedAt,
        'note': note,
      };

  factory DayRecord.fromJson(Map<String, dynamic> j) {
    final p = <String, PrayerStatus>{};
    (j['prayers'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      final i = (v as num).toInt();
      if (i >= 0 && i < PrayerStatus.values.length) p[k] = PrayerStatus.values[i];
    });
    Map<String, int> ints(dynamic m) =>
        (m as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt()));
    Set<String> strings(dynamic l) => ((l as List?) ?? []).map((e) => e.toString()).toSet();
    return DayRecord(
      done: strings(j['done']),
      skipped: strings(j['skipped']),
      prayers: p,
      sunnah: strings(j['sunnah']),
      quranPages: (j['quran'] as num?)?.toInt() ?? 0,
      dhikr: ints(j['dhikr']),
      azkar: ints(j['azkar']),
      habits: ints(j['habits']),
      muhasaba: (j['muhasaba'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v.toString())),
      completedAt: (j['at'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v.toString())),
      note: (j['note'] as String?) ?? '',
    );
  }
}

/// A user-created Tasbeeh counter.
class CustomDhikr {
  final String key;
  final String text;
  final int target;
  const CustomDhikr(this.key, this.text, this.target);

  Map<String, dynamic> toJson() => {'key': key, 'text': text, 'target': target};
  static CustomDhikr fromJson(Map<String, dynamic> j) =>
      CustomDhikr(j['key'] as String, (j['text'] as String?) ?? '', (j['target'] as num?)?.toInt() ?? 33);
}

/// A personal Islamic habit goal (e.g. "Smile / give charity", 1 per day).
class HabitGoal {
  final String id;
  final String name;
  final int target;
  const HabitGoal(this.id, this.name, this.target);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'target': target};
  static HabitGoal fromJson(Map<String, dynamic> j) =>
      HabitGoal(j['id'] as String, (j['name'] as String?) ?? '', (j['target'] as num?)?.toInt() ?? 1);
}

/// One charity record.
class SadaqahRecord {
  final String id;
  final DateTime date;
  final double amount;
  final String note;
  const SadaqahRecord(this.id, this.date, this.amount, this.note);

  Map<String, dynamic> toJson() => {'id': id, 'date': dayKey(date), 'amount': amount, 'note': note};
  static SadaqahRecord fromJson(Map<String, dynamic> j) => SadaqahRecord(
        j['id'] as String,
        DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        (j['amount'] as num?)?.toDouble() ?? 0,
        (j['note'] as String?) ?? '',
      );
}

class QuranRef {
  final int surah;
  final int ayah;
  const QuranRef(this.surah, this.ayah);

  String get key => '$surah:$ayah';
  static QuranRef? parse(String s) {
    final p = s.split(':');
    if (p.length != 2) return null;
    final a = int.tryParse(p[0]), b = int.tryParse(p[1]);
    if (a == null || b == null) return null;
    return QuranRef(a, b);
  }

  @override
  bool operator ==(Object other) => other is QuranRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);
}

class AppSettings {
  // ---- general ----
  bool urdu;
  ThemeMode themeMode;
  bool onboarded;
  String userName;
  String? profileImage;

  // ---- location & prayer ----
  int cityIndex;
  bool useCustomLocation;
  double customLat;
  double customLng;
  String customLocationName;
  CalcMethod method;
  bool hanafiAsr;
  int hijriAdjust;
  Map<String, int> prayerOffsets;
  Map<String, int> fixedPrayerTimes; // prayer -> minutes after midnight (user's own time)

  // ---- notifications ----
  bool notifications; // master switch
  bool tahajjudReminder; // legacy, mirrors notif['tahajjud']
  Map<String, bool> notif;
  int prayerReminderBefore; // minutes before prayer time (0 = at the time)
  bool notifVibrate;
  bool exactAlarms;
  bool autoTimezone;
  int snoozeMinutes;
  int wakeMinutes; // minutes after midnight, default 4:00 AM
  int quranReminderMinutes;
  int sleepMinutes;
  int azkarAfterMinutes; // morning azkar after Fajr / evening azkar after Asr

  // ---- quran ----
  int quranTarget;
  bool showUrdu;
  bool showEnglish;
  bool showTranslit;
  bool quranMushaf; // continuous mushaf view (true) or ayah-by-ayah translation view
  bool separateTasks; // routine surahs (Yaseen, Baqarah last 2...) never move the tilawat bookmark
  double arabicSize;
  bool indoPakScript; // Indo-Pak (default) or Uthmani Quran script

  // ---- tasbeeh ----
  bool tasbeehVibrate;
  bool tasbeehSound;
  bool tasbeehKeepAwake;
  Map<String, int> tasbeehTargets;
  List<CustomDhikr> customDhikr;

  // ---- routine ----
  List<RoutineItem> routine;
  Map<String, List<RoutineItem>> routineTemplates;

  // ---- extras ----
  Set<String> favAzkar;
  List<HabitGoal> habits;
  double sadaqahGoal;
  String currency;
  String? chillaStart; // dayKey of day 1 of the current chilla

  AppSettings({
    this.urdu = false,
    this.themeMode = ThemeMode.system,
    this.onboarded = false,
    this.userName = '',
    this.profileImage,
    this.cityIndex = 0,
    this.useCustomLocation = false,
    this.customLat = 0,
    this.customLng = 0,
    this.customLocationName = '',
    this.method = CalcMethod.karachi,
    this.hanafiAsr = true,
    this.hijriAdjust = 0,
    Map<String, int>? prayerOffsets,
    Map<String, int>? fixedPrayerTimes,
    this.notifications = true,
    this.tahajjudReminder = true,
    Map<String, bool>? notif,
    this.prayerReminderBefore = 0,
    this.notifVibrate = true,
    this.exactAlarms = false,
    this.autoTimezone = true,
    this.snoozeMinutes = 10,
    this.wakeMinutes = 240,
    this.quranReminderMinutes = 1200,
    this.sleepMinutes = 1320,
    this.azkarAfterMinutes = 30,
    this.quranTarget = 4,
    this.showUrdu = true,
    this.showEnglish = true,
    this.showTranslit = false,
    this.quranMushaf = true,
    this.separateTasks = true,
    this.arabicSize = 26,
    this.indoPakScript = true,
    this.tasbeehVibrate = true,
    this.tasbeehSound = false,
    this.tasbeehKeepAwake = false,
    Map<String, int>? tasbeehTargets,
    List<CustomDhikr>? customDhikr,
    List<RoutineItem>? routine,
    Map<String, List<RoutineItem>>? routineTemplates,
    Set<String>? favAzkar,
    List<HabitGoal>? habits,
    this.sadaqahGoal = 0,
    this.currency = 'Rs',
    this.chillaStart,
  })  : prayerOffsets = prayerOffsets ?? <String, int>{},
        fixedPrayerTimes = fixedPrayerTimes ?? <String, int>{},
        notif = notif ?? {for (final k in notifKeys) k: true},
        tasbeehTargets = tasbeehTargets ?? <String, int>{},
        customDhikr = customDhikr ?? <CustomDhikr>[],
        routine = routine ?? List<RoutineItem>.of(defaultRoutine),
        routineTemplates = routineTemplates ?? <String, List<RoutineItem>>{},
        favAzkar = favAzkar ?? <String>{},
        habits = habits ?? <HabitGoal>[];

  City get city => cities[cityIndex.clamp(0, cities.length - 1).toInt()];

  double get lat => useCustomLocation ? customLat : city.lat;
  double get lng => useCustomLocation ? customLng : city.lng;
  String get locationName => useCustomLocation
      ? (customLocationName.isEmpty ? '${customLat.toStringAsFixed(2)}, ${customLng.toStringAsFixed(2)}' : customLocationName)
      : city.name;

  bool notifOn(String key) => notifications && (notif[key] ?? true);

  Map<String, dynamic> toJson() => {
        'urdu': urdu,
        'theme': themeMode.index,
        'onboarded': onboarded,
        'name': userName,
        if (profileImage != null) 'photo': profileImage,
        'city': cityIndex,
        'customLoc': useCustomLocation,
        'lat': customLat,
        'lng': customLng,
        'locName': customLocationName,
        'method': method.index,
        'hanafi': hanafiAsr,
        'hijriAdjust': hijriAdjust,
        'offsets': prayerOffsets,
        'fixedTimes': fixedPrayerTimes,
        'notifications': notifications,
        'tahajjud': notif['tahajjud'] ?? tahajjudReminder,
        'notif': notif,
        'before': prayerReminderBefore,
        'vibrate': notifVibrate,
        'exact': exactAlarms,
        'autoTz': autoTimezone,
        'snooze': snoozeMinutes,
        'wake': wakeMinutes,
        'quranRemind': quranReminderMinutes,
        'sleep': sleepMinutes,
        'azkarAfter': azkarAfterMinutes,
        'quranTarget': quranTarget,
        'showUr': showUrdu,
        'showEn': showEnglish,
        'showTr': showTranslit,
        'mushaf': quranMushaf,
        'sepTasks': separateTasks,
        'arSize': arabicSize,
        'indoPak': indoPakScript,
        'tVibrate': tasbeehVibrate,
        'tSound': tasbeehSound,
        'tAwake': tasbeehKeepAwake,
        'tTargets': tasbeehTargets,
        'tCustom': customDhikr.map((e) => e.toJson()).toList(),
        'routine': routine.map((e) => e.toJson()).toList(),
        'rv': routineVersion,
        'templates': routineTemplates.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
        'favAzkar': favAzkar.toList(),
        'habits': habits.map((e) => e.toJson()).toList(),
        'sadaqahGoal': sadaqahGoal,
        'currency': currency,
        if (chillaStart != null) 'chilla': chillaStart,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    int idx(String k, int len, int def) {
      final v = (j[k] as num?)?.toInt() ?? def;
      return (v >= 0 && v < len) ? v : def;
    }

    int intOr(String k, int def) => (j[k] as num?)?.toInt() ?? def;
    double dblOr(String k, double def) => (j[k] as num?)?.toDouble() ?? def;
    bool boolOr(String k, bool def) => j[k] as bool? ?? def;
    List<Map<String, dynamic>> maps(dynamic l) =>
        ((l as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final tahajjud = boolOr('tahajjud', true);
    final notif = {for (final k in notifKeys) k: true};
    (j['notif'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      if (v is bool) notif[k] = v;
    });
    if (j['notif'] == null) notif['tahajjud'] = tahajjud;

    // Routine: v2 list, or migrate from v1 (defaults + custom items - disabled).
    List<RoutineItem> routine;
    if (j['routine'] is List) {
      routine = maps(j['routine']).map(RoutineItem.fromJson).toList();
      if (((j['rv'] as num?)?.toInt() ?? 1) < routineVersion) routine = addNewDefaults(routine);
    } else {
      final disabled = ((j['disabled'] as List?) ?? []).map((e) => e.toString()).toSet();
      final legacyCustom = maps(j['custom']).map(RoutineItem.customFromJson).toList();
      routine = [
        for (final item in [...defaultRoutine, ...legacyCustom])
          disabled.contains(item.id) ? item.copyWith(enabled: false) : item,
      ];
    }

    final templates = <String, List<RoutineItem>>{};
    (j['templates'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      templates[k] = maps(v).map(RoutineItem.fromJson).toList();
    });

    return AppSettings(
      urdu: boolOr('urdu', false),
      themeMode: ThemeMode.values[idx('theme', ThemeMode.values.length, 0)],
      onboarded: boolOr('onboarded', false),
      userName: (j['name'] as String?) ?? '',
      profileImage: j['photo'] as String?,
      cityIndex: idx('city', cities.length, 0),
      useCustomLocation: boolOr('customLoc', false),
      customLat: dblOr('lat', 0),
      customLng: dblOr('lng', 0),
      customLocationName: (j['locName'] as String?) ?? '',
      method: CalcMethod.values[idx('method', CalcMethod.values.length, 0)],
      hanafiAsr: boolOr('hanafi', true),
      hijriAdjust: intOr('hijriAdjust', 0),
      prayerOffsets: (j['offsets'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt())),
      fixedPrayerTimes: (j['fixedTimes'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt())),
      notifications: boolOr('notifications', true),
      tahajjudReminder: tahajjud,
      notif: notif,
      prayerReminderBefore: intOr('before', 0),
      notifVibrate: boolOr('vibrate', true),
      exactAlarms: boolOr('exact', false),
      autoTimezone: boolOr('autoTz', true),
      snoozeMinutes: intOr('snooze', 10),
      wakeMinutes: intOr('wake', 240),
      quranReminderMinutes: intOr('quranRemind', 1200),
      sleepMinutes: intOr('sleep', 1320),
      azkarAfterMinutes: intOr('azkarAfter', 30),
      quranTarget: intOr('quranTarget', 4),
      showUrdu: boolOr('showUr', true),
      showEnglish: boolOr('showEn', true),
      showTranslit: boolOr('showTr', false),
      quranMushaf: boolOr('mushaf', true),
      separateTasks: boolOr('sepTasks', true),
      arabicSize: dblOr('arSize', 26),
      indoPakScript: boolOr('indoPak', true),
      tasbeehVibrate: boolOr('tVibrate', true),
      tasbeehSound: boolOr('tSound', false),
      tasbeehKeepAwake: boolOr('tAwake', false),
      tasbeehTargets: (j['tTargets'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt())),
      customDhikr: maps(j['tCustom']).map(CustomDhikr.fromJson).toList(),
      routine: routine,
      routineTemplates: templates,
      favAzkar: ((j['favAzkar'] as List?) ?? []).map((e) => e.toString()).toSet(),
      habits: maps(j['habits']).map(HabitGoal.fromJson).toList(),
      sadaqahGoal: dblOr('sadaqahGoal', 0),
      currency: (j['currency'] as String?) ?? 'Rs',
      chillaStart: j['chilla'] as String?,
    );
  }
}

const int quranTotalPages = 604;

/// Bumped when new default activities are added, so saved routines get them.
const int routineVersion = 5;

/// Default activities added in later versions (chilla: Surah Waqiah and
/// morning / evening tasbeehat).
const newDefaultIds = [
  'waqiah',
  'm_istighfar', 'm_durood', 'm_kalima1', 'm_kalima3',
  'e_istighfar', 'e_durood', 'e_kalima1', 'e_kalima3',
  'awabeen', // v4: Awabeen nawafil after Maghrib
  'm_lailaha', 'e_lailaha', // v5: La ilaha illallah morning / evening
];

/// Inserts missing [newDefaultIds] into a saved routine, each after the
/// default item that precedes it.
List<RoutineItem> addNewDefaults(List<RoutineItem> routine) {
  final out = List<RoutineItem>.of(routine);
  for (final id in newDefaultIds) {
    if (out.any((e) => e.id == id)) continue;
    final di = defaultRoutine.indexWhere((e) => e.id == id);
    if (di < 0) continue;
    var insertAt = out.length;
    for (var k = di - 1; k >= 0; k--) {
      final prev = out.indexWhere((e) => e.id == defaultRoutine[k].id);
      if (prev >= 0) {
        insertAt = prev + 1;
        break;
      }
    }
    out.insert(insertAt, defaultRoutine[di]);
  }
  return out;
}

int _idCounter = 0;

/// Unique id for user-created records (time + counter, never repeats in a session).
/// Current time used by the schedule engine. Tests replace it to get a
/// deterministic time of day.
DateTime Function() clock = DateTime.now;

String newId(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  late AppSettings settings;
  final Map<String, DayRecord> _cache = {};

  /// Called whenever settings that affect notifications change.
  void Function(AppState state)? onScheduleChanged;

  DateTime _lastSeenDay = clock();
  Duration _lastOffset = clock().timeZoneOffset;

  /// Called when the app returns to the foreground: if the date or the time
  /// zone changed, prayer times / schedule are recomputed and reminders are
  /// rescheduled.
  void onResume({DateTime? now}) {
    final t = now ?? clock();
    final dayChanged = t.year != _lastSeenDay.year || t.month != _lastSeenDay.month || t.day != _lastSeenDay.day;
    final tzChanged = t.timeZoneOffset != _lastOffset && settings.autoTimezone;
    // Also refresh reminders when the app was in the background for long
    // (the user may have changed the clock manually: Android TIME_SET).
    final stale = t.difference(_lastSeenDay).abs() > const Duration(hours: 6);
    _lastSeenDay = t;
    _lastOffset = t.timeZoneOffset;
    if (dayChanged || tzChanged || stale) {
      _timesCache.clear();
      notifyListeners();
      onScheduleChanged?.call(this);
    }
  }

  // Quran khatam data
  int khatamPages = 0;
  int khatamCount = 0;
  Set<int> juzDone = {};
  Set<int> readPages = {};
  int qazaPending = 0;
  QuranRef? lastRead;

  /// Where the user stopped in each surah (surah -> ayah), so every surah
  /// resumes on its own.
  Map<int, int> surahPos = {};

  /// Ayah to resume [surah] from (1 if never read).
  int resumeAyah(int surah) {
    final t = readingTask;
    if (t != null && settings.separateTasks) {
      final p = taskPosOn(t, today);
      return p != null && p.surah == surah ? p.ayah : (surah == t.surah ? t.ayah : 1);
    }
    return surahPos[surah] ?? 1;
  }

  /// The routine surah task (e.g. Yaseen, last 2 ayat of Al-Baqarah) open in
  /// the reader right now. While set, reading positions are saved for that
  /// task only and the daily tilawat bookmark stays where it was.
  ReadingTask? readingTask;

  /// Where a routine surah task was left today: "date|surah|ayah" per item id.
  Map<String, String> taskPos = {};

  QuranRef? taskPosOn(ReadingTask t, DateTime date) {
    final parts = (taskPos[t.id] ?? '').split('|');
    if (parts.length != 3 || parts[0] != dayKey(date)) return null;
    final s = int.tryParse(parts[1]), a = int.tryParse(parts[2]);
    return s == null || a == null || !validRef(s, a) ? null : QuranRef(s, a);
  }

  void _setTaskPos(ReadingTask t, int surah, int ayah) {
    final v = '${dayKey(today)}|$surah|$ayah';
    if (taskPos[t.id] == v) return;
    taskPos[t.id] = v;
    prefs.setString('taskPos', jsonEncode(taskPos));
    notifyListeners();
  }
  List<QuranRef> bookmarks = [];
  List<QuranRef> favouriteAyat = [];
  List<Map<String, dynamic>> readingHistory = [];

  List<SadaqahRecord> sadaqah = [];

  AppState(this.prefs) {
    _loadAll();
  }

  void _loadAll() {
    _cache.clear();
    _savedDays.clear();
    final raw = prefs.getString('settings');
    try {
      settings = raw == null ? AppSettings() : AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      settings = AppSettings();
    }
    khatamPages = prefs.getInt('khatamPages') ?? 0;
    khatamCount = prefs.getInt('khatamCount') ?? 0;
    juzDone = (prefs.getStringList('juzDone') ?? []).map(int.tryParse).whereType<int>().toSet();
    readPages = (prefs.getStringList('readPages') ?? []).map(int.tryParse).whereType<int>().toSet();
    qazaPending = prefs.getInt('qazaPending') ?? 0;
    lastRead = QuranRef.parse(prefs.getString('lastRead') ?? '');
    surahPos = {};
    try {
      taskPos = (jsonDecode(prefs.getString('taskPos') ?? '{}') as Map<String, dynamic>).map((k, v) => MapEntry(k, '$v'));
    } catch (_) {
      taskPos = {};
    }
    try {
      final raw = jsonDecode(prefs.getString('surahPos') ?? '{}') as Map<String, dynamic>;
      raw.forEach((k, v) {
        final sNo = int.tryParse(k);
        if (sNo != null && v is int && validRef(sNo, v)) surahPos[sNo] = v;
      });
    } catch (_) {}
    if (lastRead != null && !surahPos.containsKey(lastRead!.surah)) surahPos[lastRead!.surah] = lastRead!.ayah;
    bookmarks = (prefs.getStringList('bookmarks') ?? [])
        .map(QuranRef.parse)
        .whereType<QuranRef>()
        .where((r) => validRef(r.surah, r.ayah))
        .toSet()
        .toList();
    favouriteAyat = (prefs.getStringList('favAyat') ?? [])
        .map(QuranRef.parse)
        .whereType<QuranRef>()
        .where((r) => validRef(r.surah, r.ayah))
        .toSet()
        .toList();
    try {
      readingHistory = ((jsonDecode(prefs.getString('readHistory') ?? '[]') as List))
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      readingHistory = [];
    }
    try {
      sadaqah = ((jsonDecode(prefs.getString('sadaqah') ?? '[]') as List))
          .map((e) => SadaqahRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      sadaqah = [];
    }
  }

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppState(prefs);
  }

  S get s => S(settings.urdu);

  PrayerCalculator get calculator => PrayerCalculator(
        lat: settings.lat,
        lng: settings.lng,
        method: settings.method,
        hanafiAsr: settings.hanafiAsr,
      );

  // ---------------- persistence ----------------
  /// Writes are serialised through one queue so they reach disk in order;
  /// [flush] waits for all of them (called when the app goes to background).
  Future<void> _queue = Future<void>.value();

  Future<void> _write(Future<bool> Function() op) {
    _queue = _queue.then((_) async {
      try {
        await op();
      } catch (e) {
        debugPrint('Save failed: $e');
      }
    });
    return _queue;
  }

  Future<void> flush() => _queue;

  void saveSettings({bool reschedule = false}) {
    final json = jsonEncode(settings.toJson());
    _write(() => prefs.setString('settings', json));
    notifyListeners();
    if (reschedule) onScheduleChanged?.call(this);
  }

  DayRecord day(DateTime date) {
    final key = dayKey(date);
    final cached = _cache[key];
    if (cached != null) return cached;
    final raw = prefs.getString('day_$key');
    DayRecord rec;
    try {
      rec = raw == null ? DayRecord() : DayRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      rec = DayRecord();
    }
    _cache[key] = rec;
    return rec;
  }

  /// Days saved in this session (writes are queued, so prefs may lag).
  final Set<String> _savedDays = {};

  bool hasRecord(DateTime date) {
    final key = dayKey(date);
    return _savedDays.contains(key) || prefs.containsKey('day_$key');
  }

  void _saveDay(DateTime date) {
    final key = dayKey(date);
    _savedDays.add(key);
    final rec = _cache[key];
    if (rec != null) {
      final json = jsonEncode(rec.toJson());
      _write(() => prefs.setString('day_$key', json));
    }
    notifyListeners();
  }

  DateTime get today {
    final n = clock();
    return DateTime(n.year, n.month, n.day);
  }

  // ---------------- prayer times ----------------
  /// Prayer times for [date]: the user's own fixed time if set, otherwise the
  /// calculated time plus the manual +/- minutes adjustment.
  DayPrayerTimes prayerTimes(DateTime date) {
    final st = settings;
    final sig = '${dayKey(date)}|${st.lat}|${st.lng}|${st.method}|${st.hanafiAsr}|${st.prayerOffsets}|'
        '${st.fixedPrayerTimes}|${DateTime(date.year, date.month, date.day).timeZoneOffset}';
    final hit = _timesCache[sig];
    if (hit != null) return hit;
    if (_timesCache.length > 64) _timesCache.clear();
    return _timesCache[sig] = _computeTimes(date);
  }

  final Map<String, DayPrayerTimes> _timesCache = {};

  DayPrayerTimes _computeTimes(DateTime date) {
    final raw = calculator.forDate(date);
    return DayPrayerTimes({
      for (final p in PrayerName.values)
        p: settings.fixedPrayerTimes[p.name] != null
            ? DateTime(date.year, date.month, date.day).add(Duration(minutes: settings.fixedPrayerTimes[p.name]!)).toUtc()
            : raw[p].add(Duration(minutes: settings.prayerOffsets[p.name] ?? 0)),
    }, reliable: raw.reliable || settings.fixedPrayerTimes.length >= 5);
  }

  bool hasFixedTime(String key) => settings.fixedPrayerTimes.containsKey(key);

  /// Sets the user's own time for a prayer (null = back to calculated time).
  void setFixedPrayerTime(String key, int? minutes) {
    if (minutes == null) {
      settings.fixedPrayerTimes.remove(key);
    } else {
      settings.fixedPrayerTimes[key] = minutes.clamp(0, 24 * 60 - 1).toInt();
    }
    saveSettings(reschedule: true);
  }

  static const farzPrayers = [PrayerName.fajr, PrayerName.dhuhr, PrayerName.asr, PrayerName.maghrib, PrayerName.isha];

  /// Next upcoming farz prayer after [now].
  MapEntry<PrayerName, DateTime> nextPrayer(DateTime now) {
    for (var offset = 0; offset < 2; offset++) {
      final d = DateTime(now.year, now.month, now.day).add(Duration(days: offset));
      final t = prayerTimes(d);
      for (final p in farzPrayers) {
        if (t[p].isAfter(now.toUtc())) return MapEntry(p, t[p]);
      }
    }
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return MapEntry(PrayerName.fajr, prayerTimes(tomorrow)[PrayerName.fajr]);
  }

  /// Whether the time of [key] has started on [date].
  bool prayerStarted(DateTime date, String key, DateTime now) {
    final p = PrayerName.values.firstWhere((e) => e.name == key);
    return !prayerTimes(date)[p].isAfter(now.toUtc());
  }

  void setPrayerOffset(String key, int minutes) {
    settings.prayerOffsets[key] = minutes.clamp(-60, 60).toInt();
    saveSettings(reschedule: true);
  }

  // ---------------- routine ----------------
  List<RoutineItem> get allItems => settings.routine;

  List<RoutineItem> routineFor(DateTime date) => settings.routine.where((i) => i.appliesOn(date)).toList();

  RoutineItem? itemById(String id) {
    for (final i in settings.routine) {
      if (i.id == id) return i;
    }
    return null;
  }

  // ---------------- schedule engine bindings ----------------
  /// Time window of [item] on [date] (see services/schedule.dart).
  ActivityWindow windowOf(RoutineItem item, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return ScheduleEngine.window(item, d, prayerTimes(d), prayerTimes(DateTime(d.year, d.month, d.day + 1)));
  }

  /// (count, target) for activities completed by a counter (tasbeeh / Quran pages).
  (int, int)? countedProgress(RoutineItem item, DateTime date) {
    final rec = day(date);
    if (item.dhikrKey != null && item.dhikrTarget > 0) {
      return (rec.dhikr[item.dhikrKey!] ?? 0, dhikrTarget(item.dhikrKey!, item.dhikrTarget));
    }
    if (item.id == 'quran_daily') return (rec.quranPages, settings.quranTarget);
    return null;
  }

  bool isDone(DateTime date, RoutineItem item) {
    final rec = day(date);
    if (item.prayerKey != null) return isPrayed(rec.prayer(item.prayerKey!));
    if (rec.done.contains(item.id)) return true;
    final p = countedProgress(item, date);
    return p != null && p.$2 > 0 && p.$1 >= p.$2;
  }

  bool isSkipped(DateTime date, RoutineItem item) => day(date).skipped.contains(item.id);

  ActivityState activityState(RoutineItem item, DateTime date, {DateTime? now}) {
    final p = countedProgress(item, date);
    return ScheduleEngine.stateOf(
      window: windowOf(item, date),
      now: now ?? clock(),
      done: isDone(date, item),
      skipped: isSkipped(date, item),
      hasProgress: p != null && p.$1 > 0,
    );
  }

  /// Whether the user may mark [item] on [date] as completed right now.
  /// Future dates: never. Past dates: yes (historical correction).
  /// Today: only once the activity's window has started.
  bool canComplete(RoutineItem item, DateTime date, {DateTime? now}) {
    final t = now ?? clock();
    final d = DateTime(date.year, date.month, date.day);
    final todayD = DateTime(t.year, t.month, t.day);
    if (d.isAfter(todayD)) return false;
    if (d.isBefore(todayD)) return true;
    return !t.isBefore(windowOf(item, d).start);
  }

  /// Whether prayer [key] on [date] can be recorded now.
  bool canRecordPrayer(DateTime date, String key, {DateTime? now}) {
    final item = itemById(key) ?? defaultRoutine.firstWhere((e) => e.id == key);
    return canComplete(item, date, now: now);
  }

  static String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Completion time of an activity (local DateTime) if recorded.
  DateTime? completedTime(DateTime date, String id) {
    final v = day(date).completedAt[id];
    if (v == null) return null;
    final p = v.split(':');
    if (p.length != 2) return null;
    return DateTime(date.year, date.month, date.day, int.tryParse(p[0]) ?? 0, int.tryParse(p[1]) ?? 0);
  }

  /// Toggles completion. Returns false when the change is not allowed
  /// (activity locked / future date / completed by its counter).
  bool toggleItem(DateTime date, RoutineItem item, {DateTime? now}) {
    final rec = day(date);
    final done = isDone(date, item);
    if (!done && !canComplete(item, date, now: now)) return false;
    if (done && item.prayerKey == null) {
      // Completed by its counter: undo by reducing / resetting the counter
      // (checked before anything is changed so no data is touched).
      final p = countedProgress(item, date);
      if (p != null && p.$2 > 0 && p.$1 >= p.$2) return false;
    }
    rec.skipped.remove(item.id);
    if (done) {
      rec.completedAt.remove(item.id);
    } else {
      rec.completedAt[item.id] = _hhmm(now ?? clock());
    }
    if (item.prayerKey != null) {
      rec.prayers[item.prayerKey!] = done ? PrayerStatus.none : PrayerStatus.alone;
    } else if (done) {
      rec.done.remove(item.id);
    } else {
      rec.done.add(item.id);
    }
    _saveDay(date);
    return true;
  }

  /// Completion state of one activity, taken before a change so it can be
  /// undone exactly (counters are never part of it).
  CompletionSnapshot snapshotOf(DateTime date, RoutineItem item) {
    final rec = day(date);
    return CompletionSnapshot(
      id: item.id,
      inDone: rec.done.contains(item.id),
      skipped: rec.skipped.contains(item.id),
      at: rec.completedAt[item.id],
      prayerKey: item.prayerKey,
      prayer: item.prayerKey == null ? null : rec.prayer(item.prayerKey!),
    );
  }

  /// Undo: restores exactly the snapshot of that one activity. Other
  /// activities and Quran / tasbeeh counters are not touched.
  void restoreSnapshot(DateTime date, CompletionSnapshot snap) {
    final rec = day(date);
    if (snap.inDone) {
      rec.done.add(snap.id);
    } else {
      rec.done.remove(snap.id);
    }
    if (snap.skipped) {
      rec.skipped.add(snap.id);
    } else {
      rec.skipped.remove(snap.id);
    }
    if (snap.at == null) {
      rec.completedAt.remove(snap.id);
    } else {
      rec.completedAt[snap.id] = snap.at!;
    }
    if (snap.prayerKey != null && snap.prayer != null) {
      if (snap.prayer == PrayerStatus.none) {
        rec.prayers.remove(snap.prayerKey);
      } else {
        rec.prayers[snap.prayerKey!] = snap.prayer!;
      }
    }
    _saveDay(date);
  }

  /// Sets (or with null, resets to the default) the Azkar schedule of an
  /// activity. The id and all records stay the same.
  void setAzkarSchedule(String id, AzkarSchedule? schedule) {
    final item = itemById(id);
    if (item == null) return;
    if (schedule != null) {
      updateRoutineItem(schedule.applyTo(item));
      return;
    }
    final def = defaultRoutine.where((e) => e.id == id).firstOrNull;
    updateRoutineItem(item.copyWith(
      clearSchedule: true,
      timeMinutes: def?.timeMinutes,
      clearTime: def != null && def.timeMinutes == null,
    ));
  }

  /// Marks / unmarks by id. Marking respects the same lock as [toggleItem].
  bool setDone(DateTime date, String id, bool value, {DateTime? now}) {
    final rec = day(date);
    final item = itemById(id);
    if (value && item != null && !canComplete(item, date, now: now)) return false;
    if (value) {
      rec.done.add(id);
      rec.skipped.remove(id);
      rec.completedAt.putIfAbsent(id, () => _hhmm(now ?? clock()));
    } else {
      rec.done.remove(id);
      rec.completedAt.remove(id);
    }
    _saveDay(date);
    return true;
  }

  void toggleSkip(DateTime date, RoutineItem item) {
    final rec = day(date);
    if (!rec.skipped.remove(item.id)) {
      rec.skipped.add(item.id);
      rec.done.remove(item.id);
    }
    _saveDay(date);
  }

  /// All activities of [date] with their window and state, in time order.
  List<ScheduledActivity> scheduleFor(DateTime date, {DateTime? now}) {
    final t = now ?? clock();
    final d = DateTime(date.year, date.month, date.day);
    final items = routineFor(d);
    final list = <ScheduledActivity>[
      for (final it in items) ScheduledActivity(it, d, windowOf(it, d), activityState(it, d, now: t)),
    ];
    final order = {for (var i = 0; i < items.length; i++) items[i].id: i};
    list.sort((a, b) {
      final c = a.window.start.compareTo(b.window.start);
      return c != 0 ? c : order[a.item.id]!.compareTo(order[b.item.id]!);
    });
    return list;
  }

  /// Yesterday's activities that are still open (e.g. Isha / Witr after
  /// midnight, before Fajr).
  List<ScheduledActivity> carriedOver({DateTime? now}) {
    final t = now ?? clock();
    final y = DateTime(t.year, t.month, t.day - 1);
    return scheduleFor(y, now: t).where((e) => e.isOpen && e.window.contains(t)).toList();
  }

  /// Daily score (Farz / Routine / Optional), see services/scoring.dart.
  DayScore scoreFor(DateTime date, {DateTime? now}) => ScoringService.score(this, date, now: now);

  /// (done, due) of farz prayers + mandatory routine activities whose time has
  /// started. Optional, skipped and future activities are excluded.
  (int, int) completion(DateTime date, {DateTime? now}) {
    final sc = scoreFor(date, now: now);
    return (sc.done, sc.due);
  }

  double completionRatio(DateTime date) => scoreFor(date).overall;

  /// Removes manual "done" marks of counted activities whose counter fell
  /// below target (after reset / decrement / target change).
  void _recalcCounted(DateTime date, {String? dhikrKey, bool quran = false}) {
    final rec = day(date);
    for (final item in allItems) {
      final matches = (dhikrKey != null && item.dhikrKey == dhikrKey) || (quran && item.id == 'quran_daily');
      if (!matches) continue;
      final p = countedProgress(item, date);
      if (p != null && p.$1 < p.$2) rec.done.remove(item.id);
    }
  }

  void addRoutineItem(RoutineItem item) {
    settings.routine.add(item);
    saveSettings(reschedule: item.reminder);
  }

  void updateRoutineItem(RoutineItem item) {
    final i = settings.routine.indexWhere((e) => e.id == item.id);
    if (i < 0) return;
    settings.routine[i] = item;
    saveSettings(reschedule: true);
  }

  void deleteRoutineItem(String id) {
    settings.routine.removeWhere((e) => e.id == id);
    saveSettings(reschedule: true);
  }

  void reorderRoutine(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = settings.routine.removeAt(oldIndex);
    settings.routine.insert(newIndex.clamp(0, settings.routine.length).toInt(), item);
    saveSettings();
  }

  void saveTemplate(String name) {
    settings.routineTemplates[name] = List<RoutineItem>.of(settings.routine);
    saveSettings();
  }

  void applyTemplate(String name) {
    final t = settings.routineTemplates[name];
    if (t == null) return;
    settings.routine = List<RoutineItem>.of(t);
    saveSettings(reschedule: true);
  }

  void deleteTemplate(String name) {
    settings.routineTemplates.remove(name);
    saveSettings();
  }

  void resetRoutineToDefault() {
    settings.routine = List<RoutineItem>.of(defaultRoutine);
    saveSettings(reschedule: true);
  }

  /// Legacy helpers kept for compatibility.
  void addCustomItem(String name, String target, RoutineSection section) {
    addRoutineItem(RoutineItem(
      id: newId('custom'),
      en: name,
      ur: name,
      section: section,
      targetEn: target,
      targetUr: target,
      custom: true,
    ));
  }

  void removeCustomItem(String id) => deleteRoutineItem(id);

  void setItemEnabled(String id, bool enabled) {
    final item = itemById(id);
    if (item != null) updateRoutineItem(item.copyWith(enabled: enabled));
  }

  // ---------------- prayers ----------------
  /// Records a prayer status. Returns false (and changes nothing) when the
  /// prayer's time has not started yet or the date is in the future.
  /// "Not recorded" (none) can always be set to undo a mistake.
  bool setPrayer(DateTime date, String key, PrayerStatus status, {DateTime? now}) {
    if (status != PrayerStatus.none && !canRecordPrayer(date, key, now: now)) return false;
    final rec = day(date);
    rec.prayers[key] = status;
    if (isPrayed(status)) {
      rec.completedAt[key] = _hhmm(now ?? clock());
    } else {
      rec.completedAt.remove(key);
    }
    _saveDay(date);
    return true;
  }

  /// Display status of a prayer: a past window that was never recorded shows
  /// as Missed (it is not stored, so the user can still correct it).
  PrayerStatus effectivePrayerStatus(DateTime date, String key, {DateTime? now}) {
    final st = day(date).prayer(key);
    if (st != PrayerStatus.none) return st;
    final item = itemById(key) ?? defaultRoutine.firstWhere((e) => e.id == key);
    final ended = !(now ?? clock()).isBefore(windowOf(item, date).end);
    return ended ? PrayerStatus.missed : PrayerStatus.none;
  }

  bool toggleSunnah(DateTime date, String key, {DateTime? now}) {
    final rec = day(date);
    final has = rec.sunnah.contains(key);
    if (!has) {
      final item = itemById(key) ?? defaultRoutine.firstWhere((e) => e.id == key, orElse: () => defaultRoutine.first);
      if (!canComplete(item, date, now: now)) return false;
    }
    if (!rec.sunnah.remove(key)) rec.sunnah.add(key);
    // Witr is also a routine item.
    if (key == 'witr') {
      if (rec.sunnah.contains('witr')) {
        rec.done.add('witr');
      } else {
        rec.done.remove('witr');
      }
    }
    _saveDay(date);
    return true;
  }

  bool witrDone(DateTime date) {
    final rec = day(date);
    return rec.sunnah.contains('witr') || rec.done.contains('witr');
  }

  void changeQaza(int delta) {
    qazaPending = (qazaPending + delta).clamp(0, 100000).toInt();
    prefs.setInt('qazaPending', qazaPending);
    notifyListeners();
  }

  // ---------------- dhikr / azkar ----------------
  int dhikrTarget(String key, int def) => settings.tasbeehTargets[key] ?? def;

  /// Changing a target re-evaluates today's linked activities immediately
  /// (completion is derived from count >= target).
  void setDhikrTarget(String key, int target) {
    settings.tasbeehTargets[key] = target.clamp(1, 100000).toInt();
    _recalcCounted(today, dhikrKey: key);
    _saveDay(today);
    saveSettings();
  }

  /// Linked routine activities complete automatically when the count reaches
  /// the target and become pending again when it drops below.
  void incrementDhikr(DateTime date, String key, {int by = 1}) {
    final rec = day(date);
    final before = rec.dhikr[key] ?? 0;
    final v = (before + by).clamp(0, 10000000).toInt();
    rec.dhikr[key] = v;
    if (by < 0) _recalcCounted(date, dhikrKey: key);
    for (final item in allItems) {
      if (item.dhikrKey != key || item.dhikrTarget <= 0) continue;
      final target = dhikrTarget(key, item.dhikrTarget);
      if (before < target && v >= target) rec.completedAt[item.id] = _hhmm(clock());
      if (v < target && !rec.done.contains(item.id)) rec.completedAt.remove(item.id);
    }
    _saveDay(date);
  }

  /// Resets a counter and returns the previous value (for Undo).
  int resetDhikr(DateTime date, String key) {
    final rec = day(date);
    final previous = rec.dhikr[key] ?? 0;
    rec.dhikr[key] = 0;
    _recalcCounted(date, dhikrKey: key);
    _saveDay(date);
    return previous;
  }

  /// Restores a counter value (Undo after reset).
  void restoreDhikr(DateTime date, String key, int value) {
    day(date).dhikr[key] = value < 0 ? 0 : value;
    _saveDay(date);
  }

  void addCustomDhikr(String text, int target) {
    settings.customDhikr.add(CustomDhikr(newId('c'), text, target));
    saveSettings();
  }

  void deleteCustomDhikr(String key) {
    settings.customDhikr.removeWhere((e) => e.key == key);
    saveSettings();
  }

  int azkarCount(DateTime date, String key) => day(date).azkar[key] ?? 0;

  void setAzkarCount(DateTime date, String key, int value) {
    day(date).azkar[key] = value;
    _saveDay(date);
  }

  /// Sets several azkar counters at once (e.g. "already read, complete all").
  void setAzkarCounts(DateTime date, Map<String, int> values) {
    day(date).azkar.addAll(values);
    _saveDay(date);
  }

  void toggleFavAzkar(String id) {
    if (!settings.favAzkar.remove(id)) settings.favAzkar.add(id);
    saveSettings();
  }

  // ---------------- Quran ----------------
  void addPages(DateTime date, int delta) {
    final rec = day(date);
    final newVal = (rec.quranPages + delta).clamp(0, 1000).toInt();
    final applied = newVal - rec.quranPages;
    rec.quranPages = newVal;
    khatamPages += applied;
    if (khatamPages < 0) khatamPages = 0;
    while (khatamPages >= quranTotalPages) {
      khatamPages -= quranTotalPages;
      khatamCount++;
      juzDone.clear();
      readPages.clear();
    }
    // "Daily Quran" completes automatically when pages >= target.
    if (applied < 0) _recalcCounted(date, quran: true);
    _saveQuran();
    _saveDay(date);
  }

  /// Changes the daily Quran target and re-evaluates today's completion.
  void setQuranTarget(int pages) {
    settings.quranTarget = pages.clamp(1, 604).toInt();
    _recalcCounted(today, quran: true);
    _saveDay(today);
    saveSettings();
  }

  /// Marks a mushaf page as read/unread (also counts towards today's pages).
  void togglePageRead(int page) {
    if (readPages.remove(page)) {
      addPages(today, -1);
    } else {
      readPages.add(page);
      addPages(today, 1);
    }
  }

  void toggleJuz(int juz) {
    if (!juzDone.remove(juz)) juzDone.add(juz);
    _saveQuran();
    notifyListeners();
  }

  /// Starts a new khatam cycle (keeps the number of completed khatams).
  void resetKhatam() {
    khatamPages = 0;
    juzDone.clear();
    readPages.clear();
    _saveQuran();
    notifyListeners();
  }

  /// Full reset: current cycle and completed khatam count (daily page
  /// history is kept).
  void resetKhatamFull() {
    khatamCount = 0;
    resetKhatam();
  }

  void setLastRead(int surah, int ayah) {
    final t = readingTask;
    if (t != null && settings.separateTasks) {
      _setTaskPos(t, surah, ayah);
      return;
    }
    final ref = QuranRef(surah, ayah);
    if (lastRead == ref && surahPos[surah] == ayah) return;
    lastRead = ref;
    prefs.setString('lastRead', ref.key);
    surahPos[surah] = ayah;
    prefs.setString('surahPos', jsonEncode({for (final e in surahPos.entries) '${e.key}': e.value}));
    final todayKey = dayKey(today);
    readingHistory.removeWhere((e) => e['d'] == todayKey && e['s'] == surah);
    readingHistory.insert(0, {'d': todayKey, 's': surah, 'a': ayah});
    if (readingHistory.length > 60) readingHistory = readingHistory.sublist(0, 60);
    prefs.setString('readHistory', jsonEncode(readingHistory));
    notifyListeners();
  }

  bool isBookmarked(int s, int a) => bookmarks.contains(QuranRef(s, a));
  bool isFavouriteAyah(int s, int a) => favouriteAyat.contains(QuranRef(s, a));

  static bool validRef(int s, int a) => s >= 1 && s <= 114 && a >= 1 && a <= 286;

  void toggleBookmark(int s, int a) {
    if (!validRef(s, a)) return;
    final r = QuranRef(s, a);
    if (!bookmarks.remove(r)) bookmarks.insert(0, r);
    bookmarks = bookmarks.toSet().toList();
    prefs.setStringList('bookmarks', bookmarks.map((e) => e.key).toList());
    notifyListeners();
  }

  void toggleFavouriteAyah(int s, int a) {
    if (!validRef(s, a)) return;
    final r = QuranRef(s, a);
    if (!favouriteAyat.remove(r)) favouriteAyat.insert(0, r);
    favouriteAyat = favouriteAyat.toSet().toList();
    prefs.setStringList('favAyat', favouriteAyat.map((e) => e.key).toList());
    notifyListeners();
  }

  void _saveQuran() {
    prefs.setInt('khatamPages', khatamPages);
    prefs.setInt('khatamCount', khatamCount);
    prefs.setStringList('juzDone', juzDone.map((e) => e.toString()).toList());
    prefs.setStringList('readPages', readPages.map((e) => e.toString()).toList());
  }

  // ---------------- chilla (40-day cycle) ----------------
  /// (chilla number, day 1..40) for [date], or null if no chilla was started.
  (int, int)? chillaOn(DateTime date) {
    final start = DateTime.tryParse(settings.chillaStart ?? '');
    if (start == null) return null;
    final d = DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    if (d < 0) return null;
    return (d ~/ 40 + 1, d % 40 + 1);
  }

  void startChilla(DateTime date) {
    settings.chillaStart = dayKey(date);
    saveSettings();
  }

  void stopChilla() {
    settings.chillaStart = null;
    saveSettings();
  }

  // ---------------- muhasaba / notes ----------------
  void setNote(DateTime date, String note) {
    day(date).note = note;
    _saveDay(date);
  }

  void setMuhasaba(DateTime date, String field, String value) {
    final rec = day(date);
    if (value.trim().isEmpty) {
      rec.muhasaba.remove(field);
    } else {
      rec.muhasaba[field] = value;
    }
    _saveDay(date);
  }

  // ---------------- habits ----------------
  void addHabit(String name, int target) {
    settings.habits.add(HabitGoal(newId('h'), name, target));
    saveSettings();
  }

  void deleteHabit(String id) {
    settings.habits.removeWhere((h) => h.id == id);
    saveSettings();
  }

  void changeHabit(DateTime date, String id, int delta) {
    final rec = day(date);
    rec.habits[id] = ((rec.habits[id] ?? 0) + delta).clamp(0, 100000).toInt();
    _saveDay(date);
  }

  // ---------------- sadaqah ----------------
  void addSadaqah(DateTime date, double amount, String note) {
    sadaqah.insert(0, SadaqahRecord(newId('s'), date, amount, note));
    _saveSadaqah();
  }

  void deleteSadaqah(String id) {
    sadaqah.removeWhere((e) => e.id == id);
    _saveSadaqah();
  }

  double sadaqahOn(DateTime date) =>
      sadaqah.where((e) => dayKey(e.date) == dayKey(date)).fold(0.0, (a, b) => a + b.amount);

  double sadaqahInMonth(int year, int month) => sadaqah
      .where((e) => e.date.year == year && e.date.month == month)
      .fold(0.0, (a, b) => a + b.amount);

  void _saveSadaqah() {
    prefs.setString('sadaqah', jsonEncode(sadaqah.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  // ---------------- reports ----------------
  bool _streakDay(DateTime d) => day(d).farzPrayed == 5;

  int currentStreak() {
    var d = today;
    // today counts only once it is complete; otherwise start from yesterday
    if (!_streakDay(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (n < 3650 && _streakDay(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  int bestStreak({int lookbackDays = 365}) {
    var best = 0, run = 0;
    for (var i = lookbackDays; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      if (_streakDay(d)) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    final stored = prefs.getInt('bestStreak') ?? 0;
    if (best > stored) {
      prefs.setInt('bestStreak', best);
      return best;
    }
    return stored;
  }

  /// Counts of each prayer status for the last [days] days.
  Map<PrayerStatus, int> prayerSummary(int days) {
    final m = {for (final s in PrayerStatus.values) s: 0};
    for (var i = 0; i < days; i++) {
      final rec = day(today.subtract(Duration(days: i)));
      for (final k in prayerKeys) {
        final st = rec.prayer(k);
        m[st] = m[st]! + 1;
      }
    }
    return m;
  }

  /// Days from [from] to [to] inclusive.
  List<DateTime> daysBetween(DateTime from, DateTime to) {
    final out = <DateTime>[];
    var d = DateTime(from.year, from.month, from.day);
    while (!d.isAfter(to)) {
      out.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return out;
  }

  /// Category completion (0..1) for the given days:
  /// namaz, quran, azkar (morning + evening), tahajjud, overall.
  Map<String, double> categoryStats(List<DateTime> days) {
    if (days.isEmpty) return {'namaz': 0, 'quran': 0, 'azkar': 0, 'tahajjud': 0, 'overall': 0};
    var namaz = 0.0, quran = 0.0, az = 0.0, tah = 0.0, overall = 0.0;
    final target = settings.quranTarget <= 0 ? 1 : settings.quranTarget;
    for (final d in days) {
      final rec = day(d);
      namaz += rec.farzPrayed / 5;
      quran += (rec.quranPages / target).clamp(0.0, 1.0).toDouble();
      az += ((rec.done.contains('morning_azkar') ? 1 : 0) + (rec.done.contains('evening_azkar') ? 1 : 0)) / 2;
      tah += rec.done.contains('tahajjud') ? 1 : 0;
      overall += completionRatio(d);
    }
    final n = days.length;
    return {'namaz': namaz / n, 'quran': quran / n, 'azkar': az / n, 'tahajjud': tah / n, 'overall': overall / n};
  }

  int totalDhikr(List<DateTime> days) => days.fold(0, (a, d) => a + day(d).totalDhikr);

  int totalPages(List<DateTime> days) => days.fold(0, (a, d) => a + day(d).quranPages);

  /// Most frequently missed routine items over the last [days] days
  /// (only days on which the user recorded something).
  List<MapEntry<RoutineItem, int>> mostMissed(int days) {
    final counts = <String, int>{};
    for (var i = 1; i <= days; i++) {
      final d = today.subtract(Duration(days: i));
      if (!hasRecord(d)) continue;
      for (final item in routineFor(d)) {
        if (item.optional || isSkipped(d, item)) continue;
        if (!isDone(d, item)) counts[item.id] = (counts[item.id] ?? 0) + 1;
      }
    }
    final byId = {for (final i in allItems) i.id: i};
    final list = counts.entries
        .where((e) => byId.containsKey(e.key))
        .map((e) => MapEntry(byId[e.key]!, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(5).toList();
  }

  /// Missed (not done, not skipped, not optional) items per day, newest first.
  List<MapEntry<DateTime, List<RoutineItem>>> missedHistory(int days) {
    final out = <MapEntry<DateTime, List<RoutineItem>>>[];
    for (var i = 1; i <= days; i++) {
      final d = today.subtract(Duration(days: i));
      if (!hasRecord(d)) continue;
      final missed = routineFor(d).where((it) => !it.optional && !isSkipped(d, it) && !isDone(d, it)).toList();
      if (missed.isNotEmpty) out.add(MapEntry(d, missed));
    }
    return out;
  }

  // ---------------- backup / restore ----------------
  static const backupVersion = 3;

  Map<String, dynamic> exportData() {
    final data = <String, dynamic>{};
    for (final k in prefs.getKeys()) {
      data[k] = prefs.get(k);
    }
    return {
      'app': 'dailydeen',
      'version': backupVersion,
      'created': DateTime.now().toIso8601String(),
      'data': data,
    };
  }

  /// Checks a backup without touching local data. Returns null when valid,
  /// otherwise a short reason.
  static String? validateBackup(Map<String, dynamic> backup) {
    if (backup['app'] != 'dailydeen') return 'not a Daily Deen backup';
    final v = backup['version'];
    if (v is! int || v < 1 || v > backupVersion) return 'unsupported backup version';
    final data = backup['data'];
    if (data is! Map) return 'missing data';
    for (final e in data.entries) {
      final val = e.value;
      if (e.key is! String) return 'invalid key';
      if (val is! bool && val is! num && val is! String && val is! List) return 'invalid value for ${e.key}';
      if (e.key == 'settings') {
        try {
          AppSettings.fromJson(jsonDecode(val as String) as Map<String, dynamic>);
        } catch (_) {
          return 'invalid settings';
        }
      }
      if ((e.key as String).startsWith('day_')) {
        try {
          DayRecord.fromJson(jsonDecode(val as String) as Map<String, dynamic>);
        } catch (_) {
          return 'invalid record ${e.key}';
        }
      }
    }
    return null;
  }

  Future<void> _writeAll(Map<String, dynamic> data) async {
    await prefs.clear();
    for (final e in data.entries) {
      final v = e.value;
      bool ok;
      if (v is bool) {
        ok = await prefs.setBool(e.key, v);
      } else if (v is int) {
        ok = await prefs.setInt(e.key, v);
      } else if (v is double) {
        ok = await prefs.setDouble(e.key, v);
      } else if (v is String) {
        ok = await prefs.setString(e.key, v);
      } else if (v is List) {
        ok = await prefs.setStringList(e.key, v.map((x) => x.toString()).toList());
      } else {
        ok = true;
      }
      if (!ok) throw StateError('write failed for ${e.key}');
    }
  }

  /// Restores [backup] safely:
  /// 1. validates it (nothing is touched if invalid),
  /// 2. keeps an in-memory copy of the current data,
  /// 3. writes the backup and verifies every key,
  /// 4. rolls back to the previous data if anything fails.
  /// Returns null on success, otherwise the reason.
  Future<String?> importDataSafe(Map<String, dynamic> backup) async {
    final problem = validateBackup(backup);
    if (problem != null) return problem;
    await flush();
    final data = Map<String, dynamic>.from(backup['data'] as Map);
    final previous = <String, dynamic>{for (final k in prefs.getKeys()) k: prefs.get(k)};
    try {
      await _writeAll(data);
      for (final k in data.keys) {
        if (!prefs.containsKey(k)) throw StateError('verification failed for $k');
      }
    } catch (e) {
      try {
        await _writeAll(previous);
      } catch (_) {}
      _loadAll();
      notifyListeners();
      return 'restore failed: $e';
    }
    _loadAll();
    notifyListeners();
    onScheduleChanged?.call(this);
    return null;
  }

  /// Compatibility wrapper. Returns true on success.
  Future<bool> importData(Map<String, dynamic> backup) async => (await importDataSafe(backup)) == null;
}

/// Completion state of a single activity (see [AppState.snapshotOf]).
class CompletionSnapshot {
  final String id;
  final bool inDone;
  final bool skipped;
  final String? at;
  final String? prayerKey;
  final PrayerStatus? prayer;
  const CompletionSnapshot({
    required this.id,
    required this.inDone,
    required this.skipped,
    this.at,
    this.prayerKey,
    this.prayer,
  });
}

/// An activity placed on the timeline for a given date.
class ScheduledActivity {
  final RoutineItem item;
  final DateTime date;
  final ActivityWindow window;
  final ActivityState state;
  const ScheduledActivity(this.item, this.date, this.window, this.state);

  bool get isOpen => state == ActivityState.active || state == ActivityState.inProgress;
}

/// Makes [AppState] available to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Reads the state without listening (usable in initState).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}

/// A routine surah task opened in the Quran reader (see [AppState.readingTask]).
class ReadingTask {
  final String id; // routine item id
  final int surah, ayah; // where the task starts
  const ReadingTask(this.id, this.surah, this.ayah);
}
