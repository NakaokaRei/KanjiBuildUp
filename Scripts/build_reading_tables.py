"""Import the 19 user-supplied reading PDFs, excluding same-category questions.

Requires pdfplumber. Keep answers and source locations, resolve the embedded
private-use glyphs against rendered originals, and reject unknown glyphs.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import unicodedata
import uuid

import pdfplumber
from build_sentence_data import extract_entries

FILES = [
 '一字訓読み_常用訓読み表（送り仮名なし・橙）.pdf',
 '一字訓読み_準１級訓読み表（送り仮名なし・橙）.pdf',
 '一字訓読み_１級訓読み表（天地人・橙）.pdf',
 '一字訓読み_１級訓読み表（未分類・橙）.pdf',
 '一字訓読み_１級訓読み表（無形・橙）.pdf',
 '一字訓読み_１級訓読み表（生物・橙）.pdf',
 '一字訓読み_１級訓読み表（衣食住・橙）.pdf',
 '一字訓読み_１級訓読み表（道具・橙）.pdf',
 '当て字_索引に無い熟字訓・当て字（１～２０・橙）.pdf',
 '訓熟語_表外訓を持つ常用熟語（１～７・橙）印刷済み.pdf',
 '訓熟語_訓熟語読み問題（１～６・橙）印刷済み.pdf',
 '訓読み_常用訓読み表（送り仮名あり・橙）.pdf',
 '訓読み_準１級訓読み表（送り仮名あり・橙）.pdf',
 '訓読み_１級訓読み表（送り仮名あり・橙）.pdf',
 '音読み_音読みテスト（１～３）／常用音読み（改）.pdf',
 '音読み_音読み問題（１～１８）（改）.pdf',
 '音読み_音読み対策問題（１１～１３）.pdf',
 '音読み_音読み対策問題（１～４）.pdf',
 '音読み_音読み対策問題（５～１０）.pdf',
]
COUNTS = [516,482,198,139,138,216,149,145,803,362,268,1048,390,1101,465,789,60,190,124]
# PUA encodings belong to these specific source PDFs, not Unicode in general.
PUA = dict(zip(
 [0xe087,0xe077,0xe043,0xe0a9,0xe082,0xe07e,0xe047,0xe05c,0xe083,0xe0a0,0xe0ad,0xe076,0xe08d,0xe0b1,0xe046,0xe057,0xe048,0xe081,0xe04f,0xe064,0xe069,0xe031,0xe080,0xe08c,0xe08e,0xe030,0xe0a6,0xe071,0xe05f,0xe072,0xe070,0xe074,0xe053,0xe051,0xe04a,0xe05a,0xe085,0xe06c,0xe032,0xe060,0xe0b0,0xe092,0xe084,0xe1fd,0xe1ea,0xe2b1,0xe24e,0xe1e9,0xe224,0xe1f4,0xe1e8,0xe23e,0xe1e7,0xe1f1,0xe249,0xe1f8,0xe24b,0xe254,0xe1f3,0xe1ed,0xe1ec,0xe260,0xe252,0xe213,0xe24f,0xe267,0xe210,0xe23f,0xe20f,0xe25f,0xe1fa,0xe248,0xe21d,0xe265],
 '塘鱈瀛萢潭嫂囮甄鐔堋旒筬靫綟淤瓊谺磔跫媾鮗𩶗梛鰌荵𬵪蟒蓴瓠蕈螽簪笄繦絣糱簟耜𫒼觚捩箙凋夐湮羸褊堙梳曁駛縢閼譁炳鞏黷抛豁哂贏舁駢簒翩陋覯韜遘諛釁濆邃捩',
 strict=True))


def clean(text):
    text = text.translate(PUA)
    assert '(cid:' not in text and not any(0xe000 <= ord(c) <= 0xf8ff for c in text), text
    return re.sub(r'\s+', '', text)


def format_answers(text):
    # A slash inside [じゃこ/ざこ] describes a partial-reading alternative.
    depth = 0
    result = []
    for c in text.replace('／','/'):
        if c == '[': depth += 1
        if c == ']': depth -= 1
        result.append('\n' if c == '/' and depth == 0 else c)
    assert depth == 0, text
    return ''.join(result)


def question_key(category, question):
    return category, re.sub(r'[\s【】]', '', unicodedata.normalize('NFC', question))


def by_position(chars, question_large_only=False):
    """Pair colored readings with cells even when the PDF stream is reordered."""
    checks = sorted((c for c in chars if c['text'] == '□'), key=lambda c:(round(c['top'],1),c['x0']))
    xs = sorted({round(c['x0'],1) for c in checks})
    groups = [[] for _ in checks]
    for c in chars:
        if c['text'] == '□' or not c['text'].strip():
            continue
        col = max(x for x in xs if x <= c['x0'] + 1)
        choices = [j for j,b in enumerate(checks) if abs(b['x0']-col)<1]
        if question_large_only and any(c['non_stroking_color']):
            # In these two pages orange alternatives begin below the question
            # baseline and may extend over several lines before the next row.
            preceding = [j for j in choices if checks[j]['top'] <= c['top'] + 5]
            assert preceding, c
            j = max(preceding, key=lambda j:checks[j]['top'])
        else:
            j = min(choices, key=lambda j:abs((c['top']+c['bottom'])/2 - (checks[j]['top']+checks[j]['bottom'])/2))
        groups[j].append(c)
    result = []
    for g in groups:
        g.sort(key=lambda c:(round(c['top']/3)*3,c['x0']))
        question = ''.join(c['text'] for c in g if not any(c['non_stroking_color']) and (not question_large_only or c['size']>=11))
        answer = ''.join(c['text'] for c in g if any(c['non_stroking_color']))
        result.append((question,answer))
    return result


def table_entries(page, source, page_number):
    chars=page.chars
    for j,c in enumerate(chars):
        if c['text']=='○':
            chars=chars[:j]
            break
    if (source,page_number) in [(0,2),(0,3),(11,6)]:
        return by_position(chars, question_large_only=(source,page_number) in [(0,3),(11,6)])
    groups=[]
    markers = ('□', '☆') if source in (9, 10) else ('□',)
    starts=[]
    for c in chars:
        if c['text'] in markers:
            groups.append([])
            starts.append(c['text'])
        elif groups:groups[-1].append(c)
    # Retain every existing square entry's ordinal/UUID. Append the previously
    # omitted star entries after the squares, rather than renumbering user data.
    groups = [g for marker in markers for start,g in zip(starts,groups) if start == marker]
    result=[]
    for g in groups:
        if source<14:
            first_answer = next(j for j,c in enumerate(g) if any(c['non_stroking_color']))
            q=''.join(c['text'] for c in g[:first_answer])
            a=''.join(c['text'] for c in g if any(c['non_stroking_color']))
        else:
            t=''.join(c['text'] for c in g)
            q,a=re.fullmatch(r'([^ぁ-ゖ]+)([ぁ-ゖ].*)',t).groups()
            # These cells contain context in smaller type before the reading.
            special={'浴沂の楽しみよくき':('浴沂','よくき'),
                     '粤犬雪に吠ゆえっけん':('粤犬','えっけん'),
                     '騅逝かずすい':('騅','すい'),
                     '年高徳邵とくしょう':('徳邵','とくしょう')}
            q,a=special.get(t,(q,a))
        result.append((q,a))
    return result


def extract(root):
    items=[]
    for source,filename in enumerate(FILES):
        file_items=[]
        with pdfplumber.open(root/filename) as pdf:
            if source==16:
                questions=[(pn,n,q) for pn,p in enumerate(pdf.pages[:3],1) for n,q in extract_entries(p,True)]
                answers=dict(extract_entries(pdf.pages[3],False))
                assert [n for _,n,_ in questions]==list(range(1,61)) and sorted(answers)==list(range(1,61))
                entries=[]
                for pn,n,q in questions:
                    targets=re.findall(r'【([^】]+)】',q)
                    assert len(targets)==1,(n,q)
                    entries.append((pn,n,targets[0],answers[n],q))
            else:
                entries=[(pn,n,q,a,'') for pn,p in enumerate(pdf.pages,1)
                         for n,(q,a) in enumerate(table_entries(p,source,pn),1)]
            assert len(entries)==COUNTS[source],(filename,len(entries))
            for pn,n,q,a,context in entries:
                q,a=clean(q),clean(a)
                if q == '扛秤':
                    # The original has an unmatched closing quote after the reading.
                    a = a.removesuffix('」')
                assert q and re.fullmatch(r'[ぁ-ゖァ-ヶー/／()（）\[\]・]+',a),(filename,pn,n,q,a)
                if source < 8:
                    assert len(q) == 1, (filename,pn,n,q)
                assert not a.startswith('/'), (filename,pn,n,a)
                assert all(a.count(left) == a.count(right) for left,right in [('(',')'),('[',']')]), (filename,pn,n,a)
                note=f'出典：{filename}\n{pn}ページ・{n}番'
                if context:note+='\n原文：'+context
                file_items.append(dict(id=str(uuid.uuid5(uuid.NAMESPACE_URL,f'kanjibuildup/reading-tables/{filename}/{pn}/{n}')),
                    category=filename.split('_')[0],question=q,answer=format_answers(a),
                    meaning='',notes=note,mastery='starting'))
        items.extend(file_items)
        print(filename,len(file_items))
    return items


def build(root,resource_dir):
    seen=set()
    for path in sorted(resource_dir.glob('*StudyData.json')):
        if path.stem=='ReadingTablesStudyData':continue
        for i in json.loads(path.read_text())['items']:
            seen.add(question_key(i['category'],i['question']))
    result=[]; duplicates=Counter();counts=Counter(); added={}
    for i in extract(root):
        key=question_key(i['category'],i['question'])
        if key in seen:
            duplicates[i['category']]+=1
            if key in added:
                previous=added[key]
                previous['answer']='\n'.join(dict.fromkeys(previous['answer'].splitlines()+i['answer'].splitlines()))
                previous['notes']+='\n'+i['notes']
            continue
        seen.add(key);result.append(i);added[key]=i;counts[i['category']]+=1
    print('Added:',dict(counts),'Skipped:',dict(duplicates))
    baseline = json.loads((Path(__file__).parent / 'fixtures/reading-tables-v1-corrections.json').read_text())
    ids = {item['id'] for item in result}
    assert all(item['id'] in ids for item in baseline['previousItems'])
    return dict(version='kurako-reading-tables-2026-10-15-v2',
                deduplicateByQuestion=True,items=result,
                replacesVersion='kurako-reading-tables-2026-10-13-v1',
                previousItems=baseline['previousItems'],
                replacementAdditionIDs=baseline['replacementAdditionIDs'])


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root',type=Path)
    parser.add_argument('--resource-dir',type=Path,default=Path('KanjiBuildUp/Resources'))
    args=parser.parse_args()
    data=build(args.root,args.resource_dir)
    (args.resource_dir/'ReadingTablesStudyData.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
