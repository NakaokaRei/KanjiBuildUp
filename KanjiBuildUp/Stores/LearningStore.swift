import Foundation
import Observation

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
