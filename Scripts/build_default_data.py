"""Build bundled defaults from the two user-supplied CSVs; source files are not modified."""
import argparse
import csv
import json
import uuid
from collections import Counter
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('kunyomi', type=Path)
parser.add_argument('ateji', type=Path)
parser.add_argument('--output', type=Path, default=Path('KanjiBuildUp/Resources/DefaultStudyData.json'))
args = parser.parse_args()

def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as source:
        return list(csv.reader(source))

# Stable identifiers let installation be safely retried without replacing learned state.
def record(category, number, question, answer, meaning, mastery):
    assert question.strip() and answer.strip()
    return {'id': str(uuid.uuid5(uuid.NAMESPACE_URL, f'kanjibuildup/teihitsu/{category}/{number}')),
            'category': category, 'question': question.strip(), 'answer': answer.strip(),
            'meaning': meaning.strip(), 'mastery': mastery, 'notes': f'逞筆さん{number}番'}

kun = rows(args.kunyomi)
assert kun[0][:2] == ['がんばるぞ', 'あと少し']
assert kun[1][2:6] == ['【番】', '【問題】', '【重要度】', '【解答】']
selected = [r for r in kun[2:] if r[2].isdigit() and 411 <= int(r[2]) <= 1200]
assert [int(r[2]) for r in selected] == list(range(411, 1201))
items = []
for r in selected:
    assert r[0] in ('', '☆') and r[1] in ('', '☆') and not (r[0] and r[1])
    mastery = 'starting' if r[0] else 'learning' if r[1] else 'mastered'
    items.append(record('訓読み', r[2], r[3], r[5], r[6], mastery))
ate = rows(args.ateji)
assert ate[0] == ['【番】', '【問題】', '【難度】', '【解答】', '【別答】', '【 意 味 】']
for r in ate[1:]:
    assert len(r) == 6 and r[0].isdigit()
    answer = r[3].strip()
    if r[4].strip():
        answer += '\n' + r[4].strip()
    items.append(record('当て字', r[0], r[1], answer, r[5], 'starting'))
assert len(items) == 2974 and len({r['id'] for r in items}) == len(items)
assert Counter(r['mastery'] for r in items) == {'starting': 2308, 'learning': 130, 'mastered': 536}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps({'version': 'teihitsu-2026-10-04-v1', 'items': items}, ensure_ascii=False, indent=2)+'\n')
print(f'{len(items)} items; {dict(Counter(r["mastery"] for r in items))}; {sum(bool(r[4]) for r in ate[1:])} alternate answers')
