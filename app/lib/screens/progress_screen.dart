import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/routine.dart';
import '../strings.dart';
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
  int _range = 1; // 0 week, 1 month, 2 year
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
      0 => today.subtract(const Duration(days: 6)),
      1 => DateTime(today.year, today.month, 1),
      _ => DateTime(today.year, 1, 1),
    };
    final days = state.daysBetween(from, today);
    final stats = state.categoryStats(days);
    final (todayDone, todayTotal) = state.completion(today);

    return Column(
      children: [
        ScreenHeader(
          title: s.t('my_progress'),
          bottom: HeaderTabs(
            labels: [s.t('this_week'), s.t('this_month'), s.t('this_year')],
            index: _range,
            onChanged: (i) => setState(() => _range = i),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    _Tile(icon: Icons.local_fire_department, color: Colors.deepOrange, value: '${state.currentStreak()}', label: s.t('streak')),
                    _Tile(icon: Icons.emoji_events, color: AppColors.gold, value: '${state.bestStreak()}', label: s.t('best_streak')),
                    _Tile(
                      icon: Icons.verified,
                      color: AppColors.onTime,
                      value: '${(stats['overall']! * 100).round()}%',
                      label: s.t('success'),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    ProgressRing(
                      value: stats['overall']!,
                      size: 112,
                      stroke: 11,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(s.t('overall'), style: theme.textTheme.bodySmall),
                        Text('${(stats['overall']! * 100).round()}%',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(children: [
                        _Breakdown(icon: Icons.mosque, label: s.t('namaz'), value: stats['namaz']!),
                        _Breakdown(icon: Icons.menu_book, label: s.t('quran'), value: stats['quran']!),
                        _Breakdown(icon: Icons.auto_awesome, label: s.t('azkar'), value: stats['azkar']!),
                        _Breakdown(icon: Icons.bedtime, label: s.t('tahajjud'), value: stats['tahajjud']!),
                      ]),
                    ),
                  ]),
                ),
              ),
              _ScoreHistory(days: days),
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
                    _chartFor(state, days, urdu),
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
                  ListTile(
                    leading: const IconBadge(Icons.mosque, color: AppColors.jamaat),
                    title: Text(s.t('farz_prayed')),
                    trailing: Text('${days.fold(0, (a, d) => a + state.day(d).farzPrayed)} / ${days.length * 5}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ]),
              ),
              SectionTitle(s.t('activity_calendar')),
              _Calendar(
                month: _calMonth,
                onMonth: (m) => setState(() => _calMonth = m),
              ),
              SectionTitle(s.t('missed_history')),
              _MissedHistory(),
              const SizedBox(height: 8),
              Text(s.t('streak_hint'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
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
    if (_range == 0) {
      for (final d in days) {
        values.add(value(d));
        labels.add((urdu ? weekdaysUr : weekdaysEn)[d.weekday - 1].substring(0, urdu ? 1 : 2));
      }
    } else if (_range == 1) {
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

class _Breakdown extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  const _Breakdown({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text('${(value * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

/// Completed activities, prayers, Quran pages, azkar and remaining tasks of a day.
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
                        color: isToday
                            ? AppColors.emeraldMid
                            : (ratio == 0 ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : AppColors.emeraldLight.withValues(alpha: 0.15 + ratio * 0.7)),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$d',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isToday || ratio > 0.6 ? Colors.white : (future ? theme.colorScheme.outline : null),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ]),
      ),
    );
  }
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


/// Separate Farz / Routine / Optional averages for the selected range, plus
/// prayer statistics (jamaat, alone, qaza, missed) kept apart.
class _ScoreHistory extends StatelessWidget {
  final List<DateTime> days;
  const _ScoreHistory({required this.days});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    final today = state.today;
    var n = 0;
    var farz = 0.0, routine = 0.0, optional = 0.0;
    var jamaat = 0, alone = 0, qaza = 0, missed = 0;
    for (final d in days) {
      if (d != today && !state.hasRecord(d)) continue; // before the app was used
      final sc = state.scoreFor(d);
      n++;
      farz += sc.farz;
      routine += sc.routine;
      optional += sc.optional;
      jamaat += sc.farzJamaat;
      alone += sc.farzOnTime;
      qaza += sc.farzQaza;
      missed += sc.farzMissed;
    }
    String pct(double v) => n == 0 ? '0%' : '${(v / n * 100).round()}%';
    Widget stat(String label, String value, Color c) => Expanded(
          child: Column(children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: c)),
            Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center, maxLines: 2),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        key: const Key('score_history'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(s.t('score_history'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              stat(s.t('farz'), pct(farz), AppColors.jamaat),
              stat(s.t('routine'), pct(routine), AppColors.emeraldMid),
              stat(s.t('optional'), pct(optional), AppColors.gold),
            ]),
            const Divider(height: 24),
            Text(s.t('prayer_stats'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(children: [
              stat(s.t('jamaat'), '$jamaat', AppColors.jamaat),
              stat(s.t('on_time'), '$alone', AppColors.onTime),
              stat(s.t('qaza'), '$qaza', AppColors.delayed),
              stat(s.t('missed'), '$missed', AppColors.missed),
            ]),
          ]),
        ),
      ),
    );
  }
}
