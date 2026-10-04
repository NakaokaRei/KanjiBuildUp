import Foundation

/// A small, versioned snapshot. The widget never reads or rewrites the learning database.
nonisolated struct WidgetProgress: Codable, Equatable, Sendable {
    static let appGroup = "group.com.reinakaoka.KanjiBuildUp"
    static let kind = "KanjiProgressWidget"
    static let key = "learning-progress-v1"
    let starting: Int
    let learning: Int
    let mastered: Int
    var total: Int { starting + learning + mastered }
    static let empty = WidgetProgress(starting: 0, learning: 0, mastered: 0)
    static let example = WidgetProgress(starting: 2711, learning: 2637, mastered: 2652)

    static func read(from defaults: UserDefaults? = UserDefaults(suiteName: appGroup)) -> WidgetProgress? {
        guard let data = defaults?.data(forKey: key),
              let value = try? JSONDecoder().decode(Self.self, from: data),
              value.starting >= 0, value.learning >= 0, value.mastered >= 0 else { return nil }
        return value
    }

    @discardableResult
    func write(to defaults: UserDefaults? = UserDefaults(suiteName: appGroup)) -> Bool {
        guard let defaults, Self.read(from: defaults) != self,
              let data = try? JSONEncoder().encode(self) else { return false }
        defaults.set(data, forKey: Self.key)
        return true
    }
}
