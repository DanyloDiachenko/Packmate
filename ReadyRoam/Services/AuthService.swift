import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthService: AuthServiceProtocol, AccessTokenProvider, ObservableObject {
    @Published public var baseURL: URL {
        didSet {
            config.setCustomBaseURL(baseURL)
        }
    }
    @Published private(set) var token: String?
    @Published private(set) var currentUser: UserProfile?
    @Published private(set) var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false

    public nonisolated var currentToken: String? {
        tokenStorage.getToken()
    }

    private let userKey = "readyroam_cached_user"
    private let tokenStorage: TokenStorageProtocol
    private let networkClient: NetworkClientProtocol
    private let config: AppConfig

    init(
        config: AppConfig = .shared,
        networkClient: NetworkClientProtocol? = nil,
        tokenStorage: TokenStorageProtocol = KeychainStorage.shared
    ) {
        self.config = config
        self.baseURL = config.baseURL
        self.tokenStorage = tokenStorage
        let client = networkClient ?? URLSessionNetworkClient(tokenProvider: nil, config: config)
        self.networkClient = client

        if let savedToken = tokenStorage.getToken(), !savedToken.isEmpty {
            self.token = savedToken
            self.isAuthenticated = true

            if let savedUserData = UserDefaults.standard.data(forKey: userKey),
               let cached = try? JSONDecoder().decode(UserProfile.self, from: savedUserData) {
                self.currentUser = cached
            }

            Task {
                _ = try? await self.fetchUserProfile()
            }
        }
    }

    func setCustomBaseURL(_ url: URL) {
        self.baseURL = url
        config.setCustomBaseURL(url)
    }

    func signIn(email: String, password: String) async throws -> SignInResult {
        isLoading = true
        defer { isLoading = false }

        let reqBody = SignInRequest(email: email, password: password)
        let bodyData = try JSONEncoder().encode(reqBody)
        let endpoint = Endpoint(path: "auth/sign-in", method: .post, body: bodyData, requiresAuth: false)

        do {
            let (data, response) = try await performRaw(endpoint)
            if (200...299).contains(response.statusCode) {
                if let twoFactor = try? JSONDecoder().decode(LoginTwoFactorResponse.self, from: data),
                   twoFactor.requiresTwoFactor == true {
                    return .requiresTwoFactor(email: twoFactor.email ?? email, message: twoFactor.message ?? "A login verification code was sent to your email.")
                }

                if let authResponse = try? JSONDecoder().decode(AuthResponse.self, from: data),
                   let token = authResponse.token, !token.isEmpty {
                    saveSession(token: token, userId: authResponse.userId ?? UUID().uuidString, email: authResponse.email ?? email)
                    _ = try? await fetchUserProfile()
                    return .authenticated(token: token)
                }

                return .requiresTwoFactor(email: email, message: "A login verification code was sent to your email.")
            } else if response.statusCode == 400 {
                let error = ServerErrorParser.parse(from: data, statusCode: 400)
                if error.localizedDescription.contains("not confirmed") || error.localizedDescription.contains("verification code") {
                    return .emailNotConfirmed(email: email, message: error.localizedDescription)
                }
                throw error
            } else {
                throw ServerErrorParser.parse(from: data, statusCode: response.statusCode)
            }
        } catch let err as APIError {
            throw err
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }

    func confirmEmail(email: String, code: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let reqBody = ConfirmEmailRequest(email: email, code: code)
        let bodyData = try JSONEncoder().encode(reqBody)
        let endpoint = Endpoint(path: "auth/confirm-email", method: .post, body: bodyData, requiresAuth: false)

        let authResponse: AuthResponse = try await networkClient.request(endpoint)
        guard let token = authResponse.token, !token.isEmpty else {
            throw APIError.httpError(statusCode: 400, message: "No token returned by server.")
        }
        saveSession(token: token, userId: authResponse.userId ?? UUID().uuidString, email: authResponse.email ?? email)
        _ = try? await fetchUserProfile()
    }

    func verifyLogin2FA(email: String, code: String) async throws -> String {
        return try await verifyLogin(email: email, code: code)
    }

    func verifyLogin(email: String, code: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        let reqBody = VerifyLoginRequest(email: email, code: code)
        let bodyData = try JSONEncoder().encode(reqBody)
        let endpoint = Endpoint(path: "auth/verify-login", method: .post, body: bodyData, requiresAuth: false)

        let authResponse: AuthResponse = try await networkClient.request(endpoint)
        guard let token = authResponse.token, !token.isEmpty else {
            throw APIError.httpError(statusCode: 400, message: "No token returned by server.")
        }
        saveSession(token: token, userId: authResponse.userId ?? UUID().uuidString, email: authResponse.email ?? email)
        _ = try? await fetchUserProfile()
        return token
    }

    func signUp(firstName: String, lastName: String, email: String, password: String) async throws -> SignUpSuccessResponse {
        isLoading = true
        defer { isLoading = false }

        let reqBody = SignUpRequest(firstName: firstName, lastName: lastName, email: email, password: password)
        let bodyData = try JSONEncoder().encode(reqBody)
        let endpoint = Endpoint(path: "auth/sign-up", method: .post, body: bodyData, requiresAuth: false)

        return try await networkClient.request(endpoint)
    }

    func forgotPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let reqBody = ForgotPasswordRequest(email: email)
        let bodyData = try JSONEncoder().encode(reqBody)
        let endpoint = Endpoint(path: "auth/forgot-password", method: .post, body: bodyData, requiresAuth: false)

        try await networkClient.requestVoid(endpoint)
    }

    @discardableResult
    func resetPassword(email: String, code: String, newPassword: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        let reqBody = ResetPasswordRequest(email: email, code: code, newPassword: newPassword)
        let bodyData = try JSONEncoder().encode(reqBody)
        let endpoint = Endpoint(path: "auth/reset-password", method: .post, body: bodyData, requiresAuth: false)

        try await networkClient.requestVoid(endpoint)
        return "Password successfully reset."
    }

    @discardableResult
    func resendCode(email: String, purpose: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        let reqBody = ResendCodeRequest(email: email, purpose: purpose)
        let bodyData = try JSONEncoder().encode(reqBody)
        let endpoint = Endpoint(path: "auth/resend-code", method: .post, body: bodyData, requiresAuth: false)

        try await networkClient.requestVoid(endpoint)
        return "A new verification code has been sent."
    }

    @discardableResult
    func fetchUserProfile() async throws -> UserProfile {
        guard let currentToken = token ?? currentToken, !currentToken.isEmpty else {
            throw APIError.unauthorized
        }

        let endpoint = Endpoint(path: "auth/profile", method: .post, requiresAuth: true)
        let profileResponse: UserProfileResponse = try await networkClient.request(endpoint)
        let user = UserProfile(
            id: profileResponse.userId,
            firstName: profileResponse.firstName ?? currentUser?.firstName ?? "",
            lastName: profileResponse.lastName ?? currentUser?.lastName ?? "",
            email: profileResponse.email ?? currentUser?.email ?? ""
        )
        self.currentUser = user
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
        return user
    }

    func updateProfile(firstName: String, lastName: String) async throws -> UserProfile {
        guard let currentToken = token ?? currentToken, !currentToken.isEmpty else {
            throw APIError.unauthorized
        }

        let reqBody = UpdateProfileRequest(firstName: firstName, lastName: lastName)
        let bodyData = try JSONEncoder().encode(reqBody)
        let endpoint = Endpoint(path: "auth/profile", method: .put, body: bodyData, requiresAuth: true)

        let profileResponse: UserProfileResponse = try await networkClient.request(endpoint)
        let updatedUser = UserProfile(
            id: currentUser?.id ?? profileResponse.userId,
            firstName: profileResponse.firstName ?? firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: profileResponse.lastName ?? lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: currentUser?.email ?? profileResponse.email ?? ""
        )
        self.currentUser = updatedUser
        if let encoded = try? JSONEncoder().encode(updatedUser) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
        return updatedUser
    }

    func logout() {
        self.token = nil
        self.currentUser = nil
        self.isAuthenticated = false
        tokenStorage.deleteToken()
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    private func performRaw(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        let cleanPath = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        let url = config.baseURL.appendingPathComponent(cleanPath)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = endpoint.body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid server response.")
        }
        return (data, httpResponse)
    }

    private func saveSession(token: String, userId: String, email: String) {
        let user = UserProfile(id: userId, firstName: currentUser?.firstName ?? "", lastName: currentUser?.lastName ?? "", email: email)
        saveSession(token: token, user: user)
    }

    private func saveSession(token: String, user: UserProfile) {
        self.token = token
        self.currentUser = user
        self.isAuthenticated = true
        tokenStorage.saveToken(token)
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }
}
