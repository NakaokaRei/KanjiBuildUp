"""Merge the two Inspi heading CSVs into a separately versioned default batch."""
import argparse
import csv
import json
import re
import uuid
from collections import Counter
from pathlib import Path


def circle_list_numbers(text):
    numbers = re.findall(r"[0-9]+", text)
    # Only a consecutive list (1, 2, ...) is enumeration; preserve ages, dates, etc.
    if len(numbers) >= 2 and numbers == [str(n) for n in range(1, len(numbers) + 1)]:
        assert len(numbers) <= 20
        return re.sub(r"[0-9]+", lambda match: chr(0x2460 + int(match[0]) - 1), text)
    return text


def read_rows(path, *, front):
    with path.open(encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        expected = ["番号", "問題", "（問題）", "答え"] + ([] if front else ["ページ数"])
        assert reader.fieldnames == expected, f"Unexpected columns: {path}"
        rows = {}
        for row in reader:
            assert None not in row and all(value is not None for value in row.values())
            number = int(row["番号"])
            assert number > 0 and number not in rows, f"Invalid or duplicate number: {number}"
            assert row["問題"].strip() and row["答え"].strip()
            rows[number] = row
    assert rows, f"Empty CSV: {path}"
    return rows


def convert(front_path, back_path):
    front = read_rows(front_path, front=True)
    back = read_rows(back_path, front=False)
    assert all(1 <= number <= 592 for number in front)
    numbers = sorted(front.keys() | back.keys())
    assert numbers == list(range(1, max(numbers) + 1)), "Missing problem numbers"
    items = []
    for number in numbers:
        row = front[number] if number in front else back[number]
        question = row["問題"].strip()
        context = row["（問題）"].strip()
        if context:
            question += f"（{context}）"
        items.append({
            "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"kanjibuildup/inspi/omidashi1/{number}")),
            "category": "大見出し①",
            "question": question,
            "answer": row["答え"].strip(),
            "meaning": "",
            "mastery": "starting" if number in front or number >= 593 else "mastered",
            "notes": f"インスピさん①{number}番",
        })
    previous_items = []
    for item in items:
        question = circle_list_numbers(item["question"])
        if question != item["question"]:
            previous_items.append(item.copy())
            item["question"] = question
    return {
        "version": "inspi-omidashi1-2026-10-09-v2",
        "replacesVersion": "inspi-omidashi1-2026-10-09-v1",
        "previousItems": previous_items,
        "items": items,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("front_csv", type=Path)
    parser.add_argument("back_csv", type=Path)
    parser.add_argument("--output", type=Path, default=Path("KanjiBuildUp/Resources/OmidashiStudyData.json"))
    args = parser.parse_args()
    data = convert(args.front_csv, args.back_csv)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'{len(data["items"])} items; {dict(Counter(i["mastery"] for i in data["items"]))}')
