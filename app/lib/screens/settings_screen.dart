import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/routine.dart';
import '../services/location.dart' as loc;
import '../services/notifications.dart';
import '../services/prayer_times.dart';
import '../strings.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';
import 'routine_screen.dart';
import '../version.dart';

const privacyPolicyUrl = 'https://mianalihassan0038-ui.github.io/daily-deen-privacy/';

const methodNames = {
  CalcMethod.karachi: 'University of Islamic Sciences, Karachi',
  CalcMethod.mwl: 'Muslim World League',
  CalcMethod.isna: 'ISNA (North America)',
  CalcMethod.egypt: 'Egyptian General Authority',
  CalcMethod.ummAlQura: 'Umm al-Qura, Makkah',
};

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final st = state.settings;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    final photo = st.profileImage;
    final hasPhoto = photo != null && File(photo).existsSync();

    Widget tile(IconData icon, String title, {String? subtitle, VoidCallback? onTap, Key? key}) => ListTile(
          key: key,
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );

    return HeaderScaffold(
      title: s.t('settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: ListTile(
              key: const Key('profile_tile'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.emerald,
                backgroundImage: hasPhoto ? FileImage(File(photo)) : null,
                child: hasPhoto ? null : const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              title: Text(st.userName.isEmpty ? s.t('your_name') : st.userName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              subtitle: Text(st.locationName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => push(const ProfileScreen()),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              tile(Icons.notifications_outlined, s.t('notifications'),
                  key: const Key('settings_notifications'), onTap: () => push(const NotificationSettingsScreen())),
              tile(Icons.location_on_outlined, s.t('location_prayer_times'),
                  subtitle: '${st.locationName} • ${st.hanafiAsr ? s.t('hanafi') : s.t('shafi_short')}',
                  key: const Key('settings_prayer'),
                  onTap: () => push(const PrayerSettingsScreen())),
              ListTile(
                leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                title: Text(s.t('language')),
                trailing: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('EN')),
                    ButtonSegment(value: true, label: Text('اردو')),
                  ],
                  selected: {st.urdu},
                  onSelectionChanged: (v) {
                    st.urdu = v.first;
                    state.saveSettings(reschedule: true);
                  },
                ),
              ),
              ListTile(
                leading: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
                title: Text(s.t('appearance')),
                trailing: DropdownButton<ThemeMode>(
                  value: st.themeMode,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: ThemeMode.system, child: Text(s.t('theme_system'))),
                    DropdownMenuItem(value: ThemeMode.light, child: Text(s.t('theme_light'))),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text(s.t('theme_dark'))),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    st.themeMode = v;
                    state.saveSettings();
                  },
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              tile(Icons.flag_outlined, s.t('daily_targets'), onTap: () => push(const TargetsScreen())),
              tile(Icons.event_note, s.t('routine_planner'), onTap: () => push(const RoutineScreen())),
              tile(Icons.backup_outlined, s.t('backup_restore'),
                  key: const Key('settings_backup'), onTap: () => push(const BackupScreen())),
            ]),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              tile(Icons.privacy_tip_outlined, s.t('privacy_security'), onTap: () => push(const PrivacyScreen())),
              tile(Icons.info_outline, s.t('about_app'), onTap: () => push(const AboutScreen())),
            ]),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Profile
