import Foundation

struct FlowTypeConfiguration: Sendable {
    let supabaseURL: URL
    let supabasePublishableKey: String
    let functionsBaseURL: URL

    static func load() -> FlowTypeConfiguration? {
        if let plistConfig = loadFromPlist() {
            return plistConfig
        }

        return loadFromEnvironment()
    }

    static func diagnosticStatus() -> SetupStatusItem {
        if let plistConfig = loadFromPlist() {
            return SetupStatusItem(
                state: .ready,
                detail: "Loaded Supabase settings from FlowTypeConfig.plist for \(plistConfig.supabaseURL.host ?? plistConfig.supabaseURL.absoluteString)."
            )
        }

        if let environmentConfig = loadFromEnvironment() {
            return SetupStatusItem(
                state: .ready,
                detail: "Loaded Supabase settings from environment for \(environmentConfig.supabaseURL.host ?? environmentConfig.supabaseURL.absoluteString)."
            )
        }

        return SetupStatusItem(
            state: .failed(message: "Missing FlowType configuration."),
            detail: "Add FlowTypeConfig.plist or SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY."
        )
    }

    private static func loadFromPlist() -> FlowTypeConfiguration? {
        guard let url = Bundle.main.url(forResource: "FlowTypeConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dictionary = object as? [String: Any],
              let supabaseURLString = dictionary["SUPABASE_URL"] as? String,
              let supabaseURL = URL(string: supabaseURLString),
              let publishableKey = dictionary["SUPABASE_PUBLISHABLE_KEY"] as? String
        else {
            return nil
        }

        let functionsBaseURL: URL
        if let functionsURLString = dictionary["SUPABASE_FUNCTIONS_URL"] as? String,
           let explicitFunctionsURL = URL(string: functionsURLString) {
            functionsBaseURL = explicitFunctionsURL
        } else {
            functionsBaseURL = supabaseURL.appending(path: "/functions/v1", directoryHint: .notDirectory)
        }

        return FlowTypeConfiguration(
            supabaseURL: supabaseURL,
            supabasePublishableKey: publishableKey,
            functionsBaseURL: functionsBaseURL
        )
    }

    private static func loadFromEnvironment() -> FlowTypeConfiguration? {
        guard let supabaseURLString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
              let supabaseURL = URL(string: supabaseURLString),
              let publishableKey = ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"]
        else {
            return nil
        }

        let functionsBaseURL: URL
        if let functionsURLString = ProcessInfo.processInfo.environment["SUPABASE_FUNCTIONS_URL"],
           let explicitFunctionsURL = URL(string: functionsURLString) {
            functionsBaseURL = explicitFunctionsURL
        } else {
            functionsBaseURL = supabaseURL.appending(path: "/functions/v1", directoryHint: .notDirectory)
        }

        return FlowTypeConfiguration(
            supabaseURL: supabaseURL,
            supabasePublishableKey: publishableKey,
            functionsBaseURL: functionsBaseURL
        )
    }
}
