# Design QA — セージグリーンとキャラクター

final result: passed

## 比較対象

- Source visual truth: `output/mockups/05-companion-sage.png` (1642 × 957 px)。承認された3画面と読書コアラのアイコン。
- Implementation: `output/verification/cute/cute-list.png`, `cute-question.png`, `cute-answer.png` (1206 × 2622 px)。iPhone 17 Pro / iOS 26.5、402 × 874 pt、3x。
- ソースと実装画像を同じ画像比較入力に読み込み、OSのステータスバー領域を除いたアプリ領域の構成・余白・文字の優先順位を確認。生成モックは計画390 × 844 ptの比率で描かれた参考で、ピクセル単位の一致は主張しない。
- 問題・答えはモックと同じ「亜典／あてね」。検証データは1問のため進捗1/1・最終ボタン「学習を終える」、メモなし。一覧の大量データは `list-initial.png` でも確認。
- 問題のキャラはランダム割り当てのため最終キャプチャではヒトデ。固定56 pt枠内で描画される。

## 比較・修正履歴

1. 初回 `question.png`, `answer.png` においてNavigationBar直下の左右端に小さな白い隙間を発見（P2）。ヘッダーの上側背景を左右余白まで拡張。
2. 最終 `cute-question.png`, `cute-answer.png` を再撮影し、同じ上部領域を確認。隙間は解消。標準の丸い戻る・メニューボタン、中央タイトル、背景接続を保持。

## 確認結果

- Typography: システムの日本語ゴシック。短い問題112 pt、長い問題44 pt、答えはScaledMetric基準56 pt。漢字・答えが装飾より優先され、フッター操作との重なりなし。
- Layout: 左右20 pt、ヘッダーは小さい画像枠とテキストの横並び、波形は単一Shape。問題は本文中央、答え・意味はスクロール領域。キャラ切り替えで本文位置を変えない。拡大文字サイズでは装飾非表示（コード確認、最大サイズでの実画面検証は未実施）。
- Colors: セージ #EAF3E8相当の共通色をNavigationBarとヘッダーへ適用。白に近い本文、深緑の主操作、既存の習熟度3色を維持。
- Assets: 背景透過した原画由来のアシカ・ペンギン・カエル・蝶・ヒトデ。コアラ＋開いた本の1024px不透明アプリアイコン。独立したPNGをasset catalogへ格納。
- Content: 習熟度は文字とチェックで識別。実データ件数、前の問題、編集メニュー、意味・メモ、ランダム出題と保存を維持。
- Native constraints: ナビゲーションタイトルは標準の中央配置。ボタンのガラス質感・余白はOSに従う。古いiOSでは旧標準の外観になる。iOS 26.5以外の実画面は今回未検証。
- 小さな吹き出しの尾は省略して白いカプセルとして実装。本文の可読性と標準レイアウトを優先した軽微な差（P3）。

## 検証

- iOS Simulatorビルド成功。
- データ処理テスト成功。セッション内のキャラ固定、隣接問題の重複回避、前後移動での同一キャラ復元を追加検証。
- UI: testImportStudyAndPersistence、testSwipeBackEditingNotesAndDeletion、testCompanionLayoutの3件成功。
- スワイプで戻る・取り込み・習熟度変更・学習完了・永続化・編集・メモ・削除の既存フローを検証。
- テスト結果: `/tmp/kanji-cute-ui.xcresult`, `/tmp/kanji-cute-layout.xcresult`。

残るP0/P1/P2指摘なし。実機および旧OSでの見た目確認は次の検証範囲。

## 一覧ヘッダーの追加修正

ユーザーの実機写真 IMG_9472.jpg と「一覧を多く表示したい」という指示を優先し、大きな見出し＋64 ptの装飾行を削除。標準 `.navigationTitle("漢字一覧")` と `.inline` を使用し、アシカをNavigationBarの32 pt枠へ移動。カテゴリーの44 pt操作領域を確保し、リスト上部余白を16→4 pt、フェードを24→8 ptに短縮。文字サイズと行の読みやすさは維持。

