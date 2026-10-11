"""Extract all 351 questions and the two answer pages from 詩経訓読み問題（１～７）.pdf.

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


from build_rongo_data import extract_entries


def convert(path):
    with pdfplumber.open(path) as pdf:
        assert len(pdf.pages) == 11
        questions = [entry for page in pdf.pages[:-2] for entry in extract_entries(page, questions=True)]
        answers = [entry for page in pdf.pages[-2:] for entry in extract_entries(page, questions=False)]
    assert [n for n, _ in questions] == list(range(1, 352))
    assert [n for n, _ in answers] == list(range(1, 352))
    items = []
    for (number, question), (_, answer) in zip(questions, answers):
        assert question.count("【") == question.count("】") == 1, (number, question)
        assert answer and all(re.fullmatch(r"[ぁ-ゖ]+", a) for a in answer.split("／")), (number, answer)
        items.append({
            "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"kanjibuildup/kurako/shikyo-kunyomi/{number}")),
            "category": "詩経訓読み",
            "question": question,
            "answer": answer.replace("／", "\n"),
            "meaning": "",
            "notes": f"倉庫さん 詩経訓読み問題 {number}番",
            "mastery": "starting",
        })
    assert len({item["id"] for item in items}) == 351
    return {"version": "kurako-shikyo-kunyomi-2026-10-11-v1", "items": items}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--output", type=Path, default=Path("KanjiBuildUp/Resources/ShikyoKunyomiStudyData.json"))
    args = parser.parse_args()
    data = convert(args.pdf)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'{len(data["items"])} items; all starting')
