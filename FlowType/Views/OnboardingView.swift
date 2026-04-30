import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("BrandNavy"), Color("BrandInk"), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 18) {
                        Text("FlowType")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text("Speak once. Send polished.")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)

                        Text("Turn rough voice notes into clean writing for email, Slack, notes, and task lists.")
                            .foregroundStyle(.white.opacity(0.78))

                        HStack(spacing: 10) {
                            Label("Built for busy workdays", systemImage: "sparkles")
                            Label("Review before sending", systemImage: "checkmark.shield")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.88))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(
                            title: "Speak Naturally",
                            subtitle: "Capture the thought first. Clean it up after."
                        )
                        FeatureRow(
                            title: "Choose The Right Mode",
                            subtitle: "Format speech for email, Slack, notes, tasks, and more."
                        )
                        FeatureRow(
                            title: "Copy Or Share Fast",
                            subtitle: "Send polished writing anywhere on your iPhone."
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("FlowType asks your permission before it sends recordings or text to Supabase and OpenAI for cloud processing. You'll always review the result before you use it.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        NavigationLink("How FlowType Works") {
                            SetupStatusView()
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.28))
                        .frame(maxWidth: .infinity, alignment: .center)

                        Button("Continue") {
                            appModel.completeOnboarding()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("BrandTeal"))
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(24)
            }
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
                .foregroundStyle(.white)
            Text(subtitle)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
