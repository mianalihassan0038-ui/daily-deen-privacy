import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../services/quran_repo.dart';
import '../widgets/common.dart';

/// Reads one surah. Opens at [ayah] (earlier ayat can be scrolled to above).
class QuranReaderScreen extends StatefulWidget {
  final int surah;
  final int ayah;
  /// Set when opened as a tilawat session from the routine: it records which
  /// pages were read so the user can log them when coming back.
  final QuranSession? session;
  const QuranReaderScreen({super.key, required this.surah, this.ayah = 1, this.session});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final repo = QuranRepository.instance;
  var _centerKey = GlobalKey();
  final _viewportKey = GlobalKey();
  final Map<int, GlobalKey> _cardKeys = {};
  final Map<int, GlobalKey<_MushafBlockState>> _blockKeys = {};
  late int _surah = widget.surah;
  late int _startAyah = widget.ayah;
  bool? _lastMode;
  List<Ayah>? _ayahs;
  Object? _error;

  /// Finds the ayah at the top of the screen and saves it as the reading
  /// position (per surah), so reading continues exactly from here.
  void _trackPosition() {
    final vp = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (vp == null || !vp.attached || _ayahs == null) return;
    final topY = vp.localToGlobal(Offset.zero).dy + 16;
    final state = AppScope.of(context);
    int? found;
    if (state.settings.quranMushaf) {
      final keys = _blockKeys.keys.toList()..sort();
      for (final k in keys) {
        final st = _blockKeys[k]!.currentState;
        if (st == null) continue;
        final a = st.ayahAt(topY);
        if (a != null) {
          found = a;
          break;
        }
      }
    } else {
      double? bestTop;
      _cardKeys.forEach((n, key) {
        final rb = key.currentContext?.findRenderObject() as RenderBox?;
        if (rb == null || !rb.attached) return;
        final top = rb.localToGlobal(Offset.zero).dy;
        if (top + rb.size.height > topY && (bestTop == null || top < bestTop!)) {
          bestTop = top;
          found = n;
        }
      });
    }
    if (found == null) return;
    state.setLastRead(_surah, found!);
    widget.session?.record(_surah, found!, repo.pageOf(_surah, found!));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await repo.ensureLoaded();
      final list = await repo.ayahs(_surah);
      if (!mounted) return;
      setState(() => _ayahs = list);
      final a = _startAyah.clamp(1, list.length).toInt();
      AppScope.of(context).setLastRead(_surah, a);
      widget.session?.record(_surah, a, repo.pageOf(_surah, a));
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Opens another surah in this same screen (each surah is its own
  /// reading; the next one starts at its beginning).
  void _openSurah(int n) {
    setState(() {
      _surah = n;
      _startAyah = 1;
      _ayahs = null;
      _cardKeys.clear();
      _blockKeys.clear();
      _centerKey = GlobalKey();
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final info = repo.isLoaded ? repo.surah(_surah) : null;
    // Switching mushaf / translation view keeps the reading position.
    final mode = state.settings.quranMushaf;
    if (_lastMode != null && _lastMode != mode) {
      _startAyah = state.resumeAyah(_surah);
      _centerKey = GlobalKey();
    }
    _lastMode = mode;
    final title = info == null ? s.t('quran') : '${info.number}. ${info.name}';
    final ayahs = _ayahs;

    return HeaderScaffold(
      title: title,
      actions: [
        IconButton(
          key: const Key('reader_mode'),
          tooltip: state.settings.quranMushaf ? s.t('translation_view') : s.t('mushaf_view'),
          icon: Icon(state.settings.quranMushaf ? Icons.translate : Icons.chrome_reader_mode, color: Colors.white),
          onPressed: () {
            state.settings.quranMushaf = !state.settings.quranMushaf;
            state.saveSettings();
          },
        ),
        IconButton(
          key: const Key('reader_settings'),
          tooltip: s.t('display'),
          icon: const Icon(Icons.text_fields, color: Colors.white),
          onPressed: () => _displaySheet(context, state),
        ),
      ],
      body: _error != null
          ? RetryState(
              text: s.t('quran_load_error'),
              onRetry: () {
                setState(() => _error = null);
                _load();
              },
            )
          : ayahs == null
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  if (_startAyah > 1)
                    Material(
                      key: const Key('resume_banner'),
                      color: AppColors.gold.withValues(alpha: 0.14),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                        child: Row(children: [
                          const Icon(Icons.bookmark, size: 18, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('${s.t('resumed_at')} ${s.t('ayah')} $_startAyah',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Flexible(
                            child: TextButton(
                            key: const Key('start_beginning'),
                            onPressed: () => setState(() {
                              _startAyah = 1;
                              _centerKey = GlobalKey();
                            }),
                            child: Text(s.t('start_beginning'), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          ),
                        ]),
                      ),
                    ),
                  Expanded(
                    child: NotificationListener<ScrollEndNotification>(
                      onNotification: (_) {
                        _trackPosition();
                        return false;
                      },
                      child: KeyedSubtree(key: _viewportKey, child: _buildList(context, state, info!, ayahs)),
                    ),
                  ),
                ]),
    );
  }

  Widget _buildList(BuildContext context, AppState state, SurahInfo info, List<Ayah> ayahs) {
    if (state.settings.quranMushaf) return _buildMushaf(context, state, info, ayahs);
    final start = (_startAyah.clamp(1, ayahs.length).toInt()) - 1;
    final before = ayahs.sublist(0, start).reversed.toList();
    final after = ayahs.sublist(start);
    final top = start == 0; // opening at ayah 1: show the surah header first
    return CustomScrollView(
      center: _centerKey,
      slivers: [
        SliverList.builder(
          itemCount: before.length + (top ? 0 : 1),
          itemBuilder: (c, i) => i == before.length ? _SurahHeader(info: info) : _card(before[i]),
        ),
        SliverList.builder(
          key: _centerKey,
          itemCount: after.length + 1 + (top ? 1 : 0),
          itemBuilder: (c, i) {
            if (top) {
              if (i == 0) return _SurahHeader(info: info);
              i--;
            }
            if (i == after.length) return _footer(context, state, info);
            return _card(after[i]);
          },
        ),
      ],
    );
  }

  /// Mushaf view: the surah as flowing Arabic text, one block per ruku, with
  /// ayah-number medallions and the ع ruku sign — like a printed Quran. Tap
  /// any ayah to read its translation and use bookmark / copy.
  Widget _buildMushaf(BuildContext context, AppState state, SurahInfo info, List<Ayah> ayahs) {
    final blocks = <List<Ayah>>[];
    for (final a in ayahs) {
      if (blocks.isEmpty || repo.isRukuStart(a.surah, a.number)) blocks.add([]);
      blocks.last.add(a);
    }
    final startAyah = _startAyah.clamp(1, ayahs.length).toInt();
    final startBlock = blocks.indexWhere((b) => b.last.number >= startAyah);
    final before = blocks.sublist(0, startBlock).reversed.toList();
    final after = blocks.sublist(startBlock);
    final top = startBlock == 0;
    return CustomScrollView(
      key: const Key('mushaf_view'),
      center: _centerKey,
      slivers: [
        SliverList.builder(
          itemCount: before.length + (top ? 0 : 1),
          itemBuilder: (c, i) => i == before.length ? _SurahHeader(info: info) : _block(before[i]),
        ),
        SliverList.builder(
          key: _centerKey,
          itemCount: after.length + 2 + (top ? 1 : 0),
          itemBuilder: (c, i) {
            if (top) {
              if (i == 0) return _SurahHeader(info: info);
              i--;
            }
            if (i == after.length) return _footer(context, state, info);
            if (i == after.length + 1) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Text(state.s.t('mushaf_tap_hint'),
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              );
            }
            return _block(after[i]);
          },
        ),
      ],
    );
  }

  Widget _card(Ayah a) => KeyedSubtree(key: _cardKeys.putIfAbsent(a.number, GlobalKey.new), child: _AyahCard(ayah: a));

  Widget _block(List<Ayah> b) =>
      _MushafBlock(key: _blockKeys.putIfAbsent(b.first.number, GlobalKey<_MushafBlockState>.new), ayahs: b);

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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<bool>(
                  key: const Key('view_toggle'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: true, icon: const Icon(Icons.chrome_reader_mode), label: Text(s.t('mushaf_view'))),
                    ButtonSegment(value: false, icon: const Icon(Icons.translate), label: Text(s.t('translation_view'))),
                  ],
                  selected: {st.quranMushaf},
                  onSelectionChanged: (v) {
                    st.quranMushaf = v.first;
                    state.saveSettings();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(child: Text(s.t('quran_script'))),
                  SegmentedButton<bool>(
                    key: const Key('script_toggle'),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: true, label: Text(s.t('script_indopak'))),
                      ButtonSegment(value: false, label: Text(s.t('script_uthmani'))),
                    ],
                    selected: {st.indoPakScript},
                    onSelectionChanged: (v) {
                      st.indoPakScript = v.first;
                      state.saveSettings();
                    },
                  ),
                ]),
              ),
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
        Text(info.arabicName,
            style: quranStyle(context, indoPak: AppScope.of(context).settings.indoPakScript, size: 28, color: AppColors.goldLight)),
        Text(info.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(
            '${urdu ? info.meaningUr : info.meaningEn} • ${info.meccan ? s.t('makki') : s.t('madani')} • '
            '${info.ayahs} ${s.t('ayat')} • ${QuranRepository.instance.rukuCount(info.number)} ${s.t('rukus')}',
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        // Al-Fatihah includes the Basmala as ayah 1; At-Tawbah has none.
        if (info.number != 1 && info.number != 9) ...[
          const SizedBox(height: 10),
          Text(
            AppScope.of(context).settings.indoPakScript ? 'بِسۡمِ اللّٰهِ الرَّحۡمٰنِ الرَّحِيۡمِ' : 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
            style: quranStyle(context, indoPak: AppScope.of(context).settings.indoPakScript, size: 22, color: Colors.white),
          ),
        ],
      ]),
    );
  }
}

