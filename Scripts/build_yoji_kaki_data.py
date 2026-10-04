"""Convert the user's yoji-kaki CSV into a separately versioned default batch."""
import argparse
import csv
import json
import uuid
from collections import Counter
from pathlib import Path


def convert(path):
    with path.open(encoding="utf-8-sig", newline="") as source:
        rows = list(csv.reader(source))
    assert rows[0][0] == "がんばるぞ"
    assert rows[1][1:9] == ["【番】", "【問題】", "【読み】", "【重要度】", "【解答】", "【別答】", "【出典】", "【 意 味 】"]
    items = []
    for row in rows[2:]:
        assert len(row) == 10 and row[1].isdigit() and row[0] in ("", "☆")
        number = int(row[1])
        assert number > 0 and all(row[i].strip() for i in (2, 3, 5))
        mastery = "starting" if row[0] == "☆" else "mastered" if number <= 1059 else "learning"
        answers = [row[5].strip()]
        if row[6].strip():
            answers.append(row[6].strip())
        notes = [f"逞筆さん{number}番"]
        if row[7].strip():
            notes.append("出典：" + row[7].strip())
        items.append({
            "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"kanjibuildup/teihitsu/yoji-kaki/{number}")),
            "category": "四字熟語",
            "question": row[2].strip() + "\n（" + row[3].strip() + "）",
            "answer": "\n".join(answers),
            "meaning": row[8].strip(),
            "mastery": mastery,
            "notes": "\n".join(notes),
        })
    assert [int(r[1]) for r in rows[2:]] == list(range(1, len(items) + 1))
    assert len({item["id"] for item in items}) == len(items)
    return {"version": "teihitsu-yoji-kaki-2026-10-04-v1", "items": items}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path)
    parser.add_argument("--output", type=Path, default=Path("KanjiBuildUp/Resources/YojiKakiStudyData.json"))
    args = parser.parse_args()
    data = convert(args.csv)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'{len(data["items"])} items; {dict(Counter(i["mastery"] for i in data["items"]))}')
