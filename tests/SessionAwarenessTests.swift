import Foundation

@main
struct SessionAwarenessTests {
    static func main() {
        var state = SessionAwareness()
        let now = Date(timeIntervalSince1970: 1_000)
        func record(_ event: String, _ id: String = "pi:one", _ pill: String = "agent_pi", parent: String? = nil, at: Date = now) {
            state.record(event: event, session: id, pill: pill, parent: parent, model: nil, now: at)
        }
        record("UserPromptSubmit")
        precondition(state.quietCompletion(session: "pi:one", hostInFront: true, now: now))
        precondition(!state.quietCompletion(session: "pi:two", hostInFront: true, now: now))
        precondition(!state.quietCompletion(session: "pi:one", hostInFront: false, now: now))
        precondition(!state.quietCompletion(session: "pi:one", hostInFront: true, now: now.addingTimeInterval(121)))
        record("Stop")
        state.presentCompletion(session: "pi:one")
        let generation = state.entries["pi:one"]!.generation
        precondition(state.resumesCompletion(session: "pi:one"))
        precondition(!state.resumesCompletion(session: "pi:two"))
        precondition(state.completionIsCurrent(session: "pi:one", generation: generation))
        record("UserPromptSubmit")
        precondition(!state.resumesCompletion(session: "pi:one"))
        precondition(!state.completionIsCurrent(session: "pi:one", generation: generation))
        record("Stop")
        let stopped = state.entries["pi:one"]!.generation
        record("StopFailure")
        precondition(!state.completionIsCurrent(session: "pi:one", generation: stopped))
        precondition(state.entries["pi:one"]?.phase == .failed)
        record("Stop")
        let beforeSibling = state.entries["pi:one"]!.generation
        record("StopFailure", "pi:sibling")
        precondition(!state.completionIsCurrent(session: "pi:one", generation: beforeSibling))
        record("Interrupt")
        precondition(state.entries["pi:one"]?.phase == .interrupted)
        record("PermissionRequest")
        precondition(state.entries["pi:one"]?.phase == .permission)
        record("Question")
        precondition(state.entries["pi:one"]?.phase == .question)
        record("UserPromptSubmit", "child", "agent_pi-child-abc", parent: "pi:one")
        record("Stop", "pi:one")
        precondition(state.children(of: "pi:one").first?.phase == .working)
        record("UserPromptSubmit", "grandchild", "agent_pi-child-def", parent: "child")
        precondition(state.workers(of: "pi:one").map(\.id) == ["grandchild"])
        record("SessionEnd", "grandchild", "agent_pi-child-def")
        record("StopFailure", "child", "agent_pi-child-abc")
        precondition(state.children(of: "pi:one").first?.phase == .failed)
        record("SessionEnd", "child", "agent_pi-child-abc")
        precondition(state.children(of: "pi:one").isEmpty)
        record("UserPromptSubmit", "unknown")
        precondition(state.entries["unknown"] == nil)
        record("SessionStart", "invalid\nidentifier")
        record("SessionStart", String(repeating: "x", count: 513))
        precondition(state.entries["invalid\nidentifier"] == nil)
        precondition(state.entries[String(repeating: "x", count: 513)] == nil)
        // Another pill cannot acknowledge a sibling's pending completion.
        state.presentCompletion(session: "pi:one")
        record("Stop", "other", "agent_other")
        state.presentCompletion(session: "other")
        record("UserPromptSubmit", "other", "agent_other")
        precondition(state.resumesCompletion(session: "pi:one"))
        for index in 0..<300 { record("SessionStart", "s\(index)", at: now.addingTimeInterval(Double(index))) }
        precondition(state.entries.count == 256)
        print("Session awareness: identity, attention, acknowledgement, stale timers, errors, children and bounded health checks passed")
    }
}
