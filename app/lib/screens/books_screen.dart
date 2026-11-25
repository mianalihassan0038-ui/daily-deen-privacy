import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../services/books.dart';
import '../widgets/common.dart';

/// "کتب" — the library: every bundled book with its reading progress.
class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  late Future<List<Book>> _future = BookRepository.instance.books();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    return HeaderScaffold(
      title: s.t('books'),
      body: FutureBuilder<List<Book>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return RetryState(text: s.t('books_load_error'), onRetry: () => setState(() => _future = BookRepository.instance.books()));
          }
          final books = snap.data;
          if (books == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            key: const Key('books_list'),
            padding: const EdgeInsets.all(16),
            children: [for (final b in books) _BookCard(book: b)],
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final read = state.chaptersRead(book.id).length;
    final total = book.chapters.length;
    final started = state.hasBookProgress(book.id);
    final last = book.chapter(state.bookChapter(book.id));
    return Card(
      child: InkWell(
        key: Key('book_${book.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookChaptersScreen(book: book))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 58,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.emerald, AppColors.emeraldLight]),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold, width: 1.4),
              ),
              child: const Icon(Icons.auto_stories, color: AppColors.goldLight, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(urduText(book.title),
                    textDirection: TextDirection.rtl,
                    style: urduStyle(context, size: 19, weight: FontWeight.w700, color: AppColors.emerald)),
                Text('${s.t('book_author')}: ${book.author}',
                    textDirection: TextDirection.rtl, style: urduStyle(context, size: 13, color: AppColors.mutedInk)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : read / total,
                    minHeight: 6,
                    color: AppColors.gold,
                    backgroundColor: AppColors.creamDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  started && last != null
                      ? '${s.t('book_continue_reading')}: ${ltr('${last.n}')}. ${last.title}'
                      : '${ltr('$total')} ${s.t('book_chapters')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A book's topics (abwaab), numbered like the reference, with search and a
/// "continue reading" shortcut.
class BookChaptersScreen extends StatefulWidget {
  final Book book;
  const BookChaptersScreen({super.key, required this.book});

  @override
  State<BookChaptersScreen> createState() => _BookChaptersScreenState();
}

class _BookChaptersScreenState extends State<BookChaptersScreen> {
  String _q = '';

  void _open(int n) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => ChapterReaderScreen(book: widget.book, chapter: n)));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final book = widget.book;
    final read = state.chaptersRead(book.id);
    final q = _q.trim();
    final list = q.isEmpty
        ? book.chapters
        : book.chapters.where((c) => c.title.contains(q) || '${c.n}' == q).toList();
    final wide = MediaQuery.sizeOf(context).width >= 640;
    final last = state.hasBookProgress(book.id) ? book.chapter(state.bookChapter(book.id)) : null;

    Widget tile(BookChapter c) {
      final done = read.contains(c.n);
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: InkWell(
          key: Key('chapter_${c.n}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(c.n),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(textDirection: TextDirection.rtl, children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? AppColors.emerald : AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text('${c.n}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.emeraldMid)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(urduText(c.title),
                    textDirection: TextDirection.rtl, style: urduStyle(context, size: 16, color: AppColors.ink)),
              ),
            ]),
          ),
        ),
      );
    }

    return HeaderScaffold(
      title: s.t('books'),
      body: CustomScrollView(key: const Key('chapters_list'), slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          sliver: SliverList.list(children: [
            Text(urduText(book.title),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: urduStyle(context, size: 26, weight: FontWeight.w700, color: AppColors.emeraldMid)),
            Text(
              [if (book.parent.isNotEmpty) '${s.t('book_parent')}: ${urduText(book.parent)}', '${s.t('book_author')}: ${book.author}']
                  .join(' ، '),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: urduStyle(context, size: 13, color: AppColors.mutedInk),
            ),
            const SizedBox(height: 10),
            if (last != null)
              FilledButton.icon(
                key: const Key('book_continue'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () => _open(last.n),
                icon: const Icon(Icons.play_arrow),
                label: Text('${s.t('book_continue_reading')} • ${ltr('${last.n}')}', maxLines: 1),
              ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('chapter_search'),
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '${s.t('book_search')} (${ltr('${book.chapters.length}')})',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
          ]),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          sliver: wide
              ? SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisExtent: textScaled(context, 92)),
                  delegate: SliverChildBuilderDelegate((_, i) => tile(list[i]), childCount: list.length),
                )
              : SliverList.builder(itemCount: list.length, itemBuilder: (_, i) => tile(list[i])),
        ),
      ]),
    );
  }
}