class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  /// In the mushaf tap sheet a translation is always shown.
  final bool forceTranslation;
  const _AyahCard({required this.ayah, this.forceTranslation = false});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final st = state.settings;
    final urdu = st.urdu;
    final repo = QuranRepository.instance;
    final theme = Theme.of(context);
    final bookmarked = state.isBookmarked(ayah.surah, ayah.number);
    final fav = state.isFavouriteAyah(ayah.surah, ayah.number);
    final isLast = state.lastRead?.surah == ayah.surah && state.lastRead?.ayah == ayah.number;
    final pageStart = repo.isPageStart(ayah.surah, ayah.number);
    final page = repo.pageOf(ayah.surah, ayah.number);
    final info = repo.surah(ayah.surah);
    final ruku = repo.rukuOf(ayah.surah, ayah.number);
    final juz = repo.juzOf(ayah.surah, ayah.number);
    final text = ayah.text(st.indoPakScript);
    final noTranslation = !st.showUrdu && !st.showEnglish;
    final showUr = st.showUrdu || (forceTranslation && noTranslation && urdu);
    final showEn = st.showEnglish || (forceTranslation && noTranslation && !urdu);

    // Info line under the ayah, like a printed mushaf index.
    final infoParts = urdu
        ? [
            'سورۃ ${info.arabicName}',
            'آیت نمبر ${ayah.number}',
            'پارہ $juz',
            if (ruku != null) 'پارہ رکوع ${ruku.$2}',
            if (ruku != null) 'سورۃ رکوع ${ruku.$1}',
          ]
        : [
            info.name,
            '${s.t('ayah')} ${ayah.number}',
            '${s.t('para')} $juz',
            if (ruku != null) 'Ruku ${ruku.$1}',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pageStart && ayah.number != 1) _PageDivider(page: page - 1),
        Card(
          key: Key('ayah_${ayah.surah}_${ayah.number}'),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: isLast ? AppColors.gold.withValues(alpha: 0.10) : null,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => state.setLastRead(ayah.surah, ayah.number),
            onLongPress: () => _actions(context, state, text),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text(
                    text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: quranStyle(context, indoPak: st.indoPakScript, size: st.arabicSize),
                  ),
                ),
                if (st.showTranslit)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Text(ayah.translit,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: AppColors.emeraldMid)),
                  ),
                if (showUr)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Text(ayah.ur, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: urduStyle(context)),
                  ),
                if (showEn)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(ayah.en, textDirection: TextDirection.ltr, style: theme.textTheme.bodyMedium),
                  ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
                  child: Row(children: [
                    _SmallIcon(
                      icon: bookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: AppColors.gold,
                      tooltip: s.t('bookmark'),
                      onTap: () => state.toggleBookmark(ayah.surah, ayah.number),
                    ),
                    _SmallIcon(
                      icon: fav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.redAccent,
                      tooltip: s.t('favourite'),
                      onTap: () => state.toggleFavouriteAyah(ayah.surah, ayah.number),
                    ),
                    _SmallIcon(
                      icon: Icons.copy,
                      color: theme.colorScheme.outline,
                      tooltip: s.t('copy'),
                      onTap: () => _copy(context, state, text),
                    ),
                    if (isLast) const Icon(Icons.push_pin, size: 14, color: AppColors.gold),
                    Expanded(
                      child: Text(
                        infoParts.join(urdu ? '   ' : '  •  '),
                        textDirection: urdu ? TextDirection.rtl : TextDirection.ltr,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: urdu
                            ? const TextStyle(fontFamily: urduFont, fontSize: 11, height: 1.9, color: Color(0xFFB4483C))
                            : const TextStyle(fontSize: 11, color: Color(0xFFB4483C)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
        if (ayah.number == info.ayahs && _isLastOfPage(repo, ayah)) _PageDivider(page: page),
      ],
    );
  }

  void _copy(BuildContext context, AppState state, String text) {
    final st = state.settings;
    final repo = QuranRepository.instance;
    final out = [
      text,
      if (st.showUrdu) ayah.ur,
      if (st.showEnglish) ayah.en,
      '(${repo.surah(ayah.surah).name} ${ayah.surah}:${ayah.number})',
    ].join('\n\n');
    Clipboard.setData(ClipboardData(text: out));
    toast(context, state.s.t('copied'));
  }

  void _actions(BuildContext context, AppState state, String text) {
    final s = state.s;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.push_pin_outlined),
            title: Text(s.t('set_last_read')),
            onTap: () {
              state.setLastRead(ayah.surah, ayah.number);
              Navigator.pop(c);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: Text(s.t('bookmark')),
            onTap: () {
              state.toggleBookmark(ayah.surah, ayah.number);
              Navigator.pop(c);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text(s.t('copy')),
            onTap: () {
              Navigator.pop(c);
              _copy(context, state, text);
            },
          ),
        ]),
      ),
    );
  }

  bool _isLastOfPage(QuranRepository repo, Ayah a) {
    // The surah's last ayah also ends a page if the next surah starts a new page.
    if (a.surah == 114) return true;
    return repo.isPageStart(a.surah + 1, 1);
  }
}

