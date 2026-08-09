import SwiftUI

struct MenuBarView: View {
    let appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                RoleRow(role: "Driver", name: appState.roster.driver?.name)
                RoleRow(role: "Navigator", name: appState.roster.navigator?.name)
            }
            
            Divider()
            
            HStack(spacing: 8) {
                Button(action: { appState.performPrimaryAction() }) {
                    Label(
                        appState.primaryActionLabel,
                        systemImage: appState.primaryActionSystemImage
                    )
                }
                .disabled(!appState.canPerformPrimaryAction)
                .keyboardShortcut(.space, modifiers: [])
                
                Button(action: { appState.performSkipAction() }) {
                    Label(appState.skipActionLabel, systemImage: "forward.fill")
                }
                .disabled(!appState.canPerformSkipAction)
                .keyboardShortcut(.rightArrow, modifiers: .command)
            }
            
            Divider()
            
            SettingsLink {
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
    MenuBarView(appState: AppState())
    .frame(width: 200)
}
