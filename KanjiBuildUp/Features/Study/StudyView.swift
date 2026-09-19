import SwiftUI

struct StudyView: View {
    let store: LearningStore
    @State var session: StudySession
    @Environment(\.dismiss) private var dismiss
    private var item: StudyItem? { session.currentID.flatMap(store.item) }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { dismiss() } label: { Label("一覧に戻る", systemImage: "chevron.left") }
                .font(.body.weight(.medium)).padding(.bottom, 24)
            if session.complete {
                Spacer()
                VStack(spacing: 18) {
                    Image(systemName: "checkmark.circle").font(.system(size: 54)).foregroundStyle(Palette.green)
                    Text("おつかれさまでした").font(.title2.bold())
                    Text("\(session.itemIDs.count)問の学習が終わりました。\n覚え具合は保存されています。")
                        .multilineTextAlignment(.center).foregroundStyle(Palette.secondary)
                }.frame(maxWidth: .infinity)
                Spacer()
                PrimaryButton(title: "一覧に戻る") { dismiss() }
            } else if let item {
                HStack {
                    Text(item.category).font(.headline)
                    Spacer()
                    if !session.isReview { Text("\(session.index + 1) / \(session.itemIDs.count)").monospacedDigit() }
                }.padding(.bottom, 16)
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if session.revealed {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("問題").font(.subheadline).foregroundStyle(Palette.secondary)
                                Text(item.question).font(.system(size: 32, weight: .bold)).foregroundStyle(Palette.secondary)
                                    .textSelection(.enabled)
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 16) {
                                Text("答え").font(.subheadline)
                                Text(item.answer).font(.system(size: item.answer.count <= 5 ? 80 : 34, weight: .bold))
                                    .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                            }.padding(.vertical, 6)
                            Divider()
                            VStack(alignment: .leading, spacing: 12) {
                                Text("意味").font(.subheadline)
                                Text(item.meaning.isEmpty ? "意味は登録されていません。" : item.meaning)
                                    .font(.body).lineSpacing(6).textSelection(.enabled)
                            }
                        } else {
                            Text(item.category == "読み" ? "この漢字の読みは？" : "答えを考えてみましょう")
                                .font(.title3.bold()).frame(maxWidth: .infinity).padding(.top, 30)
                            Text(item.question).font(.system(size: item.question.count <= 2 ? 144 : 44, weight: .bold))
                                .multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 240)
                                .padding(.vertical, 16).accessibilityIdentifier("questionText")
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 26)
                }.id("\(session.index)-\(session.revealed)")
                if session.revealed {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("覚え具合を選ぶ").font(.subheadline)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 8) { masteryButtons(item) }
                            VStack(spacing: 8) { masteryButtons(item) }
                        }
                    }.padding(.top, 16).padding(.bottom, 20)
                    PrimaryButton(title: session.isReview ? "一覧に戻る" : session.index + 1 == session.itemIDs.count ? "学習を終える" : "次の問題") {
                        if session.isReview { dismiss() } else { session.advance() }
                    }
                } else {
                    MasteryBadge(mastery: item.mastery).frame(maxWidth: .infinity).padding(.bottom, 24)
                    PrimaryButton(title: "答えを見る") { session.revealed = true }.accessibilityIdentifier("revealAnswer")
                }
            }
        }.padding(24).frame(maxWidth: 640).frame(maxWidth: .infinity)
            .background(Palette.background.ignoresSafeArea()).toolbar(.hidden)
    }
    @ViewBuilder private func masteryButtons(_ item: StudyItem) -> some View {
        ForEach(Mastery.allCases) { value in
            let selected = item.mastery == value
            Button { store.setMastery(value, for: item.id) } label: {
                VStack(spacing: 8) {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle").font(.title2)
                    Text(value.title).font(.system(size: 14, weight: .semibold)).fixedSize()
                }.frame(maxWidth: .infinity).padding(.horizontal, 8).padding(.vertical, 12)
                    .foregroundStyle(value.tint).background(value.background, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? value.tint : .clear, lineWidth: 1))
            }.buttonStyle(.plain).accessibilityLabel(value.title).accessibilityAddTraits(selected ? .isSelected : [])
        }
    }
}
