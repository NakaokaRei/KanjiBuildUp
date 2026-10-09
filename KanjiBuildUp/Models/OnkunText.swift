import Foundation

/// Present the two CSV groups without labels, preserving their boundary.
struct OnkunText {
    let groups: [String]
    var text: String { groups.joined(separator: "\n") }
    var hasAlternatives: Bool { groups.contains { $0.contains(" / ") } }

    init?(_ text: String, category: String) {
        guard category == "onkun" else { return nil }
        let lines = text.components(separatedBy: .newlines)
        guard let first = lines.first,
              first.hasPrefix("a：") || first.hasPrefix("a:"),
              let split = lines.firstIndex(where: { $0.hasPrefix("b：") || $0.hasPrefix("b:") }) else { return nil }
        let a = [String(first.dropFirst(2))] + Array(lines[1..<split])
        let b = [String(lines[split].dropFirst(2))] + Array(lines.dropFirst(split + 1))
        groups = [a, b].map { group in
            group.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }.joined(separator: " / ")
        }
    }
}

extension StudyItem {
    var displayedQuestion: String { OnkunText(question, category: category)?.text ?? question }
}
