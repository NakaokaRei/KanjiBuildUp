import SwiftUI

/// Enlarge only when the maximum-size text fits on one line. Reserve its height
/// so font changes do not unexpectedly change the text row height.
struct AdaptiveQuestionText: View {
    let question: String
    let progress: CGFloat
    @AppStorage("questionFont") private var questionFont: StudyFont = .gothic
    @ScaledMetric private var baseSize: CGFloat
    @ScaledMetric private var maximumSize: CGFloat

    init(question: String, baseSize: CGFloat, maximumSize: CGFloat, progress: CGFloat) {
        self.question = question
        self.progress = progress
        _baseSize = ScaledMetric(wrappedValue: baseSize, relativeTo: .title2)
        _maximumSize = ScaledMetric(wrappedValue: maximumSize, relativeTo: .title2)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if !question.contains(where: \.isNewline) {
                Text(question)
                    .font(questionFont.font(size: maximumSize))
                    .fixedSize()
                    .hidden()
                    .accessibilityHidden(true)
                    .overlay(alignment: .leading) {
                        Text(question)
                            .font(questionFont.font(size: baseSize + (maximumSize - baseSize) * min(1, max(0, progress))))
                            .fixedSize()
                    }
            }
            Text(question)
                .font(questionFont.font(size: baseSize))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }
}
