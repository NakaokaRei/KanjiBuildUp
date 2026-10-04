import Foundation
import Observation
import WidgetKit

@MainActor @Observable
final class LearningStore {
    private(set) var items: [StudyItem] = []
    var errorMessage: String?
    private let fileURL: URL
    private let publishesWidget: Bool
    private var canSave = true
    private var appliedDefaults: Set<String> = []

    init(fileURL: URL? = nil, defaults: DefaultStudyData? = nil, additionalDefaults: [DefaultStudyData] = []) {
        var testURL: URL?
        var testDefaults = false
        #if DEBUG
        testDefaults = ProcessInfo.processInfo.environment["KANJI_TEST_DEFAULTS"] == "1"
        // UI tests use their own store, so relaunch tests never touch the user's data.
        if let name = ProcessInfo.processInfo.environment["KANJI_TEST_STORE"] {
            testURL = URL.applicationSupportDirectory.appendingPathComponent("UITests").appendingPathComponent(name + ".json")
        }
        #endif
        self.publishesWidget = fileURL == nil && testURL == nil
        self.fileURL = fileURL ?? testURL ?? URL.applicationSupportDirectory
            .appendingPathComponent("KanjiBuildUp", isDirectory: true).appendingPathComponent("items.json")
        do {
            if FileManager.default.fileExists(atPath: self.fileURL.path) {
                let data = try Data(contentsOf: self.fileURL)
                let decoder = JSONDecoder()
                if let legacy = try? decoder.decode([StudyItem].self, from: data) {
                    items = legacy
                } else {
                    let saved = try decoder.decode(SavedLearningData.self, from: data)
                    items = saved.items
                    appliedDefaults = saved.appliedDefaults
                }
            }
            // Explicit stores and UI-test stores stay isolated from bundled defaults.
            let initialDataSets: [DefaultStudyData]
            if let defaults {
                initialDataSets = [defaults] + additionalDefaults
            } else if fileURL == nil && (testURL == nil || testDefaults) {
                initialDataSets = try DefaultStudyData.loadAll() + additionalDefaults
            } else {
                initialDataSets = additionalDefaults
            }
            for initialData in initialDataSets where !appliedDefaults.contains(initialData.version) {
                let existingIDs = Set(items.map(\.id))
                let existingContent = Set(items.map { [$0.category, $0.question, $0.answer] })
                let additions = initialData.items.filter {
                    !existingIDs.contains($0.id) && !existingContent.contains([$0.category, $0.question, $0.answer])
                }
                if !commit(items + additions, versions: appliedDefaults.union([initialData.version])) { break }
            }
            publishWidget()
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
    @discardableResult func update(_ item: StudyItem) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            errorMessage = "この問題は削除されているため、更新できません。"
            return false
        }
        var updated = items
        updated[index] = item
        return commit(updated)
    }

    @discardableResult func delete(_ id: UUID) -> Bool {
        guard items.contains(where: { $0.id == id }) else { return false }
        return commit(items.filter { $0.id != id })
    }

    private func publishWidget() {
        guard publishesWidget else { return }
        let progress = WidgetProgress(
            starting: items.filter { $0.mastery == .starting }.count,
            learning: items.filter { $0.mastery == .learning }.count,
            mastered: items.filter { $0.mastery == .mastered }.count)
        if progress.write() { WidgetCenter.shared.reloadTimelines(ofKind: WidgetProgress.kind) }
    }

    private func commit(_ updated: [StudyItem], versions: Set<String>? = nil) -> Bool {
        guard canSave else {
            errorMessage = "保存データを読み込めていないため、変更できません。アプリを再起動して確認してください。"
            return false
        }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let nextVersions = versions ?? appliedDefaults
            let saved = SavedLearningData(items: updated, appliedDefaults: nextVersions)
            try JSONEncoder().encode(saved).write(to: fileURL, options: .atomic)
            appliedDefaults = nextVersions
            items = updated
            publishWidget()
            return true
        } catch {
            errorMessage = "保存できませんでした。変更は反映されていません。\n\(error.localizedDescription)"
            return false
        }
    }
}
