import Foundation

public struct VPSSettings: Sendable, Equatable {
    public var ip: String
    public var ghostURL: String
    public var sshUser: String
    public var sshKeyPath: String
    public var vncPassword: String

    public init(ip: String, ghostURL: String, sshUser: String, sshKeyPath: String, vncPassword: String) {
        self.ip = ip
        self.ghostURL = ghostURL
        self.sshUser = sshUser
        self.sshKeyPath = sshKeyPath
        self.vncPassword = vncPassword
    }

    public static let defaultSSHKey = "\(NSHomeDirectory())/.ssh/id_ed25519"

    public static var current: VPSSettings {
        CloudMirrorConfig.settings
    }
}

public enum CloudMirrorConfig: Sendable {
    private static let envFileName = "ghost_mirror_cloud.env"
    private static let legacyEnvFileName = "ease_mirror_cloud.env"

    public static func envPath() -> URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ben_studio", isDirectory: true)
        let primary = dir.appendingPathComponent(envFileName)
        let legacy = dir.appendingPathComponent(legacyEnvFileName)
        if FileManager.default.fileExists(atPath: primary.path) { return primary }
        if FileManager.default.fileExists(atPath: legacy.path) { return legacy }
        return primary
    }

    public static func load() -> [String: String] {
        guard let text = try? String(contentsOf: envPath(), encoding: .utf8) else { return [:] }
        var map: [String: String] = [:]
        for line in text.split(separator: "\n") {
            let s = line.trimmingCharacters(in: .whitespaces)
            if s.isEmpty || s.hasPrefix("#") { continue }
            let parts = s.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                map[String(parts[0])] = String(parts[1])
            }
        }
        return map
    }

    private static func value(_ map: [String: String], _ key: String, legacy: String? = nil) -> String? {
        if let v = map[key], !v.isEmpty { return v }
        if let legacy, let v = map[legacy], !v.isEmpty { return v }
        return nil
    }

    public static var settings: VPSSettings {
        let map = load()
        return VPSSettings(
            ip: value(map, "GHOST_MIRROR_CLOUD_IP", legacy: "EASE_MIRROR_CLOUD_IP") ?? "",
            ghostURL: value(map, "GHOST_MIRROR_GHOST_URL", legacy: "EASE_MIRROR_GHOST_URL") ?? "",
            sshUser: value(map, "GHOST_MIRROR_CLOUD_USER", legacy: "EASE_MIRROR_CLOUD_USER") ?? "root",
            sshKeyPath: value(map, "GHOST_MIRROR_SSH_KEY", legacy: "EASE_MIRROR_SSH_KEY") ?? VPSSettings.defaultSSHKey,
            vncPassword: value(map, "GHOST_MIRROR_VNC_PASSWORD", legacy: "EASE_MIRROR_VNC_PASSWORD") ?? ""
        )
    }

    public static func save(_ settings: VPSSettings) throws {
        var map = load()
        map["GHOST_MIRROR_CLOUD_IP"] = settings.ip.trimmingCharacters(in: .whitespacesAndNewlines)
        map["GHOST_MIRROR_GHOST_URL"] = settings.ghostURL.trimmingCharacters(in: .whitespacesAndNewlines)
        map["GHOST_MIRROR_CLOUD_USER"] = settings.sshUser.trimmingCharacters(in: .whitespacesAndNewlines)
        map["GHOST_MIRROR_SSH_KEY"] = settings.sshKeyPath.trimmingCharacters(in: .whitespacesAndNewlines)
        map["GHOST_MIRROR_VNC_PASSWORD"] = settings.vncPassword
        map["GHOST_MIRROR_SAVED_AT"] = ISO8601DateFormatter().string(from: Date())

        let dir = envPath().deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let preferredOrder = [
            "GHOST_MIRROR_CLOUD_IP",
            "GHOST_MIRROR_GHOST_URL",
            "GHOST_MIRROR_CLOUD_USER",
            "GHOST_MIRROR_SSH_KEY",
            "GHOST_MIRROR_VNC_PASSWORD",
            "GHOST_MIRROR_NOVNC_LOCAL",
            "GHOST_MIRROR_HOST",
            "GHOST_MIRROR_DESKTOP",
            "GHOST_MIRROR_SAVED_AT",
            "GHOST_MIRROR_WIRED_AT",
            "GHOST_MIRROR_DESKTOP_READY",
        ]
        var lines = ["# Ghost Mirror VPS — saved from app"]
        var written = Set<String>()
        for key in preferredOrder {
            guard let value = map[key] else { continue }
            lines.append("\(key)=\(value)")
            written.insert(key)
        }
        for key in map.keys.sorted() where !written.contains(key) {
            lines.append("\(key)=\(map[key]!)")
        }

        let body = lines.joined(separator: "\n") + "\n"
        let target = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".ben_studio/\(envFileName)")
        try body.write(to: target, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: target.path)
    }

    public static var ip: String { settings.ip }

    public static var ghostURL: URL {
        let raw = settings.ghostURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, let url = URL(string: raw) else {
            return URL(string: "https://example.com")!
        }
        return url
    }

    public static var bridgeURL: URL {
        ghostURL.appendingPathComponent("bridge")
    }

    public static var vncPassword: String { settings.vncPassword }

    public static var novncURL: URL {
        let map = load()
        let base = value(map, "GHOST_MIRROR_NOVNC_LOCAL", legacy: "EASE_MIRROR_NOVNC_LOCAL")
            ?? "http://127.0.0.1:6080/vnc.html"
        let pass = vncPassword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vncPassword
        let query = "autoconnect=true&resize=scale&password=\(pass)"
        if base.contains("?") {
            return URL(string: "\(base)&\(query)") ?? URL(string: "http://127.0.0.1:6080/vnc.html")!
        }
        return URL(string: "\(base)?\(query)") ?? URL(string: "http://127.0.0.1:6080/vnc.html")!
    }

    public static var blackBookURL: URL {
        GhostCloudBridge.benStudioRoot
            .appendingPathComponent("EaseMirror/BLACKBOOK.md")
    }
}
