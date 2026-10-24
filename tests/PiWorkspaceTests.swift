import Foundation

// Minimal dependencies for compiling the real catalog outside the application.
enum AgentSource { case claudeCode, agent, n8n }
enum ChatProvider { case anthropic, google, openai, ollama, lmstudio
    var accentHex: String { "#000000" }
}
enum PillColors {
    static let stored: [String: String] = [:]
    static func color(for id: String, catalogColor: String, in colors: [String: String]) -> String {
        colors[id] ?? catalogColor
    }
}

@main
struct PiWorkspaceTests {
    static func main() {
        #if APPSTORE
        precondition(PillCatalog.defaultMainPillId == "integration_claude")
        precondition(!PillCatalog.available.contains { $0.id == "agent_pi" })
        #else
        precondition(PillCatalog.defaultMainPillId == "agent_pi")
        let pi = PillCatalog.available.first { $0.id == "agent_pi" }!
        precondition(pi.category == .workspace)
        precondition(pi.name == "Pi" && pi.sessionSubtitle == "Pi")
        #endif
        precondition(Set(PillCatalog.all.map(\.id)).count == PillCatalog.all.count)
        precondition(PillCatalog.available.contains { $0.id == PillCatalog.defaultMainPillId })
        print("Pi workspace catalog checks passed")
    }
}
