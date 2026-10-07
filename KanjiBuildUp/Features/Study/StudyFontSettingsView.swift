import SwiftUI

struct StudyFontSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("questionFont") private var questionFont: StudyFont = .gothic
    @AppStorage("answerFont") private var answerFont: StudyFont = .gothic
    @ScaledMetric(relativeTo: .title) private var previewSize: CGFloat = 32

    var body: some View {
        NavigationStack {
            Form {
                Section("問題のフォント") {
                    fontPicker("問題", selection: $questionFont)
                        .accessibilityIdentifier("questionFontPicker")
                    Text("一期一会")
                        .font(questionFont.font(size: previewSize))
                        .accessibilityIdentifier("questionFontPreview")
                }
                Section("答えのフォント") {
                    fontPicker("答え", selection: $answerFont)
                        .accessibilityIdentifier("answerFontPicker")
                    Text("いちごいちえ")
                        .font(answerFont.font(size: previewSize))
                        .accessibilityIdentifier("answerFontPreview")
                }
                Section {
                    Text("問題のフォントは一覧・問題画面・答え画面に反映されます。設定は自動で保存されます。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("フォント設定")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
        .tint(Palette.green)
    }

    private func fontPicker(_ title: String, selection: Binding<StudyFont>) -> some View {
        Picker(title, selection: selection) {
            ForEach(StudyFont.allCases) { font in
                Text(font.title).tag(font)
            }
        }
        .pickerStyle(.menu)
        .accessibilityValue(selection.wrappedValue.title)
    }
}
