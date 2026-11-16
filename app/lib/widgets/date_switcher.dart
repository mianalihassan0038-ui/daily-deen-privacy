import 'package:flutter/material.dart';

import '../app_state.dart';
import '../strings.dart';

/// "< Monday 16 November >" selector. Future dates are not allowed.
class DateSwitcher extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const DateSwitcher({super.key, required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final urdu = state.settings.urdu;
    final today = state.today;
    final isToday = date == today;
    final label = urdu
        ? '${weekdaysUr[date.weekday - 1]}، ${date.day} ${monthsUr[date.month - 1]}'
        : '${weekdaysEn[date.weekday - 1]}, ${date.day} ${monthsEn[date.month - 1]}';
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(date.subtract(const Duration(days: 1))),
        ),
        Expanded(
          child: Text(
            isToday ? '${state.s.t('today_total')} • $label' : label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isToday ? null : () => onChanged(_next(date, today)),
        ),
      ],
    );
  }

  DateTime _next(DateTime d, DateTime today) {
    final n = DateTime(d.year, d.month, d.day + 1);
    return n.isAfter(today) ? today : n;
  }
}
