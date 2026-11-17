import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/azkar.dart';
import '../data/routine.dart';
import 'azkar_screen.dart';
import 'muhasaba_screen.dart';
import 'quran_reader_screen.dart';
import 'routine_screen.dart';
import 'shell.dart';
import '../strings.dart';
import '../widgets/common.dart';

(IconData, Color) categoryVisual(RoutineCategory c) => switch (c) {
      RoutineCategory.prayer => (Icons.mosque, AppColors.emeraldMid),
      RoutineCategory.nafl => (Icons.nightlight_round, const Color(0xFF2E5E8C)),
      RoutineCategory.quran => (Icons.menu_book, const Color(0xFF0B6E4F)),
      RoutineCategory.azkar => (Icons.auto_awesome, const Color(0xFFE09A2D)),
      RoutineCategory.dhikr => (Icons.touch_app, const Color(0xFF7A5BC4)),
      RoutineCategory.dua => (Icons.volunteer_activism, const Color(0xFFC9A44C)),
      RoutineCategory.health => (Icons.favorite, const Color(0xFFD45A3A)),
      RoutineCategory.study => (Icons.school, const Color(0xFF3E7BC4)),
      RoutineCategory.family => (Icons.family_restroom, const Color(0xFFB0558A)),
      RoutineCategory.work => (Icons.work_outline, const Color(0xFF5D6B75)),
      RoutineCategory.other => (Icons.check_circle_outline, const Color(0xFF6B8E7F)),
    };

/// Quran position opened by Quran-related routine items.
const Map<String, (int, int)> _quranTargets = {
  'yaseen': (36, 1),
  'kahf': (18, 1),
  'mulk': (67, 1),
  'waqiah': (56, 1),
  'kursi_morning': (2, 255),
  'kursi_night': (2, 255),
  'baqarah_last2': (2, 285),
};

const Map<String, AzkarType> _azkarItems = {
  'morning_azkar': AzkarType.morning,
  'evening_azkar': AzkarType.evening,
  'sleep_azkar': AzkarType.sleep,
};

/// Whether [item] opens a dedicated screen (azkar, Quran, tasbeeh, ...).
bool hasOwnScreen(RoutineItem item) =>
    item.prayerKey != null ||
    item.id == 'witr' ||
    _azkarItems.containsKey(item.id) ||
    _quranTargets.containsKey(item.id) ||
    item.id == 'quran_daily' ||
    item.id.startsWith('tilawat') ||
    item.dhikrKey != null ||
    item.id == 'muhasaba';

/// Opens the screen that belongs to a routine activity.
void openActivity(BuildContext context, RoutineItem item, DateTime date) {
  final nav = Navigator.of(context);
  if (item.prayerKey != null || item.id == 'witr') {
    ShellScope.go(context, Tabs.namaz);
    return;
  }
  final az = _azkarItems[item.id];
  if (az != null) {
    nav.push(MaterialPageRoute(builder: (_) => AzkarDetailScreen(type: az)));
    return;
  }
  final q = _quranTargets[item.id];
  if (q != null) {
    nav.push(MaterialPageRoute(builder: (_) => QuranReaderScreen(surah: q.$1, ayah: q.$2)));
    return;
  }
  if (item.id == 'quran_daily' || item.id.startsWith('tilawat')) {
    ShellScope.go(context, Tabs.quran);
    return;
  }
  if (item.dhikrKey != null) {
    TasbeehLauncher.open(context, item.dhikrKey!);
    return;
  }
  if (item.id == 'muhasaba') {
    nav.push(MaterialPageRoute(builder: (_) => MuhasabaScreen(date: date)));
    return;
  }
  showActivitySheet(context, item, date);
}

/// Details + actions for activities without their own screen.
Future<void> showActivitySheet(BuildContext context, RoutineItem item, DateTime date) {
  final state = AppScope.of(context);
  final s = state.s;
  final urdu = state.settings.urdu;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (c) {
      final done = state.isDone(date, item);
      final skipped = state.isSkipped(date, item);
      final (icon, color) = categoryVisual(item.category);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(item.name(urdu), style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 8),
              if (item.time(urdu).isNotEmpty) Text('${s.t('time')}: ${item.time(urdu)}'),
              if (item.target(urdu).isNotEmpty) Text('${s.t('target')}: ${item.target(urdu)}'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  tryToggle(context, state, date, item);
                },
                icon: Icon(done ? Icons.undo : Icons.check),
                label: Text(done ? s.t('mark_not_done') : s.t('mark_done')),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  state.toggleSkip(date, item);
                  Navigator.pop(c);
                },
                icon: Icon(skipped ? Icons.replay : Icons.skip_next),
                label: Text(skipped ? s.t('unskip') : s.t('skip_today')),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoutineEditScreen(item: item)));
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(s.t('edit')),
              ),
            ],
          ),
        ),
      );
    },
  );
}


/// Toggles an activity and explains why when it is not allowed
/// (locked until its time, or completed by its counter).
void tryToggle(BuildContext context, AppState state, DateTime date, RoutineItem item, {DateTime? now}) {
  final snap = state.snapshotOf(date, item);
  final wasDone = state.isDone(date, item);
  if (state.toggleItem(date, item, now: now)) {
    if (!wasDone && state.isDone(date, item)) showUndo(context, state, date, item, snap);
    return;
  }
  final s = state.s;
  if (state.isDone(date, item)) {
    toast(context, s.t('counter_completed_hint'));
  } else {
    final w = state.windowOf(item, date);
    toast(context, '${s.t('locked_until')} ${formatTime(w.start, urdu: state.settings.urdu)}');
  }
}

/// Records a prayer status, explaining when the prayer time has not started.
void trySetPrayer(BuildContext context, AppState state, DateTime date, String key, PrayerStatus status) {
  final item = state.itemById(key) ?? defaultRoutine.firstWhere((e) => e.id == key);
  final snap = state.snapshotOf(date, item);
  if (state.setPrayer(date, key, status)) {
    if (status != snap.prayer && isPrayed(status)) showUndo(context, state, date, item, snap);
    return;
  }
  final w = state.windowOf(item, date);
  toast(context, '${state.s.t('prayer_locked')} ${formatTime(w.start, urdu: state.settings.urdu)}');
}


/// "Completed — UNDO" snackbar. Undo restores exactly the previous state of
/// this one activity (completion, skip, time, prayer status); counters and
/// other activities are untouched, and scores update automatically.
void showUndo(BuildContext context, AppState state, DateTime date, RoutineItem item, CompletionSnapshot snap) {
  final s = state.s;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      key: const Key('undo_snackbar'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.emerald,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(seconds: 4),
      content: Row(children: [
        const Icon(Icons.check_circle, color: AppColors.emeraldLight),
        const SizedBox(width: 10),
        Expanded(child: Text('${item.name(state.settings.urdu)} ${s.t('marked_complete')}')),
      ]),
      action: SnackBarAction(
        key: const Key('undo_action'),
        label: s.t('undo').toUpperCase(),
        textColor: AppColors.goldLight,
        onPressed: () => state.restoreSnapshot(date, snap),
      ),
    ));
}
