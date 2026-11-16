import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/routine.dart';
import '../services/hijri.dart';
import '../strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final today = state.today;
    final items = state.routineFor(today);
    final (done, total) = state.completion(today);
    final ratio = total == 0 ? 0.0 : done / total;
    final next = state.calculator.nextPrayer(_now);
    final remaining = next.value.difference(_now.toUtc());
    final hijri = HijriDate.fromGregorian(today, adjustDays: state.settings.hijriAdjust);
    final theme = Theme.of(context);

    final dateLine = urdu
        ? '${weekdaysUr[today.weekday - 1]} • ${today.day} ${monthsUr[today.month - 1]} ${today.year}'
        : '${weekdaysEn[today.weekday - 1].toUpperCase()} • ${today.day} ${monthsEn[today.month - 1].toUpperCase()} ${today.year}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(dateLine, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, letterSpacing: 0.5)),
        Text(hijri.format(urdu), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(s.t('salam'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        Text(s.t('salam_sub'), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        // ---------- Next prayer card ----------
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F7B4A), Color(0xFF0A5C37)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.t('next_prayer'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(s.t(next.key.name),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    Text(formatTime(next.value, urdu: urdu),
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('${s.t('in')} ${formatDuration(remaining.isNegative ? Duration.zero : remaining)}',
                        style: const TextStyle(color: Color(0xFFF3D77A), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.mosque, color: Colors.white24, size: 72),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ---------- Progress card ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 8,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      ),
                      Center(
                        child: Text('${(ratio * 100).round()}%',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.t('todays_progress'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(urdu ? '$total ${s.t('of')} $done ${s.t('completed_of')}' : '$done ${s.t('of')} $total ${s.t('completed_of')}'),
                      if (done == total && total > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(s.t('all_done'), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(s.t('daily_activities'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            Text('$done/$total', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 8),
        for (final section in RoutineSection.values) ..._section(context, state, section, items, today),
      ],
    );
  }

  List<Widget> _section(BuildContext context, AppState state, RoutineSection section, List<RoutineItem> all, DateTime today) {
    final s = state.s;
    final items = all.where((i) => i.section == section).toList();
    if (items.isEmpty) return [];
    final title = switch (section) {
      RoutineSection.earlyMorning => '🌙  ${s.t('sec_early')}',
      RoutineSection.day => '☀️  ${s.t('sec_day')}',
      RoutineSection.night => '🌇  ${s.t('sec_night')}',
    };
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ),
      Card(
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              RoutineTile(item: items[i], date: today),
              if (i < items.length - 1) const Divider(height: 1, indent: 56),
            ],
          ],
        ),
      ),
    ];
  }
}

class RoutineTile extends StatelessWidget {
  final RoutineItem item;
  final DateTime date;
  const RoutineTile({super.key, required this.item, required this.date});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final urdu = state.settings.urdu;
    final s = state.s;
    final done = state.isDone(date, item);
    final theme = Theme.of(context);
    final rec = state.day(date);

    var subtitle = [item.time(urdu), item.target(urdu)].where((e) => e.isNotEmpty).join(' • ');
    if (item.dhikrKey != null) {
      final c = rec.dhikr[item.dhikrKey!] ?? 0;
      subtitle = '$subtitle  ($c/${item.dhikrTarget})';
    }
    if (item.id == 'quran_daily') {
      subtitle = '$subtitle  (${rec.quranPages}/${state.settings.quranTarget} ${s.t('pages')})';
    }

    return ListTile(
      key: Key('routine_${item.id}'),
      onTap: () => state.toggleItem(date, item),
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? theme.colorScheme.primary : Colors.transparent,
          border: Border.all(color: done ? theme.colorScheme.primary : theme.colorScheme.outline, width: 2),
        ),
        child: done ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
      ),
      title: Text(
        item.name(urdu),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? theme.colorScheme.onSurface.withValues(alpha: 0.55) : null,
        ),
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: item.optional
          ? Chip(
              label: Text(s.t('optional'), style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            )
          : (item.fridayOnly ? Text(s.t('friday'), style: TextStyle(color: theme.colorScheme.tertiary)) : null),
    );
  }
}
