import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/cities.dart';
import 'data/routine.dart';
import 'services/prayer_times.dart';
import 'strings.dart';

enum PrayerStatus { none, alone, jamaat, qaza, missed }

bool isPrayed(PrayerStatus s) => s == PrayerStatus.alone || s == PrayerStatus.jamaat || s == PrayerStatus.qaza;

/// Everything recorded for one calendar day.
class DayRecord {
  final Set<String> done;
  final Map<String, PrayerStatus> prayers;
  final Set<String> sunnah;
  int quranPages;
  final Map<String, int> dhikr;
  final Map<String, int> azkar;
  String note;

  DayRecord({
    Set<String>? done,
    Map<String, PrayerStatus>? prayers,
    Set<String>? sunnah,
    this.quranPages = 0,
    Map<String, int>? dhikr,
    Map<String, int>? azkar,
    this.note = '',
  })  : done = done ?? <String>{},
        prayers = prayers ?? <String, PrayerStatus>{},
        sunnah = sunnah ?? <String>{},
        dhikr = dhikr ?? <String, int>{},
        azkar = azkar ?? <String, int>{};

  PrayerStatus prayer(String key) => prayers[key] ?? PrayerStatus.none;

  int get farzPrayed => prayerKeys.where((k) => isPrayed(prayer(k))).length;

  Map<String, dynamic> toJson() => {
        'done': done.toList(),
        'prayers': prayers.map((k, v) => MapEntry(k, v.index)),
        'sunnah': sunnah.toList(),
        'quran': quranPages,
        'dhikr': dhikr,
        'azkar': azkar,
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
    return DayRecord(
      done: ((j['done'] as List?) ?? []).map((e) => e.toString()).toSet(),
      prayers: p,
      sunnah: ((j['sunnah'] as List?) ?? []).map((e) => e.toString()).toSet(),
      quranPages: (j['quran'] as num?)?.toInt() ?? 0,
      dhikr: ints(j['dhikr']),
      azkar: ints(j['azkar']),
      note: (j['note'] as String?) ?? '',
    );
  }
}

class AppSettings {
  bool urdu;
  ThemeMode themeMode;
  int cityIndex;
  CalcMethod method;
  bool hanafiAsr;
  int hijriAdjust;
  bool notifications;
  bool tahajjudReminder;
  int wakeMinutes; // minutes after midnight, default 4:00 AM
  int quranTarget;
  Set<String> disabledItems;
  List<RoutineItem> customItems;
  bool onboarded;

  AppSettings({
    this.urdu = false,
    this.themeMode = ThemeMode.system,
    this.cityIndex = 0,
    this.method = CalcMethod.karachi,
    this.hanafiAsr = true,
    this.hijriAdjust = 0,
    this.notifications = true,
    this.tahajjudReminder = true,
    this.wakeMinutes = 240,
    this.quranTarget = 4,
    Set<String>? disabledItems,
    List<RoutineItem>? customItems,
    this.onboarded = false,
  })  : disabledItems = disabledItems ?? <String>{},
        customItems = customItems ?? <RoutineItem>[];

  City get city => cities[cityIndex.clamp(0, cities.length - 1).toInt()];

  Map<String, dynamic> toJson() => {
        'urdu': urdu,
        'theme': themeMode.index,
        'city': cityIndex,
        'method': method.index,
        'hanafi': hanafiAsr,
        'hijriAdjust': hijriAdjust,
        'notifications': notifications,
        'tahajjud': tahajjudReminder,
        'wake': wakeMinutes,
        'quranTarget': quranTarget,
        'disabled': disabledItems.toList(),
        'custom': customItems.map((e) => e.toJson()).toList(),
        'onboarded': onboarded,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    int idx(String k, int len, int def) {
      final v = (j[k] as num?)?.toInt() ?? def;
      return (v >= 0 && v < len) ? v : def;
    }

    return AppSettings(
      urdu: j['urdu'] as bool? ?? false,
      themeMode: ThemeMode.values[idx('theme', ThemeMode.values.length, 0)],
      cityIndex: idx('city', cities.length, 0),
      method: CalcMethod.values[idx('method', CalcMethod.values.length, 0)],
      hanafiAsr: j['hanafi'] as bool? ?? true,
      hijriAdjust: (j['hijriAdjust'] as num?)?.toInt() ?? 0,
      notifications: j['notifications'] as bool? ?? true,
      tahajjudReminder: j['tahajjud'] as bool? ?? true,
      wakeMinutes: (j['wake'] as num?)?.toInt() ?? 240,
      quranTarget: (j['quranTarget'] as num?)?.toInt() ?? 4,
      disabledItems: ((j['disabled'] as List?) ?? []).map((e) => e.toString()).toSet(),
      customItems: ((j['custom'] as List?) ?? [])
          .map((e) => RoutineItem.customFromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      onboarded: j['onboarded'] as bool? ?? false,
    );
  }
}

const int quranTotalPages = 604;

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
  int qazaPending = 0;

