import Foundation

enum FlowTypeServiceFactory {
    static func makeServices() -> FlowTypeServices {
        guard let configuration = FlowTypeConfiguration.load() else {
            return unavailableServices(
                reason: "FlowType is not configured correctly yet. Please reinstall or contact support."
            )
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
            configurationStatusProvider: { FlowTypeConfiguration.diagnosticStatus() },
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
        return unavailableServices(
            reason: "FlowType needs the full app build to connect to voice and cloud services."
        )
        #endif
    }

    private static func unavailableServices(reason: String) -> FlowTypeServices {
        let authService = UnavailableAuthService(reason: reason)
        let audioCapture = UnavailableAudioCaptureService(reason: reason)
        let apiClient = UnavailableFlowTypeAPIClient(reason: reason)

        return FlowTypeServices(
            auth: authService,
            audioCapture: audioCapture,
            transcription: UnavailableTranscriptionService(reason: reason),
            polish: UnavailablePolishService(reason: reason),
            transform: UnavailableTransformService(reason: reason),
            usage: UnavailableUsageService(reason: reason),
            history: UnavailableHistoryService(reason: reason),
            diagnostics: FlowTypeDiagnosticsService.live(
                configurationStatusProvider: { FlowTypeConfiguration.diagnosticStatus() },
                audioCapture: audioCapture,
                authService: authService,
                apiClient: apiClient,
                authTokenProvider: { nil }
            )
        )
    }
}
