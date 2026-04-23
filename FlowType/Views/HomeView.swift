import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    modePicker
                    voiceCard
                    historySection
                }
                .padding(20)
            }
            .navigationTitle("FlowType")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SetupStatusView()
                    } label: {
                        Image(systemName: "checklist")
                    }
                    .accessibilityLabel("Setup Status")
                }
            }
            .sheet(isPresented: resultSheetBinding) {
                ResultView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Write faster on iPhone")
                        .font(.title2.bold())
                    Text("Choose a mode, speak naturally, and polish before you insert.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                NavigationLink("Setup", destination: SetupStatusView())
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modes")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FlowMode.allCases) { mode in
                        Button(mode.title) {
                            appModel.selectedMode = mode
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appModel.selectedMode == mode ? .blue : .gray.opacity(0.4))
                    }
                }
            }
        }
    }

    private var voiceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Mode")
                .font(.headline)
            Text(appModel.selectedMode.title)
                .font(.title3.weight(.semibold))
            Text(appModel.selectedMode.samplePrompt)
                .foregroundStyle(.secondary)

            Button(appModel.isListening ? "Stop Dictation" : "Start Dictation") {
                if appModel.isListening {
                    appModel.stopDictation()
                } else {
                    appModel.startDictation()
                }
            }
            .buttonStyle(.borderedProminent)

            if appModel.isListening {
                Text("Listening...")
                    .foregroundStyle(.red)
            } else if appModel.isProcessing {
                Text(appModel.processingMessage)
                    .foregroundStyle(.secondary)
            } else if let errorMessage = appModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else {
                Text("\(appModel.usageSnapshot.remainingDictations) free dictations left this week")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $appModel.isShowingPaywall) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Upgrade to Pro")
                        .font(.title2.bold())
                    Text("You have used \(appModel.usageSnapshot.usedDictations) of \(appModel.usageSnapshot.weeklyDictationLimit) free dictations.")
                        .foregroundStyle(.secondary)
                    Button("Close") {
                        appModel.isShowingPaywall = false
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .padding(20)
                .navigationTitle("Paywall")
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.headline)

            ForEach(appModel.sessions.prefix(5)) { session in
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.mode.title)
                        .font(.subheadline.weight(.semibold))
                    Text(session.polishedText)
                        .font(.subheadline)
                    Text(session.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var resultSheetBinding: Binding<Bool> {
        Binding(
            get: { !appModel.currentPolishedText.isEmpty && !appModel.isListening },
            set: { shouldShow in
                if !shouldShow {
                    appModel.currentTranscript = ""
                    appModel.currentPolishedText = ""
                }
            }
        )
    }
}
