import Foundation

struct StudyItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let category: String
    let question: String
    let answer: String
    let meaning: String
    var mastery: Mastery = .starting
}
