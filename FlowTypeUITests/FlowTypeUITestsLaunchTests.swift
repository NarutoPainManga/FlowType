//
//  FlowTypeUITestsLaunchTests.swift
//  FlowTypeUITests
//
//  Created by Pain on 4/22/26.
//

import XCTest

final class FlowTypeUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["FLOWTYPE_UI_TEST_MODE"] = "1"
        app.launchEnvironment["FLOWTYPE_USE_MOCK_SERVICES"] = "1"
        app.launchEnvironment["FLOWTYPE_RESET_STATE"] = "1"
        app.launch()

        XCTAssertTrue(app.otherElements["flowtype.onboarding.screen"].waitForExistence(timeout: 8))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
