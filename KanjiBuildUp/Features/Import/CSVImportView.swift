import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    let store: LearningStore
    let onImport: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false
    @State private var entries: [StudyItem] = []
    @State private var fileName = ""
    @State private var errorMessage: String?
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("CSV取り込み").font(.largeTitle.bold())
                    Spacer()
                    Button("閉じる") { dismiss() }.font(.subheadline)
                }.padding(.bottom, 24)
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("CSVから学習する漢字を追加します。")
                        previewTable
                        Button { showPicker = true } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "doc.text").font(.title)
                                Text("CSVファイルを選ぶ").font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }.padding(18).background(Palette.softGreen, in: RoundedRectangle(cornerRadius: 10))
                        }.buttonStyle(.plain)
                        if !entries.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("選択されたファイル").font(.subheadline)
                                HStack { Text(fileName).font(.headline); Spacer(); Text("\(entries.count)件") }
                            }
                        }
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill").font(.title3)
                            Text("取り込んだ漢字はすべて\n「がんばるぞ」からスタートします。")
                                .font(.subheadline).lineSpacing(5)
                        }.foregroundStyle(Palette.green).padding(18).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.softGreen, in: RoundedRectangle(cornerRadius: 10))
                        Text("UTF-8・Shift JISに対応。既存の問題に追加されます。同じCSVを再度取り込むと、問題も追加されます。")
                            .font(.footnote).foregroundStyle(Palette.secondary).lineSpacing(4)
                    }
                }
                PrimaryButton(title: entries.isEmpty ? "ファイルを選択してください" : "\(entries.count)件を取り込む", enabled: !entries.isEmpty) {
                    if store.add(entries) { onImport(entries.count); dismiss() }
                    else { errorMessage = store.errorMessage; store.errorMessage = nil }
                }.padding(.top, 20)
            }.padding(24).frame(maxWidth: 640).frame(maxWidth: .infinity)
                .background(Palette.background.ignoresSafeArea()).toolbar(.hidden)
        }.tint(Palette.green).foregroundStyle(Palette.ink).preferredColorScheme(.light)
            .onAppear {
                #if DEBUG
                // Deterministic UI-test fixture for the preview/commit path; file access is tested separately.
                if let csv = ProcessInfo.processInfo.environment["KANJI_TEST_CSV"], entries.isEmpty {
                    do { entries = try KanjiCSV.parse(csv); fileName = "kanji.csv" }
                    catch { errorMessage = error.localizedDescription }
                }
                #endif
            }
            .fileImporter(isPresented: $showPicker, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
                switch result {
                case .success(let url):
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    do {
                        let data = try Data(contentsOf: url)
                        entries = try KanjiCSV.decode(data); fileName = url.lastPathComponent
                    } catch { entries = []; fileName = ""; errorMessage = error.localizedDescription }
                case .failure(let error): errorMessage = error.localizedDescription
                }
            }
            .alert("取り込みを確認してください", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("閉じる", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
    }
    private var previewTable: some View {
        let example = entries.first ?? StudyItem(category: "読み", question: "桜", answer: "さくら", meaning: "春に花を咲かせる木")
        return VStack(alignment: .leading, spacing: 8) {
            if !entries.isEmpty { Text("取り込み内容のプレビュー（先頭1件）").font(.caption).foregroundStyle(Palette.secondary) }
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow { ForEach(KanjiCSV.header, id: \.self) { title in
                    Text(title).font(.system(size: 12, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 14)
                } }.background(Palette.softGreen)
                GridRow { ForEach(Array([example.category, example.question, example.answer, example.meaning].enumerated()), id: \.offset) { _, text in
                    Text(text).font(.system(size: 13)).lineLimit(4).frame(maxWidth: .infinity).padding(8)
                } }
            }.overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray.opacity(0.25)))
        }
    }
}
