import Foundation

enum RemoteFlowTypeServiceError: Error {
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case unsupported
}

extension RemoteFlowTypeServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The backend returned an unexpected response."
        case let .requestFailed(statusCode, message):
            return "Backend request failed (HTTP \(statusCode)): \(message)"
        case .unsupported:
            return "This feature is not available in the current build."
        }
    }
}

extension FlowTypeServices {
    static func live(
        apiClient: FlowTypeAPIClientProtocol,
        sessionProvider: @escaping @Sendable () async -> AuthSession? = { nil },
        audioCapture: any AudioCaptureServicing & AudioPermissionStatusProviding = MockAudioCaptureService()
    ) -> FlowTypeServices {
        let tokenProvider: @Sendable () async -> String? = {
            await sessionProvider()?.accessToken
        }

        let authService = RemoteAuthService(sessionProvider: sessionProvider)

        return FlowTypeServices(
            auth: authService,
            account: RemoteAccountService(apiClient: apiClient, authTokenProvider: tokenProvider),
            audioCapture: audioCapture,
            transcription: RemoteTranscriptionService(apiClient: apiClient, authTokenProvider: tokenProvider),
            polish: RemotePolishService(apiClient: apiClient, authTokenProvider: tokenProvider),
            transform: RemoteTransformService(apiClient: apiClient, authTokenProvider: tokenProvider),
            usage: RemoteUsageService(apiClient: apiClient, authTokenProvider: tokenProvider),
            history: RemoteHistoryService(),
            diagnostics: FlowTypeDiagnosticsService.live(
                configurationStatusProvider: { FlowTypeConfiguration.diagnosticStatus() },
                audioCapture: audioCapture,
                authService: authService,
                apiClient: apiClient,
                authTokenProvider: tokenProvider
            )
        )
    }
}

struct RemoteAuthService: AuthServicing {
    private let sessionProvider: @Sendable () async -> AuthSession?

    init(sessionProvider: @escaping @Sendable () async -> AuthSession? = { nil }) {
        self.sessionProvider = sessionProvider
    }

    func currentSession() async throws -> AuthSession? {
        await sessionProvider()
    }

    func signInAnonymously() async throws -> AuthSession {
        throw RemoteFlowTypeServiceError.unsupported
    }

    func signOut() async throws {
        throw RemoteFlowTypeServiceError.unsupported
    }
}

struct RemoteAccountService: AccountServicing {
    private let apiClient: FlowTypeAPIClientProtocol
    private let authTokenProvider: @Sendable () async -> String?

    init(
        apiClient: FlowTypeAPIClientProtocol,
        authTokenProvider: @escaping @Sendable () async -> String? = { nil }
    ) {
        self.apiClient = apiClient
        self.authTokenProvider = authTokenProvider
    }

    func deleteCurrentAccount() async throws {
        let response = try await apiClient.send(
            FlowTypeAPIRequest(
                path: "account",
                method: "DELETE",
                headers: await authorizationHeader()
            )
        )

        guard (200..<300).contains(response.statusCode) else {
            throw response.remoteError
        }
    }

    private func authorizationHeader() async -> [String: String] {
        guard let token = await authTokenProvider() else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }
}

struct RemoteTranscriptionService: TranscriptionServicing {
    private let apiClient: FlowTypeAPIClientProtocol
    private let decoder = JSONDecoder()
    private let authTokenProvider: @Sendable () async -> String?

    init(
        apiClient: FlowTypeAPIClientProtocol,
        authTokenProvider: @escaping @Sendable () async -> String? = { nil }
    ) {
        self.apiClient = apiClient
        self.authTokenProvider = authTokenProvider
    }

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        let multipart = MultipartFormData(fields: [
            MultipartField(
                name: "audio",
                fileName: "dictation.m4a",
                contentType: "audio/m4a",
                data: request.audioPayload
            ),
            MultipartField(name: "mode", data: Data(request.mode.rawValue.utf8)),
            MultipartField(name: "source", data: Data("home".utf8))
        ])

        let response = try await apiClient.send(
            FlowTypeAPIRequest(
                path: "transcribe",
                method: "POST",
                headers: await authorizationHeader(),
                body: multipart.body,
                contentType: multipart.contentType
            )
        )
        guard (200..<300).contains(response.statusCode) else {
            throw response.remoteError
        }

        return try decoder.decode(TranscriptionResultDTO.self, from: response.data).transcriptionResult
    }

    private func authorizationHeader() async -> [String: String] {
        guard let token = await authTokenProvider() else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }
}

struct RemotePolishService: PolishServicing {
    private let apiClient: FlowTypeAPIClientProtocol
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let authTokenProvider: @Sendable () async -> String?

    init(
        apiClient: FlowTypeAPIClientProtocol,
        authTokenProvider: @escaping @Sendable () async -> String? = { nil }
    ) {
        self.apiClient = apiClient
        self.authTokenProvider = authTokenProvider
    }

    func polish(_ request: PolishRequest) async throws -> PolishResult {
        let payload = try encoder.encode(PolishRequestDTO(request: request))
        let response = try await apiClient.send(
            FlowTypeAPIRequest(
                path: "polish",
                method: "POST",
                headers: await authorizationHeader(),
                body: payload
            )
        )
        guard (200..<300).contains(response.statusCode) else {
            throw response.remoteError
        }

        return try decoder.decode(PolishResultDTO.self, from: response.data).polishResult
    }

    private func authorizationHeader() async -> [String: String] {
        guard let token = await authTokenProvider() else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }
}

