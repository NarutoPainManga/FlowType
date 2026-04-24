import Foundation

struct DictationSession: Identifiable, Codable, Sendable {
    let id: UUID
    let mode: FlowMode
    let rawTranscript: String
    let polishedText: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        mode: FlowMode,
        rawTranscript: String,
        polishedText: String,
        createdAt: Date
    ) {
        self.id = id
        self.mode = mode
        self.rawTranscript = rawTranscript
        self.polishedText = polishedText
        self.createdAt = createdAt
    }
}
