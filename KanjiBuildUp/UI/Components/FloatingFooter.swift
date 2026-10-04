import SwiftUI

/// Draws over scrollable content; only the controls intercept touches.
private struct FloatingFooterModifier<Footer: View>: ViewModifier {
    @Binding var height: CGFloat
    let footer: Footer

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            footer
                .padding(.horizontal, 20).padding(.vertical, 12)
                .frame(maxWidth: 640).frame(maxWidth: .infinity)
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: FooterHeightKey.self, value: geometry.size.height)
                    }
                }
                .background {
                    VStack(spacing: 0) {
                        Palette.bottomFade.frame(height: 64)
                        Color.white.opacity(0.97)
                    }
                        .padding(.top, -64)
                        .ignoresSafeArea(edges: .bottom)
                        .allowsHitTesting(false)
                }
        }
        .onPreferenceChange(FooterHeightKey.self) { height = $0 }
    }
}

private struct FooterHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    func floatingFooter<Footer: View>(height: Binding<CGFloat>, @ViewBuilder content: () -> Footer) -> some View {
        modifier(FloatingFooterModifier(height: height, footer: content()))
    }
}
