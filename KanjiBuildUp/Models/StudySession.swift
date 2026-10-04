import Foundation

struct StudySession: Identifiable, Hashable {
    let id = UUID()
    let itemIDs: [UUID]
    let isReview: Bool
    static let companionNames = ["CompanionPenguin", "CompanionFrog", "CompanionButterfly", "CompanionStarfish", "CompanionSeaLion"]
    private let companions: [UUID: String]
    var companionName: String { currentID.flatMap { companions[$0] } ?? "CompanionPenguin" }
    var index = 0
    var revealed: Bool
    var complete = false
    init(items: [StudyItem], review: Bool = false) {
        itemIDs = (review ? items : items.shuffled()).map(\.id)
        var assignments: [UUID: String] = [:]
        var previous: String?
        for id in itemIDs {
            let choices = Self.companionNames.filter { $0 != previous }
            let name = choices.randomElement() ?? "CompanionPenguin"
            assignments[id] = name
            previous = name
        }
        companions = assignments
        isReview = review
        revealed = review
    }
    var currentID: UUID? { itemIDs.indices.contains(index) ? itemIDs[index] : nil }
    var canGoBack: Bool { !isReview && !complete && index > 0 }
    mutating func goBack() {
        guard canGoBack else { return }
        index -= 1
        revealed = false
    }
    mutating func advance() {
        if index + 1 < itemIDs.count { index += 1; revealed = false }
        else { complete = true }
    }
}