// ----------------------------------------------------------------------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  bool _init = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(AppState state) async {
    final s = state.s;
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(x.path).copy(path);
      final old = state.settings.profileImage;
      state.settings.profileImage = path;
      state.saveSettings();
      if (old != null && old != path) {
        try {
          await File(old).delete();
        } catch (_) {}
      }
    } catch (_) {
      if (mounted) toast(context, s.t('photo_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final st = state.settings;
    if (!_init) {
      _name.text = st.userName;
      _init = true;
    }
    final photo = st.profileImage;
    final hasPhoto = photo != null && File(photo).existsSync();
    return HeaderScaffold(
      title: s.t('profile'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: AppColors.emerald,
                backgroundImage: hasPhoto ? FileImage(File(photo)) : null,
                child: hasPhoto ? null : const Icon(Icons.person, color: Colors.white, size: 60),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.gold),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () => _pickPhoto(state),
                ),
              ),
            ]),
          ),
          if (hasPhoto)
            Center(
              child: TextButton(
                onPressed: () {
                  st.profileImage = null;
                  state.saveSettings();
                },
                child: Text(s.t('remove_photo')),
              ),
            ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('profile_name'),
            controller: _name,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: s.t('your_name'), prefixIcon: const Icon(Icons.person_outline)),
            onChanged: (v) {
              st.userName = v.trim();
              state.saveSettings();
            },
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Location & prayer settings
// ----------------------------------------------------------------------------
class PrayerSettingsScreen extends StatelessWidget {
  const PrayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final st = state.settings;
    final urdu = st.urdu;
    final raw = state.calculator.forDate(state.today);
    final theme = Theme.of(context);

    return HeaderScaffold(
      title: s.t('location_prayer_times'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          SectionTitle(s.t('location')),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(st.locationName),
                subtitle: Text(st.useCustomLocation
                    ? '${st.customLat.toStringAsFixed(3)}, ${st.customLng.toStringAsFixed(3)}'
                    : '${st.city.name}, ${st.city.country}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pickCity(context, state),
              ),
              ListTile(
                leading: const Icon(Icons.my_location),
                title: Text(s.t('use_my_location')),
                onTap: () => useDeviceLocation(context, state),
              ),
            ]),
          ),
          SectionTitle(s.t('calculation')),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.calculate_outlined),
                title: Text(s.t('calc_method')),
                subtitle: Text(methodNames[st.method]!),
                onTap: () async {
                  final m = await showDialog<CalcMethod>(
                    context: context,
                    builder: (c) => SimpleDialog(
                      title: Text(s.t('calc_method')),
                      children: [
                        for (final e in methodNames.entries)
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(c, e.key),
                            child: Row(children: [
                              Icon(e.key == st.method ? Icons.radio_button_checked : Icons.radio_button_off, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(e.value)),
                            ]),
                          ),
                      ],
                    ),
                  );
                  if (m != null) {
                    st.method = m;
                    state.saveSettings(reschedule: true);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: Text(s.t('asr_method')),
                subtitle: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: true, label: Text(s.t('hanafi'))),
                    ButtonSegment(value: false, label: Text(s.t('shafi_short'))),
                  ],
                  selected: {st.hanafiAsr},
                  onSelectionChanged: (v) {
                    st.hanafiAsr = v.first;
                    state.saveSettings(reschedule: true);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(s.t('hijri_adjust')),
                trailing: _Stepper(
                  value: st.hijriAdjust,
                  min: -2,
                  max: 2,
                  signed: true,
                  onChanged: (v) {
                    st.hijriAdjust = v;
                    state.saveSettings();
                  },
                ),
              ),
            ]),
          ),
          SectionTitle(s.t('manual_adjust')),
          Card(
            child: Column(children: [
              for (final p in PrayerName.values)
                ListTile(
                  key: Key('offset_${p.name}'),
                  title: Text(s.t(p.name)),
                  subtitle: Text(
                    st.fixedPrayerTimes[p.name] != null
                        ? '${s.t('my_time')} • ${s.t('calculated')}: ${formatTime(raw[p], urdu: urdu)}'
                        : (st.prayerOffsets[p.name] ?? 0) == 0
                            ? s.t('calculated')
                            : '${s.t('calculated')} ${(st.prayerOffsets[p.name] ?? 0) > 0 ? '+' : ''}${st.prayerOffsets[p.name]} ${s.t('min_short')}',
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(formatTime(state.prayerTimes(state.today)[p], urdu: urdu),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Icon(st.fixedPrayerTimes[p.name] != null ? Icons.push_pin : Icons.edit, size: 18, color: AppColors.gold),
                  ]),
                  onTap: () => editPrayerTime(context, state, p.name),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(s.t('my_time_hint'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text(s.t('disclaimer'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Lets the user choose their own time for a prayer, or go back to the
/// calculated time (with optional +/- minutes).
Future<void> editPrayerTime(BuildContext context, AppState state, String key) {
  final s = state.s;
  final urdu = state.settings.urdu;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (c) => ListenableBuilder(
      listenable: state,
      builder: (c, _) {
        final p = PrayerName.values.firstWhere((e) => e.name == key);
        final raw = state.calculator.forDate(state.today)[p];
        final fixed = state.settings.fixedPrayerTimes[key];
        final offset = state.settings.prayerOffsets[key] ?? 0;
        final current = state.prayerTimes(state.today)[p];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('${s.t(key)} • ${formatTime(current, urdu: urdu)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${s.t('calculated')}: ${formatTime(raw, urdu: urdu)}',
                  textAlign: TextAlign.center, style: Theme.of(c).textTheme.bodySmall),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: Key('set_time_$key'),
                icon: const Icon(Icons.edit_calendar),
                label: Text(fixed == null ? s.t('set_my_time') : '${s.t('my_time')}: ${formatMinutes(fixed, urdu: urdu)}'),
                onPressed: () async {
                  final local = current.toLocal();
                  final t = await showTimePicker(
                    context: c,
                    initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
                    helpText: s.t(key),
                  );
                  if (t != null) state.setFixedPrayerTime(key, t.hour * 60 + t.minute);
                },
              ),
              if (fixed != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(s.t('use_calculated')),
                  onPressed: () => state.setFixedPrayerTime(key, null),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text(s.t('adjust_minutes'))),
                  _Stepper(
                    value: offset,
                    min: -60,
                    max: 60,
                    signed: true,
                    suffix: s.t('min_short'),
                    onChanged: (v) => state.setPrayerOffset(key, v),
                  ),
                ]),
              ],
              const SizedBox(height: 8),
              Text(s.t('my_time_hint'), style: Theme.of(c).textTheme.bodySmall, textAlign: TextAlign.center),
            ]),
          ),
        );
      },
    ),
  );
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final bool signed;
  final String suffix;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.signed = false,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: value > min ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove_circle_outline),
      ),
      SizedBox(
        width: 44,
        child: Text('${signed && value > 0 ? '+' : ''}$value$suffix', textAlign: TextAlign.center),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add_circle_outline),
      ),
    ]);
  }
}

