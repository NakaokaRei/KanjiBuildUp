import Foundation

struct StudySession: Identifiable, Hashable {
    let id = UUID()
    let itemIDs: [UUID]
    let isReview: Bool
    var index = 0
    var revealed: Bool
    var complete = false
    init(items: [StudyItem], review: Bool = false) {
        itemIDs = (review ? items : items.shuffled()).map(\.id)
        isReview = review
        revealed = review
    }
    var currentID: UUID? { itemIDs.indices.contains(index) ? itemIDs[index] : nil }
    mutating func advance() {
        if index + 1 < itemIDs.count { index += 1; revealed = false }
        else { complete = true }
    }
}
