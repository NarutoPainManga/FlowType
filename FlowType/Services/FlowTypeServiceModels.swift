import Foundation

enum FlowTypeSpendPolicy {
    static let freeWeeklyDictationLimit = 5
    static let freeTransformsPerDraft = 1
}

struct ServiceUnavailableError: LocalizedError, Sendable {
    let reason: String

    var errorDescription: String? {
        reason
    }
}

struct AuthSession: Equatable, Sendable {
    let userID: UUID
    let isAnonymous: Bool
    let createdAt: Date
    let accessToken: String
}

struct UserProfile: Equatable, Sendable {
    let id: UUID
    let favoriteModes: [FlowMode]
    let createdAt: Date
}

struct TranscriptionRequest: Equatable, Sendable {
    let audioPayload: Data
    let localeIdentifier: String
    let mode: FlowMode
}

struct TranscriptionResult: Equatable, Sendable {
    let transcript: String
    let durationSeconds: TimeInterval
}

struct PolishRequest: Equatable, Sendable {
    let transcript: String
    let mode: FlowMode
}

struct PolishResult: Equatable, Sendable {
    let text: String
}

enum TransformIntent: String, CaseIterable, Codable, Sendable {
    case shorter
    case professional
    case friendly
    case bulletList
}

struct TransformRequest: Equatable, Sendable {
    let text: String
    let mode: FlowMode
    let intent: TransformIntent
}

struct TransformResult: Equatable, Sendable {
    let text: String
}

struct AudioCaptureResult: Equatable, Sendable {
    let audioPayload: Data
    let durationSeconds: TimeInterval
    let fileExtension: String
}

struct UsageSnapshot: Equatable, Sendable {
    let weeklyDictationLimit: Int
    let usedDictations: Int
    let weeklyTransformLimit: Int?
    let usedTransforms: Int
    let resetsAt: Date

    var remainingDictations: Int {
        max(weeklyDictationLimit - usedDictations, 0)
    }

    var hasRemainingDictations: Bool {
        remainingDictations > 0
    }

    var remainingTransforms: Int? {
        guard let weeklyTransformLimit else { return nil }
        return max(weeklyTransformLimit - usedTransforms, 0)
    }

    var hasRemainingTransforms: Bool {
        guard let remainingTransforms else { return true }
        return remainingTransforms > 0
    }
}

struct HistoryItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let mode: FlowMode
    let rawTranscript: String
    let polishedText: String
    let createdAt: Date
}

extension HistoryItem {
    init(session: DictationSession) {
        self.id = session.id
        self.mode = session.mode
        self.rawTranscript = session.rawTranscript
        self.polishedText = session.polishedText
        self.createdAt = session.createdAt
    }
}

enum SetupStatusState: Equatable, Sendable {
    case unavailable
    case pending
    case ready
    case failed(message: String)
}

struct SetupStatusItem: Equatable, Sendable {
    let state: SetupStatusState
    let detail: String
}

struct SetupStatusSnapshot: Equatable, Sendable {
    let configuration: SetupStatusItem
    let microphone: SetupStatusItem
    let auth: SetupStatusItem
    let backend: SetupStatusItem

    static let placeholder = SetupStatusSnapshot(
        configuration: SetupStatusItem(state: .pending, detail: "Checking FlowType configuration."),
        microphone: SetupStatusItem(state: .pending, detail: "Checking microphone access."),
        auth: SetupStatusItem(state: .pending, detail: "Checking session state."),
        backend: SetupStatusItem(state: .pending, detail: "Checking backend connectivity.")
    )
}
