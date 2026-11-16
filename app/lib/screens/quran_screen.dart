import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../services/quran_repo.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';
import 'quran_reader_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final repo = QuranRepository.instance;
  int _tab = 0;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    repo.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    }, onError: (_) {
      if (mounted) setState(() => _error = true);
    });
  }

  void _open(int surah, [int ayah = 1]) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuranReaderScreen(surah: surah, ayah: ayah)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    return Column(
      children: [
        ScreenHeader(
          title: s.t('quran'),
          actions: [
            IconButton(
              key: const Key('quran_search'),
              tooltip: s.t('search'),
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuranSearchScreen())),
            ),
          ],
        ),
        Expanded(
          child: _error
              ? EmptyState(icon: Icons.error_outline, text: s.t('quran_load_error'))
              : !repo.isLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Column(children: [
                              const _TargetCard(),
                              const SizedBox(height: 10),
                              if (state.lastRead != null) _ContinueCard(onOpen: _open),
                              const SizedBox(height: 10),
                              SegmentedButton<int>(
                                showSelectedIcon: false,
                                segments: [
                                  ButtonSegment(value: 0, label: Text(s.t('surah'))),
                                  ButtonSegment(value: 1, label: Text(s.t('para'))),
                                  ButtonSegment(value: 2, label: Text(s.t('saved'))),
                                  ButtonSegment(value: 3, label: Text(s.t('khatam'))),
                                ],
                                selected: {_tab},
                                onSelectionChanged: (v) => setState(() => _tab = v.first),
                              ),
                              const SizedBox(height: 8),
                            ]),
                          ),
                        ),
                        switch (_tab) {
                          0 => _SurahList(onOpen: _open),
                          1 => _JuzList(onOpen: _open),
                          2 => _SavedList(onOpen: _open),
                          _ => const SliverToBoxAdapter(child: _KhatamTracker()),
                        },
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    final today = state.today;
    final rec = state.day(today);
    final target = state.settings.quranTarget;
    final ratio = target == 0 ? 0.0 : (rec.quranPages / target).clamp(0.0, 1.0).toDouble();
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.t('daily_target'), style: theme.textTheme.titleSmall),
                  InkWell(
                    onTap: () => _editTarget(context, state),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(
                        child: Text('$target ${s.t('pages')}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 16, color: theme.colorScheme.primary),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    IconButton.filledTonal(
                      key: const Key('quran_minus'),
                      onPressed: rec.quranPages > 0 ? () => state.addPages(today, -1) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('${rec.quranPages} / $target',
                              key: const Key('quran_pages'),
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      key: const Key('quran_plus'),
                      onPressed: () => state.addPages(today, 1),
                      icon: const Icon(Icons.add),
                    ),
                  ]),
                  Text(s.t('pages_today'), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ProgressRing(
              value: ratio,
              size: 80,
              stroke: 8,
              child: Text('${(ratio * 100).round()}%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTarget(BuildContext context, AppState state) async {
    final s = state.s;
    final v = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(s.t('quran_target'), style: Theme.of(c).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final n in [1, 2, 4, 5, 10, 15, 20, 30])
                ChoiceChip(
                  label: Text('$n'),
                  selected: state.settings.quranTarget == n,
                  onSelected: (_) => Navigator.pop(c, n),
                ),
              ActionChip(
                label: Text(s.t('custom')),
                onPressed: () async {
                  final n = await askNumber(c, state, s.t('quran_target'), initial: state.settings.quranTarget, max: 604);
                  if (n != null && c.mounted) Navigator.pop(c, n);
                },
              ),
            ]),
          ]),
        ),
      ),
    );
    if (v != null) {
      state.settings.quranTarget = v;
      state.saveSettings();
    }
  }
}

class _ContinueCard extends StatelessWidget {
  final void Function(int, [int]) onOpen;
  const _ContinueCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final repo = QuranRepository.instance;
    final lr = state.lastRead!;
    final info = repo.surah(lr.surah);
    return Card(
      color: AppColors.emerald,
      child: ListTile(
        key: const Key('continue_reading'),
        leading: const Icon(Icons.bookmark, color: AppColors.goldLight),
        title: Text(s.t('continue_reading'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        subtitle: Text('${info.name} • ${s.t('ayah')} ${lr.ayah} • ${s.t('page')} ${repo.pageOf(lr.surah, lr.ayah)}',
            style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.play_circle_fill, color: AppColors.goldLight, size: 32),
        onTap: () => onOpen(lr.surah, lr.ayah),
      ),
    );
  }
}

class SurahNumberBadge extends StatelessWidget {
  final int number;
  final bool done;
  const SurahNumberBadge(this.number, {super.key, this.done = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? AppColors.emeraldMid : AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: done
          ? const Icon(Icons.check, color: Colors.white, size: 20)
          : Text('$number',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.goldLight : const Color(0xFF7A5B12),
              )),
    );
  }
}

