import SwiftUI

/// Give the answer a central focus while keeping definitions and notes below it.
struct AnswerContentView: View {
    let item: StudyItem
    let availableHeight: CGFloat
    @AppStorage("answerFont") private var answerFont: StudyFont = .gothic
    @ScaledMetric(relativeTo: .largeTitle) private var answerSize = 56
    @ScaledMetric(relativeTo: .body) private var bodySize = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 8) {
                Text("答え").font(.caption).foregroundStyle(Palette.secondary)
                Text(item.answer).font(answerFont.font(size: answerSize))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("studyAnswer")
                    .studyTextCopy(item.answer, title: "答え")
            }
            .frame(maxWidth: .infinity, minHeight: max(140, availableHeight * 0.5))
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("意味").font(.subheadline.weight(.semibold))
                Text(item.meaning.isEmpty ? "意味は登録されていません。" : item.meaning)
                    .font(.system(size: bodySize)).lineSpacing(3)
                    .accessibilityIdentifier("studyMeaning")
                    .studyTextCopy(item.meaning.isEmpty ? "意味は登録されていません。" : item.meaning, title: "意味")
            }
            if !item.notes.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("メモ").font(.subheadline.weight(.semibold))
                    Text(item.notes).font(.system(size: bodySize))
                        .accessibilityIdentifier("studyNotes")
                        .studyTextCopy(item.notes, title: "メモ")
                }
            }
        }
    }
}
