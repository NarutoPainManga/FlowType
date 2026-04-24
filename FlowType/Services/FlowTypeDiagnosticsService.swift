import Foundation

struct FlowTypeDiagnosticsService: SetupDiagnosticsServicing {
    private let configurationStatusProvider: @Sendable () -> SetupStatusItem
    private let microphoneStatusProvider: @Sendable () async -> SetupStatusItem
    private let authStatusProvider: @Sendable () async -> SetupStatusItem
    private let backendStatusProvider: @Sendable () async -> SetupStatusItem

    init(
        configurationStatusProvider: @escaping @Sendable () -> SetupStatusItem,
        microphoneStatusProvider: @escaping @Sendable () async -> SetupStatusItem,
        authStatusProvider: @escaping @Sendable () async -> SetupStatusItem,
        backendStatusProvider: @escaping @Sendable () async -> SetupStatusItem
    ) {
        self.configurationStatusProvider = configurationStatusProvider
        self.microphoneStatusProvider = microphoneStatusProvider
        self.authStatusProvider = authStatusProvider
        self.backendStatusProvider = backendStatusProvider
    }

    func collectStatus() async -> SetupStatusSnapshot {
        async let microphone = microphoneStatusProvider()
        async let auth = authStatusProvider()
        async let backend = backendStatusProvider()

        return SetupStatusSnapshot(
            configuration: configurationStatusProvider(),
            microphone: await microphone,
            auth: await auth,
            backend: await backend
        )
    }
}

extension FlowTypeDiagnosticsService {
    static func live(
        configurationStatusProvider: @escaping @Sendable () -> SetupStatusItem,
        audioCapture: (any AudioPermissionStatusProviding)?,
        authService: any AuthServicing,
        apiClient: FlowTypeAPIClientProtocol,
        authTokenProvider: @escaping @Sendable () async -> String?
    ) -> FlowTypeDiagnosticsService {
        FlowTypeDiagnosticsService(
            configurationStatusProvider: configurationStatusProvider,
            microphoneStatusProvider: {
                guard let audioCapture else {
                    return SetupStatusItem(
                        state: .failed(message: "Microphone diagnostics unavailable."),
                        detail: "The current audio capture service does not expose permission state."
                    )
                }

                return await audioCapture.currentPermissionStatus()
            },
            authStatusProvider: {
                do {
                    guard let session = try await authService.currentSession() else {
                        return SetupStatusItem(
                            state: .unavailable,
                            detail: "No active session yet. Anonymous auth will be created during setup."
                        )
                    }

                    return SetupStatusItem(
                        state: .ready,
                        detail: session.isAnonymous
                            ? "Anonymous auth session is active."
                            : "Authenticated session is active."
                    )
                } catch {
                    return SetupStatusItem(
                        state: .failed(message: "Session check failed."),
                        detail: error.localizedDescription
                    )
                }
            },
            backendStatusProvider: {
                let headers: [String: String]
                if let token = await authTokenProvider() {
                    headers = ["Authorization": "Bearer \(token)"]
                } else {
                    headers = [:]
                }

                do {
                    let response = try await apiClient.send(
                        FlowTypeAPIRequest(
                            path: "usage",
                            method: "GET",
                            headers: headers
                        )
                    )

                    switch response.statusCode {
                    case 200..<300:
                        return SetupStatusItem(
                            state: .ready,
                            detail: "Backend functions are reachable."
                        )
                    case 401, 403:
                        return SetupStatusItem(
                            state: .unavailable,
                            detail: "Backend is reachable and waiting for a valid session."
                        )
                    default:
                        return SetupStatusItem(
                            state: .failed(message: "Backend probe failed."),
                            detail: "Usage endpoint returned HTTP \(response.statusCode)."
                        )
                    }
                } catch {
                    return SetupStatusItem(
                        state: .failed(message: "Backend probe failed."),
                        detail: error.localizedDescription
                    )
                }
            }
        )
    }
}
