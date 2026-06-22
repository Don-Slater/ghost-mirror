import Combine
import EaseMirrorCore
import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var mirrors: [VMDefinition] = []
    @Published var selectedID: UUID?
    @Published var showCreateWizard = false
    @Published var statusMessage = "Ready"
    @Published var isoReady = GhostCloudBridge.isoExists()
    @Published var isoDownloading = false
    @Published var isoProgress: Double = 0
    @Published var showCloudDesktop = false
    @Published var cloudDesktopURL: URL?
    @Published var cloudIP: String = CloudMirrorConfig.ip
    @Published var ghostURL: String = CloudMirrorConfig.settings.ghostURL
    @Published var sshUser: String = CloudMirrorConfig.settings.sshUser
    @Published var sshKeyPath: String = CloudMirrorConfig.settings.sshKeyPath
    @Published var vncPassword: String = CloudMirrorConfig.settings.vncPassword
    @Published var showVPSSettings = false
    @Published var vpsConfigured = FileManager.default.fileExists(atPath: CloudMirrorConfig.envPath().path)
    @Published var productTier: ProductTier = ProductTier.current
    @Published var showBootError = false
    @Published var bootErrorMessage = ""

    let engine = LinuxVMEngine()
    private let clipboardBridge = ClipboardBridge()
    @Published var clipboardBridgeActive = false

    var clipboardLinuxReady: Bool { clipboardBridge.linuxSideReady }

    init() {
        reloadVPSSettings()
        refresh()
        runBootCheck()
        clipboardBridge.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        engine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        engine.$state
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleEngineStateChange(state)
            }
            .store(in: &cancellables)
        engine.$bootStalled
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stalled in
                guard let self, stalled else { return }
                self.statusMessage = "Boot slow or stuck — try Reset & Install Ubuntu from the menu"
            }
            .store(in: &cancellables)
    }

    var selectedMirror: VMDefinition? {
        guard let selectedID else { return nil }
        return mirrors.first { $0.id == selectedID }
    }

    func refresh() {
        mirrors = VMStore.shared.all()
        isoReady = GhostCloudBridge.isoExists()
        if selectedID == nil {
            selectedID = mirrors.first?.id
        }
    }

    func runBootCheck() {
        guard let vm = mirrors.first else {
            statusMessage = "Ready — create your first mirror"
            return
        }
        let mode: VMRunMode = vm.installed
            ? .run
            : .install(isoURL: VMPaths.defaultUbuntuISO)
        let preflight = VMStability.preflight(vm: vm, mode: mode)
        if preflight.allOK {
            if vm.installed {
                statusMessage = "Ready — click Start Ubuntu for your Linux PC"
            } else {
                statusMessage = "Ready — click Install Ubuntu (complete setup in the framed window)"
            }
        } else {
            let failed = preflight.diagnostics.filter { !$0.ok }.map(\.name).joined(separator: ", ")
            statusMessage = "Fix before boot: \(failed)"
        }
    }

    func createMirror(name: String, memoryGB: Int, diskGB: Int) {
        do {
            let iso = GhostCloudBridge.isoExists() ? VMPaths.defaultUbuntuISO.path : nil
            let vm = try VMStore.shared.create(
                name: name,
                cpuCount: 4,
                memoryGB: memoryGB,
                diskGB: diskGB,
                isoPath: iso
            )
            try GhostCloudBridge.wireShareFolderForGuest()
            selectedID = vm.id
            refresh()
            statusMessage = "Created mirror \"\(name)\""
            showCreateWizard = false
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func deleteMirror(_ vm: VMDefinition) async {
        if engine.activeVMID == vm.id {
            clipboardBridge.stop()
            clipboardBridgeActive = false
            await engine.stop()
        }
        do {
            try VMStore.shared.delete(id: vm.id)
            if selectedID == vm.id { selectedID = nil }
            refresh()
            statusMessage = "Deleted \"\(vm.name)\""
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func startSelected() async {
        guard let vm = selectedMirror else { return }
        await start(vm)
    }

    func startUbuntu() async {
        if mirrors.isEmpty {
            createMirror(name: "Ghost Mirror", memoryGB: 4, diskGB: 32)
            refresh()
        }
        guard let vm = selectedMirror ?? mirrors.first else {
            statusMessage = "Could not create Ubuntu mirror"
            return
        }
        if selectedID == nil {
            selectedID = vm.id
        }
        if !vm.installed, !GhostCloudBridge.isoExists() {
            statusMessage = "Downloading Ubuntu ISO…"
            downloadISO()
            return
        }
        await start(vm)
    }

    var ubuntuRunning: Bool {
        engine.isRunning || engine.showsDisplay
    }

    var ubuntuStarting: Bool {
        if case .starting = engine.state { return true }
        return false
    }

    func start(_ vm: VMDefinition) async {
        do {
            showBootError = false
            try GhostCloudBridge.wireShareFolderForGuest()
            let mode: VMRunMode
            if vm.installed {
                mode = .run
            } else if let isoPath = vm.isoPath ?? (GhostCloudBridge.isoExists() ? VMPaths.defaultUbuntuISO.path : nil) {
                mode = .install(isoURL: URL(fileURLWithPath: isoPath))
            } else {
                statusMessage = "Download Ubuntu ISO first"
                return
            }

            let preflight = VMStability.preflight(vm: vm, mode: mode)
            if !preflight.allOK {
                let failed = preflight.diagnostics.filter { !$0.ok }.map(\.detail).joined(separator: "; ")
                statusMessage = "Preflight failed: \(failed)"
                return
            }

            statusMessage = vm.installed
                ? "Booting Ubuntu…"
                : "Loading Ubuntu installer — first boot can take 2–3 minutes"

            Task { @MainActor in
                do {
                    try await self.engine.start(vm: vm, mode: mode)
                    if vm.installed {
                        self.clipboardBridge.start()
                        self.clipboardBridgeActive = true
                        self.statusMessage = "Running — after desktop loads: sudo bash RUN-CLIPBOARD-IN-LINUX.sh"
                    } else {
                        self.clipboardBridge.stop()
                        self.clipboardBridgeActive = false
                        self.statusMessage = "Install in progress — Mark Installed only after Ubuntu desktop appears"
                    }
                } catch {
                    self.clipboardBridge.stop()
                    self.clipboardBridgeActive = false
                    self.statusMessage = error.localizedDescription
                    self.bootErrorMessage = error.localizedDescription
                    self.showBootError = true
                }
            }
        } catch {
            clipboardBridge.stop()
            clipboardBridgeActive = false
            statusMessage = error.localizedDescription
            bootErrorMessage = error.localizedDescription
            showBootError = true
        }
    }

    func stop() async {
        clipboardBridge.stop()
        clipboardBridgeActive = false
        await engine.stop()
        statusMessage = "Stopped"
    }

    func repairSelectedMirror() {
        guard let vm = selectedMirror else { return }
        do {
            let msg = try VMStability.repairInstallBoot(for: vm.id)
            statusMessage = msg
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func resetInstallSelectedMirror() async {
        guard let vm = selectedMirror ?? mirrors.first else { return }
        if engine.activeVMID == vm.id {
            await stop()
        }
        do {
            try VMStore.shared.resetInstall(id: vm.id)
            refresh()
            statusMessage = "Reset — click Install Ubuntu to run the installer from ISO"
            showBootError = false
        } catch {
            statusMessage = error.localizedDescription
            bootErrorMessage = error.localizedDescription
            showBootError = true
        }
    }

    func resetInstallAndStart() async {
        await resetInstallSelectedMirror()
        guard let vm = selectedMirror ?? mirrors.first else { return }
        await start(vm)
    }

    func markInstalled() {
        guard let vm = selectedMirror else { return }
        do {
            try VMStore.shared.markInstalled(id: vm.id)
            refresh()
            statusMessage = "Installed — Stop, then Start Ubuntu. Then run clipboard setup in Linux."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func downloadISO() {
        guard !isoDownloading else { return }
        isoDownloading = true
        isoProgress = 0
        statusMessage = "Downloading Ubuntu 24.04 ARM64…"

        let task = GhostCloudBridge.downloadISO { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isoDownloading = false
                switch result {
                case let .failure(error):
                    self.statusMessage = error.localizedDescription
                case let .success(temp):
                    do {
                        try VMPaths.ensureLayout()
                        if FileManager.default.fileExists(atPath: VMPaths.defaultUbuntuISO.path) {
                            try FileManager.default.removeItem(at: VMPaths.defaultUbuntuISO)
                        }
                        try FileManager.default.moveItem(at: temp, to: VMPaths.defaultUbuntuISO)
                        self.isoReady = true
                        self.statusMessage = "Ubuntu ISO ready"
                        self.refresh()
                    } catch {
                        self.statusMessage = error.localizedDescription
                    }
                }
            }
        }
        task.progress.publisher(for: \.fractionCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.isoProgress = value
            }
            .store(in: &cancellables)

        task.resume()
    }

    func setupGhostCloud() {
        Task.detached {
            do {
                let result = try GhostCloudBridge.ensureGhostCloudOnMac()
                await MainActor.run {
                    self.statusMessage = "Ghost Cloud ready"
                    _ = result.output
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }

    func provisionCloudMirror(ip: String) {
        Task.detached {
            do {
                let result = try GhostCloudBridge.runScript("provision-cloud-mirror.sh", arguments: [ip])
                await MainActor.run {
                    self.statusMessage = "Cloud mirror provisioned"
                    _ = result.output
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }

    func setupCloudDesktop() {
        let ip = cloudIP.isEmpty ? CloudMirrorConfig.ip : cloudIP
        Task.detached {
            do {
                let result = try GhostCloudBridge.runScript("setup-cloud-desktop.sh", arguments: [ip])
                await MainActor.run {
                    self.cloudIP = ip
                    self.statusMessage = "Linux desktop installed (VNC + noVNC)"
                    _ = result.output
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }

    func openCloudDesktop() {
        if productTier == .cheap {
            openCloudDesktopInBrowser()
            return
        }
        openCloudDesktopInBrowser()
    }

    func openCloudDesktopInApp() {
        let ip = cloudIP.isEmpty ? CloudMirrorConfig.ip : cloudIP
        statusMessage = "Starting SSH tunnel…"
        Task.detached {
            do {
                _ = try GhostCloudBridge.runScript("tunnel-cloud-vnc.sh", arguments: [ip, "start"])
                let url = CloudMirrorConfig.novncURL
                await MainActor.run {
                    self.cloudDesktopURL = url
                    self.showCloudDesktop = true
                    self.statusMessage = "Cloud desktop connected (Linux VNC)"
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }

    func openCloudDesktopInBrowser(ip: String? = nil) {
        if let ip, !ip.isEmpty { cloudIP = ip }
        statusMessage = "Opening cloud desktop in browser…"
        Task.detached {
            do {
                let result = try GhostCloudBridge.runScript("connect-cloud-desktop.sh")
                await MainActor.run {
                    self.statusMessage = "Cloud desktop opened in browser"
                    _ = result.output
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }

    func openGhostCloud() {
        NSWorkspace.shared.open(CloudMirrorConfig.ghostURL)
        statusMessage = "Opened Ghost Cloud"
    }

    func openCommandBridge() {
        NSWorkspace.shared.open(CloudMirrorConfig.bridgeURL)
        statusMessage = "Opened Ghost Cloud command bridge"
    }

    func openBlackBook() {
        let url = CloudMirrorConfig.blackBookURL
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.open(url)
            statusMessage = "Black Book opened"
        } else {
            statusMessage = "BLACKBOOK.md not found at \(url.path)"
        }
    }

    var vpsFormValid: Bool {
        !cloudIP.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !ghostURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !sshUser.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !sshKeyPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func reloadVPSSettings() {
        let settings = CloudMirrorConfig.settings
        cloudIP = settings.ip
        ghostURL = settings.ghostURL
        sshUser = settings.sshUser
        sshKeyPath = settings.sshKeyPath
        vncPassword = settings.vncPassword
        vpsConfigured = FileManager.default.fileExists(atPath: CloudMirrorConfig.envPath().path)
    }

    func saveVPSSettings() {
        let settings = VPSSettings(
            ip: cloudIP,
            ghostURL: ghostURL,
            sshUser: sshUser,
            sshKeyPath: sshKeyPath,
            vncPassword: vncPassword
        )
        do {
            try CloudMirrorConfig.save(settings)
            vpsConfigured = true
            statusMessage = "VPS details saved"
        } catch {
            statusMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    func chooseSSHKeyFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Choose SSH private key"
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        if panel.runModal() == .OK, let url = panel.url {
            sshKeyPath = url.path
        }
    }

    func setProductTier(_ tier: ProductTier) {
        productTier = tier
        ProductTier.current = tier
        statusMessage = tier == .cheap ? "Cheap model — scripts do the fiddly bits" : "Full mode — all controls visible"
    }

    func handleLaunchArguments(_ args: [String]) {
        if let idx = args.firstIndex(of: "--cloud-desktop"), idx + 1 < args.count,
           let url = URL(string: args[idx + 1]) {
            cloudDesktopURL = url
            showCloudDesktop = true
        }
    }

    private func handleEngineStateChange(_ state: LinuxVMEngine.State) {
        switch state {
        case .failed(let message):
            clipboardBridge.stop()
            clipboardBridgeActive = false
            statusMessage = message
            bootErrorMessage = message
            showBootError = true
        case .stopped:
            clipboardBridge.stop()
            clipboardBridgeActive = false
            statusMessage = "Stopped"
        case .starting, .running, .idle:
            break
        }
    }

    private var cancellables = Set<AnyCancellable>()
}
