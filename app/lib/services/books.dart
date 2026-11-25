import 'dart:convert';

import 'package:flutter/services.dart';

class BookChapter {
  final int n;
  final String title;
  final String body;
  const BookChapter(this.n, this.title, this.body);
  List<String> get paragraphs =>
      body.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
}

class Book {
  final String id, title, titleEn, parent, author;
  final List<BookChapter> chapters;
  const Book(this.id, this.title, this.titleEn, this.parent, this.author, this.chapters);

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        j['id'] as String,
        j['title'] as String,
        (j['titleEn'] ?? j['title']) as String,
        (j['parent'] ?? '') as String,
        (j['author'] ?? '') as String,
        [
          for (final c in j['chapters'] as List)
            BookChapter((c['n'] as num).toInt(), c['title'] as String, (c['body'] ?? '') as String),
        ],
      );

  BookChapter? chapter(int n) {
    for (final c in chapters) {
      if (c.n == n) return c;
    }
    return null;
  }
}

/// Books bundled under assets/books/ (index.json lists their ids).
class BookRepository {
  BookRepository._();
  static final instance = BookRepository._();

  List<Book>? _books;

  /// For tests: use these books instead of the bundled assets.
  static List<Book>? debugBooks;

  Future<List<Book>> books() async {
    if (debugBooks != null) return debugBooks!;
    if (_books != null) return _books!;
    final ids = (jsonDecode(await rootBundle.loadString('assets/books/index.json')) as List).cast<String>();
    final list = <Book>[];
    for (final id in ids) {
      list.add(Book.fromJson(jsonDecode(await rootBundle.loadString('assets/books/$id.json')) as Map<String, dynamic>));
    }
    return _books = list;
  }
}
