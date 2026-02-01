import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        TabView {
            GeneralSettingsTab(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            BreakSettingsTab(appState: appState)
                .tabItem {
                    Label("Breaks", systemImage: "cup.and.saucer")
                }
        }
        .frame(width: 450, height: 320)
    }
}

private struct GeneralSettingsTab: View {
    @Bindable var appState: AppState
    @State private var launchAtLogin = LaunchAtLoginService.shared.isEnabled
    
    var body: some View {
        Form {
            Section("App") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLoginService.shared.isEnabled = newValue
                    }
            }
            
            Section("Timer") {
                Stepper(value: Binding(
                    get: { appState.timerDuration / 60 },
                    set: { appState.timerDuration = $0 * 60 }
                ), in: 1...60) {
                    HStack {
                        Text("Turn duration")
                        Spacer()
                        Text("\(appState.timerDuration / 60) min")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                
                Toggle("Notifications", isOn: Binding(
                    get: { appState.notificationsEnabled },
                    set: { appState.notificationsEnabled = $0 }
                ))
                
                Toggle("Show Tips", isOn: Binding(
                    get: { appState.showTips },
                    set: { appState.showTips = $0 }
                ))
            }
            
            Section("Keyboard Shortcuts") {
                ShortcutRow(shortcut: "⌘⇧L", description: "Toggle floating timer", note: "Global")
                ShortcutRow(shortcut: "⌘↩", description: "Start/Pause timer")
                ShortcutRow(shortcut: "⌘⇧S", description: "Skip turn")
                ShortcutRow(shortcut: "⌘,", description: "Open Settings")
                ShortcutRow(shortcut: "Esc", description: "Dismiss break screen")
            }
        }
        .formStyle(.grouped)
    }
}

private struct ShortcutRow: View {
    let shortcut: String
    let description: String
    var note: String? = nil
    
    var body: some View {
        HStack {
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            Text(description)
            
            Spacer()
            
            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BreakSettingsTab: View {
    @Bindable var appState: AppState
    
    var body: some View {
        Form {
            Section("Breaks") {
                Stepper(value: Binding(
                    get: { appState.breakInterval },
                    set: { appState.breakInterval = $0 }
                ), in: 1...20) {
                    HStack {
                        Text("Break after")
                        Spacer()
                        Text(appState.breakInterval == 1 ? "1 turn" : "\(appState.breakInterval) turns")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                
                Stepper(value: Binding(
                    get: { appState.breakDuration / 60 },
                    set: { appState.breakDuration = $0 * 60 }
                ), in: 1...30) {
                    HStack {
                        Text("Break duration")
                        Spacer()
                        Text("\(appState.breakDuration / 60) min")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView(appState: AppState())
}
