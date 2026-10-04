import SwiftUI

struct StudyListView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var store = LearningStore()
    @State private var category: String?
    @State private var mastery: Mastery?
    @State private var showImport = false
    @State private var showManualEntry = false
    @State private var session: StudySession?
    @State private var notice: String?
    @State private var headerCollapse: CGFloat = 0
    @ScaledMetric(relativeTo: .title) private var headerTitleSize = 28
    @State private var studyActionHeight: CGFloat = 96
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
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("漢字一覧").font(.system(size: headerTitleSize - 6 * headerCollapse, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if !dynamicTypeSize.isAccessibilitySize {
                            CompanionImage(name: "CompanionSeaLion", size: 120 - 68 * headerCollapse)
                                .offset(y: 4 * (1 - headerCollapse))
                                .frame(width: 128 - 68 * headerCollapse, height: 112 - 60 * headerCollapse)
                        }
                    }
                    .frame(minHeight: 56)
                    .background {
                        HeaderWave().fill(Palette.header)
                            .padding(.horizontal, -20)
                            .overlay(alignment: .top) {
                                Palette.header.frame(height: 150)
                                    .padding(.horizontal, -20).offset(y: -150)
                            }
                            .allowsHitTesting(false)
                    }
                    Picker("カテゴリー", selection: $category) {
                        Text("すべてのカテゴリー").tag(String?.none)
                        ForEach(store.categories, id: \.self) { value in Text(value).tag(Optional(value)) }
                    }
                    .pickerStyle(.menu).accessibilityIdentifier("categoryFilter")
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                masteryFilters.padding(.bottom, 4)
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
                        .listRowBackground(Color.clear)
                    }.listStyle(.plain).scrollContentBackground(.hidden)
                        .modifier(LibraryScrollHeaderModifier(collapse: $headerCollapse))
                        .overlay {
                            if filtered.isEmpty {
                                ContentUnavailableView("該当する問題はありません", systemImage: "line.3.horizontal.decrease", description: Text("カテゴリーや覚え具合を変更してください。"))
                            }
                        }
                        .listRowSpacing(4)
                        .contentMargins(.top, 4, for: .scrollContent)
                        .contentMargins(.bottom, studyActionHeight + 24)
                        .mask {
                            VStack(spacing: 0) {
                                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 8)
                                Rectangle().fill(.black)
                            }
                        }
                }
            }.padding(.horizontal, 20).frame(maxWidth: 640).frame(maxWidth: .infinity)
                .background(Palette.pageGradient.ignoresSafeArea())
                .floatingFooter(height: $studyActionHeight) {
                    PrimaryButton(title: "問題をはじめる", enabled: !filtered.isEmpty) {
                        session = StudySession(items: filtered)
                    }
                    .accessibilityIdentifier("startStudy")
                    .shadow(color: Palette.green.opacity(0.18), radius: 16, x: 0, y: 6)
                }
                .navigationTitle("")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .companionNavigationBar()
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
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) { filterButtons }
                }
            } else {
                HStack(spacing: 6) { filterButtons }
            }
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
            VStack(spacing: 5) {
                Text(title).font(.system(size: 13, weight: .semibold))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(count, format: .number).font(.system(size: 20, weight: .bold))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? .white : value?.tint ?? Palette.green)
            .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 140 : nil,
                   maxWidth: .infinity, minHeight: 54)
        }
        .controlSize(.small)
        .appGlassButton(prominent: selected)
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .tint(value?.tint ?? Palette.green)
        .accessibilityLabel(Text(verbatim: "\(title)、\(count)件"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct LibraryScrollHeaderModifier: ViewModifier {
    @Binding var collapse: CGFloat
    @State private var userIsScrolling = false

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18, macOS 15, visionOS 2, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geometry in
                min(1, max(0, (geometry.contentOffset.y + geometry.contentInsets.top) / 80))
            } action: { _, progress in
                if userIsScrolling { collapse = progress }
            }
            .onScrollPhaseChange { _, phase, context in
                let wasScrolling = userIsScrolling
                userIsScrolling = phase == .interacting || phase == .decelerating
                if userIsScrolling || wasScrolling {
                    collapse = min(1, max(0, (context.geometry.contentOffset.y + context.geometry.contentInsets.top) / 80))
                }
            }
        } else {
            // Earlier systems retain the expanded header and native List scrolling.
            content
        }
    }
}

#Preview { StudyListView() }
