import Foundation

enum SampleData {
    static let sessions: [DictationSession] = [
        DictationSession(
            mode: .slack,
            rawTranscript: "quick update the landing page is ready and i need copy feedback by noon",
            polishedText: "Quick update: the landing page is ready, and I need copy feedback by noon.",
            createdAt: .now.addingTimeInterval(-3600)
        ),
        DictationSession(
            mode: .taskList,
            rawTranscript: "follow up with design finalize pricing and send testflight invites",
            polishedText: "- Follow up with design\n- Finalize pricing\n- Send TestFlight invites",
            createdAt: .now.addingTimeInterval(-7200)
        )
    ]
}
