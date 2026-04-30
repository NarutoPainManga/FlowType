import SwiftUI

enum LegalDocument: String, CaseIterable, Identifiable {
    case privacy = "Privacy Policy"
    case terms = "Terms of Service"
    case support = "Support Guide"

    var id: String { rawValue }

    var navigationTitle: String { rawValue }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        List {
            ForEach(document.sections) { section in
                Section(section.title) {
                    Text(section.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(document.navigationTitle)
    }
}

private struct LegalSection: Identifiable {
    let title: String
    let body: String

    var id: String { title }
}

private extension LegalDocument {
    var sections: [LegalSection] {
        switch self {
        case .privacy:
            return [
                LegalSection(
                    title: "What FlowType Processes",
                    body: "FlowType processes the audio you record, the transcript created from that recording, the polished text returned to you, rewrite text you request, and basic anonymous session information needed to connect the app to its backend services."
                ),
                LegalSection(
                    title: "How FlowType Uses Data",
                    body: "FlowType uses this information to transcribe speech, polish text, apply rewrite actions, and enforce usage limits. Recording only starts after you tap the record button."
                ),
                LegalSection(
                    title: "Local Storage",
                    body: "Recent polished drafts are stored on this iPhone so you can reopen them later. You can clear recent drafts from Help & Status."
                ),
                LegalSection(
                    title: "Third-Party Services",
                    body: "FlowType sends approved requests to Supabase and OpenAI. Supabase hosts anonymous authentication and backend endpoints. OpenAI processes audio transcription and generates polished or rewritten text."
                ),
                LegalSection(
                    title: "Permission",
                    body: "Before FlowType sends recordings, transcripts, polished text, or rewrite text for AI processing, the app asks for your permission. You can withdraw that permission from Help & Status."
                )
            ]
        case .terms:
            return [
                LegalSection(
                    title: "Using FlowType",
                    body: "FlowType is designed to turn rough speech into send-ready writing. You are responsible for reviewing and deciding how to use any transcript or rewritten result."
                ),
                LegalSection(
                    title: "Limits And Availability",
                    body: "Features, usage limits, and availability may change over time, especially during early release. Weekly dictation limits are shown in the app when available."
                ),
                LegalSection(
                    title: "Output Quality",
                    body: "Transcripts and AI-generated rewrites may contain mistakes. Always check the result before relying on it in work, school, legal, medical, or financial situations."
                )
            ]
        case .support:
            return [
                LegalSection(
                    title: "How FlowType Works",
                    body: "Choose a mode, record a short voice note, review the polished result, then copy or share it into the app you want to use."
                ),
                LegalSection(
                    title: "Common Fixes",
                    body: "If recording fails, confirm microphone access, reopen the app, and refresh the checks in Help & Status. If cloud processing is unavailable, reconnect to the internet and try again."
                ),
                LegalSection(
                    title: "Early Release",
                    body: "FlowType is still in early release. If something feels off, treat the result as a draft and verify important details before sending."
                )
            ]
        }
    }
}
