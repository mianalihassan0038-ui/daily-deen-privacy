import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/azkar.dart';
import '../data/routine.dart';
import '../services/hijri.dart';
import '../services/prayer_times.dart';
import '../strings.dart';
import '../widgets/common.dart';
import '../widgets/islamic_art.dart';
import 'azkar_screen.dart';
import 'chilla_screen.dart';
import 'more_screen.dart';
import 'navigation.dart';
import 'report_screen.dart';
import '../services/report.dart';
import 'routine_screen.dart';
import 'settings_screen.dart';
import 'shell.dart';
import '../services/schedule.dart';
import '../services/scoring.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = clock();
  bool _showEarlier = false;
  bool _resumed = true;

  bool get _visible => shellTab.value == Tabs.home && _resumed;

  /// Ticks every second only while Home is visible and the app is in the
  /// foreground (for countdowns); otherwise no timer runs.
  void _syncTimer() {
    if (_visible) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = clock());
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _onTab() {
    _syncTimer();
    if (_visible && mounted) setState(() => _now = clock());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    shellTab.addListener(_onTab);
    _syncTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    _resumed = s == AppLifecycleState.resumed;
    _syncTimer();
    if (!mounted) return;
    final state = AppScope.of(context);
    if (_resumed) {
      setState(() => _now = clock());
      state.onResume();
    } else if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
      state.flush(); // make sure pending writes reach disk
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    shellTab.removeListener(_onTab);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final entries = state.scheduleFor(today, now: now);
    final open = [...state.carriedOver(now: now), ...entries.where((e) => e.isOpen)];
    final upcoming = entries.where((e) => e.state == ActivityState.upcoming).toList();
    final earlier = entries
        .where((e) =>
            e.state == ActivityState.completed || e.state == ActivityState.missed || e.state == ActivityState.skipped)
        .toList()
        .reversed
        .toList();

    // Current focus: an open prayer first, then the earliest open mandatory
    // activity, then optional; otherwise the next upcoming activity (locked).
    ScheduledActivity? current;
    for (final e in open) {
      if (e.item.prayerKey != null) {
        current = e;
        break;
      }
    }
    current ??= open.where((e) => !e.item.optional).firstOrNull ?? open.firstOrNull;
    final isUpcoming = current == null && upcoming.isNotEmpty;
    current ??= upcoming.firstOrNull;
    final otherOpen = open.where((e) => e != current).toList();
    final nextUp = upcoming.where((e) => e != current).take(4).toList();
    final completedCount = earlier.where((e) => e.state == ActivityState.completed).length;
    final missedCount = earlier.where((e) => e.state == ActivityState.missed).length;

    return ListView(
      key: const Key('home_list'),
      padding: EdgeInsets.zero,
      children: [
        _Header(now: now),
        Transform.translate(
          offset: const Offset(0, -26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScoreCard(score: state.scoreFor(today, now: now)),
                const SizedBox(height: 12),
                if (!state.prayerTimes(today).reliable) ...[
                  Card(
                    color: AppColors.delayed.withValues(alpha: 0.15),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber, color: AppColors.delayed),
                      title: Text(s.t('times_unreliable')),
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayerSettingsScreen())),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (current != null) _NowCard(entry: current, upcoming: isUpcoming, now: now),
                if (current == null && entries.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        const Icon(Icons.celebration, color: AppColors.gold),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s.t('all_done'), style: const TextStyle(fontWeight: FontWeight.w700))),
                      ]),
                    ),
                  ),
                if (otherOpen.isNotEmpty) ...[
                  _ListLabel('${s.t('now_available')} (${otherOpen.length})', AppColors.onTime),
                  Card(
                    key: const Key('now_section'),
                    child: Column(children: [
                      for (var i = 0; i < otherOpen.length; i++) ...[
                        RoutineTile(item: otherOpen[i].item, date: otherOpen[i].date, now: now),
                        if (i < otherOpen.length - 1) const Divider(indent: 60),
                      ],
                    ]),
                  ),
                ],
                if (nextUp.isNotEmpty) ...[
                  SectionTitle(
                    s.t('coming_up'),
                    actionLabel: s.t('full_schedule'),
                    onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutineScreen())),
                  ),
                  Card(
                    key: const Key('upcoming_section'),
                    child: Column(children: [
                      for (final e in nextUp) RoutineTile(item: e.item, date: e.date, now: now),
                    ]),
                  ),
                ],
                if (earlier.isNotEmpty) ...[
                  InkWell(
                    key: const Key('earlier_toggle'),
                    onTap: () => setState(() => _showEarlier = !_showEarlier),
                    child: Row(children: [
                      Expanded(
                        child: _ListLabel(
                          '${s.t('earlier_today')}  ✓ $completedCount   ✗ $missedCount',
                          theme.colorScheme.outline,
                        ),
                      ),
                      Icon(_showEarlier ? Icons.expand_less : Icons.expand_more),
                    ]),
                  ),
                  if (_showEarlier)
                    Card(
                      key: const Key('earlier_section'),
                      child: Column(children: [
                        for (final e in earlier) RoutineTile(item: e.item, date: e.date, now: now),
                      ]),
                    ),
                ],
                const SizedBox(height: 12),
                const _PlanCard(),
                SectionTitle(s.t('todays_prayers'),
                    actionLabel: s.t('view_all'), onAction: () => ShellScope.go(context, Tabs.namaz)),
                _TodayPrayers(now: now),
                SectionTitle(s.t('quick_track')),
                _QuickGrid(),
                SectionTitle(s.t('dua_of_day')),
                const _DuaOfDayCard(),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      color: Colors.deepOrange,
                      value: '${state.currentStreak()}',
                      label: s.t('current_streak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.emoji_events,
                      color: AppColors.gold,
                      value: '${state.bestStreak()}',
                      label: s.t('best_streak'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('more_features'),
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoreFeaturesScreen())),
                  icon: const Icon(Icons.apps),
                  label: Text(s.t('more_features')),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                ),
                const SizedBox(height: 8),
                Text(s.t('score_hint'), textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ListLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _ListLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime now;
  const _Header({required this.now});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final today = state.today;
    final hijri = HijriDate.fromGregorian(today, adjustDays: state.settings.hijriAdjust);
    final name = state.settings.userName.trim();
    final dateLine = urdu
        ? '${weekdaysUr[today.weekday - 1]}، ${today.day} ${monthsUr[today.month - 1]} ${today.year}  •  ${hijri.format(true)}'
        : '${weekdaysEn[today.weekday - 1].substring(0, 3)}, ${today.day} ${monthsEn[today.month - 1].substring(0, 3)} ${today.year}  •  ${hijri.format(false)}';
    final photo = state.settings.profileImage;

    return IslamicHeaderBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 46),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? s.t('salam') : '${s.t('salam_comma')} $name 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(dateLine, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.goldLight),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(state.settings.locationName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.goldLight, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ],
                ),
              ),
              Column(children: [
                IconButton(
                  key: const Key('settings_button'),
                  tooltip: s.t('settings'),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15)),
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                if (photo != null && File(photo).existsSync())
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: CircleAvatar(radius: 18, backgroundImage: FileImage(File(photo))),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final DayScore score;
  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    Widget bar(String label, double v, String detail, Color c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(width: 72, child: Text(label, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: v, minHeight: 7, color: c, backgroundColor: c.withValues(alpha: 0.14)),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(detail, style: theme.textTheme.labelSmall),
              ),
            ),
          ]),
        );
    return Card(
      key: const Key('score_card'),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ShellScope.go(context, Tabs.progress),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              ProgressRing(
                value: score.overall,
                size: 76,
                stroke: 8,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${(score.overall * 100).round()}%',
                      key: const Key('home_percent'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.t('your_daily_progress'),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 10, runSpacing: 4, children: [
                    _Count(Icons.check_circle, AppColors.onTime, '${score.done}', s.t('completed')),
                    _Count(Icons.timelapse, AppColors.pending, '${score.active}', s.t('remaining')),
                    _Count(Icons.cancel, AppColors.missed, '${score.missed}', s.t('missed')),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            bar(s.t('farz'), score.farz, '${score.farzDone}/${score.farzDue}', AppColors.jamaat),
            bar(s.t('routine'), score.routine, '${score.routineDone}/${score.routineDue}', AppColors.emeraldLight),
            bar(s.t('optional'), score.optional, '${score.optionalDone}/${score.optionalDue}', AppColors.gold),
          ]),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _Count(this.icon, this.color, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 3),
      Text('$value $label', style: Theme.of(context).textTheme.labelSmall),
    ]);
  }
}

