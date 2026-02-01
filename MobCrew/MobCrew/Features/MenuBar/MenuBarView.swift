import SwiftUI

struct MenuBarView: View {
    let driverName: String?
    let navigatorName: String?
    let isRunning: Bool
    let onToggle: () -> Void
    let onSkip: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                RoleRow(role: "Driver", name: driverName)
                RoleRow(role: "Navigator", name: navigatorName)
            }
            
            Divider()
            
            HStack(spacing: 8) {
                Button(action: onToggle) {
                    Label(
                        isRunning ? "Stop" : "Start",
                        systemImage: isRunning ? "stop.fill" : "play.fill"
                    )
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Button(action: onSkip) {
                    Label("Skip", systemImage: "forward.fill")
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)
            }
            
            Divider()
            
            Button(action: onOpenSettings) {
                Label("Settings…", systemImage: "gear")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        .padding(8)
    }
}

private struct RoleRow: View {
    let role: String
    let name: String?
    
    var body: some View {
        HStack {
            Text(role + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            Text(name ?? "—")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    MenuBarView(
        driverName: "Alice",
        navigatorName: "Bob",
        isRunning: false,
        onToggle: {},
        onSkip: {},
        onOpenSettings: {}
    )
    .frame(width: 200)
}
