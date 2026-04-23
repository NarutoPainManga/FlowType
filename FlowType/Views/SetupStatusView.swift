import SwiftUI

struct SetupStatusView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        List {
            Section("Setup Overview") {
                Text(summaryText)
                    .foregroundStyle(.secondary)
            }

            Section("Checks") {
                statusRow(title: "Supabase Config", item: appModel.setupStatus.configuration)
                statusRow(title: "Microphone Permission", item: appModel.setupStatus.microphone)
                statusRow(title: "Auth Session", item: appModel.setupStatus.auth)
                statusRow(title: "Backend Connectivity", item: appModel.setupStatus.backend)
            }

            Section("What To Finish In Xcode") {
                instructionRow("1", "Add `NSMicrophoneUsageDescription` to the app target `Info.plist`.")
                instructionRow("2", "Add the `Supabase` Swift package dependency.")
                instructionRow("3", "Add `FlowTypeConfig.plist` using the example file in this repo.")
                instructionRow("4", "Run the app and refresh this screen to confirm the live path.")
            }

            Section {
                Button(appModel.isRefreshingSetupStatus ? "Refreshing..." : "Refresh Checks") {
                    appModel.refreshSetupStatus()
                }
                .disabled(appModel.isRefreshingSetupStatus)
            }
        }
        .navigationTitle("Setup Status")
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
            return "Everything needed for the live dictation flow looks ready."
        }

        if items.contains(where: \.isFailed) {
            return "At least one setup step is still blocking the live path. The details below show exactly what needs attention."
        }

        return "The app is partially configured. Finish the remaining Xcode steps and refresh this screen."
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
                .background(Color.blue.opacity(0.12))
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
