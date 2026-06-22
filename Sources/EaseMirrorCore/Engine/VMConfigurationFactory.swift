import Foundation
import Virtualization

@available(macOS 13, *)
enum VMConfigurationFactory {
    static func makeConfiguration(
        for vm: VMDefinition,
        mode: VMRunMode,
        shareURL: URL
    ) throws -> VZVirtualMachineConfiguration {
        let config = VZVirtualMachineConfiguration()
        VMStability.applyQualityProfile(to: config, vm: vm, mode: mode)

        let diskURL = VMPaths.diskURL(id: vm.id)
        let efiStoreURL = VMPaths.efiStoreURL(id: vm.id)

        let platform = VZGenericPlatformConfiguration()
        platform.machineIdentifier = try loadOrCreateMachineIdentifier(for: vm.id)
        config.platform = platform

        let efi = VZEFIBootLoader()
        switch mode {
        case .install:
            // Fresh EFI every install boot — stops kernel panic from booting a broken partial disk.
            if FileManager.default.fileExists(atPath: efiStoreURL.path) {
                try? FileManager.default.removeItem(at: efiStoreURL)
            }
            efi.variableStore = try VZEFIVariableStore(creatingVariableStoreAt: efiStoreURL)
        case .run:
            if FileManager.default.fileExists(atPath: efiStoreURL.path) {
                efi.variableStore = VZEFIVariableStore(url: efiStoreURL)
            } else {
                efi.variableStore = try VZEFIVariableStore(creatingVariableStoreAt: efiStoreURL)
            }
        }
        config.bootLoader = efi

        var storage: [VZStorageDeviceConfiguration] = []
        if case let .install(isoURL) = mode {
            guard FileManager.default.fileExists(atPath: isoURL.path) else {
                throw EaseMirrorError.isoMissing
            }
            // Present installer media first so EFI boots Ubuntu instead of falling through to a blank disk shell.
            let isoAttachment = try VZDiskImageStorageDeviceAttachment(url: isoURL, readOnly: true)
            storage.append(VZUSBMassStorageDeviceConfiguration(attachment: isoAttachment))
        }

        let diskAttachment = try VZDiskImageStorageDeviceAttachment(url: diskURL, readOnly: false)
        storage.append(VZVirtioBlockDeviceConfiguration(attachment: diskAttachment))

        config.storageDevices = storage

        let network = VZVirtioNetworkDeviceConfiguration()
        network.attachment = VZNATNetworkDeviceAttachment()
        config.networkDevices = [network]

        let graphics = VZVirtioGraphicsDeviceConfiguration()
        let (width, height) = {
            switch mode {
            case .install: return VMStability.installGraphicsSize()
            case .run: return VMStability.runGraphicsSize()
            }
        }()
        graphics.scanouts = [
            VZVirtioGraphicsScanoutConfiguration(widthInPixels: width, heightInPixels: height)
        ]
        config.graphicsDevices = [graphics]

        config.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
        config.keyboards = [VZUSBKeyboardConfiguration()]
        config.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]

        // VirtioFS only after Mark Installed — can kernel-panic during/ before proper boot.
        if case .run = mode, vm.installed,
           FileManager.default.fileExists(atPath: shareURL.path) {
            let share = VZVirtioFileSystemDeviceConfiguration(tag: "EaseMirrorShare")
            let sharedDirectory = VZSharedDirectory(url: shareURL, readOnly: false)
            share.share = VZSingleDirectoryShare(directory: sharedDirectory)
            config.directorySharingDevices = [share]
        }

        try config.validate()
        return config
    }

    private static func loadOrCreateMachineIdentifier(for vmID: UUID) throws -> VZGenericMachineIdentifier {
        let url = VMPaths.machineIdentifierURL(id: vmID)
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) {
            guard let identifier = VZGenericMachineIdentifier(dataRepresentation: data) else {
                throw EaseMirrorError.configurationInvalid("Corrupt machine identifier")
            }
            return identifier
        }
        let identifier = VZGenericMachineIdentifier()
        try identifier.dataRepresentation.write(to: url, options: .atomic)
        return identifier
    }
}
