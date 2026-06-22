import SwiftUI

@main
struct EaseMirrorApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup("Ghost Mirror") {
            ContentView()
                .environmentObject(appModel)
                .frame(minWidth: 960, minHeight: 640)
        }
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Local Mirror…") {
                    appModel.showCreateWizard = true
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            CommandMenu("Ghost Mirror") {
                Button("VPS Details…") { appModel.showVPSSettings = true }
                Divider()
                Button("Terminal Bridge") { appModel.openCommandBridge() }
                Button("Open Vault") { appModel.openGhostCloud() }
                Button("Cloud Desktop (browser)") { appModel.openCloudDesktop() }
                Divider()
                Button("Repair EFI Boot…") { appModel.repairSelectedMirror() }
                Button("Reset & Install Ubuntu…") {
                    Task { await appModel.resetInstallAndStart() }
                }
                Divider()
                Button("Black Book…") { appModel.openBlackBook() }
                Divider()
                Toggle(isOn: Binding(
                    get: { appModel.productTier == .full },
                    set: { appModel.setProductTier($0 ? .full : .cheap) }
                )) {
                    Text("Full Mode")
                }
            }
        }
    }
}
