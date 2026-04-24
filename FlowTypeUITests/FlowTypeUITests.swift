//
//  FlowTypeUITests.swift
//  FlowTypeUITests
//
//  Created by Pain on 4/22/26.
//

import XCTest

final class FlowTypeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingLeadsIntoHome() throws {
        let app = XCUIApplication()
        app.launchEnvironment["FLOWTYPE_USE_MOCK_SERVICES"] = "1"
        app.launchEnvironment["FLOWTYPE_RESET_STATE"] = "1"
        app.launch()

        XCTAssertTrue(app.staticTexts["Speak once. Send polished."].waitForExistence(timeout: 2))
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.navigationBars["FlowType"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Start Dictation"].exists)
    }

    @MainActor
    func testMockDictationShowsReviewFlow() throws {
        let app = XCUIApplication()
        app.launchEnvironment["FLOWTYPE_USE_MOCK_SERVICES"] = "1"
        app.launchEnvironment["FLOWTYPE_RESET_STATE"] = "1"
        app.launchEnvironment["FLOWTYPE_SKIP_ONBOARDING"] = "1"
        app.launch()

        XCTAssertTrue(app.buttons["Start Dictation"].waitForExistence(timeout: 2))
        app.buttons["Start Dictation"].tap()
        XCTAssertTrue(app.buttons["Stop Dictation"].waitForExistence(timeout: 2))
        app.buttons["Stop Dictation"].tap()

        XCTAssertTrue(app.navigationBars["Review"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Copy"].exists)
        XCTAssertTrue(app.buttons["Share"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
