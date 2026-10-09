import XCTest

final class KanjiBuildUpUITests: XCTestCase {
    @MainActor func testOnkunPairLayout() throws {
        continueAfterFailure = false
        for (question, answer, expected) in [
            ("a：窘迫\nb：窘しむ", "a：きんぱく\nb：くる", "きんぱく\nくる"),
            ("a：諷誦\nb：諷んじる", "a：ふうじゅ\n ふうしょう\n ふじゅ\nb：そら", "ふうじゅ / ふうしょう / ふじゅ\nそら")
        ] {
            let app = XCUIApplication()
            app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
            app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\nonkun,\"\(question)\",\"\(answer)\",意味の説明"
            app.launch()
            XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
            app.buttons["addItem"].tap()
            app.buttons["importCSV"].tap()
            app.buttons["1件を取り込む"].tap()
            app.buttons["startStudy"].tap()
            XCTAssertTrue(app.buttons["revealAnswer"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "a：")).firstMatch.exists)
            capture("onkun-question-\(expected.prefix(4))", app)
            app.buttons["revealAnswer"].tap()
            let shownAnswer = app.textViews["studyAnswer"]
            XCTAssertTrue(shownAnswer.waitForExistence(timeout: 5))
            XCTAssertEqual(shownAnswer.value as? String, expected)
            if expected.contains(" / ") {
                XCTAssertLessThan(shownAnswer.frame.height, 140)
            }
            XCTAssertFalse((app.textViews["answerQuestion"].value as? String ?? "").contains("a："))
            XCTAssertLessThan(shownAnswer.frame.maxY, app.buttons["かんぺき"].frame.minY)
            capture("onkun-answer-\(expected.prefix(4))", app)
            app.terminate()
        }
    }

    @MainActor func testQuestionExplanationLayout() throws {
        continueAfterFailure = false
        for (reading, explanation) in [
            ("たいどう", "（一緒に連れて行くこと）"),
            ("げんろう", "（①功労・名声があった政治家②功績をあげた年長者）")
        ] {
            let app = XCUIApplication()
            app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
            app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n大見出し②,\(reading)\(explanation),答え,"
            app.launch()
            XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
            app.buttons["addItem"].tap()
            app.buttons["importCSV"].tap()
            app.buttons["1件を取り込む"].tap()
            app.buttons["startStudy"].tap()
            let main = app.staticTexts[reading]
            let detail = app.staticTexts[explanation]
            XCTAssertTrue(main.waitForExistence(timeout: 5))
            XCTAssertTrue(detail.exists)
            XCTAssertEqual(detail.label, explanation)
            XCTAssertGreaterThan(detail.frame.minY, main.frame.maxY)
            XCTAssertTrue(app.buttons["revealAnswer"].isHittable)
            capture("question-explanation-\(reading)", app)
            app.terminate()
        }
    }

    @MainActor override func setUpWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor func testPartialCopyFromAnswer() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n読み,桜,さくら,alpha beta gamma"
        app.launch()
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        app.buttons["addItem"].tap()
        app.buttons["importCSV"].tap()
        app.buttons["1件を取り込む"].tap()
        XCTAssertTrue(app.buttons["startStudy"].waitForExistence(timeout: 5))
        app.buttons["startStudy"].tap()
        app.buttons["revealAnswer"].tap()

        let meaning = app.textViews["studyMeaning"]
        XCTAssertTrue(meaning.waitForExistence(timeout: 5))
        XCTAssertEqual(meaning.value as? String, "alpha beta gamma")
        // Select a single word directly on the answer page, without a sheet.
        meaning.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 20, dy: 12)).press(forDuration: 1)
        let copy = app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", ["コピー", "Copy"])).firstMatch
        XCTAssertTrue(copy.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        XCTAssertFalse(app.textViews["copySelectionText"].exists)
        capture("inline-text-selection", app)
        copy.tap()
        XCTAssertEqual(meaning.value as? String, "alpha beta gamma")
        XCTAssertEqual(app.textViews["studyAnswer"].value as? String, "さくら")
    }

    @MainActor func testImportStudyAndPersistence() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n読み,桜,さくら,春に花を咲かせる木。\n読み,椿,つばき,冬から春に花を咲かせる木。\n四字熟語,一期一会,いちごいちえ,一生に一度の出会いを大切にすること。\n四字熟語,温故知新,おんこちしん,昔のことを学び新しい知識を得ること。\nことわざ,七転び八起き,ななころびやおき,何度失敗しても立ち上がること。"
        app.launch()
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["startStudy"].isEnabled)
        capture("empty", app)
        app.buttons["addItem"].tap()
        app.buttons["importCSV"].tap()
        XCTAssertTrue(app.buttons["5件を取り込む"].waitForExistence(timeout: 5))
        capture("import", app)
        app.buttons["5件を取り込む"].tap()
        XCTAssertTrue(app.staticTexts["5件を取り込みました。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["がんばるぞ、5件"].exists)
        app.buttons["取り込み通知を閉じる"].tap()
        XCTAssertFalse(app.staticTexts["5件を取り込みました。"].exists)
        capture("list", app)
        app.collectionViews.firstMatch.swipeUp()
        XCTAssertTrue(app.buttons["startStudy"].isHittable)
        XCTAssertTrue(app.buttons.containing(.staticText, identifier: "七転び八起き").firstMatch.isHittable)
        capture("list-scrolled", app)
        app.collectionViews.firstMatch.swipeDown()
        app.buttons.containing(.staticText, identifier: "桜").firstMatch.tap()
        XCTAssertTrue(app.textViews["studyAnswer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["revealAnswer"].exists)
        XCTAssertFalse(app.buttons["previousQuestion"].exists)
        capture("answer", app)
        let masteryFrames = ["がんばるぞ", "あとすこし", "かんぺき"].map { app.buttons[$0].frame }
        for frame in masteryFrames.dropFirst() {
            XCTAssertEqual(frame.width, masteryFrames[0].width, accuracy: 1)
            XCTAssertEqual(frame.minY, masteryFrames[0].minY, accuracy: 1)
        }
        XCTAssertLessThan(masteryFrames[0].maxX, masteryFrames[1].minX)
        XCTAssertLessThan(masteryFrames[1].maxX, masteryFrames[2].minX)
        XCTAssertTrue(app.textViews["studyMeaning"].isHittable)
        XCTAssertLessThan(app.textViews["studyMeaning"].frame.maxY, masteryFrames[0].minY)
        app.buttons["かんぺき"].tap()
        app.buttons["一覧に戻る"].firstMatch.tap()
        XCTAssertTrue(app.buttons["かんぺき、1件"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["かんぺき、1件"].waitForExistence(timeout: 10))
        app.buttons["かんぺき、1件"].tap()
        app.buttons["startStudy"].tap()
        XCTAssertTrue(app.buttons["revealAnswer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textViews["studyAnswer"].exists)
        capture("question", app)
        app.buttons["revealAnswer"].tap()
        XCTAssertTrue(app.textViews["studyAnswer"].waitForExistence(timeout: 5))
        app.buttons["あとすこし"].tap()
        app.buttons["学習を終える"].tap()
        capture("after-finish", app)
        XCTAssertTrue(app.staticTexts["おつかれさまでした"].waitForExistence(timeout: 5))
        capture("complete", app)
        app.buttons["一覧に戻る"].firstMatch.tap()
        XCTAssertTrue(app.buttons["あとすこし、1件"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["startStudy"].isEnabled)
        app.buttons["すべて、5件"].tap()
        app.buttons["categoryFilter"].tap()
        app.buttons["四字熟語"].firstMatch.tap()
        XCTAssertTrue(app.buttons["すべて、2件"].waitForExistence(timeout: 5))
        app.buttons["startStudy"].tap()
        XCTAssertTrue(app.staticTexts["1 / 2"].waitForExistence(timeout: 5))
        let firstQuestion = app.staticTexts["questionText"].label
        XCTAssertFalse(app.buttons["previousQuestion"].isEnabled)
        app.buttons["revealAnswer"].tap()
        app.buttons["かんぺき"].tap()
        app.buttons["次の問題"].tap()
        XCTAssertTrue(app.staticTexts["2 / 2"].waitForExistence(timeout: 5))
        let secondQuestion = app.staticTexts["questionText"].label
        XCTAssertNotEqual(firstQuestion, secondQuestion)
        app.buttons["previousQuestion"].tap()
        XCTAssertTrue(app.staticTexts["1 / 2"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["questionText"].label, firstQuestion)
        XCTAssertFalse(app.buttons["previousQuestion"].isEnabled)
        app.buttons["revealAnswer"].tap()
        XCTAssertTrue(app.buttons["かんぺき"].isSelected)
        app.buttons["次の問題"].tap()
        XCTAssertTrue(app.staticTexts["2 / 2"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["questionText"].label, secondQuestion)
        app.buttons["revealAnswer"].tap()
        capture("answer-with-previous", app)
        app.buttons["previousQuestion"].tap()
        XCTAssertTrue(app.staticTexts["1 / 2"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["questionText"].label, firstQuestion)
        XCTAssertTrue(app.buttons["revealAnswer"].exists)
    }

    @MainActor func testManualEntryValidationAndPersistence() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        app.buttons["addItem"].tap()
        app.buttons["manualEntry"].tap()
        XCTAssertTrue(app.buttons["saveManualEntry"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["saveManualEntry"].isEnabled)
        let category = app.descendants(matching: .any)["manualCategory"].firstMatch
        category.tap(); category.typeText("   ")
        let question = app.descendants(matching: .any)["manualQuestion"].firstMatch
        question.tap(); question.typeText("梅")
        let answer = app.descendants(matching: .any)["manualAnswer"].firstMatch
        answer.tap(); answer.typeText("うめ")
        XCTAssertFalse(app.buttons["saveManualEntry"].isEnabled)
        app.buttons["入力を完了"].tap()
        app.swipeDown()
        app.buttons["categorySuggestion-訓読み"].tap()
        XCTAssertTrue(app.buttons["saveManualEntry"].isEnabled)
        capture("manual-entry", app)
        app.buttons["saveManualEntry"].tap()
        XCTAssertTrue(app.staticTexts["1件を追加しました。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["がんばるぞ、1件"].exists)
        app.buttons.containing(.staticText, identifier: "梅").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["うめ"].waitForExistence(timeout: 5))
        let emptyMeaning = app.textViews["studyMeaning"]
        XCTAssertTrue(emptyMeaning.waitForExistence(timeout: 5))
        XCTAssertEqual(emptyMeaning.value as? String ?? "", "")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["がんばるぞ、1件"].waitForExistence(timeout: 10))
        app.buttons["addItem"].tap()
        app.buttons["manualEntry"].tap()
        let newCategory = app.descendants(matching: .any)["manualCategory"].firstMatch
        XCTAssertTrue(newCategory.waitForExistence(timeout: 5))
        newCategory.tap(); newCategory.typeText("未保存")
        app.buttons["キャンセル"].tap()
        app.buttons["入力を破棄"].tap()
        XCTAssertTrue(app.buttons["すべて、1件"].waitForExistence(timeout: 5))
    }

    @MainActor func testSwipeBackEditingNotesAndDeletion() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n訓読み,桜,さくら,春の木"
        app.launch()
        app.buttons["addItem"].tap(); app.buttons["importCSV"].tap()
        app.buttons["1件を取り込む"].tap()
        XCTAssertTrue(app.buttons["startStudy"].waitForExistence(timeout: 5))
        app.buttons["startStudy"].tap()
        XCTAssertTrue(app.buttons["revealAnswer"].waitForExistence(timeout: 5))
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        XCTAssertTrue(app.buttons["startStudy"].waitForExistence(timeout: 5))
        app.buttons["startStudy"].tap()
        XCTAssertFalse(app.buttons["editNotes"].exists)
        XCTAssertFalse(app.textViews["studyNotes"].exists)
        app.buttons["revealAnswer"].tap()
        app.swipeUp()
        XCTAssertFalse(app.buttons["editNotes"].exists)
        app.buttons["itemActions"].tap(); app.buttons["editItem"].tap()
        app.collectionViews.firstMatch.swipeUp()
        let notes = app.descendants(matching: .any)["itemNotes"].firstMatch
        XCTAssertTrue(notes.waitForExistence(timeout: 5))
        notes.tap(); notes.typeText("春の復習")
        app.buttons["入力を完了"].tap()
        app.buttons["saveItem"].tap()
        app.swipeUp()
        XCTAssertTrue(app.textViews["studyNotes"].waitForExistence(timeout: 5))
        app.buttons["itemActions"].tap(); app.buttons["editItem"].tap()
        app.collectionViews.firstMatch.swipeUp()
        notes.tap(); notes.typeText("・追加")
        app.buttons["入力を完了"].tap()
        app.buttons["キャンセル"].tap()
        app.buttons["入力を破棄"].tap()
        XCTAssertEqual(app.textViews["studyNotes"].value as? String, "春の復習")
        app.buttons["itemActions"].tap(); app.buttons["editItem"].tap()
        app.collectionViews.firstMatch.swipeUp()
        notes.tap(); notes.typeText("・追記")
        let updatedNotes = try XCTUnwrap(notes.value as? String)
        XCTAssertTrue(updatedNotes.contains("・追記"))
        XCTAssertEqual(updatedNotes.replacingOccurrences(of: "・追記", with: ""), "春の復習")
        app.buttons["入力を完了"].tap()
        app.buttons["saveItem"].tap()
        XCTAssertEqual(app.textViews["studyNotes"].value as? String, updatedNotes)
        capture("answer-memo", app)
        app.buttons["itemActions"].tap(); app.buttons["editItem"].tap()
        app.buttons["categorySuggestion-音読み"].tap()
        app.buttons["saveItem"].tap()
        app.terminate(); app.launch()
        app.buttons.containing(.staticText, identifier: "桜").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["音読み"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.textViews["studyNotes"].exists)
        XCTAssertEqual(app.textViews["studyNotes"].value as? String, updatedNotes)
        app.buttons["itemActions"].tap(); app.buttons["deleteItem"].tap()
        app.buttons["削除する"].tap()
        XCTAssertTrue(app.buttons["startStudy"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["startStudy"].isEnabled)
        app.terminate(); app.launch()
        XCTAssertFalse(app.buttons["startStudy"].isEnabled)
    }

    @MainActor func testBundledDefaults() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["KANJI_TEST_DEFAULTS"] = "1"
        app.launch()
        XCTAssertTrue(app.buttons["すべて、16420件"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["がんばるぞ、9131件"].exists)
        XCTAssertTrue(app.buttons["あとすこし、3435件"].exists)
        XCTAssertTrue(app.buttons["かんぺき、3854件"].exists)
        capture("default-library", app)
        app.buttons["categoryFilter"].tap()
        app.buttons["訓読み"].firstMatch.tap()
        XCTAssertTrue(app.buttons["すべて、790件"].waitForExistence(timeout: 5))
        app.buttons["あとすこし、130件"].tap()
        app.buttons["startStudy"].tap()
        XCTAssertTrue(app.buttons["revealAnswer"].waitForExistence(timeout: 5))
        app.buttons["revealAnswer"].tap()
        capture("default-answer", app)
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["すべて、16420件"].waitForExistence(timeout: 10))
        app.buttons["categoryFilter"].tap()
        app.buttons["四字熟語"].firstMatch.tap()
        XCTAssertTrue(app.buttons["すべて、1605件"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["がんばるぞ、198件"].exists)
        XCTAssertTrue(app.buttons["あとすこし、388件"].exists)
        XCTAssertTrue(app.buttons["かんぺき、1019件"].exists)
        app.buttons["categoryFilter"].tap()
        app.buttons["ことわざ"].firstMatch.tap()
        XCTAssertTrue(app.buttons["すべて、2390件"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["がんばるぞ、150件"].exists)
        XCTAssertTrue(app.buttons["あとすこし、2104件"].exists)
        XCTAssertTrue(app.buttons["かんぺき、136件"].exists)
        app.buttons["categoryFilter"].tap()
        app.buttons["音読み"].firstMatch.tap()
        XCTAssertTrue(app.buttons["すべて、4199件"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["がんばるぞ、2411件"].exists)
        XCTAssertTrue(app.buttons["あとすこし、79件"].exists)
        XCTAssertTrue(app.buttons["かんぺき、1709件"].exists)
    }

    @MainActor func testCompanionLayout() throws {
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n当て字,亜典,あてね,出典不明。"
        app.launch()
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        app.buttons["addItem"].tap()
        app.buttons["importCSV"].tap()
        app.buttons["1件を取り込む"].tap()
        XCTAssertTrue(app.staticTexts["1件を取り込みました。"].waitForExistence(timeout: 5))
        app.buttons["取り込み通知を閉じる"].tap()
        capture("cute-list", app)
        app.buttons["startStudy"].tap()
        XCTAssertTrue(app.staticTexts["questionText"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["questionText"].isHittable)
        XCTAssertLessThan(app.staticTexts["questionText"].frame.maxY, app.buttons["revealAnswer"].frame.minY)
        capture("cute-question", app)
        app.buttons["revealAnswer"].tap()
        XCTAssertTrue(app.textViews["studyAnswer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textViews["studyMeaning"].isHittable)
        XCTAssertLessThan(app.textViews["studyAnswer"].frame.maxY, app.buttons["かんぺき"].frame.minY)
        capture("cute-answer", app)
    }

    @MainActor func testCollapsingLibraryHeader() throws {
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n" + (1...30).map {
            "読み,問題\($0),こたえ,意味"
        }.joined(separator: "\n")
        app.launch()
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        app.buttons["addItem"].tap()
        app.buttons["importCSV"].tap()
        app.buttons["30件を取り込む"].tap()
        app.buttons["取り込み通知を閉じる"].tap()
        let filter = app.buttons["categoryFilter"]
        let expandedY = filter.frame.minY
        let expandedStartWidth = app.buttons["startStudy"].frame.width
        XCTAssertLessThan(app.buttons["addItem"].frame.maxY, app.buttons["startStudy"].frame.minY)
        XCTAssertGreaterThan(app.buttons["addItem"].frame.minY, filter.frame.maxY)
        capture("header-expanded", app)
        let list = app.collectionViews.firstMatch
        list.swipeUp()
        // Settings remain available above the floating add button as the header compacts.
        XCTAssertLessThan(filter.frame.minY, expandedY - 40)
        XCTAssertTrue(app.buttons["fontSettings"].isHittable)
        XCTAssertTrue(filter.isHittable)
        XCTAssertTrue(app.buttons["startStudy"].isHittable)
        XCTAssertLessThan(app.buttons["startStudy"].frame.width, expandedStartWidth - 80)
        XCTAssertEqual(app.buttons["startStudy"].frame.maxX, app.buttons["addItem"].frame.maxX, accuracy: 2)
        capture("header-collapsed", app)
        let collapsedY = filter.frame.minY
        let visibleQuestion = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "問題")).allElementsBoundByIndex.first { $0.isHittable && $0.label != "問題をはじめる" }!
        let visibleLabel = visibleQuestion.label
        let visibleY = visibleQuestion.frame.minY
        app.buttons["がんばるぞ、30件"].tap()
        XCTAssertEqual(filter.frame.minY, collapsedY, accuracy: 2)
        XCTAssertEqual(app.staticTexts[visibleLabel].frame.minY, visibleY, accuracy: 2)
        app.buttons["すべて、30件"].tap()
        XCTAssertEqual(filter.frame.minY, collapsedY, accuracy: 2)
        XCTAssertEqual(app.staticTexts[visibleLabel].frame.minY, visibleY, accuracy: 2)
        capture("filter-position-preserved", app)
        app.buttons["あとすこし、0件"].tap()
        XCTAssertEqual(filter.frame.minY, collapsedY, accuracy: 2)
        XCTAssertTrue(app.staticTexts["該当する問題はありません"].exists)
        app.buttons["すべて、30件"].tap()
        XCTAssertEqual(filter.frame.minY, collapsedY, accuracy: 2)

        for _ in 0..<3 { list.swipeDown() }
        XCTAssertEqual(filter.frame.minY, expandedY, accuracy: 2)
        XCTAssertEqual(app.buttons["startStudy"].frame.width, expandedStartWidth, accuracy: 2)
        capture("header-restored", app)
    }

    @MainActor func testLongAnswerFloatingFooter() throws {
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        let meaning = String(repeating: "小さな虫が木に入り、幹や枝を食べることがあります。", count: 14)
        app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n読み,虫,むし,\(meaning)ここが説明の最後です。"
        app.launch()
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        app.buttons["addItem"].tap()
        app.buttons["importCSV"].tap()
        XCTAssertTrue(app.buttons["1件を取り込む"].waitForExistence(timeout: 5))
        app.buttons["1件を取り込む"].tap()
        app.buttons["startStudy"].tap()
        app.buttons["revealAnswer"].tap()
        XCTAssertTrue(app.textViews["studyMeaning"].waitForExistence(timeout: 5))
        capture("footer-long-answer", app)
        let headerQuestion = app.textViews["answerQuestion"]
        XCTAssertTrue(headerQuestion.exists)
        let initialQuestionFrame = headerQuestion.frame
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<4 { scroll.swipeUp() }
        XCTAssertTrue(app.buttons["かんぺき"].isHittable)
        XCTAssertLessThan(app.textViews["studyMeaning"].frame.maxY, app.buttons["かんぺき"].frame.minY)
        capture("footer-long-answer-end", app)
        XCTAssertEqual(headerQuestion.frame.height, initialQuestionFrame.height, accuracy: 2)
        for _ in 0..<5 { scroll.swipeDown() }
        XCTAssertGreaterThan(headerQuestion.frame.height, initialQuestionFrame.height)
        capture("answer-header-expanded", app)
        let bodyStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        bodyStart.press(forDuration: 0.1, thenDragTo: bodyStart.withOffset(CGVector(dx: 0, dy: -180)))
        XCTAssertEqual(headerQuestion.frame.height, initialQuestionFrame.height, accuracy: 2)
        capture("answer-header-collapsed", app)
    }

    @MainActor func testLongQuestionHeaderExpansion() throws {
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        let question = "【一坏】の濁れる酒を飲むべくあるらし"
        app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n訓読み,\(question),ひとつき,食器。酒を入れる器。"
        app.launch()
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        app.buttons["addItem"].tap()
        app.buttons["importCSV"].tap()
        app.buttons["1件を取り込む"].tap()
        app.buttons["取り込み通知を閉じる"].tap()
        app.buttons.containing(.staticText, identifier: question).firstMatch.tap()
        let text = app.textViews["answerQuestion"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        let initialFrame = text.frame
        capture("long-header-initial", app)
        // Pull the short answer body, including when it has no scroll overflow.
        let pullStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.48))
        pullStart.press(forDuration: 0.1, thenDragTo: pullStart.withOffset(CGVector(dx: 0, dy: 180)))
        XCTAssertGreaterThan(text.frame.height, initialFrame.height * 1.3)
        XCTAssertEqual(text.value as? String, question)
        XCTAssertTrue(app.textViews["studyAnswer"].isHittable)
        capture("long-header-expanded", app)
        let bodyStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        bodyStart.press(forDuration: 0.1, thenDragTo: bodyStart.withOffset(CGVector(dx: 0, dy: -180)))
        XCTAssertEqual(text.frame.height, initialFrame.height, accuracy: 2)
        capture("long-header-collapsed", app)
        app.buttons["一覧に戻る"].tap()
        app.buttons.containing(.staticText, identifier: question).firstMatch.tap()
        XCTAssertEqual(text.frame.height, initialFrame.height, accuracy: 2)
    }

    @MainActor func testFontSettingsPersistence() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n読み,桜,さくら,春の花。"
        app.launch()
        XCTAssertTrue(app.buttons["fontSettings"].waitForExistence(timeout: 10))
        app.buttons["addItem"].tap()
        app.buttons["importCSV"].tap()
        app.buttons["1件を取り込む"].tap()
        app.buttons["取り込み通知を閉じる"].tap()
        capture("home-font-entry", app)
        app.buttons["fontSettings"].tap()
        app.buttons["questionFontPicker"].tap()
        app.buttons["明朝体"].tap()
        app.buttons["answerFontPicker"].tap()
        app.buttons["ゴシック（細字）"].tap()
        capture("font-settings-preview", app)
        app.buttons["完了"].tap()
        app.buttons["startStudy"].tap()
        XCTAssertTrue(app.staticTexts["questionText"].exists)
        app.buttons["revealAnswer"].tap()
        XCTAssertTrue(app.textViews["studyAnswer"].exists)
        capture("custom-font-answer", app)
        app.buttons["itemActions"].tap()
        app.buttons["fontSettings"].tap()
        XCTAssertEqual(app.buttons["questionFontPicker"].value as? String, "明朝体")
        XCTAssertEqual(app.buttons["answerFontPicker"].value as? String, "ゴシック（細字）")
        app.terminate()
        app.launch()
        app.buttons["fontSettings"].tap()
        XCTAssertEqual(app.buttons["questionFontPicker"].value as? String, "明朝体")
        XCTAssertEqual(app.buttons["answerFontPicker"].value as? String, "ゴシック（細字）")
        // Leave the shared simulator preferences at the default for other tests.
        for identifier in ["questionFontPicker", "answerFontPicker"] {
            app.buttons[identifier].tap()
            app.buttons["ゴシック（標準）"].tap()
        }
        app.buttons["完了"].tap()
    }

    @MainActor func testQuestionTypography() throws {
        let app = XCUIApplication()
        let longQuestion = "逝く者は斯くの如きか、昼夜を【舎】かず"
        for largeText in [false, true] {
            app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
            app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n音読み,炊爨,すいさん,飯を炊く\n訓読み,\(longQuestion),お,意味"
            app.launchArguments = largeText
                ? ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityM"] : []
            app.launch()
            XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
            app.buttons["addItem"].tap()
            app.buttons["importCSV"].tap()
            app.buttons["2件を取り込む"].tap()
            app.buttons["取り込み通知を閉じる"].tap()
            XCTAssertTrue(app.staticTexts["炊爨"].exists)
            XCTAssertTrue(app.staticTexts[longQuestion].exists)
            capture(largeText ? "list-large-type" : "list-question-sizes", app)
            app.buttons.containing(.staticText, identifier: "炊爨").firstMatch.tap()
            XCTAssertTrue(app.textViews["answerQuestion"].exists)
            XCTAssertTrue(app.textViews["studyAnswer"].exists)
            capture(largeText ? "answer-large-type" : "answer-short-question", app)
            app.terminate()
        }
    }

    @MainActor func testQuestionAndAnswerSearch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["KANJI_TEST_STORE"] = UUID().uuidString
        app.launchEnvironment["KANJI_TEST_CSV"] = "カテゴリー,問題,答え,意味\n音読み,炊爨,すいさん,飯を炊く\n訓読み,炊く,たく,食事\n音読み,桜,さくら,炊爨は検索対象外"
        app.launch()
        XCTAssertTrue(app.buttons["addItem"].waitForExistence(timeout: 10))
        app.buttons["addItem"].tap()
        app.buttons["importCSV"].tap()
        app.buttons["3件を取り込む"].tap()
        app.buttons["取り込み通知を閉じる"].tap()
        let search = app.textFields["questionSearch"]
        search.tap()
        search.typeText("炊\n")
        XCTAssertTrue(app.buttons["すべて、2件"].exists)
        XCTAssertFalse(app.staticTexts["答えに一致"].exists)
        app.buttons["categoryFilter"].tap()
        app.buttons["音読み"].firstMatch.tap()
        XCTAssertTrue(app.buttons["すべて、1件"].exists)
        app.buttons["あとすこし、0件"].tap()
        XCTAssertFalse(app.buttons["startStudy"].isEnabled)
        XCTAssertTrue(app.staticTexts["該当する問題はありません"].exists)
        app.buttons["すべて、1件"].tap()
        app.buttons["startStudy"].tap()
        XCTAssertEqual(app.staticTexts["questionText"].label, "炊爨")
        app.buttons["revealAnswer"].tap()
        app.buttons["学習を終える"].tap()
        app.buttons["一覧に戻る"].tap()
        XCTAssertEqual(search.value as? String, "炊")
        app.buttons["clearQuestionSearch"].tap()
        XCTAssertTrue(app.buttons["すべて、2件"].exists)
        search.tap()
        search.typeText("すいさん\n")
        XCTAssertTrue(app.buttons["すべて、1件"].exists)
        XCTAssertTrue(app.staticTexts["答えに一致"].exists)
        XCTAssertFalse(app.staticTexts["すいさん"].exists)
        XCTAssertTrue(app.buttons["startStudy"].isEnabled)
        app.buttons["startStudy"].tap()
        XCTAssertEqual(app.staticTexts["questionText"].label, "炊爨")
        XCTAssertFalse(app.staticTexts["すいさん"].exists)
        app.buttons["revealAnswer"].tap()
        XCTAssertEqual(app.textViews["studyAnswer"].value as? String, "すいさん")
        app.terminate()
        app.launch()
        XCTAssertFalse(app.buttons["clearQuestionSearch"].exists)
        XCTAssertTrue(app.buttons["すべて、3件"].exists)
    }

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let directory = URL.documentsDirectory.appendingPathComponent("Screenshots")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? app.screenshot().pngRepresentation.write(to: directory.appendingPathComponent(name + ".png"))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
