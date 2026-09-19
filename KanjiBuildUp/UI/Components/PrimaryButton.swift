import SwiftUI

struct PrimaryButton: View {
    let title: String
    var enabled = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 8)
                .foregroundStyle(.white)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(Palette.green)
        .disabled(!enabled)
    }
}
