import Foundation
import Virtualization

@available(macOS 13, *)
public enum VMStability: Sendable {
    public struct Diagnostic: Sendable {
        public let name: String
        public let ok: Bool
        public let detail: String
    }

    public struct Preflight: Sendable {
        public let diagnostics: [Diagnostic]
        public var allOK: Bool { diagnostics.allSatisfy(\.ok) }
    }

    /// Quality-first limits — install uses lighter resources to avoid freeze/panic.
    public static func applyQualityProfile(
        to config: VZVirtualMachineConfiguration,
        vm: VMDefinition,
        mode: VMRunMode
    ) {
        let minCPU = VZVirtualMachineConfiguration.minimumAllowedCPUCount
        let maxCPU = VZVirtualMachineConfiguration.maximumAllowedCPUCount
        let minMem = VZVirtualMachineConfiguration.minimumAllowedMemorySize
        let maxMem = VZVirtualMachineConfiguration.maximumAllowedMemorySize

        switch mode {
        case .install:
            config.cpuCount = min(max(2, minCPU), maxCPU)
            let installMem: UInt64 = 4 * 1024 * 1024 * 1024
            config.memorySize = min(max(installMem, minMem), maxMem)
        case .run:
            config.cpuCount = min(max(vm.cpuCount, minCPU), maxCPU)
            config.memorySize = min(max(vm.memoryBytes, minMem), maxMem)
        }
    }

    public static func installGraphicsSize() -> (width: Int, height: Int) {
        (1280, 720)
    }

    public static func runGraphicsSize() -> (width: Int, height: Int) {
        (1280, 800)
    }

    public static func preflight(vm: VMDefinition, mode: VMRunMode) -> Preflight {
        var items: [Diagnostic] = []

        if #available(macOS 13, *) {
            items.append(Diagnostic(
                name: "Virtualization.framework",
                ok: true,
                detail: "macOS 13+ OK"
            ))
        } else {
            items.append(Diagnostic(
                name: "Virtualization.framework",
                ok: false,
                detail: "Requires macOS 13 or later"
            ))
        }

        let diskURL = VMPaths.diskURL(id: vm.id)
        if FileManager.default.fileExists(atPath: diskURL.path) {
            let size = (try? FileManager.default.attributesOfItem(atPath: diskURL.path)[.size] as? Int64) ?? 0
            items.append(Diagnostic(
                name: "Virtual disk",
                ok: size > 1_000_000_000,
                detail: size > 0 ? "\(size / 1_000_000_000) GB image" : "disk.img missing or empty"
            ))
        } else {
            items.append(Diagnostic(name: "Virtual disk", ok: false, detail: "disk.img not found"))
        }

        if case let .install(isoURL) = mode {
            let isoPath = isoURL.path
            if FileManager.default.fileExists(atPath: isoPath) {
                let size = (try? FileManager.default.attributesOfItem(atPath: isoPath)[.size] as? Int64) ?? 0
                let ok = size > 2_500_000_000
                items.append(Diagnostic(
                    name: "Ubuntu ISO",
                    ok: ok,
                    detail: ok ? "ISO present (\(size / 1_000_000_000) GB)" : "ISO too small — re-download"
                ))
            } else {
                items.append(Diagnostic(name: "Ubuntu ISO", ok: false, detail: "ISO missing"))
            }
            items.append(Diagnostic(
                name: "Install safety",
                ok: !vm.installed,
                detail: vm.installed
                    ? "Already installed — use Start without ISO"
                    : "Install mode — no share folder (prevents kernel panic)"
            ))
        }

        if vm.installed {
            items.append(Diagnostic(
                name: "Boot mode",
                ok: true,
                detail: "Run from disk — share folder enabled after Mark Installed"
            ))
        }

        let efi = VMPaths.efiStoreURL(id: vm.id)
        if FileManager.default.fileExists(atPath: efi.path) {
            items.append(Diagnostic(name: "EFI store", ok: true, detail: "Present"))
        } else {
            items.append(Diagnostic(name: "EFI store", ok: true, detail: "Will be created on first boot"))
        }

        return Preflight(diagnostics: items)
    }

    /// Reset EFI boot entries after kernel panic / bad boot loop. Keeps disk intact.
    public static func repairEFI(for vmID: UUID) throws -> URL {
        let efiURL = VMPaths.efiStoreURL(id: vmID)
        let fm = FileManager.default
        guard fm.fileExists(atPath: efiURL.path) else {
            return efiURL
        }
        let backup = efiURL.deletingLastPathComponent()
            .appendingPathComponent("efi_vars.store.bak.\(Int(Date().timeIntervalSince1970))")
        try fm.copyItem(at: efiURL, to: backup)
        try fm.removeItem(at: efiURL)
        return backup
    }

    /// Full local recovery after kernel panic during install.
    public static func repairInstallBoot(for vmID: UUID) throws -> String {
        let backup = try repairEFI(for: vmID)
        return "EFI reset (\(backup.lastPathComponent)). Start Install again — if Ubuntu desktop already works, Mark Installed instead."
    }

    public static func formatReport(_ preflight: Preflight) -> String {
        var lines = ["Ease Mirror local VM diagnostic:"]
        for item in preflight.diagnostics {
            let mark = item.ok ? "OK" : "FAIL"
            lines.append("  [\(mark)] \(item.name) — \(item.detail)")
        }
        lines.append(preflight.allOK ? "  → Ready to boot" : "  → Fix FAIL items before Start")
        return lines.joined(separator: "\n")
    }
}
