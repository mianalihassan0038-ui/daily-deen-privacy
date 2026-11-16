import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/cities.dart';
import 'data/routine.dart';
import 'services/prayer_times.dart';
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
    this.note = '',
  })  : done = done ?? <String>{},
        skipped = skipped ?? <String>{},
        prayers = prayers ?? <String, PrayerStatus>{},
        sunnah = sunnah ?? <String>{},
        dhikr = dhikr ?? <String, int>{},
        azkar = azkar ?? <String, int>{},
        habits = habits ?? <String, int>{},
        muhasaba = muhasaba ?? <String, String>{};

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

  // ---- notifications ----
  bool notifications; // master switch
  bool tahajjudReminder; // legacy, mirrors notif['tahajjud']
  Map<String, bool> notif;
  int prayerReminderBefore; // minutes before prayer time (0 = at the time)
  bool notifVibrate;
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
  double arabicSize;

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
    this.notifications = true,
    this.tahajjudReminder = true,
    Map<String, bool>? notif,
    this.prayerReminderBefore = 0,
    this.notifVibrate = true,
    this.snoozeMinutes = 10,
    this.wakeMinutes = 240,
    this.quranReminderMinutes = 1200,
    this.sleepMinutes = 1320,
    this.azkarAfterMinutes = 30,
    this.quranTarget = 4,
    this.showUrdu = true,
    this.showEnglish = true,
    this.showTranslit = false,
    this.arabicSize = 26,
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
  })  : prayerOffsets = prayerOffsets ?? <String, int>{},
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
        'notifications': notifications,
        'tahajjud': notif['tahajjud'] ?? tahajjudReminder,
        'notif': notif,
        'before': prayerReminderBefore,
        'vibrate': notifVibrate,
        'snooze': snoozeMinutes,
        'wake': wakeMinutes,
        'quranRemind': quranReminderMinutes,
        'sleep': sleepMinutes,
        'azkarAfter': azkarAfterMinutes,
        'quranTarget': quranTarget,
        'showUr': showUrdu,
        'showEn': showEnglish,
        'showTr': showTranslit,
        'arSize': arabicSize,
        'tVibrate': tasbeehVibrate,
        'tSound': tasbeehSound,
        'tAwake': tasbeehKeepAwake,
        'tTargets': tasbeehTargets,
        'tCustom': customDhikr.map((e) => e.toJson()).toList(),
        'routine': routine.map((e) => e.toJson()).toList(),
        'templates': routineTemplates.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
        'favAzkar': favAzkar.toList(),
        'habits': habits.map((e) => e.toJson()).toList(),
        'sadaqahGoal': sadaqahGoal,
        'currency': currency,
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
      notifications: boolOr('notifications', true),
      tahajjudReminder: tahajjud,
      notif: notif,
      prayerReminderBefore: intOr('before', 0),
      notifVibrate: boolOr('vibrate', true),
      snoozeMinutes: intOr('snooze', 10),
      wakeMinutes: intOr('wake', 240),
      quranReminderMinutes: intOr('quranRemind', 1200),
      sleepMinutes: intOr('sleep', 1320),
      azkarAfterMinutes: intOr('azkarAfter', 30),
      quranTarget: intOr('quranTarget', 4),
      showUrdu: boolOr('showUr', true),
      showEnglish: boolOr('showEn', true),
      showTranslit: boolOr('showTr', false),
      arabicSize: dblOr('arSize', 26),
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
    );
  }
}

const int quranTotalPages = 604;

int _idCounter = 0;