/// The activity the user should focus on now (or the next one, locked).
class _NowCard extends StatelessWidget {
  final ScheduledActivity entry;
  final bool upcoming;
  final DateTime now;
  const _NowCard({required this.entry, required this.upcoming, required this.now});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final item = entry.item;
    final w = entry.window;
    final progress = state.countedProgress(item, entry.date);
    final remaining = (upcoming ? w.start : w.end).difference(now);
    final (icon, color) = categoryVisual(item.category);
    final yesterday = entry.date.isBefore(DateTime(now.year, now.month, now.day));
    final next = state.nextPrayer(now);
    final toNext = next.value.difference(now.toUtc());

    String cta;
    VoidCallback? onCta;
    if (upcoming) {
      cta = '${s.t('locked_until')} ${formatTime(w.start, urdu: urdu)}';
    } else if (item.prayerKey != null) {
      cta = s.t('mark_prayed');
      onCta = () => showPrayerStatusSheet(context, state, entry.date, item.prayerKey!);
    } else if (progress != null) {
      cta = progress.$1 > 0 ? '${s.t('continue')} (${progress.$1}/${progress.$2})' : s.t('start_now');
      onCta = () => openActivity(context, item, entry.date);
    } else if (hasOwnScreen(item)) {
      cta = s.t('start_now');
      onCta = () => openActivity(context, item, entry.date);
    } else {
      cta = s.t('mark_completed');
      onCta = () => tryToggle(context, state, entry.date, item);
    }

