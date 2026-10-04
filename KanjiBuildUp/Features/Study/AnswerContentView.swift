import SwiftUI

/// Give the answer a central focus while keeping definitions and notes below it.
struct AnswerContentView: View {
    let item: StudyItem
    let availableHeight: CGFloat
    @ScaledMetric(relativeTo: .largeTitle) private var answerSize = 56
    @ScaledMetric(relativeTo: .body) private var bodySize = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 8) {
                Text("答え").font(.caption).foregroundStyle(Palette.secondary)
                Text(item.answer).font(.system(size: answerSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                    .accessibilityIdentifier("studyAnswer")
            }
            .frame(maxWidth: .infinity, minHeight: max(140, availableHeight * 0.5))
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("意味").font(.subheadline.weight(.semibold))
                Text(item.meaning.isEmpty ? "意味は登録されていません。" : item.meaning)
                    .font(.system(size: bodySize)).lineSpacing(3).textSelection(.enabled)
                    .accessibilityIdentifier("studyMeaning")
            }
            if !item.notes.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("メモ").font(.subheadline.weight(.semibold))
                    Text(item.notes).font(.system(size: bodySize)).textSelection(.enabled)
                        .accessibilityIdentifier("studyNotes")
                }
            }
        }
    }
}
