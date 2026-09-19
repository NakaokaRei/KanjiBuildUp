import SwiftUI

struct MasteryBadge: View {
    let mastery: Mastery
    var body: some View {
        Text(mastery.title).font(.subheadline.weight(.semibold))
            .foregroundStyle(mastery.tint).padding(.horizontal, 12).padding(.vertical, 8)
            .background(mastery.background, in: RoundedRectangle(cornerRadius: 10))
    }
}