/// Unique id for user-created records (time + counter, never repeats in a session).
String newId(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  late AppSettings settings;
  final Map<String, DayRecord> _cache = {};

  /// Called whenever settings that affect notifications change.
  void Function(AppState state)? onScheduleChanged;

  // Quran khatam data
  int khatamPages = 0;
  int khatamCount = 0;
  Set<int> juzDone = {};
  Set<int> readPages = {};
  int qazaPending = 0;
  QuranRef? lastRead;
  List<QuranRef> bookmarks = [];
  List<QuranRef> favouriteAyat = [];
  List<Map<String, dynamic>> readingHistory = [];

  List<SadaqahRecord> sadaqah = [];

  AppState(this.prefs) {
    _loadAll();
  }

  void _loadAll() {
    _cache.clear();
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
    bookmarks = (prefs.getStringList('bookmarks') ?? []).map(QuranRef.parse).whereType<QuranRef>().toList();
    favouriteAyat = (prefs.getStringList('favAyat') ?? []).map(QuranRef.parse).whereType<QuranRef>().toList();
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
  void saveSettings({bool reschedule = false}) {
    prefs.setString('settings', jsonEncode(settings.toJson()));
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

  bool hasRecord(DateTime date) => prefs.containsKey('day_${dayKey(date)}');

  void _saveDay(DateTime date) {
    final key = dayKey(date);
    final rec = _cache[key];
    if (rec != null) prefs.setString('day_$key', jsonEncode(rec.toJson()));
    notifyListeners();
  }

  DateTime get today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ---------------- prayer times ----------------
  /// Calculated prayer times with the user's manual adjustments applied.
  DayPrayerTimes prayerTimes(DateTime date) {
    final raw = calculator.forDate(date);
    return DayPrayerTimes({
      for (final p in PrayerName.values)
        p: raw[p].add(Duration(minutes: settings.prayerOffsets[p.name] ?? 0)),
    });
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

  bool isDone(DateTime date, RoutineItem item) {
    final rec = day(date);
    if (item.prayerKey != null) return isPrayed(rec.prayer(item.prayerKey!));
    return rec.done.contains(item.id);
  }

  bool isSkipped(DateTime date, RoutineItem item) => day(date).skipped.contains(item.id);

  void toggleItem(DateTime date, RoutineItem item) {
    final rec = day(date);
    rec.skipped.remove(item.id);
    if (item.prayerKey != null) {
      final current = rec.prayer(item.prayerKey!);
      rec.prayers[item.prayerKey!] = isPrayed(current) ? PrayerStatus.none : PrayerStatus.alone;
    } else if (rec.done.contains(item.id)) {
      rec.done.remove(item.id);
    } else {
      rec.done.add(item.id);
    }
    _saveDay(date);
  }

  void setDone(DateTime date, String id, bool value) {
    final rec = day(date);
    if (value) {
      rec.done.add(id);
      rec.skipped.remove(id);
    } else {
      rec.done.remove(id);
    }
    _saveDay(date);
  }

  void toggleSkip(DateTime date, RoutineItem item) {
    final rec = day(date);
    if (!rec.skipped.remove(item.id)) {
      rec.skipped.add(item.id);
      rec.done.remove(item.id);
    }
    _saveDay(date);
  }

  /// Returns (done, total) for the given day. Skipped items are not counted.
  (int, int) completion(DateTime date) {
    final items = routineFor(date).where((i) => !isSkipped(date, i)).toList();
    final done = items.where((i) => isDone(date, i)).length;
    return (done, items.length);
  }

  double completionRatio(DateTime date) {
    final (d, t) = completion(date);
    return t == 0 ? 0 : d / t;
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
  void setPrayer(DateTime date, String key, PrayerStatus status) {
    day(date).prayers[key] = status;
    _saveDay(date);
  }

  void toggleSunnah(DateTime date, String key) {
    final rec = day(date);
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

  void setDhikrTarget(String key, int target) {
    settings.tasbeehTargets[key] = target.clamp(1, 100000).toInt();
    saveSettings();
  }

  void incrementDhikr(DateTime date, String key, {int by = 1}) {
    final rec = day(date);
    final v = ((rec.dhikr[key] ?? 0) + by).clamp(0, 10000000).toInt();
    rec.dhikr[key] = v;
    for (final item in allItems) {
      if (item.dhikrKey == key && item.dhikrTarget > 0) {
        if (v >= item.dhikrTarget) {
          rec.done.add(item.id);
        } else if (by < 0) {
          rec.done.remove(item.id);
        }
      }
    }
    _saveDay(date);
  }

  void resetDhikr(DateTime date, String key) {
    day(date).dhikr[key] = 0;
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
    if (rec.quranPages >= settings.quranTarget) {
      rec.done.add('quran_daily');
    } else {
      rec.done.remove('quran_daily');
    }
    _saveQuran();
    _saveDay(date);
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

  void resetKhatam() {
    khatamPages = 0;
    juzDone.clear();
    readPages.clear();
    _saveQuran();
    notifyListeners();
  }

  void setLastRead(int surah, int ayah) {
    final ref = QuranRef(surah, ayah);
    if (lastRead == ref) return;
    lastRead = ref;
    prefs.setString('lastRead', ref.key);
    final todayKey = dayKey(today);
    readingHistory.removeWhere((e) => e['d'] == todayKey && e['s'] == surah);
    readingHistory.insert(0, {'d': todayKey, 's': surah, 'a': ayah});
    if (readingHistory.length > 60) readingHistory = readingHistory.sublist(0, 60);
    prefs.setString('readHistory', jsonEncode(readingHistory));
    notifyListeners();
  }

  bool isBookmarked(int s, int a) => bookmarks.contains(QuranRef(s, a));
  bool isFavouriteAyah(int s, int a) => favouriteAyat.contains(QuranRef(s, a));

  void toggleBookmark(int s, int a) {
    final r = QuranRef(s, a);
    if (!bookmarks.remove(r)) bookmarks.insert(0, r);
    prefs.setStringList('bookmarks', bookmarks.map((e) => e.key).toList());
    notifyListeners();
  }

  void toggleFavouriteAyah(int s, int a) {
    final r = QuranRef(s, a);
    if (!favouriteAyat.remove(r)) favouriteAyat.insert(0, r);
    prefs.setStringList('favAyat', favouriteAyat.map((e) => e.key).toList());
    notifyListeners();
  }

  void _saveQuran() {
    prefs.setInt('khatamPages', khatamPages);
    prefs.setInt('khatamCount', khatamCount);
    prefs.setStringList('juzDone', juzDone.map((e) => e.toString()).toList());
    prefs.setStringList('readPages', readPages.map((e) => e.toString()).toList());
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
  static const _backupVersion = 2;

  Map<String, dynamic> exportData() {
    final data = <String, dynamic>{};
    for (final k in prefs.getKeys()) {
      data[k] = prefs.get(k);
    }
    return {'app': 'dailydeen', 'version': _backupVersion, 'created': DateTime.now().toIso8601String(), 'data': data};
  }

  /// Replaces all local data with [backup]. Returns false if the file is invalid.
  Future<bool> importData(Map<String, dynamic> backup) async {
    if (backup['app'] != 'dailydeen' || backup['data'] is! Map) return false;
    final data = Map<String, dynamic>.from(backup['data'] as Map);
    await prefs.clear();
    for (final e in data.entries) {
      final v = e.value;
      if (v is bool) {
        await prefs.setBool(e.key, v);
      } else if (v is int) {
        await prefs.setInt(e.key, v);
      } else if (v is double) {
        await prefs.setDouble(e.key, v);
      } else if (v is String) {
        await prefs.setString(e.key, v);
      } else if (v is List) {
        await prefs.setStringList(e.key, v.map((x) => x.toString()).toList());
      }
    }
    _loadAll();
    notifyListeners();
    onScheduleChanged?.call(this);
    return true;
  }
}

/// Makes [AppState] available to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
