import SwiftUI

struct SetupStatusView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        List {
            Section("What FlowType Does") {
                Text(summaryText)
                    .foregroundStyle(.secondary)
            }

            Section("How It Works") {
                instructionRow("1", "Choose the mode that matches what you need to write.")
                instructionRow("2", "Record one short voice note in your own words.")
                instructionRow("3", "Review the polished result, then copy or share it anywhere you need.")
            }

            Section("Privacy And Processing") {
                Text("FlowType uses microphone access to capture your recording and cloud processing to turn it into polished writing. Recording only starts after you tap the button, and you always review the result before you use it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Data And Storage") {
                Text("Completed drafts are stored on this iPhone so you can reopen recent work. FlowType also creates an anonymous session to check usage and reach its cloud processing services.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Usage") {
                Text("FlowType currently includes a weekly dictation limit while the product is in early release. Your remaining usage updates inside the app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Support") {
                Text("If FlowType stops working, refresh the checks below, then relaunch the app after reconnecting to the internet or granting microphone access.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Policies And Help") {
                NavigationLink("Privacy Policy") {
                    LegalDocumentView(document: .privacy)
                }

                NavigationLink("Terms of Service") {
                    LegalDocumentView(document: .terms)
                }

                NavigationLink("Support Guide") {
                    LegalDocumentView(document: .support)
                }
            }

            Section("Manage Local Data") {
                Button("Clear Recent Drafts") {
                    appModel.clearLocalHistory()
                }
                .foregroundStyle(.red)

                Text("This removes recent polished drafts saved on this iPhone. It does not change your weekly usage count.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Status Checks") {
                statusRow(title: "App Configuration", item: appModel.setupStatus.configuration)
                statusRow(title: "Microphone Access", item: appModel.setupStatus.microphone)
                statusRow(title: "Session", item: appModel.setupStatus.auth)
                statusRow(title: "Cloud Processing", item: appModel.setupStatus.backend)
            }

            Section {
                Button(appModel.isRefreshingSetupStatus ? "Refreshing..." : "Refresh Checks") {
                    appModel.refreshSetupStatus()
                }
                .disabled(appModel.isRefreshingSetupStatus)
            }
        }
        .navigationTitle("Help & Status")
        .task {
            appModel.refreshSetupStatus()
        }
    }

    private var summaryText: String {
        let items = [
            appModel.setupStatus.configuration,
            appModel.setupStatus.microphone,
            appModel.setupStatus.auth,
            appModel.setupStatus.backend
        ]

        if items.allSatisfy(\.isReady) {
            return "FlowType is ready to capture speech, polish it, and help you send cleaner writing faster."
        }

        if items.contains(where: \.isFailed) {
            return "Something is blocking FlowType right now. The checks below show what needs attention before voice processing can work."
        }

        return "FlowType is still getting ready. Refresh the checks after granting permissions or reconnecting."
    }

    private func statusRow(title: String, item: SetupStatusItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.iconName)
                .foregroundStyle(item.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Text(item.shortLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.color)
                }

                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func instructionRow(_ step: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.caption.weight(.bold))
                .frame(width: 20, height: 20)
                .background(Color("BrandTeal").opacity(0.18))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}

private extension SetupStatusItem {
    var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = state { return true }
        return false
    }

    var shortLabel: String {
        switch state {
        case .ready:
            return "Ready"
        case .pending:
            return "Checking"
        case .unavailable:
            return "Needs Setup"
        case .failed:
            return "Blocked"
        }
    }

    var iconName: String {
        switch state {
        case .ready:
            return "checkmark.circle.fill"
        case .pending:
            return "clock.fill"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch state {
        case .ready:
            return .green
        case .pending:
            return .blue
        case .unavailable:
            return .orange
        case .failed:
            return .red
        }
    }
}