確認画像: `output/verification/cute/list-compact.png`（5問テストデータ）、`list-compact-defaults.png`（同梱7,999問）、ともに1206×2622 px / 402×874 pt。タイトルは追加ボタンと同じ上段に収まり、先頭の項目位置が上がり、キャラ・フィルター・一覧の重なりなし。旧デザインの大見出しからの変更は明示的なユーザー指示による。

ビルドおよび `testImportStudyAndPersistence` 成功（`/tmp/kanji-compact-header.xcresult`）。カテゴリー・習熟度フィルター、追加、一覧スクロール、問題・答えへの遷移、保存を確認。final result: passed。

## 吹き出しとキャラ拡大

ユーザー指示により問題文のカプセルを、右側のキャラに向く14 ptのしっぽ付きShapeへ変更。問題・答えのキャラを56→72 ptに拡大し、行の高さは56 ptのまま維持。拡大文字でキャラが非表示になる際はしっぽも非表示。

確認画像: `output/verification/cute/question-bubble.png`, `answer-larger-companion.png`。同じ亜典／あてねで以前の `cute-question.png`, `cute-answer.png` と比較し、漢字・答え・フッターの位置を維持、キャラの重なりなし、しっぽがキャラ側を向くことを確認。P3の「しっぽ省略」は解消。ビルドおよびtestCompanionLayout成功（`/tmp/kanji-speech-bubble.xcresult`）。final result: passed。

## 参考画像に合わせた波形と一覧ヘッダー

参照: ユーザー提供 `IMG_9473.jpg` と `codex-clipboard-c77367df-42dc-4af5-83c5-54e8b875e5f2.png`。後者を色以外の配置基準とした。波の振幅16 ptを維持し、4つの交互曲線（2周期）を2つ（1周期）へ変更。

一覧はtitle2の左寄せタイトル、右の72 ptアシカ、下段カテゴリー。ヘッダー本体は通常文字で100 pt（56+44）で変更前の64+36と同じ高さ。大見出しへ戻さず、一覧の領域を維持。背景はセージグリーン。

実画面: `output/verification/broad-wave/cute-list.png`, `cute-question.png`, `cute-answer.png`, `list-defaults.png`。iPhone 17 Pro / iOS 26.5、1206×2622 px、402×874 pt。参照画像と一覧の実描画を同じ比較入力で確認し、左右配置、カテゴリー位置、波の周期、キャラと文字の干渉なしを確認。問題の吹き出しの中央揃えと漢字の可読性も確認。ビルド・testCompanionLayout成功（`/tmp/kanji-broad-wave.xcresult`）。final result: passed。

## 固定フッターの透過とヒトデ拡大

参照: IMG_9474.jpg。ヒトデを26→44 ptへ拡大。問題・答え・学習完了・一覧・CSV取り込みを共通のfloatingFooterへ移行し、上端64 ptの透過グラデーションと下部Safe Areaへ続く半透明背景を適用。フッターの実測高さに合わせて本文・スクロールインジケーターの下余白を調整。

初回確認では本文が操作ラベルに重なり読みにくかったため、フェード区間を上端に限定して操作領域の背景濃度を上げて解消。iPhone 17 Pro / iOS 26.5の実描画（output/verification/footer内のlist.png、question.png、import.png、footer-long-answer.png、footer-long-answer-end.png）で境界の連続性・ラベルの可読性・長文の末尾がフッターより上までスクロールできることを確認。

ビルド、testImportStudyAndPersistence、testLongAnswerFloatingFooterの2件成功、失敗0（/tmp/kanji-footer-v3.xcresult）。final result: passed。実機および他OSの表示は未検証。

## 一覧のアシカを大きく表示

ユーザー指示により一覧のアシカを72→120 pt（約1.7倍）へ拡大。ヘッダーのキャラ枠は128×112 ptとし、波形・色・タイトル書体は維持。初回の上方向オフセットでは頭がNavigationBar境界で切れたため、下方向4 ptへ調整。ヘッダーは56 pt高くなるが、全身が収まりカテゴリー・タイトルと重ならないことをシミュレーター画像で確認した。

確認画像: output/verification/larger-sealion/list.png。iPhone 17 Pro / iOS 26.5。ビルドとtestCompanionLayout成功（/tmp/kanji-larger-sealion-v2.xcresult）。final result: passed。

## 一覧ヘッダーのスクロール連動縮小

