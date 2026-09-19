import Foundation

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