    return Card(
      key: const Key('now_card'),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: upcoming ? theme.colorScheme.outline : AppColors.emeraldLight, width: 5),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(upcoming ? s.t('next_activity') : s.t('current_activity'),
                  style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.outline)),
            ),
            StateChip(state: upcoming ? ActivityState.upcoming : entry.state),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            IconBadge(icon, color: color, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name(urdu) + (yesterday ? ' (${s.t('yesterday')})' : ''),
                    key: const Key('now_title'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                Text('${formatTime(w.start, urdu: urdu)} – ${formatTime(w.end, urdu: urdu)}',
                    style: theme.textTheme.bodySmall),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${upcoming ? s.t('starts_in') : s.t('time_left')}  ${formatDuration(remaining.isNegative ? Duration.zero : remaining)}',
              key: const Key('countdown'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
            ),
          ),
          if (progress != null && !upcoming) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.$2 == 0 ? 0 : (progress.$1 / progress.$2).clamp(0.0, 1.0).toDouble(),
                minHeight: 7,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('now_cta'),
              onPressed: onCta,
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(cta)),
            ),
          ),
          if (item.prayerKey == null) ...[
            const SizedBox(height: 8),
            Text(
              '${s.t('next_prayer_title')}: ${s.t(next.key.name)} ${formatTime(next.value, urdu: urdu)} • '
              '${formatDuration(toNext.isNegative ? Duration.zero : toNext)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ]),
      ),
    );
  }
}

