import SwiftUI
import CoreText
#if os(iOS)
import UIKit
#endif

/// Three source-PDF characters not covered by the system Japanese fonts.
/// Keep Unicode text intact for search, selection, copying, and accessibility.
enum StudyGlyphs {
    static let characters = ["𬵪", "𩶗", "𫒼"]
    static let fontName = "KanjiPDFGlyphs-Regular"
    private static let registered: Bool = {
        guard let url = Bundle.main.url(forResource: "KanjiPDFGlyphs", withExtension: "ttf")
            ?? Bundle.main.url(forResource: "KanjiPDFGlyphs", withExtension: "ttf", subdirectory: "Resources") else { return false }
        return CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }()

    static func text(_ value: String, size: CGFloat) -> Text {
        guard characters.contains(where: value.contains), registered else { return Text(value) }
        var attributed = AttributedString(value)
        for character in characters {
            var start = attributed.startIndex
            while start < attributed.endIndex,
                  let range = attributed[start...].range(of: character) {
                attributed[range].font = .custom(fontName, fixedSize: size)
                start = range.upperBound
            }
        }
        return Text(attributed)
    }

    #if os(iOS)
    static func apply(to text: NSMutableAttributedString, size: CGFloat) {
        guard characters.contains(where: text.string.contains), registered,
              let font = UIFont(name: fontName, size: size) else { return }
        let string = text.string as NSString
        for character in characters {
            var start = 0
            while start < string.length {
                let range = string.range(of: character, range: NSRange(location: start, length: string.length - start))
                guard range.location != NSNotFound else { break }
                text.addAttribute(.font, value: font, range: range)
                start = NSMaxRange(range)
            }
        }
    }
    #endif
}
