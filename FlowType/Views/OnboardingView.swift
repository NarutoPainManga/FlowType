import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text("FlowType")
                        .font(.largeTitle.bold())

                    Text("Write work messages with your voice.")
                        .font(.title2.weight(.semibold))

                    Text("Speak once. Get polished text for email, Slack, notes, and more.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(title: "Intent Modes", subtitle: "Format speech for the job you are doing.")
                    FeatureRow(title: "Anywhere on iPhone", subtitle: "Use the keyboard inside your favorite apps.")
                    FeatureRow(title: "Fast Cleanup", subtitle: "Fix punctuation, grammar, and structure in one tap.")
                }

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink("Review Setup Checklist") {
                        SetupStatusView()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .center)

                    Button("Set Up FlowType") {
                        appModel.hasCompletedOnboarding = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(24)
        }
    }
}

private struct FeatureRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
