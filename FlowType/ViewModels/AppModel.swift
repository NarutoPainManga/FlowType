import Foundation
import SwiftUI
import Combine

@MainActor
final class AppModel: ObservableObject {
    enum StorageKeys {
        static let hasCompletedOnboarding = "flowtype.hasCompletedOnboarding"
        static let localSessions = "flowtype.localSessions"
    }

    @Published var hasCompletedOnboarding = false
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
    @Published var usageSnapshot = UsageSnapshot(
        weeklyDictationLimit: 30,
        usedDictations: 0,
        resetsAt: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    )
    @Published var authSession: AuthSession?
    @Published var setupStatus = SetupStatusSnapshot.placeholder
    @Published var isRefreshingSetupStatus = false

    private let services: FlowTypeServices

    init(services: FlowTypeServices) {
        self.services = services
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: StorageKeys.hasCompletedOnboarding)
        self.sessions = Self.loadStoredSessions()
        Task {
            await bootstrap()
        }
    }

    func startDictation() {
        guard !isProcessing else { return }
        currentPolishedText = ""
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
        isProcessing = true

        Task {
            do {
                let result = try await services.transform.transform(
                    TransformRequest(text: currentPolishedText, mode: selectedMode, intent: intent)
                )
                await MainActor.run {
                    self.currentPolishedText = result.text
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
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
            let usage = try await services.usage.fetchUsage(for: session)
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

    static func resetLocalState() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.hasCompletedOnboarding)
        UserDefaults.standard.removeObject(forKey: StorageKeys.localSessions)
    }

    static func seedForTesting(hasCompletedOnboarding: Bool) {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: StorageKeys.hasCompletedOnboarding)
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
}
