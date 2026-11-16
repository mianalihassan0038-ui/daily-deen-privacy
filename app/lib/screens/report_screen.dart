import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/routine.dart';
import '../services/report.dart';
import '../widgets/common.dart';
import '../strings.dart';
import '../widgets/islamic_art.dart';
import '../widgets/pickers.dart';
import 'azkar_screen.dart';
import 'home_screen.dart' show showPrayerStatusSheet;
import 'quran_reader_screen.dart';

/// Daily report in the chilla format (prayers, tilawat, morning/evening tasbeehat),
/// fillable in place and shareable on WhatsApp.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime? _date;

  static const _surahs = {'yaseen': 36, 'waqiah': 56, 'mulk': 67};

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final date = _date ?? state.today;
    final rec = state.day(date);
    final chilla = state.chillaOn(date);
    final theme = Theme.of(context);
    final text = buildDailyReport(state, date, urdu: urdu);

    void openItem(String id) {
      final it = state.itemById(id);
      if (it == null) return;
      if (it.dhikrKey != null) {
        TasbeehLauncher.open(context, it.dhikrKey!);
      } else if (_surahs.containsKey(id)) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuranReaderScreen(surah: _surahs[id]!)));
      } else {
        state.toggleItem(date, it);
      }
    }

    final weekday = (urdu ? weekdaysUr : weekdaysEn)[date.weekday - 1];
    final dateText = urdu
        ? '${date.day} ${monthsUr[date.month - 1]} ${date.year}'
        : '${date.day} ${monthsEn[date.month - 1].substring(0, 3)} ${date.year}';

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _PlanHeader(title: s.t('my_daily_plan')),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // ---------- date | chilla | day ----------
                Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(children: [
                      Expanded(
                        child: InkWell(
                          key: const Key('report_date'),
                          onTap: () async {
                            final p = await showDatePicker(
                                context: context, initialDate: date, firstDate: DateTime(2020), lastDate: state.today);
                            if (p != null) setState(() => _date = DateTime(p.year, p.month, p.day));
                          },
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.calendar_month, color: AppColors.emerald, size: 22),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('${s.t('date')}: $dateText', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      Container(width: 1, height: 30, color: theme.dividerColor),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: InkWell(
                          key: const Key('chilla_start'),
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _chillaMenu(context, state, date),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(color: AppColors.emerald, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              chilla == null
                                  ? s.t('start_chilla')
                                  : '${s.t('chilla')}: ${chilla.$1.toString().padLeft(2, '0')}',
                              key: const Key('chilla_label'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 30, color: theme.dividerColor),
                      Expanded(
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                chilla == null ? '${s.t('day')}: $weekday' : '${s.t('day')}: ${chilla.$2.toString().padLeft(2, '0')} ($weekday)',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.event_note, color: AppColors.emerald, size: 22),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 18),
                // ---------- prayers ----------
                _RibbonCard(
                  title: s.t('prayers'),
                  icon: Icons.mosque,
                  child: Column(children: [
                    for (var i = 0; i < prayerKeys.length; i++) ...[
                      InkWell(
                        key: Key('report_prayer_${prayerKeys[i]}'),
                        onTap: () => showPrayerStatusSheet(context, state, date, prayerKeys[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.creamDark,
                              child: Icon(Icons.mosque, color: AppColors.emerald, size: 20),
                            ),
                            Expanded(
                              child: Text(s.t(prayerKeys[i]),
                                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            ),
                            Container(width: 1, height: 26, color: theme.dividerColor),
                            Expanded(
                              child: Center(child: _StatusPill(status: rec.prayer(prayerKeys[i]), urdu: urdu)),
                            ),
                            Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                                color: theme.colorScheme.outline),
                          ]),
                        ),
                      ),
                      if (i < prayerKeys.length - 1) const Divider(indent: 12, endIndent: 12),
                    ],
                  ]),
                ),
                const SizedBox(height: 18),
                // ---------- tilawat ----------
                _RibbonCard(
                  title: s.t('tilawat'),
                  icon: Icons.menu_book,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(children: [
                      for (final id in reportTilawat)
                        Expanded(
                          child: Builder(builder: (context) {
                            final it = state.itemById(id);
                            if (it == null) return const SizedBox.shrink();
                            final done = state.isDone(date, it);
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Material(
                                color: done ? AppColors.emerald.withValues(alpha: 0.10) : AppColors.creamDark.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  key: Key('report_$id'),
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => openItem(id),
                                  onLongPress: () => state.toggleItem(date, it),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                    child: Column(children: [
                                      Stack(clipBehavior: Clip.none, children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            border: Border.all(color: AppColors.gold, width: 1.5),
                                          ),
                                          child: const Icon(Icons.menu_book, color: AppColors.emerald),
                                        ),
                                        if (done)
                                          const Positioned(
                                            right: -4,
                                            bottom: -4,
                                            child: Icon(Icons.check_circle, color: AppColors.onTime, size: 20),
                                          ),
                                      ]),
                                      const SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(reportItemName(it, urdu), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        key: Key('report_check_$id'),
                                        onTap: () => state.toggleItem(date, it),
                                        child: Text(done ? s.t('read') : s.t('mark_read'),
                                            style: TextStyle(fontSize: 11, color: done ? AppColors.onTime : AppColors.gold)),
                                      ),
                                    ]),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 18),
                // ---------- tasbeehat morning / evening ----------
                LayoutBuilder(builder: (context, c) {
                  final morning = _TasbeehCard(title: '${s.t('tasbeehat')} : ${s.t('az_m')}', icon: Icons.wb_twilight, ids: reportMorning, date: date, onOpen: openItem);
                  final evening = _TasbeehCard(title: '${s.t('tasbeehat')} : ${s.t('az_e')}', icon: Icons.wb_sunny_outlined, ids: reportEvening, date: date, onOpen: openItem);
                  if (c.maxWidth < 340) return Column(children: [morning, const SizedBox(height: 12), evening]);
                  return IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(child: morning),
                      const SizedBox(width: 10),
                      Expanded(child: evening),
                    ]),
                  );
                }),
                const SizedBox(height: 18),
                // ---------- share ----------
                ExpansionTile(
                  key: const Key('report_preview'),
                  title: Text(s.t('report_preview'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: SelectableText(
                        text,
                        key: const Key('report_text'),
                        textDirection: urdu ? TextDirection.rtl : TextDirection.ltr,
                        style: TextStyle(fontFamily: urdu ? arabicFont : null, height: 1.6),
                      ),
                    ),
                  ],
                ),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('report_copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        toast(context, s.t('copied'));
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(s.t('copy')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('report_whatsapp'),
                      onPressed: () async {
                        final ok = await launchUrl(
                          Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
                          mode: LaunchMode.externalApplication,
                        );
                        if (!ok && context.mounted) {
                          Clipboard.setData(ClipboardData(text: text));
                          toast(context, s.t('copied'));
                        }
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _chillaMenu(BuildContext context, AppState state, DateTime date) async {
    final s = state.s;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text(s.t('start_chilla_today')),
            onTap: () => Navigator.pop(c, 'today'),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(s.t('start_chilla_date')),
            onTap: () => Navigator.pop(c, 'date'),
          ),
          if (state.settings.chillaStart != null)
            ListTile(
              leading: const Icon(Icons.stop_circle_outlined),
              title: Text(s.t('stop_chilla')),
              onTap: () => Navigator.pop(c, 'stop'),
            ),
        ]),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case 'today':
        state.startChilla(state.today);
      case 'date':
        final p = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: state.today,
          helpText: s.t('chilla_day1'),
        );
        if (p != null) state.startChilla(p);
      case 'stop':
        if (await confirm(context, state, s.t('stop_chilla'))) state.stopChilla();
    }
  }
}


