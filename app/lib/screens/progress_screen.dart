import 'package:flutter/material.dart';

import '../app_state.dart';
import '../strings.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _noteCtrl = TextEditingController();
  bool _noteLoaded = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final today = state.today;
    if (!_noteLoaded) {
      _noteCtrl.text = state.day(today).note;
      _noteLoaded = true;
    }

    final week = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    var sum = 0.0;
    var counted = 0;
    var farz = 0;
    for (var i = 0; i < 30; i++) {
      final d = today.subtract(Duration(days: i));
      farz += state.day(d).farzPrayed;
      if (i == 0 || state.hasRecord(d)) {
        sum += state.completionRatio(d);
        counted++;
      }
    }
    final avg = counted == 0 ? 0.0 : sum / counted;
    final missed = state.mostMissed(30);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: _tile(context, Icons.local_fire_department, Colors.orange, s.t('current_streak'), '${state.currentStreak()} ${s.t('days')}')),
            const SizedBox(width: 10),
            Expanded(child: _tile(context, Icons.emoji_events, theme.colorScheme.tertiary, s.t('best_streak'), '${state.bestStreak()} ${s.t('days')}')),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Text(s.t('streak_hint'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ),
        // ---------- week chart ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('this_week'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final d in week)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${(state.completionRatio(d) * 100).round()}%', style: const TextStyle(fontSize: 10)),
                              const SizedBox(height: 4),
                              Container(
                                width: 22,
                                height: 4 + 100 * state.completionRatio(d),
                                decoration: BoxDecoration(
                                  color: d == today ? theme.colorScheme.tertiary : theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (urdu ? weekdaysUr : weekdaysEn)[d.weekday - 1].substring(0, urdu ? null : 3),
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ---------- month stats ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('this_month'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text(s.t('avg_completion'))),
                  Text('${(avg * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: avg, minHeight: 8, borderRadius: BorderRadius.circular(8)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Text(s.t('prayers_on_time'))),
                  Text('$farz / 150', style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: farz / 150, minHeight: 8, borderRadius: BorderRadius.circular(8)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (missed.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.t('most_missed'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  for (final e in missed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text(e.key.name(urdu))),
                        Text('${e.value}×', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                ],
              ),
            ),
          ),
        if (missed.isNotEmpty) const SizedBox(height: 12),
        // ---------- muhasaba ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📝  ${urdu ? 'روزانہ محاسبہ' : 'Daily Muhasaba'}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(s.t('muhasaba_hint'), style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(border: const OutlineInputBorder(), hintText: s.t('note')),
                  onChanged: (v) => state.setNote(today, v),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, Color color, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
