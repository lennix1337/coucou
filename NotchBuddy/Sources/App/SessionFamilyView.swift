import SwiftUI

/// Compact parent/child summary. Each child remains independently addressable in the pill picker.
struct SessionFamilyView: View {
    var pill: String
    @ObservedObject private var activity = SessionActivity.shared
    var body: some View {
        let roots = activity.awareness.entries.values.filter { $0.pill == pill }
        let children = roots.flatMap { activity.awareness.workers(of: $0.id) }
        if !children.isEmpty {
            Text("\(children.filter { $0.phase == .working }.count) working · \(children.filter { [.question, .permission, .failed, .interrupted].contains($0.phase) }.count) need you")
                .font(.system(size: 10)).foregroundStyle(.secondary)
                .help(children.map { "#\($0.id.suffix(6)): \($0.phase.rawValue)" }.joined(separator: "\n"))
        }
    }
}
