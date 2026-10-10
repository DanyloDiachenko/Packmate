import Foundation
import Security

public protocol TokenStorageProtocol: AccessTokenProvider, Sendable {
    func getToken() -> String?
    func saveToken(_ token: String)
    func deleteToken()
}

extension KeychainStorage {
    public var currentToken: String? {
        getToken()
    }
}

public final class KeychainStorage: TokenStorageProtocol, @unchecked Sendable {
    public static let shared = KeychainStorage()
    
    private let service: String = "com.readyroam.app.auth"
    private let tokenAccount: String = "authToken"
    private let legacyTokenKeys = ["readyroam_auth_token", "packmate_auth_token"]
    
    public init() {}
    
    public func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data, let token = String(data: data, encoding: .utf8), !token.isEmpty {
            return token
        }
        
        for key in legacyTokenKeys {
            if let legacyToken = UserDefaults.standard.string(forKey: key), !legacyToken.isEmpty {
                saveToken(legacyToken)
                UserDefaults.standard.removeObject(forKey: key)
                return legacyToken
            }
        }
        
        return nil
    }
    
    public func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount
        ]
        
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        if status == errSecItemNotFound {
            var newQuery = query
            newQuery[kSecValueData as String] = data
            SecItemAdd(newQuery as CFDictionary, nil)
        }
        
        for key in legacyTokenKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    public func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenAccount
        ]
        
        SecItemDelete(query as CFDictionary)
        
        for key in legacyTokenKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