/// Divider shown after the last ayah of a mushaf page with a "mark read" toggle.
class _SmallIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _SmallIcon({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 19,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: color),
      onPressed: onTap,
    );
  }
}

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


/// Ayah text without a trailing ayah number that some scripts embed (the
/// mushaf view draws its own medallion).
/// Indo-Pak text ends with " <number><waqf/ruku sign>"; the number is removed
/// and the sign is kept.
String mushafText(String t) => t.replaceFirstMapped(
    RegExp(r'\s*[\u0660-\u0669\u06F0-\u06F9]+(\s*[\uFD00-\uFDFF]?)\s*$'), (m) => m.group(1)!.trim().isEmpty ? '' : ' ${m.group(1)!.trim()}');

/// True if the ayah text already carries the ruku sign (Indo-Pak script).
bool hasRukuSign(String t) => t.trimRight().endsWith('\uFD92');

/// Arabic-Indic digits for ayah numbers.
String arabicNumber(int n) => n.toString().split('').map((c) => '٠١٢٣٤٥٦٧٨٩'[int.parse(c)]).join();

/// One ruku as continuous mushaf text.
class _MushafBlock extends StatefulWidget {
  final List<Ayah> ayahs;
  const _MushafBlock({super.key, required this.ayahs});

  @override
  State<_MushafBlock> createState() => _MushafBlockState();
}

