import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel
    private let screenshotScenario = ProcessInfo.processInfo.environment["FLOWTYPE_SCREENSHOT_SCENE"] ?? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-FlowTypeScreenshotScene"),
              arguments.indices.contains(index + 1) else {
            return nil
        }

        return arguments[index + 1]
    }()

    var body: some View {
        Group {
            if screenshotScenario == "onboarding" {
                OnboardingView()
                    .accessibilityIdentifier("flowtype.onboarding.screen")
            } else if screenshotScenario == "review" {
                ResultView()
                    .accessibilityIdentifier("flowtype.review.screen")
            } else if screenshotScenario == "help" {
                NavigationStack {
                    SetupStatusView()
                }
                .accessibilityIdentifier("flowtype.help.screen")
            } else if screenshotScenario == "home" {
                HomeView()
                    .accessibilityIdentifier("flowtype.home.screen")
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
