import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/azkar.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(tabs: [Tab(text: s.t('tasbeeh')), Tab(text: s.t('azkar'))]),
          const Expanded(child: TabBarView(children: [_CounterTab(), _AzkarTab()])),
        ],
      ),
    );
  }
}

class _CounterTab extends StatefulWidget {
  const _CounterTab();

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final today = state.today;
    final dhikr = tasbeehList[_selected];
    final count = state.day(today).dhikr[dhikr.key] ?? 0;
    final progress = (count % dhikr.target) / dhikr.target;
    final rounds = count ~/ dhikr.target;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < tasbeehList.length; i++)
              ChoiceChip(
                label: Text(urdu ? tasbeehList[i].ur : tasbeehList[i].en),
                selected: _selected == i,
                onSelected: (_) => setState(() => _selected = i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(dhikr.arabic, textAlign: TextAlign.center, textDirection: TextDirection.rtl,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.8)),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            key: const Key('tasbeeh_tap'),
            onTap: () {
              HapticFeedback.lightImpact();
              state.incrementDhikr(today, dhikr.key);
              if ((count + 1) % dhikr.target == 0) HapticFeedback.heavyImpact();
            },
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  Container(
                    margin: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [Color(0xFF16A061), Color(0xFF0A5C37)]),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${count % dhikr.target}',
                            key: const Key('tasbeeh_count'),
                            style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800)),
                        Text(s.t('tap_to_count'), style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _info(context, s.t('target'), '${dhikr.target}'),
            _info(context, '×${dhikr.target}', '$rounds'),
            _info(context, s.t('today_total'), '$count'),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: () => state.resetDhikr(today, dhikr.key),
            icon: const Icon(Icons.refresh),
            label: Text(s.t('reset')),
          ),
        ),
      ],
    );
  }

  Widget _info(BuildContext context, String label, String value) => Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _AzkarTab extends StatefulWidget {
  const _AzkarTab();

  @override
  State<_AzkarTab> createState() => _AzkarTabState();
}

class _AzkarTabState extends State<_AzkarTab> {
  AzkarType _type = AzkarType.morning;

  @override
  void initState() {
    super.initState();
    final h = DateTime.now().hour;
    _type = h >= 21 || h < 3 ? AzkarType.sleep : (h >= 15 ? AzkarType.evening : AzkarType.morning);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final today = state.today;
    final list = azkar[_type]!;
    final routineId = azkarRoutineId[_type]!;
    final setDone = state.day(today).done.contains(routineId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<AzkarType>(
          segments: [
            ButtonSegment(value: AzkarType.morning, label: Text(s.t('az_m'))),
            ButtonSegment(value: AzkarType.evening, label: Text(s.t('az_e'))),
            ButtonSegment(value: AzkarType.sleep, label: Text(s.t('az_s'))),
          ],
          selected: {_type},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _type = v.first),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < list.length; i++) ...[
          _ZikrCard(zikr: list[i], countKey: '${_type.name}_$i', urdu: urdu, onAllDone: () => _checkAll(state)),
          const SizedBox(height: 10),
        ],
        FilledButton.icon(
          onPressed: () => state.setDone(today, routineId, !setDone),
          icon: Icon(setDone ? Icons.check_circle : Icons.check),
          label: Text(setDone ? s.t('completed') : s.t('mark_complete')),
          style: FilledButton.styleFrom(
            backgroundColor: setDone ? theme.colorScheme.primary : null,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  void _checkAll(AppState state) {
    final list = azkar[_type]!;
    final today = state.today;
    var all = true;
    for (var i = 0; i < list.length; i++) {
      if (state.azkarCount(today, '${_type.name}_$i') < list[i].count) all = false;
    }
    if (all) state.setDone(today, azkarRoutineId[_type]!, true);
  }
}

class _ZikrCard extends StatelessWidget {
  final Zikr zikr;
  final String countKey;
  final bool urdu;
  final VoidCallback onAllDone;
  const _ZikrCard({required this.zikr, required this.countKey, required this.urdu, required this.onAllDone});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final today = state.today;
    final count = state.azkarCount(today, countKey);
    final done = count >= zikr.count;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: done
            ? null
            : () {
                HapticFeedback.selectionClick();
                state.setAzkarCount(today, countKey, count + 1);
                if (count + 1 >= zikr.count) onAllDone();
              },
        onLongPress: () => state.setAzkarCount(today, countKey, 0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(zikr.arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleLarge?.copyWith(height: 1.9)),
              const SizedBox(height: 8),
              Text(urdu ? zikr.ur : zikr.en, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(zikr.reference, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: done ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      done ? '✓ ${zikr.count}' : '$count / ${zikr.count}',
                      style: TextStyle(color: done ? Colors.white : theme.colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