/// Header from the design: green sky, mosque skyline, lanterns, crescent and
/// an arch with the title.
class _PlanHeader extends StatelessWidget {
  final String title;
  const _PlanHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return SizedBox(
      height: 230,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: GeometricPatternPainter())),
          const Positioned(right: 0, left: 120, bottom: 30, height: 110, child: CustomPaint(painter: MosqueSkylinePainter(color: Color(0x55000000)))),
          const Positioned(top: 50, right: 90, width: 44, height: 44, child: CustomPaint(painter: CrescentPainter())),
          const Positioned(top: 0, left: 12, width: 28, height: 100, child: CustomPaint(painter: LanternPainter())),
          const Positioned(top: 0, right: 12, width: 28, height: 100, child: CustomPaint(painter: LanternPainter())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: ClipPath(
                clipper: _ArchClipper(),
                child: Container(
                  width: 250,
                  height: 140,
                  padding: const EdgeInsets.only(top: 56),
                  decoration: const BoxDecoration(
                    color: AppColors.emerald,
                    border: Border(bottom: BorderSide(color: AppColors.gold, width: 2)),
                  ),
                  child: Column(children: [
                    Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.goldLight, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: arabicFont)),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 60, height: 1, color: AppColors.gold),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.diamond, size: 10, color: AppColors.gold)),
                      Container(width: 60, height: 1, color: AppColors.gold),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
          if (canPop)
            const SafeArea(child: Padding(padding: EdgeInsets.only(left: 4, top: 4), child: BackButton(color: Colors.white))),
        ]),
      ),
    );
  }
}

