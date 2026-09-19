import Foundation
import Observation

enum Mastery: String, Codable, CaseIterable, Identifiable {
    case starting, learning, mastered
    var id: String { rawValue }
    var title: String {
        switch self {
        case .starting: "がんばるぞ"
        case .learning: "あとすこし"
        case .mastered: "かんぺき"
        }
    }
}

struct StudyItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let category: String
    let question: String
    let answer: String
    let meaning: String
    var mastery: Mastery = .starting
}

struct LearningError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

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

@MainActor @Observable
final class LearningStore {
    private(set) var items: [StudyItem] = []
    var errorMessage: String?
    private let fileURL: URL
    private var canSave = true

    init(fileURL: URL? = nil) {
        var testURL: URL?
        #if DEBUG
        // UI tests use their own store, so relaunch tests never touch the user's data.
        if let name = ProcessInfo.processInfo.environment["KANJI_TEST_STORE"] {
            testURL = URL.applicationSupportDirectory.appendingPathComponent("UITests").appendingPathComponent(name + ".json")
        }
        #endif
        self.fileURL = fileURL ?? testURL ?? URL.applicationSupportDirectory
            .appendingPathComponent("KanjiBuildUp", isDirectory: true).appendingPathComponent("items.json")
        do {
            if FileManager.default.fileExists(atPath: self.fileURL.path) {
                items = try JSONDecoder().decode([StudyItem].self, from: Data(contentsOf: self.fileURL))
            }
        } catch {
            canSave = false
            errorMessage = "保存したデータを読み込めませんでした。データの上書きを防ぐため、保存を停止しています。\n\(error.localizedDescription)"
        }
    }

    var categories: [String] { Array(Set(items.map(\.category))).sorted() }
    func filtered(category: String?, mastery: Mastery?) -> [StudyItem] {
        items.filter { (category == nil || $0.category == category) && (mastery == nil || $0.mastery == mastery) }
    }
    func item(_ id: UUID) -> StudyItem? { items.first { $0.id == id } }
    @discardableResult func add(_ entries: [StudyItem]) -> Bool { commit(items + entries) }
    @discardableResult func setMastery(_ mastery: Mastery, for id: UUID) -> Bool {
        var updated = items
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return false }
        updated[index].mastery = mastery
        return commit(updated)
    }
    private func commit(_ updated: [StudyItem]) -> Bool {
        guard canSave else {
            errorMessage = "保存データを読み込めていないため、変更できません。アプリを再起動して確認してください。"
            return false
        }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(updated).write(to: fileURL, options: .atomic)
            items = updated
            return true
        } catch {
            errorMessage = "保存できませんでした。変更は反映されていません。\n\(error.localizedDescription)"
            return false
        }
    }
}

struct StudySession: Identifiable, Hashable {
    let id = UUID()
    let itemIDs: [UUID]
    let isReview: Bool
    var index = 0
    var revealed: Bool
    var complete = false
    init(items: [StudyItem], review: Bool = false) {
        itemIDs = (review ? items : items.shuffled()).map(\.id)
        isReview = review
        revealed = review
    }
    var currentID: UUID? { itemIDs.indices.contains(index) ? itemIDs[index] : nil }
    mutating func advance() {
        if index + 1 < itemIDs.count { index += 1; revealed = false }
        else { complete = true }
    }
}
