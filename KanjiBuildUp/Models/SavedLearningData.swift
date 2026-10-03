import Foundation

/// The default-data marker and items are saved atomically, so deleted defaults stay deleted.
struct SavedLearningData: Codable {
    var items: [StudyItem]
    var appliedDefaults: Set<String>
}