class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    return Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.55)
      ..quadraticBezierTo(0, h * 0.28, w * 0.28, h * 0.22)
      ..quadraticBezierTo(w * 0.45, h * 0.18, w * 0.5, 0)
      ..quadraticBezierTo(w * 0.55, h * 0.18, w * 0.72, h * 0.22)
      ..quadraticBezierTo(w, h * 0.28, w, h * 0.55)
      ..lineTo(w, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Card with a green ribbon title on top (as in the design).
class _RibbonCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _RibbonCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
            border: Border(bottom: BorderSide(color: AppColors.gold, width: 1.5)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 40, height: 1, color: AppColors.gold),
            const SizedBox(width: 10),
            Icon(icon, color: AppColors.goldLight, size: 26),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Container(width: 40, height: 1, color: AppColors.gold),
          ]),
        ),
        child,
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final PrayerStatus status;
  final bool urdu;
  const _StatusPill({required this.status, required this.urdu});

  @override
  Widget build(BuildContext context) {
    final prayed = isPrayed(status);
    final color = switch (status) {
      PrayerStatus.jamaat || PrayerStatus.alone => AppColors.onTime,
      PrayerStatus.qaza => AppColors.delayed,
      PrayerStatus.missed => AppColors.missed,
      PrayerStatus.none => Theme.of(context).colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: status == PrayerStatus.none ? Colors.transparent : color,
          child: Icon(
            prayed ? Icons.check : (status == PrayerStatus.missed ? Icons.close : Icons.remove),
            size: 14,
            color: status == PrayerStatus.none ? color : Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(status == PrayerStatus.none ? (urdu ? 'درج کریں' : 'Mark') : reportPrayerStatus(status, urdu),
            style: TextStyle(fontWeight: FontWeight.w700, color: color == Theme.of(context).colorScheme.outline ? null : color)),
      ]),
    );
  }
}

class _TasbeehCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> ids;
  final DateTime date;
  final void Function(String id) onOpen;
  const _TasbeehCard({required this.title, required this.icon, required this.ids, required this.date, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final urdu = state.settings.urdu;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        const Positioned(
          right: 0,
          bottom: 0,
          width: 110,
          height: 70,
          child: CustomPaint(painter: MosqueSkylinePainter(color: Color(0x1A0B4D35))),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: AppColors.goldLight, size: 22),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
          for (final id in ids)
            Builder(builder: (context) {
              final it = state.itemById(id);
              if (it == null) return const SizedBox.shrink();
              final done = state.isDone(date, it);
              final mark = reportMark(state, date, it);
              return InkWell(
                key: Key('report_$id'),
                onTap: () => onOpen(id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(children: [
                    IconButton(
                      key: Key('report_check_$id'),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: done ? AppColors.onTime : Theme.of(context).colorScheme.outline),
                      onPressed: () => state.toggleItem(date, it),
                    ),
                    Expanded(
                      child: Text(reportItemName(it, urdu),
                          textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    if (!done && mark != '❌')
                      Text(mark, style: const TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w700)),
                  ]),
                ),
              );
            }),
          const SizedBox(height: 6),
        ]),
      ]),
    );
  }
}
