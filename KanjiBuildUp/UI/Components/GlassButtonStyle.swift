import SwiftUI

extension View {
    /// Use the system's interactive glass, with a native fallback on older OS versions.
    @ViewBuilder func appGlassButton(prominent: Bool = false) -> some View {
        #if os(iOS) || os(macOS)
        if #available(iOS 26.0, macOS 26.0, *) {
            if prominent { self.buttonStyle(.glassProminent) }
            else { self.buttonStyle(.glass) }
        } else {
            if prominent { self.buttonStyle(.borderedProminent) }
            else { self.buttonStyle(.bordered) }
        }
        #else
        if prominent { self.buttonStyle(.borderedProminent) }
        else { self.buttonStyle(.bordered) }
        #endif
    }
}
