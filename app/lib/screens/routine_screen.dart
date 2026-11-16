import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/routine.dart';
import '../services/prayer_times.dart';
import '../strings.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';
import 'navigation.dart';

/// "My Daily Routine" timeline + editor.
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  bool _edit = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    return HeaderScaffold(
      title: s.t('my_daily_routine'),
      actions: [
        TextButton(
          key: const Key('routine_edit_toggle'),
          onPressed: () => setState(() => _edit = !_edit),
          child: Text(_edit ? s.t('done') : s.t('edit'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (v) => _menu(context, state, v),
          itemBuilder: (c) => [
            PopupMenuItem(value: 'templates', child: Text(s.t('templates'))),
            PopupMenuItem(value: 'reset', child: Text(s.t('reset_routine'))),
          ],
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('routine_add'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutineEditScreen())),
        icon: const Icon(Icons.add),
        label: Text(s.t('add_activity')),
      ),
      body: _edit ? const _EditList() : const _Timeline(),
    );
  }

  Future<void> _menu(BuildContext context, AppState state, String v) async {
    final s = state.s;
    if (v == 'reset') {
      if (await confirm(context, state, s.t('reset_routine'), message: s.t('reset_routine_msg'))) {
        state.resetRoutineToDefault();
      }
      return;
    }
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => ListenableBuilder(
        listenable: state,
        builder: (c, _) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(s.t('templates'), style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(s.t('templates_hint'), style: Theme.of(c).textTheme.bodySmall, textAlign: TextAlign.center),
            ),
            for (final name in state.settings.routineTemplates.keys)
              ListTile(
                leading: const Icon(Icons.view_list),
                title: Text(name),
                subtitle: Text('${state.settings.routineTemplates[name]!.length} ${s.t('activities')}'),
                onTap: () async {
                  if (await confirm(c, state, '${s.t('apply_template')}: $name?', message: s.t('apply_template_msg'))) {
                    state.applyTemplate(name);
                    if (c.mounted) Navigator.pop(c);
                  }
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => state.deleteTemplate(name),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.save_outlined),
              title: Text(s.t('save_as_template')),
              onTap: () async {
                final name = await _askName(c, state);
                if (name != null && name.isNotEmpty) state.saveTemplate(name);
              },
            ),
          ]),
        ),
      ),
    );
  }

  Future<String?> _askName(BuildContext context, AppState state) {
    final s = state.s;
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.t('template_name')),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 40),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(s.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: Text(s.t('save'))),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final today = state.today;
    final items = state.routineFor(today);
    final times = state.prayerTimes(today);
    final theme = Theme.of(context);
    if (items.isEmpty) return EmptyState(icon: Icons.event_note, text: s.t('no_activities'));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: items.length,
      itemBuilder: (c, i) {
        final it = items[i];
        final done = state.isDone(today, it);
        final skipped = state.isSkipped(today, it);
        final (icon, color) = categoryVisual(it.category);
        String time = it.time(urdu);
        if (it.prayerKey != null) {
          final p = PrayerName.values.firstWhere((e) => e.name == it.prayerKey);
          time = formatTime(times[p], urdu: urdu);
        }
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 40,
              child: Column(children: [
                Expanded(child: Container(width: 2, color: i == 0 ? Colors.transparent : theme.dividerColor)),
                GestureDetector(
                  onTap: () => state.toggleItem(today, it),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: done ? AppColors.onTime : color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: done ? AppColors.onTime : color, width: 1.5),
                    ),
                    child: Icon(done ? Icons.check : icon, size: 16, color: done ? Colors.white : color),
                  ),
                ),
                Expanded(child: Container(width: 2, color: i == items.length - 1 ? Colors.transparent : theme.dividerColor)),
              ]),
            ),
            Expanded(
              child: InkWell(
                key: Key('timeline_${it.id}'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => openActivity(context, it, today),
                onLongPress: () => showActivitySheet(context, it, today),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(time.isEmpty ? '—' : time, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      if (it.reminder) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.notifications_active, size: 14, color: AppColors.gold),
                      ],
                      const Spacer(),
                      if (skipped) Text(s.t('skipped'), style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
                    ]),
                    Text(
                      it.name(urdu),
                      style: TextStyle(
                        decoration: done || skipped ? TextDecoration.lineThrough : null,
                        color: done || skipped ? theme.colorScheme.outline : null,
                      ),
                    ),
                    if (it.target(urdu).isNotEmpty) Text(it.target(urdu), style: theme.textTheme.bodySmall),
                  ]),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _EditList extends StatelessWidget {
  const _EditList();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final items = state.allItems;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Text(s.t('reorder_hint'), style: Theme.of(context).textTheme.bodySmall),
      ),
      Expanded(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
          itemCount: items.length,
          buildDefaultDragHandles: false,
          onReorder: state.reorderRoutine,
          itemBuilder: (c, i) {
            final it = items[i];
            final (icon, color) = categoryVisual(it.category);
            final days = it.days.isEmpty
                ? s.t('every_day')
                : (it.days.toList()..sort()).map((d) => (urdu ? weekdaysUr : weekdaysEn)[d - 1].substring(0, urdu ? 1 : 3)).join(', ');
            return Card(
              key: ValueKey(it.id),
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                leading: Icon(icon, color: it.enabled ? color : Colors.grey),
                title: Text(it.name(urdu), style: TextStyle(color: it.enabled ? null : Colors.grey)),
                subtitle: Text('${it.time(urdu).isEmpty ? '' : '${it.time(urdu)} • '}$days'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoutineEditScreen(item: it))),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (it.prayerKey == null)
                    Switch(
                      value: it.enabled,
                      onChanged: (v) => state.updateRoutineItem(it.copyWith(enabled: v)),
                    ),
                  if (it.prayerKey == null)
                    IconButton(
                      tooltip: s.t('delete'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await confirm(context, state, '${s.t('delete')}: ${it.name(urdu)}?')) {
                          state.deleteRoutineItem(it.id);
                        }
                      },
                    ),
                  ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

/// Add or edit one routine activity.
class RoutineEditScreen extends StatefulWidget {
  final RoutineItem? item;
  const RoutineEditScreen({super.key, this.item});

  @override
  State<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends State<RoutineEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  RoutineSection _section = RoutineSection.day;
  RoutineCategory _category = RoutineCategory.other;
  int? _time;
  Set<int> _days = {};
  bool _reminder = false;
  bool _optional = false;
  bool _init = false;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  void _initFrom(AppState state) {
    final it = widget.item;
    final urdu = state.settings.urdu;
    if (it != null) {
      _name.text = it.name(urdu);
      _target.text = it.target(urdu);
      _section = it.section;
      _category = it.category;
      _time = it.timeMinutes;
      _days = it.fridayOnly && it.days.isEmpty ? {5} : Set<int>.of(it.days);
      _reminder = it.reminder;
      _optional = it.optional;
    }
    _init = true;
  }

  void _save(AppState state) {
    if (!_form.currentState!.validate()) return;
    final urdu = state.settings.urdu;
    final name = _name.text.trim();
    final target = _target.text.trim();
    final it = widget.item;
    if (it == null) {
      state.addRoutineItem(RoutineItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        en: name,
        ur: name,
        targetEn: target,
        targetUr: target,
        section: _section,
        category: _category,
        timeMinutes: _time,
        days: _days.length == 7 ? <int>{} : _days,
        reminder: _reminder && _time != null,
        optional: _optional,
        custom: true,
      ));
    } else {
      final sameNames = it.en == it.ur;
      state.updateRoutineItem(it.copyWith(
        en: urdu && !sameNames ? it.en : name,
        ur: urdu || sameNames ? name : it.ur,
        targetEn: urdu && it.targetEn != it.targetUr ? it.targetEn : target,
        targetUr: urdu || it.targetEn == it.targetUr ? target : it.targetUr,
        section: _section,
        category: _category,
        timeMinutes: _time,
        clearTime: _time == null,
        days: _days.length == 7 ? <int>{} : _days,
        reminder: _reminder && _time != null,
        optional: _optional,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    if (!_init) _initFrom(state);
    final isPrayer = widget.item?.prayerKey != null;

    return HeaderScaffold(
      title: widget.item == null ? s.t('add_activity') : s.t('edit_activity'),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              key: const Key('activity_name'),
              controller: _name,
              maxLength: 60,
              decoration: InputDecoration(labelText: s.t('activity_name')),
              validator: (v) => (v ?? '').trim().isEmpty ? s.t('required') : null,
            ),
            TextFormField(
              controller: _target,
              maxLength: 60,
              decoration: InputDecoration(labelText: s.t('activity_target')),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RoutineCategory>(
              initialValue: _category,
              decoration: InputDecoration(labelText: s.t('category')),
              items: [
                for (final c in RoutineCategory.values)
                  DropdownMenuItem(
                    value: c,
                    child: Row(children: [
                      Icon(categoryVisual(c).$1, color: categoryVisual(c).$2, size: 20),
                      const SizedBox(width: 10),
                      Text(s.t('cat_${c.name}')),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RoutineSection>(
              initialValue: _section,
              decoration: InputDecoration(labelText: s.t('section')),
              items: [
                DropdownMenuItem(value: RoutineSection.earlyMorning, child: Text(s.t('sec_early'))),
                DropdownMenuItem(value: RoutineSection.day, child: Text(s.t('sec_day'))),
                DropdownMenuItem(value: RoutineSection.night, child: Text(s.t('sec_night'))),
              ],
              onChanged: (v) => setState(() => _section = v ?? _section),
            ),
            const SizedBox(height: 12),
            if (!isPrayer)
              Card(
                child: ListTile(
                  key: const Key('activity_time'),
                  leading: const Icon(Icons.access_time),
                  title: Text(s.t('time')),
                  subtitle: Text(_time == null ? s.t('no_fixed_time') : formatMinutes(_time!, urdu: urdu)),
                  trailing: _time == null
                      ? const Icon(Icons.chevron_right)
                      : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _time = null)),
                  onTap: () async {
                    final init = _time ?? 8 * 60;
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: init ~/ 60, minute: init % 60));
                    if (t != null) setState(() => _time = t.hour * 60 + t.minute);
                  },
                ),
              )
            else
              Text(s.t('prayer_time_auto'), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(s.t('repeat_days'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              FilterChip(
                label: Text(s.t('every_day')),
                selected: _days.isEmpty || _days.length == 7,
                onSelected: (_) => setState(() => _days = {}),
              ),
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text((urdu ? weekdaysUr : weekdaysEn)[d - 1].substring(0, urdu ? null : 3)),
                  selected: _days.contains(d),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _days.add(d);
                    } else {
                      _days.remove(d);
                    }
                  }),
                ),
            ]),
            const SizedBox(height: 12),
            if (!isPrayer)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('reminder')),
                subtitle: Text(_time == null ? s.t('reminder_needs_time') : s.t('reminder_at_time')),
                value: _reminder && _time != null,
                onChanged: _time == null ? null : (v) => setState(() => _reminder = v),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.t('optional')),
              subtitle: Text(s.t('optional_hint')),
              value: _optional,
              onChanged: (v) => setState(() => _optional = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('activity_save'),
              onPressed: () => _save(state),
              child: Text(s.t('save')),
            ),
            if (widget.item != null && !isPrayer) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  if (await confirm(context, state, '${s.t('delete')}?')) {
                    state.deleteRoutineItem(widget.item!.id);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.missed),
                label: Text(s.t('delete'), style: const TextStyle(color: AppColors.missed)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
