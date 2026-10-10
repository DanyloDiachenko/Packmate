import Foundation

public enum APIError: Error, LocalizedError, Equatable {
    case invalidURL
    case httpError(statusCode: Int, message: String?)
    case decodingError(String)
    case networkError(String)
    case unauthorized
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid endpoint URL."
        case .httpError(let statusCode, let message):
            if let msg = message, !msg.isEmpty {
                return msg
            }
            return "Request failed with status code \(statusCode)."
        case .decodingError(let details):
            return details.isEmpty ? "Failed to parse server response." : "Failed to parse server response: \(details)"
        case .networkError(let message):
            return message
        case .unauthorized:
            return "Session expired. Please log in again."
        case .cancelled:
            return "Request was cancelled."
        }
    }

    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.unauthorized, .unauthorized):
            return true
        case (.cancelled, .cancelled):
            return true
        case let (.decodingError(d1), .decodingError(d2)):
            return d1 == d2
        case let (.httpError(code1, msg1), .httpError(code2, msg2)):
            return code1 == code2 && msg1 == msg2
        case let (.networkError(msg1), .networkError(msg2)):
            return msg1 == msg2
        default:
            return false
        }
    }
}
