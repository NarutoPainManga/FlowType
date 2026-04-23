import Foundation

#if canImport(Supabase)
import Supabase

func makeSupabaseClient(configuration: FlowTypeConfiguration) -> SupabaseClient {
    SupabaseClient(
        supabaseURL: configuration.supabaseURL,
        supabaseKey: configuration.supabasePublishableKey
    )
}

struct SupabaseAuthService: AuthServicing {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func currentSession() async throws -> AuthSession? {
        if let currentSession = client.auth.currentSession {
            return AuthSession(session: currentSession)
        }

        do {
            let refreshedSession = try await client.auth.session
            return AuthSession(session: refreshedSession)
        } catch {
            return nil
        }
    }

    func signInAnonymously() async throws -> AuthSession {
        let session = try await client.auth.signInAnonymously()
        return AuthSession(session: session)
    }

    func currentAccessToken() async throws -> String? {
        if let currentSession = client.auth.currentSession {
            return currentSession.accessToken
        }

        do {
            return try await client.auth.session.accessToken
        } catch {
            return nil
        }
    }
}

private extension AuthSession {
    init(session: Session) {
        self.init(
            userID: session.user.id,
            isAnonymous: session.user.isAnonymous,
            createdAt: session.user.createdAt,
            accessToken: session.accessToken
        )
    }
}
#else
struct SupabaseAuthService: AuthServicing {
    func currentSession() async throws -> AuthSession? { nil }
    func signInAnonymously() async throws -> AuthSession {
        throw FlowTypeConfigurationError.supabaseSDKUnavailable
    }

    func currentAccessToken() async throws -> String? { nil }
}

enum FlowTypeConfigurationError: Error {
    case supabaseSDKUnavailable
}
#endif
