import Foundation

public struct ServerErrorParser {
    public static func parse(from data: Data, statusCode: Int) -> APIError {
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
        
        if let rawText = String(data: data, encoding: .utf8), !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
    
    public static func parseErrorMessage(from data: Data) -> String? {
        if let errorObj = try? JSONDecoder().decode(BackendErrorResponse.self, from: data),
           let msg = errorObj.message, !msg.isEmpty {
            return msg
        }
        if let problemObj = try? JSONDecoder().decode(ProblemDetailsResponse.self, from: data) {
            if let errors = problemObj.errors, let first = errors.values.first, let msg = first.first {
                return msg
            }
            if let detail = problemObj.detail, !detail.isEmpty {
                return detail
            }
            if let title = problemObj.title, !title.isEmpty {
                return title
            }
        }
        if let raw = String(data: data, encoding: .utf8), !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return raw
        }
        return nil
    }
}
