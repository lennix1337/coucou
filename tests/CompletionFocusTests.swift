import Foundation

@main
struct CompletionFocusTests {
    static func main() {
        let ghostty = "com.mitchellh.ghostty"
        var focus = SessionAwareness()
        focus.record(event: "Stop", session: "pi:focus", pill: "agent_pi", parent: nil, model: nil)
        focus.presentCompletion(session: "pi:focus")
        precondition(!focus.acknowledgeCompletion(session: "pi:focus", activatedHost: nil, completionHost: ghostty))
        precondition(!focus.acknowledgeCompletion(session: "pi:focus", activatedHost: ghostty, completionHost: nil))
        precondition(!focus.acknowledgeCompletion(session: "pi:focus", activatedHost: "com.apple.Safari", completionHost: ghostty))
        precondition(focus.acknowledgeCompletion(session: "pi:focus", activatedHost: ghostty, completionHost: ghostty))
        precondition(!focus.resumesCompletion(session: "pi:focus"))
        precondition(!focus.acknowledgeCompletion(session: "pi:focus", activatedHost: ghostty, completionHost: ghostty))
        // Errors, questions, approvals, resumed work and ended sessions must not be acknowledged.
        for event in ["StopFailure", "Interrupt", "PermissionRequest", "Question", "UserPromptSubmit", "SessionEnd"] {
            focus.record(event: "Stop", session: "pi:focus", pill: "agent_pi", parent: nil, model: nil)
            focus.presentCompletion(session: "pi:focus")
            focus.record(event: event, session: "pi:focus", pill: "agent_pi", parent: nil, model: nil)
            precondition(!focus.acknowledgeCompletion(session: "pi:focus", activatedHost: ghostty, completionHost: ghostty))
        }
        // A sibling event invalidates the old card even if it belongs to the same host app.
        focus.record(event: "Stop", session: "pi:focus", pill: "agent_pi", parent: nil, model: nil)
        focus.presentCompletion(session: "pi:focus")
        focus.record(event: "UserPromptSubmit", session: "pi:sibling", pill: "agent_pi", parent: nil, model: nil)
        precondition(!focus.acknowledgeCompletion(session: "pi:focus", activatedHost: ghostty, completionHost: ghostty))
        print("Completion focus checks passed: matching host, unknown hosts, single acknowledgement, attention states and stale sibling")
    }
}
