import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/routine.dart';
import '../services/prayer_times.dart';
import '../strings.dart';
import '../widgets/common.dart';
import '../widgets/date_switcher.dart';
import '../widgets/islamic_art.dart';
import 'home_screen.dart' show prayerVisual, showPrayerStatusSheet, statusColor, statusLabel;
import 'settings_screen.dart' show PrayerSettingsScreen, editPrayerTime;

class NamazScreen extends StatefulWidget {
  const NamazScreen({super.key});

  @override
  State<NamazScreen> createState() => _NamazScreenState();
}

class _NamazScreenState extends State<NamazScreen> {
  int _tab = 0;
  DateTime? _date;
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
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
    return Column(
      children: [
        ScreenHeader(
          title: s.t('namaz_tracker'),
          actions: [
            IconButton(
              tooltip: s.t('prayer_settings'),
              icon: const Icon(Icons.tune, color: Colors.white),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayerSettingsScreen())),
            ),
          ],
          bottom: HeaderTabs(
            labels: [s.t('today_total'), s.t('week'), s.t('month')],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_tab) {
              0 => _TodayTab(
                  key: const ValueKey('today'),
                  date: _date ?? state.today,
                  now: _now,
                  onDate: (d) => setState(() => _date = d),
                ),
              1 => const _WeekTab(key: ValueKey('week')),
              _ => const _MonthTab(key: ValueKey('month')),
            },
          ),
        ),
      ],
    );
  }
}

