import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/routine.dart';
import '../services/report.dart';
import '../strings.dart';
import '../widgets/common.dart';
import 'report_screen.dart';

/// Dedicated 40-day Chilla screen: overview, 1–40 grid with states and the
/// detail of a selected day. A missed day never resets the chilla.
class ChillaScreen extends StatefulWidget {
  const ChillaScreen({super.key});

  @override
  State<ChillaScreen> createState() => _ChillaScreenState();
}

class _ChillaScreenState extends State<ChillaScreen> {
  int? _selected; // day number 1..40

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final sum = chillaSummary(state);

    if (sum == null) {
      return HeaderScaffold(
        title: s.t('my_chilla'),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          EmptyState(icon: Icons.event_available, text: s.t('chilla_not_started')),
          FilledButton.icon(
            key: const Key('chilla_start_today'),
            onPressed: () => state.startChilla(state.today),
            icon: const Icon(Icons.play_arrow),
            label: Text(s.t('start_chilla_today')),
          ),
        ]),
      );
    }

    String date(DateTime d) => '${d.day} ${(urdu ? monthsUr : monthsEn)[d.month - 1]} ${d.year}';
    final defaultSel = sum.currentDay.clamp(1, 40);
    final sel = sum.days[(_selected ?? defaultSel) - 1];

    Widget stat(String label, String value, Color c, String key) => Expanded(
          child: Column(children: [
            Text(value, key: Key(key), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
            Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center, maxLines: 2),
          ]),
        );

    return HeaderScaffold(
      title: s.t('my_chilla'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ---------- overview ----------
          Card(
            key: const Key('chilla_overview'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.goldLight, AppColors.gold]),
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.white, size: 38),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${s.t('current_chilla')} ${sum.chillaNumber.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall),
                    Text(
                      sum.currentDay > 40
                          ? s.t('chilla_complete')
                          : '${s.t('day')} ${sum.currentDay.clamp(1, 40)} ${s.t('of')} 40',
                      key: const Key('chilla_current_day'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: sum.progress, minHeight: 8, color: AppColors.emeraldMid),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(sum.progress * 100).round()}%',
                          key: const Key('chilla_percent'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 4),
                    Text('${date(sum.start)} – ${date(sum.end)}', style: theme.textTheme.labelSmall),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _InfoTile(Icons.check_circle, AppColors.onTime, s.t('completed'), '${sum.completedDays} ${s.t('days')}',
                'chilla_completed'),
            const SizedBox(width: 8),
            _InfoTile(Icons.local_fire_department, Colors.deepOrange, s.t('streak'), '${sum.streak} ${s.t('days')}',
                'chilla_streak'),
            const SizedBox(width: 8),
            _InfoTile(Icons.star, AppColors.gold, s.t('best_streak'), '${sum.bestStreak} ${s.t('days')}',
                'chilla_best'),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            stat(s.t('partial'), '${sum.partialDays}', AppColors.gold, 'chilla_partial'),
            stat(s.t('missed'), '${sum.missedDays}', AppColors.missed, 'chilla_missed'),
            stat(s.t('start_date'), '${sum.start.day}/${sum.start.month}', theme.colorScheme.primary, 'chilla_start_d'),
            stat(s.t('end_date'), '${sum.end.day}/${sum.end.month}', theme.colorScheme.primary, 'chilla_end_d'),
          ]),
          SectionTitle(s.t('chilla_40_days')),
          // ---------- grid ----------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    for (final d in sum.days)
                      _DayCell(
                        day: d,
                        selected: d.number == sel.number,
                        onTap: () => setState(() => _selected = d.number),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 12, runSpacing: 6, alignment: WrapAlignment.center, children: [
                  for (final st in ChillaDayState.values)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: chillaColor(st, theme), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(chillaStateLabel(s, st), style: theme.textTheme.labelSmall),
                    ]),
                ]),
              ]),
            ),
          ),
          SectionTitle('${s.t('day')} ${sel.number} • ${date(sel.date)}'),
          _DayDetail(day: sel),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('chilla_open_plan'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportScreen())),
            icon: const Icon(Icons.assignment_turned_in),
            label: Text(s.t('my_daily_plan')),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.onTime.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.info, color: AppColors.onTime),
              const SizedBox(width: 10),
              Expanded(
                child: Text(sum.streak >= 3 ? s.t('chilla_keep_going') : s.t('chilla_missed_hint')),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

Color chillaColor(ChillaDayState st, ThemeData theme) => switch (st) {
      ChillaDayState.completed => AppColors.onTime,
      ChillaDayState.partial => AppColors.gold,
      ChillaDayState.missed => AppColors.missed,
      ChillaDayState.today => AppColors.emeraldLight,
      ChillaDayState.upcoming => theme.colorScheme.surfaceContainerHighest,
    };

String chillaStateLabel(S s, ChillaDayState st) => switch (st) {
      ChillaDayState.completed => s.t('completed'),
      ChillaDayState.partial => s.t('partial'),
      ChillaDayState.missed => s.t('missed'),
      ChillaDayState.today => s.t('today'),
      ChillaDayState.upcoming => s.t('upcoming'),
    };

class _DayCell extends StatelessWidget {
  final ChillaDay day;
  final bool selected;
  final VoidCallback onTap;
  const _DayCell({required this.day, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = chillaColor(day.state, theme);
    final strong = day.state != ChillaDayState.upcoming;
    return InkWell(
      key: Key('chilla_cell_${day.number}'),
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: day.state == ChillaDayState.partial ? c.withValues(alpha: 0.35 + day.ratio * 0.5) : c,
          border: selected ? Border.all(color: theme.colorScheme.primary, width: 2.5) : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Text(
              '${day.number}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: strong && day.state != ChillaDayState.partial ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Breakdown of the chilla tasks of one day.
class _DayDetail extends StatelessWidget {
  final ChillaDay day;
  const _DayDetail({required this.day});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    if (day.state == ChillaDayState.upcoming) {
      return Card(
        child: Padding(padding: const EdgeInsets.all(16), child: Text(chillaStateLabel(s, day.state))),
      );
    }
    final rec = state.day(day.date);
    Widget row(String name, String mark, bool ok) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18, color: ok ? AppColors.onTime : theme.colorScheme.outline),
            const SizedBox(width: 8),
            Expanded(child: Text(name)),
            Text(mark, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        );
    Widget group(String title, List<String> ids) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          for (final id in ids)
            if (state.itemById(id) case final it?)
              row(reportItemName(it, urdu), reportMark(state, day.date, it), state.isDone(day.date, it)),
        ]);
    return Card(
      key: const Key('chilla_day_detail'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Text(chillaStateLabel(s, day.state),
                  style: TextStyle(fontWeight: FontWeight.w800, color: chillaColor(day.state, theme))),
            ),
            Text('${day.done}/${day.total}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: day.ratio, minHeight: 6),
          ),
          const SizedBox(height: 4),
          Text(s.t('prayers'), style: const TextStyle(fontWeight: FontWeight.w800)),
          for (final k in prayerKeys)
            row(s.t(k), reportPrayerStatus(rec.prayer(k), urdu), isPrayed(rec.prayer(k))),
          group(s.t('tilawat'), reportTilawatOn(day.date)),
          group(s.t('morning_tasbeehat'), reportMorning),
          group(s.t('evening_tasbeehat'), reportEvening),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String k;
  const _InfoTile(this.icon, this.color, this.label, this.value, this.k);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(children: [
              Icon(icon, color: color),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              FittedBox(
                child: Text(value, key: Key(k), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      );
}
