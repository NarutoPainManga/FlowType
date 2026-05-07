import Foundation
import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    enum StorageKeys {
        static let hasCompletedOnboarding = "flowtype.hasCompletedOnboarding"
        static let localSessions = "flowtype.localSessions"
        static let hasAcceptedThirdPartyAIConsent = "flowtype.hasAcceptedThirdPartyAIConsent"
    }

    static let defaultUsageSnapshot = UsageSnapshot(
        weeklyDictationLimit: FlowTypeSpendPolicy.freeWeeklyDictationLimit,
        usedDictations: 0,
        weeklyTransformLimit: 0,
        usedTransforms: 0,
        resetsAt: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    )

    @Published var hasCompletedOnboarding = false
    @Published var hasAcceptedThirdPartyAIConsent = false
    @Published var selectedMode: FlowMode = .email
    @Published var favoriteModes: [FlowMode] = [.email, .slack, .taskList]
    @Published var sessions: [DictationSession] = []
    @Published var currentTranscript = ""
    @Published var currentPolishedText = ""
    @Published var isListening = false
    @Published var isProcessing = false
    @Published var processingMessage = "Polishing..."
    @Published var isShowingPaywall = false
    @Published var errorMessage: String?
    @Published var usageSnapshot = AppModel.defaultUsageSnapshot
    @Published var authSession: AuthSession?
    @Published var setupStatus = SetupStatusSnapshot.placeholder
    @Published var isRefreshingSetupStatus = false
    @Published var isDeletingAccount = false
    @Published var isShowingThirdPartyAIConsent = false
    @Published private(set) var remainingFreeTransformsForCurrentDraft = FlowTypeSpendPolicy.freeTransformsPerDraft

    private let services: FlowTypeServices
    private var pendingCloudAction: PendingCloudAction?

    private enum PendingCloudAction {
        case startDictation
        case transform(TransformIntent)
    }

    init(services: FlowTypeServices, shouldBootstrap: Bool = true) {
        self.services = services
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: StorageKeys.hasCompletedOnboarding)
        self.hasAcceptedThirdPartyAIConsent = UserDefaults.standard.bool(forKey: StorageKeys.hasAcceptedThirdPartyAIConsent)
        self.sessions = Self.loadStoredSessions()
        if shouldBootstrap {
            Task {
                await bootstrap()
            }
        }
    }

    func startDictation() {
        guard !isProcessing else { return }
        guard hasAcceptedThirdPartyAIConsent else {
            pendingCloudAction = .startDictation
            isShowingThirdPartyAIConsent = true
            return
        }

        beginStartDictation()
    }

    private func beginStartDictation() {
        currentPolishedText = ""
        remainingFreeTransformsForCurrentDraft = FlowTypeSpendPolicy.freeTransformsPerDraft
        Task {
            let session = await ensureSession()
            guard let session else {
                await MainActor.run {
                    self.isListening = false
                    self.errorMessage = "FlowType couldn't start right now. Please try again in a moment."
                }
                return
            }

            if !(await refreshUsage(for: session)).hasRemainingDictations {
                await MainActor.run {
                    self.isListening = false
                    self.isShowingPaywall = true
                }
                return
            }

            do {
                await MainActor.run {
                    self.errorMessage = nil
                    self.isListening = true
                }
                try await services.audioCapture.startCapture()
            } catch {
                await MainActor.run {
                    self.currentTranscript = ""
                    self.isListening = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopDictation() {
        guard isListening else { return }
        isListening = false
        isProcessing = true
        processingMessage = "Finishing recording..."

        Task {
            do {
                print("[FlowType] stopDictation: stopping audio capture")
                let audioCapture = try await services.audioCapture.stopCapture()
                print("[FlowType] stopDictation: captured \(audioCapture.audioPayload.count) bytes over \(audioCapture.durationSeconds)s")
                await MainActor.run {
                    self.processingMessage = "Transcribing..."
                }
                let result = try await services.transcription.transcribe(
                    TranscriptionRequest(
                        audioPayload: audioCapture.audioPayload,
                        localeIdentifier: Locale.current.identifier,
                        mode: selectedMode
                    )
                )
                print("[FlowType] stopDictation: transcript length \(result.transcript.count)")
                await MainActor.run {
                    self.currentTranscript = result.transcript
                    self.processingMessage = "Polishing..."
                }

                let polished = try await services.polish.polish(
                    PolishRequest(transcript: result.transcript, mode: selectedMode)
                )
                print("[FlowType] stopDictation: polished length \(polished.text.count)")

                await MainActor.run {
                    self.currentPolishedText = polished.text
                    self.saveCurrentSession()
                    self.isProcessing = false
                    self.processingMessage = "Polishing..."
                }

                if let session = await ensureSession() {
                    let updatedUsage = try await services.usage.recordDictation(for: session)
                    await MainActor.run {
                        self.usageSnapshot = updatedUsage
                        self.isShowingPaywall = !updatedUsage.hasRemainingDictations
                    }
                }
            } catch {
                print("[FlowType] stopDictation error: \(error.localizedDescription)")
                await MainActor.run {
                    self.currentPolishedText = ""
                    self.isProcessing = false
                    self.processingMessage = "Polishing..."
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func saveCurrentSession() {
        guard !currentTranscript.isEmpty, !currentPolishedText.isEmpty else { return }
        let session = DictationSession(
            mode: selectedMode,
            rawTranscript: currentTranscript,
            polishedText: currentPolishedText,
            createdAt: .now
        )
        sessions.insert(session, at: 0)
        persistSessions()
        Task {
            guard let authSession = await ensureSession() else { return }
            try? await services.history.save(HistoryItem(session: session), for: authSession)
        }
    }

    func transformCurrentText(using intent: TransformIntent) {
        guard !currentPolishedText.isEmpty, !isProcessing else { return }
        guard usageSnapshot.hasRemainingTransforms else {
            errorMessage = "You've used all free AI rewrites available from this week's completed dictations."
            return
        }
        guard remainingFreeTransformsForCurrentDraft > 0 else {
            errorMessage = "Free accounts currently include one AI rewrite per draft to keep usage sustainable."
            return
        }
        guard hasAcceptedThirdPartyAIConsent else {
            pendingCloudAction = .transform(intent)
            isShowingThirdPartyAIConsent = true
            return
        }

        beginTransformCurrentText(using: intent)
    }

    private func beginTransformCurrentText(using intent: TransformIntent) {
        isProcessing = true

        Task {
            do {
                let result = try await services.transform.transform(
                    TransformRequest(text: currentPolishedText, mode: selectedMode, intent: intent)
                )
                await MainActor.run {
                    self.currentPolishedText = result.text
                    self.remainingFreeTransformsForCurrentDraft = max(self.remainingFreeTransformsForCurrentDraft - 1, 0)
                    self.isProcessing = false
                }

                if let session = await ensureSession() {
                    _ = await refreshUsage(for: session)
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func acceptThirdPartyAIConsent() {
        hasAcceptedThirdPartyAIConsent = true
        UserDefaults.standard.set(true, forKey: StorageKeys.hasAcceptedThirdPartyAIConsent)
        isShowingThirdPartyAIConsent = false

        let pendingAction = pendingCloudAction
        pendingCloudAction = nil

        switch pendingAction {
        case .startDictation:
            beginStartDictation()
        case let .transform(intent):
            beginTransformCurrentText(using: intent)
        case nil:
            break
        }
    }

    func declineThirdPartyAIConsent() {
        pendingCloudAction = nil
        isShowingThirdPartyAIConsent = false
        errorMessage = "FlowType needs your permission before sending recordings or text to OpenAI and Supabase for cloud processing."
    }

    func revokeThirdPartyAIConsent() {
        hasAcceptedThirdPartyAIConsent = false
        UserDefaults.standard.removeObject(forKey: StorageKeys.hasAcceptedThirdPartyAIConsent)
    }

    func refreshSetupStatus() {
        Task {
            await MainActor.run {
                self.isRefreshingSetupStatus = true
            }

            let snapshot = await services.diagnostics.collectStatus()

            await MainActor.run {
                self.setupStatus = snapshot
                self.isRefreshingSetupStatus = false
            }
        }
    }

    private func bootstrap() async {
        refreshSetupStatus()
        guard let session = await ensureSession() else { return }
        _ = await refreshUsage(for: session)
        await loadHistory(for: session)
        refreshSetupStatus()
    }

    private func ensureSession() async -> AuthSession? {
        if let authSession {
            return authSession
        }

        do {
            if let existing = try await services.auth.currentSession() {
                authSession = existing
                refreshSetupStatus()
                return existing
            }

            let created = try await services.auth.signInAnonymously()
            authSession = created
            refreshSetupStatus()
            return created
        } catch {
            refreshSetupStatus()
            return nil
        }
    }

    private func refreshUsage(for session: AuthSession) async -> UsageSnapshot {
        do {
            let usage = Self.normalizedUsage(try await services.usage.fetchUsage(for: session))
            await MainActor.run {
                self.usageSnapshot = usage
                self.isShowingPaywall = !usage.hasRemainingDictations
            }
            return usage
        } catch {
            return usageSnapshot
        }
    }

    private func loadHistory(for session: AuthSession) async {
        do {
            let history = try await services.history.fetchHistory(for: session)
            let mapped = history.map {
                DictationSession(
                    id: $0.id,
                    mode: $0.mode,
                    rawTranscript: $0.rawTranscript,
                    polishedText: $0.polishedText,
                    createdAt: $0.createdAt
                )
            }
            guard !mapped.isEmpty else { return }
            await MainActor.run {
                self.sessions = mapped
                self.persistSessions()
            }
        } catch {
            return
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: StorageKeys.hasCompletedOnboarding)
    }

    func clearLocalHistory() {
        sessions = []
        persistSessions()
    }

    func deleteAnonymousAccount() {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true

        Task {
            do {
                try await services.account.deleteCurrentAccount()
                try? await services.auth.signOut()

                await MainActor.run {
                    self.authSession = nil
                    self.sessions = []
                    self.currentTranscript = ""
                    self.currentPolishedText = ""
                    self.errorMessage = nil
                    self.usageSnapshot = AppModel.defaultUsageSnapshot
                    self.isShowingPaywall = false
                    self.persistSessions()
                    self.isDeletingAccount = false
                    self.refreshSetupStatus()
                }
            } catch {
                await MainActor.run {
                    self.isDeletingAccount = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    static func resetLocalState() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: StorageKeys.localSessions)
        UserDefaults.standard.removeObject(forKey: StorageKeys.hasAcceptedThirdPartyAIConsent)
    }

    static func seedForTesting(hasCompletedOnboarding: Bool) {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: StorageKeys.hasCompletedOnboarding)
        UserDefaults.standard.set(true, forKey: StorageKeys.hasAcceptedThirdPartyAIConsent)
    }

    func applyScreenshotScenario(_ scenario: String) {
        hasCompletedOnboarding = scenario != "onboarding"
        hasAcceptedThirdPartyAIConsent = true
        if hasCompletedOnboarding {
            UserDefaults.standard.set(true, forKey: StorageKeys.hasCompletedOnboarding)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKeys.hasCompletedOnboarding)
        }
        UserDefaults.standard.set(true, forKey: StorageKeys.hasAcceptedThirdPartyAIConsent)

        let sampleSessions = Self.screenshotSessions
        sessions = scenario == "onboarding" ? [] : sampleSessions
        currentTranscript = ""
        currentPolishedText = ""
        remainingFreeTransformsForCurrentDraft = FlowTypeSpendPolicy.freeTransformsPerDraft
        isListening = false
        isProcessing = false
        processingMessage = "Polishing..."
        errorMessage = nil
        isShowingPaywall = false
        selectedMode = .slack
        favoriteModes = [.slack, .email, .meetingNotes]
        usageSnapshot = UsageSnapshot(
            weeklyDictationLimit: FlowTypeSpendPolicy.freeWeeklyDictationLimit,
            usedDictations: 3,
            weeklyTransformLimit: 3,
            usedTransforms: 1,
            resetsAt: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now
        )
        setupStatus = SetupStatusSnapshot(
            configuration: SetupStatusItem(state: .ready, detail: "FlowType is connected and ready."),
            microphone: SetupStatusItem(state: .ready, detail: "Microphone access has been granted."),
            auth: SetupStatusItem(state: .ready, detail: "Anonymous session is available."),
            backend: SetupStatusItem(state: .ready, detail: "Transcription and polishing services are responding.")
        )

        switch scenario {
        case "review":
            selectedMode = .email
            currentTranscript = "client wants a friday homepage refresh and simpler pricing"
            currentPolishedText = "Client update: refresh the homepage by Friday and simplify pricing."
            remainingFreeTransformsForCurrentDraft = 1
        case "usage":
            selectedMode = .email
            usageSnapshot = UsageSnapshot(
                weeklyDictationLimit: FlowTypeSpendPolicy.freeWeeklyDictationLimit,
                usedDictations: FlowTypeSpendPolicy.freeWeeklyDictationLimit,
                weeklyTransformLimit: FlowTypeSpendPolicy.freeWeeklyDictationLimit,
                usedTransforms: FlowTypeSpendPolicy.freeWeeklyDictationLimit,
                resetsAt: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
            )
            isShowingPaywall = true
        case "history":
            selectedMode = .meetingNotes
            favoriteModes = [.meetingNotes, .taskList, .slack]
        case "help":
            selectedMode = .meetingNotes
        case "onboarding":
            usageSnapshot = AppModel.defaultUsageSnapshot
            setupStatus = SetupStatusSnapshot.placeholder
        default:
            break
        }

        persistSessions()
    }

    private func persistSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.localSessions)
    }

    private static func loadStoredSessions() -> [DictationSession] {
        guard let data = UserDefaults.standard.data(forKey: StorageKeys.localSessions),
              let sessions = try? JSONDecoder().decode([DictationSession].self, from: data) else {
            return []
        }

        return sessions.sorted { $0.createdAt > $1.createdAt }
    }

    private static var screenshotSessions: [DictationSession] {
        [
            DictationSession(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
                mode: .slack,
                rawTranscript: "quick update for the team we shipped the signup fix and support volume is already down",
                polishedText: "Quick team update: we shipped the signup fix, and support volume is already trending down.",
                createdAt: .now.addingTimeInterval(-900)
            ),
            DictationSession(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
                mode: .meetingNotes,
                rawTranscript: "client wants mobile speed reviewed this week and homepage copy tightened before launch",
                polishedText: "Client notes: review mobile performance this week and tighten homepage copy before launch.",
                createdAt: .now.addingTimeInterval(-3600)
            ),
            DictationSession(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
                mode: .taskList,
                rawTranscript: "follow up with design update pricing section and send recap",
                polishedText: "Tasks: follow up with design, update the pricing section, and send the recap.",
                createdAt: .now.addingTimeInterval(-7200)
            ),
            DictationSession(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(),
                mode: .email,
                rawTranscript: "send launch draft to client and ask for final signoff",
                polishedText: "Please review the latest launch draft and let me know if we have final signoff.",
                createdAt: .now.addingTimeInterval(-10800)
            ),
            DictationSession(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555") ?? UUID(),
                mode: .brainDump,
                rawTranscript: "thinking through pricing message onboarding friction and demo timing",
                polishedText: "Thinking through pricing messaging, onboarding friction, and demo timing before the launch push.",
                createdAt: .now.addingTimeInterval(-14400)
            )
        ]
    }

    private static func normalizedUsage(_ usage: UsageSnapshot) -> UsageSnapshot {
        let weeklyLimit = min(usage.weeklyDictationLimit, FlowTypeSpendPolicy.freeWeeklyDictationLimit)
        let usedDictations = min(usage.usedDictations, weeklyLimit)

        return UsageSnapshot(
            weeklyDictationLimit: weeklyLimit,
            usedDictations: usedDictations,
            weeklyTransformLimit: min(usage.weeklyTransformLimit ?? usedDictations, usedDictations),
            usedTransforms: min(usage.usedTransforms, min(usage.weeklyTransformLimit ?? usedDictations, usedDictations)),
            resetsAt: usage.resetsAt
        )
    }
}
