import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/schedule.dart';
import '../widgets/azkar_schedule_editor.dart';
import '../widgets/common.dart';
import 'navigation.dart';

/// Lists every Azkar / dhikr activity with its schedule; tap to change it.
class AzkarScheduleScreen extends StatelessWidget {
  const AzkarScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final items = state.allItems.where(isAzkarItem).toList();
    return HeaderScaffold(
      title: s.t('azkar_schedule'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(s.t('azkar_schedule_hint'), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final it in items)
            Card(
              child: ListTile(
                key: Key('azkar_sched_${it.id}'),
                leading: Icon(categoryVisual(it.category).$1, color: categoryVisual(it.category).$2),
                title: Text(it.name(urdu), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(azkarScheduleSummary(s, AzkarSchedule.of(it), urdu: urdu)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAzkarScheduleSheet(context, state, it.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens the Azkar schedule editor for one activity.
Future<void> showAzkarScheduleSheet(BuildContext context, AppState state, String id) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AzkarScheduleEditScreen(id: id)));

/// Full-screen editor (After Prayer / Fixed Time / Time Window) for one
/// Azkar activity. Nothing changes until "Save Schedule".
class AzkarScheduleEditScreen extends StatefulWidget {
  final String id;
  const AzkarScheduleEditScreen({super.key, required this.id});

  @override
  State<AzkarScheduleEditScreen> createState() => _AzkarScheduleEditScreenState();
}

class _AzkarScheduleEditScreenState extends State<AzkarScheduleEditScreen> {
  AzkarSchedule? _value;
  bool _init = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final item = state.itemById(widget.id);
    if (item == null) return HeaderScaffold(title: s.t('azkar_schedule'), body: const SizedBox.shrink());
    if (!_init) {
      _value = AzkarSchedule.of(item);
      _init = true;
    }
    return HeaderScaffold(
      title: s.t('azkar_schedule'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(item.name(state.settings.urdu),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          AzkarScheduleEditor(value: _value, onChanged: (v) => setState(() => _value = v)),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('azkar_sched_save'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () {
              state.setAzkarSchedule(widget.id, _value);
              toast(context, s.t('schedule_saved'));
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.save),
            label: Text(s.t('save_schedule')),
          ),
        ],
      ),
    );
  }
}
