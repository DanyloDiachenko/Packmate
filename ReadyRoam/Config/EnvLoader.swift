import Foundation

public enum Env {
    private static let envDictionary: [String: String] = {
        var dict: [String: String] = [:]

        let possiblePaths: [String] = [
            Bundle.main.path(forResource: ".env", ofType: nil) ?? "",
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent(".env").path,
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent(".env").path
        ]

        for path in possiblePaths where !path.isEmpty {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                parse(content, into: &dict)
                break
            }
        }

        return dict
    }()

    private static func parse(_ content: String, into dict: inout [String: String]) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            guard let separatorIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[..<separatorIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            var value = String(trimmed[trimmed.index(after: separatorIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            if !key.isEmpty {
                dict[key] = value
            }
        }
    }

    public static func get(_ key: String) -> String? {
        if let processVal = ProcessInfo.processInfo.environment[key], !processVal.isEmpty {
            return processVal
        }
        if let bundleVal = Bundle.main.object(forInfoDictionaryKey: key) as? String, !bundleVal.isEmpty {
            return bundleVal
        }
        return envDictionary[key]
    }
}
