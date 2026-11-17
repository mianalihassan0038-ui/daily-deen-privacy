import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/date_switcher.dart';

/// Daily self-review (Muhasaba). Stored only on this device.
class MuhasabaScreen extends StatefulWidget {
  final DateTime date;
  const MuhasabaScreen({super.key, required this.date});

  @override
  State<MuhasabaScreen> createState() => _MuhasabaScreenState();
}

class _MuhasabaScreenState extends State<MuhasabaScreen> {
  static const fields = ['good_deeds', 'achievements', 'improve', 'goals'];
  late DateTime _date = widget.date;
  final Map<String, TextEditingController> _ctrls = {for (final f in [...fields, 'note']) f: TextEditingController()};
  bool _loaded = false;

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(AppState state) {
    final rec = state.day(_date);
    for (final f in fields) {
      _ctrls[f]!.text = rec.muhasaba[f] ?? '';
    }
    _ctrls['note']!.text = rec.note;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    if (!_loaded) _load(state);
    final rec = state.day(_date);
    final rating = int.tryParse(rec.muhasaba['rating'] ?? '') ?? 0;
    final azkarDone = ['morning_azkar', 'evening_azkar', 'sleep_azkar'].where(rec.done.contains).length;
    final (done, total) = state.completion(_date);

    return HeaderScaffold(
      title: s.t('daily_muhasaba'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          DateSwitcher(
            date: _date,
            onChanged: (d) => setState(() {
              _date = d;
              _load(state);
            }),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.t('auto_summary'), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _line(Icons.mosque, '${s.t('prayers')}: ${rec.farzPrayed}/5'),
                _line(Icons.menu_book, '${s.t('quran')}: ${rec.quranPages} ${s.t('pages')}'),
                _line(Icons.auto_awesome, '${s.t('azkar')}: $azkarDone/3'),
                _line(Icons.task_alt, '${s.t('daily_routine')}: $done/$total'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.t('m_rating'), style: const TextStyle(fontWeight: FontWeight.w700)),
                Row(children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      key: Key('rating_$i'),
                      icon: Icon(i <= rating ? Icons.star : Icons.star_border, color: AppColors.gold, size: 32),
                      onPressed: () => state.setMuhasaba(_date, 'rating', i == rating ? '' : '$i'),
                    ),
                ]),
              ]),
            ),
          ),
          for (final f in fields) ...[
            const SizedBox(height: 12),
            TextField(
              key: Key('muhasaba_$f'),
              controller: _ctrls[f],
              minLines: 2,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(labelText: s.t('m_$f'), alignLabelWithHint: true),
              onChanged: (v) => state.setMuhasaba(_date, f, v),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const Key('muhasaba_note'),
            controller: _ctrls['note'],
            minLines: 4,
            maxLines: 10,
            maxLength: 5000,
            decoration: InputDecoration(labelText: s.t('m_journal'), alignLabelWithHint: true),
            onChanged: (v) {
              state.setNote(_date, v);
              final item = state.itemById('muhasaba');
              if (item != null && v.trim().isNotEmpty && !state.isDone(_date, item)) state.setDone(_date, 'muhasaba', true);
            },
          ),
          const SizedBox(height: 12),
          _PeriodReview(date: _date),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 6),
            Expanded(child: Text(s.t('private_note'), style: theme.textTheme.bodySmall)),
          ]),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [Icon(icon, size: 18, color: AppColors.gold), const SizedBox(width: 8), Text(text)]),
      );
}


/// Weekly / monthly reflection: an automatic summary of the period plus a
/// free-text review stored on the period's first day.
class _PeriodReview extends StatefulWidget {
  final DateTime date;
  const _PeriodReview({required this.date});

  @override
  State<_PeriodReview> createState() => _PeriodReviewState();
}

class _PeriodReviewState extends State<_PeriodReview> {
  bool _monthly = false;
  final _ctrl = TextEditingController();
  String? _loadedKey;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final d = widget.date;
    final start = _monthly ? DateTime(d.year, d.month, 1) : DateTime(d.year, d.month, d.day - (d.weekday - 1));
    final end = _monthly ? DateTime(d.year, d.month + 1, 1) : DateTime(start.year, start.month, start.day + 7);
    final field = _monthly ? 'month_review' : 'week_review';
    final key = '${start.toIso8601String()}|$field';
    if (_loadedKey != key) {
      _ctrl.text = state.day(start).muhasaba[field] ?? '';
      _loadedKey = key;
    }
    final today = state.today;
    var days = 0, prayers = 0, pages = 0, ratingSum = 0, rated = 0;
    var score = 0.0;
    for (var x = start; x.isBefore(end) && !x.isAfter(today); x = DateTime(x.year, x.month, x.day + 1)) {
      days++;
      final rec = state.day(x);
      prayers += rec.farzPrayed;
      pages += rec.quranPages;
      score += state.scoreFor(x).overall;
      final r = int.tryParse(rec.muhasaba['rating'] ?? '');
      if (r != null) {
        ratingSum += r;
        rated++;
      }
    }
    final avg = days == 0 ? 0 : (score / days * 100).round();
    return Card(
      key: const Key('period_review'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(s.t('weekly_review'))),
              ButtonSegment(value: true, label: Text(s.t('monthly_review'))),
            ],
            selected: {_monthly},
            onSelectionChanged: (v) => setState(() => _monthly = v.first),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 6, children: [
            Text('${s.t('score_history')}: $avg%'),
            Text('${s.t('prayers')}: $prayers/${days * 5}'),
            Text('${s.t('quran')}: $pages ${s.t('pages')}'),
            if (rated > 0) Text('★ ${(ratingSum / rated).toStringAsFixed(1)}'),
          ]),
          const SizedBox(height: 10),
          TextField(
            key: Key('review_$field'),
            controller: _ctrl,
            minLines: 2,
            maxLines: 6,
            maxLength: 3000,
            decoration: InputDecoration(
              labelText: _monthly ? s.t('monthly_review') : s.t('weekly_review'),
              alignLabelWithHint: true,
            ),
            onChanged: (v) => state.setMuhasaba(start, field, v),
          ),
        ]),
      ),
    );
  }
}
