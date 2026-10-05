"""Convert the user's onyomi CSV into a separately versioned default batch."""
import argparse
import csv
import json
import uuid
from collections import Counter
from pathlib import Path


def convert(path, continuation=False):
    with path.open(encoding="utf-8-sig", newline="") as source:
        rows = list(csv.reader(source))
    assert rows[0][:2] == ["がんばるぞ", "あと少し"]
    assert rows[1][2:8] == ["【番】", "【問題】", "【難度】", "【解答】", "【別答】", "【 意 味 】"]
    items = []
    first, last = (1031, 4200) if continuation else (1, 1030)
    selected = [r for r in rows[2:] if len(r) > 2 and r[2].isdigit() and first <= int(r[2]) <= last]
    for row in selected:
        assert len(row) == 9 and row[2].isdigit() and row[0] in ("", "☆")
        assert row[1] in ("", "☆") and not (row[0] and row[1])
        number = int(row[2])
        assert number > 0 and all(row[i].strip() for i in (3, 5))
        mastery = "starting" if number >= 1907 or row[0] == "☆" else "learning" if row[1] == "☆" else "mastered"
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
    assert [int(r[2]) for r in selected] == list(range(first, last + 1))
    assert len({item["id"] for item in items}) == len(items)
    version = "teihitsu-onyomi-1031-4200-2026-10-06-v2" if continuation else "teihitsu-onyomi-2026-10-04-v1"
    return {"version": version, "items": items}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path)
    parser.add_argument("--continuation", action="store_true", help="Generate the separate 1031–4200 batch")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--previous-batch", type=Path, help="Previous JSON batch for one-time corrections")
    args = parser.parse_args()
    data = convert(args.csv, continuation=args.continuation)
    if args.output is None:
        name = "OnyomiContinuationStudyData" if args.continuation else "OnyomiStudyData"
        args.output = Path(f"KanjiBuildUp/Resources/{name}.json")
    if args.continuation:
        previous_path = args.previous_batch or args.output
        if previous_path.exists():
            previous = json.loads(previous_path.read_text(encoding="utf-8"))
            if previous["version"] == data["version"]:
                data.update({key: previous[key] for key in ("replacesVersion", "previousItems") if key in previous})
            else:
                current = {item["id"]: item for item in data["items"]}
                data["replacesVersion"] = previous["version"]
                data["previousItems"] = [item for item in previous["items"] if item["id"] in current and item != current[item["id"]]]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'{len(data["items"])} items; {dict(Counter(i["mastery"] for i in data["items"]))}')
