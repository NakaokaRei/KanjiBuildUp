import SwiftUI
#if os(iOS)
import PencilKit
#endif

struct StudyView: View {
  let store: LearningStore
  let session: StudySession
  var embedsNavigationStack = true
  @Environment(\.dismiss) private var dismiss
  @State private var path: [StudySession] = []
  #if os(iOS)
  @State private var drawings: [UUID: PKDrawing] = [:]
  #endif

  var body: some View {
    Group {
      if embedsNavigationStack {
        NavigationStack(path: $path) {
          page(session)
            .navigationDestination(for: StudySession.self) { page($0) }
        }
      } else {
        page(session)
      }
    }
    .tint(Palette.green)
    .foregroundStyle(Palette.ink)
  }

  private func page(_ value: StudySession) -> some View {
    #if os(iOS)
    StudyPage(store: store, session: value, drawings: $drawings,
              push: { path.append($0) }, close: { dismiss() })
    #else
    StudyPage(store: store, session: value,
              push: { path.append($0) }, close: { dismiss() })
    #endif
  }
}

private struct StudyPage: View {
  let store: LearningStore
  let session: StudySession
  #if os(iOS)
  @Binding var drawings: [UUID: PKDrawing]
  #endif
  let push: (StudySession) -> Void
  let close: () -> Void
  #if os(iOS)
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  private var compactHeight: Bool { verticalSizeClass == .compact }
  #else
  private var compactHeight: Bool { false }
  #endif
  private var studyLayout: AnyLayout {
    compactHeight && !dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(HStackLayout(alignment: .center, spacing: 16))
      : AnyLayout(VStackLayout(spacing: 12))
  }
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var headerCollapse: CGFloat = 1
  @State private var headerHeight: CGFloat = 140
  @ScaledMetric(relativeTo: .title2) private var collapsedQuestionSize: CGFloat = 22
  @ScaledMetric(relativeTo: .title2) private var expandedQuestionSize: CGFloat = 48
  @AppStorage("questionFont") private var questionFont: StudyFont = .gothic
  @State private var showFontSettings = false
  private var headerProgress: CGFloat { session.revealed ? 1 - headerCollapse : 0 }
  @State private var editingItem: StudyItem?
  @State private var confirmDelete = false
  @State private var errorMessage: String?
  private var item: StudyItem? { session.currentID.flatMap(store.item) }
  private var questionInBody: Bool {
    guard let item else { return false }
    return item.displayedQuestion.count > 40 || item.displayedQuestion.filter { $0.isNewline }.count > 2 || dynamicTypeSize.isAccessibilitySize
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if session.complete {
        Spacer()
        VStack(spacing: 18) {
          Image(systemName: "checkmark.circle").font(.system(size: 54)).foregroundStyle(
            Palette.green)
          Text("おつかれさまでした").font(.title2.bold())
          Text("\(session.itemIDs.count)問の学習が終わりました。\n覚え具合は保存されています。")
            .multilineTextAlignment(.center).foregroundStyle(Palette.secondary)
        }.frame(maxWidth: .infinity)
        Spacer()
      } else if let item {
        GeometryReader { geometry in
          ZStack(alignment: .top) {
            ScrollView {
              VStack(alignment: .leading, spacing: 12) {
                if session.revealed {
                  #if os(iOS)
                  AnswerContentView(handwriting: drawings[item.id], item: item, showsQuestion: questionInBody || compactHeight, availableHeight: max(0, geometry.size.height - headerHeight))
                  #else
                  AnswerContentView(item: item, showsQuestion: questionInBody || compactHeight, availableHeight: max(0, geometry.size.height - headerHeight))
                  #endif
                } else {
                  studyLayout {
                    StudyQuestionText(question: item.question, studyFont: questionFont, category: item.category)
                      .frame(maxWidth: .infinity, minHeight: 100)
                      .padding(.vertical, 8).accessibilityIdentifier("questionText")
                    #if os(iOS)
                    HandwritingView(drawing: Binding(
                      get: { drawings[item.id] ?? PKDrawing() },
                      set: { drawings[item.id] = $0 }
                    )).id(item.id)
                    #endif
                  }
                }
              }.frame(maxWidth: .infinity, alignment: .leading).padding(
                .vertical, compactHeight ? 4 : 12)
                .padding(.top, headerHeight)
            }
            .contentMargins(.bottom, 24)
            .modifier(StudyScrollHeaderModifier(collapse: $headerCollapse, enabled: session.revealed && !questionInBody))
            .id("\(session.index)-\(session.revealed)")
            studyHeader(item)
              .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
          }
        }

      }
    }.padding(.horizontal, 20).padding(.vertical, compactHeight ? 4 : 12).frame(maxWidth: 900).frame(
      maxWidth: .infinity
    )
    .background(Palette.pageGradient.ignoresSafeArea())
    .safeAreaInset(edge: .bottom, spacing: 0) {
      VStack(spacing: 0) {
        if session.complete {
          PrimaryButton(title: "一覧に戻る") { close() }
        } else if let item {
          studyLayout {
            if session.revealed {
              VStack(alignment: .leading, spacing: 6) {
                if !compactHeight {
                  HStack(spacing: 8) {
                    CompanionImage(name: "CompanionStarfish", size: 44)
                    Text("覚え具合を選ぶ").font(.subheadline)
                  }
                }
                HStack(spacing: 8) { masteryButtons(item) }
              }.padding(.top, compactHeight ? 0 : 8).padding(.bottom, compactHeight ? 0 : 12)
              PrimaryButton(
                title: session.isReview
                  ? "一覧に戻る" : session.index + 1 == session.itemIDs.count ? "学習を終える" : "次の問題"
              ) {
                if session.isReview { close() } else {
                  var next = session
                  next.advance()
                  push(next)
                }
              }
            } else {
              MasteryBadge(mastery: item.mastery).frame(maxWidth: .infinity).padding(.bottom, compactHeight ? 0 : 12)
              PrimaryButton(title: "答えを見る") {
                var answer = session
                answer.revealed = true
                push(answer)
              }.accessibilityIdentifier(
                "revealAnswer")
            }
          }
        }
      }.padding(.horizontal, 20).padding(.vertical, compactHeight ? 8 : 12)
        .frame(maxWidth: compactHeight ? 900 : 640).frame(maxWidth: .infinity)
        .background(Palette.background)
    }
    .onChange(of: session.currentID) { _, _ in headerCollapse = 1 }
    .onChange(of: session.revealed) { _, _ in headerCollapse = 1 }
    .companionNavigationBar()
    .navigationTitle(session.complete ? "学習完了" : session.revealed ? "答え" : "問題")
    #if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
    #endif
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button(action: close) { Image(systemName: "xmark") }
          .accessibilityLabel("学習を閉じる")
          .accessibilityIdentifier("closeStudy")
      }
      if let item, !session.complete {
        ToolbarItemGroup(placement: .primaryAction) {
          Button {
            if !store.toggleFavorite(for: item.id) {
              errorMessage = store.errorMessage
              store.errorMessage = nil
            }
          } label: {
            Image(systemName: item.isFavorite ? "star.fill" : "star")
          }
          .accessibilityLabel(item.isFavorite ? "お気に入りを解除" : "お気に入りに登録")
          .accessibilityIdentifier("toggleFavorite")

          Menu {
            Button("フォント設定", systemImage: "textformat") { showFontSettings = true }
              .accessibilityIdentifier("fontSettings")
            Button("編集", systemImage: "pencil") { editingItem = item }
              .accessibilityIdentifier("editItem")
            Button("削除", systemImage: "trash", role: .destructive) { confirmDelete = true }
              .accessibilityIdentifier("deleteItem")
          } label: {
            Image(systemName: "ellipsis.circle")
          }
          .accessibilityLabel("問題の操作").accessibilityIdentifier("itemActions")
        }
      }
    }
    .sheet(item: $editingItem) { value in
      StudyItemEditor(store: store, item: value) {}
    }
    .sheet(isPresented: $showFontSettings) {
      StudyFontSettingsView()
    }
    .confirmationDialog("この漢字を削除しますか？", isPresented: $confirmDelete, titleVisibility: .visible) {
      Button("削除する", role: .destructive) {
        guard let item else { return }
        if store.delete(item.id) {
          close()
        } else {
          errorMessage = store.errorMessage
          store.errorMessage = nil
        }
      }
    } message: {
      Text("削除すると元に戻せません。削除後は一覧に戻ります。")
    }
    .alert(
      "変更を保存できませんでした",
      isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    ) {
      Button("閉じる", role: .cancel) { errorMessage = nil }
    } message: {
      Text(errorMessage ?? "")
    }
  }
  private func studyHeader(_ item: StudyItem) -> some View {
    CompanionHeader() {
      VStack(spacing: 12) {
        ViewThatFits(in: .horizontal) {
          HStack {
            Text(item.category).font(.headline)
            Spacer()
            if !session.isReview {
              Text("\(session.index + 1) / \(session.itemIDs.count)").monospacedDigit()
            }
          }
          VStack(alignment: .leading, spacing: 8) {
            Text(item.category).font(.headline)
            if !session.isReview {
              HStack {
                Spacer()
                Text("\(session.index + 1) / \(session.itemIDs.count)").monospacedDigit()
              }
            }
          }
        }
        if !compactHeight {
          HStack(spacing: 12) {
            if session.revealed && questionInBody {
              Text("答えを確認しましょう")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if session.revealed {
              VStack(alignment: .leading, spacing: 4) {
                Text("問題").font(.caption).foregroundStyle(Palette.secondary)
                StudySelectableText(text: item.displayedQuestion,
                                    size: collapsedQuestionSize + (expandedQuestionSize - collapsedQuestionSize) * headerProgress,
                                    studyFont: questionFont,
                                    paragraphSpacing: item.category == "onkun" ? 12 : 0)
                  .fixedSize(horizontal: false, vertical: true)
                  .accessibilityIdentifier("answerQuestion")
              }.frame(maxWidth: .infinity, alignment: .leading)
            } else {
              Text(
                ["読み", "音読み", "訓読み", "当て字"].contains(item.category) ? "この漢字の読みは？" : "答えを考えてみましょう"
              )
              .font(.headline)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
              .padding(.leading, 16)
              .padding(.trailing, dynamicTypeSize.isAccessibilitySize ? 16 : 30)
              .padding(.vertical, 12)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(.white, in: CompanionSpeechBubble(showsTail: !dynamicTypeSize.isAccessibilitySize))
            }
            if !dynamicTypeSize.isAccessibilitySize {
              CompanionImage(name: session.revealed ? "CompanionSeaLion" : session.companionName, size: 72 + 28 * headerProgress)
                // Resize the artwork together with the question as the user scrolls the body.
                .frame(width: session.revealed ? 100 : 72, height: 56 + 28 * headerProgress)
            }
          }.frame(minHeight: 56 + 28 * headerProgress)
        }
      }
    }
  }

  @ViewBuilder private func masteryButtons(_ item: StudyItem) -> some View {
    ForEach(Mastery.allCases) { value in
      Button {
        store.setMastery(value, for: item.id)
      } label: {
        VStack(spacing: 4) {
          Image(systemName: item.mastery == value ? "checkmark.circle.fill" : "circle")
            .font(.body)
          Text(value.title).font(.subheadline.weight(.semibold))
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .foregroundStyle(item.mastery == value ? .white : value.tint)
      }
      .appGlassButton(prominent: true)
      .buttonBorderShape(.roundedRectangle(radius: 16))
      .tint(item.mastery == value ? value.tint : value.background)
      .accessibilityLabel(value.title)
      .accessibilityAddTraits(item.mastery == value ? .isSelected : [])
    }
  }
}

/// Follow the user's scroll direction and keep the selected size on release.
/// Ignore deceleration and bounce-back so releasing a pull does not undo it.
private struct StudyScrollHeaderModifier: ViewModifier {
  @Binding var collapse: CGFloat
  let enabled: Bool
  @State private var userIsScrolling = false

  @ViewBuilder func body(content: Content) -> some View {
    if #available(iOS 18, macOS 15, visionOS 2, *) {
      content
        .scrollBounceBehavior(.always, axes: .vertical)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
          geometry.contentOffset.y + geometry.contentInsets.top
        } action: { previousOffset, offset in
          if enabled && userIsScrolling {
            collapse = min(1, max(0, collapse + (offset - previousOffset) / 80))
          }
        }
        .onScrollPhaseChange { _, phase in
          userIsScrolling = phase == .interacting
        }
    } else {
      // Older systems retain the original compact size.
      content
    }
  }
}
