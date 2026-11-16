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
import 'more_screen.dart';
import 'navigation.dart';
import 'report_screen.dart';
import 'routine_screen.dart';
import 'settings_screen.dart';
import 'shell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _showCompleted = false;

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
    final today = state.today;
    final theme = Theme.of(context);
    final (done, total) = state.completion(today);
    final ratio = total == 0 ? 0.0 : done / total;
    final items = state.routineFor(today);
    final pending = items.where((i) => !state.isDone(today, i) && !state.isSkipped(today, i)).toList();
    final completed = items.where((i) => state.isDone(today, i)).toList();
    final skipped = items.where((i) => state.isSkipped(today, i)).toList();

    return ListView(
      key: const Key('home_list'),
      padding: EdgeInsets.zero,
      children: [
        _Header(now: _now),
        Transform.translate(
          offset: const Offset(0, -26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProgressCard(ratio: ratio, done: done, total: total),
                const SizedBox(height: 12),
                const _PlanCard(),
                const SizedBox(height: 12),
                _NextPrayerCard(now: _now),
                const SizedBox(height: 4),
                SectionTitle(s.t('todays_prayers'),
                    actionLabel: s.t('view_all'), onAction: () => ShellScope.go(context, Tabs.namaz)),
                _TodayPrayers(now: _now),
                SectionTitle(s.t('quick_track')),
                _QuickGrid(),
                SectionTitle(s.t('dua_of_day')),
                const _DuaOfDayCard(),
                SectionTitle(
                  '${s.t('daily_routine')}  ($done/$total)',
                  actionLabel: s.t('plan'),
                  onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoutineScreen())),
                ),
                if (pending.isEmpty && total > 0)
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
                if (pending.isNotEmpty) ...[
                  _ListLabel('${s.t('pending')} (${pending.length})', AppColors.pending),
                  Card(
                    child: Column(children: [
                      for (var i = 0; i < pending.length; i++) ...[
                        RoutineTile(item: pending[i], date: today),
                        if (i < pending.length - 1) const Divider(indent: 60),
                      ],
                    ]),
                  ),
                ],
                if (completed.isNotEmpty || skipped.isNotEmpty) ...[
                  InkWell(
                    onTap: () => setState(() => _showCompleted = !_showCompleted),
                    child: Row(children: [
                      Expanded(child: _ListLabel('${s.t('completed')} (${completed.length})', AppColors.onTime)),
                      Icon(_showCompleted ? Icons.expand_less : Icons.expand_more),
                    ]),
                  ),
                  if (_showCompleted)
                    Card(
                      child: Column(children: [
                        for (final it in [...completed, ...skipped]) RoutineTile(item: it, date: today),
                      ]),
                    ),
                ],
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
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MoreFeaturesScreen())),
                  icon: const Icon(Icons.apps),
                  label: Text(s.t('more_features')),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                ),
                const SizedBox(height: 8),
                Text(
                  s.t('streak_hint'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
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
        Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _ProgressCard extends StatelessWidget {
  final double ratio;
  final int done;
  final int total;
  const _ProgressCard({required this.ratio, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ShellScope.go(context, Tabs.progress),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.t('your_daily_progress'), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('${(ratio * 100).round()}%',
                        key: const Key('home_percent'),
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                    Text('$done ${s.t('of')} $total ${s.t('tasks')}', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: ratio, minHeight: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              ProgressRing(
                value: ratio,
                size: 84,
                stroke: 9,
                child: Icon(Icons.mosque, color: theme.colorScheme.primary, size: 34),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  final DateTime now;
  const _NextPrayerCard({required this.now});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final next = state.nextPrayer(now);
    final remaining = next.value.difference(now.toUtc());
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            bottom: 0,
            width: 170,
            height: 90,
            child: CustomPaint(painter: MosqueSkylinePainter(color: Color(0x33C9A44C))),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('next_prayer_title'), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(s.t(next.key.name), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Text(formatTime(next.value, urdu: urdu), style: Theme.of(context).textTheme.bodyMedium),
                ]),
                const SizedBox(height: 4),
                Text(
                  formatDuration(remaining.isNegative ? Duration.zero : remaining),
                  key: const Key('countdown'),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8)),
                  onPressed: () => ShellScope.go(context, Tabs.namaz),
                  child: Text(s.t('view_details')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    final rec = state.day(today);
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: [
          for (final key in prayerKeys)
            Builder(builder: (context) {
              final p = PrayerName.values.firstWhere((e) => e.name == key);
              final status = rec.prayer(key);
              final started = !times[p].isAfter(now.toUtc());
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
                    Text(started ? s.t('pending') : s.t('upcoming'),
                        style: TextStyle(fontSize: 11, color: started ? AppColors.pending : theme.colorScheme.outline)),
                  const SizedBox(width: 6),
                  Icon(
                    isPrayed(status)
                        ? Icons.check_circle
                        : status == PrayerStatus.missed
                            ? Icons.cancel
                            : Icons.radio_button_unchecked,
                    color: isPrayed(status) || status == PrayerStatus.missed ? statusColor(status) : theme.colorScheme.outline,
                  ),
                ]),
                onTap: () {
                  if (status == PrayerStatus.none && !started) {
                    toast(context, s.t('not_started_yet'));
                    return;
                  }
                  state.setPrayer(today, key, isPrayed(status) ? PrayerStatus.none : PrayerStatus.alone);
                },
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
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.t(key), style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final st in [PrayerStatus.jamaat, PrayerStatus.alone, PrayerStatus.qaza, PrayerStatus.missed, PrayerStatus.none])
              ListTile(
                leading: Icon(st == current ? Icons.radio_button_checked : Icons.radio_button_off, color: statusColor(st)),
                title: Text(statusLabel(s, st)),
                onTap: () {
                  state.setPrayer(date, key, st);
                  Navigator.pop(c);
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

/// One routine checklist row: the circle toggles completion, the row opens
/// the related screen, long-press offers skip.
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
    final skipped = state.isSkipped(date, item);
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
    final (icon, color) = categoryVisual(item.category);

    return ListTile(
      key: Key('routine_${item.id}'),
      onTap: () => openActivity(context, item, date),
      onLongPress: () => state.toggleSkip(date, item),
      leading: InkWell(
        key: Key('routine_check_${item.id}'),
        customBorder: const CircleBorder(),
        onTap: () => state.toggleItem(date, item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? theme.colorScheme.primary : color.withValues(alpha: 0.12),
            border: Border.all(color: done ? theme.colorScheme.primary : color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Icon(done ? Icons.check : icon, size: 17, color: done ? Colors.white : color),
        ),
      ),
      title: Text(
        item.name(urdu),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          decoration: done || skipped ? TextDecoration.lineThrough : null,
          color: done || skipped ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : null,
        ),
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: skipped
          ? Text(s.t('skipped'), style: TextStyle(color: theme.colorScheme.outline, fontSize: 12))
          : item.optional
              ? Text(s.t('optional'), style: TextStyle(color: AppColors.gold, fontSize: 11))
              : const Icon(Icons.chevron_right, size: 18),
    );
  }
}


/// Shortcut to "My Daily Plan" (chilla report).
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final chilla = state.chillaOn(state.today);
    return Card(
      color: AppColors.emerald,
      child: ListTile(
        key: const Key('open_daily_plan'),
        leading: const Icon(Icons.assignment_turned_in, color: AppColors.goldLight, size: 32),
        title: Text(s.t('my_daily_plan'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        subtitle: Text(
          chilla == null ? s.t('daily_plan_sub') : '${s.t('chilla')} ${chilla.$1.toString().padLeft(2, '0')} • ${s.t('day')} ${chilla.$2.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.goldLight),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportScreen())),
      ),
    );
  }
}
