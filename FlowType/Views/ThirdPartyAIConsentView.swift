import SwiftUI

struct ThirdPartyAIConsentView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Before FlowType sends data for AI processing")
                        .font(.title.bold())

                    Text("FlowType needs your permission before it sends personal data to third-party services for transcription, polishing, and rewrite features.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        consentRow(
                            title: "What FlowType may send",
                            body: "Your voice recording, transcript, polished result, rewrite text, selected writing mode, and anonymous session token used to authorize the request."
                        )
                        consentRow(
                            title: "Who receives it",
                            body: "Supabase hosts FlowType's backend and anonymous auth. OpenAI processes audio transcription and generates polished or rewritten text."
                        )
                        consentRow(
                            title: "When it is sent",
                            body: "Only after you tap Start Dictation or use an AI rewrite action, and only after you choose Allow below."
                        )
                        consentRow(
                            title: "Your control",
                            body: "You can review or withdraw this permission later in Help & Status. If you do not allow it, FlowType will not send recordings or text for AI processing."
                        )
                    }

                    Text("By continuing, you confirm that you want FlowType to send this data to Supabase and OpenAI so the app can create your transcript and polished writing.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .navigationTitle("AI Processing Permission")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") {
                        appModel.declineThirdPartyAIConsent()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Allow") {
                        appModel.acceptThirdPartyAIConsent()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func consentRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
