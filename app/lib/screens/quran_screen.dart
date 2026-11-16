import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/routine.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  static const _surahItemIds = ['yaseen', 'kahf', 'mulk', 'baqarah_last2', 'kursi_morning', 'kursi_night'];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final today = state.today;
    final rec = state.day(today);
    final target = state.settings.quranTarget;
    final todayRatio = target == 0 ? 0.0 : (rec.quranPages / target).clamp(0.0, 1.0).toDouble();
    final khatamRatio = state.khatamPages / quranTotalPages;
    final byId = {for (final i in defaultRoutine) i.id: i};

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ---------- today ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('pages_today'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      key: const Key('quran_minus'),
                      onPressed: rec.quranPages > 0 ? () => state.addPages(today, -1) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('${rec.quranPages}',
                          key: const Key('quran_pages'),
                          style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                    ),
                    IconButton.filled(
                      key: const Key('quran_plus'),
                      onPressed: () => state.addPages(today, 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: todayRatio, minHeight: 8, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 6),
                Text('${s.t('daily_target')}: $target ${s.t('pages')}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ---------- khatam ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(s.t('khatam_progress'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                  Text('${(khatamRatio * 100).toStringAsFixed(1)}%', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: khatamRatio, minHeight: 10, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 6),
                Text('${state.khatamPages} / $quranTotalPages ${s.t('pages')}  •  ${s.t('khatams_done')}: ${state.khatamCount}',
                    style: theme.textTheme.bodySmall),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(onPressed: () => _confirmReset(context, state), child: Text(s.t('reset_khatam'))),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ---------- juz grid ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.t('para_progress')}  (${state.juzDone.length}/30)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var j = 1; j <= 30; j++)
                      InkWell(
                        key: Key('juz_$j'),
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => state.toggleJuz(j),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: state.juzDone.contains(j) ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.08),
                          ),
                          child: Text('$j',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: state.juzDone.contains(j) ? Colors.white : theme.colorScheme.primary,
                              )),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ---------- surah checklist ----------
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(s.t('surah_checklist'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              for (final id in _surahItemIds)
                if (byId[id] != null && (!byId[id]!.fridayOnly || today.weekday == DateTime.friday))
                  CheckboxListTile(
                    value: state.isDone(today, byId[id]!),
                    onChanged: (_) => state.toggleItem(today, byId[id]!),
                    title: Text(byId[id]!.name(urdu)),
                    subtitle: Text(byId[id]!.time(urdu)),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, AppState state) async {
    final s = state.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.t('reset_khatam')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('reset'))),
        ],
      ),
    );
    if (ok == true) state.resetKhatam();
  }
}