ユーザーの「スクロールしたら折り畳む／小さくする」指示に対応。標準onScrollGeometryChangeで先頭からのスクロール量を取得し、80 ptの範囲でアシカ120→52 pt、タイトル28→22 pt、見出し行112→56 ptへ連続縮小。波形・色・フィルター操作を維持。カテゴリー・習熟度の変更時は一覧を先頭へ戻し、ヘッダーも復元。初回のセル座標計測では初期表示が縮んでしまう問題を検出し、標準スクロール計測へ変更して解消。

iPhone 17 Pro / iOS 26.5で展開・縮小・復元の3画像を確認（output/verification/collapse/header-expanded.png、header-collapsed.png、header-restored.png）。文字・キャラの見切れや重なりなし。testCollapsingLibraryHeaderでフィルター位置が40 pt以上上がり、先頭では元の位置に戻ること、固定操作が押せることを検証。testImportStudyAndPersistenceも成功。ビルド・2テスト成功（/tmp/kanji-collapse-v2.xcresult）。final result: passed。iOS 17 / macOS 14では従来の固定表示にフォールバック。

## フィルター切り替え時の状態保持と件数Widget

一覧のフィルター由来の.idとresetHeaderを削除。0件でも同じListを維持し、空表示をoverlay化。ヘッダー縮小はユーザー操作中のscroll phaseとgeometryだけに連動させ、データ差し替えによる位置補正では大きさを変更しない。スクロール開始・終了時のgeometryも反映し、0件フィルターから復帰した後の先頭復元を修正。

UIテストで「すべて→がんばるぞ→すべて」の表示行のY座標・ヘッダー位置維持、0件フィルター前後のヘッダー維持、スクロールでの先頭復元を確認（/tmp/kanji-widget-ui-v2.xcresult、1件成功）。既存testImportStudyAndPersistenceは/tmp/kanji-widget-ui.xcresultで成功。件数減少時はネイティブListが存在する内容の範囲にスクロールを補正する。

Widget「漢字のあゆみ」: systemSmallは2×2、systemMediumは4列。アシカ・ヒトデの既存素材、淡いセージ背景、色別の件数カード。Xcode Widget Previewで小・中サイズを確認（output/verification/widget/small.png、medium.png）。小サイズで発生したWidgetKit画像アーカイブ容量超過は、UIImage.preparingThumbnailで表示画像を180px以下へ縮小して解消。元アセットは保持。

App Groupの共有スナップショットは本体読み込み成功時と保存成功時のみ更新。テストストアは除外し、既存学習JSONは移動しない。データ処理テストで共有スナップショットの保存・復元・0件・不正データ・同じ値での再通知抑止を検証。署名付きシミュレータービルドの通常起動で学習JSONの7999件と共有値（2714 / 2635 / 2650）が一致。Xcodeの実機向け署名付きビルドも成功。実機ホーム画面上の更新タイミングは未検証でOSに依存。final result: passed。

## Widgetの文字拡大

ユーザー指示によりWidget内の「漢字のあゆみ」と応援文を削除。中サイズも2×2へ変更し、項目名11→15 pt、件数23→32 ptへ拡大。小サイズは10→12 pt、20→27 ptを基準に表示幅へ調整。中サイズのカード内にアシカとヒトデを配置。ギャラリー名は「漢字の件数」へ変更。

Xcode Widget Previewで小・中の4桁カンマ付き件数が欠けずに収まることを確認。画像はoutput/verification/widget-large-text/small.png、medium.png。Xcode実機向けビルド成功（BuildProject-Log-20261004-231543.txt）、エラー0件。final result: passed。

## Widgetを元の配置へ戻して見出しのみ削除

ユーザーの修正指示を優先し、中サイズを4列、小サイズを2×2の元の構成へ復元。「漢字のあゆみ」の見出しだけ削除し、中サイズの上下の応援文・上のアシカ・下のヒトデを復元。元版から項目名を小10→11／中11→12 pt、件数を小20→22／中23→25 pt、応援文を10→12 ptに調整。小サイズのアシカも復元。Xcode Previewで両サイズの文字と素材が収まることを確認（output/verification/widget-no-title/small.png、medium.png）。

## Widgetカードの余白調整

