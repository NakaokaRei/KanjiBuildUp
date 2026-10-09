import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Read-only text with native selection handles directly on the answer page.
struct StudySelectableText: View {
    let text: String
    let size: CGFloat
    var studyFont: StudyFont? = nil
    var centered = false
    var lineSpacing: CGFloat = 0

    var body: some View {
        #if os(iOS)
        InlineStudyText(text: text, size: size, studyFont: studyFont,
                        centered: centered, lineSpacing: lineSpacing)
        #else
        Text(text)
            .font(studyFont?.font(size: size) ?? .system(size: size))
            .multilineTextAlignment(centered ? .center : .leading)
            .lineSpacing(lineSpacing)
            .textSelection(.enabled)
        #endif
    }
}

#if os(iOS)
private struct InlineStudyText: UIViewRepresentable {
    let text: String
    let size: CGFloat
    let studyFont: StudyFont?
    let centered: Bool
    let lineSpacing: CGFloat

    private var font: UIFont {
        switch studyFont {
        case .gothic: .systemFont(ofSize: size, weight: .bold)
        case .mincho: UIFont(name: "HiraMinProN-W6", size: size) ?? .systemFont(ofSize: size, weight: .bold)
        case .lightGothic: UIFont(name: "HiraginoSans-W3", size: size) ?? .systemFont(ofSize: size)
        case nil: .systemFont(ofSize: size)
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        // The surrounding SwiftUI ScrollView owns scrolling and text height.
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.tintColor = UIColor(Palette.green)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = centered ? .center : .natural
        paragraph.lineSpacing = lineSpacing
        let attributed = NSAttributedString(string: text, attributes: [
            .font: font, .foregroundColor: UIColor(Palette.ink), .paragraphStyle: paragraph
        ])
        // SwiftUI updates also happen while selecting and resizing the header.
        // Avoid resetting the selection unless the actual content changes.
        if view.text != text {
            view.attributedText = attributed
            view.selectedRange = NSRange(location: 0, length: 0)
        } else if !view.attributedText.isEqual(to: attributed) {
            let selection = view.selectedRange
            view.attributedText = attributed
            view.selectedRange = selection
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        return CGSize(width: width, height: ceil(uiView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)).height))
    }
}
#endif
