import XCTest

final class KanjiBuildUpUITests: XCTestCase {
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
        app.buttons.containing(.staticText, identifier: "桜").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["さくら"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["revealAnswer"].exists)
        capture("answer", app)
        app.buttons["かんぺき"].tap()
        app.buttons["一覧に戻る"].firstMatch.tap()
        XCTAssertTrue(app.buttons["かんぺき、1件"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["かんぺき、1件"].waitForExistence(timeout: 10))
        app.buttons["かんぺき、1件"].tap()
        app.buttons["startStudy"].tap()
        XCTAssertTrue(app.buttons["revealAnswer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["さくら"].exists)
        capture("question", app)
        app.buttons["revealAnswer"].tap()
        XCTAssertTrue(app.staticTexts["さくら"].waitForExistence(timeout: 5))
        app.buttons["あとすこし"].tap()
        app.buttons["学習を終える"].tap()
        capture("after-finish", app)
        XCTAssertTrue(app.staticTexts["おつかれさまでした"].waitForExistence(timeout: 5))
        capture("complete", app)
        app.buttons["一覧に戻る"].firstMatch.tap()
        XCTAssertTrue(app.buttons["あとすこし、1件"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["startStudy"].isEnabled)
        app.buttons["すべて、5件"].tap()
        app.buttons["すべてのカテゴリー"].tap()
        app.buttons["四字熟語"].firstMatch.tap()
        XCTAssertTrue(app.buttons["すべて、2件"].waitForExistence(timeout: 5))
        app.buttons["startStudy"].tap()
        XCTAssertTrue(app.staticTexts["1 / 2"].waitForExistence(timeout: 5))
        app.buttons["revealAnswer"].tap()
        app.buttons["次の問題"].tap()
        XCTAssertTrue(app.staticTexts["2 / 2"].waitForExistence(timeout: 5))
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
        XCTAssertTrue(app.staticTexts["意味は登録されていません。"].exists)
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
        app.buttons["editNotes"].tap()
        let form = app.collectionViews.firstMatch
        form.swipeUp()
        let notes = app.descendants(matching: .any)["itemNotes"].firstMatch
        XCTAssertTrue(notes.waitForExistence(timeout: 5))
        notes.tap(); notes.typeText("春の復習")
        app.buttons["saveItem"].tap()
        app.buttons["revealAnswer"].tap()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["studyNotes"].waitForExistence(timeout: 5))
        app.buttons["itemActions"].tap(); app.buttons["editItem"].tap()
        app.buttons["categorySuggestion-音読み"].tap()
        app.buttons["saveItem"].tap()
        app.terminate(); app.launch()
        app.buttons.containing(.staticText, identifier: "桜").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["音読み"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["studyNotes"].exists)
        app.buttons["itemActions"].tap(); app.buttons["deleteItem"].tap()
        app.buttons["削除する"].tap()
        XCTAssertTrue(app.buttons["startStudy"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["startStudy"].isEnabled)
        app.terminate(); app.launch()
        XCTAssertFalse(app.buttons["startStudy"].isEnabled)
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