class _TodayTab extends StatelessWidget {
  final DateTime date;
  final DateTime now;
  final ValueChanged<DateTime> onDate;
  const _TodayTab({super.key, required this.date, required this.now, required this.onDate});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final times = state.prayerTimes(date);
    final isToday = date == state.today;
    final next = state.nextPrayer(now);
    final weekDays = [for (var i = 6; i >= 0; i--) state.today.subtract(Duration(days: i))];
    final weekValues = [for (final d in weekDays) state.day(d).farzPrayed / 5];
    final weekAvg = weekValues.fold(0.0, (a, b) => a + b) / 7;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ---------- hero ----------
        if (isToday)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: IslamicHeaderBackground(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                child: Column(children: [
                  Text(s.t(next.key.name),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  Text(formatTime(next.value, urdu: urdu),
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${s.t('upcoming')} • ${s.t('in')} ${formatDuration(next.value.difference(now.toUtc()).isNegative ? Duration.zero : next.value.difference(now.toUtc())).substring(0, 5)}',
                      style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(state.settings.locationName, style: const TextStyle(color: Colors.white70)),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 12),
        DateSwitcher(date: date, onChanged: onDate),
        SectionTitle(s.t('all_prayers')),
        Card(
          child: Column(children: [
            for (final p in PrayerName.values)
              if (p == PrayerName.sunrise)
                ListTile(
                  dense: true,
                  leading: IconBadge(prayerVisual('sunrise').$1, color: prayerVisual('sunrise').$2, size: 32),
                  title: Text(s.t('sunrise')),
                  trailing: Text(formatTime(times[p], urdu: urdu), style: theme.textTheme.bodySmall),
                )
              else
                _PrayerRow(date: date, prayerKey: p.name, time: times[p], now: now),
            const Divider(height: 1),
            CheckboxListTile(
              key: const Key('witr_check'),
              value: state.witrDone(date),
              onChanged: (_) => state.toggleSunnah(date, 'witr'),
              secondary: const IconBadge(Icons.nights_stay, color: Color(0xFF5B4BB7), size: 32),
              title: Text(s.t('witr')),
              subtitle: Text(s.t('witr_hint')),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        Text(s.t('prayer_tap_hint'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        SectionTitle(s.t('prayer_stats')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${(weekAvg * 100).round()}%',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                  Text(s.t('this_week')),
                ]),
                const SizedBox(width: 16),
                Expanded(
                  child: MiniBarChart(
                    values: weekValues,
                    labels: [for (final d in weekDays) (urdu ? weekdaysUr : weekdaysEn)[d.weekday - 1].substring(0, urdu ? 1 : 2)],
                    height: 90,
                    highlight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ---------- qaza ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.t('qaza_pending'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${state.qazaPending}', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
                OutlinedButton(onPressed: () => state.changeQaza(1), child: Text(s.t('qaza_add'))),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: state.qazaPending > 0 ? () => state.changeQaza(-1) : null,
                  child: Text(s.t('qaza_done')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(s.t('disclaimer'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final DateTime date;
  final String prayerKey;
  final DateTime time;
  final DateTime now;
  const _PrayerRow({required this.date, required this.prayerKey, required this.time, required this.now});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final rec = state.day(date);
    final status = rec.prayer(prayerKey);
    final started = !time.isAfter(now.toUtc());
    final (icon, color) = prayerVisual(prayerKey);
    final sunnah = rec.sunnah.contains(prayerKey);

    final label = status != PrayerStatus.none ? statusLabel(s, status) : (started ? s.t('pending') : s.t('upcoming'));
    final labelColor = status != PrayerStatus.none ? statusColor(status) : (started ? AppColors.pending : theme.colorScheme.outline);

    return ExpansionTile(
      key: Key('prayer_$prayerKey'),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: IconBadge(icon, color: color, size: 32),
      title: Row(children: [
        Expanded(child: Text(s.t(prayerKey), style: const TextStyle(fontWeight: FontWeight.w700))),
        if (state.hasFixedTime(prayerKey)) const Icon(Icons.push_pin, size: 14, color: AppColors.gold),
        Text(formatTime(time, urdu: urdu), style: theme.textTheme.bodyMedium),
      ]),
      subtitle: Row(children: [
        Icon(
          isPrayed(status)
              ? Icons.check_circle
              : status == PrayerStatus.missed
                  ? Icons.cancel
                  : (started ? Icons.radio_button_unchecked : Icons.hourglass_bottom),
          size: 14,
          color: labelColor,
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.w600)),
        if (status == PrayerStatus.jamaat) ...[
          const SizedBox(width: 6),
          const Icon(Icons.groups, size: 14, color: AppColors.jamaat),
        ],
        if (sunnah) ...[
          const SizedBox(width: 6),
          Text('+ ${s.t('sunnah')}', style: const TextStyle(fontSize: 11, color: AppColors.gold)),
        ],
      ]),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        if (!started && status == PrayerStatus.none)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(s.t('not_started_yet'), style: theme.textTheme.bodySmall),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in [PrayerStatus.alone, PrayerStatus.jamaat, PrayerStatus.qaza, PrayerStatus.missed])
              ChoiceChip(
                key: Key('status_${prayerKey}_${o.name}'),
                label: Text(statusLabel(s, o)),
                selected: status == o,
                selectedColor: statusColor(o).withValues(alpha: 0.2),
                onSelected: (sel) => state.setPrayer(date, prayerKey, sel ? o : PrayerStatus.none),
              ),
          ],
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          value: sunnah,
          onChanged: (_) => state.toggleSunnah(date, prayerKey),
          title: Text(s.t('sunnah_nafl')),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(
            key: Key('edit_time_$prayerKey'),
            onPressed: () => editPrayerTime(context, state, prayerKey),
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(s.t('edit_time')),
          ),
          TextButton(
            onPressed: () => showPrayerStatusSheet(context, state, date, prayerKey),
            child: Text(s.t('more_options')),
          ),
        ]),
      ],
    );
  }
}

class _WeekTab extends StatelessWidget {
  const _WeekTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final days = [for (var i = 6; i >= 0; i--) state.today.subtract(Duration(days: i))];
    final summary = _summary(state, days);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SummaryCards(summary: summary, total: days.length * 5),
        SectionTitle(s.t('last_7_days')),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: [
              Row(children: [
                const SizedBox(width: 80),
                for (final k in prayerKeys)
                  Expanded(
                    child: Text(s.t(k), textAlign: TextAlign.center, style: theme.textTheme.labelSmall, maxLines: 1),
                  ),
              ]),
              const SizedBox(height: 6),
              for (final d in days.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(
                      width: 80,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 12),
                        child: Text(
                          '${(urdu ? weekdaysUr : weekdaysEn)[d.weekday - 1].substring(0, urdu ? null : 3)} ${d.day}',
                          style: TextStyle(fontWeight: d == state.today ? FontWeight.w800 : FontWeight.w500),
                        ),
                      ),
                    ),
                    for (final k in prayerKeys)
                      Expanded(
                        child: Center(child: _StatusDot(status: state.day(d).prayer(k))),
                      ),
                  ]),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        _Legend(),
      ],
    );
  }
}

class _MonthTab extends StatelessWidget {
  const _MonthTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    final days = [for (var i = 29; i >= 0; i--) state.today.subtract(Duration(days: i))];
    final summary = _summary(state, days);
    final sunnahCount = days.fold(0, (a, d) => a + state.day(d).sunnah.where((k) => prayerKeys.contains(k)).length);
    final witrCount = days.where((d) => state.witrDone(d)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SummaryCards(summary: summary, total: days.length * 5),
        SectionTitle(s.t('last_30_days')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final d in days)
                  Tooltip(
                    message: '${dayKey(d)}: ${state.day(d).farzPrayed}/5',
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08 + 0.8 * state.day(d).farzPrayed / 5),
                        borderRadius: BorderRadius.circular(8),
                        border: d == state.today ? Border.all(color: AppColors.gold, width: 2) : null,
                      ),
                      child: Text(
                        '${d.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: state.day(d).farzPrayed >= 3 ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(s.t('heatmap_hint'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.add_task, color: AppColors.gold),
              title: Text(s.t('sunnah_nafl')),
              trailing: Text('$sunnahCount', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: const Icon(Icons.nights_stay, color: Color(0xFF5B4BB7)),
              title: Text(s.t('witr')),
              trailing: Text('$witrCount / ${days.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ],
    );
  }
}

Map<PrayerStatus, int> _summary(AppState state, List<DateTime> days) {
  final m = {for (final st in PrayerStatus.values) st: 0};
  for (final d in days) {
    final rec = state.day(d);
    for (final k in prayerKeys) {
      final st = rec.prayer(k);
      m[st] = m[st]! + 1;
    }
  }
  return m;
}

class _SummaryCards extends StatelessWidget {
  final Map<PrayerStatus, int> summary;
  final int total;
  const _SummaryCards({required this.summary, required this.total});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    final prayed = summary[PrayerStatus.alone]! + summary[PrayerStatus.jamaat]! + summary[PrayerStatus.qaza]!;
    final theme = Theme.of(context);
    Widget tile(String label, int v, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text('$v', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
              Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
            ]),
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            ProgressRing(
              value: total == 0 ? 0 : prayed / total,
              size: 64,
              child: Text('${total == 0 ? 0 : (prayed * 100 / total).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('$prayed / $total ${s.t('farz_prayed')}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            tile(s.t('with_jamaat'), summary[PrayerStatus.jamaat]!, AppColors.jamaat),
            const SizedBox(width: 6),
            tile(s.t('on_time'), summary[PrayerStatus.alone]!, AppColors.onTime),
            const SizedBox(width: 6),
            tile(s.t('delayed'), summary[PrayerStatus.qaza]!, AppColors.delayed),
            const SizedBox(width: 6),
            tile(s.t('missed'), summary[PrayerStatus.missed]!, AppColors.missed),
          ]),
        ]),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final PrayerStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = status == PrayerStatus.none ? Theme.of(context).colorScheme.outlineVariant : statusColor(status);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: status == PrayerStatus.none ? Colors.transparent : c,
        shape: BoxShape.circle,
        border: Border.all(color: c, width: 2),
      ),
      child: status == PrayerStatus.jamaat
          ? const Icon(Icons.groups, size: 12, color: Colors.white)
          : (isPrayed(status) ? const Icon(Icons.check, size: 12, color: Colors.white) : null),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final st in [PrayerStatus.jamaat, PrayerStatus.alone, PrayerStatus.qaza, PrayerStatus.missed, PrayerStatus.none])
          Row(mainAxisSize: MainAxisSize.min, children: [
            _StatusDot(status: st),
            const SizedBox(width: 4),
            Text(statusLabel(s, st), style: const TextStyle(fontSize: 12)),
          ]),
      ],
    );
  }
}
