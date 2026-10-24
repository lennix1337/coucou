#if !APPSTORE
import SwiftUI
import AppKit

struct PiHookSettingsView: View {
    @State private var status = PiHookSetup().status()
    @State private var message = ""

    var body: some View {
        GroupBox("Pi Agent") {
            VStack(alignment: .leading, spacing: 10) {
                Label(status.detail, systemImage: status.configured ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(status.configured ? Color.green : Color.secondary)
                Text("Checks ~/.pi/agent/settings.json and the ACP hook target. Configuration does not prove a running session has loaded the extension.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Install / Repair…", action: install)
                        .buttonStyle(.borderedProminent).accessibilityLabel("Install or repair Pi hooks")
                    Button("Refresh status") { status = PiHookSetup().status() }
                        .buttonStyle(.bordered).accessibilityLabel("Refresh Pi hook status")
                }
                Text("After installation, run /reload in Pi. Only session, model and tool metadata is relayed; permissions remain in Pi.")
                    .font(.caption).foregroundStyle(.secondary)
                SessionActivityView()
                if !message.isEmpty { Text(message).font(.caption).textSelection(.enabled) }
            }.frame(maxWidth: .infinity, alignment: .leading).padding(6)
        }.onAppear { status = PiHookSetup().status() }
    }

    private func install() {
        let panel = NSOpenPanel()
        panel.title = "Select the pi-coucou package"
        panel.message = "Install the selected package's Pi extension and ACP hook. Other settings and foreign hooks are preserved."
        panel.prompt = "Install / Repair"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("projetos/pi-coucou")
        guard panel.runModal() == .OK, let source = panel.url else { return }
        do {
            try PiHookSetup().install(source: source)
            status = PiHookSetup().status()
            message = "Configuration saved. Run /reload in Pi to activate it."
        } catch {
            status = PiHookSetup().status()
            message = error.localizedDescription
        }
    }
}
#endif
