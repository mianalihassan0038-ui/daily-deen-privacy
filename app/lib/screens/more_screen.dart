import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'azkar_screen.dart';
import 'calendar_screen.dart';
import 'extras_screens.dart';
import 'muhasaba_screen.dart';
import 'qibla_screen.dart';
import 'routine_screen.dart';
import 'settings_screen.dart';
import 'shell.dart';

class MoreFeaturesScreen extends StatelessWidget {
  const MoreFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    final items = <(String, String, IconData, Color, VoidCallback)>[
      (s.t('dua_library'), s.t('dua_library_sub'), Icons.volunteer_activism, AppColors.gold,
          () => push(HeaderScaffold(title: s.t('dua_library'), body: const AzkarCategoriesList()))),
      (s.t('surah_list'), s.t('surah_list_sub'), Icons.menu_book, AppColors.emeraldMid, () => ShellScope.go(context, Tabs.quran)),
      (s.t('routine_planner'), s.t('routine_planner_sub'), Icons.event_note, const Color(0xFF3E7BC4), () => push(const RoutineScreen())),
      (s.t('daily_muhasaba'), s.t('muhasaba_sub'), Icons.edit_note, const Color(0xFF7A5BC4), () => push(MuhasabaScreen(date: state.today))),
      (s.t('qibla'), s.t('qibla_sub'), Icons.explore, const Color(0xFF0B6E4F), () => push(const QiblaScreen())),
      (s.t('islamic_calendar'), s.t('calendar_sub'), Icons.calendar_month, const Color(0xFFD45A3A), () => push(const IslamicCalendarScreen())),
      (s.t('sadaqah'), s.t('sadaqah_sub'), Icons.savings, const Color(0xFFB0558A), () => push(const SadaqahScreen())),
      (s.t('habit_goals'), s.t('habit_goals_sub'), Icons.flag, const Color(0xFFE09A2D), () => push(const HabitsScreen())),
      (s.t('tasbeeh'), s.t('tasbeeh_sub'), Icons.touch_app, const Color(0xFF2E5E8C), () {
        azkarSubTab.value = 1;
        ShellScope.go(context, Tabs.azkar);
      }),
      (s.t('reminders'), s.t('reminders_sub'), Icons.notifications_active, const Color(0xFFC9A44C), () => push(const NotificationSettingsScreen())),
    ];

    return HeaderScaffold(
      title: s.t('more_features'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              for (final it in items)
                Card(
                  child: InkWell(
                    key: Key('feature_${it.$1}'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: it.$5,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(it.$3, color: it.$4, size: 36),
                          const SizedBox(height: 8),
                          Text(it.$1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(it.$2,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.goldLight, AppColors.gold]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Text('رَبَّنَا تَقَبَّلْ مِنَّا', style: arabicStyle(context, size: 24, color: AppColors.emerald)),
              Text(s.t('accept_deeds'),
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }
}
