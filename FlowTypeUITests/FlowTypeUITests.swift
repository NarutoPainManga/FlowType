//
//  FlowTypeUITests.swift
//  FlowTypeUITests
//
//  Created by Pain on 4/22/26.
//

import XCTest

final class FlowTypeUITests: XCTestCase {
    private func makeApp(skipOnboarding: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["FLOWTYPE_UI_TEST_MODE"] = "1"
        app.launchEnvironment["FLOWTYPE_USE_MOCK_SERVICES"] = "1"
        app.launchEnvironment["FLOWTYPE_RESET_STATE"] = "1"
        if skipOnboarding {
            app.launchEnvironment["FLOWTYPE_SKIP_ONBOARDING"] = "1"
        }
        return app
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingLeadsIntoHome() throws {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.otherElements["flowtype.onboarding.screen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Speak once. Send polished."].waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.otherElements["flowtype.home.screen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.navigationBars["FlowType"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Start Dictation"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testMockDictationShowsReviewFlow() throws {
        let app = makeApp(skipOnboarding: true)
        app.launch()

        XCTAssertTrue(app.otherElements["flowtype.home.screen"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Start Dictation"].waitForExistence(timeout: 5))
        app.buttons["Start Dictation"].tap()
        XCTAssertTrue(app.buttons["Stop Dictation"].waitForExistence(timeout: 5))
        app.buttons["Stop Dictation"].tap()

        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Copy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Share"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testDeleteAnonymousAccountClearsRecentDrafts() throws {
        let app = makeApp(skipOnboarding: true)
        app.launch()

        XCTAssertTrue(app.otherElements["flowtype.home.screen"].waitForExistence(timeout: 8))

        app.buttons["Start Dictation"].tap()
        XCTAssertTrue(app.buttons["Stop Dictation"].waitForExistence(timeout: 5))
        app.buttons["Stop Dictation"].tap()

        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 8))
        app.navigationBars["Review"].buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.staticTexts["Recent On This iPhone"].waitForExistence(timeout: 5))

        app.buttons["Help and Status"].tap()
        XCTAssertTrue(app.navigationBars["Help & Status"].waitForExistence(timeout: 5))

        let deleteButton = app.buttons["flowtype.deleteAccount"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let confirmButton = app.buttons["flowtype.confirmDeleteAccount"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        XCTAssertTrue(app.navigationBars["FlowType"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Start Dictation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your polished drafts will show up here after you finish a session."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testFreeRewriteLimitBlocksSecondRewrite() throws {
        let app = makeApp(skipOnboarding: true)
        app.launch()

        XCTAssertTrue(app.otherElements["flowtype.home.screen"].waitForExistence(timeout: 8))

        app.buttons["Start Dictation"].tap()
        XCTAssertTrue(app.buttons["Stop Dictation"].waitForExistence(timeout: 5))
        app.buttons["Stop Dictation"].tap()

        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 8))

        let shorterButton = app.buttons["Shorter"]
        XCTAssertTrue(shorterButton.waitForExistence(timeout: 5))
        XCTAssertTrue(shorterButton.isEnabled)
        shorterButton.tap()

        XCTAssertTrue(app.staticTexts["Free accounts currently include one AI rewrite per draft."].waitForExistence(timeout: 5))
        XCTAssertFalse(shorterButton.isEnabled)
        XCTAssertFalse(app.buttons["Professional"].isEnabled)
        XCTAssertFalse(app.buttons["Friendly"].isEnabled)
        XCTAssertFalse(app.buttons["Bullet List"].isEnabled)
        XCTAssertTrue(app.textViews.firstMatch.value as? String == "Quick follow-up: we can ship v1 by Friday if design signs off today.")
    }
}
