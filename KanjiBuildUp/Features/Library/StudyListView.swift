import SwiftUI

struct StudyListView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var actionsNamespace
    @State private var actionsCollapsed = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var store = LearningStore()
    @State private var search = ""
    @FocusState private var searchFocused: Bool
    @State private var category: String?
    @State private var mastery: Mastery?
    @State private var showImport = false
    @State private var showManualEntry = false
    @State private var showFontSettings = false
    @State private var session: StudySession?
    @State private var notice: String?
    @State private var headerCollapse: CGFloat = 0
    @ScaledMetric(relativeTo: .title) private var headerTitleSize = 28
    @ScaledMetric(relativeTo: .headline) private var compactActionWidth = 156
    @State private var studyActionHeight: CGFloat = 96
    @State private var searchResults = LearningStore.SearchResults()
    private var filtered: [StudyItem] { searchResults.items }

    private func refreshSearchResults() {
        searchResults = store.searchResults(category: category, mastery: mastery, search: search)
    }

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
                        Text("漢字一覧")
                            .font(.system(size: headerTitleSize - 6 * headerCollapse, weight: .bold))
                            .accessibilityAddTraits(.isHeader)
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
                searchField.padding(.bottom, 8)
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
                                    AdaptiveQuestionText(question: item.question, baseSize: 20, maximumSize: 24, progress: 1)
                                    Text(item.category).font(.caption).foregroundStyle(Palette.secondary)
                                    if searchResults.answerOnlyIDs.contains(item.id) {
                                        Text("答えに一致").font(.caption).foregroundStyle(Palette.secondary)
                                    }
                                }
                                Spacer(minLength: 4)
                                MasteryBadge(mastery: item.mastery)
                            }.frame(maxWidth: .infinity, minHeight: 66).padding(.vertical, 4).contentShape(Rectangle())
                        }.accessibilityHint("答えと意味を確認します")
                        .listRowBackground(Color.clear)
                    }.listStyle(.plain).scrollContentBackground(.hidden)
                        .scrollDismissesKeyboard(.interactively)
                        .modifier(LibraryScrollHeaderModifier(collapse: $headerCollapse, actionsCollapsed: $actionsCollapsed))
                        .overlay {
                            if filtered.isEmpty {
                                ContentUnavailableView("該当する問題はありません", systemImage: "line.3.horizontal.decrease", description: Text("検索語・カテゴリー・覚え具合を変更してください。"))
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
                .floatingFooter(height: $studyActionHeight, softensContent: false) {
                    libraryActions
                }
                .navigationTitle("")
                #if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
                #endif
                .navigationDestination(for: StudySession.self) { value in
                    StudyView(store: store, session: value)
                }
                .navigationDestination(item: $session) { initial in
                    StudyView(store: store, session: initial)
                }
        }
        .tint(Palette.green).foregroundStyle(Palette.ink).preferredColorScheme(.light)
        .onAppear { refreshSearchResults() }
        .onChange(of: search) { refreshSearchResults() }
        .onChange(of: category) { refreshSearchResults() }
        .onChange(of: mastery) { refreshSearchResults() }
        .onChange(of: store.items) { refreshSearchResults() }
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
        .sheet(isPresented: $showFontSettings) {
            StudyFontSettingsView()
        }
        .alert("データを保存できません", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("閉じる", role: .cancel) { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Palette.secondary)
            TextField("問題文・答えを検索", text: $search)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { searchFocused = false }
                .accessibilityIdentifier("questionSearch")
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").padding(6)
                }
                .accessibilityLabel("検索をクリア")
                .accessibilityIdentifier("clearQuestionSearch")
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder private var libraryActions: some View {
        #if os(iOS) || os(macOS)
        if #available(iOS 26, macOS 26, *) {
            GlassEffectContainer(spacing: 8) { libraryActionButtons }
        } else {
            libraryActionButtons
        }
        #else
        libraryActionButtons
        #endif
    }

    private var libraryActionButtons: some View {
        let compact = actionsCollapsed && !dynamicTypeSize.isAccessibilitySize
        return VStack(alignment: .trailing, spacing: 12) {
            Button {
                searchFocused = false
                showFontSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 24, weight: .medium))
                    .frame(width: 52, height: 52)
                    .contentShape(Circle())
                    .libraryGlass(in: Circle(), id: "settings", namespace: actionsNamespace)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("設定")
            .accessibilityHint("問題と答えのフォント設定を開きます")
            .accessibilityIdentifier("fontSettings")

            Menu {
                Button { showManualEntry = true } label: {
                    Label("手入力で追加", systemImage: "square.and.pencil")
                }.accessibilityIdentifier("manualEntry")
                Button { showImport = true } label: {
                    Label("CSV取り込み", systemImage: "doc.text")
                }.accessibilityIdentifier("importCSV")
            } label: {
                Image(systemName: "plus").font(.system(size: 24, weight: .medium))
                    .frame(width: 52, height: 52)
                    .libraryGlass(in: Circle(), id: "add", namespace: actionsNamespace)
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
            .accessibilityLabel("追加").accessibilityIdentifier("addItem")

            GeometryReader { geometry in
                Button {
                    searchFocused = false
                    session = StudySession(items: filtered)
                } label: {
                    Label("はじめる", systemImage: "play.fill")
                        .font(.headline)
                        .fixedSize()
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .frame(width: compact ? min(compactActionWidth, geometry.size.width) : geometry.size.width)
                .libraryGlass(in: Capsule(), id: "start", namespace: actionsNamespace)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .animation(reduceMotion ? nil : .smooth(duration: 0.32), value: compact)
                .disabled(filtered.isEmpty)
                .opacity(filtered.isEmpty ? 0.5 : 1)
                .accessibilityLabel("問題をはじめる")
                .accessibilityIdentifier("startStudy")
            }
            .frame(height: 56)
        }
        .foregroundStyle(Palette.green)
        .frame(maxWidth: .infinity, alignment: .trailing)
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
        let count = value.map { searchResults.counts[$0, default: 0] } ?? searchResults.total
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
    @Binding var actionsCollapsed: Bool
    @State private var userIsScrolling = false

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18, macOS 15, visionOS 2, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { oldOffset, offset in
                if userIsScrolling {
                    collapse = min(1, max(0, offset / 80))
                    if offset <= 8 || offset < oldOffset - 3 { actionsCollapsed = false }
                    else if offset > 60 && offset > oldOffset + 2 { actionsCollapsed = true }
                }
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

private extension View {
    @ViewBuilder func libraryGlass<S: Shape>(in shape: S, id: String, namespace: Namespace.ID) -> some View {
        #if os(iOS) || os(macOS)
        if #available(iOS 26, macOS 26, *) {
            self.glassEffect(
                .regular.tint(Palette.green.opacity(0.16)).interactive(),
                in: shape
            )
                .glassEffectID(id, in: namespace)
        } else {
            self.background(.regularMaterial, in: shape)
                .overlay(shape.stroke(Palette.green.opacity(0.2), lineWidth: 1))
        }
        #else
        self.background(.regularMaterial, in: shape)
            .overlay(shape.stroke(Palette.green.opacity(0.2), lineWidth: 1))
        #endif
    }
}
