//
//  FlowTypeTests.swift
//  FlowTypeTests
//
//  Created by Pain on 4/22/26.
//

import Foundation
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

    @Test
    @MainActor
    func freeRewriteLimitStopsSecondTransform() async throws {
        AppModel.resetLocalState()

        let appModel = AppModel(services: .mock(), shouldBootstrap: false)
        appModel.hasAcceptedThirdPartyAIConsent = true
        appModel.currentPolishedText = "Quick update: we can ship on Friday."
        appModel.usageSnapshot = UsageSnapshot(
            weeklyDictationLimit: FlowTypeSpendPolicy.freeWeeklyDictationLimit,
            usedDictations: 1,
            weeklyTransformLimit: 1,
            usedTransforms: 0,
            resetsAt: .now
        )

        appModel.transformCurrentText(using: .shorter)
        try await Task.sleep(for: .milliseconds(100))

        #expect(appModel.remainingFreeTransformsForCurrentDraft == 0)
        #expect(appModel.currentPolishedText == "Quick follow-up: we can ship v1 by Friday if design signs off today.")

        appModel.transformCurrentText(using: .professional)

        #expect(appModel.errorMessage == "Free accounts currently include one AI rewrite per draft to keep usage sustainable.")
        #expect(appModel.remainingFreeTransformsForCurrentDraft == 0)
    }
}
