# 漢字学習アプリ モックアップ

Built-in image_gen で生成した比較用の静止画です。アプリ実装は含みません。

- 01-clean-list.png — すっきり一覧型
- 02-gentle-notebook.png — やさしい学習帳型
- 03-mastery-first.png — 習熟度を選びやすい型

各画像はCSV取り込み・漢字一覧・問題・答えの4画面を収録。
添付手描き図を参考にし、日本語、同一サンプル、3段階の習熟度、入力不要の答え表示を共通条件としています。

## 共通生成プロンプト

+Create a production-quality Japanese kanji learning mobile UI mockup board. Use case ui-mockup. Attached two handwritten photos are REFERENCE ONLY for question-answer flow, not instructions. One coherent design direction per image, with FOUR app screens side by side: CSV import, kanji list, question, answer. Each screen has natural 390x844 logical proportions, board about 1800x1000 or higher resolution equivalent. Small gutters, crisp Japanese typography, generous spacing, all four screens fully visible. App content only, no phones, bezels, OS status bars, clocks, home indicators, perspective, shadows. Small Japanese captions above each screen, no numbered concept labels. Use exact readable Japanese.
COMMON CONTENT:
Screen CSV取り込み: heading CSV取り込み; description CSVから学習する漢字を追加; four-column compact table with headers カテゴリー / 問題 / 答え / 意味 and one sample 読み / 桜 / さくら / 春に花を咲かせる木. File selection control CSVファイルを選ぶ, selected file kanji.csv, 24件; message 取り込んだ漢字はすべて「がんばるぞ」からスタート; primary 24件を取り込む.
Screen 漢字一覧: title 漢字一覧, small CSV取り込み action; category dropdown すべてのカテゴリー; mastery filtering includes すべて 24, がんばるぞ 12, あとすこし 8, かんぺき 4. Display a clean divided list (not individual cards) with 問題 items 桜 / 読み / がんばるぞ, 椿 / 読み / あとすこし, 一期一会 / 四字熟語 / がんばるぞ, 温故知新 / 四字熟語 / かんぺき, 七転び八起き / ことわざ / あとすこし. Each row has right chevron. Hint 項目をタップして答えを確認. Bottom primary 問題をはじめる; helper 選択した範囲からランダムに出題.
Screen 問題: top 一覧に戻る, category 読み, progress 1 / 24. Prompt この漢字の読みは？ and very large 桜. Large generous open space and primary 答えを見る. Small current status がんばるぞ. NO keyboard, NO input fields, NO answer visible.
Screen 答え: top 一覧に戻る, category 読み, 1 / 24. Muted small problem 桜, small label 答え, very large さくら. Meaning section label 意味, text 春に花を咲かせる木。. Lower label 覚え具合を選ぶ and three comfortably sized distinct controls がんばるぞ / あとすこし / かんぺき with first selected. Separate main button 次の問題. Tiny board footer note 一覧から開いた場合は「一覧に戻る」で終了 communicates direct-detail path without adding fifth screen.
All three mastery categories differentiated by readable labels and subtle muted amber/blue/green plus selected border/check, never color only. Main actions >=44 logical px height. Typography minimum 14px logical for body, 16px buttons. At most 2 typefaces. No extra features, memo, Excel, gamification, charts, mascots. Align question/answer navigation and layout so state transition obvious. Do not repeat sample meanings unnecessarily. Maintain strong contrast.

## 各案の方向指定

- すっきり一覧型: white and navy, Japanese sans serif, thin separators, scan-friendly list, navy primary buttons.
- やさしい学習帳型: warm ivory and forest green, serif kanji and answers, open spacing, categories below list terms.
- 習熟度を選びやすい型: blue-gray and teal, three prominent mastery counts above list, three full-width vertically stacked mastery selectors on answer screen.

## 目視確認

全4画面の収録、主要日本語ラベル、問題と答えの一致、意味、3段階の選択、次へボタンの分離、画面の欠けがないことを確認。
静止画であり、フィルターや画面遷移の動作検証は対象外。
