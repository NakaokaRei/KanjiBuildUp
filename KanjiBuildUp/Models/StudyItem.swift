import Foundation

struct StudyItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var category: String
    var question: String
    var answer: String
    var meaning: String
    var notes: String = ""
    var mastery: Mastery = .starting

    private enum CodingKeys: String, CodingKey {
        case id, category, question, answer, meaning, notes, mastery
    }

    init(category: String, question: String, answer: String, meaning: String) {
        self.category = category
        self.question = question
        self.answer = answer
        self.meaning = meaning
    }

    // Records saved before notes were introduced remain readable.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        category = try values.decode(String.self, forKey: .category)
        question = try values.decode(String.self, forKey: .question)
        answer = try values.decode(String.self, forKey: .answer)
        meaning = try values.decode(String.self, forKey: .meaning)
        notes = try values.decodeIfPresent(String.self, forKey: .notes) ?? ""
        mastery = try values.decode(Mastery.self, forKey: .mastery)
    }
}
