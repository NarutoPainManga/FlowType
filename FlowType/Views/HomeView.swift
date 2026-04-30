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
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("Help and Status")
                }
            }
            .sheet(isPresented: resultSheetBinding) {
                ResultView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Turn rough thoughts into polished writing")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Pick a mode, speak naturally, then copy or share the result.")
                .foregroundStyle(.white.opacity(0.8))
            Text("No background listening. FlowType only records when you tap Start Dictation.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
            Text("FlowType asks your permission before sending recordings or text to OpenAI and Supabase for cloud processing.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color("BrandNavy"), Color("BrandInk")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
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
                        .tint(appModel.selectedMode == mode ? Color("BrandTeal") : .gray.opacity(0.4))
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
            .tint(appModel.isListening ? .red : Color("BrandTeal"))

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
                    Text("Weekly Limit Reached")
                        .font(.title2.bold())
                    Text("You have used \(appModel.usageSnapshot.usedDictations) of \(appModel.usageSnapshot.weeklyDictationLimit) dictations for this week.")
                        .foregroundStyle(.secondary)
                    Text("FlowType is still in early release. More usage options are coming, but for now your free limit resets automatically next week.")
                        .foregroundStyle(.secondary)
                    Button("Close") {
                        appModel.isShowingPaywall = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("BrandTeal"))
                    Spacer()
                }
                .padding(20)
                .navigationTitle("Usage Limit")
            }
        }
        .sheet(isPresented: $appModel.isShowingThirdPartyAIConsent) {
            ThirdPartyAIConsentView()
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent On This iPhone")
                .font(.headline)

            if appModel.sessions.isEmpty {
                Text("Your polished drafts will show up here after you finish a session.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
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
