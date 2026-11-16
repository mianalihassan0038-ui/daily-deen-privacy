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
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when.toUtc(), tz.UTC),
      NotificationDetails(android: _androidDetails(prayer: prayer, vibrate: st.notifVibrate, snoozeLabel: snoozeLabel)),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancels everything and schedules the next 7 days.
  Future<void> reschedule(AppState state) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final st = state.settings;
      if (!st.notifications) return;
      final s = state.s;
      final now = DateTime.now();
      final nowUtc = now.toUtc();
      const prayers = [PrayerName.fajr, PrayerName.dhuhr, PrayerName.asr, PrayerName.maghrib, PrayerName.isha];

      for (var offset = 0; offset < 7; offset++) {
        final date = DateTime(now.year, now.month, now.day + offset);
        final times = state.prayerTimes(date);

        for (var i = 0; i < prayers.length; i++) {
          final key = prayers[i].name;
          if (!st.notifOn(key)) continue;
          final when = times[prayers[i]].subtract(Duration(minutes: st.prayerReminderBefore));
          if (!when.isAfter(nowUtc)) continue;
          final name = s.t(key);
          final title = st.prayerReminderBefore > 0
              ? '$name ${s.t('in')} ${st.prayerReminderBefore} ${s.t('min_short')}'
              : '${s.t('notif_title')} $name';
          await _schedule(state, offset * 100 + i, title, s.t('notif_body'), when, prayer: true);
        }

        Future<void> at(int base, String key, DateTime when, String title, String body) async {
          if (!st.notifOn(key) || !when.toUtc().isAfter(nowUtc)) return;
          await _schedule(state, base + offset, title, body, when, prayer: false);
        }

        await at(1000, 'tahajjud', date.add(Duration(minutes: st.wakeMinutes)), s.t('tahajjud_notif'), s.t('tahajjud_body'));
        await at(1100, 'quran', date.add(Duration(minutes: st.quranReminderMinutes)), s.t('quran_notif'), s.t('quran_notif_body'));
        await at(1200, 'morning_azkar', times[PrayerName.fajr].toLocal().add(Duration(minutes: st.azkarAfterMinutes)),
            s.t('morning_azkar'), s.t('azkar_notif_body'));
        await at(1300, 'evening_azkar', times[PrayerName.asr].toLocal().add(Duration(minutes: st.azkarAfterMinutes)),
            s.t('evening_azkar'), s.t('azkar_notif_body'));
        await at(1400, 'sleep_azkar', date.add(Duration(minutes: st.sleepMinutes)), s.t('sleep_azkar'), s.t('sleep_notif_body'));

        if (st.notifOn('routine')) {
          final items = state.routineFor(date).where((it) => it.reminder && it.timeMinutes != null).take(90).toList();
          for (var j = 0; j < items.length; j++) {
            final RoutineItem it = items[j];
            final when = date.add(Duration(minutes: it.timeMinutes!));
            if (!when.toUtc().isAfter(nowUtc)) continue;
            await _schedule(
              state,
              2000 + offset * 100 + j,
              it.name(st.urdu),
              it.target(st.urdu).isEmpty ? s.t('routine_notif_body') : it.target(st.urdu),
              when,
              prayer: false,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Scheduling failed: $e');
    }
  }
}
