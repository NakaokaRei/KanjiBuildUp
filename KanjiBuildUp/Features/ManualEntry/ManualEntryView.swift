import SwiftUI

struct ManualEntryView: View {
    private enum Field: Hashable { case category, question, answer, meaning }
    let store: LearningStore
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var category = ""
    @State private var question = ""
    @State private var answer = ""
    @State private var meaning = ""
    @State private var errorMessage: String?
    @State private var confirmDiscard = false
    @FocusState private var focusedField: Field?

    private var categories: [String] {
        let defaults = ["当て字", "書き", "音読み", "訓読み", "ことわざ", "四字熟語"]
        return defaults + store.categories.filter { !defaults.contains($0) }
    }
    private func trimmed(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canAdd: Bool { [category, question, answer].allSatisfy { !trimmed($0).isEmpty } }
    private var hasChanges: Bool { [category, question, answer, meaning].contains { !$0.isEmpty } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("例：訓読み", text: $category).focused($focusedField, equals: .category)
                        .accessibilityLabel("カテゴリー").accessibilityIdentifier("manualCategory")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], alignment: .leading) {
                        ForEach(categories, id: \.self) { value in
                            Button(value) { category = value }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("categorySuggestion-\(value)")
                        }
                    }
                } header: { Text("カテゴリー（必須）") }
                footer: { Text("既存のカテゴリーを選ぶか、新しい名前を入力できます。") }

                Section("問題（必須）") {
                    TextField("例：桜", text: $question, axis: .vertical)
                        .focused($focusedField, equals: .question)
                        .lineLimit(2...6).accessibilityLabel("問題").accessibilityIdentifier("manualQuestion")
                }
                Section("答え（必須）") {
                    TextField("例：さくら", text: $answer, axis: .vertical)
                        .focused($focusedField, equals: .answer)
                        .lineLimit(2...6).accessibilityLabel("答え").accessibilityIdentifier("manualAnswer")
                }
                Section("意味（任意）") {
                    TextField("例：春に花を咲かせる木。", text: $meaning, axis: .vertical)
                        .focused($focusedField, equals: .meaning)
                        .lineLimit(3...8).accessibilityLabel("意味").accessibilityIdentifier("manualMeaning")
                }
                Section {
                    Label("「がんばるぞ」からスタートします。", systemImage: "info.circle")
                        .font(.subheadline).foregroundStyle(Palette.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(Palette.background)
            .navigationTitle("手入力で追加")
            .toolbar {
                #if os(iOS)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("入力を完了") { focusedField = nil }
                }
                #endif
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        if hasChanges { confirmDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        guard canAdd else { return }
                        let item = StudyItem(category: trimmed(category), question: trimmed(question), answer: trimmed(answer), meaning: trimmed(meaning))
                        if store.add([item]) { onAdd(); dismiss() }
                        else { errorMessage = store.errorMessage; store.errorMessage = nil }
                    }.fontWeight(.semibold).disabled(!canAdd).accessibilityIdentifier("saveManualEntry")
                }
            }
        }.tint(Palette.green).foregroundStyle(Palette.ink).preferredColorScheme(.light)
            .interactiveDismissDisabled(hasChanges)
            .confirmationDialog("入力内容を破棄しますか？", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("入力を破棄", role: .destructive) { dismiss() }
                Button("入力を続ける", role: .cancel) { }
            }
            .alert("追加できませんでした", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("閉じる", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
    }
}
