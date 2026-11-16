import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../strings.dart';
import '../widgets/common.dart';
import '../widgets/date_switcher.dart';
import '../widgets/pickers.dart';

String _money(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

/// Sadaqah (charity) tracker.
class SadaqahScreen extends StatelessWidget {
  const SadaqahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final today = state.today;
    final cur = state.settings.currency;
    final goal = state.settings.sadaqahGoal;
    final todayAmount = state.sadaqahOn(today);
    final months = [for (var i = 5; i >= 0; i--) DateTime(today.year, today.month - i)];
    final monthTotals = [for (final m in months) state.sadaqahInMonth(m.year, m.month)];
    final maxMonth = monthTotals.fold(0.0, (a, b) => a > b ? a : b);

    return HeaderScaffold(
      title: s.t('sadaqah'),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('sadaqah_add'),
        onPressed: () => _add(context, state),
        icon: const Icon(Icons.add),
        label: Text(s.t('add_record')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                ProgressRing(
                  value: goal <= 0 ? (todayAmount > 0 ? 1 : 0) : todayAmount / goal,
                  size: 80,
                  color: AppColors.gold,
                  child: const Icon(Icons.savings, color: AppColors.gold, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.t('today_total'), style: theme.textTheme.bodySmall),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('$cur ${_money(todayAmount)}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    InkWell(
                      onTap: () => _editGoal(context, state),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(child: Text(goal <= 0 ? s.t('set_daily_goal') : '${s.t('daily_goal')}: $cur ${_money(goal)}')),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 14, color: theme.colorScheme.primary),
                      ]),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          SectionTitle(s.t('monthly_stats')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                MiniBarChart(
                  values: [for (final v in monthTotals) maxMonth == 0 ? 0 : v / maxMonth],
                  labels: [for (final m in months) (urdu ? monthsUr : monthsEn)[m.month - 1].substring(0, urdu ? null : 3)],
                  height: 100,
                  highlight: 5,
                ),
                const SizedBox(height: 8),
                Text('${s.t('this_month')}: $cur ${_money(monthTotals.last)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
          SectionTitle(s.t('records')),
          if (state.sadaqah.isEmpty)
            Card(child: EmptyState(icon: Icons.volunteer_activism, text: s.t('no_records')))
          else
            Card(
              child: Column(children: [
                for (final r in state.sadaqah.take(100))
                  ListTile(
                    leading: const IconBadge(Icons.volunteer_activism, color: AppColors.gold, size: 36),
                    title: Text('$cur ${_money(r.amount)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([dayKey(r.date), if (r.note.isNotEmpty) r.note].join(' • ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await confirm(context, state, '${s.t('delete')}?')) state.deleteSadaqah(r.id);
                      },
                    ),
                  ),
              ]),
            ),
          const SizedBox(height: 10),
          Text(s.t('sadaqah_private'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _editGoal(BuildContext context, AppState state) async {
    final s = state.s;
    final amount = TextEditingController(text: state.settings.sadaqahGoal > 0 ? _money(state.settings.sadaqahGoal) : '');
    final currency = TextEditingController(text: state.settings.currency);
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.t('daily_goal')),
        content: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: s.t('amount')),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                return n == null || n < 0 ? s.t('enter_number') : null;
              },
            ),
            TextFormField(
              controller: currency,
              maxLength: 5,
              decoration: InputDecoration(labelText: s.t('currency')),
              validator: (v) => (v ?? '').trim().isEmpty ? s.t('required') : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: Text(s.t('save')),
          ),
        ],
      ),
    );
    if (ok == true) {
      state.settings.sadaqahGoal = double.parse(amount.text.trim());
      state.settings.currency = currency.text.trim();
      state.saveSettings();
    }
  }

  Future<void> _add(BuildContext context, AppState state) async {
    final s = state.s;
    final amount = TextEditingController();
    final note = TextEditingController();
    final key = GlobalKey<FormState>();
    var date = state.today;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) => AlertDialog(
          title: Text(s.t('add_record')),
          content: Form(
            key: key,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                key: const Key('sadaqah_amount'),
                controller: amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: '${s.t('amount')} (${state.settings.currency})'),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  return n == null || n <= 0 ? s.t('enter_number') : null;
                },
              ),
              TextFormField(
                controller: note,
                maxLength: 80,
                decoration: InputDecoration(labelText: s.t('note_optional')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(dayKey(date)),
                onTap: () async {
                  final p = await showDatePicker(context: c, initialDate: date, firstDate: DateTime(2020), lastDate: state.today);
                  if (p != null) setLocal(() => date = DateTime(p.year, p.month, p.day));
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))),
            FilledButton(
              key: const Key('sadaqah_save'),
              onPressed: () {
                if (key.currentState!.validate()) Navigator.pop(c, true);
              },
              child: Text(s.t('save')),
            ),
          ],
        ),
      ),
    );
    if (ok == true) state.addSadaqah(date, double.parse(amount.text.trim()), note.text.trim());
  }
}

/// Personal Islamic habit goals with daily counters.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  DateTime? _date;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final date = _date ?? state.today;
    final rec = state.day(date);
    final habits = state.settings.habits;
    return HeaderScaffold(
      title: s.t('habit_goals'),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('habit_add'),
        onPressed: () => _add(context, state),
        icon: const Icon(Icons.add),
        label: Text(s.t('add_goal')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          DateSwitcher(date: date, onChanged: (d) => setState(() => _date = d)),
          const SizedBox(height: 10),
          if (habits.isEmpty)
            Card(child: EmptyState(icon: Icons.flag_outlined, text: s.t('no_goals')))
          else
            for (final h in habits)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(children: [
                    ProgressRing(
                      value: (rec.habits[h.id] ?? 0) / h.target,
                      size: 44,
                      stroke: 5,
                      child: (rec.habits[h.id] ?? 0) >= h.target
                          ? const Icon(Icons.check, size: 18, color: AppColors.onTime)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(h.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${rec.habits[h.id] ?? 0} / ${h.target}', style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: (rec.habits[h.id] ?? 0) > 0 ? () => state.changeHabit(date, h.id, -1) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.emeraldMid),
                      onPressed: () => state.changeHabit(date, h.id, 1),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (_) async {
                        if (await confirm(context, state, '${s.t('delete')}: ${h.name}?')) state.deleteHabit(h.id);
                      },
                      itemBuilder: (c) => [PopupMenuItem(value: 'delete', child: Text(s.t('delete')))],
                    ),
                  ]),
                ),
              ),
          const SizedBox(height: 8),
          Text(s.t('habits_hint'), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, AppState state) async {
    final s = state.s;
    final name = TextEditingController();
    final target = TextEditingController(text: '1');
    final key = GlobalKey<FormState>();
    final suggestions = [s.t('habit_s1'), s.t('habit_s2'), s.t('habit_s3'), s.t('habit_s4')];
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.t('add_goal')),
        content: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              key: const Key('habit_name'),
              controller: name,
              autofocus: true,
              maxLength: 60,
              decoration: InputDecoration(labelText: s.t('goal_name')),
              validator: (v) => (v ?? '').trim().isEmpty ? s.t('required') : null,
            ),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final sug in suggestions) ActionChip(label: Text(sug), onPressed: () => name.text = sug),
            ]),
            TextFormField(
              controller: target,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.t('daily_target_count')),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return n == null || n < 1 || n > 10000 ? s.t('enter_number') : null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))),
          FilledButton(
            key: const Key('habit_save'),
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: Text(s.t('save')),
          ),
        ],
      ),
    );
    if (ok == true) state.addHabit(name.text.trim(), int.parse(target.text.trim()));
  }
}
