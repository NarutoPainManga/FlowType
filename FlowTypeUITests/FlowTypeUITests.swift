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
}
