import SwiftUI

struct StudyQuestionText: View {
    let question: String
    let studyFont: StudyFont
    var category: String = ""
    @ScaledMetric(relativeTo: .largeTitle) private var questionSize: CGFloat = 36
    @ScaledMetric(relativeTo: .largeTitle) private var longQuestionSize: CGFloat = 32
    @ScaledMetric(relativeTo: .largeTitle) private var shortQuestionSize: CGFloat = 88
    @ScaledMetric(relativeTo: .body) private var explanationSize: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var pairSpacing: CGFloat = 24

    var body: some View {
        let pair = OnkunText(question, category: category)
        let parts = QuestionTextParts(pair?.text ?? question)
        VStack(spacing: 16) {
            if let pair {
                VStack(spacing: pairSpacing) {
                    ForEach(pair.groups.indices, id: \.self) { index in
                        Text(pair.groups[index]).font(studyFont.font(size: questionSize))
                    }
                }
            } else {
                StudyGlyphs.text(parts.main, size: parts.main.count <= 2 ? shortQuestionSize : parts.main.count >= 16 ? longQuestionSize : questionSize)
                    .font(studyFont.font(size: parts.main.count <= 2 ? shortQuestionSize : parts.main.count >= 16 ? longQuestionSize : questionSize))
                if let explanation = parts.explanation {
                    Text(explanation)
                        .font(studyFont.font(size: explanationSize))
                        .lineSpacing(4)
                }
            }
        }
        .padding(.horizontal, 12)
        .lineSpacing(6)
        .lineLimit(nil)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}