文字の左右に小4／中5 ptの内側余白を追加し、上下も小4→6／中8→10 ptへ拡大。元の配置を維持し、件数は使用可能な幅へ自動調整。小・中のWidget Previewで4桁件数・ラベルが枠内に収まり、余白が確保されることを確認（output/verification/widget-padding/）。

## 一覧の浮遊操作と右端収納

追加Menuを右上NavigationBarから開始ボタンの右上へ移動。一覧NavigationBarを非表示にし、タイトル・アシカを約56 pt上へ移動。問題・答え側はcompanionNavigationBarで明示的に再表示して戻る操作を維持。

Apple公式のTabBarMinimizeBehavior、toolbarMinimizationBehavior、glassEffectIDを調査。タブバー縮小はTabView用、汎用toolbarMinimizationBehaviorはローカルSDKでiOS 27以降のため、iOS 26の今回の独立アクションにはGlassEffectContainer＋glassEffect＋glassEffectIDを使用。下スクロールで開始ボタンを右端156 ptへ収納し、上スクロールで展開。ラベルは「はじめる」を残して用途が分かるようにした。追加は52 pt、開始は56 ptの高さでタップ可能。Reduce Motionとアクセシビリティ文字サイズへ配慮。

参照: https://developer.apple.com/documentation/swiftui/view/glasseffectid(_:in:) 、https://developer.apple.com/documentation/swiftui/view/toolbarminimizationbehavior(_:for:) 。

実画面: output/verification/floating-actions/header-expanded.png、header-collapsed.png。iPhone 17 Pro / iOS 26.5で上部余白削減、ガラス越しの本文、追加ボタンと開始ボタンの右端整列、文字の可読性を確認。testCollapsingLibraryHeaderで縮小幅・展開復元・追加位置・フィルター保持、testImportStudyAndPersistenceで追加・取り込み・画面遷移・保存を検証。2テスト成功（/tmp/kanji-floating-actions-v2.xcresult）。final result: passed。

## 開始ボタンのラベルを簡潔化

ユーザー指示で展開時を「▶ はじめる」、収納時を「▶」だけの56×56 ptへ変更。アクセシビリティラベル「問題をはじめる」を維持。output/verification/play-icon/の展開・収納スクリーンショットで配置確認、testCollapsingLibraryHeaderとビルド成功（/tmp/kanji-play-icon.xcresult）。

## 開始ボタンのアニメーション調整

条件付きTextの挿入・削除をやめ、展開ラベルと収納時の再生アイコンを分離。ラベルは80 msで消してから320 msで右端へ収納し、展開時は形が戻ってからラベルを表示する。親VStack全体へのアニメーションを削除し、ガラスの幅とラベルの透明度を個別に制御。Reduce Motionでは遅延も省略。

シミュレーター録画でガラスと文字の重なりを確認し、ラベルをglassEffectの内側へ修正。展開・収納・フィルター保持のUIテスト成功（/tmp/kanji-action-motion-v3.xcresult）。最終タイミング調整後のXcodeビルド成功。

## 収納時も開始ラベルを維持

再フィードバックにより、収納時も「▶ はじめる」を残す156 pt基準のカプセルへ変更（文字サイズに追従）。ラベルを単一のLabelに統一し、透明度の切り替え・遅延・重ね合わせを削除。右端を固定した幅の変化だけを320 msでアニメーションする。シミュレーター録画で収納・展開時のラベル表示を確認。ビルドとtestCollapsingLibraryHeader成功（/tmp/kanji-stable-label.xcresult）。

## 追加ボタンの透過

＋のガラスをMenu全体からラベルへ移し、borderlessButton＋plainスタイルで背景の重なりを避ける。追加ボタンは色付きregular glassからclear glassへ変更し、旧OSはultraThinMaterialへフォールバック。開始ボタンは従来の色付きガラスを維持。シミュレーター画像で背景の透過を確認し、追加メニュー操作を含むtestCollapsingLibraryHeaderと実機向けビルドが成功（/tmp/kanji-clear-add.xcresult）。

## 追加・開始ボタンの背景を統一

ユーザー指定により＋にも開始ボタンと同じ淡い緑のregular Liquid Glassを適用。Menuのラベルに効果を適用する構成は維持し、両ボタンが同じlibraryGlassを共有するように統一。Xcodeビルド成功。
