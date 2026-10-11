import Foundation

struct StudyItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var category: String
    var question: String
    var answer: String
    var meaning: String
    var notes: String = ""
    var mastery: Mastery = .starting
    var isFavorite = false

    private enum CodingKeys: String, CodingKey {
        case id, category, question, answer, meaning, notes, mastery, isFavorite
    }

    init(category: String, question: String, answer: String, meaning: String) {
        self.category = category
        self.question = question
        self.answer = answer
        self.meaning = meaning
    }

    // Older records default to empty notes and no favorite.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        category = try values.decode(String.self, forKey: .category)
        question = try values.decode(String.self, forKey: .question)
        answer = try values.decode(String.self, forKey: .answer)
        meaning = try values.decode(String.self, forKey: .meaning)
        isFavorite = try values.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        notes = try values.decodeIfPresent(String.self, forKey: .notes) ?? ""
        mastery = try values.decode(Mastery.self, forKey: .mastery)
    }
}
