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
        session.revealed = true; session.advance()
        precondition(session != originalSession)
        precondition(session.index == 1 && !session.revealed)
        session.advance(); precondition(session.complete)
        let review = StudySession(items: [parsed[0]], review: true)
        precondition(review.revealed && review.isReview)
        try Data("corrupt".utf8).write(to: url)
        let corrupt = LearningStore(fileURL: url)
        precondition(corrupt.errorMessage != nil && !corrupt.add(parsed))
        let preserved = try String(contentsOf: url, encoding: .utf8)
        precondition(preserved == "corrupt")
        print("PASS: CSV formats/errors, Shift JIS, initial mastery, filtering, persistence, session, corrupted-file protection")
    }
}
