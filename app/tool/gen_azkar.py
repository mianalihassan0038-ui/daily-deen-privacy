#!/usr/bin/env python3
"""Fills {{ar|en|ur|tr:S:A[-B]}} / {{..:S}} tokens in azkar_template.dart.txt
with exact text from assets/quran and writes lib/data/azkar.dart."""
import json, pathlib, re
root = pathlib.Path(__file__).resolve().parent.parent
q = root / 'assets' / 'quran'
cache = {}
def surah(n):
    if n not in cache:
        cache[n] = json.loads((q / f'{n}.json').read_text())
    return cache[n]
FIELD = {'ar': 0, 'en': 1, 'ur': 2, 'tr': 3}
ARABIC_DIGITS = '٠١٢٣٤٥٦٧٨٩'
def ar_num(n):
    return ''.join(ARABIC_DIGITS[int(c)] for c in str(n))
def esc(s):
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
def repl(m):
    field, ref = m.group(1), m.group(2)
    parts = ref.split(':')
    s = int(parts[0]); verses = surah(s)
    if len(parts) == 1:
        a, b = 1, len(verses)
    else:
        rng = parts[1].split('-'); a = int(rng[0]); b = int(rng[-1])
    out = []
    for i in range(a, b + 1):
        t = verses[i - 1][FIELD[field]]
        if b > a:
            t = f'{t} ﴿{ar_num(i)}﴾' if field == 'ar' else f'({i}) {t}'
        out.append(t)
    return esc(' '.join(out))
src = (root / 'tool' / 'azkar_template.dart.txt').read_text()
out = re.sub(r'\{\{(ar|en|ur|tr):([0-9:\-]+)\}\}', repl, src)
assert '{{' not in out
(root / 'lib' / 'data' / 'azkar.dart').write_text(out)
print('azkar.dart generated')
