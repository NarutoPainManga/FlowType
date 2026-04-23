import Foundation

struct DictationSession: Identifiable, Sendable {
    let id = UUID()
    let mode: FlowMode
    let rawTranscript: String
    let polishedText: String
    let createdAt: Date
}
