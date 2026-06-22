import Foundation

public enum VMPaths {
    public static let appSupport: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("EaseMirror", isDirectory: true)
    }()

    public static let vmsRoot: URL = appSupport.appendingPathComponent("VMs", isDirectory: true)
    public static let isosRoot: URL = appSupport.appendingPathComponent("ISOs", isDirectory: true)
    public static let shareRoot: URL = appSupport.appendingPathComponent("Share", isDirectory: true)

    public static let defaultUbuntuISO: URL = isosRoot.appendingPathComponent("ubuntu-24.04.4-desktop-arm64.iso")

    public static let ubuntuISOURL = URL(string: "https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.4-desktop-arm64.iso")!

    public static func vmDirectory(id: UUID) -> URL {
        vmsRoot.appendingPathComponent(id.uuidString, isDirectory: true)
    }

    public static func configURL(id: UUID) -> URL {
        vmDirectory(id: id).appendingPathComponent("config.json")
    }

    public static func diskURL(id: UUID) -> URL {
        vmDirectory(id: id).appendingPathComponent("disk.img")
    }

    public static func efiStoreURL(id: UUID) -> URL {
        vmDirectory(id: id).appendingPathComponent("efi_vars.store")
    }

    public static func machineIdentifierURL(id: UUID) -> URL {
        vmDirectory(id: id).appendingPathComponent("machine_id.bin")
    }

    public static func ensureLayout() throws {
        let fm = FileManager.default
        for url in [appSupport, vmsRoot, isosRoot, shareRoot] {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
