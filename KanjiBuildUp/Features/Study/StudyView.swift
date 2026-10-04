import SwiftUI

struct StudyView: View {
    let store: LearningStore
    @State var session: StudySession
    @State private var editingItem: StudyItem?
    @State private var confirmDelete = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    private var item: StudyItem? { session.currentID.flatMap(store.item) }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    if !session.isReview {
                        Button("前の問題", systemImage: "arrow.left") { session.goBack() }
                            .font(.subheadline)
                            .appGlassButton()
                            .tint(Palette.green)
                            .disabled(!session.canGoBack)
                            .accessibilityIdentifier("previousQuestion")
                        Text("\(session.index + 1) / \(session.itemIDs.count)").monospacedDigit()
                    }
                }.padding(.bottom, 10)
                Divider()
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .leading, spacing: session.revealed ? 12 : 22) {
                            if session.revealed {
                                AnswerContentView(item: item, availableHeight: geometry.size.height)
                            } else {
                                Text(["読み", "音読み", "訓読み", "当て字"].contains(item.category) ? "この漢字の読みは？" : "答えを考えてみましょう")
                                    .font(.title3.bold()).frame(maxWidth: .infinity).padding(.top, 30)
                                Text(item.question).font(.system(size: 44, weight: .bold))
                                    .multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 240)
                                    .padding(.vertical, 16).accessibilityIdentifier("questionText")
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, session.revealed ? 12 : 26)
                    }.id("\(session.index)-\(session.revealed)")
                }
                if session.revealed {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("覚え具合を選ぶ").font(.subheadline)
                        HStack(spacing: 8) { masteryButtons(item) }
                    }.padding(.top, 8).padding(.bottom, 12)
                    PrimaryButton(title: session.isReview ? "一覧に戻る" : session.index + 1 == session.itemIDs.count ? "学習を終える" : "次の問題") {
                        if session.isReview { dismiss() } else { session.advance() }
                    }
                } else {
                    MasteryBadge(mastery: item.mastery).frame(maxWidth: .infinity).padding(.bottom, 24)
                    PrimaryButton(title: "答えを見る") { session.revealed = true }.accessibilityIdentifier("revealAnswer")
                }
            }
        }.padding(.horizontal, 20).padding(.vertical, 12).frame(maxWidth: 640).frame(maxWidth: .infinity)
            .background(Palette.pageGradient.ignoresSafeArea())
            .navigationTitle(session.complete ? "学習完了" : session.revealed ? "答え" : "問題")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if let item, !session.complete {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button("編集", systemImage: "pencil") { editingItem = item }
                                .accessibilityIdentifier("editItem")
                            Button("削除", systemImage: "trash", role: .destructive) { confirmDelete = true }
                                .accessibilityIdentifier("deleteItem")
                        } label: { Image(systemName: "ellipsis.circle") }
                        .accessibilityLabel("問題の操作").accessibilityIdentifier("itemActions")
                    }
                }
            }
            .sheet(item: $editingItem) { value in
                StudyItemEditor(store: store, item: value) { }
            }
            .confirmationDialog("この漢字を削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("削除する", role: .destructive) {
                    guard let item else { return }
                    if store.delete(item.id) { dismiss() }
                    else { errorMessage = store.errorMessage; store.errorMessage = nil }
                }
            } message: { Text("削除すると元に戻せません。削除後は一覧に戻ります。") }
            .alert("削除できませんでした", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("閉じる", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
    }
    @ViewBuilder private func masteryButtons(_ item: StudyItem) -> some View {
        ForEach(Mastery.allCases) { value in
            Button {
                store.setMastery(value, for: item.id)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: item.mastery == value ? "checkmark.circle.fill" : "circle")
                        .font(.body)
                    Text(value.title).font(.subheadline.weight(.semibold))
                        .lineLimit(1).minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 46)
                .foregroundStyle(item.mastery == value ? .white : value.tint)
            }
            .appGlassButton(prominent: true)
            .buttonBorderShape(.roundedRectangle(radius: 16))
            .tint(item.mastery == value ? value.tint : value.background)
            .accessibilityLabel(value.title)
            .accessibilityAddTraits(item.mastery == value ? .isSelected : [])
        }
    }
}
