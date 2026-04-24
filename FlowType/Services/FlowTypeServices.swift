import Foundation

protocol AuthServicing: Sendable {
    func currentSession() async throws -> AuthSession?
    func signInAnonymously() async throws -> AuthSession
}

protocol TranscriptionServicing: Sendable {
    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult
}

protocol AudioCaptureServicing: Sendable {
    func startCapture() async throws
    func stopCapture() async throws -> AudioCaptureResult
}

protocol PolishServicing: Sendable {
    func polish(_ request: PolishRequest) async throws -> PolishResult
}

protocol TransformServicing: Sendable {
    func transform(_ request: TransformRequest) async throws -> TransformResult
}

protocol UsageServicing: Sendable {
    func fetchUsage(for session: AuthSession) async throws -> UsageSnapshot
    func recordDictation(for session: AuthSession) async throws -> UsageSnapshot
}

protocol HistoryServicing: Sendable {
    func fetchHistory(for session: AuthSession) async throws -> [HistoryItem]
    func save(_ item: HistoryItem, for session: AuthSession) async throws
}

protocol SetupDiagnosticsServicing: Sendable {
    func collectStatus() async -> SetupStatusSnapshot
}

struct FlowTypeServices: Sendable {
    let auth: AuthServicing
    let audioCapture: AudioCaptureServicing
    let transcription: TranscriptionServicing
    let polish: PolishServicing
    let transform: TransformServicing
    let usage: UsageServicing
    let history: HistoryServicing
    let diagnostics: SetupDiagnosticsServicing
}

extension FlowTypeServices {
    static func mock() -> FlowTypeServices {
        let state = MockServiceState()
        return FlowTypeServices(
            auth: MockAuthService(state: state),
            audioCapture: MockAudioCaptureService(),
            transcription: MockTranscriptionService(),
            polish: MockPolishService(),
            transform: MockTransformService(),
            usage: MockUsageService(state: state),
            history: MockHistoryService(state: state),
            diagnostics: MockSetupDiagnosticsService(state: state)
        )
    }
}

actor MockServiceState {
    private(set) var session: AuthSession?
    private(set) var usage: UsageSnapshot
    private var history: [HistoryItem]

    init(
        usage: UsageSnapshot = UsageSnapshot(
            weeklyDictationLimit: 30,
            usedDictations: 2,
            resetsAt: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
        ),
        history: [HistoryItem] = []
    ) {
        self.usage = usage
        self.history = history
    }

    func currentSession() -> AuthSession? {
        session
    }

    func setSession(_ session: AuthSession) {
        self.session = session
    }

    func currentUsage() -> UsageSnapshot {
        usage
    }

    func incrementUsage() -> UsageSnapshot {
        usage = UsageSnapshot(
            weeklyDictationLimit: usage.weeklyDictationLimit,
            usedDictations: usage.usedDictations + 1,
            resetsAt: usage.resetsAt
        )
        return usage
    }

    func allHistory() -> [HistoryItem] {
        history.sorted { $0.createdAt > $1.createdAt }
    }

    func saveHistory(_ item: HistoryItem) {
        history.removeAll { $0.id == item.id }
        history.insert(item, at: 0)
    }
}

struct MockAuthService: AuthServicing {
    private let state: MockServiceState

    init(state: MockServiceState = MockServiceState()) {
        self.state = state
    }

    func currentSession() async throws -> AuthSession? {
        await state.currentSession()
    }

    func signInAnonymously() async throws -> AuthSession {
        if let existing = await state.currentSession() {
            return existing
        }

        let session = AuthSession(
            userID: UUID(),
            isAnonymous: true,
            createdAt: .now,
            accessToken: UUID().uuidString
        )
        await state.setSession(session)
        return session
    }
}

struct MockAudioCaptureService: AudioCaptureServicing, AudioPermissionStatusProviding {
    func startCapture() async throws {}

    func stopCapture() async throws -> AudioCaptureResult {
        AudioCaptureResult(
            audioPayload: Data("mock-audio".utf8),
            durationSeconds: 5,
            fileExtension: "m4a"
        )
    }

    func currentPermissionStatus() async -> SetupStatusItem {
        SetupStatusItem(
            state: .ready,
            detail: "Microphone is available in mock mode."
        )
    }
}

struct MockTranscriptionService: TranscriptionServicing {
    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        let transcript: String
        switch request.mode {
        case .email, .text, .brainDump:
            transcript = "hey just following up on yesterday we can ship the first version by friday if design signs off today"
        case .slack:
            transcript = "quick update we can ship v1 by friday if design signs off today"
        case .meetingNotes:
            transcript = "follow up from yesterday ship the first version by friday pending design sign off"
        case .taskList:
            transcript = "follow up on yesterday confirm design sign off ship first version by friday"
        }

        return TranscriptionResult(transcript: transcript, durationSeconds: 5)
    }
}

