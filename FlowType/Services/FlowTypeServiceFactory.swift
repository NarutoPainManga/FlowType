import Foundation

enum FlowTypeServiceFactory {
    static func makeServices() -> FlowTypeServices {
        guard let configuration = FlowTypeConfiguration.load() else {
            return .mock
        }

        #if canImport(Supabase)
        let supabaseClient = makeSupabaseClient(configuration: configuration)
        let authService = SupabaseAuthService(client: supabaseClient)
        let audioCapture = SystemAudioCaptureService()
        let apiClient = FlowTypeAPIClient(
            baseURL: configuration.functionsBaseURL,
            defaultHeaders: [
                "apikey": configuration.supabasePublishableKey
            ]
        )
        let diagnostics = FlowTypeDiagnosticsService.live(
            audioCapture: audioCapture,
            authService: authService,
            apiClient: apiClient,
            authTokenProvider: { try? await authService.currentAccessToken() }
        )

        return FlowTypeServices(
            auth: authService,
            audioCapture: audioCapture,
            transcription: RemoteTranscriptionService(
                apiClient: apiClient,
                authTokenProvider: { try? await authService.currentAccessToken() }
            ),
            polish: RemotePolishService(
                apiClient: apiClient,
                authTokenProvider: { try? await authService.currentAccessToken() }
            ),
            transform: RemoteTransformService(
                apiClient: apiClient,
                authTokenProvider: { try? await authService.currentAccessToken() }
            ),
            usage: RemoteUsageService(
                apiClient: apiClient,
                authTokenProvider: { try? await authService.currentAccessToken() }
            ),
            history: RemoteHistoryService(),
            diagnostics: diagnostics
        )
        #else
        let state = MockServiceState()
        let authService = MockAuthService(state: state)
        let audioCapture = SystemAudioCaptureService()
        return FlowTypeServices(
            auth: authService,
            audioCapture: audioCapture,
            transcription: MockTranscriptionService(),
            polish: MockPolishService(),
            transform: MockTransformService(),
            usage: MockUsageService(state: state),
            history: MockHistoryService(state: state),
            diagnostics: FlowTypeDiagnosticsService.live(
                audioCapture: audioCapture,
                authService: authService,
                apiClient: MockFlowTypeAPIClient(),
                authTokenProvider: { nil }
            )
        )
        #endif
    }
}
