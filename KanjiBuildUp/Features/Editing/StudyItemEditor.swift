import SwiftUI

struct StudyItemEditor: View {
    private enum Field: Hashable { case category, question, answer, meaning, notes }
    let store: LearningStore
    let original: StudyItem?
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var category = ""
    @State private var question = ""
    @State private var answer = ""
    @State private var meaning = ""
    @State private var notes = ""
    @State private var mastery: Mastery = .starting
    @State private var errorMessage: String?
    @State private var confirmDiscard = false
    @FocusState private var focusedField: Field?

    init(store: LearningStore, item: StudyItem? = nil, onSave: @escaping () -> Void) {
        self.store = store
        self.original = item
        self.onSave = onSave
        _category = State(initialValue: item?.category ?? "")
        _question = State(initialValue: item?.question ?? "")
        _answer = State(initialValue: item?.answer ?? "")
        _meaning = State(initialValue: item?.meaning ?? "")
        _notes = State(initialValue: item?.notes ?? "")
        _mastery = State(initialValue: item?.mastery ?? .starting)
    }

    private var categories: [String] {
        let defaults = ["当て字", "書き", "音読み", "訓読み", "ことわざ", "四字熟語"]
        return defaults + store.categories.filter { !defaults.contains($0) }
    }
    private func trimmed(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { [category, question, answer].allSatisfy { !trimmed($0).isEmpty } }
    private var hasChanges: Bool {
        category != (original?.category ?? "") || question != (original?.question ?? "") ||
        answer != (original?.answer ?? "") || meaning != (original?.meaning ?? "") ||
        notes != (original?.notes ?? "") || mastery != (original?.mastery ?? .starting)
    }

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
                Section("備考（任意）") {
                    TextField("覚え方や補足を入力", text: $notes, axis: .vertical)
                        .focused($focusedField, equals: .notes)
                        .lineLimit(3...8).accessibilityIdentifier("itemNotes")
                }
                if original != nil {
                    Section("覚え具合") {
                        Picker("覚え具合", selection: $mastery) {
                            ForEach(Mastery.allCases) { value in Text(value.title).tag(value) }
                        }
                    }
                }
                if original == nil {
                    Section {
                        Label("「がんばるぞ」からスタートします。", systemImage: "info.circle")
                            .font(.subheadline).foregroundStyle(Palette.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Palette.background)
            .navigationTitle(original == nil ? "手入力で追加" : "問題を編集")
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
                    Button(original == nil ? "追加" : "保存") {
                        guard canSave else { return }
                        var item = original ?? StudyItem(category: "", question: "", answer: "", meaning: "")
                        item.category = trimmed(category)
                        item.question = trimmed(question)
                        item.answer = trimmed(answer)
                        item.meaning = trimmed(meaning)
                        item.notes = trimmed(notes)
                        item.mastery = mastery
                        let saved = original == nil ? store.add([item]) : store.update(item)
                        if saved { onSave(); dismiss() }
                        else { errorMessage = store.errorMessage; store.errorMessage = nil }
                    }.fontWeight(.semibold).disabled(!canSave).accessibilityIdentifier(original == nil ? "saveManualEntry" : "saveItem")
                }
            }
        }.tint(Palette.green).foregroundStyle(Palette.ink).preferredColorScheme(.light)
            .interactiveDismissDisabled(hasChanges)
            .confirmationDialog("入力内容を破棄しますか？", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("入力を破棄", role: .destructive) { dismiss() }
                Button("入力を続ける", role: .cancel) { }
            }
            .alert("保存できませんでした", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("閉じる", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
    }
}
