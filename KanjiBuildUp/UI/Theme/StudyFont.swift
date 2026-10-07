import SwiftUI

enum StudyFont: String, CaseIterable, Identifiable {
    case gothic, mincho, lightGothic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gothic: "ゴシック（標準）"
        case .mincho: "明朝体"
        case .lightGothic: "ゴシック（細字）"
        }
    }

    // Sizes are already scaled by the calling view's ScaledMetric.
    func font(size: CGFloat) -> Font {
        switch self {
        case .gothic: .system(size: size, weight: .bold)
        case .mincho: .custom("HiraMinProN-W6", fixedSize: size)
        case .lightGothic: .custom("HiraginoSans-W3", fixedSize: size)
        }
    }
}
