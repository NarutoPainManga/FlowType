//
//  FlowTypeTests.swift
//  FlowTypeTests
//
//  Created by Pain on 4/22/26.
//

import Testing
@testable import FlowType

struct FlowTypeTests {
    @Test
    @MainActor
    func onboardingStatePersistsAfterCompletion() async throws {
        AppModel.resetLocalState()
        let firstLaunch = AppModel(services: .mock())

        #expect(firstLaunch.hasCompletedOnboarding == false)

        firstLaunch.completeOnboarding()

        let secondLaunch = AppModel(services: .mock())
        #expect(secondLaunch.hasCompletedOnboarding == true)
    }

    @Test
    @MainActor
    func savedSessionsPersistAcrossRelaunch() async throws {
        AppModel.resetLocalState()

        let firstLaunch = AppModel(services: .mock())
        firstLaunch.selectedMode = .slack
        firstLaunch.currentTranscript = "quick update we can ship on friday"
        firstLaunch.currentPolishedText = "Quick update: we can ship on Friday."
        firstLaunch.saveCurrentSession()

        let secondLaunch = AppModel(services: .mock())
        #expect(secondLaunch.sessions.count == 1)
        #expect(secondLaunch.sessions.first?.mode == .slack)
        #expect(secondLaunch.sessions.first?.polishedText == "Quick update: we can ship on Friday.")
    }
}
