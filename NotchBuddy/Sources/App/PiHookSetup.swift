import Foundation

/// Checks configuration on disk, not whether an already-running Pi loaded it.
struct PiHookSetup {
    let home: URL
    init(home: URL = FileManager.default.homeDirectoryForCurrentUser) { self.home = home }
    private var agent: URL { home.appendingPathComponent(".pi/agent") }
    private var settings: URL { agent.appendingPathComponent("settings.json") }
    private var hook: URL { agent.appendingPathComponent("acp/hooks/pi-coucou.mjs") }

    struct Status {
        let extensionConfigured: Bool
        let acpConfigured: Bool
        let detail: String
        var configured: Bool { extensionConfigured && acpConfigured }
    }

    private func configuration() throws -> [String: Any] {
        guard FileManager.default.fileExists(atPath: settings.path) else { return [:] }
        guard let value = try JSONSerialization.jsonObject(with: Data(contentsOf: settings)) as? [String: Any] else {
            throw SetupError.invalidSettings
        }
        for key in ["packages", "extensions"] where value[key] != nil && !(value[key] is [Any]) {
            throw SetupError.invalidSettings
        }
        return value
    }

    private func resolve(_ path: String) -> URL {
        let expanded = (path as NSString).expandingTildeInPath
        return URL(fileURLWithPath: expanded, relativeTo: URL(fileURLWithPath: agent.path, isDirectory: true)).standardizedFileURL
    }

    private func validPackage(_ source: URL) -> Bool {
        guard let data = try? Data(contentsOf: source.appendingPathComponent("package.json")),
              let package = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              package["name"] as? String == "pi-coucou" else { return false }
        return ["pi/coucou.ts", "acp/coucou.mjs"].allSatisfy {
            FileManager.default.fileExists(atPath: source.appendingPathComponent($0).path)
        }
    }

    private func sources(_ config: [String: Any]) -> [URL] {
        // Filtered package objects are not assumed enabled; installing adds an explicit extension.
        let packages = (config["packages"] as? [Any] ?? []).compactMap { $0 as? String }.map(resolve).filter(validPackage)
        let extensions = (config["extensions"] as? [Any] ?? []).compactMap { $0 as? String }.compactMap { path -> URL? in
            let file = resolve(path)
            let root = file.deletingLastPathComponent().deletingLastPathComponent()
            return file.lastPathComponent == "coucou.ts" && validPackage(root) ? root : nil
        }
        return packages + extensions
    }

    func status() -> Status {
        do {
            let roots = sources(try configuration())
            let linked = try? FileManager.default.destinationOfSymbolicLink(atPath: hook.path)
            let target = linked.map { URL(fileURLWithPath: $0, relativeTo: hook.deletingLastPathComponent()).standardizedFileURL }
            let acp = roots.contains { $0.appendingPathComponent("acp/coucou.mjs").standardizedFileURL == target }
            return Status(extensionConfigured: !roots.isEmpty, acpConfigured: acp,
                          detail: roots.isEmpty ? "Pi extension not configured" : (acp ? "Extension and ACP hook configured" : "Pi extension configured; ACP hook missing or mismatched"))
        } catch {
            return Status(extensionConfigured: false, acpConfigured: false, detail: "Cannot read Pi settings: \(error.localizedDescription)")
        }
    }

    /// Explicit user action only. Preserve other settings and refuse foreign hooks.
    func install(source: URL) throws {
        let source = source.standardizedFileURL
        guard validPackage(source) else { throw SetupError.invalidPackage }
        var config = try configuration()
        let fm = FileManager.default
        let expected = source.appendingPathComponent("acp/coucou.mjs").path
        var createdHook = false
        if (try? fm.attributesOfItem(atPath: hook.path)) != nil {
            guard let link = try? fm.destinationOfSymbolicLink(atPath: hook.path),
                  URL(fileURLWithPath: link, relativeTo: hook.deletingLastPathComponent()).standardizedFileURL.path == expected else {
                throw SetupError.foreignHook
            }
        } else {
            try fm.createDirectory(at: hook.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fm.createSymbolicLink(atPath: hook.path, withDestinationPath: expected)
            createdHook = true
        }
        do {
            // An already-registered extension needs no settings rewrite, even during ACP repair.
            if sources(config).contains(source) { return }
            var extensions = config["extensions"] as? [Any] ?? []
            extensions.append(source.appendingPathComponent("pi/coucou.ts").path)
            config["extensions"] = extensions
            let data = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
            try data.write(to: settings, options: .atomic)
        } catch {
            if createdHook { try fm.removeItem(at: hook) }
            throw error
        }
    }

    enum SetupError: LocalizedError {
        case invalidSettings, invalidPackage, foreignHook
        var errorDescription: String? {
            switch self {
            case .invalidSettings: return "Pi settings must be a JSON object with packages/extensions arrays. No changes made."
            case .invalidPackage: return "Select a pi-coucou package containing pi/coucou.ts and acp/coucou.mjs."
            case .foreignHook: return "Existing ACP hook belongs to another source. Review it manually; it was not replaced."
            }
        }
    }
}
