import Foundation

@main struct LearningTests {
    @MainActor static func main() throws {
        let simple = "カテゴリー,問題,答え,意味\n読み,桜,さくら,春の木\n読み,椿,つばき,"
        let parsed = try KanjiCSV.parse(simple)
        precondition(parsed.count == 2 && parsed.allSatisfy { $0.mastery == .starting })
        let complex = try KanjiCSV.parse("\u{FEFF}答え,意味,カテゴリー,問題\r\nさくら,\"春,花\n\"\"桜\"\"\",読み,桜\r\n")
        precondition(complex[0].meaning == "春,花\n\"桜\"")
        precondition(complex[0].question == "桜")
        for invalid in ["", "カテゴリー,問題,答え,意味", "問題,答え\n桜,さくら", "カテゴリー,問題,答え,意味\n読み,,さくら,木", "カテゴリー,問題,答え,意味\n読み,桜,さくら,\"未終了", "カテゴリー,問題,答え,意味\n読み,桜,さくら,\"木\"x"] {
            do { _ = try KanjiCSV.parse(invalid); preconditionFailure("Invalid CSV accepted") }
            catch is LearningError { }
        }
        let sjis = simple.data(using: .shiftJIS)!
        let decoded = try KanjiCSV.decode(sjis)
        precondition(decoded.count == 2)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("items.json")
        let store = LearningStore(fileURL: url)
        precondition(store.items.isEmpty)
        precondition(store.add(parsed))
        precondition(store.setMastery(.mastered, for: parsed[0].id))
        let reloaded = LearningStore(fileURL: url)
        precondition(reloaded.items.count == 2)
        precondition(reloaded.item(parsed[0].id)?.mastery == .mastered)
        precondition(reloaded.filtered(category: "読み", mastery: .mastered).count == 1)
        precondition(reloaded.filtered(category: "ことわざ", mastery: nil).isEmpty)
        var session = StudySession(items: parsed)
        let originalSession = session
        precondition(Set(session.itemIDs) == Set(parsed.map(\.id)))
        precondition(!session.revealed && !session.isReview)
        precondition(!session.canGoBack)
        session.goBack()
        precondition(session == originalSession)
        session.revealed = true; session.advance()
        precondition(session != originalSession)
        precondition(session.index == 1 && !session.revealed)
        let secondID = session.currentID
        precondition(session.canGoBack)
        session.revealed = true
        session.goBack()
        precondition(session.currentID == originalSession.currentID && !session.revealed)
        precondition(session.itemIDs == originalSession.itemIDs && !session.canGoBack)
        session.advance()
        precondition(session.currentID == secondID)
        session.advance(); precondition(session.complete)
        let completedSession = session
        session.goBack()
        precondition(session == completedSession)
        var review = StudySession(items: [parsed[0]], review: true)
        review.goBack()
        precondition(review.revealed && review.isReview)
        // Migration from records without a notes key.
        let encoded = try JSONEncoder().encode(parsed)
        var legacy = try JSONSerialization.jsonObject(with: encoded) as! [[String: Any]]
        for index in legacy.indices { legacy[index].removeValue(forKey: "notes") }
        let migrated = try JSONDecoder().decode([StudyItem].self, from: JSONSerialization.data(withJSONObject: legacy))
        precondition(migrated.allSatisfy { $0.notes.isEmpty })
        var edited = reloaded.items[0]
        edited.category = "訓読み"; edited.question = "梅"; edited.answer = "うめ"
        edited.meaning = "春の花"; edited.notes = "覚え方\n補足"
        precondition(reloaded.update(edited))
        let editedStore = LearningStore(fileURL: url)
        precondition(editedStore.item(edited.id) == edited)
        precondition(editedStore.delete(edited.id))
        precondition(LearningStore(fileURL: url).item(edited.id) == nil)
        precondition(!editedStore.update(edited))
        let invalidURL = directory.appendingPathComponent("not-a-directory")
        try Data("block".utf8).write(to: invalidURL)
        let failedStore = LearningStore(fileURL: invalidURL.appendingPathComponent("items.json"))
        precondition(!failedStore.add(parsed) && failedStore.items.isEmpty)
        let failureURL = directory.appendingPathComponent("failure.json")
        let writeFailureStore = LearningStore(fileURL: failureURL)
        precondition(writeFailureStore.add([edited]))
        try FileManager.default.removeItem(at: failureURL)
        try FileManager.default.createDirectory(at: failureURL, withIntermediateDirectories: false)
        var unsaved = edited
        unsaved.notes = "保存されない変更"
        precondition(!writeFailureStore.update(unsaved))
        precondition(writeFailureStore.item(edited.id) == edited)
        precondition(!writeFailureStore.delete(edited.id))
        precondition(writeFailureStore.item(edited.id) == edited)
        try Data("corrupt".utf8).write(to: url)
        let corrupt = LearningStore(fileURL: url)
        precondition(corrupt.errorMessage != nil && !corrupt.add(parsed))
        let preserved = try String(contentsOf: url, encoding: .utf8)
        precondition(preserved == "corrupt")
        let defaultsURL = URL(fileURLWithPath: "KanjiBuildUp/Resources/DefaultStudyData.json")
        let defaults = try JSONDecoder().decode(DefaultStudyData.self, from: Data(contentsOf: defaultsURL))
        precondition(defaults.items.count == 2974)
        precondition(defaults.items.filter { $0.mastery == .starting }.count == 2308)
        precondition(defaults.items.filter { $0.mastery == .learning }.count == 130)
        precondition(defaults.items.filter { $0.mastery == .mastered }.count == 536)
        let seededURL = directory.appendingPathComponent("seeded.json")
        let seeded = LearningStore(fileURL: seededURL, defaults: defaults)
        precondition(seeded.items == defaults.items)
        let first = defaults.items[0]
        precondition(first.notes == "逞筆さん411番")
        precondition(seeded.setMastery(.mastered, for: first.id))
        precondition(seeded.delete(defaults.items[1].id))
        let restarted = LearningStore(fileURL: seededURL, defaults: defaults)
        precondition(restarted.items.count == 2973)
        precondition(restarted.item(first.id)?.mastery == .mastered)
        precondition(restarted.item(defaults.items[1].id) == nil)
        let yojiURL = URL(fileURLWithPath: "KanjiBuildUp/Resources/YojiKakiStudyData.json")
        let yoji = try JSONDecoder().decode(DefaultStudyData.self, from: Data(contentsOf: yojiURL))
        precondition(yoji.items.count == 1605)
        precondition(yoji.items.filter { $0.mastery == .starting }.count == 198)
        precondition(yoji.items.filter { $0.mastery == .learning }.count == 388)
        precondition(yoji.items.filter { $0.mastery == .mastered }.count == 1019)
        precondition(yoji.items[1057].mastery == .starting)
        precondition(yoji.items[1058].mastery == .mastered)
        precondition(yoji.items[1059].mastery == .learning)
        precondition(yoji.items[1604].mastery == .starting)
        precondition(yoji.items[4].answer == "縹渺\n縹緲\n 縹眇")
        precondition(yoji.items[0].notes == "逞筆さん1番\n出典：＊『礼記-中庸』")
        var personal = restarted.item(first.id)!
        personal.notes = "編集したメモ"
        precondition(restarted.update(personal))
        let expanded = LearningStore(fileURL: seededURL, defaults: defaults, additionalDefaults: [yoji])
        precondition(expanded.items.count == 4578)
        precondition(expanded.item(first.id) == personal)
        precondition(expanded.item(defaults.items[1].id) == nil)
        precondition(expanded.item(yoji.items[0].id) == yoji.items[0])
        precondition(expanded.delete(yoji.items[0].id))
        precondition(expanded.setMastery(.mastered, for: yoji.items[1059].id))
        let expandedRestart = LearningStore(fileURL: seededURL, defaults: defaults, additionalDefaults: [yoji])
        precondition(expandedRestart.items.count == 4577)
        precondition(expandedRestart.item(yoji.items[0].id) == nil)
        precondition(expandedRestart.item(yoji.items[1059].id)?.mastery == .mastered)
        let legacyURL = directory.appendingPathComponent("legacy.json")
        var existing = first
        existing.id = UUID(); existing.notes = "自分のメモ"; existing.mastery = .learning
        try JSONEncoder().encode([existing]).write(to: legacyURL)
        let upgraded = LearningStore(fileURL: legacyURL, defaults: defaults)
        precondition(upgraded.items.count == 2974 && upgraded.item(existing.id) == existing)
        precondition(upgraded.item(first.id) == nil)
        let corruptDefaults = LearningStore(fileURL: url, defaults: defaults)
        precondition(corruptDefaults.items.isEmpty && corruptDefaults.errorMessage != nil)
        let stillCorrupt = try String(contentsOf: url, encoding: .utf8)
        precondition(stillCorrupt == "corrupt")
        print("PASS: CSV formats/errors, Shift JIS, initial mastery, filtering, persistence, session, corrupted-file protection")
    }
}
