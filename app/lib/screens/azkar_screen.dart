import 'package:flutter/material.dart';

import 'azkar_schedule_screen.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../data/azkar.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';
import 'shell.dart';

/// 0 = Azkar, 1 = Tasbeeh (inside the Azkar tab).
final ValueNotifier<int> azkarSubTab = ValueNotifier<int>(0);

/// Dhikr key to pre-select when the Tasbeeh opens.
final ValueNotifier<String?> tasbeehSelect = ValueNotifier<String?>(null);

class TasbeehLauncher {
  static void open(BuildContext context, String dhikrKey) {
    tasbeehSelect.value = dhikrKey;
    azkarSubTab.value = 1;
    ShellScope.go(context, Tabs.azkar);
  }
}

(IconData, Color) azkarVisual(AzkarType t) => switch (t) {
      AzkarType.morning => (Icons.wb_sunny, const Color(0xFFE09A2D)),
      AzkarType.evening => (Icons.nights_stay, const Color(0xFF5B4BB7)),
      AzkarType.sleep => (Icons.bedtime, const Color(0xFF2E5E8C)),
      AzkarType.afterSalah => (Icons.mosque, AppColors.emeraldMid),
      AzkarType.wakeUp => (Icons.alarm, const Color(0xFFD45A3A)),
      AzkarType.daily => (Icons.today, const Color(0xFF0B6E4F)),
      AzkarType.protection => (Icons.shield, const Color(0xFF3E7BC4)),
      AzkarType.travel => (Icons.flight_takeoff, const Color(0xFF7A5BC4)),
      AzkarType.salah => (Icons.self_improvement, const Color(0xFF0E7C86)),
      AzkarType.kalimas => (Icons.auto_stories, AppColors.gold),
    };

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    azkarSubTab.addListener(_changed);
  }

  @override
  void dispose() {
    azkarSubTab.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    return Column(
      children: [
        ScreenHeader(
          title: s.t('azkar_tasbeeh'),
          actions: [
            IconButton(
              key: const Key('azkar_schedule'),
              tooltip: s.t('azkar_schedule'),
              icon: const Icon(Icons.schedule, color: Colors.white),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AzkarScheduleScreen())),
            ),
          ],
          bottom: HeaderTabs(
            labels: [s.t('azkar'), s.t('tasbeeh')],
            index: azkarSubTab.value,
            onChanged: (i) => azkarSubTab.value = i,
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: azkarSubTab.value,
            children: const [AzkarCategoriesList(), TasbeehPanel()],
          ),
        ),
      ],
    );
  }
}

