import SwiftUI
#if os(iOS)
import PencilKit
#endif

/// Give the answer a central focus while keeping definitions and notes below it.
struct AnswerContentView: View {
    #if os(iOS)
    var handwriting: PKDrawing? = nil
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let item: StudyItem
    var showsQuestion = false
    let availableHeight: CGFloat
    @AppStorage("questionFont") private var questionFont: StudyFont = .gothic
    @AppStorage("answerFont") private var answerFont: StudyFont = .gothic
    @ScaledMetric(relativeTo: .largeTitle) private var answerSize = 56
    @ScaledMetric(relativeTo: .body) private var bodySize = 18
    @ScaledMetric(relativeTo: .largeTitle) private var alternativeAnswerSize = 26
    @ScaledMetric(relativeTo: .body) private var pairSpacing = 24

    private var compactHeight: Bool {
        #if os(iOS)
        return verticalSizeClass == .compact
        #else
        return false
        #endif
    }

    private var comparisonLayout: AnyLayout {
        #if os(iOS)
        if (sizeClass == .regular || verticalSizeClass == .compact) && !dynamicTypeSize.isAccessibilitySize {
            return AnyLayout(HStackLayout(alignment: .center, spacing: 20))
        }
        #endif
        return AnyLayout(VStackLayout(spacing: 12))
    }

    var body: some View {
        let pair = OnkunText(item.answer, category: item.category)
        VStack(alignment: .leading, spacing: 12) {
            comparisonLayout {
                #if os(iOS)
                if let handwriting, !handwriting.strokes.isEmpty {
                    HandwritingPreview(drawing: handwriting)
                }
                #endif
                VStack(spacing: 8) {
                    Text("答え").font(.caption).foregroundStyle(Palette.secondary)
                    StudySelectableText(text: pair?.text ?? item.answer,
                                        size: pair?.hasAlternatives == true ? alternativeAnswerSize : answerSize * (compactHeight ? 0.7 : 1),
                                        studyFont: answerFont, centered: true,
                                        paragraphSpacing: pair == nil ? 0 : pairSpacing)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("studyAnswer")
                }
                .frame(maxWidth: .infinity, minHeight: compactHeight ? 70 : max(100, availableHeight * 0.35))
            }
            if showsQuestion {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("問題").font(.subheadline.weight(.semibold))
                    StudySelectableText(text: item.displayedQuestion, size: bodySize,
                                        studyFont: questionFont, lineSpacing: 4)
                        .accessibilityIdentifier("answerQuestion")
                }
            }
            if !item.meaning.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("意味").font(.subheadline.weight(.semibold))
                    StudySelectableText(text: item.meaning,
                                        size: bodySize, lineSpacing: 3)
                        .accessibilityIdentifier("studyMeaning")
                }
            }
            if !item.notes.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("メモ").font(.subheadline.weight(.semibold))
                    StudySelectableText(text: item.notes, size: bodySize)
                        .accessibilityIdentifier("studyNotes")
                }
            }
        }
    }
}
