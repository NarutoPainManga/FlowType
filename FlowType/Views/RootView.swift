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
            } else if screenshotScenario == "history" {
                ScreenshotHistoryView()
                    .accessibilityIdentifier("flowtype.history.screen")
            } else if screenshotScenario == "review" {
                ResultView()
                    .accessibilityIdentifier("flowtype.review.screen")
            } else if screenshotScenario == "usage" {
                ScreenshotUsageView()
                    .accessibilityIdentifier("flowtype.usage.screen")
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

private struct ScreenshotHistoryView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recent On This iPhone")
                        .font(.largeTitle.bold())

                    Text("Pick back up where you left off with polished drafts saved on this iPhone.")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    ForEach(appModel.sessions.prefix(5)) { session in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.mode.title)
                                .font(.headline)
                            Text(session.polishedText)
                                .font(.body)
                            Text(session.createdAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .padding(20)
            }
            .navigationTitle("History")
        }
    }
}

private struct ScreenshotUsageView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Usage Limit")
                    .font(.largeTitle.bold())

                Text("FlowType is in early release, so your weekly dictation limit resets automatically.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Weekly Limit Reached")
                        .font(.title2.bold())
                    Text("You have used \(appModel.usageSnapshot.usedDictations) of \(appModel.usageSnapshot.weeklyDictationLimit) dictations for this week.")
                        .foregroundStyle(.secondary)
                    Text("Your free usage resets soon, and more usage options are coming in a future update.")
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("Resets")
                            .font(.headline)
                        Spacer()
                        Text(appModel.usageSnapshot.resetsAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Spacer()
            }
            .padding(20)
        }
    }
}
