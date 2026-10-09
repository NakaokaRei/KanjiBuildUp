"""Merge Inspi heading set 2, recovering missing front-sheet numbers by content."""
import argparse
import csv
import json
import unicodedata
import uuid
from collections import Counter, defaultdict
from pathlib import Path

from build_omidashi_data import circle_list_numbers


def read_rows(path, *, front):
    with path.open(encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        expected = ["", "番号", "問題", "（問題）", "答え"] + ([] if front else ["ページ数"])
        assert reader.fieldnames == expected, f"Unexpected columns: {path}"
        rows = []
        for row in reader:
            assert None not in row and all(value is not None for value in row.values())
            if not any(value.strip() for value in row.values()):
                continue
            assert not row[""].strip()
            assert row["問題"].strip() and row["答え"].strip()
            rows.append(row)
    assert rows, f"Empty CSV: {path}"
    return rows


def content_key(row):
    return tuple(unicodedata.normalize("NFC", row[key].strip()) for key in ("問題", "（問題）", "答え"))


def convert(front_path, back_path):
    back = {}
    by_content = defaultdict(list)
    for row in read_rows(back_path, front=False):
        number = int(row["番号"])
        assert number > 0 and number not in back
        back[number] = row
        by_content[content_key(row)].append(number)
    assert sorted(back) == list(range(1, max(back) + 1)), "Missing back-sheet numbers"
    front = {}
    recovered = []
    for row in read_rows(front_path, front=True):
        if row["番号"].strip():
            number = int(row["番号"])
        else:
            matches = by_content[content_key(row)]
            assert len(matches) == 1, f"Cannot uniquely recover number: {row} ({matches})"
            number = matches[0]
            recovered.append(number)
        assert 1 <= number <= 1120 and number not in front
        assert content_key(row) == content_key(back[number]), f"Mismatched number: {number}"
        front[number] = row
    items = []
    for number in sorted(back):
        row = front.get(number, back[number])
        question = row["問題"].strip()
        if context := row["（問題）"].strip():
            question += f"（{context}）"
        items.append({
            "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"kanjibuildup/inspi/omidashi2/{number}")),
            "category": "大見出し②",
            "question": circle_list_numbers(question),
            "answer": row["答え"].strip(),
            "meaning": "",
            "mastery": "starting" if number in front or number >= 1121 else "learning",
            "notes": f"インスピさん②{number}番",
        })
    print(f"Recovered {len(recovered)} numbers: {recovered}")
    return {"version": "inspi-omidashi2-2026-10-09-v1", "items": items}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("front_csv", type=Path)
    parser.add_argument("back_csv", type=Path)
    parser.add_argument("--output", type=Path, default=Path("KanjiBuildUp/Resources/Omidashi2StudyData.json"))
    args = parser.parse_args()
    data = convert(args.front_csv, args.back_csv)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'{len(data["items"])} items; {dict(Counter(i["mastery"] for i in data["items"]))}')
