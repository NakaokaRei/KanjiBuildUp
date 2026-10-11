"""Extract all 135 questions and the final answer page from 論語訓読み問題（１～３）.pdf.

Requires pdfplumber. The PDF's content stream follows vertical reading order;
ordinary line-based extraction interleaves wrapped columns. Large (15.96 pt)
characters mark the single kanji whose reading is requested.
"""
import argparse
import json
import re
import uuid
from pathlib import Path

import pdfplumber


GLYPHS = {
    "(cid:18637)": "、",
    "(cid:18638)": "。",
    "(cid:18809)": "（",
    "(cid:18810)": "）",
    "(cid:18668)": "っ",
}


def extract_entries(page, *, questions):
    text = ""
    for char in page.chars:
        # The title precedes the first number; regex below ignores it.
        if char["text"].isspace():
            continue
        value = GLYPHS.get(char["text"], char["text"])
        assert "(cid:" not in value, value
        if questions and abs(char["size"] - 15.96) < 0.05:
            value = f"【{value}】"
        text += value
    return [(int(number), body) for number, body in re.findall(r"([0-9]+)([^0-9]+)", text)]


def convert(path):
    with pdfplumber.open(path) as pdf:
        assert len(pdf.pages) == 5
        questions = [entry for page in pdf.pages[:-1] for entry in extract_entries(page, questions=True)]
        answers = extract_entries(pdf.pages[-1], questions=False)
    assert [n for n, _ in questions] == list(range(1, 136))
    assert [n for n, _ in answers] == list(range(1, 136))
    items = []
    for (number, question), (_, answer) in zip(questions, answers):
        assert question.count("【") == question.count("】") == 1, (number, question)
        assert answer and all(re.fullmatch(r"[ぁ-ゖ]+", a) for a in answer.split("／")), (number, answer)
        items.append({
            "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"kanjibuildup/kurako/rongo-kunyomi/{number}")),
            "category": "論語訓読み",
            "question": question,
            "answer": answer.replace("／", "\n"),
            "meaning": "",
            "notes": f"倉庫さん 論語訓読み問題 {number}番",
            "mastery": "starting",
        })
    assert len({item["id"] for item in items}) == 135
    return {"version": "kurako-rongo-kunyomi-2026-10-11-v1", "items": items}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--output", type=Path, default=Path("KanjiBuildUp/Resources/RongoKunyomiStudyData.json"))
    args = parser.parse_args()
    data = convert(args.pdf)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'{len(data["items"])} items; all starting')
