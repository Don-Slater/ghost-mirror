import Foundation

public struct GhostCloudBridge: Sendable {
    public static let benStudioRoot: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("BenStudio", isDirectory: true)
    }()

    public static func scriptsRoot() -> URL {
        benStudioRoot.appendingPathComponent("EaseMirror/scripts", isDirectory: true)
    }

    public struct CommandResult: Sendable {
        public let exitCode: Int32
        public let output: String
    }

    @discardableResult
    public static func runScript(_ name: String, arguments: [String] = []) throws -> CommandResult {
        let script = scriptsRoot().appendingPathComponent(name)
        guard FileManager.default.isExecutableFile(atPath: script.path) else {
            throw EaseMirrorError.processFailed("Script not found or not executable: \(script.path)")
        }
        return try run(executable: "/bin/bash", arguments: [script.path] + arguments)
    }

    @discardableResult
    public static func run(executable: String, arguments: [String] = [], environment: [String: String]? = nil) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        if let environment {
            var env = ProcessInfo.processInfo.environment
            environment.forEach { env[$0.key] = $0.value }
            process.environment = env
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw EaseMirrorError.processFailed(output.isEmpty ? "Command failed (\(process.terminationStatus))" : output)
        }

        return CommandResult(exitCode: process.terminationStatus, output: output)
    }

    public static func ensureGhostCloudOnMac() throws -> CommandResult {
        let finish = benStudioRoot.appendingPathComponent("scripts/ghostcloud-remote/finish-setup.sh")
        if FileManager.default.isExecutableFile(atPath: finish.path) {
            return try run(executable: "/bin/bash", arguments: [finish.path])
        }
        return try runScript("ghost-setup-mac.sh")
    }

    public static func wireShareFolderForGuest() throws {
        try VMPaths.ensureLayout()
        let share = VMPaths.shareRoot
        let scripts = scriptsRoot()
        let fm = FileManager.default

        for name in ["wire-ghost-home.sh", "ghost-setup-mac.sh", "download-ubuntu-iso.sh", "ease-mirror-clipboard-guest.sh", "RUN-CLIPBOARD-IN-LINUX.sh"] {
            let src = scripts.appendingPathComponent(name)
            let dst = share.appendingPathComponent(name)
            if fm.fileExists(atPath: src.path) {
                if fm.fileExists(atPath: dst.path) { try fm.removeItem(at: dst) }
                try fm.copyItem(at: src, to: dst)
                try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dst.path)
            }
        }

        let readme = """
        Ease Mirror shared folder
        =========================
        CLIPBOARD (type once inside Linux VM):

          sudo bash RUN-CLIPBOARD-IN-LINUX.sh

        Ghost Home:

          bash wire-ghost-home.sh
        """
        try readme.write(to: share.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)
    }

    public static func isoExists() -> Bool {
        FileManager.default.fileExists(atPath: VMPaths.defaultUbuntuISO.path)
    }

    public static func downloadISO(completion: @escaping @Sendable (Result<URL, Error>) -> Void) -> URLSessionDownloadTask {
        URLSession.shared.downloadTask(with: VMPaths.ubuntuISOURL) { tempURL, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let tempURL else {
                completion(.failure(EaseMirrorError.processFailed("Download failed")))
                return
            }
            completion(.success(tempURL))
        }
    }
}