/// Small coloured label for an activity state.
class StateChip extends StatelessWidget {
  final ActivityState state;
  const StateChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    final (label, color, icon) = stateVisual(s, state, Theme.of(context).colorScheme.outline);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

(String, Color, IconData) stateVisual(S s, ActivityState st, Color neutral) => switch (st) {
      ActivityState.upcoming => (s.t('upcoming'), neutral, Icons.lock_clock),
      ActivityState.active => (s.t('active'), AppColors.onTime, Icons.play_circle_outline),
      ActivityState.inProgress => (s.t('in_progress'), AppColors.pending, Icons.timelapse),
      ActivityState.completed => (s.t('completed'), AppColors.onTime, Icons.check_circle),
      ActivityState.missed => (s.t('missed'), AppColors.missed, Icons.warning_amber),
      ActivityState.skipped => (s.t('skipped'), AppColors.delayed, Icons.skip_next),
    };

/// Icon + colour per prayer.
(IconData, Color) prayerVisual(String key) => switch (key) {
      'fajr' => (Icons.wb_twilight, const Color(0xFF3E7BC4)),
      'sunrise' => (Icons.wb_sunny_outlined, const Color(0xFFE0A030)),
      'dhuhr' => (Icons.wb_sunny, const Color(0xFFE09A2D)),
      'asr' => (Icons.light_mode, const Color(0xFFD9822B)),
      'maghrib' => (Icons.wb_twilight, const Color(0xFFD45A3A)),
      _ => (Icons.nightlight_round, const Color(0xFF5B4BB7)),
    };

class _TodayPrayers extends StatelessWidget {
  final DateTime now;
  const _TodayPrayers({required this.now});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final today = state.today;
    final times = state.prayerTimes(today);
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: [
          for (final key in prayerKeys)
            Builder(builder: (context) {
              final p = PrayerName.values.firstWhere((e) => e.name == key);
              final status = state.effectivePrayerStatus(today, key, now: now);
              final started = state.canRecordPrayer(today, key, now: now);
              final (icon, color) = prayerVisual(key);
              return ListTile(
                key: Key('home_prayer_$key'),
                dense: true,
                leading: IconBadge(icon, color: color, size: 34),
                title: Text(s.t(key), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(formatTime(times[p], urdu: urdu)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (status != PrayerStatus.none)
                    Text(statusLabel(s, status), style: TextStyle(fontSize: 11, color: statusColor(status)))
                  else
                    Text(started ? s.t('pending') : s.t('locked'),
                        style: TextStyle(fontSize: 11, color: started ? AppColors.pending : theme.colorScheme.outline)),
                  const SizedBox(width: 6),
                  Icon(
                    isPrayed(status)
                        ? Icons.check_circle
                        : status == PrayerStatus.missed
                            ? Icons.cancel
                            : (started ? Icons.radio_button_unchecked : Icons.lock_clock),
                    color: isPrayed(status) || status == PrayerStatus.missed ? statusColor(status) : theme.colorScheme.outline,
                  ),
                ]),
                onTap: () => trySetPrayer(context, state, today, key, isPrayed(status) ? PrayerStatus.none : PrayerStatus.alone),
                onLongPress: () => showPrayerStatusSheet(context, state, today, key),
              );
            }),
        ],
      ),
    );
  }
}

String statusLabel(S s, PrayerStatus st) => switch (st) {
      PrayerStatus.none => s.t('pending'),
      PrayerStatus.alone => s.t('on_time'),
      PrayerStatus.jamaat => s.t('with_jamaat'),
      PrayerStatus.qaza => s.t('delayed'),
      PrayerStatus.missed => s.t('missed'),
    };

Color statusColor(PrayerStatus st) => switch (st) {
      PrayerStatus.none => AppColors.pending,
      PrayerStatus.alone => AppColors.onTime,
      PrayerStatus.jamaat => AppColors.jamaat,
      PrayerStatus.qaza => AppColors.delayed,
      PrayerStatus.missed => AppColors.missed,
    };

/// Bottom sheet to set a prayer's status manually.
Future<void> showPrayerStatusSheet(BuildContext context, AppState state, DateTime date, String key) {
  final s = state.s;
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (c) {
      final current = state.day(date).prayer(key);
      final canRecord = state.canRecordPrayer(date, key);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.t(key), style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            if (date.isBefore(state.today))
              Text(s.t('editing_past_day'), style: Theme.of(c).textTheme.bodySmall?.copyWith(color: AppColors.delayed)),
            if (!canRecord) Text(s.t('not_started_yet'), style: Theme.of(c).textTheme.bodySmall),
            const SizedBox(height: 8),
            for (final st in [PrayerStatus.jamaat, PrayerStatus.alone, PrayerStatus.qaza, PrayerStatus.missed, PrayerStatus.none])
              ListTile(
                key: Key('sheet_status_${st.name}'),
                enabled: canRecord || st == PrayerStatus.none,
                leading: Icon(st == current ? Icons.radio_button_checked : Icons.radio_button_off, color: statusColor(st)),
                title: Text(st == PrayerStatus.none ? s.t('not_recorded') : statusLabel(s, st)),
                onTap: () {
                  Navigator.pop(c);
                  trySetPrayer(context, state, date, key, st);
                },
              ),
          ],
        ),
      );
    },
  );
}

