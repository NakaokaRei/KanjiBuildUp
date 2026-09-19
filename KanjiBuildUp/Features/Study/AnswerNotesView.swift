import SwiftUI

/// Keeps note editing on the answer, separate from the question editor.
struct AnswerNotesView: View {
    let store: LearningStore
    let item: StudyItem
    @State private var isEditing = false
    @State private var draft = ""
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("備考").font(.subheadline)
            if isEditing {
                TextField("覚え方や補足を入力", text: $draft, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .accessibilityLabel("備考")
                    .accessibilityIdentifier("itemNotes")
                HStack {
                    Button("キャンセル") { isFocused = false; isEditing = false }
                        .buttonStyle(.bordered).accessibilityIdentifier("cancelNotes")
                    Button("保存", action: save)
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("saveNotes")
                }
            } else {
                if !item.notes.isEmpty {
                    Text(item.notes).textSelection(.enabled)
                        .accessibilityIdentifier("studyNotes")
                }
                Button(item.notes.isEmpty ? "備考を追加" : "備考を編集") {
                    draft = item.notes
                    isEditing = true
                }
                .buttonStyle(.bordered).accessibilityIdentifier("editNotes")
            }
        }
        #if os(iOS)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("入力を完了") { isFocused = false }
            }
        }
        #endif
        .alert("備考を保存できませんでした", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("閉じる", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func save() {
        // Read the latest record so changing notes never overwrites mastery or other edits.
        guard var updated = store.item(item.id) else {
            errorMessage = "この問題は削除されています。"
            return
        }
        updated.notes = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if store.update(updated) {
            isFocused = false
            isEditing = false
        } else {
            errorMessage = store.errorMessage
            store.errorMessage = nil
        }
    }
}
