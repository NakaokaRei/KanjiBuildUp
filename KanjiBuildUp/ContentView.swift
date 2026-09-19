import SwiftUI
import UniformTypeIdentifiers

private enum Palette {
    static let background = Color(red: 0.993, green: 0.993, blue: 0.985)
    static let green = Color(red: 0.22, green: 0.39, blue: 0.33)
    static let ink = Color(red: 0.10, green: 0.16, blue: 0.16)
    static let secondary = Color(red: 0.34, green: 0.41, blue: 0.41)
    static let softGreen = Color(red: 0.93, green: 0.96, blue: 0.93)
}

private extension Mastery {
    var tint: Color {
        switch self {
        case .starting: Color(red: 0.51, green: 0.35, blue: 0.10)
        case .learning: Color(red: 0.12, green: 0.34, blue: 0.56)
        case .mastered: Color(red: 0.16, green: 0.43, blue: 0.30)
        }
    }
    var background: Color {
        switch self {
        case .starting: Color(red: 1, green: 0.95, blue: 0.84)
        case .learning: Color(red: 0.89, green: 0.94, blue: 0.99)
        case .mastered: Color(red: 0.89, green: 0.97, blue: 0.91)
        }
    }
}

private struct PrimaryButton: View {
    let title: String
    var enabled = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 18)
                .foregroundStyle(.white)
                .background(enabled ? Palette.green : Palette.secondary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        }.buttonStyle(.plain).disabled(!enabled)
    }
}

private struct MasteryBadge: View {
    let mastery: Mastery
    var body: some View {
        Text(mastery.title).font(.subheadline.weight(.semibold))
            .foregroundStyle(mastery.tint).padding(.horizontal, 12).padding(.vertical, 8)
            .background(mastery.background, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct ContentView: View {
    @State private var store = LearningStore()
    @State private var category: String?
    @State private var mastery: Mastery?
    @State private var showImport = false
    @State private var showManualEntry = false
    @State private var session: StudySession?
    @State private var notice: String?
    private var filtered: [StudyItem] { store.filtered(category: category, mastery: mastery) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("漢字一覧").font(.largeTitle.bold())
                    Spacer()
                    Menu {
                        Button { showManualEntry = true } label: {
                            Label("手入力で追加", systemImage: "square.and.pencil")
                        }.accessibilityIdentifier("manualEntry")
                        Button { showImport = true } label: {
                            Label("CSV取り込み", systemImage: "doc.text")
                        }.accessibilityIdentifier("importCSV")
                    } label: {
                        Label("追加", systemImage: "plus").font(.headline).padding(.vertical, 10)
                    }.accessibilityIdentifier("addItem")
                }.padding(.bottom, 24)
                if let notice {
                    HStack {
                        Text(notice).font(.subheadline)
                        Spacer()
                        Button { self.notice = nil } label: { Image(systemName: "xmark").padding(8) }
                            .accessibilityLabel("取り込み通知を閉じる")
                    }.foregroundStyle(Palette.green).padding(12)
                        .background(Palette.softGreen, in: RoundedRectangle(cornerRadius: 10)).padding(.bottom, 12)
                }
                Menu {
                    Button("すべてのカテゴリー") { category = nil }
                    ForEach(store.categories, id: \.self) { value in Button(value) { category = value } }
                } label: {
                    HStack { Text(category ?? "すべてのカテゴリー"); Spacer(); Image(systemName: "chevron.down") }
                        .padding(14).overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.3)))
                }.foregroundStyle(Palette.ink).padding(.bottom, 16)
                masteryFilters.padding(.bottom, 14)
                if store.items.isEmpty {
                    Spacer()
                    ContentUnavailableView {
                        Label("学習する漢字を追加", systemImage: "book.closed")
                    } description: {
                        Text("手入力やCSV取り込みで、\n自分だけの漢字帳をつくりましょう。")
                    } actions: {
                        Button("手入力で追加") { showManualEntry = true }.buttonStyle(.bordered)
                        Button("CSVを取り込む") { showImport = true }.buttonStyle(.bordered)
                    }
                    Spacer()
                } else if filtered.isEmpty {
                    Spacer()
                    ContentUnavailableView("該当する問題はありません", systemImage: "line.3.horizontal.decrease", description: Text("カテゴリーや覚え具合を変更してください。"))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filtered) { item in
                                Button { session = StudySession(items: [item], review: true) } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(item.question).font(.title3.bold()).multilineTextAlignment(.leading)
                                            Text(item.category).font(.caption).foregroundStyle(Palette.secondary)
                                        }
                                        Spacer(minLength: 4)
                                        MasteryBadge(mastery: item.mastery)
                                        Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                                    }.frame(maxWidth: .infinity, minHeight: 66).padding(.vertical, 4).contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityHint("答えと意味を確認します")
                                Divider()
                            }
                        }
                    }
                    Text("項目をタップして答えを確認。").font(.footnote).foregroundStyle(Palette.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                }
                VStack(spacing: 10) {
                    PrimaryButton(title: "問題をはじめる", enabled: !filtered.isEmpty) {
                        session = StudySession(items: filtered)
                    }.accessibilityIdentifier("startStudy")
                    Text("選択した範囲からランダムに出題。").font(.caption).foregroundStyle(Palette.secondary)
                }.padding(.top, 14)
            }.padding(20).frame(maxWidth: 640).frame(maxWidth: .infinity)
                .background(Palette.background.ignoresSafeArea())
                .toolbar(.hidden)
                .navigationDestination(item: $session) { initial in
                    StudyView(store: store, session: initial)
                }
        }
        .tint(Palette.green).foregroundStyle(Palette.ink).preferredColorScheme(.light)
        .sheet(isPresented: $showImport) {
            ImportView(store: store) { count in
                category = nil; mastery = nil
                notice = "\(count)件を取り込みました。"
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(store: store) {
                category = nil; mastery = nil
                notice = "1件を追加しました。"
            }
        }
        .alert("データを保存できません", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("閉じる", role: .cancel) { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }

    private var masteryFilters: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { filterButtons }
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { filterButtons } }
        }
    }
    @ViewBuilder private var filterButtons: some View {
        filterButton(nil, title: "すべて")
        ForEach(Mastery.allCases) { value in filterButton(value, title: value.title) }
    }
    private func filterButton(_ value: Mastery?, title: String) -> some View {
        let selected = mastery == value
        let count = store.filtered(category: category, mastery: value).count
        return Button { mastery = value } label: {
            VStack(spacing: 6) {
                Text(title).font(.system(size: 13, weight: .semibold)).fixedSize()
                Text("\(count)").font(.headline).monospacedDigit()
            }.frame(maxWidth: .infinity).padding(.horizontal, 8).padding(.vertical, 12)
                .foregroundStyle(selected ? .white : value?.tint ?? Palette.ink)
                .background(selected ? Palette.green : value?.background ?? Palette.softGreen, in: RoundedRectangle(cornerRadius: 10))
        }.buttonStyle(.plain).accessibilityLabel("\(title)、\(count)件")
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct StudyView: View {
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

private struct ImportView: View {
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

#Preview { ContentView() }

private struct ManualEntryView: View {
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
