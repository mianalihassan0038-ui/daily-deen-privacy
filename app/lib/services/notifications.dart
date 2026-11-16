import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../app_state.dart';
import 'prayer_times.dart';

/// Schedules local prayer-time and Tahajjud reminders (no internet needed).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
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

  static const _prayerDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_times',
      'Prayer times',
      channelDescription: 'Reminders when a prayer time begins',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  static const _tahajjudDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'tahajjud',
      'Tahajjud reminder',
      channelDescription: 'Daily wake-up reminder for Tahajjud',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> reschedule(AppState state) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final s = state.s;
      final now = DateTime.now();
      final calc = state.calculator;
      const prayers = [PrayerName.fajr, PrayerName.dhuhr, PrayerName.asr, PrayerName.maghrib, PrayerName.isha];

      for (var offset = 0; offset < 7; offset++) {
        final date = DateTime(now.year, now.month, now.day).add(Duration(days: offset));

        if (state.settings.notifications) {
          final times = calc.forDate(date);
          for (var i = 0; i < prayers.length; i++) {
            final when = times[prayers[i]];
            if (!when.isAfter(now.toUtc())) continue;
            final name = s.t(prayers[i].name);
            await _plugin.zonedSchedule(
              offset * 10 + i,
              '${s.t('notif_title')} $name',
              s.t('notif_body'),
              tz.TZDateTime.from(when.toUtc(), tz.UTC),
              _prayerDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }

        if (state.settings.tahajjudReminder) {
          final wake = date.add(Duration(minutes: state.settings.wakeMinutes));
          if (wake.isAfter(now)) {
            await _plugin.zonedSchedule(
              1000 + offset,
              s.t('tahajjud_notif'),
              s.t('tahajjud_body'),
              tz.TZDateTime.from(wake.toUtc(), tz.UTC),
              _tahajjudDetails,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Scheduling failed: $e');
    }
  }
}