class _MushafBlockState extends State<_MushafBlock> {
  final List<TapGestureRecognizer> _taps = [];
  final _textKey = GlobalKey();
  final List<int> _starts = []; // text offset where each ayah starts

  /// The ayah being read at screen position [globalY], or null if this
  /// block is entirely above it.
  int? ayahAt(double globalY) {
    final rp = _textKey.currentContext?.findRenderObject();
    final box = context.findRenderObject() as RenderBox?;
    if (rp is! RenderParagraph || box == null || !box.attached || !rp.attached) return null;
    final blockBottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    if (blockBottom <= globalY) return null;
    var result = widget.ayahs.first.number;
    for (var i = 0; i < _starts.length && i < widget.ayahs.length; i++) {
      final caret = rp.getOffsetForCaret(TextPosition(offset: _starts[i]), Rect.zero);
      final y = rp.localToGlobal(caret).dy;
      if (y <= globalY) result = widget.ayahs[i].number;
    }
    return result;
  }

  void _clear() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _open(BuildContext context, AppState state, Ayah a) {
    state.setLastRead(a.surah, a.number);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (c, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.only(bottom: 24),
          child: _AyahCard(ayah: a, forceTranslation: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final st = state.settings;
    final urdu = st.urdu;
    final repo = QuranRepository.instance;
    final theme = Theme.of(context);
    final first = widget.ayahs.first;
    final ruku = repo.rukuOf(first.surah, first.number);
    final juz = repo.juzOf(first.surah, first.number);
    final base = quranStyle(context, indoPak: st.indoPakScript, size: st.arabicSize);
    final lastRead = state.lastRead;
    _clear();

    final spans = <InlineSpan>[];
    _starts.clear();
    var offset = 0;
    for (final a in widget.ayahs) {
      final tap = TapGestureRecognizer()..onTap = () => _open(context, state, a);
      _taps.add(tap);
      final isLast = lastRead?.surah == a.surah && lastRead?.ayah == a.number;
      final text = mushafText(a.text(st.indoPakScript));
      _starts.add(offset);
      offset += text.length + 2; // text + medallion + space
      if (repo.isRukuEnd(a.surah, a.number) && !hasRukuSign(a.text(st.indoPakScript))) offset += 1;
      spans.add(TextSpan(
        text: text,
        recognizer: tap,
        style: isLast ? TextStyle(backgroundColor: AppColors.gold.withValues(alpha: 0.22)) : null,
      ));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => _open(context, state, a),
          child: _AyahMarker(number: a.number, bookmarked: state.isBookmarked(a.surah, a.number)),
        ),
      ));
      if (repo.isRukuEnd(a.surah, a.number) && !hasRukuSign(a.text(st.indoPakScript))) {
        spans.add(const WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text('ع', style: TextStyle(fontFamily: arabicFont, fontSize: 16, color: AppColors.gold, fontWeight: FontWeight.w700)),
          ),
        ));
      }
      spans.add(const TextSpan(text: ' '));
    }

    final label = urdu
        ? 'رکوع ${ruku?.$1 ?? 1} • پارہ $juz • آیات ${first.number}–${widget.ayahs.last.number}'
        : 'Ruku ${ruku?.$1 ?? 1} • ${state.s.t('para')} $juz • ${state.s.t('ayat')} ${first.number}–${widget.ayahs.last.number}';
    return Card(
      key: Key('mushaf_${first.surah}_${first.number}'),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            label,
            textDirection: urdu ? TextDirection.rtl : TextDirection.ltr,
            textAlign: TextAlign.center,
            style: urdu
                ? const TextStyle(fontFamily: urduFont, fontSize: 11, height: 1.9, color: Color(0xFFB4483C))
                : theme.textTheme.labelSmall?.copyWith(color: const Color(0xFFB4483C)),
          ),
          const SizedBox(height: 6),
          Text.rich(
            key: _textKey,
            TextSpan(style: base, children: spans),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
          ),
        ]),
      ),
    );
  }
}

