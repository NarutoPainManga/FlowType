import Foundation

struct FlowTypeAPIRequest: Sendable {
    let path: String
    let method: String
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?
    var contentType: String?
}

struct FlowTypeAPIResponse: Sendable {
    let statusCode: Int
    let data: Data
}

enum FlowTypeAPIClientError: Error {
    case invalidBaseURL
}

extension FlowTypeAPIClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "FlowType is missing a valid backend URL."
        }
    }
}

protocol FlowTypeAPIClientProtocol: Sendable {
    func send(_ request: FlowTypeAPIRequest) async throws -> FlowTypeAPIResponse
}

struct FlowTypeAPIClient: FlowTypeAPIClientProtocol {
    let baseURL: URL
    let session: URLSession
    let defaultHeaders: [String: String]

    init(baseURL: URL, session: URLSession = .shared, defaultHeaders: [String: String] = [:]) {
        self.baseURL = baseURL
        self.session = session
        self.defaultHeaders = defaultHeaders
    }

    func send(_ request: FlowTypeAPIRequest) async throws -> FlowTypeAPIResponse {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(request.path), resolvingAgainstBaseURL: false) else {
            throw FlowTypeAPIClientError.invalidBaseURL
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw FlowTypeAPIClientError.invalidBaseURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = 30
        for (header, value) in defaultHeaders.merging(request.headers, uniquingKeysWith: { _, new in new }) {
            urlRequest.setValue(value, forHTTPHeaderField: header)
        }
        if let contentType = request.contentType {
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        } else if request.body != nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: urlRequest)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
        return FlowTypeAPIResponse(statusCode: statusCode, data: data)
    }
}

struct MockFlowTypeAPIClient: FlowTypeAPIClientProtocol {
    var handler: @Sendable (FlowTypeAPIRequest) async throws -> FlowTypeAPIResponse

    init(handler: @escaping @Sendable (FlowTypeAPIRequest) async throws -> FlowTypeAPIResponse = { _ in
        FlowTypeAPIResponse(statusCode: 200, data: Data())
    }) {
        self.handler = handler
    }

    func send(_ request: FlowTypeAPIRequest) async throws -> FlowTypeAPIResponse {
        try await handler(request)
    }
}

struct UnavailableFlowTypeAPIClient: FlowTypeAPIClientProtocol {
    let reason: String

    func send(_ request: FlowTypeAPIRequest) async throws -> FlowTypeAPIResponse {
        _ = request
        throw ServiceUnavailableError(reason: reason)
    }
}