  AppState(this.prefs) {
    final raw = prefs.getString('settings');
    settings = raw == null ? AppSettings() : AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    khatamPages = prefs.getInt('khatamPages') ?? 0;
    khatamCount = prefs.getInt('khatamCount') ?? 0;
    juzDone = (prefs.getStringList('juzDone') ?? []).map(int.parse).toSet();
    qazaPending = prefs.getInt('qazaPending') ?? 0;
  }

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppState(prefs);
  }

  S get s => S(settings.urdu);

  PrayerCalculator get calculator => PrayerCalculator(
        lat: settings.city.lat,
        lng: settings.city.lng,
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
    final rec = raw == null ? DayRecord() : DayRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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

  // ---------------- routine ----------------
  List<RoutineItem> get allItems => [...defaultRoutine, ...settings.customItems];

  List<RoutineItem> routineFor(DateTime date) {
    final friday = date.weekday == DateTime.friday;
    return allItems
        .where((i) => !settings.disabledItems.contains(i.id))
        .where((i) => !i.fridayOnly || friday)
        .toList();
  }

  bool isDone(DateTime date, RoutineItem item) {
    final rec = day(date);
    if (item.prayerKey != null) return isPrayed(rec.prayer(item.prayerKey!));
    return rec.done.contains(item.id);
  }

  void toggleItem(DateTime date, RoutineItem item) {
    final rec = day(date);
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
    } else {
      rec.done.remove(id);
    }
    _saveDay(date);
  }

  /// Returns (done, total) for the given day.
  (int, int) completion(DateTime date) {
    final items = routineFor(date);
    final done = items.where((i) => isDone(date, i)).length;
    return (done, items.length);
  }

  double completionRatio(DateTime date) {
    final (d, t) = completion(date);
    return t == 0 ? 0 : d / t;
  }

  // ---------------- prayers ----------------
  void setPrayer(DateTime date, String key, PrayerStatus status) {
    day(date).prayers[key] = status;
    _saveDay(date);
  }

  void toggleSunnah(DateTime date, String key) {
    final rec = day(date);
    if (!rec.sunnah.remove(key)) rec.sunnah.add(key);
    _saveDay(date);
  }

  void changeQaza(int delta) {
    qazaPending = (qazaPending + delta).clamp(0, 100000).toInt();
    prefs.setInt('qazaPending', qazaPending);
    notifyListeners();
  }

  // ---------------- dhikr / azkar ----------------
  void incrementDhikr(DateTime date, String key, {int by = 1}) {
    final rec = day(date);
    final v = (rec.dhikr[key] ?? 0) + by;
    rec.dhikr[key] = v;
    for (final item in allItems) {
      if (item.dhikrKey == key && v >= item.dhikrTarget) rec.done.add(item.id);
    }
    _saveDay(date);
  }

  void resetDhikr(DateTime date, String key) {
    day(date).dhikr[key] = 0;
    _saveDay(date);
  }

  int azkarCount(DateTime date, String key) => day(date).azkar[key] ?? 0;

  void setAzkarCount(DateTime date, String key, int value) {
    day(date).azkar[key] = value;
    _saveDay(date);
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
    }
    if (rec.quranPages >= settings.quranTarget) {
      rec.done.add('quran_daily');
    } else {
      rec.done.remove('quran_daily');
    }
    _saveQuran();
    _saveDay(date);
  }

  void toggleJuz(int juz) {
    if (!juzDone.remove(juz)) juzDone.add(juz);
    _saveQuran();
    notifyListeners();
  }

  void resetKhatam() {
    khatamPages = 0;
    juzDone.clear();
    _saveQuran();
    notifyListeners();
  }

  void _saveQuran() {
    prefs.setInt('khatamPages', khatamPages);
    prefs.setInt('khatamCount', khatamCount);
    prefs.setStringList('juzDone', juzDone.map((e) => e.toString()).toList());
  }

  void setNote(DateTime date, String note) {
    day(date).note = note;
    _saveDay(date);
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

  /// Most frequently missed routine items over the last [days] days
  /// (only days on which the user recorded something).
  List<MapEntry<RoutineItem, int>> mostMissed(int days) {
    final counts = <String, int>{};
    for (var i = 1; i <= days; i++) {
      final d = today.subtract(Duration(days: i));
      if (!hasRecord(d)) continue;
      for (final item in routineFor(d)) {
        if (item.optional) continue;
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

  // ---------------- settings helpers ----------------
  void addCustomItem(String name, String target, RoutineSection section) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    settings.customItems.add(RoutineItem(
      id: id,
      en: name,
      ur: name,
      section: section,
      targetEn: target,
      targetUr: target,
      custom: true,
    ));
    saveSettings();
  }

  void removeCustomItem(String id) {
    settings.customItems.removeWhere((e) => e.id == id);
    saveSettings();
  }

  void setItemEnabled(String id, bool enabled) {
    if (enabled) {
      settings.disabledItems.remove(id);
    } else {
      settings.disabledItems.add(id);
    }
    saveSettings();
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