class _QuickGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final today = state.today;
    final rec = state.day(today);
    final target = state.settings.quranTarget;

    int azkarDone(AzkarType t) {
      final list = azkar[t]!;
      var n = 0;
      for (var i = 0; i < list.length; i++) {
        if (state.azkarCount(today, '${t.name}_$i') >= list[i].count) n++;
      }
      return n;
    }

    final mDone = rec.done.contains('morning_azkar');
    final eDone = rec.done.contains('evening_azkar');
    final tahajjud = state.itemById('tahajjud');
    final tDone = rec.done.contains('tahajjud');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      padding: EdgeInsets.zero,
      children: [
        _QuickCard(
          key: const Key('quick_quran'),
          icon: Icons.menu_book,
          color: AppColors.emeraldMid,
          title: s.t('quran'),
          value: '${rec.quranPages}/$target ${s.t('pages')}',
          progress: target == 0 ? 0 : rec.quranPages / target,
          onTap: () => ShellScope.go(context, Tabs.quran),
        ),
        _QuickCard(
          key: const Key('quick_morning'),
          icon: Icons.wb_sunny,
          color: const Color(0xFFE09A2D),
          title: s.t('morning_azkar'),
          value: mDone ? s.t('completed') : '${azkarDone(AzkarType.morning)}/${azkar[AzkarType.morning]!.length}',
          progress: mDone ? 1 : azkarDone(AzkarType.morning) / azkar[AzkarType.morning]!.length,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AzkarDetailScreen(type: AzkarType.morning))),
        ),
        _QuickCard(
          key: const Key('quick_evening'),
          icon: Icons.nights_stay,
          color: const Color(0xFF5B4BB7),
          title: s.t('evening_azkar'),
          value: eDone ? s.t('completed') : '${azkarDone(AzkarType.evening)}/${azkar[AzkarType.evening]!.length}',
          progress: eDone ? 1 : azkarDone(AzkarType.evening) / azkar[AzkarType.evening]!.length,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AzkarDetailScreen(type: AzkarType.evening))),
        ),
        _QuickCard(
          key: const Key('quick_tahajjud'),
          icon: Icons.bedtime,
          color: const Color(0xFF2E5E8C),
          title: s.t('tahajjud'),
          value: tDone ? s.t('completed') : s.t('tap_to_mark'),
          progress: tDone ? 1 : 0,
          onTap: () {
            if (tahajjud != null) {
              state.toggleItem(today, tahajjud);
            } else {
              state.setDone(today, 'tahajjud', !tDone);
            }
          },
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final double progress;
  final VoidCallback onTap;
  const _QuickCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                IconBadge(icon, color: color, size: 30),
                const Spacer(),
                if (progress >= 1) const Icon(Icons.check_circle, color: AppColors.onTime, size: 20),
              ]),
              const Spacer(),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0).toDouble(),
                  minHeight: 5,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuaOfDayCard extends StatelessWidget {
  const _DuaOfDayCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final urdu = state.settings.urdu;
    final pool = dailyDuaPool;
    final today = state.today;
    final dayOfYear = today.difference(DateTime(today.year)).inDays;
    final dua = pool[dayOfYear % pool.length];
    final title = urdu ? dua.titleUr : dua.titleEn;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ZikrDetailScreen(zikr: dua))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title.isNotEmpty) Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(dua.arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: arabicStyle(context, size: 22)),
              const SizedBox(height: 6),
              Text(urdu ? dua.ur : dua.en, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(dua.reference,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppColors.gold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconBadge(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// One routine checklist row, aware of the schedule state: upcoming items
/// are locked, missed ones are flagged, completed ones show their time. The
/// check button toggles completion, the row opens the related screen and a
/// long-press offers skip / edit.
class RoutineTile extends StatelessWidget {
  final RoutineItem item;
  final DateTime date;
  final DateTime? now;
  const RoutineTile({super.key, required this.item, required this.date, this.now});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final urdu = state.settings.urdu;
    final s = state.s;
    final t = now ?? clock();
    final st = state.activityState(item, date, now: t);
    final done = st == ActivityState.completed;
    final skipped = st == ActivityState.skipped;
    final missed = st == ActivityState.missed;
    final locked = st == ActivityState.upcoming;
    final theme = Theme.of(context);
    final w = state.windowOf(item, date);

    String timing;
    if (done) {
      final at = state.completedTime(date, item.id);
      timing = at == null ? s.t('completed') : '${s.t('completed_at')} ${formatTime(at, urdu: urdu)}';
    } else if (locked) {
      final d = w.start.difference(t);
      timing = '${formatTime(w.start, urdu: urdu)} • ${s.t('starts_in')} ${formatDuration(d.isNegative ? Duration.zero : d)}';
    } else if (missed) {
      timing = '${s.t('missed')} • ${formatTime(w.start, urdu: urdu)} – ${formatTime(w.end, urdu: urdu)}';
    } else if (skipped) {
      timing = s.t('skipped');
    } else {
      timing = '${s.t('until')} ${formatTime(w.end, urdu: urdu)}';
    }
    final subtitle = [timing, item.target(urdu), if (item.optional) s.t('optional')]
        .where((e) => e.isNotEmpty)
        .join(' • ');
    final progress = state.countedProgress(item, date);
    final (icon, color) = categoryVisual(item.category);
    final faded = done || skipped || locked;

    return ListTile(
      key: Key('routine_${item.id}'),
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 4),
      onTap: () => openActivity(context, item, date),
      onLongPress: () => showActivitySheet(context, item, date),
      leading: IconBadge(locked ? Icons.lock_clock : icon, color: missed ? AppColors.missed : color, size: 38),
      title: Text(
        item.name(urdu),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: done || skipped ? TextDecoration.lineThrough : null,
          color: faded ? theme.colorScheme.onSurface.withValues(alpha: 0.55) : (missed ? AppColors.missed : null),
        ),
      ),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: missed ? AppColors.missed : null)),
        if (progress != null && !done && !locked) ...[
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.$2 == 0 ? 0 : (progress.$1 / progress.$2).clamp(0.0, 1.0).toDouble(),
                  minHeight: 5,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${progress.$1}/${progress.$2}',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ],
      ]),
      trailing: IconButton(
        key: Key('routine_check_${item.id}'),
        tooltip: locked ? s.t('locked') : (done ? s.t('mark_not_done') : s.t('mark_done')),
        iconSize: 32,
        onPressed: () => tryToggle(context, state, date, item),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: done
              ? const Icon(Icons.check_circle, key: ValueKey('done'), color: AppColors.onTime)
              : locked
                  ? Icon(Icons.lock_outline, key: const ValueKey('locked'), color: theme.colorScheme.outline)
                  : Icon(Icons.radio_button_unchecked,
                      key: const ValueKey('todo'), color: missed ? AppColors.missed : theme.colorScheme.outline),
        ),
      ),
    );
  }
}

