import Foundation

public struct VMDefinition: Codable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var cpuCount: Int
    public var memoryBytes: UInt64
    public var diskBytes: UInt64
    public var createdAt: Date
    public var installed: Bool
    public var isoPath: String?

    public init(
        id: UUID = UUID(),
        name: String,
        cpuCount: Int = 4,
        memoryGB: Int = 8,
        diskGB: Int = 32,
        createdAt: Date = Date(),
        installed: Bool = false,
        isoPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.cpuCount = max(1, cpuCount)
        self.memoryBytes = UInt64(memoryGB) * 1024 * 1024 * 1024
        self.diskBytes = UInt64(diskGB) * 1024 * 1024 * 1024
        self.createdAt = createdAt
        self.installed = installed
        self.isoPath = isoPath
    }

    public var memoryGB: Int {
        Int(memoryBytes / (1024 * 1024 * 1024))
    }

    public var diskGB: Int {
        Int(diskBytes / (1024 * 1024 * 1024))
    }
}

public enum VMRunMode: Sendable {
    case install(isoURL: URL)
    case run
}

public enum EaseMirrorError: LocalizedError, Sendable {
    case unsupportedPlatform
    case vmNotFound(UUID)
    case configurationInvalid(String)
    case diskCreationFailed(String)
    case isoMissing
    case engineBusy
    case bootTimeout
    case processFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedPlatform:
            return "Ghost Mirror requires Apple Silicon and macOS 13 or later."
        case let .vmNotFound(id):
            return "Mirror not found: \(id.uuidString)"
        case let .configurationInvalid(msg):
            return "Invalid VM configuration: \(msg)"
        case let .diskCreationFailed(msg):
            return "Could not create disk: \(msg)"
        case .isoMissing:
            return "Ubuntu ISO not found. Download one from the setup wizard."
        case .engineBusy:
            return "A mirror is already running."
        case .bootTimeout:
            return "Ubuntu boot is taking too long. Use Ghost Mirror → Reset & Install Ubuntu, or run: ease-mirror-cli reset-install <uuid>"
        case let .processFailed(msg):
            return msg
        }
    }
}
