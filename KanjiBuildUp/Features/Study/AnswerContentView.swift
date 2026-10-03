import SwiftUI

/// Keep the answer compact so definitions and notes get most of the available space.
struct AnswerContentView: View {
    let item: StudyItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("問題").font(.caption).foregroundStyle(Palette.secondary)
                Text(item.question).font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.secondary).textSelection(.enabled)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("答え").font(.caption).foregroundStyle(Palette.secondary)
                Text(item.answer).font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("意味").font(.subheadline.weight(.semibold))
                Text(item.meaning.isEmpty ? "意味は登録されていません。" : item.meaning)
                    .font(.body).lineSpacing(3).textSelection(.enabled)
                    .accessibilityIdentifier("studyMeaning")
            }
            if !item.notes.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("メモ").font(.subheadline.weight(.semibold))
                    Text(item.notes).font(.body).textSelection(.enabled)
                        .accessibilityIdentifier("studyNotes")
                }
            }
        }
    }
}