struct MockPolishService: PolishServicing {
    func polish(_ request: PolishRequest) async throws -> PolishResult {
        let text: String
        switch request.mode {
        case .email:
            text = "Just following up on yesterday's discussion. We can ship the first version by Friday if design signs off today."
        case .text:
            text = "Quick follow-up from yesterday. We can ship the first version by Friday if design signs off today."
        case .slack:
            text = "Quick update: we can ship v1 by Friday if design signs off today."
        case .meetingNotes:
            text = "Follow-up from yesterday: ship the first version by Friday pending design sign-off today."
        case .taskList:
            text = "- Follow up on yesterday's discussion\n- Confirm design sign-off today\n- Ship the first version by Friday"
        case .brainDump:
            text = "Following up on yesterday. We can ship the first version by Friday if design signs off today."
        }

        return PolishResult(text: text)
    }
}

struct MockTransformService: TransformServicing {
    func transform(_ request: TransformRequest) async throws -> TransformResult {
        let text: String
        switch request.intent {
        case .shorter:
            text = "Quick follow-up: we can ship v1 by Friday if design signs off today."
        case .professional:
            text = "Just following up on yesterday's discussion. We can ship the first version by Friday, assuming design signs off today."
        case .friendly:
            text = "Quick follow-up from yesterday. We should be able to ship the first version by Friday if design signs off today."
        case .bulletList:
            text = "- Follow up on yesterday\n- Get design sign-off today\n- Ship the first version by Friday"
        }

        return TransformResult(text: text)
    }
}

struct MockUsageService: UsageServicing {
    private let state: MockServiceState

    init(state: MockServiceState = MockServiceState()) {
        self.state = state
    }

    func fetchUsage(for session: AuthSession) async throws -> UsageSnapshot {
        _ = session
        return await state.currentUsage()
    }

    func recordDictation(for session: AuthSession) async throws -> UsageSnapshot {
        _ = session
        return await state.incrementUsage()
    }
}

struct MockHistoryService: HistoryServicing {
    private let state: MockServiceState

    init(state: MockServiceState = MockServiceState()) {
        self.state = state
    }

    func fetchHistory(for session: AuthSession) async throws -> [HistoryItem] {
        _ = session
        return await state.allHistory()
    }

    func save(_ item: HistoryItem, for session: AuthSession) async throws {
        _ = session
        await state.saveHistory(item)
    }
}

struct MockSetupDiagnosticsService: SetupDiagnosticsServicing {
    private let state: MockServiceState

    init(state: MockServiceState = MockServiceState()) {
        self.state = state
    }

    func collectStatus() async -> SetupStatusSnapshot {
        let authDetail: SetupStatusItem
        if let session = await state.currentSession() {
            authDetail = SetupStatusItem(
                state: .ready,
                detail: "Anonymous session ready for \(session.userID.uuidString.prefix(8))."
            )
        } else {
            authDetail = SetupStatusItem(
                state: .unavailable,
                detail: "No session yet. The app can create one during setup."
            )
        }

        return SetupStatusSnapshot(
            configuration: SetupStatusItem(
                state: .ready,
                detail: "Using mock configuration."
            ),
            microphone: SetupStatusItem(
                state: .ready,
                detail: "Microphone is available in mock mode."
            ),
            auth: authDetail,
            backend: SetupStatusItem(
                state: .ready,
                detail: "Mock backend services are responding."
            )
        )
    }
}

struct UnavailableAuthService: AuthServicing {
    let reason: String

    func currentSession() async throws -> AuthSession? {
        throw ServiceUnavailableError(reason: reason)
    }

    func signInAnonymously() async throws -> AuthSession {
        throw ServiceUnavailableError(reason: reason)
    }
}

struct UnavailableAudioCaptureService: AudioCaptureServicing, AudioPermissionStatusProviding {
    let reason: String

    func startCapture() async throws {
        throw ServiceUnavailableError(reason: reason)
    }

    func stopCapture() async throws -> AudioCaptureResult {
        throw ServiceUnavailableError(reason: reason)
    }

    func currentPermissionStatus() async -> SetupStatusItem {
        SetupStatusItem(
            state: .failed(message: "FlowType unavailable."),
            detail: reason
        )
    }
}

struct UnavailableTranscriptionService: TranscriptionServicing {
    let reason: String

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        _ = request
        throw ServiceUnavailableError(reason: reason)
    }
}

struct UnavailablePolishService: PolishServicing {
    let reason: String

    func polish(_ request: PolishRequest) async throws -> PolishResult {
        _ = request
        throw ServiceUnavailableError(reason: reason)
    }
}

struct UnavailableTransformService: TransformServicing {
    let reason: String

    func transform(_ request: TransformRequest) async throws -> TransformResult {
        _ = request
        throw ServiceUnavailableError(reason: reason)
    }
}

struct UnavailableUsageService: UsageServicing {
    let reason: String

    func fetchUsage(for session: AuthSession) async throws -> UsageSnapshot {
        _ = session
        throw ServiceUnavailableError(reason: reason)
    }

    func recordDictation(for session: AuthSession) async throws -> UsageSnapshot {
        _ = session
        throw ServiceUnavailableError(reason: reason)
    }
}

struct UnavailableHistoryService: HistoryServicing {
    let reason: String

    func fetchHistory(for session: AuthSession) async throws -> [HistoryItem] {
        _ = session
        throw ServiceUnavailableError(reason: reason)
    }

    func save(_ item: HistoryItem, for session: AuthSession) async throws {
        _ = item
        _ = session
        throw ServiceUnavailableError(reason: reason)
    }
}