class _SurahList extends StatelessWidget {
  final void Function(int, [int]) onOpen;
  const _SurahList({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final surahs = QuranRepository.instance.surahs;
    final todayKey = '${state.today.year}-${state.today.month.toString().padLeft(2, '0')}-${state.today.day.toString().padLeft(2, '0')}';
    final readToday = state.readingHistory.where((e) => e['d'] == todayKey).map((e) => e['s']).toSet();
    return SliverList.builder(
      itemCount: surahs.length,
      itemBuilder: (c, i) {
        final info = surahs[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Card(
            child: ListTile(
              key: Key('surah_${info.number}'),
              leading: SurahNumberBadge(info.number, done: readToday.contains(info.number)),
              title: Text(info.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  '${urdu ? info.meaningUr : info.meaningEn} • ${info.ayahs} ${s.t('ayat')} • ${info.meccan ? s.t('makki') : s.t('madani')}'),
              trailing: Text(info.arabicName, style: arabicStyle(context, size: 20, color: AppColors.emeraldMid)),
              onTap: () => onOpen(info.number),
            ),
          ),
        );
      },
    );
  }
}

class _JuzList extends StatelessWidget {
  final void Function(int, [int]) onOpen;
  const _JuzList({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final repo = QuranRepository.instance;
    return SliverList.builder(
      itemCount: 30,
      itemBuilder: (c, i) {
        final start = repo.juzStarts[i];
        final info = repo.surah(start[0]);
        final done = state.juzDone.contains(i + 1);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Card(
            child: ListTile(
              key: Key('juz_${i + 1}'),
              leading: SurahNumberBadge(i + 1, done: done),
              title: Text('${s.t('para')} ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${info.name} ${start[0]}:${start[1]} • ${s.t('page')} ${repo.pageOf(start[0], start[1])}'),
              trailing: IconButton(
                tooltip: s.t('mark_para'),
                icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline,
                    color: done ? AppColors.emeraldMid : Theme.of(context).colorScheme.outline),
                onPressed: () => state.toggleJuz(i + 1),
              ),
              onTap: () => onOpen(start[0], start[1]),
            ),
          ),
        );
      },
    );
  }
}

