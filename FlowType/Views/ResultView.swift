import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ResultView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Polished Result")
                    .font(.headline)

                TextEditor(text: $appModel.currentPolishedText)
                    .frame(minHeight: 220)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        quickAction("Shorter", intent: .shorter)
                        quickAction("Professional", intent: .professional)
                        quickAction("Friendly", intent: .friendly)
                        quickAction("Bullet List", intent: .bulletList)
                    }
                }

                Button(didCopy ? "Copied" : "Copy Result") {
                    copyResult()
                }
                .buttonStyle(.borderedProminent)
                .disabled(appModel.currentPolishedText.isEmpty)

                Text("Paste it into Messages, Mail, Slack, or anywhere else on your iPhone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Review")
        }
    }

    private func quickAction(_ title: String, intent: TransformIntent) -> some View {
        Button(title) {
            appModel.transformCurrentText(using: intent)
        }
        .buttonStyle(.bordered)
    }

    private func copyResult() {
        #if canImport(UIKit)
        UIPasteboard.general.string = appModel.currentPolishedText
        #endif
        didCopy = true
    }
}
