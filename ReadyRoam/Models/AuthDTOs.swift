import Foundation

public struct SignUpRequest: Codable {
    public let firstName: String
    public let lastName: String
    public let email: String
    public let password: String

    public init(firstName: String, lastName: String, email: String, password: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
    }
}

public struct UpdateProfileRequest: Codable {
    public let firstName: String
    public let lastName: String

    public init(firstName: String, lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
}

public struct SignInRequest: Codable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct AuthResponse: Codable {
    public let token: String?
    public let userId: String?
    public let email: String?

    public init(token: String?, userId: String?, email: String?) {
        self.token = token
        self.userId = userId
        self.email = email
    }
}

public struct UserProfileResponse: Codable {
    public let userId: String
    public let firstName: String?
    public let lastName: String?
    public let email: String?
    public let createdAt: String?

    public init(userId: String, firstName: String?, lastName: String?, email: String?, createdAt: String?) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.createdAt = createdAt
    }
}

public struct ConfirmEmailRequest: Codable {
    public let email: String
    public let code: String

    public init(email: String, code: String) {
        self.email = email
        self.code = code
    }
}

public struct VerifyLoginRequest: Codable {
    public let email: String
    public let code: String

    public init(email: String, code: String) {
        self.email = email
        self.code = code
    }
}

public struct ForgotPasswordRequest: Codable {
    public let email: String

    public init(email: String) {
        self.email = email
    }
}

public struct ResetPasswordRequest: Codable {
    public let email: String
    public let code: String
    public let newPassword: String

    public init(email: String, code: String, newPassword: String) {
        self.email = email
        self.code = code
        self.newPassword = newPassword
    }
}

public struct ResendCodeRequest: Codable {
    public let email: String
    public let purpose: String

    public init(email: String, purpose: String) {
        self.email = email
        self.purpose = purpose
    }
}

public struct SignUpSuccessResponse: Codable {
    public let message: String?
    public let email: String?

    public init(message: String?, email: String?) {
        self.message = message
        self.email = email
    }
}

public struct BackendErrorResponse: Codable {
    public let message: String?

    public init(message: String?) {
        self.message = message
    }
}

public struct ProblemDetailsResponse: Codable {
    public let title: String?
    public let detail: String?
    public let errors: [String: [String]]?

    public init(title: String?, detail: String?, errors: [String: [String]]?) {
        self.title = title
        self.detail = detail
        self.errors = errors
    }
}

public struct LoginTwoFactorResponse: Decodable {
    public let requiresTwoFactor: Bool?
    public let email: String?
    public let message: String?

    enum CodingKeys: String, CodingKey {
        case requiresTwoFactor, email, message
        case requiresTwoFactorPascal = "RequiresTwoFactor"
        case emailPascal = "Email"
        case messagePascal = "Message"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.requiresTwoFactor = (try? container.decodeIfPresent(Bool.self, forKey: .requiresTwoFactor))
            ?? (try? container.decodeIfPresent(Bool.self, forKey: .requiresTwoFactorPascal))
        self.email = (try? container.decodeIfPresent(String.self, forKey: .email))
            ?? (try? container.decodeIfPresent(String.self, forKey: .emailPascal))
        self.message = (try? container.decodeIfPresent(String.self, forKey: .message))
            ?? (try? container.decodeIfPresent(String.self, forKey: .messagePascal))
    }
}

public enum SignInResult {
    case requiresTwoFactor(email: String, message: String)
    case emailNotConfirmed(email: String, message: String)
    case authenticated(token: String)
}

public struct UserProfile: Codable, Equatable {
    public let id: String
    public var firstName: String
    public var lastName: String
    public var email: String

    public init(id: String, firstName: String, lastName: String, email: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }

    public var fullName: String {
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

    public var initial: String {
        if let first = firstName.first {
            return String(first).uppercased()
        }
        if let emailFirst = email.first {
            return String(emailFirst).uppercased()
        }
        return "U"
    }
}
