import SwiftUI
#if os(iOS)
import UIKit
#endif

extension View {
    func studyTextCopy(_ text: String, title: String) -> some View {
        modifier(StudyTextCopyModifier(text: text, title: title))
    }
}

private struct StudyTextCopyModifier: ViewModifier {
    let text: String
    let title: String
    @State private var showingSelection = false

    @ViewBuilder func body(content: Content) -> some View {
        #if os(iOS)
        content
            .contextMenu {
                Button("コピー", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = text
                }
                Button("一部を選択してコピー", systemImage: "selection.pin.in.out") {
                    showingSelection = true
                }
            }
            .accessibilityAction(named: Text("一部を選択してコピー")) {
                showingSelection = true
            }
            .sheet(isPresented: $showingSelection) {
                StudyTextSelectionSheet(text: text, title: title)
            }
        #else
        content.textSelection(.enabled)
        #endif
    }
}

#if os(iOS)
private struct StudyTextSelectionSheet: View {
    let text: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var selection = ""
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("文字を長押しして、選択ハンドルでコピーする範囲を調整してください。")
                    .font(.footnote).foregroundStyle(.secondary)
                SelectableStudyText(text: text, selection: $selection)
                    .accessibilityIdentifier("copySelectionText")
                Button {
                    UIPasteboard.general.string = selection
                    copied = true
                } label: {
                    Text(copied ? "コピーしました" : "選択した部分をコピー")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selection.isEmpty)
                .accessibilityIdentifier("copySelectedText")
            }
            .padding()
            .navigationTitle("\(title)を選択してコピー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
            .onChange(of: selection) { _, _ in copied = false }
        }
        .tint(Palette.green)
    }
}

/// UITextView provides selection handles on iPhone without allowing edits or a keyboard.
private struct SelectableStudyText: UIViewRepresentable {
    let text: String
    @Binding var selection: String

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = true
        view.backgroundColor = .clear
        view.font = .preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.textColor = .label
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.delegate = context.coordinator
        view.text = text
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        // Do not replace unchanged text: that would reset the user's selection.
        if view.text != text {
            view.text = text
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let selection: Binding<String>

        init(selection: Binding<String>) { self.selection = selection }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard let range = textView.selectedTextRange else {
                selection.wrappedValue = ""
                return
            }
            selection.wrappedValue = textView.text(in: range) ?? ""
        }
    }
}
#endif
