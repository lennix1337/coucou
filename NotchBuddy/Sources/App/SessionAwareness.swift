import Foundation

/// Metadata only. A foreground application is never proof of which terminal tab is visible.
struct SessionAwareness {
    enum Phase: String {
        case idle = "Connected", working = "Working", response = "Response finished"
        case question = "Needs your response", permission = "Awaiting permission"
        case failed = "Failed", interrupted = "Interrupted", ended = "Session ended"
    }
    struct Entry {
        var id: String
        var pill: String
        var parent: String?
        var model: String?
        var phase: Phase
        var lastEvent: String
        var receivedAt: Date
        var generation: Int
    }
    private(set) var entries: [String: Entry] = [:]
    private(set) var acknowledgedSession: String?
    private(set) var acknowledgedAt: Date?
    private var completions: [String: String] = [:]
    private var latest: [String: String] = [:]

    mutating func record(event: String, session: String, pill: String, parent: String?, model: String?, now: Date = Date()) {
        guard !session.isEmpty, session != "unknown", session.count <= 512,
              session.unicodeScalars.allSatisfy({
                  CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.:+/-").contains($0)
              }) else { return }
        latest[pill] = session
        let previous = entries[session]
        let phase: Phase
        switch event {
        case "UserPromptSubmit", "PreToolUse", "PostToolUse", "PostToolUseFailure": phase = .working
        case "Stop": phase = .response
        case "StopFailure": phase = .failed
        case "Interrupt": phase = .interrupted
        case "SessionEnd": phase = .ended
        case "SessionStart": phase = .idle
        case "PermissionRequest": phase = .permission
        case "Question": phase = .question
        default: phase = previous?.phase ?? .idle
        }
        if event == "UserPromptSubmit" {
            acknowledgedSession = session
            acknowledgedAt = now
            if completions[pill] == session { completions.removeValue(forKey: pill) }
        }
        entries[session] = Entry(id: session, pill: pill, parent: parent ?? previous?.parent,
                                 model: model ?? previous?.model, phase: phase, lastEvent: event,
                                 receivedAt: now, generation: (previous?.generation ?? 0) + 1)
        // Bound historical metadata, preserving active sessions where possible.
        if entries.count > 256, let oldest = entries.values.filter({ $0.id != session }).min(by: { $0.receivedAt < $1.receivedAt }) {
            entries.removeValue(forKey: oldest.id)
            if completions[oldest.pill] == oldest.id { completions.removeValue(forKey: oldest.pill) }
            if latest[oldest.pill] == oldest.id { latest.removeValue(forKey: oldest.pill) }
        }
    }

    func resumesCompletion(session: String) -> Bool {
        guard let entry = entries[session] else { return false }
        return completions[entry.pill] == session
    }

    mutating func presentCompletion(session: String) {
        guard let entry = entries[session] else { return }
        completions[entry.pill] = session
    }

    func completionIsCurrent(session: String, generation: Int) -> Bool {
        guard let entry = entries[session] else { return false }
        return latest[entry.pill] == session && entry.generation == generation && entry.phase == .response
    }

    /// Only a recent prompt in this exact session plus its foreground host permits quiet completion.
    func quietCompletion(session: String, hostInFront: Bool, now: Date = Date()) -> Bool {
        guard hostInFront, acknowledgedSession == session, let date = acknowledgedAt else { return false }
        return now.timeIntervalSince(date) >= 0 && now.timeIntervalSince(date) < 120
    }

    func children(of session: String) -> [Entry] {
        entries.values.filter { $0.parent == session && $0.phase != .ended }.sorted { $0.id < $1.id }
    }

    /// Run containers do not count as extra workers. Cycles or missing parents never loop.
    func workers(of session: String) -> [Entry] {
        var visited: Set<String> = [session]
        var pending = children(of: session)
        var result: [Entry] = []
        while let entry = pending.popLast() {
            guard visited.insert(entry.id).inserted else { continue }
            let nested = children(of: entry.id)
            if nested.isEmpty { result.append(entry) } else { pending.append(contentsOf: nested) }
        }
        return result.sorted { $0.id < $1.id }
    }
}