struct RemoteTransformService: TransformServicing {
    private let apiClient: FlowTypeAPIClientProtocol
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let authTokenProvider: @Sendable () async -> String?

    init(
        apiClient: FlowTypeAPIClientProtocol,
        authTokenProvider: @escaping @Sendable () async -> String? = { nil }
    ) {
        self.apiClient = apiClient
        self.authTokenProvider = authTokenProvider
    }

    func transform(_ request: TransformRequest) async throws -> TransformResult {
        let payload = try encoder.encode(TransformRequestDTO(request: request))
        let response = try await apiClient.send(
            FlowTypeAPIRequest(
                path: "transform",
                method: "POST",
                headers: await authorizationHeader(),
                body: payload
            )
        )
        guard (200..<300).contains(response.statusCode) else {
            throw response.remoteError
        }

        return try decoder.decode(TransformResultDTO.self, from: response.data).transformResult
    }

    private func authorizationHeader() async -> [String: String] {
        guard let token = await authTokenProvider() else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }
}

struct RemoteUsageService: UsageServicing {
    private let apiClient: FlowTypeAPIClientProtocol
    private let decoder = JSONDecoder()
    private let authTokenProvider: @Sendable () async -> String?

    init(
        apiClient: FlowTypeAPIClientProtocol,
        authTokenProvider: @escaping @Sendable () async -> String? = { nil }
    ) {
        self.apiClient = apiClient
        self.authTokenProvider = authTokenProvider
    }

    func fetchUsage(for session: AuthSession) async throws -> UsageSnapshot {
        _ = session
        let response = try await apiClient.send(
            FlowTypeAPIRequest(
                path: "usage",
                method: "GET",
                headers: await authorizationHeader()
            )
        )
        guard (200..<300).contains(response.statusCode) else {
            throw response.remoteError
        }

        return try decoder.decode(UsageSnapshotDTO.self, from: response.data).usageSnapshot
    }

    func recordDictation(for session: AuthSession) async throws -> UsageSnapshot {
        try await fetchUsage(for: session)
    }

    private func authorizationHeader() async -> [String: String] {
        guard let token = await authTokenProvider() else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }
}

struct RemoteHistoryService: HistoryServicing {
    func fetchHistory(for session: AuthSession) async throws -> [HistoryItem] {
        _ = session
        return []
    }

    func save(_ item: HistoryItem, for session: AuthSession) async throws {
        _ = item
        _ = session
    }
}

private struct TranscriptionResultDTO: Codable, Sendable {
    let transcript: String
    let durationSeconds: TimeInterval

    var transcriptionResult: TranscriptionResult {
        TranscriptionResult(transcript: transcript, durationSeconds: durationSeconds)
    }

    enum CodingKeys: String, CodingKey {
        case transcript
        case durationSeconds = "durationSeconds"
    }
}

private struct PolishRequestDTO: Codable, Sendable {
    let transcript: String
    let mode: FlowMode
    let source: String

    init(request: PolishRequest) {
        self.transcript = request.transcript
        self.mode = request.mode
        self.source = "home"
    }
}

private struct PolishResultDTO: Codable, Sendable {
    let output: String

    var polishResult: PolishResult {
        PolishResult(text: output)
    }
}

private struct TransformRequestDTO: Codable, Sendable {
    let action: String
    let input: String
    let mode: FlowMode

    init(request: TransformRequest) {
        self.action = request.intent.backendValue
        self.input = request.text
        self.mode = request.mode
    }
}

private struct TransformResultDTO: Codable, Sendable {
    let output: String

    var transformResult: TransformResult {
        TransformResult(text: output)
    }
}

private struct UsageSnapshotDTO: Codable, Sendable {
    let dictationsLimit: Int?
    let dictationsUsed: Int
    let weekStart: String

    var usageSnapshot: UsageSnapshot {
        UsageSnapshot(
            weeklyDictationLimit: dictationsLimit ?? .max,
            usedDictations: dictationsUsed,
            resetsAt: Self.weekStartFormatter.date(from: weekStart) ?? .now
        )
    }

    private static let weekStartFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private extension FlowTypeAPIResponse {
    var remoteError: RemoteFlowTypeServiceError {
        let rawMessage = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let message: String
        if let rawMessage, !rawMessage.isEmpty {
            message = rawMessage
        } else {
            message = "No response body returned."
        }

        return .requestFailed(statusCode: statusCode, message: message)
    }
}

private extension TransformIntent {
    var backendValue: String {
        switch self {
        case .shorter:
            return "shorter"
        case .professional:
            return "professional"
        case .friendly:
            return "friendly"
        case .bulletList:
            return "bullet_list"
        }
    }
}

private struct MultipartField {
    let name: String
    var fileName: String?
    var contentType: String?
    let data: Data
}

private struct MultipartFormData {
    let boundary = "Boundary-\(UUID().uuidString)"
    let body: Data

    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    init(fields: [MultipartField]) {
        var data = Data()

        for field in fields {
            data.append(Data("--\(boundary)\r\n".utf8))

            var disposition = "Content-Disposition: form-data; name=\"\(field.name)\""
            if let fileName = field.fileName {
                disposition += "; filename=\"\(fileName)\""
            }
            data.append(Data("\(disposition)\r\n".utf8))

            if let contentType = field.contentType {
                data.append(Data("Content-Type: \(contentType)\r\n".utf8))
            }

            data.append(Data("\r\n".utf8))
            data.append(field.data)
            data.append(Data("\r\n".utf8))
        }

        data.append(Data("--\(boundary)--\r\n".utf8))
        self.body = data
    }
}
