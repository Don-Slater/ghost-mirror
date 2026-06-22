import EaseMirrorCore
import SwiftUI

struct VPSSettingsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MirrorField(label: "VPS IP", text: $appModel.cloudIP, placeholder: "72.62.212.87")
            MirrorField(label: "Ghost Cloud URL", text: $appModel.ghostURL, placeholder: "https://ghostcloud.example.com")
            MirrorField(label: "SSH user", text: $appModel.sshUser, placeholder: "root")

            VStack(alignment: .leading, spacing: 6) {
                Text("SSH key")
                    .font(.caption)
                    .foregroundStyle(MirrorTheme.muted)
                HStack(spacing: 8) {
                    TextField("~/.ssh/your_key", text: $appModel.sshKeyPath)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(MirrorTheme.fieldFill)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(MirrorTheme.line, lineWidth: 1)
                                }
                        }
                        .foregroundStyle(MirrorTheme.label)
                    MirrorActionButton(title: "Choose", width: 78) {
                        appModel.chooseSSHKeyFile()
                    }
                }
            }

            MirrorField(label: "VNC password", text: $appModel.vncPassword, placeholder: "••••••••", secure: true)

            HStack {
                Spacer()
                MirrorActionButton(title: "Save", prominent: true, width: 96) {
                    appModel.saveVPSSettings()
                }
                .disabled(!appModel.vpsFormValid)
            }
        }
    }
}

struct VPSSettingsSheet: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GlossyBlackFrame {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("VPS Details")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MirrorTheme.label)
                    Spacer()
                    MirrorActionButton(title: "Done", width: 82) { dismiss() }
                }

                VPSSettingsView()
            }
            .padding(28)
        }
        .frame(width: 500, height: 520)
    }
}
