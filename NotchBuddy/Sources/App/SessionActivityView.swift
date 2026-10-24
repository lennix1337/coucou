import SwiftUI

@MainActor
final class SessionActivity: ObservableObject {
    static let shared = SessionActivity()
    @Published var awareness = SessionAwareness()
}

struct SessionActivityView: View {
    @ObservedObject private var activity = SessionActivity.shared
    var pill: String? = nil

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            let entries = activity.awareness.entries.values.filter {
                pill == nil ? ($0.pill == "agent_pi" || $0.pill.hasPrefix("agent_pi-acp-") || $0.parent != nil)
                    && ($0.parent.map { activity.awareness.entries[$0] == nil } ?? true) : $0.pill == pill
            }.sorted { $0.receivedAt > $1.receivedAt }
            VStack(alignment: .leading, spacing: 4) {
                if entries.isEmpty {
                    Text("No runtime event received yet. Configured does not mean connected.")
                }
                ForEach(Array(entries.prefix(4)), id: \.id) { entry in
                    let children = activity.awareness.workers(of: entry.id)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.model ?? "Model unknown") · \(entry.phase.rawValue)")
                        Text("\(entry.lastEvent) · \(entry.receivedAt.formatted(date: .omitted, time: .standard)) · #\(entry.id.suffix(6))")
                        if context.date.timeIntervalSince(entry.receivedAt) > 120 {
                            Text("No recent signal — activity unknown, not necessarily stalled")
                        }
                        if !children.isEmpty {
                            Text("\(children.filter { $0.phase == .working }.count) agents working · \(children.filter { [.permission, .question, .failed, .interrupted].contains($0.phase) }.count) need attention")
                            ForEach(children.prefix(6), id: \.id) { child in
                                Text("↳ #\(child.id.suffix(6)) · \(child.phase.rawValue)")
                            }
                        }
                    }
                }
            }
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
        }
    }
}
