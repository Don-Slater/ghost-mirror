import Foundation

public final class VMStore: @unchecked Sendable {
    public static let shared = VMStore()

    private let queue = DispatchQueue(label: "com.easeaudio.easemirror.vmstore")
    private var cache: [UUID: VMDefinition] = [:]

    private init() {
        try? VMPaths.ensureLayout()
        reload()
    }

    public func reload() {
        queue.sync {
            cache.removeAll()
            let fm = FileManager.default
            guard let entries = try? fm.contentsOfDirectory(at: VMPaths.vmsRoot, includingPropertiesForKeys: nil) else {
                return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            for dir in entries where dir.hasDirectoryPath {
                let config = dir.appendingPathComponent("config.json")
                guard let data = try? Data(contentsOf: config),
                      let vm = try? decoder.decode(VMDefinition.self, from: data) else {
                    continue
                }
                cache[vm.id] = vm
            }
        }
    }

    public func all() -> [VMDefinition] {
        queue.sync {
            cache.values.sorted { $0.createdAt > $1.createdAt }
        }
    }

    public func get(id: UUID) -> VMDefinition? {
        queue.sync { cache[id] }
    }

    @discardableResult
    public func create(name: String, cpuCount: Int, memoryGB: Int, diskGB: Int, isoPath: String?) throws -> VMDefinition {
        try VMPaths.ensureLayout()
        let vm = VMDefinition(name: name, cpuCount: cpuCount, memoryGB: memoryGB, diskGB: diskGB, isoPath: isoPath)
        try persist(vm)
        try createDisk(for: vm)
        queue.sync { cache[vm.id] = vm }
        return vm
    }

    public func update(_ vm: VMDefinition) throws {
        try persist(vm)
        queue.sync { cache[vm.id] = vm }
    }

    public func delete(id: UUID) throws {
        let dir = VMPaths.vmDirectory(id: id)
        try FileManager.default.removeItem(at: dir)
        _ = queue.sync { cache.removeValue(forKey: id) }
    }

    public func markInstalled(id: UUID) throws {
        guard var vm = get(id: id) else { throw EaseMirrorError.vmNotFound(id) }
        vm.installed = true
        try update(vm)
    }

    /// Clear installed flag and reset EFI so the next Start boots the Ubuntu installer from ISO.
    public func resetInstall(id: UUID) throws {
        guard var vm = get(id: id) else { throw EaseMirrorError.vmNotFound(id) }
        vm.installed = false
        try update(vm)
        _ = try VMStability.repairEFI(for: id)
    }

    private func persist(_ vm: VMDefinition) throws {
        let dir = VMPaths.vmDirectory(id: vm.id)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(vm)
        try data.write(to: VMPaths.configURL(id: vm.id), options: .atomic)
    }

    private func createDisk(for vm: VMDefinition) throws {
        let diskURL = VMPaths.diskURL(id: vm.id)
        let fm = FileManager.default
        if fm.fileExists(atPath: diskURL.path) { return }

        fm.createFile(atPath: diskURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: diskURL)
        defer { try? handle.close() }
        let size = vm.diskBytes
        try handle.truncate(atOffset: size)
    }
}
