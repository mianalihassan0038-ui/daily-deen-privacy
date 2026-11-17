import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/routine.dart';
import '../services/schedule.dart';
import '../strings.dart';

/// Easy scheduler for Azkar activities with three modes:
///  * After prayer (+ optional reminder offset) – never marked missed,
///  * Fixed time – never marked missed,
///  * Time window – marked missed only after the window ends.
/// `null` means "use the default schedule".
class AzkarScheduleEditor extends StatelessWidget {
  final AzkarSchedule? value;
  final ValueChanged<AzkarSchedule?> onChanged;
  const AzkarScheduleEditor({super.key, required this.value, required this.onChanged});

  static const offsets = [0, 5, 10, 15, 20, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final v = value;

    Future<int?> pickTime(int initial) async {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: initial ~/ 60 % 24, minute: initial % 60),
      );
      return t == null ? null : t.hour * 60 + t.minute;
    }

    Widget timeBox(String key, int minutes, ValueChanged<int> set) => OutlinedButton.icon(
          key: Key(key),
          onPressed: () async {
            final m = await pickTime(minutes);
            if (m != null) set(m);
          },
          icon: const Icon(Icons.access_time, size: 18),
          label: Text(formatMinutes(minutes, urdu: urdu)),
        );

    Widget option({
      required String key,
      required bool selected,
      required String title,
      required String subtitle,
      required VoidCallback onSelect,
      List<Widget> body = const [],
    }) {
      final c = theme.colorScheme.primary;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: selected ? c.withValues(alpha: 0.07) : theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: selected ? c : theme.dividerColor, width: selected ? 2 : 1),
          ),
          child: InkWell(
            key: Key('azkar_mode_$key'),
            borderRadius: BorderRadius.circular(16),
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: selected ? c : theme.colorScheme.outline),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ]),
                  ),
                  if (selected) const Icon(Icons.check_circle, color: AppColors.onTime),
                ]),
                if (selected && body.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 34, top: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: body),
                  ),
              ]),
            ),
          ),
        ),
      );
    }

    final after = v?.mode == AzkarMode.afterPrayer ? v! : const AzkarSchedule.afterPrayer('fajr', offset: 15);
    final fixed = v?.mode == AzkarMode.fixed ? v! : const AzkarSchedule.fixed(7 * 60);
    final window = v?.mode == AzkarMode.window ? v! : const AzkarSchedule.window(7 * 60, 10 * 60);

    return Column(
      key: const Key('azkar_schedule_editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(s.t('azkar_when'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
        option(
          key: 'default',
          selected: v == null,
          title: s.t('use_default_schedule'),
          subtitle: s.t('default_schedule_hint'),
          onSelect: () => onChanged(null),
        ),
        option(
          key: 'after',
          selected: v?.mode == AzkarMode.afterPrayer,
          title: s.t('mode_after_prayer'),
          subtitle: s.t('mode_after_prayer_sub'),
          onSelect: () => onChanged(after),
          body: [
            DropdownButtonFormField<String>(
              key: const Key('azkar_prayer'),
              initialValue: after.prayer,
              isExpanded: true,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.mosque), labelText: s.t('after_prayer')),
              items: [for (final p in azkarPrayers) DropdownMenuItem(value: p, child: Text(s.t(p)))],
              onChanged: (p) => onChanged(AzkarSchedule.afterPrayer(p ?? after.prayer, offset: after.offset)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: const Key('azkar_offset'),
              initialValue: offsets.contains(after.offset) ? after.offset : 0,
              isExpanded: true,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.timer_outlined), labelText: s.t('reminder_offset')),
              items: [
                for (final o in offsets)
                  DropdownMenuItem(value: o, child: Text(o == 0 ? s.t('right_after') : '$o ${s.t('min_after')}')),
              ],
              onChanged: (o) => onChanged(AzkarSchedule.afterPrayer(after.prayer, offset: o ?? 0)),
            ),
          ],
        ),
        option(
          key: 'fixed',
          selected: v?.mode == AzkarMode.fixed,
          title: s.t('mode_fixed'),
          subtitle: s.t('mode_fixed_sub'),
          onSelect: () => onChanged(fixed),
          body: [timeBox('azkar_fixed_time', fixed.start, (m) => onChanged(AzkarSchedule.fixed(m)))],
        ),
        option(
          key: 'window',
          selected: v?.mode == AzkarMode.window,
          title: s.t('mode_window'),
          subtitle: s.t('mode_window_sub'),
          onSelect: () => onChanged(window),
          body: [
            Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              timeBox('azkar_window_start', window.start, (m) => onChanged(AzkarSchedule.window(m, window.end))),
              const Text('—'),
              timeBox('azkar_window_end', window.end, (m) => onChanged(AzkarSchedule.window(window.start, m))),
            ]),
          ],
        ),
        Container(
          key: const Key('azkar_schedule_info'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3E7BC4).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info, color: Color(0xFF3E7BC4)),
            const SizedBox(width: 10),
            Expanded(child: Text(azkarScheduleExplanation(s, v, urdu: urdu))),
          ]),
        ),
      ],
    );
  }
}

/// Plain-language rule: when the Azkar appears and when it becomes missed.
String azkarScheduleExplanation(S s, AzkarSchedule? v, {required bool urdu}) {
  if (v == null) return s.t('default_schedule_hint');
  return switch (v.mode) {
    AzkarMode.afterPrayer => s
        .t('explain_after')
        .replaceAll('{p}', s.t(v.prayer))
        .replaceAll('{o}', v.offset == 0 ? '' : ' + ${v.offset} ${s.t('min_short')}'),
    AzkarMode.fixed => s.t('explain_fixed').replaceAll('{t}', formatMinutes(v.start, urdu: urdu)),
    AzkarMode.window => s
        .t('explain_window')
        .replaceAll('{a}', formatMinutes(v.start, urdu: urdu))
        .replaceAll('{b}', formatMinutes(v.end, urdu: urdu)),
  };
}

/// One-line description of an Azkar activity's current schedule.
String azkarScheduleSummary(S s, AzkarSchedule? v, {required bool urdu}) {
  if (v == null) return s.t('use_default_schedule');
  return switch (v.mode) {
    AzkarMode.afterPrayer =>
      '${s.t('mode_after_prayer')}: ${s.t(v.prayer)}${v.offset > 0 ? ' +${v.offset} ${s.t('min_short')}' : ''}',
    AzkarMode.fixed => '${s.t('mode_fixed')}: ${formatMinutes(v.start, urdu: urdu)}',
    AzkarMode.window =>
      '${s.t('mode_window')}: ${formatMinutes(v.start, urdu: urdu)} – ${formatMinutes(v.end, urdu: urdu)}',
  };
}
