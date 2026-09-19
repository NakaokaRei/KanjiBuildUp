import Foundation

/// Parses quoted commas, doubled quotes, and embedded newlines without splitting records first.
enum KanjiCSV {
    static let header = ["カテゴリー", "問題", "答え", "意味"]
    static func decode(_ data: Data) throws -> [StudyItem] {
        guard data.count <= 5_000_000 else {
            throw LearningError(message: "CSVは5MB以下のファイルを選んでください。")
        }
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .shiftJIS) else {
            throw LearningError(message: "文字コードを読み取れません。UTF-8のCSVとして保存してください。")
        }
        return try parse(text)
    }

    static func parse(_ text: String) throws -> [StudyItem] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        var chars = Array(normalized)
        if chars.first == "\u{FEFF}" { chars.removeFirst() }
        var rows: [[String]] = [], row: [String] = [], field = ""
        var quoted = false, closed = false, index = 0
        func finishField() { row.append(field); field = ""; closed = false }
        func finishRow() {
            finishField()
            if row.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { rows.append(row) }
            row = []
        }
        while index < chars.count {
            let c = chars[index]
            if quoted {
                if c == "\"" {
                    if index + 1 < chars.count && chars[index + 1] == "\"" {
                        field.append("\""); index += 1
                    } else { quoted = false; closed = true }
                } else { field.append(c) }
            } else if c == "," { finishField() }
            else if c == "\n" { finishRow() }
            else if c == "\"" && field.isEmpty && !closed { quoted = true }
            else if closed || c == "\"" {
                throw LearningError(message: "CSVの引用符の形式が正しくありません。ダブルクォートの閉じ忘れなどを確認してください。")
            } else { field.append(c) }
            index += 1
        }
        guard !quoted else { throw LearningError(message: "CSVのダブルクォートが閉じられていません。") }
        finishRow()
        guard let first = rows.first else { throw LearningError(message: "CSVが空です。") }
        let headings = first.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard headings.count == 4, Set(headings) == Set(header) else {
            throw LearningError(message: "1行目には「カテゴリー,問題,答え,意味」の4列を指定してください。")
        }
        let columns = header.map { headings.firstIndex(of: $0)! }
        guard rows.count > 1 else { throw LearningError(message: "CSVに問題がありません。") }
        return try rows.dropFirst().enumerated().map { offset, values in
            guard values.count == 4 else { throw LearningError(message: "データの\(offset + 1)件目が4列ではありません。") }
            let fields = columns.map { values[$0].trimmingCharacters(in: .whitespacesAndNewlines) }
            guard fields.prefix(3).allSatisfy({ !$0.isEmpty }) else {
                throw LearningError(message: "データの\(offset + 1)件目のカテゴリー・問題・答えを入力してください。")
            }
            return StudyItem(category: fields[0], question: fields[1], answer: fields[2], meaning: fields[3])
        }
    }
}
