import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel
    private let screenshotScenario = ProcessInfo.processInfo.environment["FLOWTYPE_SCREENSHOT_SCENE"]

    var body: some View {
        Group {
            if screenshotScenario == "help" {
                NavigationStack {
                    SetupStatusView()
                }
                .accessibilityIdentifier("flowtype.help.screen")
            } else if appModel.hasCompletedOnboarding {
                HomeView()
                    .accessibilityIdentifier("flowtype.home.screen")
            } else {
                OnboardingView()
                    .accessibilityIdentifier("flowtype.onboarding.screen")
            }
        }
    }
}