/// List of Azkar / Dua categories plus favourites.
class AzkarCategoriesList extends StatelessWidget {
  const AzkarCategoriesList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final today = state.today;
    final favs = [
      for (final list in azkar.values)
        for (final z in list)
          if (state.settings.favAzkar.contains(z.id)) z,
    ];
    final seen = <String>{};
    final uniqueFavs = favs.where((z) => seen.add(z.id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        SectionTitle(s.t('categories')),
        Card(
          child: Column(children: [
            for (final t in AzkarType.values)
              Builder(builder: (context) {
                final (icon, color) = azkarVisual(t);
                final core = coreAzkarIndices(t).length;
                final extras = azkar[t]!.length - core;
                final doneCount = coreAzkarDone(t, (k) => state.azkarCount(today, k));
                final routineId = azkarRoutineId[t];
                final setDone = routineId != null && state.day(today).done.contains(routineId);
                return ListTile(
                  key: Key('azkar_cat_${t.name}'),
                  leading: IconBadge(icon, color: color),
                  title: Text(azkarTypeNames[t]![urdu ? 1 : 0], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$doneCount / $core ${s.t('completed').toLowerCase()}'
                      '${extras > 0 ? '  •  +$extras ${s.t('extra_azkar_short')}' : ''}'),
                  trailing: setDone
                      ? const Icon(Icons.check_circle, color: AppColors.onTime)
                      : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AzkarDetailScreen(type: t))),
                );
              }),
          ]),
        ),
        if (uniqueFavs.isNotEmpty) ...[
          SectionTitle(s.t('favourites')),
          Card(
            child: Column(children: [
              for (final z in uniqueFavs)
                ListTile(
                  leading: const Icon(Icons.star, color: AppColors.gold),
                  title: Text(
                    (urdu ? z.titleUr : z.titleEn).isNotEmpty ? (urdu ? z.titleUr : z.titleEn) : z.translit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(z.reference),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ZikrDetailScreen(zikr: z))),
                ),
            ]),
          ),
        ],
        const SizedBox(height: 12),
        Text(s.t('azkar_sources'), style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Screen that lists all azkar of a category with counters.
class AzkarDetailScreen extends StatelessWidget {
  final AzkarType type;
  const AzkarDetailScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final today = state.today;
    final list = azkar[type]!;
    final routineId = azkarRoutineId[type];
    final setDone = routineId != null && state.day(today).done.contains(routineId);
    final core = coreAzkarIndices(type);
    final extras = [for (var i = 0; i < list.length; i++) if (list[i].extra) i];
    final doneCount = coreAzkarDone(type, (k) => state.azkarCount(today, k));

    return HeaderScaffold(
      title: azkarTypeNames[type]![urdu ? 1 : 0],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                ProgressRing(
                  value: core.isEmpty ? 0 : doneCount / core.length,
                  size: 54,
                  stroke: 6,
                  child: Text('$doneCount/${core.length}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(s.t('azkar_hint'), style: Theme.of(context).textTheme.bodySmall)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          for (final i in core) ...[
            ZikrCard(
              zikr: list[i],
              countKey: '${type.name}_$i',
              onCompleted: () => _checkAll(state),
            ),
            const SizedBox(height: 10),
          ],
          if (extras.isNotEmpty) ...[
            Padding(
              key: const Key('extra_azkar_header'),
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Text(s.t('extra_azkar'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(s.t('extra_azkar_hint'), style: Theme.of(context).textTheme.bodySmall),
            ),
            for (final i in extras) ...[
              ZikrCard(zikr: list[i], countKey: '${type.name}_$i'),
              const SizedBox(height: 10),
            ],
          ],
          if (routineId != null)
            FilledButton.icon(
              key: const Key('azkar_mark_complete'),
              onPressed: () => state.setDone(today, routineId, !setDone),
              icon: Icon(setDone ? Icons.check_circle : Icons.check),
              label: Text(setDone ? s.t('completed') : s.t('mark_complete')),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
        ],
      ),
    );
  }

  void _checkAll(AppState state) {
    final list = azkar[type]!;
    final routineId = azkarRoutineId[type];
    if (routineId == null) return;
    final today = state.today;
    for (final i in coreAzkarIndices(type)) {
      if (state.azkarCount(today, '${type.name}_$i') < list[i].count) return;
    }
    state.setDone(today, routineId, true);
  }
}

/// One zikr with Arabic, transliteration, translations, counter and reference.
class ZikrCard extends StatelessWidget {
  final Zikr zikr;
  final String countKey;
  final VoidCallback? onCompleted;
  const ZikrCard({super.key, required this.zikr, required this.countKey, this.onCompleted});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final today = state.today;
    final count = state.azkarCount(today, countKey);
    final done = count >= zikr.count;
    final fav = state.settings.favAzkar.contains(zikr.id);
    final title = urdu ? zikr.titleUr : zikr.titleEn;

    return Card(
      key: Key('zikr_$countKey'),
      color: done ? AppColors.emerald.withValues(alpha: 0.06) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: done
            ? null
            : () {
                if (state.settings.tasbeehVibrate) HapticFeedback.selectionClick();
                state.setAzkarCount(today, countKey, count + 1);
                if (count + 1 >= zikr.count) {
                  if (state.settings.tasbeehVibrate) HapticFeedback.mediumImpact();
                  onCompleted?.call();
                }
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                if (title.isNotEmpty)
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)))
                else
                  const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: s.t('favourite'),
                  icon: Icon(fav ? Icons.star : Icons.star_border, color: AppColors.gold),
                  onPressed: () => state.toggleFavAzkar(zikr.id),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: s.t('reset'),
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: count == 0 ? null : () => state.setAzkarCount(today, countKey, 0),
                ),
              ]),
              Text(zikr.arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: arabicStyle(context, size: 24)),
              const SizedBox(height: 8),
              Text(zikr.translit,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: AppColors.emeraldMid)),
              const SizedBox(height: 8),
              Text(zikr.ur,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: urduStyle(context, size: 16)),
              const SizedBox(height: 6),
              Text(zikr.en, textDirection: TextDirection.ltr, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(zikr.reference,
                        style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppColors.gold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: done ? AppColors.onTime : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      done ? '✓ ${zikr.count}×' : '$count / ${zikr.count}',
                      style: TextStyle(color: done ? Colors.white : theme.colorScheme.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              if (!done)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(s.t('tap_card_to_count'), style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single dua page (used for "Dua of the day" and favourites).
class ZikrDetailScreen extends StatelessWidget {
  final Zikr zikr;
  const ZikrDetailScreen({super.key, required this.zikr});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    return HeaderScaffold(
      title: s.t('dua'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [ZikrCard(zikr: zikr, countKey: 'single_${zikr.id}')],
      ),
    );
  }
}

/// Digital Tasbeeh counter.
class TasbeehPanel extends StatefulWidget {
  const TasbeehPanel({super.key});

  @override
  State<TasbeehPanel> createState() => _TasbeehPanelState();
}

class _TasbeehPanelState extends State<TasbeehPanel> {
  String _key = tasbeehList.first.key;
  bool _awake = false;

  @override
  void initState() {
    super.initState();
    tasbeehSelect.addListener(_onSelect);
    shellTab.addListener(_syncWakelock);
    azkarSubTab.addListener(_syncWakelock);
    _onSelect();
  }

  @override
  void dispose() {
    tasbeehSelect.removeListener(_onSelect);
    shellTab.removeListener(_syncWakelock);
    azkarSubTab.removeListener(_syncWakelock);
    _setWakelock(false);
    super.dispose();
  }

  void _onSelect() {
    final k = tasbeehSelect.value;
    if (k != null && mounted) {
      setState(() => _key = k);
      tasbeehSelect.value = null;
    }
  }

  void _syncWakelock() {
    if (!mounted) return;
    final visible = shellTab.value == Tabs.azkar && azkarSubTab.value == 1;
    _setWakelock(visible && AppScope.of(context).settings.tasbeehKeepAwake);
  }

  void _setWakelock(bool on) {
    if (on == _awake) return;
    _awake = on;
    WakelockPlus.toggle(enable: on).catchError((_) {});
  }

  ({String key, String arabic, String name, int defTarget, bool custom}) _current(AppState state) {
    final base = dhikrBase(_key);
    for (final d in tasbeehList) {
      if (d.key == base) return (key: _key, arabic: d.arabic, name: state.settings.urdu ? d.ur : d.en, defTarget: d.target, custom: false);
    }
    for (final c in state.settings.customDhikr) {
      if (c.key == base) return (key: _key, arabic: c.text, name: c.text, defTarget: c.target, custom: true);
    }
    final d = tasbeehList.first;
    return (key: d.key, arabic: d.arabic, name: state.settings.urdu ? d.ur : d.en, defTarget: d.target, custom: false);
  }

  void _tap(AppState state, String key, int delta, int target) {
    final today = state.today;
    final before = state.day(today).dhikr[key] ?? 0;
    if (delta < 0 && before == 0) return;
    state.incrementDhikr(today, key, by: delta);
    if (delta > 0) {
      if (state.settings.tasbeehVibrate) {
        (before + 1) % target == 0 ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
      }
      if (state.settings.tasbeehSound) SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final theme = Theme.of(context);
    final today = state.today;
    final d = _current(state);
    final target = state.dhikrTarget(d.key, d.defTarget);
    final count = state.day(today).dhikr[d.key] ?? 0;
    final inRound = count % target;
    final rounds = count ~/ target;
    final todayTotal = state.day(today).totalDhikr;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWakelock());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          elevation: 2,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(children: [
              Text(d.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: arabicStyle(context, size: 30, weight: FontWeight.w700)),
              Text(
                [if (!d.custom) d.name, if (dhikrSession(d.key) == '@m') s.t('az_m'), if (dhikrSession(d.key) == '@e') s.t('az_e')].join(' • '),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    key: const Key('tasbeeh_minus'),
                    iconSize: 28,
                    onPressed: count > 0 ? () => _tap(state, d.key, -1, target) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    key: const Key('tasbeeh_tap'),
                    onTap: () => _tap(state, d.key, 1, target),
                    child: ProgressRing(
                      value: inRound / target,
                      size: 150,
                      stroke: 9,
                      color: AppColors.gold,
                      child: Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(colors: [AppColors.emeraldLight, AppColors.emerald]),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))],
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('$inRound',
                              key: const Key('tasbeeh_count'),
                              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800)),
                          Text(s.t('tap_to_count'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    key: const Key('tasbeeh_plus'),
                    iconSize: 28,
                    onPressed: () => _tap(state, d.key, 1, target),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('${s.t('target')}: $target  •  ${s.t('rounds')}: $rounds  •  ${s.t('today_total')}: $count',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('tasbeeh_reset'),
                onPressed: count == 0
                    ? null
                    : () async {
                        if (await confirm(context, state, s.t('reset_counter'), message: s.t('reset_counter_msg'))) {
                          final prev = state.resetDhikr(today, d.key);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(
                                content: Text(s.t('counter_reset')),
                                action: SnackBarAction(label: s.t('undo'), onPressed: () => state.restoreDhikr(today, d.key, prev)),
                              ));
                          }
                        }
                      },
                icon: const Icon(Icons.refresh),
                label: Text(s.t('reset')),
              ),
            ]),
          ),
        ),
        SectionTitle(s.t('target')),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final n in [33, 100, 500, 1000])
            ChoiceChip(
              key: Key('target_$n'),
              label: Text('$n'),
              selected: target == n,
              onSelected: (_) => state.setDhikrTarget(d.key, n),
            ),
          ActionChip(
            avatar: const Icon(Icons.edit, size: 16),
            label: Text(s.t('custom')),
            onPressed: () async {
              final n = await askNumber(context, state, s.t('custom_target'), initial: target);
              if (n != null) state.setDhikrTarget(d.key, n);
            },
          ),
        ]),
        SectionTitle(s.t('session')),
        SegmentedButton<String>(
          key: const Key('tasbeeh_session'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: '', label: Text(s.t('anytime'))),
            ButtonSegment(value: '@m', label: Text(s.t('az_m'))),
            ButtonSegment(value: '@e', label: Text(s.t('az_e'))),
          ],
          selected: {dhikrSession(_key)},
          onSelectionChanged: (v) => setState(() => _key = dhikrBase(_key) + v.first),
        ),
        SectionTitle(s.t('my_tasbeeh'), actionLabel: s.t('add'), onAction: () => _addCustom(context, state)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in tasbeehList)
            ChoiceChip(
              label: Text(urdu ? t.ur : t.en),
              selected: dhikrBase(_key) == t.key,
              onSelected: (_) => setState(() => _key = t.key + dhikrSession(_key)),
            ),
          for (final c in state.settings.customDhikr)
            InputChip(
              label: Text(c.text, overflow: TextOverflow.ellipsis),
              selected: dhikrBase(_key) == c.key,
              onSelected: (_) => setState(() => _key = c.key + dhikrSession(_key)),
              onDeleted: () async {
                if (await confirm(context, state, '${s.t('delete')}: ${c.text}?')) {
                  if (dhikrBase(_key) == c.key) setState(() => _key = tasbeehList.first.key);
                  state.deleteCustomDhikr(c.key);
                }
              },
            ),
        ]),
        SectionTitle(s.t('settings')),
        Card(
          child: Column(children: [
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: Text(s.t('vibration')),
              value: state.settings.tasbeehVibrate,
              onChanged: (v) {
                state.settings.tasbeehVibrate = v;
                state.saveSettings();
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.volume_up_outlined),
              title: Text(s.t('sound')),
              value: state.settings.tasbeehSound,
              onChanged: (v) {
                state.settings.tasbeehSound = v;
                state.saveSettings();
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.screen_lock_portrait_outlined),
              title: Text(s.t('keep_screen_on')),
              value: state.settings.tasbeehKeepAwake,
              onChanged: (v) {
                state.settings.tasbeehKeepAwake = v;
                state.saveSettings();
                _syncWakelock();
              },
            ),
          ]),
        ),
        SectionTitle(s.t('dhikr_history')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.t('today_total')}: $todayTotal', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (var i = 1; i <= 7; i++)
                Builder(builder: (context) {
                  final day = today.subtract(Duration(days: i));
                  final total = state.day(day).totalDhikr;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Expanded(child: Text('${day.day}/${day.month}/${day.year}')),
                      Text('$total', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  );
                }),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _addCustom(BuildContext context, AppState state) async {
    final s = state.s;
    final text = TextEditingController();
    final target = TextEditingController(text: '33');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.t('add_tasbeeh')),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: text,
              autofocus: true,
              maxLength: 80,
              decoration: InputDecoration(labelText: s.t('dhikr_text')),
              validator: (v) => (v ?? '').trim().isEmpty ? s.t('required') : null,
            ),
            TextFormField(
              controller: target,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.t('target')),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return n == null || n < 1 || n > 100000 ? s.t('enter_number') : null;
              },
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(c, true);
            },
            child: Text(s.t('save')),
          ),
        ],
      ),
    );
    if (ok == true) {
      state.addCustomDhikr(text.text.trim(), int.parse(target.text.trim()));
      setState(() => _key = state.settings.customDhikr.last.key);
    }
  }
}
