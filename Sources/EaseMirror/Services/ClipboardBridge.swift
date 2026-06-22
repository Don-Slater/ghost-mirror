import AppKit
import EaseMirrorCore
import Foundation

/// Mac ↔ Linux clipboard via VirtioFS share files (host_clipboard.txt / guest_clipboard.txt).
@MainActor
final class ClipboardBridge: ObservableObject {
    @Published private(set) var linuxSideReady = false

    private var timer: Timer?
    private var lastHost = ""
    private var lastGuest = ""
    private var lastPasteboardChangeCount = 0
    private var lastHostWrite = Date.distantPast
    private var lastGuestApply = Date.distantPast

    private var hostFile: URL { VMPaths.shareRoot.appendingPathComponent("host_clipboard.txt") }
    private var guestFile: URL { VMPaths.shareRoot.appendingPathComponent("guest_clipboard.txt") }
    private var heartbeatFile: URL { VMPaths.shareRoot.appendingPathComponent("guest_clipboard_alive") }

    var isActive: Bool { timer != nil }

    func start() {
        guard timer == nil else { return }
        try? VMPaths.ensureLayout()
        try? "".write(to: hostFile, atomically: true, encoding: .utf8)
        lastHost = ""
        lastGuest = ""
        lastPasteboardChangeCount = NSPasteboard.general.changeCount
        linuxSideReady = false

        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        linuxSideReady = false
    }

    private func tick() {
        checkLinuxHeartbeat()
        syncHostToShare()
        syncShareToHost()
    }

    private func checkLinuxHeartbeat() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: heartbeatFile.path),
              let modified = attrs[.modificationDate] as? Date else {
            linuxSideReady = false
            return
        }
        linuxSideReady = Date().timeIntervalSince(modified) < 3.0
    }

    private func syncHostToShare() {
        let pasteboard = NSPasteboard.general
        let count = pasteboard.changeCount
        guard count != lastPasteboardChangeCount else { return }
        lastPasteboardChangeCount = count

        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        guard text != lastHost else { return }
        if Date().timeIntervalSince(lastGuestApply) < 0.6 { return }

        lastHost = text
        lastHostWrite = Date()
        atomicWrite(text, to: hostFile)
    }

    private func syncShareToHost() {
        guard let data = try? Data(contentsOf: guestFile),
              let text = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: CharacterSet(charactersIn: "\0")) else { return }
        guard !text.isEmpty, text != lastGuest else { return }
        if text == lastHost, Date().timeIntervalSince(lastHostWrite) < 0.6 { return }

        lastGuest = text
        lastHost = text
        lastGuestApply = Date()
        lastPasteboardChangeCount = NSPasteboard.general.changeCount + 1

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastPasteboardChangeCount = pasteboard.changeCount
    }

    private func atomicWrite(_ text: String, to url: URL) {
        let tmp = url.deletingLastPathComponent().appendingPathComponent(".clip_tmp")
        do {
            try text.write(to: tmp, atomically: true, encoding: .utf8)
            let fm = FileManager.default
            if fm.fileExists(atPath: url.path) {
                try fm.removeItem(at: url)
            }
            try fm.moveItem(at: tmp, to: url)
        } catch {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