class _SavedList extends StatelessWidget {
  final void Function(int, [int]) onOpen;
  const _SavedList({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final repo = QuranRepository.instance;
    final items = <(String, QuranRef, IconData)>[
      for (final b in state.bookmarks) (s.t('bookmark'), b, Icons.bookmark),
      for (final f in state.favouriteAyat) (s.t('favourite'), f, Icons.favorite),
    ];
    final history = state.readingHistory.take(20).toList();
    if (items.isEmpty && history.isEmpty) {
      return SliverToBoxAdapter(child: EmptyState(icon: Icons.bookmark_border, text: s.t('no_bookmarks')));
    }
    return SliverList.list(children: [
      for (final it in items)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Card(
            child: ListTile(
              leading: Icon(it.$3, color: it.$3 == Icons.favorite ? Colors.redAccent : AppColors.gold),
              title: Text('${repo.surah(it.$2.surah).name} ${it.$2.surah}:${it.$2.ayah}'),
              subtitle: Text(it.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpen(it.$2.surah, it.$2.ayah),
            ),
          ),
        ),
      if (history.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SectionTitle(s.t('reading_history'))),
      for (final h in history)
        ListTile(
          dense: true,
          leading: const Icon(Icons.history),
          title: Text('${repo.surah((h['s'] as num).toInt()).name} ${h['s']}:${h['a']}'),
          subtitle: Text('${h['d']}'),
          onTap: () => onOpen((h['s'] as num).toInt(), (h['a'] as num).toInt()),
        ),
    ]);
  }
}

class _KhatamTracker extends StatelessWidget {
  const _KhatamTracker();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    final khatamRatio = state.khatamPages / quranTotalPages;
    final week = [for (var i = 6; i >= 0; i--) state.today.subtract(Duration(days: i))];
    final target = state.settings.quranTarget <= 0 ? 1 : state.settings.quranTarget;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(s.t('khatam_progress'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                    Text('${(khatamRatio * 100).toStringAsFixed(1)}%',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: khatamRatio, minHeight: 10),
                  ),
                  const SizedBox(height: 6),
                  Text('${state.khatamPages} / $quranTotalPages ${s.t('pages')}  •  ${s.t('khatams_done')}: ${state.khatamCount}',
                      style: theme.textTheme.bodySmall),
                  if (state.khatamPages > 0)
                    Text(
                      '${s.t('days_left_at_target')}: ${((quranTotalPages - state.khatamPages) / target).ceil()}',
                      style: theme.textTheme.bodySmall,
                    ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () async {
                        if (await confirm(context, state, s.t('reset_khatam'))) state.resetKhatam();
                      },
                      child: Text(s.t('reset_khatam')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.t('pages_this_week'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                MiniBarChart(
                  values: [for (final d in week) (state.day(d).quranPages / target).clamp(0.0, 1.0).toDouble()],
                  labels: [for (final d in week) '${state.day(d).quranPages}'],
                  height: 90,
                  highlight: 6,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
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
                          key: Key('juz_grid_$j'),
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => state.toggleJuz(j),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: state.juzDone.contains(j)
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withValues(alpha: 0.08),
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
        ],
      ),
    );
  }
}

/// Surah / ayah search.
class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';
  List<Ayah> _ayahs = const [];
  bool _searching = false;
  int _token = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() {
      _q = q;
      _ayahs = const [];
    });
    final t = ++_token;
    if (q.trim().length < 3 || RegExp(r'^\d+(:\d+)?$').hasMatch(q.trim())) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (t != _token) return;
    setState(() => _searching = true);
    final res = await QuranRepository.instance.searchText(q);
    if (!mounted || t != _token) return;
    setState(() {
      _ayahs = res;
      _searching = false;
    });
  }

  void _open(int s, int a) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuranReaderScreen(surah: s, ayah: a)));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final urdu = state.settings.urdu;
    final repo = QuranRepository.instance;
    final surahs = repo.isLoaded ? repo.searchSurahs(_q) : const <SurahInfo>[];
    final ref = RegExp(r'^(\d+):(\d+)$').firstMatch(_q.trim());
    QuranRef? direct;
    if (ref != null) {
      final sn = int.parse(ref.group(1)!), an = int.parse(ref.group(2)!);
      if (sn >= 1 && sn <= 114 && an >= 1 && an <= repo.surah(sn).ayahs) direct = QuranRef(sn, an);
    }

    return HeaderScaffold(
      title: s.t('search'),
      headerBottom: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          key: const Key('quran_search_field'),
          controller: _ctrl,
          autofocus: true,
          onChanged: _search,
          decoration: InputDecoration(
            hintText: s.t('search_hint'),
            prefixIcon: const Icon(Icons.search),
            isDense: true,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (direct != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.arrow_forward),
                title: Text('${repo.surah(direct.surah).name} ${direct.key}'),
                onTap: () {
                  final d = direct!;
                  _open(d.surah, d.ayah);
                },
              ),
            ),
          if (_q.trim().isNotEmpty && surahs.isNotEmpty) SectionTitle(s.t('surahs')),
          if (_q.trim().isNotEmpty)
            for (final info in surahs.take(20))
              ListTile(
                leading: SurahNumberBadge(info.number),
                title: Text(info.name),
                subtitle: Text(urdu ? info.meaningUr : info.meaningEn),
                trailing: Text(info.arabicName, style: arabicStyle(context, size: 18)),
                onTap: () => _open(info.number, 1),
              ),
          if (_searching) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_ayahs.isNotEmpty) SectionTitle('${s.t('ayat')} (${_ayahs.length})'),
          for (final a in _ayahs)
            Card(
              child: ListTile(
                title: Text('${repo.surah(a.surah).name} ${a.surah}:${a.number}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(urdu ? a.ur : a.en, maxLines: 3, overflow: TextOverflow.ellipsis),
                onTap: () => _open(a.surah, a.number),
              ),
            ),
          if (_q.trim().length >= 3 && !_searching && _ayahs.isEmpty && surahs.isEmpty && direct == null)
            EmptyState(icon: Icons.search_off, text: s.t('no_results')),
        ],
      ),
    );
  }
}
