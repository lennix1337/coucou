import Foundation

/// Client and model are separate: a Pi session is not a Claude Code session.
enum AgentIdentity {
    static func displayName(agent: String, model: String?) -> String {
        let client = agent == "pi" ? "Pi" : agent
        guard agent == "pi", let model, !model.isEmpty, model.count <= 160,
              model.unicodeScalars.allSatisfy({
                  CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_./:@+ -").contains($0)
              }) else { return client }
        return "\(client) · \(model)"
    }
}
