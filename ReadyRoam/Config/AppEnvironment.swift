import Foundation

public enum AppEnvironment: String, CaseIterable, Identifiable, Codable {
    case development
    case production

    public var id: String { rawValue }

    public var defaultBaseURL: URL {
        switch self {
        case .development:
            if let customDev = Env.get("BACKEND_DEV_URL") ?? Env.get("API_BASE_URL"), let url = URL(string: customDev) {
                return url
            }
            return URL(string: "http://192.168.0.102:5050")!
        case .production:
            if let customProd = Env.get("BACKEND_PROD_URL"), let url = URL(string: customProd) {
                return url
            }
            return URL(string: "https://api.readyroam.app")!
        }
    }

    public var displayName: String {
        switch self {
        case .development: return "Development (Local)"
        case .production: return "Production (HTTPS)"
        }
    }
}

@MainActor
public final class AppConfig: ObservableObject {
    public static let shared = AppConfig()

    private let userDefaultsKey = "readyroam_backend_base_url"
    private let environmentKey = "readyroam_active_environment"

    @Published public var activeEnvironment: AppEnvironment {
        didSet {
            UserDefaults.standard.set(activeEnvironment.rawValue, forKey: environmentKey)
        }
    }

    @Published public var customBaseURLString: String {
        didSet {
            if customBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            } else {
                UserDefaults.standard.set(customBaseURLString, forKey: userDefaultsKey)
            }
        }
    }

    public init() {
        let savedEnvRaw = UserDefaults.standard.string(forKey: "readyroam_active_environment") ?? ""
        let env = AppEnvironment(rawValue: savedEnvRaw) ?? .development
        self.activeEnvironment = env

        let savedCustomURL = UserDefaults.standard.string(forKey: "readyroam_backend_base_url") ?? UserDefaults.standard.string(forKey: "packmate_backend_base_url") ?? ""
        if savedCustomURL.isEmpty, let envBase = Env.get("API_BASE_URL") ?? Env.get("BACKEND_BASE_URL"), !envBase.isEmpty {
            self.customBaseURLString = envBase
        } else {
            self.customBaseURLString = savedCustomURL
        }
    }

    public var baseURL: URL {
        let trimmed = customBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let url = URL(string: trimmed) {
            return url
        }
        if let envBase = Env.get("API_BASE_URL") ?? Env.get("BACKEND_BASE_URL"), let url = URL(string: envBase) {
            return url
        }
        return activeEnvironment.defaultBaseURL
    }

    public func setCustomBaseURL(_ url: URL) {
        self.customBaseURLString = url.absoluteString
    }

    public func resetToDefault() {
        self.customBaseURLString = ""
    }
}
