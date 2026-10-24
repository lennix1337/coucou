import Foundation

@main
struct AgentIdentityTests {
    static func main() {
        assert(AgentIdentity.displayName(agent: "pi", model: "openai/gpt-codex") == "Pi · openai/gpt-codex")
        assert(AgentIdentity.displayName(agent: "pi", model: "anthropic/claude-test") == "Pi · anthropic/claude-test")
        assert(AgentIdentity.displayName(agent: "pi", model: nil) == "Pi")
        assert(AgentIdentity.displayName(agent: "pi", model: "") == "Pi")
        assert(AgentIdentity.displayName(agent: "pi", model: "bad\nmodel") == "Pi")
        assert(AgentIdentity.displayName(agent: "pi", model: String(repeating: "x", count: 161)) == "Pi")
        assert(AgentIdentity.displayName(agent: "opencode", model: "openai/gpt-codex") == "opencode")
        print("Agent identity tests passed")
    }
}
