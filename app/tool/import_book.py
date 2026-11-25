"""Fill a book's chapter texts from a plain UTF-8 text file.

Usage: python3 tool/import_book.py assets/books/<id>.json chapters.txt

chapters.txt format: each chapter starts with a heading line "## <number>"
(optionally followed by the title); everything until the next heading is the
chapter body. Blank lines separate paragraphs. Only add text you have the
right to publish (author / publisher permission or public domain).
"""
import json, re, sys

book_path, txt_path = sys.argv[1], sys.argv[2]
book = json.load(open(book_path, encoding='utf-8'))
bodies, cur = {}, None
for line in open(txt_path, encoding='utf-8'):
    m = re.match(r'^##\s*(\d+)', line)
    if m:
        cur = int(m.group(1)); bodies[cur] = []
    elif cur is not None:
        bodies[cur].append(line.rstrip('\n'))
for ch in book['chapters']:
    if ch['n'] in bodies:
        ch['body'] = re.sub(r'\n{3,}', '\n\n', '\n'.join(bodies[ch['n']]).strip())
json.dump(book, open(book_path, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('filled', sum(1 for c in book['chapters'] if c['body']), 'of', len(book['chapters']), 'chapters')
