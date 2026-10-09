import Foundation

/// Separate a trailing explanation without rewriting the saved question.
struct QuestionTextParts {
    let main: String
    let explanation: String?

    init(_ question: String) {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = text.firstIndex(where: { $0 == "（" || $0 == "(" }),
              start != text.startIndex else {
            main = question
            explanation = nil
            return
        }
        let prefix = String(text[..<start]).trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = String(text[start...])
        var closing: [Character] = []
        var valid = true
        for character in suffix {
            switch character {
            case "（": closing.append("）")
            case "(": closing.append(")")
            case "）", ")":
                if closing.popLast() != character { valid = false }
            default:
                if closing.isEmpty && !character.isWhitespace { valid = false }
            }
        }
        // Keep incomplete parentheses and inline fill-in questions as written.
        if valid && closing.isEmpty && !prefix.isEmpty {
            main = prefix
            explanation = suffix
        } else {
            main = question
            explanation = nil
        }
    }
}
