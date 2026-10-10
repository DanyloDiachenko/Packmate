import Foundation
import SwiftUI
import Combine

struct SignUpRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
}

struct UpdateProfileRequest: Codable {
    let firstName: String
    let lastName: String
}

struct SignInRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let token: String?
    let userId: String?
    let email: String?
}

struct UserProfileResponse: Codable {
    let userId: String
    let firstName: String?
    let lastName: String?
    let email: String?
    let createdAt: String?
}

struct ConfirmEmailRequest: Codable {
    let email: String
    let code: String
}

struct VerifyLoginRequest: Codable {
    let email: String
    let code: String
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let email: String
    let code: String
    let newPassword: String
}

struct ResendCodeRequest: Codable {
    let email: String
    let purpose: String
}

struct SignUpSuccessResponse: Codable {
    let message: String?
    let email: String?
}

struct BackendErrorResponse: Codable {
    let message: String?
}

struct ProblemDetailsResponse: Codable {
    let title: String?
    let detail: String?
    let errors: [String: [String]]?
}

struct LoginTwoFactorResponse: Decodable {
    let requiresTwoFactor: Bool?
    let email: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case requiresTwoFactor, email, message
        case requiresTwoFactorPascal = "RequiresTwoFactor"
        case emailPascal = "Email"
        case messagePascal = "Message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.requiresTwoFactor = (try? container.decodeIfPresent(Bool.self, forKey: .requiresTwoFactor))
            ?? (try? container.decodeIfPresent(Bool.self, forKey: .requiresTwoFactorPascal))
        self.email = (try? container.decodeIfPresent(String.self, forKey: .email))
            ?? (try? container.decodeIfPresent(String.self, forKey: .emailPascal))
        self.message = (try? container.decodeIfPresent(String.self, forKey: .message))
            ?? (try? container.decodeIfPresent(String.self, forKey: .messagePascal))
    }
}

enum SignInResult {
    case requiresTwoFactor(email: String, message: String)
    case emailNotConfirmed(email: String, message: String)
    case authenticated(token: String)
}

struct UserProfile: Codable, Equatable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String

    var fullName: String {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedFirst.isEmpty && !trimmedLast.isEmpty {
            return "\(trimmedFirst) \(trimmedLast)"
        } else if !trimmedFirst.isEmpty {
            return trimmedFirst
        } else if !trimmedLast.isEmpty {
            return trimmedLast
        }
        return email.components(separatedBy: "@").first ?? "Traveler"
    }

    var initial: String {
        if let first = firstName.first {
            return String(first).uppercased()
        }
        if let emailFirst = email.first {
            return String(emailFirst).uppercased()
        }
        return "U"
    }
}

@MainActor
final class AuthService: AuthServiceProtocol, AccessTokenProvider, ObservableObject {
    static let shared = AuthService()

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
        UserDefaults.standard.string(forKey: "readyroam_auth_token") ?? UserDefaults.standard.string(forKey: "packmate_auth_token")
    }

    private let tokenKey = "readyroam_auth_token"
    private let userKey = "readyroam_cached_user"
    private let networkClient: NetworkClientProtocol
    private let config: AppConfig

    init(
        config: AppConfig = .shared,
        networkClient: NetworkClientProtocol? = nil
    ) {
        self.config = config
        self.baseURL = config.baseURL
        let client = networkClient ?? URLSessionNetworkClient(tokenProvider: nil, config: config)
        self.networkClient = client

        let savedToken = UserDefaults.standard.string(forKey: tokenKey) ?? UserDefaults.standard.string(forKey: "packmate_auth_token")
        if let savedToken = savedToken, !savedToken.isEmpty {
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
                let error = parseError(from: data, statusCode: 400)
                if error.localizedDescription.contains("not confirmed") || error.localizedDescription.contains("verification code") {
                    return .emailNotConfirmed(email: email, message: error.localizedDescription)
                }
                throw error
            } else {
                throw parseError(from: data, statusCode: response.statusCode)
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
        UserDefaults.standard.removeObject(forKey: tokenKey)
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
        UserDefaults.standard.set(token, forKey: tokenKey)
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }

    private func parseError(from data: Data, statusCode: Int) -> APIError {
        if let errorResponse = try? JSONDecoder().decode(BackendErrorResponse.self, from: data),
           let msg = errorResponse.message, !msg.isEmpty {
            return APIError.httpError(statusCode: statusCode, message: msg)
        }

        if let problem = try? JSONDecoder().decode(ProblemDetailsResponse.self, from: data) {
            if let errors = problem.errors, let firstList = errors.values.first, let firstMsg = firstList.first {
                return APIError.httpError(statusCode: statusCode, message: firstMsg)
            }
            if let detail = problem.detail, !detail.isEmpty {
                return APIError.httpError(statusCode: statusCode, message: detail)
            }
            if let title = problem.title, !title.isEmpty {
                return APIError.httpError(statusCode: statusCode, message: title)
            }
        }

        if let rawText = String(data: data, encoding: .utf8), !rawText.isEmpty {
            return APIError.httpError(statusCode: statusCode, message: rawText)
        }

        let fallbackMsg: String
        switch statusCode {
        case 400: fallbackMsg = "Invalid request details."
        case 401: fallbackMsg = "Invalid email or password."
        case 409: fallbackMsg = "An account with this email already exists."
        case 500...599: fallbackMsg = "Server error. Please try again later."
        default: fallbackMsg = "Request failed (status code: \(statusCode))."
        }
        return APIError.httpError(statusCode: statusCode, message: fallbackMsg)
    }
}