// ----------------------------------------------------------------------------
// Daily targets
// ----------------------------------------------------------------------------
class TargetsScreen extends StatelessWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final st = state.settings;
    return HeaderScaffold(
      title: s.t('daily_targets'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(s.t('quran_target')),
                trailing: _Stepper(
                  value: st.quranTarget,
                  min: 1,
                  max: 60,
                  onChanged: (v) {
                    state.setQuranTarget(v);
                  },
                ),
              ),
              for (final item in state.allItems.where((i) => i.dhikrKey != null))
                ListTile(
                  leading: const Icon(Icons.touch_app_outlined),
                  title: Text(item.name(st.urdu)),
                  subtitle: Text('${s.t('tasbeeh')} ${s.t('target')}'),
                  trailing: Text('${state.dhikrTarget(item.dhikrKey!, item.dhikrTarget)}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  onTap: () async {
                    final n = await askNumber(context, state, s.t('custom_target'),
                        initial: state.dhikrTarget(item.dhikrKey!, item.dhikrTarget));
                    if (n != null) state.setDhikrTarget(item.dhikrKey!, n);
                  },
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Notifications
// ----------------------------------------------------------------------------
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final st = state.settings;
    final urdu = st.urdu;

    Widget sw(String key, IconData icon, String title, {String? subtitle, Widget? extra}) => Column(children: [
          SwitchListTile(
            key: Key('notif_$key'),
            secondary: Icon(icon),
            title: Text(title),
            subtitle: subtitle == null ? null : Text(subtitle),
            value: st.notif[key] ?? true,
            onChanged: st.notifications
                ? (v) {
                    st.notif[key] = v;
                    if (key == 'tahajjud') st.tahajjudReminder = v;
                    state.saveSettings(reschedule: true);
                  }
                : null,
          ),
          if (extra != null && (st.notif[key] ?? true) && st.notifications) extra,
        ]);

    Widget timeTile(String label, int minutes, ValueChanged<int> onChanged) => ListTile(
          contentPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
          dense: true,
          title: Text(label),
          trailing: Text(formatMinutes(minutes, urdu: urdu), style: const TextStyle(fontWeight: FontWeight.w700)),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
            if (t != null) onChanged(t.hour * 60 + t.minute);
          },
        );

    return HeaderScaffold(
      title: s.t('notifications'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: SwitchListTile(
              key: const Key('notif_master'),
              secondary: const Icon(Icons.notifications_active),
              title: Text(s.t('all_notifications'), style: const TextStyle(fontWeight: FontWeight.w700)),
              value: st.notifications,
              onChanged: (v) async {
                st.notifications = v;
                if (v) await NotificationService.instance.requestPermission();
                state.saveSettings(reschedule: true);
              },
            ),
          ),
          SectionTitle(s.t('prayers')),
          Card(
            child: Column(children: [
              for (final k in prayerKeys) sw(k, Icons.mosque_outlined, s.t(k)),
              ListTile(
                enabled: st.notifications,
                leading: const Icon(Icons.timer_outlined),
                title: Text(s.t('remind_before')),
                trailing: DropdownButton<int>(
                  value: const [0, 5, 10, 15, 20, 30].contains(st.prayerReminderBefore) ? st.prayerReminderBefore : 0,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final m in const [0, 5, 10, 15, 20, 30])
                      DropdownMenuItem(value: m, child: Text(m == 0 ? s.t('at_time') : '$m ${s.t('min_short')}')),
                  ],
                  onChanged: st.notifications
                      ? (v) {
                          st.prayerReminderBefore = v ?? 0;
                          state.saveSettings(reschedule: true);
                        }
                      : null,
                ),
              ),
            ]),
          ),
          SectionTitle(s.t('worship_reminders')),
          Card(
            child: Column(children: [
              sw('tahajjud', Icons.alarm, s.t('tahajjud_alarm'),
                  extra: timeTile(s.t('wake_time'), st.wakeMinutes, (v) {
                    st.wakeMinutes = v;
                    state.saveSettings(reschedule: true);
                  })),
              sw('quran', Icons.menu_book_outlined, s.t('quran_reminder'),
                  extra: timeTile(s.t('time'), st.quranReminderMinutes, (v) {
                    st.quranReminderMinutes = v;
                    state.saveSettings(reschedule: true);
                  })),
              sw('morning_azkar', Icons.wb_sunny_outlined, s.t('morning_azkar'), subtitle: '${st.azkarAfterMinutes} ${s.t('min_after_fajr')}'),
              sw('evening_azkar', Icons.nights_stay_outlined, s.t('evening_azkar'), subtitle: '${st.azkarAfterMinutes} ${s.t('min_after_asr')}'),
              sw('sleep_azkar', Icons.bedtime_outlined, s.t('sleep_azkar'),
                  extra: timeTile(s.t('time'), st.sleepMinutes, (v) {
                    st.sleepMinutes = v;
                    state.saveSettings(reschedule: true);
                  })),
              sw('routine', Icons.event_note, s.t('routine_reminders'), subtitle: s.t('routine_reminders_sub')),
            ]),
          ),
          SectionTitle(s.t('options')),
          Card(
            child: Column(children: [
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: Text(s.t('vibration')),
                value: st.notifVibrate,
                onChanged: (v) {
                  st.notifVibrate = v;
                  state.saveSettings(reschedule: true);
                },
              ),
              SwitchListTile(
                key: const Key('exact_alarms'),
                secondary: const Icon(Icons.alarm_on),
                title: Text(s.t('exact_alarms')),
                subtitle: Text(s.t('exact_alarms_sub')),
                value: st.exactAlarms,
                onChanged: (v) async {
                  if (v && !await NotificationService.instance.canScheduleExact()) {
                    await NotificationService.instance.requestExactAlarms();
                  }
                  st.exactAlarms = v;
                  state.saveSettings(reschedule: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.snooze),
                title: Text(s.t('snooze_duration')),
                trailing: DropdownButton<int>(
                  value: const [5, 10, 15, 30].contains(st.snoozeMinutes) ? st.snoozeMinutes : 10,
                  underline: const SizedBox.shrink(),
                  items: [for (final m in const [5, 10, 15, 30]) DropdownMenuItem(value: m, child: Text('$m ${s.t('min_short')}'))],
                  onChanged: (v) {
                    st.snoozeMinutes = v ?? 10;
                    state.saveSettings(reschedule: true);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.music_note_outlined),
                title: Text(s.t('notification_sound')),
                subtitle: Text(s.t('notification_sound_sub')),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => loc.openAppSettings(),
              ),
              ListTile(
                leading: const Icon(Icons.battery_alert_outlined),
                title: Text(s.t('battery_title')),
                subtitle: Text(s.t('battery_text')),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => loc.openAppSettings(),
              ),
              ListTile(
                key: const Key('test_notification'),
                leading: const Icon(Icons.notification_add_outlined),
                title: Text(s.t('test_notification')),
                onTap: () async {
                  await NotificationService.instance.requestPermission();
                  await NotificationService.instance.showTest(state);
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Backup & restore
// ----------------------------------------------------------------------------
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _backup(BuildContext context, AppState state) async {
    final s = state.s;
    try {
      await state.flush();
      final json = const JsonEncoder.withIndent(' ').convert(state.exportData());
      final now = DateTime.now();
      final name = 'daily-deen-backup-${dayKey(now)}.json';
      final uri = await FilePicker.saveFile(
        fileName: name,
        bytes: Uint8List.fromList(utf8.encode(json)),
        mimeType: 'application/json',
        dialogTitle: s.t('backup_now'),
      );
      if (uri != null && context.mounted) toast(context, s.t('backup_saved'));
    } catch (_) {
      if (context.mounted) toast(context, s.t('backup_failed'));
    }
  }

  Future<void> _restore(BuildContext context, AppState state) async {
    final s = state.s;
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map<String, dynamic>) throw const FormatException();
      if (!context.mounted) return;
      if (!await confirm(context, state, s.t('restore_confirm'), message: s.t('restore_confirm_msg'))) return;
      final problem = await state.importDataSafe(data);
      if (context.mounted) toast(context, problem == null ? s.t('restore_done') : '${s.t('restore_invalid')} ($problem)');
    } catch (_) {
      if (context.mounted) toast(context, s.t('restore_invalid'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    return HeaderScaffold(
      title: s.t('backup_restore'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.t('backup_text')),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('backup_now'),
            onPressed: () => _backup(context, state),
            icon: const Icon(Icons.save_alt),
            label: Text(s.t('backup_now')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const Key('restore_now'),
            onPressed: () => _restore(context, state),
            icon: const Icon(Icons.restore),
            label: Text(s.t('restore')),
          ),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.cloud_off, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(s.t('cloud_backup_note'), style: Theme.of(context).textTheme.bodySmall)),
          ]),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Privacy & About
// ----------------------------------------------------------------------------
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    return HeaderScaffold(
      title: s.t('privacy_security'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final k in ['privacy_text', 'privacy_location', 'privacy_notes', 'privacy_backup'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_circle, color: AppColors.onTime, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s.t(k))),
                    ]),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: Text(s.t('full_privacy_policy')),
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    final theme = Theme.of(context);
    return HeaderScaffold(
      title: s.t('about_app'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Icon(Icons.mosque, size: 56, color: AppColors.emerald),
                const SizedBox(height: 8),
                Text('${s.t('app_name')} $appVersion', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                Text(s.t('splash_tagline'), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Aurial Tech', style: theme.textTheme.bodySmall),
              ]),
            ),
          ),
          SectionTitle(s.t('sources')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.t('sources_text')),
            ),
          ),
          SectionTitle(s.t('disclaimer_title')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.t('disclaimer')),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => showLicensePage(context: context, applicationName: s.t('app_name'), applicationVersion: appVersion),
            child: Text(s.t('licenses')),
          ),
        ],
      ),
    );
  }
}
