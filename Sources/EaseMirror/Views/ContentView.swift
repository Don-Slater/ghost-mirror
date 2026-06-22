import EaseMirrorCore
import SwiftUI
import Virtualization

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        GlossyBlackFrame {
            Group {
                if #available(macOS 13, *), appModel.engine.showsDisplay, let machine = appModel.engine.virtualMachine {
                    vmView(machine)
                } else {
                    homeView
                }
            }
        }
        .sheet(isPresented: $appModel.showCreateWizard) {
            CreateMirrorSheet()
                .environmentObject(appModel)
        }
        .sheet(isPresented: $appModel.showCloudDesktop) {
            if let url = appModel.cloudDesktopURL {
                CloudDesktopView(url: url)
            }
        }
        .sheet(isPresented: $appModel.showVPSSettings) {
            VPSSettingsSheet()
                .environmentObject(appModel)
        }
        .onAppear {
            appModel.handleLaunchArguments(Array(CommandLine.arguments))
        }
        .alert("Ubuntu could not start", isPresented: $appModel.showBootError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appModel.bootErrorMessage)
        }
    }

    private var homeView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 58)

            GhostReplicaLogoView()
                .padding(.horizontal, 18)

            Spacer(minLength: 46)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    MirrorActionButton(title: "Terminal", prominent: true) {
                        appModel.openCommandBridge()
                    }
                    MirrorActionButton(title: "Open Vault") {
                        appModel.openGhostCloud()
                    }
                    MirrorActionButton(title: "Cloud") {
                        appModel.openCloudDesktop()
                    }
                    MirrorActionButton(title: "VPS") {
                        appModel.showVPSSettings = true
                    }
                }

                HStack(spacing: 12) {
                    MirrorActionButton(title: ubuntuStartLabel, prominent: true, width: 156) {
                        Task { await appModel.startUbuntu() }
                    }
                    .disabled(appModel.ubuntuRunning || appModel.ubuntuStarting)

                    MirrorActionButton(title: "Stop", width: 92) {
                        Task { await appModel.stop() }
                    }
                    .disabled(!appModel.ubuntuRunning && !appModel.ubuntuStarting)
                }
            }

            if appModel.ubuntuStarting {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                    .padding(.top, 18)
            }

            Spacer(minLength: 40)

            Text(appModel.statusMessage)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(statusColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .truncationMode(.middle)
                .frame(maxWidth: 520)
                .padding(.bottom, 22)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func vmView(_ machine: VZVirtualMachine) -> some View {
        VStack(spacing: 0) {
            if case .starting = appModel.engine.state {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small).tint(.white)
                    Text(appModel.engine.bootStalled
                        ? "Boot stuck — use menu: Reset & Install Ubuntu"
                        : "Booting Ubuntu…")
                        .font(.caption)
                        .foregroundStyle(MirrorTheme.muted)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.25))
            }

            ZStack {
                Color.black
                VMContainerView(virtualMachine: machine, engine: appModel.engine)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: 1440, maxHeight: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 12) {
                Text(appModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(MirrorTheme.muted)
                    .lineLimit(1)
                Spacer()
                if let vm = appModel.selectedMirror, !vm.installed {
                    MirrorActionButton(title: "Mark Installed") {
                        appModel.markInstalled()
                    }
                }
                MirrorActionButton(title: "Stop") {
                    Task { await appModel.stop() }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.35))
        }
    }

    private var ubuntuStartLabel: String {
        if let vm = appModel.selectedMirror ?? appModel.mirrors.first {
            return vm.installed ? "Start Ubuntu" : "Install Ubuntu"
        }
        return "Start Ubuntu"
    }

    private var statusColor: Color {
        let msg = appModel.statusMessage.lowercased()
        if msg.contains("fail") || msg.contains("error") || msg.contains("fix before") {
            return Color(red: 1, green: 0.45, blue: 0.45)
        }
        return MirrorTheme.muted
    }
}

struct CreateMirrorSheet: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Ease Mirror"
    @State private var memoryGB = 8
    @State private var diskGB = 32

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Local Mirror")
                .font(.title2.bold())

            TextField("Name", text: $name)
            Stepper("Memory: \(memoryGB) GB", value: $memoryGB, in: 4...32, step: 2)
            Stepper("Disk: \(diskGB) GB", value: $diskGB, in: 24...256, step: 8)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") {
                    appModel.createMirror(name: name, memoryGB: memoryGB, diskGB: diskGB)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
