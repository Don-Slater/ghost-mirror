import Combine
import Foundation
import Virtualization

@available(macOS 13, *)
@MainActor
public final class LinuxVMEngine: NSObject, ObservableObject {
    public enum State: Equatable, Sendable {
        case idle
        case starting
        case running
        case stopped
        case failed(String)
    }

    public static let bootStallWarningSeconds: UInt64 = 45

    @Published public private(set) var state: State = .idle
    @Published public private(set) var activeVMID: UUID?
    @Published public private(set) var bootStalled = false

    public private(set) var virtualMachine: VZVirtualMachine?

    private var bootWatchTask: Task<Void, Never>?
    private var armedMachine: VZVirtualMachine?
    private var startContinuation: CheckedContinuation<Void, Error>?

    public override init() {
        super.init()
    }

    public var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    public var showsDisplay: Bool {
        switch state {
        case .starting, .running:
            return virtualMachine != nil
        default:
            return false
        }
    }

    /// Stage 1: build config and expose the VM to SwiftUI. Start is deferred until the display attaches.
    public func start(vm: VMDefinition, mode: VMRunMode) async throws {
        if isRunning || showsDisplay {
            throw EaseMirrorError.engineBusy
        }

        cancelBootWatch()
        bootStalled = false
        try VMPaths.ensureLayout()
        let config = try VMConfigurationFactory.makeConfiguration(
            for: vm,
            mode: mode,
            shareURL: VMPaths.shareRoot
        )
        let machine = VZVirtualMachine(configuration: config)
        machine.delegate = self

        state = .starting
        activeVMID = vm.id
        virtualMachine = machine
        armedMachine = machine

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            startContinuation = continuation
        }
    }

    /// Stage 2: called by VMContainerView once VZVirtualMachineView is in the window hierarchy.
    public func commitStartIfNeeded() {
        guard let machine = armedMachine, startContinuation != nil else { return }
        armedMachine = nil

        final class BootGate: @unchecked Sendable {
            var finished = false
        }
        let gate = BootGate()

        func finish(_ result: Result<Void, Error>) {
            Task { @MainActor in
                guard !gate.finished else { return }
                gate.finished = true
                self.cancelBootWatch()
                let continuation = self.startContinuation
                self.startContinuation = nil
                switch result {
                case .success:
                    continuation?.resume()
                case let .failure(error):
                    continuation?.resume(throwing: error)
                }
            }
        }

        bootWatchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.bootStallWarningSeconds * 1_000_000_000)
            guard !Task.isCancelled, !gate.finished else { return }
            self.bootStalled = true
        }

        machine.start { [weak self] result in
            Task { @MainActor in
                guard let self else {
                    finish(.failure(EaseMirrorError.engineBusy))
                    return
                }
                self.bootStalled = false
                switch result {
                case .success:
                    self.state = .running
                    finish(.success(()))
                case let .failure(error):
                    self.state = .failed(error.localizedDescription)
                    self.activeVMID = nil
                    self.virtualMachine = nil
                    finish(.failure(error))
                }
            }
        }
    }

    public func stop() async {
        cancelBootWatch()
        bootStalled = false
        armedMachine = nil
        if let continuation = startContinuation {
            startContinuation = nil
            continuation.resume(throwing: EaseMirrorError.engineBusy)
        }

        guard let machine = virtualMachine else {
            state = .stopped
            activeVMID = nil
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            machine.stop { [weak self] _ in
                Task { @MainActor in
                    guard let self else {
                        continuation.resume()
                        return
                    }
                    self.state = .stopped
                    self.activeVMID = nil
                    self.virtualMachine = nil
                    continuation.resume()
                }
            }
        }
    }

    public func pause() {
        virtualMachine?.pause(completionHandler: { _ in })
    }

    public func resume() {
        virtualMachine?.resume(completionHandler: { _ in })
    }

    private func cancelBootWatch() {
        bootWatchTask?.cancel()
        bootWatchTask = nil
    }
}

@available(macOS 13, *)
extension LinuxVMEngine: VZVirtualMachineDelegate {
    nonisolated public func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        Task { @MainActor in
            cancelBootWatch()
            bootStalled = false
            state = .stopped
            activeVMID = nil
            self.virtualMachine = nil
        }
    }

    nonisolated public func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        Task { @MainActor in
            cancelBootWatch()
            bootStalled = false
            state = .failed(error.localizedDescription)
            activeVMID = nil
            self.virtualMachine = nil
        }
    }
}
