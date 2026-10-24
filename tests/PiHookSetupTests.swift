import Foundation

@main struct PiHookSetupTests {
    static func main() throws {
        let fm = FileManager.default
        let root = URL(fileURLWithPath: "scratchpad/pi-hook-tests-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { do { try fm.removeItem(at: root) } catch { fatalError("Test cleanup failed: \(error)") } }
        let home = root.appendingPathComponent("home", isDirectory: true)
        let source = root.appendingPathComponent("pi-coucou", isDirectory: true).standardizedFileURL
        for path in ["pi", "acp"] { try fm.createDirectory(at: source.appendingPathComponent(path), withIntermediateDirectories: true) }
        try Data("{\"name\":\"pi-coucou\"}".utf8).write(to: source.appendingPathComponent("package.json"))
        for path in ["pi/coucou.ts", "acp/coucou.mjs"] { try Data("// fixture".utf8).write(to: source.appendingPathComponent(path)) }
        let setup = PiHookSetup(home: home)
        precondition(!setup.status().configured)
        try setup.install(source: source)
        precondition(setup.status().configured)
        try setup.install(source: source)
        let settings = home.appendingPathComponent(".pi/agent/settings.json")
        var config = try JSONSerialization.jsonObject(with: Data(contentsOf: settings)) as! [String: Any]
        precondition((config["extensions"] as! [String]).count == 1)
        config["unrelated"] = ["preserve": true]
        try JSONSerialization.data(withJSONObject: config).write(to: settings)
        let beforeRepair = try Data(contentsOf: settings)
        try setup.install(source: source)
        let afterRepair = try Data(contentsOf: settings)
        precondition(beforeRepair == afterRepair)
        let preserved = try JSONSerialization.jsonObject(with: afterRepair) as! [String: Any]
        precondition((preserved["unrelated"] as! [String: Bool])["preserve"] == true)
        let hook = home.appendingPathComponent(".pi/agent/acp/hooks/pi-coucou.mjs")
        try fm.removeItem(at: hook)
        precondition(setup.status().extensionConfigured && !setup.status().acpConfigured)
        try Data("foreign hook".utf8).write(to: hook)
        do { try setup.install(source: source); fatalError("Replaced foreign hook") }
        catch PiHookSetup.SetupError.foreignHook { }
        let foreign = try String(contentsOf: hook, encoding: .utf8)
        precondition(foreign == "foreign hook")
        try fm.removeItem(at: hook)
        try fm.createSymbolicLink(atPath: hook.path, withDestinationPath: "/missing/foreign-hook")
        do { try setup.install(source: source); fatalError("Replaced dangling foreign hook") }
        catch PiHookSetup.SetupError.foreignHook { }
        try fm.removeItem(at: hook)
        try Data("{malformed".utf8).write(to: settings)
        do { try setup.install(source: source); fatalError("Overwrote invalid settings") } catch { }
        precondition(!fm.fileExists(atPath: hook.path))
        precondition(!setup.status().configured)
        // Existing relative package registration is recognized without a duplicate extension.
        let relative = "../../../pi-coucou"
        try JSONSerialization.data(withJSONObject: ["packages": [relative]]).write(to: settings)
        precondition(setup.status().extensionConfigured)
        try setup.install(source: source)
        precondition(setup.status().configured)
        let relativeConfig = try JSONSerialization.jsonObject(with: Data(contentsOf: settings)) as! [String: Any]
        precondition(relativeConfig["extensions"] == nil)
        print("Pi setup checks passed: install, idempotence, partial state, preserved settings, foreign/dangling hook refusal, malformed settings, relative package")
        if CommandLine.arguments.contains("--live-status") {
            let live = PiHookSetup().status()
            print("Live Pi: \(live.detail)")
            precondition(live.configured)
        }
    }
}