/// "My Chilla" card: day x/40 and today's chilla tasks.
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final chilla = state.chillaOn(state.today);
    final (done, total) = chillaProgress(state, state.today);
    void open() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportScreen()));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('open_daily_plan'),
        onTap: open,
        child: Ink(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: Stack(children: [
            const Positioned(
              right: 0,
              bottom: 0,
              width: 150,
              height: 70,
              child: CustomPaint(painter: MosqueSkylinePainter(color: Color(0x33000000))),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                ProgressRing(
                  value: chilla == null ? 0 : chilla.$2 / 40,
                  size: 70,
                  stroke: 7,
                  color: AppColors.gold,
                  trackColor: Colors.white24,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(chilla == null ? '—' : '${chilla.$2}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const Text('/ 40', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.t('my_daily_plan'),
                        style: const TextStyle(color: AppColors.goldLight, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      chilla == null
                          ? s.t('daily_plan_sub')
                          : '${s.t('chilla')} ${chilla.$1.toString().padLeft(2, '0')} • ${s.t('day')} ${chilla.$2.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    if (chilla != null) ...[
                      Text('${s.t('chilla_today')}: $done/$total', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 6,
                          color: AppColors.gold,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          key: const Key('open_chilla'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.goldLight, padding: EdgeInsets.zero),
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChillaScreen())),
                          icon: const Icon(Icons.grid_view, size: 16),
                          label: Text(s.t('chilla_40_view')),
                        ),
                      ),
                    ] else
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.emerald,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        ),
                        onPressed: () => state.startChilla(state.today),
                        child: Text(s.t('start_chilla')),
                      ),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: AppColors.goldLight),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
