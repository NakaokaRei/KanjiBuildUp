"""Convert the user's onkun CSV into a separately versioned default batch."""
import argparse
import csv
import json
import uuid
from pathlib import Path


def convert(path):
    with path.open(encoding="utf-8-sig", newline="") as source:
        rows = list(csv.reader(source))
    assert rows[0] == ["がんばるぞ", "", "", "", "", "", "", ""]
    assert rows[1] == ["", "【番】", "【問題⒜】", "【問題⒝】", "【解答⒜】", "【解答⒝】", "【重要度】", "【 意 味 】"]
    items = []
    for row in rows[2:]:
        assert len(row) == 8 and row[1].isdigit()
        assert all(row[index].strip() for index in (2, 3, 4, 5))
        number = int(row[1])
        assert number == len(items) + 1, f"Missing or duplicate number: {number}"
        items.append({
            "id": str(uuid.uuid5(uuid.NAMESPACE_URL, f"kanjibuildup/teihitsu/onkun/{number}")),
            "category": "onkun",
            "question": f"a：{row[2].strip()}\nb：{row[3].strip()}",
            "answer": f"a：{row[4].strip()}\nb：{row[5].strip()}",
            "meaning": row[7].strip(),
            "mastery": "starting",
            "notes": f"逞筆さん{number}番",
        })
    assert items, "Empty CSV"
    return {"version": "teihitsu-onkun-2026-10-09-v1", "items": items}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path)
    parser.add_argument("--output", type=Path, default=Path("KanjiBuildUp/Resources/OnkunStudyData.json"))
    args = parser.parse_args()
    data = convert(args.csv)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f'{len(data["items"])} items; all starting')
