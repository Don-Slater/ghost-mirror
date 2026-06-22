import EaseMirrorCore
import SwiftUI
import Virtualization

@available(macOS 13, *)
struct VMContainerView: NSViewRepresentable {
    let virtualMachine: VZVirtualMachine
    let engine: LinuxVMEngine

    func makeNSView(context: Context) -> VZVirtualMachineView {
        let view = VZVirtualMachineView()
        view.capturesSystemKeys = true
        view.virtualMachine = virtualMachine
        DispatchQueue.main.async {
            engine.commitStartIfNeeded()
        }
        return view
    }

    func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {
        if nsView.virtualMachine !== virtualMachine {
            nsView.virtualMachine = virtualMachine
            DispatchQueue.main.async {
                engine.commitStartIfNeeded()
            }
        }
    }
}
