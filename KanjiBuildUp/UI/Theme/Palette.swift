import SwiftUI

enum Palette {
    static let background = Color(red: 0.993, green: 0.993, blue: 0.985)
    static let green = Color(red: 0.22, green: 0.39, blue: 0.33)
    static let ink = Color(red: 0.10, green: 0.16, blue: 0.16)
    static let secondary = Color(red: 0.34, green: 0.41, blue: 0.41)
    static let softGreen = Color(red: 0.93, green: 0.96, blue: 0.93)

    static var pageGradient: LinearGradient {
        LinearGradient(colors: [softGreen.opacity(0.7), background, .white],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var bottomFade: LinearGradient {
        LinearGradient(stops: [
            .init(color: background.opacity(0), location: 0),
            .init(color: Color.white.opacity(0.25), location: 0.25),
            .init(color: Color.white.opacity(0.82), location: 0.6),
            .init(color: Color.white.opacity(0.98), location: 1)
        ], startPoint: .top, endPoint: .bottom)
    }
}
