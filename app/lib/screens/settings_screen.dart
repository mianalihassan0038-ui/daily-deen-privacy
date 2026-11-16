import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/cities.dart';
import '../data/routine.dart';
import '../services/notifications.dart';
import '../services/prayer_times.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _methodNames = {
    CalcMethod.karachi: 'University of Islamic Sciences, Karachi',
    CalcMethod.mwl: 'Muslim World League',
    CalcMethod.isna: 'ISNA (North America)',
    CalcMethod.egypt: 'Egyptian General Authority',
    CalcMethod.ummAlQura: 'Umm al-Qura, Makkah',
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final st = state.settings;
    final theme = Theme.of(context);
    final wake = TimeOfDay(hour: st.wakeMinutes ~/ 60, minute: st.wakeMinutes % 60);

    Widget header(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(t, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.t('settings'))),
      body: ListView(
        children: [
          header(s.t('language')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('English')),
                ButtonSegment(value: true, label: Text('اردو')),
              ],
              selected: {st.urdu},
              onSelectionChanged: (v) {
                st.urdu = v.first;
                state.saveSettings(reschedule: true);
              },
            ),
          ),
          header(s.t('theme')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(s.t('theme_system'))),
                ButtonSegment(value: ThemeMode.light, label: Text(s.t('theme_light'))),
                ButtonSegment(value: ThemeMode.dark, label: Text(s.t('theme_dark'))),
              ],
              selected: {st.themeMode},
              onSelectionChanged: (v) {
                st.themeMode = v.first;
                state.saveSettings();
              },
            ),
          ),
          header(s.t('prayer_times')),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(s.t('location')),
            subtitle: Text('${st.city.name}, ${st.city.country}'),
            onTap: () => _pickCity(context, state),
          ),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: Text(s.t('calc_method')),
            subtitle: Text(_methodNames[st.method]!),
            onTap: () async {
              final m = await showDialog<CalcMethod>(
                context: context,
                builder: (c) => SimpleDialog(
                  title: Text(s.t('calc_method')),
                  children: [
                    for (final e in _methodNames.entries)
                      SimpleDialogOption(onPressed: () => Navigator.pop(c, e.key), child: Text(e.value)),
                  ],
                ),
              );
              if (m != null) {
                st.method = m;
                state.saveSettings(reschedule: true);
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wb_sunny_outlined),
            title: Text(s.t('asr_method')),
            subtitle: Text(st.hanafiAsr ? s.t('hanafi') : s.t('shafi')),
            value: st.hanafiAsr,
            onChanged: (v) {
              st.hanafiAsr = v;
              state.saveSettings(reschedule: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(s.t('hijri_adjust')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: st.hijriAdjust > -2 ? () { st.hijriAdjust--; state.saveSettings(); } : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(st.hijriAdjust > 0 ? '+${st.hijriAdjust}' : '${st.hijriAdjust}'),
                IconButton(
                  onPressed: st.hijriAdjust < 2 ? () { st.hijriAdjust++; state.saveSettings(); } : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          header(s.t('notifications')),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(s.t('notifications')),
            value: st.notifications,
            onChanged: (v) async {
              st.notifications = v;
              if (v) await NotificationService.instance.requestPermission();
              state.saveSettings(reschedule: true);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm),
            title: Text(s.t('tahajjud_alarm')),
            value: st.tahajjudReminder,
            onChanged: (v) async {
              st.tahajjudReminder = v;
              if (v) await NotificationService.instance.requestPermission();
              state.saveSettings(reschedule: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(s.t('wake_time')),
            trailing: Text(wake.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: wake);
              if (t != null) {
                st.wakeMinutes = t.hour * 60 + t.minute;
                state.saveSettings(reschedule: true);
              }
            },
          ),
          header(s.t('quran_tracker')),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(s.t('quran_target')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: st.quranTarget > 1 ? () { st.quranTarget--; state.saveSettings(); } : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${st.quranTarget}'),
                IconButton(
                  onPressed: st.quranTarget < 60 ? () { st.quranTarget++; state.saveSettings(); } : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          header(s.t('daily_activities')),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: Text(s.t('routine_items')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutineEditorScreen())),
          ),
          header(s.t('about')),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(s.t('privacy')),
            subtitle: Text(s.t('privacy_text')),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('${s.t('app_name')} 1.0.0'),
            subtitle: Text(s.t('disclaimer')),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _pickCity(BuildContext context, AppState state) async {
    final idx = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (c, ctrl) => ListView.builder(
          controller: ctrl,
          itemCount: cities.length,
          itemBuilder: (c, i) => ListTile(
            title: Text(cities[i].name),
            subtitle: Text(cities[i].country),
            trailing: i == state.settings.cityIndex ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(c, i),
          ),
        ),
      ),
    );
    if (idx != null) {
      state.settings.cityIndex = idx;
      state.saveSettings(reschedule: true);
    }
  }
}

class RoutineEditorScreen extends StatelessWidget {
  const RoutineEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final items = state.allItems;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('routine_items'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDialog(context, state),
        icon: const Icon(Icons.add),
        label: Text(s.t('add_custom')),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          for (final item in items)
            item.custom
                ? ListTile(
                    title: Text(item.name(urdu)),
                    subtitle: item.targetEn.isEmpty ? null : Text(item.targetEn),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: s.t('delete'),
                      onPressed: () => state.removeCustomItem(item.id),
                    ),
                  )
                : SwitchListTile(
                    title: Text(item.name(urdu)),
                    subtitle: Text(item.target(urdu)),
                    value: !state.settings.disabledItems.contains(item.id),
                    onChanged: item.prayerKey != null ? null : (v) => state.setItemEnabled(item.id, v),
                  ),
        ],
      ),
    );
  }

  Future<void> _addDialog(BuildContext context, AppState state) async {
    final s = state.s;
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    var section = RoutineSection.day;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) => AlertDialog(
          title: Text(s.t('add_custom')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: s.t('activity_name'))),
              TextField(controller: targetCtrl, decoration: InputDecoration(labelText: s.t('activity_target'))),
              const SizedBox(height: 12),
              DropdownButton<RoutineSection>(
                isExpanded: true,
                value: section,
                items: [
                  DropdownMenuItem(value: RoutineSection.earlyMorning, child: Text(s.t('sec_early'))),
                  DropdownMenuItem(value: RoutineSection.day, child: Text(s.t('sec_day'))),
                  DropdownMenuItem(value: RoutineSection.night, child: Text(s.t('sec_night'))),
                ],
                onChanged: (v) => setLocal(() => section = v ?? section),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('save'))),
          ],
        ),
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      state.addCustomItem(nameCtrl.text.trim(), targetCtrl.text.trim(), section);
    }
    nameCtrl.dispose();
    targetCtrl.dispose();
  }
}
