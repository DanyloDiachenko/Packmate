import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct Endpoint {
    public let path: String
    public let method: HTTPMethod
    public let headers: [String: String]?
    public let queryItems: [URLQueryItem]?
    public let body: Data?
    public let requiresAuth: Bool

    public init(
        path: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil,
        requiresAuth: Bool = true
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.requiresAuth = requiresAuth
    }
}

public protocol AccessTokenProvider: Sendable {
    var currentToken: String? { get }
}

public protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func requestVoid(_ endpoint: Endpoint) async throws
    func request<T: Decodable>(_ request: URLRequest) async throws -> T
    func requestVoid(_ request: URLRequest) async throws
}

@MainActor
public final class URLSessionNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    public static let shared = URLSessionNetworkClient()

    private let session: URLSession
    private let tokenProvider: AccessTokenProvider?
    private let config: AppConfig

    public init(
        session: URLSession = .shared,
        tokenProvider: AccessTokenProvider? = nil,
        config: AppConfig = .shared
    ) {
        self.session = session
        self.tokenProvider = tokenProvider
        self.config = config
    }

    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try buildURLRequest(from: endpoint)
        return try await request(urlRequest)
    }

    public func requestVoid(_ endpoint: Endpoint) async throws {
        let urlRequest = try buildURLRequest(from: endpoint)
        try await requestVoid(urlRequest)
    }

    public func request<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, _) = try await perform(request)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    public func requestVoid(_ request: URLRequest) async throws {
        _ = try await perform(request)
    }

    private func buildURLRequest(from endpoint: Endpoint) throws -> URLRequest {
        let baseURL = config.baseURL
        let cleanPath = endpoint.path.hasPrefix("/") ? String(endpoint.path.dropFirst()) : endpoint.path
        let urlWithPath = baseURL.appendingPathComponent(cleanPath)

        guard var components = URLComponents(url: urlWithPath, resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }

        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let headers = endpoint.headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        if endpoint.requiresAuth {
            if let token = tokenProvider?.currentToken, !token.isEmpty {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        if let body = endpoint.body {
            urlRequest.httpBody = body
        }

        return urlRequest
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        if Task.isCancelled {
            throw APIError.cancelled
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlErr as URLError where urlErr.code == .cancelled {
            throw APIError.cancelled
        } catch {
            if Task.isCancelled {
                throw APIError.cancelled
            }
            throw APIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid server response.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            let serverMessage = parseServerErrorMessage(from: data)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: serverMessage)
        }

        return (data, httpResponse)
    }

    private func parseServerErrorMessage(from data: Data) -> String? {
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
        if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
            return raw
        }
        return nil
    }
}
