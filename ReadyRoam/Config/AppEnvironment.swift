import Foundation

public enum AppEnvironment: String, CaseIterable, Identifiable, Codable {
    case development
    case production

    public var id: String { rawValue }

    public var defaultBaseURL: URL {
        switch self {
        case .development:
            return URL(string: "http://192.168.0.102:5050")!
        case .production:
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
        self.customBaseURLString = savedCustomURL
    }

    public var baseURL: URL {
        let trimmed = customBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let url = URL(string: trimmed) {
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