/// Reads one topic; the scroll position is saved continuously, so the book
/// reopens exactly where reading stopped.
class ChapterReaderScreen extends StatefulWidget {
  final Book book;
  final int chapter;
  const ChapterReaderScreen({super.key, required this.book, required this.chapter});

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  late int _n = widget.chapter;
  ScrollController? _ctrl;
  AppState? _state;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state ??= AppScope.read(context);
    if (_ctrl == null) _attach();
  }

  void _attach() {
    final st = _state!;
    _finished = st.chaptersRead(widget.book.id).contains(_n);
    _ctrl?.dispose();
    _ctrl = ScrollController(initialScrollOffset: st.chapterOffset(widget.book.id, _n));
    // Opening a chapter makes it the book's "continue reading" chapter.
    WidgetsBinding.instance.addPostFrameCallback((_) => _save());
  }

  void _save() {
    final c = _ctrl;
    if (!mounted || c == null || !c.hasClients) return;
    final atEnd = c.position.maxScrollExtent - c.offset < 80;
    if (atEnd && !_finished && _hasText) _finished = true;
    _state!.saveBookPosition(widget.book.id, _n, c.offset, finished: _finished && _hasText);
  }

  bool get _hasText => widget.book.chapter(_n)?.body.trim().isNotEmpty ?? false;

  void _go(int n) {
    _save();
    setState(() {
      _n = n;
      _ctrl?.dispose();
      _ctrl = null;
      _attach();
    });
  }

  @override
  void dispose() {
    final c = _ctrl;
    if (c != null && c.hasClients) {
      final atEnd = c.position.maxScrollExtent - c.offset < 80;
      _state?.saveBookPosition(widget.book.id, _n, c.offset, finished: (_finished || atEnd) && _hasText);
    }
    c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final book = widget.book;
    final ch = book.chapter(_n)!;
    final idx = book.chapters.indexOf(ch);
    final prev = idx > 0 ? book.chapters[idx - 1] : null;
    final next = idx < book.chapters.length - 1 ? book.chapters[idx + 1] : null;
    final size = (state.settings.arabicSize - 8).clamp(15, 26).toDouble();
    final paras = ch.paragraphs;

    return HeaderScaffold(
      title: urduText(book.title),
      body: NotificationListener<ScrollEndNotification>(
        onNotification: (_) {
          _save();
          return false;
        },
        child: ListView(
          key: Key('book_reader_${ch.n}'),
          controller: _ctrl,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            Row(textDirection: TextDirection.rtl, children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.emerald, borderRadius: BorderRadius.circular(10)),
                child: Text('${ch.n}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(urduText(ch.title),
                    textDirection: TextDirection.rtl,
                    style: urduStyle(context, size: 20, weight: FontWeight.w700, color: AppColors.emerald)),
              ),
            ]),
            const Divider(height: 28),
            if (paras.isEmpty)
              Container(
                key: const Key('chapter_no_text'),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(s.t('chapter_text_soon'),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: urduStyle(context, size: 15, color: AppColors.mutedInk)),
              )
            else
              for (final p in paras)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(urduText(p),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: urduStyle(context, size: size, color: AppColors.ink)),
                ),
            const SizedBox(height: 18),
            Row(textDirection: TextDirection.rtl, children: [
              if (prev != null)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('chapter_prev'),
                    onPressed: () => _go(prev.n),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(s.t('previous_chapter'), maxLines: 1),
                  ),
                ),
              if (prev != null && next != null) const SizedBox(width: 10),
              if (next != null)
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('chapter_next'),
                    onPressed: () => _go(next.n),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(s.t('next_chapter'), maxLines: 1),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}
