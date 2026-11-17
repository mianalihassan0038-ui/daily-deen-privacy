import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../services/hijri.dart';
import '../services/prayer_times.dart';
import '../strings.dart';
import '../widgets/common.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  HijriDate? _month; // day = 1

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final adj = state.settings.hijriAdjust;
    final theme = Theme.of(context);
    final today = state.today;
    final todayH = HijriDate.fromGregorian(today, adjustDays: adj);
    final month = _month ?? HijriDate(todayH.year, todayH.month, 1);
    final first = month.toGregorian(adjustDays: adj);
    final length = month.monthLength;
    final lead = first.weekday % 7; // Sunday first
    final names = urdu ? weekdaysUr : weekdaysEn;
    final header = [names[6], ...names.sublist(0, 6)];

    final events = [
      for (final e in islamicEvents)
        (HijriDate(todayH.year, e.$1, e.$2), e.$3, e.$4),
      for (final e in islamicEvents)
        (HijriDate(todayH.year + 1, e.$1, e.$2), e.$3, e.$4),
    ]
        .map((e) => (e.$1, e.$1.toGregorian(adjustDays: adj), urdu ? e.$3 : e.$2))
        .where((e) => !e.$2.isBefore(today))
        .take(10)
        .toList();

    void go(int delta) {
      var y = month.year, m = month.month + delta;
      if (m < 1) {
        m = 12;
        y--;
      } else if (m > 12) {
        m = 1;
        y++;
      }
      setState(() => _month = HijriDate(y, m, 1));
    }

    return HeaderScaffold(
      title: s.t('islamic_calendar'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => go(-1)),
                  Expanded(
                    child: Column(children: [
                      Text('${month.monthName(urdu)} ${month.year}${urdu ? ' ھ' : ' AH'}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        '${(urdu ? monthsUr : monthsEn)[first.month - 1]} ${first.year}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ]),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => go(1)),
                ]),
                Row(children: [
                  for (final h in header)
                    Expanded(child: Text(h.substring(0, urdu ? 1 : 3), textAlign: TextAlign.center, style: theme.textTheme.labelSmall)),
                ]),
                const SizedBox(height: 6),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.85,
                  children: [
                    for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                    for (var d = 1; d <= length; d++)
                      Builder(builder: (context) {
                        final g = DateTime(first.year, first.month, first.day + d - 1);
                        final isToday = g == today;
                        final event = islamicEvents.any((e) => e.$1 == month.month && e.$2 == d);
                        final white = d >= 13 && d <= 15;
                        return Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.emeraldMid
                                : event
                                    ? AppColors.gold.withValues(alpha: 0.25)
                                    : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('$d',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: isToday ? Colors.white : null,
                                )),
                            Text('${g.day}', style: TextStyle(fontSize: 10, color: isToday ? Colors.white70 : theme.colorScheme.outline)),
                            if (white)
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(color: isToday ? Colors.white : AppColors.gold, shape: BoxShape.circle),
                              ),
                          ]),
                        );
                      }),
                  ],
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(s.t('white_days_hint'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          SectionTitle('${s.t('sehri')} / ${s.t('iftar')}'),
          Card(
            key: const Key('sehri_iftar'),
            child: Column(children: [
              for (final d in month.month == 9
                  ? [for (var i = 0; i < length; i++) DateTime(first.year, first.month, first.day + i)]
                  : [today])
                Builder(builder: (c) {
                  final t = state.prayerTimes(d);
                  final isToday = d == today;
                  return ListTile(
                    dense: month.month == 9,
                    selected: isToday,
                    leading: month.month == 9
                        ? CircleAvatar(radius: 14, child: Text('${HijriDate.fromGregorian(d, adjustDays: adj).day}', style: const TextStyle(fontSize: 11)))
                        : const Icon(Icons.wb_twilight, color: AppColors.gold),
                    title: Text(isToday ? s.t('today') : '${d.day} ${(urdu ? monthsUr : monthsEn)[d.month - 1]}'),
                    trailing: Text(
                      '${s.t('sehri')} ${formatTime(t[PrayerName.fajr], urdu: urdu)}   ${s.t('iftar')} ${formatTime(t[PrayerName.maghrib], urdu: urdu)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }),
            ]),
          ),
          SectionTitle(s.t('upcoming_dates')),
          Card(
            child: Column(children: [
              for (final e in events)
                ListTile(
                  leading: const Icon(Icons.star, color: AppColors.gold),
                  title: Text(e.$3, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${e.$1.format(urdu)} • ${e.$2.day} ${(urdu ? monthsUr : monthsEn)[e.$2.month - 1]} ${e.$2.year}'),
                  trailing: Text(
                    e.$2 == today ? s.t('today_total') : '${e.$2.difference(today).inDays} ${s.t('days')}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          Text(s.t('moon_sighting_note'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
