import SwiftUI

/// Keep the answer compact so definitions and notes get most of the available space.
struct AnswerContentView: View {
    let item: StudyItem
    @ScaledMetric(relativeTo: .largeTitle) private var answerSize = 48
    @ScaledMetric(relativeTo: .body) private var bodySize = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("問題").font(.caption).foregroundStyle(Palette.secondary)
                Text(item.question).font(.title2.weight(.semibold))
                    .foregroundStyle(Palette.secondary).textSelection(.enabled)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("答え").font(.caption).foregroundStyle(Palette.secondary)
                Text(item.answer).font(.system(size: answerSize, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            }
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