/// Ornamental ayah-end medallion with the ayah number.
class _AyahMarker extends StatelessWidget {
  final int number;
  final bool bookmarked;
  const _AyahMarker({required this.number, this.bookmarked = false});

  @override
  Widget build(BuildContext context) {
    final size = AppScope.of(context).settings.arabicSize.clamp(18, 40) * 0.95;
    return Container(
      key: Key('ayah_marker_$number'),
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bookmarked ? AppColors.gold.withValues(alpha: 0.25) : null,
        border: Border.all(color: AppColors.gold, width: 1.6),
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Text(arabicNumber(number),
              style: const TextStyle(fontFamily: arabicFont, fontSize: 13, color: AppColors.emeraldMid, fontWeight: FontWeight.w700, height: 1.1)),
        ),
      ),
    );
  }
}


/// Tracks a tilawat session opened from the routine ("Do this now").
class QuranSession {
  final QuranRef start;
  final int startPage;
  QuranRef? last;
  final Set<int> pages = {};
  QuranSession(this.start, this.startPage) {
    pages.add(startPage);
  }

  void record(int surah, int ayah, int page) {
    last = QuranRef(surah, ayah);
    pages.add(page);
  }

  int get lastPage => pages.isEmpty ? startPage : pages.reduce((a, b) => a > b ? a : b);

  /// Pages read: from the start page up to the page the reader stopped on
  /// (0 if the reader did not move).
  int get pagesRead {
    if (last == null || last == start) return 0;
    return (lastPage - startPage + 1).clamp(0, 604).toInt();
  }
}
