"""Import six 倉庫さん PDFs into the three requested study categories.

Requires pdfplumber. Read vertical PDF content order, not horizontal text lines.
The reading targets use 14.04 pt type. CID substitutions were checked against
rendered pages; unknown glyphs abort the import rather than silently losing text.
Usage: python3 Scripts/build_sentence_data.py <倉庫さん directory>
"""
import argparse
from collections import defaultdict
import json
from pathlib import Path
import re
import uuid

import pdfplumber

# These PDFs use subset-font CIDs, not the standard Adobe-Japan1 CID mapping.
GLYPHS = {
    7925: "っ", 7935: "ッ", 7936: "ャ", 7937: "ュ", 7938: "ョ",
    18637: "、", 18638: "。", 18643: "「", 18644: "」",
    18668: "っ", 18669: "ゃ", 18670: "ゅ", 18671: "ょ",
    18676: "ァ", 18677: "ィ", 18681: "ッ", 18684: "ョ", 18688: "ー",
    18809: "（", 18810: "）", 18821: "～",
}
# source id, file, question pages, total pages, question count, category, output
SOURCES = [
    ("tajigo", "１級多字語書き取り問題（１～１０）.pdf", 4, 6, 250, "多字語書き取り", "TajigoStudyData"),
    ("joyo-niban-long", "訓読み/文章題訓読み問題　常用二版読み対策.pdf", 12, 13, 236, "文章題訓読み二版", "SentenceNibanStudyData"),
    ("joyo-niban-1-20", "訓読み/文章題訓読み問題　常用二版読み対策（１～２０）.pdf", 7, 8, 200, "文章題訓読み二版", "SentenceNibanStudyData"),
    ("jun1-niban", "訓読み/文章題訓読み問題　準１級二版読み対策（１～１０）.pdf", 7, 8, 100, "文章題訓読み二版", "SentenceNibanStudyData"),
    ("joyo-sentence", "訓読み/文章題訓読み問題　常用対策（１～７）.pdf", 6, 7, 140, "文章題訓読み", "SentenceKunyomiStudyData"),
    ("sentence-1-5", "訓読み/文章題訓読み問題（１～５）.pdf", 5, 6, 100, "文章題訓読み", "SentenceKunyomiStudyData"),
]


def extract_entries(page, mark_targets):
    parts = []
    for char in page.chars:
        value = char["text"]
        cid = re.fullmatch(r"\(cid:(\d+)\)", value)
        if cid:
            value = GLYPHS[int(cid[1])]
        if mark_targets and abs(char["size"] - 14.04) < 0.02 and not value.isspace():
            value = f"【{value}】"
        parts.append(value)
    text = "".join(parts)
    # Preserve spaces within Western author names; Japanese PDF layout spaces go.
    text = re.sub(r"(?<=[A-Za-z])\s+(?=[A-Za-z])", "\x00", text)
    text = re.sub(r"\s+", "", text).replace("\x00", " ").replace("】【", "")
    text = re.sub(r"(?:◇(?:問題|解答))?【?その[０-９]+】?(?:（続き）)?", "", text)
    return [(int(n), body) for n, body in re.findall(r"([0-9]+)([^0-9]+)", text)]


def convert(root):
    outputs = defaultdict(list)
    for source, filename, question_pages, page_count, count, category, output in SOURCES:
        with pdfplumber.open(root / filename) as pdf:
            assert len(pdf.pages) == page_count, filename
            questions = [entry for page in pdf.pages[:question_pages]
                         for entry in extract_entries(page, source != "tajigo")]
            answer_entries = [entry for page in pdf.pages[question_pages:]
                              for entry in extract_entries(page, False)]
        assert [n for n, _ in questions] == list(range(1, count + 1)), filename
        answers = defaultdict(list)
        for n, answer in answer_entries:
            answers[n].append(answer)
        assert sorted(answers) == list(range(1, count + 1)), filename
        for n, question in questions:
            answer_parts = answers[n]
            labels = re.findall(r"[ⒶⒷⒸ]", question)
            if labels:
                assert labels == [a[0] for a in answer_parts], (filename, n)
                assert question.count("【") == len(labels), (filename, n)
            else:
                assert len(answer_parts) == 1, (filename, n)
                if source != "tajigo":
                    assert question.count("【") == 1, (filename, n)
            assert question.count("【") == question.count("】"), (filename, n)
            if source != "tajigo":
                assert all(re.fullmatch(r"[ⒶⒷⒸ]?[ぁ-ゖ]+(?:／\[?[ぁ-ゖ]+\]?)*", a)
                           for a in answer_parts), (filename, n, answer_parts)
            # Keep brackets around annotated alternatives, with each reading on a line.
            answer = "\n".join(answer_parts).replace("／", "\n")
            notes = f"倉庫さん {Path(filename).stem} {n}番"
            citation = re.search(r"（[^（）]*より）$", question)
            if citation:
                notes += "\n出典：" + citation[0][1:-1]
                question = question[:citation.start()]
            assert question and answer and "(cid:" not in question + answer
            outputs[output].append({
                "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"kanjibuildup/kurako/{source}/{n}")),
                "category": category, "question": question, "answer": answer,
                "meaning": "", "notes": notes, "mastery": "starting",
            })
        print(f"{filename}: {count} questions")
    for name, items in outputs.items():
        assert len({i['id'] for i in items}) == len(items)
        assert len({(i['question'], i['answer']) for i in items}) == len(items)
    return outputs


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    parser.add_argument("--output-dir", type=Path, default=Path("KanjiBuildUp/Resources"))
    args = parser.parse_args()
    for name, items in convert(args.root).items():
        data = {"version": f"kurako-{name}-2026-10-12-v1", "items": items}
        if name == "TajigoStudyData":
            # Keep the original questions for the existing non-destructive migration.
            data["previousItems"] = items
            data["replacesVersion"] = data["version"]
            data["version"] = f"kurako-{name}-2026-10-12-v2"
            marked = []
            for item in items:
                question, targets = re.subn(r"[ァ-ヶー]+", r"【\g<0>】", item["question"])
                assert targets == 1, item["question"]
                marked.append({**item, "question": question})
            data["items"] = marked
        args.output_dir.mkdir(parents=True, exist_ok=True)
        (args.output_dir / f"{name}.json").write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{name}: {len(items)} items; all starting")
