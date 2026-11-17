import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../app_state.dart';
import '../data/routine.dart';
import 'prayer_times.dart';

const _snoozeAction = 'snooze';

AndroidNotificationDetails _androidDetails({
  required bool prayer,
  required bool vibrate,
  String? snoozeLabel,
}) {
  final id = '${prayer ? 'prayer_times' : 'reminders'}${vibrate ? '' : '_silent_vibe'}';
  return AndroidNotificationDetails(
    id,
    prayer ? 'Prayer times' : 'Worship reminders',
    channelDescription: prayer ? 'Reminders for the five daily prayers' : 'Tahajjud, Quran, Azkar and routine reminders',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: vibrate,
    category: AndroidNotificationCategory.reminder,
    actions: snoozeLabel == null
        ? null
        : [AndroidNotificationAction(_snoozeAction, snoozeLabel, cancelNotification: true)],
  );
}

/// Handles the "Snooze" button when the app is in the background.
@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  await NotificationService.handleSnooze(response, FlutterLocalNotificationsPlugin(), initialise: true);
}

/// Schedules local prayer-time and worship reminders (no internet needed).
/// Scheduled alarms survive reboots via the plugin's boot receiver, and the
/// app re-schedules the next 7 days every time it starts or settings change.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _init = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));

  Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        _init,
        onDidReceiveNotificationResponse: (r) => handleSnooze(r, _plugin),
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  static Future<void> handleSnooze(NotificationResponse r, FlutterLocalNotificationsPlugin plugin, {bool initialise = false}) async {
    if (r.actionId != _snoozeAction || r.payload == null) return;
    try {
      if (initialise) await plugin.initialize(_init);
      final p = jsonDecode(r.payload!) as Map<String, dynamic>;
      final minutes = (p['z'] as num?)?.toInt() ?? 10;
      final when = DateTime.now().toUtc().add(Duration(minutes: minutes));
      await plugin.zonedSchedule(
        9000 + DateTime.now().millisecondsSinceEpoch % 900,
        p['t'] as String?,
        p['b'] as String?,
        tz.TZDateTime.from(when, tz.UTC),
        NotificationDetails(
          android: _androidDetails(prayer: p['p'] == true, vibrate: p['v'] != false, snoozeLabel: p['l'] as String?),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: r.payload,
      );
    } catch (e) {
      debugPrint('Snooze failed: $e');
    }
  }

  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  /// Whether exact alarms may be scheduled (Android 12+ special permission).
  Future<bool> canScheduleExact() async {
    if (!_ready) return false;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.canScheduleExactNotifications() ??
          false;
    } catch (e) {
      debugPrint('Exact alarm check failed: $e');
      return false;
    }
  }

  /// Opens the system screen to allow exact alarms. Returns the result.
  Future<bool> requestExactAlarms() async {
    if (!_ready) return false;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestExactAlarmsPermission() ??
          false;
    } catch (e) {
      debugPrint('Exact alarm request failed: $e');
      return false;
    }
  }

  bool _exact = false;

  /// Number of reminders that failed to schedule in the last run.
  int lastFailures = 0;

  Future<void> showTest(AppState state) async {
    if (!_ready) return;
    final s = state.s;
    try {
      await _plugin.show(
        9999,
        s.t('app_name'),
        s.t('test_notification_body'),
        NotificationDetails(android: _androidDetails(prayer: false, vibrate: state.settings.notifVibrate)),
      );
    } catch (e) {
      debugPrint('Test notification failed: $e');
    }
  }

  Future<void> _schedule(
    AppState state,
    int id,
    String title,
    String body,
    DateTime when, {
    required bool prayer,
  }) async {
    final st = state.settings;
    final snoozeLabel = '${state.s.t('snooze')} ${st.snoozeMinutes} ${state.s.t('min_short')}';
    final payload = jsonEncode({
      't': title,
      'b': body,
      'p': prayer,
      'v': st.notifVibrate,
      'z': st.snoozeMinutes,
      'l': snoozeLabel,
    });
    // Each reminder is isolated: one failure never stops the rest.
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when.toUtc(), tz.UTC),
        NotificationDetails(android: _androidDetails(prayer: prayer, vibrate: st.notifVibrate, snoozeLabel: snoozeLabel)),
        androidScheduleMode: _exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      lastFailures++;
      debugPrint('Reminder $id failed: $e');
    }
  }

  /// Cancels everything and schedules the next 7 days.
  Future<void> _chain = Future.value();

  /// Cancels everything and schedules the next 7 days. Calls are serialised,
  /// so overlapping triggers (resume + settings change + boot) can never
  /// leave duplicate reminders behind.
  Future<void> reschedule(AppState state) {
    _chain = _chain.then((_) => _reschedule(state)).catchError((Object e) {
      debugPrint('Scheduling failed: $e');
    });
    return _chain;
  }

  Future<void> _reschedule(AppState state) async {
    if (!_ready) return;
    await _plugin.cancelAll(); // also removes obsolete reminders
    final st = state.settings;
    lastFailures = 0;
    if (!st.notifications) return;
    _exact = st.exactAlarms && await canScheduleExact();
    for (final r in plan(state)) {
      await _schedule(state, r.id, r.title, r.body, r.when, prayer: r.prayer);
    }
  }

  /// Every reminder for the next [days] days, computed from the schedule
  /// engine (pure: no plugin calls, so it is unit-tested). Ids are unique and
  /// two reminders with the same title at the same minute are never planned.
  static List<PlannedReminder> plan(AppState state, {DateTime? now, int days = 7}) {
    final st = state.settings;
    final out = <PlannedReminder>[];
    if (!st.notifications) return out;
    final s = state.s;
    final t = now ?? clock();
    final nowUtc = t.toUtc();
    final seen = <String>{};
    final ids = <int>{};
    void add(int id, String title, String body, DateTime when, {bool prayer = false}) {
      if (!when.toUtc().isAfter(nowUtc)) return;
      final key = '$title|${when.toUtc().millisecondsSinceEpoch ~/ 60000}';
      if (!seen.add(key) || !ids.add(id)) return;
      out.add(PlannedReminder(id, title, body, when, prayer));
    }

    const prayers = [PrayerName.fajr, PrayerName.dhuhr, PrayerName.asr, PrayerName.maghrib, PrayerName.isha];
    const ownReminder = {'morning_azkar', 'evening_azkar', 'sleep_azkar'};
    for (var offset = 0; offset < days; offset++) {
      final date = DateTime(t.year, t.month, t.day + offset);
      final times = state.prayerTimes(date);

      for (var i = 0; i < prayers.length; i++) {
        final key = prayers[i].name;
        if (!st.notifOn(key)) continue;
        final name = s.t(key);
        final title = st.prayerReminderBefore > 0
            ? '$name ${s.t('in')} ${st.prayerReminderBefore} ${s.t('min_short')}'
            : '${s.t('notif_title')} $name';
        add(offset * 100 + i, title, s.t('notif_body'),
            times[prayers[i]].subtract(Duration(minutes: st.prayerReminderBefore)), prayer: true);
      }

      void at(int base, String key, DateTime when, String title, String body) {
        if (st.notifOn(key)) add(base + offset, title, body, when);
      }

      at(1000, 'tahajjud', date.add(Duration(minutes: st.wakeMinutes)), s.t('tahajjud_notif'), s.t('tahajjud_body'));
      at(1100, 'quran', date.add(Duration(minutes: st.quranReminderMinutes)), s.t('quran_notif'), s.t('quran_notif_body'));

      // Azkar: a user schedule (after prayer / fixed / window) is used when
      // set; otherwise the previous defaults are kept.
      final routine = state.routineFor(date);
      DateTime azkarAt(String id, DateTime fallback) {
        final it = routine.where((e) => e.id == id).firstOrNull;
        return it != null && it.anchor != null ? state.windowOf(it, date).start : fallback;
      }

      at(1200, 'morning_azkar',
          azkarAt('morning_azkar', times[PrayerName.fajr].toLocal().add(Duration(minutes: st.azkarAfterMinutes))),
          s.t('morning_azkar'), s.t('azkar_notif_body'));
      at(1300, 'evening_azkar',
          azkarAt('evening_azkar', times[PrayerName.asr].toLocal().add(Duration(minutes: st.azkarAfterMinutes))),
          s.t('evening_azkar'), s.t('azkar_notif_body'));
      at(1400, 'sleep_azkar', azkarAt('sleep_azkar', date.add(Duration(minutes: st.sleepMinutes))), s.t('sleep_azkar'),
          s.t('sleep_notif_body'));

      if (st.notifOn('routine')) {
        final items = routine
            .where((it) => it.reminder && it.prayerKey == null && !ownReminder.contains(it.id))
            .take(90)
            .toList();
        for (var j = 0; j < items.length; j++) {
          final RoutineItem it = items[j];
          add(2000 + offset * 100 + j, it.name(st.urdu),
              it.target(st.urdu).isEmpty ? s.t('routine_notif_body') : it.target(st.urdu), state.windowOf(it, date).start);
        }
      }
    }
    return out;
  }
}

/// A reminder computed by [NotificationService.plan].
class PlannedReminder {
  final int id;
  final String title;
  final String body;
  final DateTime when;
  final bool prayer;
  const PlannedReminder(this.id, this.title, this.body, this.when, this.prayer);
}
