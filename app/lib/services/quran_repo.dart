import 'dart:convert';

import 'package:flutter/services.dart';

/// Surah metadata from assets/quran/index.json.
class SurahInfo {
  final int number;
  final String arabicName;
  final String name; // transliterated, e.g. Al-Fatihah
  final String meaningEn;
  final String meaningUr;
  final bool meccan;
  final int ayahs;
  const SurahInfo(this.number, this.arabicName, this.name, this.meaningEn, this.meaningUr, this.meccan, this.ayahs);
}

class Ayah {
  final int surah;
  final int number;
  final String arabic;
  final String en;
  final String ur;
  final String translit;
  const Ayah(this.surah, this.number, this.arabic, this.en, this.ur, this.translit);
}

/// Offline Quran text: Uthmani Arabic (QuranEnc), Saheeh International (English),
/// Abul A'la Maududi (Urdu) and Tanzil transliteration.
class QuranRepository {
  QuranRepository._();
  static final QuranRepository instance = QuranRepository._();

  List<SurahInfo> _surahs = const [];
  List<List<int>> _juzStarts = const [];
  List<List<int>> _pageStarts = const [];
  final Map<int, List<Ayah>> _cache = {};
  Future<void>? _loading;

  bool get isLoaded => _surahs.isNotEmpty;
  List<SurahInfo> get surahs => _surahs;
  List<List<int>> get juzStarts => _juzStarts;
  List<List<int>> get pageStarts => _pageStarts;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    final raw = await _loadText('assets/quran/index.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    _surahs = (j['surahs'] as List).map((e) {
      final m = e as Map<String, dynamic>;
      return SurahInfo(
        (m['n'] as num).toInt(),
        m['ar'] as String,
        m['tr'] as String,
        m['en'] as String,
        m['ur'] as String,
        m['type'] == 'k',
        (m['ayahs'] as num).toInt(),
      );
    }).toList();
    List<List<int>> pairs(dynamic l) =>
        (l as List).map((e) => (e as List).map((x) => (x as num).toInt()).toList()).toList();
    _juzStarts = pairs(j['juz']);
    _pageStarts = pairs(j['pages']);
  }

  /// Loads and decodes UTF-8 text directly (AssetBundle.loadString would use
  /// an isolate for large files, which is unnecessary for our small JSON).
  static Future<String> _loadText(String key) async {
    final data = await rootBundle.load(key);
    return utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  SurahInfo surah(int n) => _surahs[n - 1];

  Future<List<Ayah>> ayahs(int surah) async {
    final cached = _cache[surah];
    if (cached != null) return cached;
    final raw = await _loadText('assets/quran/$surah.json');
    final list = jsonDecode(raw) as List;
    final out = <Ayah>[];
    for (var i = 0; i < list.length; i++) {
      final v = list[i] as List;
      out.add(Ayah(surah, i + 1, v[0] as String, v[1] as String, v[2] as String, v[3] as String));
    }
    _cache[surah] = out;
    return out;
  }

  static int _cmp(int s1, int a1, int s2, int a2) => s1 != s2 ? s1.compareTo(s2) : a1.compareTo(a2);

  static int _indexOf(List<List<int>> starts, int s, int a) {
    var lo = 0, hi = starts.length - 1, ans = 0;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      if (_cmp(starts[mid][0], starts[mid][1], s, a) <= 0) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }

  /// Mushaf page (1..604) containing ayah [s]:[a].
  int pageOf(int s, int a) => _pageStarts.isEmpty ? 1 : _indexOf(_pageStarts, s, a) + 1;

  /// Juz / Para (1..30) containing ayah [s]:[a].
  int juzOf(int s, int a) => _juzStarts.isEmpty ? 1 : _indexOf(_juzStarts, s, a) + 1;

  /// True if [s]:[a] is the first ayah on its page.
  bool isPageStart(int s, int a) {
    if (_pageStarts.isEmpty) return false;
    final p = _pageStarts[_indexOf(_pageStarts, s, a)];
    return p[0] == s && p[1] == a;
  }

  /// Searches surah names / numbers and "s:a" references.
  List<SurahInfo> searchSurahs(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return _surahs;
    final n = int.tryParse(query);
    return _surahs.where((s) {
      if (n != null) return s.number == n;
      return s.name.toLowerCase().contains(query) ||
          s.meaningEn.toLowerCase().contains(query) ||
          s.arabicName.contains(q.trim()) ||
          s.meaningUr.contains(q.trim());
    }).toList();
  }

  /// Full-text search in translations, transliteration and Arabic (max [limit] results).
  Future<List<Ayah>> searchText(String q, {int limit = 100}) async {
    final query = q.trim().toLowerCase();
    if (query.length < 3) return const [];
    final out = <Ayah>[];
    for (var s = 1; s <= 114 && out.length < limit; s++) {
      for (final a in await ayahs(s)) {
        if (a.en.toLowerCase().contains(query) ||
            a.translit.toLowerCase().contains(query) ||
            a.ur.contains(q.trim()) ||
            a.arabic.contains(q.trim())) {
          out.add(a);
          if (out.length >= limit) break;
        }
      }
    }
    return out;
  }
}
