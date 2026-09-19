import SwiftUI

extension Mastery {
    var tint: Color {
        switch self {
        case .starting: Color(red: 0.51, green: 0.35, blue: 0.10)
        case .learning: Color(red: 0.12, green: 0.34, blue: 0.56)
        case .mastered: Color(red: 0.16, green: 0.43, blue: 0.30)
        }
    }
    var background: Color {
        switch self {
        case .starting: Color(red: 1, green: 0.95, blue: 0.84)
        case .learning: Color(red: 0.89, green: 0.94, blue: 0.99)
        case .mastered: Color(red: 0.89, green: 0.97, blue: 0.91)
        }
    }
}
