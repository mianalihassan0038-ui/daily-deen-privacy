import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../services/quran_repo.dart';
import '../widgets/common.dart';

/// Reads one surah. Opens at [ayah] (earlier ayat can be scrolled to above).
class QuranReaderScreen extends StatefulWidget {
  final int surah;
  final int ayah;
  const QuranReaderScreen({super.key, required this.surah, this.ayah = 1});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final repo = QuranRepository.instance;
  final _centerKey = GlobalKey();
  List<Ayah>? _ayahs;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await repo.ensureLoaded();
      final list = await repo.ayahs(widget.surah);
      if (!mounted) return;
      setState(() => _ayahs = list);
      AppScope.of(context).setLastRead(widget.surah, widget.ayah.clamp(1, list.length).toInt());
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _openSurah(int n) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => QuranReaderScreen(surah: n)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final info = repo.isLoaded ? repo.surah(widget.surah) : null;
    final title = info == null ? s.t('quran') : '${info.number}. ${info.name}';
    final ayahs = _ayahs;

    return HeaderScaffold(
      title: title,
      actions: [
        IconButton(
          key: const Key('reader_settings'),
          tooltip: s.t('display'),
          icon: const Icon(Icons.text_fields, color: Colors.white),
          onPressed: () => _displaySheet(context, state),
        ),
      ],
      body: _error != null
          ? EmptyState(icon: Icons.error_outline, text: s.t('quran_load_error'))
          : ayahs == null
              ? const Center(child: CircularProgressIndicator())
              : _buildList(context, state, info!, ayahs),
    );
  }

  Widget _buildList(BuildContext context, AppState state, SurahInfo info, List<Ayah> ayahs) {
    final start = (widget.ayah.clamp(1, ayahs.length).toInt()) - 1;
    final before = ayahs.sublist(0, start).reversed.toList();
    final after = ayahs.sublist(start);
    return CustomScrollView(
      center: _centerKey,
      slivers: [
        SliverList.builder(
          itemCount: before.length + 1,
          itemBuilder: (c, i) => i == before.length ? _SurahHeader(info: info) : _AyahCard(ayah: before[i]),
        ),
        SliverList.builder(
          key: _centerKey,
          itemCount: after.length + 1,
          itemBuilder: (c, i) {
            if (i == after.length) return _footer(context, state, info);
            return _AyahCard(ayah: after[i]);
          },
        ),
      ],
    );
  }

  Widget _footer(BuildContext context, AppState state, SurahInfo info) {
    final s = state.s;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Row(children: [
        if (info.number > 1)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openSurah(info.number - 1),
              icon: const Icon(Icons.chevron_left),
              label: Text(repo.surah(info.number - 1).name, overflow: TextOverflow.ellipsis),
            ),
          ),
        if (info.number > 1 && info.number < 114) const SizedBox(width: 10),
        if (info.number < 114)
          Expanded(
            child: FilledButton.icon(
              key: const Key('next_surah'),
              onPressed: () => _openSurah(info.number + 1),
              icon: const Icon(Icons.chevron_right),
              label: Text('${s.t('next')}: ${repo.surah(info.number + 1).name}', overflow: TextOverflow.ellipsis),
            ),
          ),
      ]),
    );
  }

  void _displaySheet(BuildContext context, AppState state) {
    final s = state.s;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => ListenableBuilder(
        listenable: state,
        builder: (c, _) {
          final st = state.settings;
          return SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SwitchListTile(
                title: Text(s.t('show_urdu')),
                value: st.showUrdu,
                onChanged: (v) {
                  st.showUrdu = v;
                  state.saveSettings();
                },
              ),
              SwitchListTile(
                title: Text(s.t('show_english')),
                value: st.showEnglish,
                onChanged: (v) {
                  st.showEnglish = v;
                  state.saveSettings();
                },
              ),
              SwitchListTile(
                title: Text(s.t('show_translit')),
                value: st.showTranslit,
                onChanged: (v) {
                  st.showTranslit = v;
                  state.saveSettings();
                },
              ),
              ListTile(
                title: Text(s.t('arabic_size')),
                subtitle: Slider(
                  min: 18,
                  max: 40,
                  divisions: 11,
                  value: st.arabicSize.clamp(18, 40).toDouble(),
                  label: st.arabicSize.round().toString(),
                  onChanged: (v) {
                    st.arabicSize = v;
                    state.saveSettings();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(s.t('quran_sources'), style: Theme.of(c).textTheme.bodySmall),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  final SurahInfo info;
  const _SurahHeader({required this.info});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    final urdu = AppScope.of(context).settings.urdu;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Column(children: [
        Text(info.arabicName, style: arabicStyle(context, size: 30, color: AppColors.goldLight)),
        Text(info.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        Text('${urdu ? info.meaningUr : info.meaningEn} • ${info.ayahs} ${s.t('ayat')} • ${info.meccan ? s.t('makki') : s.t('madani')}',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        // Al-Fatihah includes the Basmala as ayah 1; At-Tawbah has none.
        if (info.number != 1 && info.number != 9) ...[
          const SizedBox(height: 10),
          Text('بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ', style: arabicStyle(context, size: 24, color: Colors.white)),
        ],
      ]),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  const _AyahCard({required this.ayah});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final st = state.settings;
    final repo = QuranRepository.instance;
    final theme = Theme.of(context);
    final bookmarked = state.isBookmarked(ayah.surah, ayah.number);
    final fav = state.isFavouriteAyah(ayah.surah, ayah.number);
    final isLast = state.lastRead?.surah == ayah.surah && state.lastRead?.ayah == ayah.number;
    final pageStart = repo.isPageStart(ayah.surah, ayah.number);
    final page = repo.pageOf(ayah.surah, ayah.number);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pageStart && ayah.number != 1)
          _PageDivider(page: page - 1),
        Card(
          key: Key('ayah_${ayah.surah}_${ayah.number}'),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          color: isLast ? AppColors.gold.withValues(alpha: 0.10) : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => state.setLastRead(ayah.surah, ayah.number),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${ayah.surah}:${ayah.number}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                    ),
                    if (isLast) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.push_pin, size: 16, color: AppColors.gold),
                    ],
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: s.t('bookmark'),
                      icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border, color: AppColors.gold),
                      onPressed: () => state.toggleBookmark(ayah.surah, ayah.number),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: s.t('favourite'),
                      icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent),
                      onPressed: () => state.toggleFavouriteAyah(ayah.surah, ayah.number),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: s.t('copy'),
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        final text = [
                          ayah.arabic,
                          if (st.showUrdu) ayah.ur,
                          if (st.showEnglish) ayah.en,
                          '(${repo.surah(ayah.surah).name} ${ayah.surah}:${ayah.number})',
                        ].join('\n\n');
                        Clipboard.setData(ClipboardData(text: text));
                        toast(context, s.t('copied'));
                      },
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    ayah.arabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: arabicStyle(context, size: st.arabicSize, weight: FontWeight.w400),
                  ),
                  if (st.showTranslit) ...[
                    const SizedBox(height: 6),
                    Text(ayah.translit,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: AppColors.emeraldMid)),
                  ],
                  if (st.showUrdu) ...[
                    const SizedBox(height: 8),
                    Text(ayah.ur,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontFamily: arabicFont, fontSize: 17, height: 1.8)),
                  ],
                  if (st.showEnglish) ...[
                    const SizedBox(height: 6),
                    Text(ayah.en, textDirection: TextDirection.ltr, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (ayah.number == repo.surah(ayah.surah).ayahs && _isLastOfPage(repo, ayah)) _PageDivider(page: page),
      ],
    );
  }

  bool _isLastOfPage(QuranRepository repo, Ayah a) {
    // The surah's last ayah also ends a page if the next surah starts a new page.
    if (a.surah == 114) return true;
    return repo.isPageStart(a.surah + 1, 1);
  }
}

/// Divider shown after the last ayah of a mushaf page with a "mark read" toggle.
class _PageDivider extends StatelessWidget {
  final int page;
  const _PageDivider({required this.page});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    if (page < 1) return const SizedBox.shrink();
    final read = state.readPages.contains(page);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        const Expanded(child: Divider(color: AppColors.gold)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ActionChip(
            key: Key('page_$page'),
            avatar: Icon(read ? Icons.check_circle : Icons.check_circle_outline,
                color: read ? AppColors.onTime : AppColors.gold, size: 18),
            label: Text(read ? '${s.t('page')} $page • ${s.t('read')}' : '${s.t('page')} $page • ${s.t('mark_read')}'),
            onPressed: () => state.togglePageRead(page),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.gold)),
      ]),
    );
  }
}
