import SwiftUI

/// Decorative artwork never participates in the text's intrinsic size.
struct CompanionImage: View {
  let name: String
  var size: CGFloat = 56
  var body: some View {
    Image(name).resizable().scaledToFit()
      .frame(width: size, height: size)
      .accessibilityHidden(true).allowsHitTesting(false)
  }
}

/// The tail occupies its own inset and points toward the companion on the right.
struct CompanionSpeechBubble: Shape {
  var showsTail = true

  func path(in rect: CGRect) -> Path {
    let tailWidth: CGFloat = showsTail ? 14 : 0
    let body = CGRect(x: rect.minX, y: rect.minY,
                      width: max(0, rect.width - tailWidth), height: rect.height)
    var path = Path(roundedRect: body, cornerRadius: min(24, rect.height / 2))
    if showsTail {
      let middle = rect.midY
      path.move(to: CGPoint(x: body.maxX - 4, y: middle - 8))
      path.addQuadCurve(to: CGPoint(x: rect.maxX, y: middle + 7),
                       control: CGPoint(x: body.maxX + 4, y: middle + 3))
      path.addQuadCurve(to: CGPoint(x: body.maxX - 4, y: middle + 10),
                       control: CGPoint(x: body.maxX + 2, y: middle + 12))
      path.closeSubpath()
    }
    return path
  }
}

struct HeaderWave: Shape {
  func path(in rect: CGRect) -> Path {
    let amplitude = min(16, rect.height / 3)
    let baseline = rect.maxY - amplitude
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: baseline))
    // One broad crest and trough; keep the existing amplitude.
    for segment in 0..<2 {
      let endX = rect.maxX - rect.width * CGFloat(segment + 1) / 2
      let controlX = rect.maxX - rect.width * (CGFloat(segment) + 0.5) / 2
      let direction: CGFloat = segment.isMultiple(of: 2) ? 1 : -1
      path.addQuadCurve(to: CGPoint(x: endX, y: baseline),
                        control: CGPoint(x: controlX, y: baseline + direction * amplitude * 2))
    }
    path.closeSubpath()
    return path
  }
}

struct CompanionHeader<Content: View>: View {
  var bottomPadding: CGFloat = 36
  @ViewBuilder var content: Content
  var body: some View {
    content.padding(.bottom, bottomPadding)
      .background {
        HeaderWave().fill(Palette.header)
          .padding(.horizontal, -20)
          .overlay(alignment: .top) {
            Palette.header.frame(height: 150).padding(.horizontal, -20).offset(y: -150)
          }
          .allowsHitTesting(false)
      }
  }
}

extension View {
  @ViewBuilder func companionNavigationBar() -> some View {
    #if os(iOS)
      self.toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Palette.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    #else
      self
    #endif
  }
}
