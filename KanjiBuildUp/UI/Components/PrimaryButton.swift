import SwiftUI

struct PrimaryButton: View {
    let title: String
    var enabled = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 18)
                .foregroundStyle(.white)
                .background(enabled ? Palette.green : Palette.secondary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        }.buttonStyle(.plain).disabled(!enabled)
    }
}
