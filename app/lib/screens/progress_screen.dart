import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/routine.dart';
import '../strings.dart';
import '../services/report.dart';
import '../widgets/common.dart';
import 'home_screen.dart' show statusColor, statusLabel;
import 'muhasaba_screen.dart';
import 'navigation.dart' show tryToggle;

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _range = 1; // 0 day, 1 week, 2 month, 3 year
  int _chart = 0; // 0 namaz, 1 quran, 2 azkar
  late DateTime _calMonth;
  bool _init = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final today = state.today;
    if (!_init) {
      _calMonth = DateTime(today.year, today.month);
      _init = true;
    }

    final from = switch (_range) {
      0 => today,
      1 => today.subtract(const Duration(days: 6)),
      2 => DateTime(today.year, today.month, 1),
      _ => DateTime(today.year, 1, 1),
    };
    final days = state.daysBetween(from, today);
    // Same-length previous period, for the trend arrow.
    final span = days.length;
    final prevDays = state.daysBetween(from.subtract(Duration(days: span)), from.subtract(const Duration(days: 1)));
    final rep = buildRangeReport(state, days);
    final prev = buildRangeReport(state, prevDays);
    final last7 = state.daysBetween(today.subtract(const Duration(days: 6)), today);
    final weekly = buildRangeReport(state, last7);
    final (todayDone, todayTotal) = state.completion(today);
    final periodLabel = [s.t('today'), s.t('this_week'), s.t('this_month'), s.t('this_year')][_range];
    int pct(double v) => (v * 100).round();
    final delta = pct(rep.overall) - pct(prev.overall);

    return Column(
      children: [
        ScreenHeader(
          title: s.t('reports_analytics'),
          bottom: HeaderTabs(
            labels: [s.t('day_tab'), s.t('week_tab'), s.t('month_tab'), s.t('year_tab')],
            index: _range,
            onChanged: (i) => setState(() => _range = i),
          ),
        ),
        Expanded(
          child: ListView(
            key: const Key('reports_list'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // ---------- score tiles ----------
              Row(children: [
                _ScoreTile(key: const Key('tile_daily'), delta: _range == 0 ? null : pct(rep.overall) - pct(prev.overall), icon: Icons.stars, color: AppColors.onTime,
                    value: '${pct(rep.overall)}%', label: s.t('daily_score')),
                const SizedBox(width: 8),
                _ScoreTile(key: const Key('tile_farz'), delta: _range == 0 ? null : pct(rep.farz) - pct(prev.farz), icon: Icons.mosque, color: AppColors.jamaat,
                    value: '${pct(rep.farz)}%', label: s.t('farz_score')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _ScoreTile(key: const Key('tile_routine'), delta: _range == 0 ? null : pct(rep.routine) - pct(prev.routine), icon: Icons.task_alt, color: AppColors.emeraldMid,
                    value: '${pct(rep.routine)}%', label: s.t('routine_score')),
                const SizedBox(width: 8),
                _ScoreTile(key: const Key('tile_optional'), delta: _range == 0 ? null : pct(rep.optional) - pct(prev.optional), icon: Icons.star, color: AppColors.gold,
                    value: '${pct(rep.optional)}%', label: s.t('optional')),
              ]),
              const SizedBox(height: 12),
              // ---------- prayer stats + ring ----------
              Card(
                key: const Key('prayer_stats_card'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(s.t('prayer_stats'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Expanded(
                        child: Column(children: [
                          for (final k in prayerKeys)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(children: [
                                Expanded(child: Text(s.t(k))),
                                Text('${rep.perPrayer[k]?.$1 ?? 0}/${rep.perPrayer[k]?.$2 ?? 0}',
                                    key: Key('pstat_$k'), style: theme.textTheme.bodySmall),
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    '${(rep.perPrayer[k]?.$2 ?? 0) == 0 ? 0 : (rep.perPrayer[k]!.$1 * 100 / rep.perPrayer[k]!.$2).round()}%',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ]),
                            ),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Column(children: [
                        ProgressRing(
                          value: rep.overall,
                          size: 104,
                          stroke: 10,
                          color: AppColors.onTime,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            FittedBox(child: Text(periodLabel, style: theme.textTheme.labelSmall)),
                            Text('${pct(rep.overall)}%',
                                key: const Key('report_overall'),
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          ]),
                        ),
                        const SizedBox(height: 4),
                        if (_range > 0)
                          Text(
                            '${delta >= 0 ? '↑' : '↓'} ${delta >= 0 ? '+' : ''}$delta%',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, color: delta >= 0 ? AppColors.onTime : AppColors.missed),
                          ),
                      ]),
                    ]),
                    const Divider(height: 22),
                    Row(children: [
                      _Mini(s.t('jamaat'), '${rep.jamaat}', AppColors.jamaat, 'rb_jamaat'),
                      _Mini(s.t('on_time'), '${rep.alone}', AppColors.onTime, 'rb_alone'),
                      _Mini(s.t('qaza'), '${rep.qaza}', AppColors.delayed, 'rb_qaza'),
                      _Mini(s.t('missed'), '${rep.missed}', AppColors.missed, 'rb_missed'),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              // ---------- Quran + Azkar ----------
              Card(
                key: const Key('quran_azkar_card'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      const IconBadge(Icons.menu_book, color: AppColors.emeraldMid, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.t('quran'), style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${rep.pages} ${s.t('pages')} • ${s.t('target_met')} ${rep.quranTargetDays}/${rep.days}',
                              style: theme.textTheme.bodySmall),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _Bar(s.t('khatam'), state.khatamPages / quranTotalPages,
                        '${state.khatamPages}/$quranTotalPages', AppColors.emeraldMid),
                    const Divider(height: 22),
                    Text(s.t('azkar'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    _Bar(s.t('morning_azkar'), rep.days == 0 ? 0 : rep.morning / rep.days, '${rep.morning}/${rep.days}',
                        const Color(0xFFE09A2D)),
                    _Bar(s.t('evening_azkar'), rep.days == 0 ? 0 : rep.evening / rep.days, '${rep.evening}/${rep.days}',
                        const Color(0xFF7A5BC4)),
                    _Bar(s.t('sleep_azkar'), rep.days == 0 ? 0 : rep.sleep / rep.days, '${rep.sleep}/${rep.days}',
                        const Color(0xFF2E5E8C)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              // ---------- streaks ----------
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    _Tile(icon: Icons.local_fire_department, color: Colors.deepOrange, value: '${state.currentStreak()}', label: s.t('streak')),
                    _Tile(icon: Icons.emoji_events, color: AppColors.gold, value: '${state.bestStreak()}', label: s.t('best_streak')),
                    _Tile(icon: Icons.verified, color: AppColors.onTime, value: '${pct(rep.overall)}%', label: s.t('daily_completion')),
                  ]),
                ),
              ),
              // ---------- weekly progress ----------
              SectionTitle(s.t('weekly_progress')),
              Card(
                key: const Key('weekly_chart'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: MiniBarChart(
                    values: [
                      for (final d in last7)
                        weekly.daily.where((e) => e.$1 == d).map((e) => e.$2).firstOrNull ?? 0,
                    ],
                    labels: [for (final d in last7) (urdu ? weekdaysUr : weekdaysEn)[d.weekday - 1].substring(0, urdu ? 1 : 3)],
                    height: 110,
                    highlight: 6,
                  ),
                ),
              ),
              SectionTitle(s.t('monthly_calendar')),
              _Calendar(
                month: _calMonth,
                onMonth: (m) => setState(() => _calMonth = m),
              ),
              SectionTitle(s.t('todays_summary'),
                  actionLabel: s.t('muhasaba'),
                  onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MuhasabaScreen(date: today)))),
              _DaySummary(date: today, done: todayDone, total: todayTotal),
              SectionTitle(s.t('charts')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(children: [
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: 0, label: Text(s.t('namaz'))),
                        ButtonSegment(value: 1, label: Text(s.t('quran'))),
                        ButtonSegment(value: 2, label: Text(s.t('azkar'))),
                      ],
                      selected: {_chart},
                      onSelectionChanged: (v) => setState(() => _chart = v.first),
                    ),
                    const SizedBox(height: 14),
                    _chartFor(state, _range == 0 ? last7 : days, urdu),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(children: [
                  ListTile(
                    leading: const IconBadge(Icons.touch_app, color: Color(0xFF7A5BC4)),
                    title: Text(s.t('total_dhikr')),
                    trailing: Text('${state.totalDhikr(days)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  ListTile(
                    leading: const IconBadge(Icons.menu_book, color: AppColors.emeraldMid),
                    title: Text(s.t('quran_pages_read')),
                    trailing: Text('${state.totalPages(days)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ]),
              ),
              SectionTitle(s.t('missed_history')),
              _MissedHistory(),
              const SizedBox(height: 8),
              Text(s.t('score_hint'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chartFor(AppState state, List<DateTime> days, bool urdu) {
    final target = state.settings.quranTarget <= 0 ? 1 : state.settings.quranTarget;
    double value(DateTime d) {
      final rec = state.day(d);
      return switch (_chart) {
        0 => rec.farzPrayed / 5,
        1 => (rec.quranPages / target).clamp(0.0, 1.0).toDouble(),
        _ => ((rec.done.contains('morning_azkar') ? 1 : 0) +
                (rec.done.contains('evening_azkar') ? 1 : 0) +
                (rec.done.contains('sleep_azkar') ? 1 : 0)) /
            3,
      };
    }

    // Bucket: per day (week), per week (month), per month (year).
    final values = <double>[];
    final labels = <String>[];
    if (_range <= 1) {
      for (final d in days) {
        values.add(value(d));
        labels.add((urdu ? weekdaysUr : weekdaysEn)[d.weekday - 1].substring(0, urdu ? 1 : 2));
      }
    } else if (_range == 2) {
      for (var i = 0; i < days.length; i += 7) {
        final chunk = days.sublist(i, (i + 7).clamp(0, days.length).toInt());
        values.add(chunk.fold(0.0, (a, d) => a + value(d)) / chunk.length);
        labels.add('${chunk.first.day}-${chunk.last.day}');
      }
    } else {
      for (var m = 1; m <= days.last.month; m++) {
        final chunk = days.where((d) => d.month == m).toList();
        values.add(chunk.isEmpty ? 0 : chunk.fold(0.0, (a, d) => a + value(d)) / chunk.length);
        labels.add((urdu ? monthsUr : monthsEn)[m - 1].substring(0, urdu ? null : 3));
      }
    }
    return MiniBarChart(values: values, labels: labels, height: 130, highlight: values.length - 1);
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _Tile({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _DaySummary extends StatelessWidget {
  final DateTime date;
  final int done;
  final int total;
  const _DaySummary({required this.date, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final rec = state.day(date);
    final azkarDone = ['morning_azkar', 'evening_azkar', 'sleep_azkar'].where(rec.done.contains).length;
    Widget cell(IconData icon, String value, String label, Color color) => Expanded(
          child: Column(children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11)),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          cell(Icons.task_alt, '$done', s.t('completed'), AppColors.onTime),
          cell(Icons.mosque, '${rec.farzPrayed}/5', s.t('prayers'), AppColors.jamaat),
          cell(Icons.menu_book, '${rec.quranPages}', s.t('pages'), AppColors.emeraldMid),
          cell(Icons.auto_awesome, '$azkarDone/3', s.t('azkar'), const Color(0xFFE09A2D)),
          cell(Icons.pending_actions, '${total - done}', s.t('remaining'), AppColors.missed),
        ]),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onMonth;
  const _Calendar({required this.month, required this.onMonth});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final today = state.today;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday % 7; // Sunday first
    final canNext = DateTime(month.year, month.month + 1, 1).isBefore(today) || DateTime(month.year, month.month + 1, 1) == today;
    final names = urdu ? weekdaysUr : weekdaysEn;
    final header = [names[6], ...names.sublist(0, 6)];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
            ),
            Expanded(
              child: Text('${(urdu ? monthsUr : monthsEn)[month.month - 1]} ${month.year}',
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canNext ? () => onMonth(DateTime(month.year, month.month + 1)) : null,
            ),
          ]),
          Row(children: [
            for (final h in header)
              Expanded(
                child: Text(h.substring(0, urdu ? 1 : 3), textAlign: TextAlign.center, style: theme.textTheme.labelSmall),
              ),
          ]),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++)
                Builder(builder: (context) {
                  final date = DateTime(month.year, month.month, d);
                  final future = date.isAfter(today);
                  final ratio = future || !state.hasRecord(date) ? 0.0 : state.completionRatio(date);
                  final isToday = date == today;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: future ? null : () => showDaySummary(context, date),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: heatColor(state, date, ratio, theme),
                        shape: BoxShape.circle,
                        border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2.5) : null,
                      ),
                      child: Text(
                        '$d',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: !future && state.hasRecord(date) ? Colors.white : (future ? theme.colorScheme.outline : null),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 14, alignment: WrapAlignment.center, children: [
            for (final (label, color) in [
              (state.s.t('done'), AppColors.onTime),
              (state.s.t('partial'), AppColors.gold),
              (state.s.t('missed'), AppColors.missed),
            ])
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(label, style: theme.textTheme.labelSmall),
              ]),
          ]),
        ]),
      ),
    );
  }
}

/// Heatmap colour: done (>= 80%), partial, missed; days without data stay grey.
Color heatColor(AppState state, DateTime date, double ratio, ThemeData theme) {
  if (date.isAfter(state.today) || !state.hasRecord(date)) {
    return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
  }
  if (ratio >= 0.8) return AppColors.onTime;
  if (ratio > 0) return AppColors.gold;
  if (date == state.today) return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
  return AppColors.missed;
}

/// Bottom sheet with the summary of a past day.
Future<void> showDaySummary(BuildContext context, DateTime date) {
  final state = AppScope.of(context);
  final s = state.s;
  final urdu = state.settings.urdu;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (c) {
      final rec = state.day(date);
      final items = state.routineFor(date);
      final (done, total) = state.completion(date);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (c, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              '${(urdu ? weekdaysUr : weekdaysEn)[date.weekday - 1]}, ${date.day} ${(urdu ? monthsUr : monthsEn)[date.month - 1]} ${date.year}',
              style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _DaySummary(date: date, done: done, total: total),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final k in prayerKeys)
                Chip(
                  label: Text('${s.t(k)}: ${statusLabel(s, rec.prayer(k))}'),
                  backgroundColor: statusColor(rec.prayer(k)).withValues(alpha: 0.12),
                ),
            ]),
            const SizedBox(height: 10),
            for (final it in items)
              ListTile(
                dense: true,
                leading: Icon(
                  state.isDone(date, it)
                      ? Icons.check_circle
                      : state.isSkipped(date, it)
                          ? Icons.skip_next
                          : Icons.radio_button_unchecked,
                  color: state.isDone(date, it) ? AppColors.onTime : null,
                ),
                title: Text(it.name(urdu)),
                onTap: () => tryToggle(context, state, date, it),
              ),
            if (rec.note.isNotEmpty || rec.muhasaba.isNotEmpty) ...[
              const Divider(),
              Text(s.t('muhasaba'), style: const TextStyle(fontWeight: FontWeight.w700)),
              if (rec.note.isNotEmpty) Text(rec.note),
              for (final e in rec.muhasaba.entries) Text('• ${s.t('m_${e.key}')}: ${e.value}'),
            ],
          ],
        ),
      );
    },
  );
}

class _MissedHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final history = state.missedHistory(14);
    final most = state.mostMissed(30);
    if (history.isEmpty) {
      return Card(child: EmptyState(icon: Icons.verified_outlined, text: s.t('no_missed')));
    }
    return Card(
      child: Column(children: [
        if (most.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final e in most)
                Chip(
                  avatar: const Icon(Icons.warning_amber, size: 16, color: AppColors.missed),
                  label: Text('${e.key.name(urdu)} ×${e.value}'),
                ),
            ]),
          ),
        for (final e in history.take(10))
          ExpansionTile(
            shape: const Border(),
            title: Text('${(urdu ? weekdaysUr : weekdaysEn)[e.key.weekday - 1]} ${e.key.day}/${e.key.month}'),
            subtitle: Text('${e.value.length} ${s.t('missed').toLowerCase()}'),
            children: [
              for (final it in e.value)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.close, color: AppColors.missed, size: 18),
                  title: Text(it.name(urdu)),
                ),
            ],
          ),
      ]),
    );
  }
}


class _ScoreTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final int? delta; // change vs the previous period, in points
  const _ScoreTile(
      {super.key, required this.icon, required this.color, required this.value, required this.label, this.delta});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          if (delta != null)
            Text('${delta! >= 0 ? '↑ +' : '↓ '}$delta%',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: delta! >= 0 ? AppColors.onTime : AppColors.missed)),
        ]),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String k;
  const _Mini(this.label, this.value, this.color, this.k);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, key: Key(k), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
          Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center, maxLines: 2),
        ]),
      );
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  final String detail;
  final Color color;
  const _Bar(this.label, this.value, this.detail, this.color);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 96, child: Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(detail, style: theme.textTheme.labelSmall),
          ),
        ),
      ]),
    );
  }
}
