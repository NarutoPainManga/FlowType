import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Group {
            if appModel.hasCompletedOnboarding {
                HomeView()
                    .accessibilityIdentifier("flowtype.home.screen")
            } else {
                OnboardingView()
                    .accessibilityIdentifier("flowtype.onboarding.screen")
            }
        }
    }
}
