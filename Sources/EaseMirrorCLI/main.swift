import EaseMirrorCore
import Foundation
import Virtualization

@main
struct EaseMirrorCLI {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let command = args.first else {
            printUsage()
            exit(1)
        }

        do {
            switch command {
            case "list":
                try cmdList()
            case "create":
                try cmdCreate(Array(args.dropFirst()))
            case "delete":
                try cmdDelete(Array(args.dropFirst()))
            case "download-iso":
                try cmdDownloadISO()
            case "ghost-setup":
                try cmdGhostSetup()
            case "cloud-provision":
                try cmdCloudProvision(Array(args.dropFirst()))
            case "paths":
                cmdPaths()
            case "diagnose":
                try cmdDiagnose(Array(args.dropFirst()))
            case "repair":
                try cmdRepair(Array(args.dropFirst()))
            case "mark-installed":
                try cmdMarkInstalled(Array(args.dropFirst()))
            case "start":
                try cmdStart(Array(args.dropFirst()))
            case "reset-install":
                try cmdResetInstall(Array(args.dropFirst()))
            case "help", "-h", "--help":
                printUsage()
            default:
                fputs("Unknown command: \(command)\n", stderr)
                printUsage()
                exit(1)
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    static func printUsage() {
        print("""
        ease-mirror-cli — Ease Mirror command line

        Usage:
          ease-mirror-cli list
          ease-mirror-cli create <name> [--memory 8] [--disk 32]
          ease-mirror-cli delete <uuid>
          ease-mirror-cli download-iso
          ease-mirror-cli ghost-setup
          ease-mirror-cli cloud-provision <ip>
          ease-mirror-cli paths
          ease-mirror-cli diagnose [uuid]
          ease-mirror-cli repair <uuid>
          ease-mirror-cli mark-installed <uuid>
          ease-mirror-cli start [uuid]
          ease-mirror-cli reset-install [uuid]
        """)
    }

    static func cmdList() throws {
        let vms = VMStore.shared.all()
        if vms.isEmpty {
            print("No mirrors.")
            return
        }
        for vm in vms {
            let state = vm.installed ? "installed" : "needs-install"
            print("\(vm.id.uuidString)\t\(vm.name)\t\(state)\t\(vm.memoryGB)GB/\(vm.diskGB)GB")
        }
    }

    static func cmdCreate(_ args: [String]) throws {
        guard let name = args.first else {
            throw EaseMirrorError.processFailed("Usage: create <name> [--memory 8] [--disk 32]")
        }
        var memory = 8
        var disk = 32
        var i = 1
        while i < args.count {
            if args[i] == "--memory", i + 1 < args.count, let v = Int(args[i + 1]) {
                memory = v
                i += 2
            } else if args[i] == "--disk", i + 1 < args.count, let v = Int(args[i + 1]) {
                disk = v
                i += 2
            } else {
                i += 1
            }
        }
        let iso = GhostCloudBridge.isoExists() ? VMPaths.defaultUbuntuISO.path : nil
        let vm = try VMStore.shared.create(name: name, cpuCount: 4, memoryGB: memory, diskGB: disk, isoPath: iso)
        try GhostCloudBridge.wireShareFolderForGuest()
        print("Created \(vm.name) → \(vm.id.uuidString)")
    }

    static func cmdDelete(_ args: [String]) throws {
        guard let idStr = args.first, let id = UUID(uuidString: idStr) else {
            throw EaseMirrorError.processFailed("Usage: delete <uuid>")
        }
        try VMStore.shared.delete(id: id)
        print("Deleted \(idStr)")
    }

    static func cmdDownloadISO() throws {
        let sema = DispatchSemaphore(value: 0)
        var failure: Error?
        fputs("Downloading Ubuntu 24.04 ARM64…\n", stderr)
        let task = GhostCloudBridge.downloadISO { result in
            defer { sema.signal() }
            switch result {
            case let .failure(error):
                failure = error
            case let .success(temp):
                do {
                    try VMPaths.ensureLayout()
                    let dest = VMPaths.defaultUbuntuISO
                    if FileManager.default.fileExists(atPath: dest.path) {
                        try FileManager.default.removeItem(at: dest)
                    }
                    try FileManager.default.moveItem(at: temp, to: dest)
                    print(dest.path)
                } catch {
                    failure = error
                }
            }
        }
        task.resume()
        sema.wait()
        if let failure { throw failure }
    }

    static func cmdGhostSetup() throws {
        let result = try GhostCloudBridge.ensureGhostCloudOnMac()
        print(result.output)
    }

    static func cmdCloudProvision(_ args: [String]) throws {
        guard let ip = args.first else {
            throw EaseMirrorError.processFailed("Usage: cloud-provision <ip>")
        }
        let result = try GhostCloudBridge.runScript("provision-cloud-mirror.sh", arguments: [ip])
        print(result.output)
    }

    static func cmdPaths() {
        print("App support: \(VMPaths.appSupport.path)")
        print("VMs:         \(VMPaths.vmsRoot.path)")
        print("ISO:         \(VMPaths.defaultUbuntuISO.path)")
        print("Share:       \(VMPaths.shareRoot.path)")
    }

    static func cmdDiagnose(_ args: [String]) throws {
        let vms: [VMDefinition]
        if let idStr = args.first, let id = UUID(uuidString: idStr), let vm = VMStore.shared.get(id: id) {
            vms = [vm]
        } else {
            vms = VMStore.shared.all()
        }
        if vms.isEmpty {
            print("No mirrors.")
            return
        }
        for vm in vms {
            let mode: VMRunMode = vm.installed
                ? .run
                : .install(isoURL: VMPaths.defaultUbuntuISO)
            let report = VMStability.preflight(vm: vm, mode: mode)
            print("\(vm.name) [\(vm.id.uuidString)]")
            print(VMStability.formatReport(report))
            print("")
        }
    }

    static func cmdRepair(_ args: [String]) throws {
        guard let idStr = args.first, let id = UUID(uuidString: idStr) else {
            throw EaseMirrorError.processFailed("Usage: repair <uuid>")
        }
        guard VMStore.shared.get(id: id) != nil else {
            throw EaseMirrorError.vmNotFound(id)
        }
        let backup = try VMStability.repairEFI(for: id)
        print("EFI reset. Backup: \(backup.path)")
        print("Start the mirror again from the app.")
    }

    static func cmdMarkInstalled(_ args: [String]) throws {
        guard let idStr = args.first, let id = UUID(uuidString: idStr) else {
            throw EaseMirrorError.processFailed("Usage: mark-installed <uuid>")
        }
        guard VMStore.shared.get(id: id) != nil else {
            throw EaseMirrorError.vmNotFound(id)
        }
        try VMStore.shared.markInstalled(id: id)
        print("Marked installed. Stop VM → Start again (boots from disk, share enabled).")
    }

    @MainActor
    static func cmdStart(_ args: [String]) throws {
        let vm: VMDefinition
        if let idStr = args.first, let id = UUID(uuidString: idStr) {
            guard let found = VMStore.shared.get(id: id) else {
                throw EaseMirrorError.vmNotFound(id)
            }
            vm = found
        } else if let first = VMStore.shared.all().first {
            vm = first
        } else {
            throw EaseMirrorError.processFailed("No mirrors — create one first")
        }

        try GhostCloudBridge.wireShareFolderForGuest()
        let mode: VMRunMode = vm.installed
            ? .run
            : .install(isoURL: VMPaths.defaultUbuntuISO)
        let preflight = VMStability.preflight(vm: vm, mode: mode)
        guard preflight.allOK else {
            fputs(VMStability.formatReport(preflight) + "\n", stderr)
            throw EaseMirrorError.configurationInvalid("Preflight failed")
        }

        let engine = LinuxVMEngine()
        let sema = DispatchSemaphore(value: 0)
        var failure: Error?
        Task { @MainActor in
            do {
                try await engine.start(vm: vm, mode: mode)
                print("VM running: \(vm.name) [\(vm.id.uuidString)]")
            } catch {
                failure = error
                fputs("Start failed: \(error.localizedDescription)\n", stderr)
            }
            sema.signal()
        }
        sema.wait()
        if let failure { throw failure }
        print("Press Ctrl+C to stop.")
        RunLoop.main.run()
    }

    static func cmdResetInstall(_ args: [String]) throws {
        let id: UUID
        if let idStr = args.first, let parsed = UUID(uuidString: idStr) {
            id = parsed
        } else if let first = VMStore.shared.all().first {
            id = first.id
        } else {
            throw EaseMirrorError.processFailed("No mirrors")
        }
        guard VMStore.shared.get(id: id) != nil else {
            throw EaseMirrorError.vmNotFound(id)
        }
        try VMStore.shared.resetInstall(id: id)
        print("Reset \(id.uuidString) — run Start / ease-mirror-cli start to install from ISO")
    }
}
