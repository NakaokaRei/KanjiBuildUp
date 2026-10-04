"""Convert the user's onyomi CSV into a separately versioned default batch."""
import argparse
import csv
import json
import uuid
from collections import Counter
from pathlib import Path


def convert(path):
    with path.open(encoding="utf-8-sig", newline="") as source:
        rows = list(csv.reader(source))
    assert rows[0][:2] == ["がんばるぞ", "あと少し"]
    assert rows[1][2:8] == ["【番】", "【問題】", "【難度】", "【解答】", "【別答】", "【 意 味 】"]
    items = []
    selected = [r for r in rows[2:] if r[2].isdigit() and 1 <= int(r[2]) <= 1030]
    for row in selected:
        assert len(row) == 9 and row[2].isdigit() and row[0] in ("", "☆")
        assert row[1] in ("", "☆") and not (row[0] and row[1])
        number = int(row[2])
        assert number > 0 and all(row[i].strip() for i in (3, 5))
        mastery = "starting" if row[0] == "☆" else "learning" if row[1] == "☆" else "mastered"
        answers = [row[5].strip()]
        if row[6].strip():
            answers.append(row[6].strip())
        items.append({
            "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"kanjibuildup/teihitsu/onyomi/{number}")),
            "category": "音読み",
            "question": row[3].strip(),
            "answer": "\n".join(answers),
            "meaning": row[7].strip(),
            "mastery": mastery,
            "notes": f"逞筆さん{number}番",
        })
    assert [int(r[2]) for r in selected] == list(range(1, 1031))
    assert len({item["id"] for item in items}) == len(items)
    return {"version": "teihitsu-onyomi-2026-10-04-v1", "items": items}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path)
    parser.add_argument("--output", type=Path, default=Path("KanjiBuildUp/Resources/OnyomiStudyData.json"))
    args = parser.parse_args()
    data = convert(args.csv)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'{len(data["items"])} items; {dict(Counter(i["mastery"] for i in data["items"]))}')
