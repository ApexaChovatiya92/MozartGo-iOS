import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {

    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false

    private let api: APIServiceProtocol
    private let keychain: KeychainService
    private let cacheService: CacheService

    // ✅ Dependency Injection
    init(
        api: APIServiceProtocol = MockAPIService(),
        keychain: KeychainService = .shared,
        cacheService: CacheService = .shared
    ) {
        self.api = api
        self.keychain = keychain
        self.cacheService = cacheService

        // Restore session
        if let token = keychain.getToken(), !token.isEmpty {
            isAuthenticated = true
            Task { await loadCurrentUser() }
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let response = try await api.signIn(email: email, password: password)

        guard let token = response.token else {
            throw APIError.unknown(response.error ?? "Sign in failed.")
        }

        keychain.saveToken(token)
        currentUser = response.user
        isAuthenticated = true
    }

    // MARK: - Sign Up

    func signUp(name: String, email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let response = try await api.signUp(name: name, email: email, password: password)

        guard let token = response.token else {
            throw APIError.unknown(response.error ?? "Sign up failed.")
        }

        keychain.saveToken(token)
        currentUser = response.user
        isAuthenticated = true
    }

    // MARK: - Sign Out

    func signOut() {
        keychain.deleteToken()
        currentUser = nil
        isAuthenticated = false

        // ✅ Clear all cached data
        cacheService.clearAll()
    }

    // MARK: - Load User

    func loadCurrentUser() async {
        do {
            currentUser = try await api.getCurrentUser()
        } catch {
            if case APIError.unauthorized = error {
                signOut()
            }
        }
    }
}
