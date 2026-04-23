import Foundation

enum FlowMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case email
    case text
    case slack
    case meetingNotes = "meeting_notes"
    case taskList = "task_list"
    case brainDump = "brain_dump"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .email: return "Email"
        case .text: return "Text"
        case .slack: return "Slack"
        case .meetingNotes: return "Meeting Notes"
        case .taskList: return "Task List"
        case .brainDump: return "Brain Dump"
        }
    }

    var samplePrompt: String {
        switch self {
        case .email:
            return "Turn speech into a concise professional email."
        case .text:
            return "Turn speech into a casual clean text message."
        case .slack:
            return "Turn speech into a short team-ready Slack update."
        case .meetingNotes:
            return "Turn speech into clear notes with decisions and action items."
        case .taskList:
            return "Turn speech into a structured checklist."
        case .brainDump:
            return "Clean up speech while keeping the user's original thinking."
        }
    }
}
