import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/routine.dart';
import '../services/prayer_times.dart';
import '../strings.dart';
import '../widgets/date_switcher.dart';

class NamazScreen extends StatefulWidget {
  const NamazScreen({super.key});

  @override
  State<NamazScreen> createState() => _NamazScreenState();
}

class _NamazScreenState extends State<NamazScreen> {
  DateTime? _date;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final date = _date ?? state.today;
    final times = state.calculator.forDate(date);
    final rec = state.day(date);
    final summary = state.prayerSummary(30);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        DateSwitcher(date: date, onChanged: (d) => setState(() => _date = d)),
        const SizedBox(height: 8),
        // ---------- prayer times ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.schedule, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(s.t('prayer_times'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(state.settings.city.name, style: theme.textTheme.bodySmall),
                ]),
                const SizedBox(height: 8),
                for (final p in PrayerName.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(child: Text(s.t(p.name))),
                      Text(formatTime(times[p], urdu: urdu), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ---------- per prayer status ----------
        for (final key in prayerKeys) ...[
          _PrayerCard(prayerKey: key, date: date, status: rec.prayer(key), sunnah: rec.sunnah.contains(key)),
          const SizedBox(height: 10),
        ],
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
        const SizedBox(height: 12),
        // ---------- monthly report ----------
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('monthly_report'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _stat(context, s.t('status_jamaat'), summary[PrayerStatus.jamaat]!, Colors.green),
                    _stat(context, s.t('status_alone'), summary[PrayerStatus.alone]!, Colors.teal),
                    _stat(context, s.t('status_qaza'), summary[PrayerStatus.qaza]!, Colors.orange),
                    _stat(context, s.t('status_missed'), summary[PrayerStatus.missed]!, Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(s.t('disclaimer'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, int value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final String prayerKey;
  final DateTime date;
  final PrayerStatus status;
  final bool sunnah;
  const _PrayerCard({required this.prayerKey, required this.date, required this.status, required this.sunnah});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    const options = [PrayerStatus.jamaat, PrayerStatus.alone, PrayerStatus.qaza, PrayerStatus.missed];
    final labels = {
      PrayerStatus.jamaat: s.t('status_jamaat'),
      PrayerStatus.alone: s.t('status_alone'),
      PrayerStatus.qaza: s.t('status_qaza'),
      PrayerStatus.missed: s.t('status_missed'),
    };

    return Card(
      key: Key('prayer_$prayerKey'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(isPrayed(status) ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isPrayed(status) ? theme.colorScheme.primary : theme.colorScheme.outline),
              const SizedBox(width: 8),
              Text(s.t(prayerKey), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(status == PrayerStatus.none ? s.t('status_none') : labels[status]!, style: theme.textTheme.bodySmall),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final o in options)
                  ChoiceChip(
                    label: Text(labels[o]!),
                    selected: status == o,
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
          ],
        ),
      ),
    );
  }
}
