import SwiftUI

/// Give the answer a central focus while keeping definitions and notes below it.
struct AnswerContentView: View {
    let item: StudyItem
    let availableHeight: CGFloat
    @AppStorage("answerFont") private var answerFont: StudyFont = .gothic
    @ScaledMetric(relativeTo: .largeTitle) private var answerSize = 56
    @ScaledMetric(relativeTo: .body) private var bodySize = 18
    @ScaledMetric(relativeTo: .largeTitle) private var alternativeAnswerSize = 26
    @ScaledMetric(relativeTo: .body) private var pairSpacing = 24

    var body: some View {
        let pair = OnkunText(item.answer, category: item.category)
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 8) {
                Text("答え").font(.caption).foregroundStyle(Palette.secondary)
                StudySelectableText(text: pair?.text ?? item.answer,
                                    size: pair?.hasAlternatives == true ? alternativeAnswerSize : answerSize,
                                    studyFont: answerFont, centered: true,
                                    paragraphSpacing: pair == nil ? 0 : pairSpacing)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("studyAnswer")
            }
            .frame(maxWidth: .infinity, minHeight: max(140, availableHeight * 0.5))
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("意味").font(.subheadline.weight(.semibold))
                StudySelectableText(text: item.meaning,
                                    size: bodySize, lineSpacing: 3)
                    .accessibilityIdentifier("studyMeaning")
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
