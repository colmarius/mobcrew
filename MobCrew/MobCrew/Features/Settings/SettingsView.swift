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
            
            ShortcutsSettingsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
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
                    set: { appState.setTimerDuration(minutes: $0) }
                ), in: AppState.timerDurationMinutesRange) {
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
            

        }
        .formStyle(.grouped)
    }
}

private struct ShortcutsSettingsTab: View {
    @ObservedObject private var hotkeyService = GlobalHotkeyService.shared

    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                ShortcutRow(
                    shortcut: GlobalHotkeyService.shortcut.displayName,
                    description: GlobalHotkeyService.shortcut.actionDescription,
                    note: "Global"
                )
                ShortcutRow(shortcut: "⌘↩", description: "Start/Pause timer")
                ShortcutRow(shortcut: "⌘⇧S", description: "Skip turn")
                ShortcutRow(shortcut: "⌘,", description: "Open Settings")
                ShortcutRow(shortcut: "Esc", description: "Dismiss break screen")
            }

            Section("Global Shortcut Status") {
                switch hotkeyService.registrationState {
                case .notRegistered:
                    Label("Not registered", systemImage: "keyboard.badge.ellipsis")
                        .foregroundStyle(.secondary)
                case .registered:
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failed:
                    Label("Unavailable", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    if let description = hotkeyService.registrationState.failureDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Try Again") {
                        hotkeyService.retryRegistration()
                    }
                }
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
                Toggle("Enable Breaks", isOn: Binding(
                    get: { appState.breaksEnabled },
                    set: { appState.setBreaksEnabled($0) }
                ))

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
                .disabled(!appState.breaksEnabled)
                
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
                .disabled(!appState.breaksEnabled)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView(appState: AppState())
}
