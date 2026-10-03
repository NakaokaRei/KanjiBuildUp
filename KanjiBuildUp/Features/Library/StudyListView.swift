import SwiftUI

struct StudyListView: View {
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
                if let notice {
                    HStack {
                        Text(notice).font(.subheadline)
                        Spacer()
                        Button { self.notice = nil } label: { Image(systemName: "xmark").padding(8) }
                            .accessibilityLabel("取り込み通知を閉じる")
                    }.foregroundStyle(Palette.green).padding(12)
                        .background(Palette.softGreen, in: RoundedRectangle(cornerRadius: 10)).padding(.bottom, 12)
                }
                Picker("カテゴリー", selection: $category) {
                    Text("すべてのカテゴリー").tag(String?.none)
                    ForEach(store.categories, id: \.self) { value in Text(value).tag(Optional(value)) }
                }
                .pickerStyle(.menu).accessibilityIdentifier("categoryFilter")
                .padding(.bottom, 12)
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
                    List(filtered) { item in
                        NavigationLink(value: StudySession(items: [item], review: true)) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(item.question).font(.title3.bold()).multilineTextAlignment(.leading)
                                    Text(item.category).font(.caption).foregroundStyle(Palette.secondary)
                                }
                                Spacer(minLength: 4)
                                MasteryBadge(mastery: item.mastery)
                            }.frame(maxWidth: .infinity, minHeight: 66).padding(.vertical, 4).contentShape(Rectangle())
                        }.accessibilityHint("答えと意味を確認します")
                    }.listStyle(.plain).scrollContentBackground(.hidden)
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
                .navigationTitle("漢字一覧")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
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
                    }
                }
                .navigationDestination(for: StudySession.self) { value in
                    StudyView(store: store, session: value)
                }
                .navigationDestination(item: $session) { initial in
                    StudyView(store: store, session: initial)
                }
        }
        .tint(Palette.green).foregroundStyle(Palette.ink).preferredColorScheme(.light)
        .sheet(isPresented: $showImport) {
            CSVImportView(store: store) { count in
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
            VStack(spacing: 4) {
                Text(title).font(.subheadline).fixedSize()
                Text("\(count)").font(.headline).monospacedDigit()
            }.frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(selected ? Palette.green : .secondary)
        .accessibilityLabel(Text(verbatim: "\(title)、\(count)件"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview { StudyListView() }
