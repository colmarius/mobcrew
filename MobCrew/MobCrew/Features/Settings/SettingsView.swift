import SwiftUI
import ServiceManagement
import UserNotifications

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
        .frame(width: 500, height: 390)
    }
}

private struct GeneralSettingsTab: View {
    @Bindable var appState: AppState
    @ObservedObject private var launchAtLogin = LaunchAtLoginService.shared
    @ObservedObject private var notificationService = NotificationService.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Form {
            Section("App") {
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { launchAtLogin.isRegistrationRequested },
                        set: { launchAtLogin.setEnabled($0) }
                    )
                )
                .disabled(launchAtLogin.status == .notFound)

                HStack {
                    Label(launchAtLoginStatusText, systemImage: launchAtLoginStatusIcon)
                        .foregroundStyle(launchAtLoginStatusColor)
                    Spacer()
                    if shouldShowLoginItemsSettings {
                        Button("Open Login Items") {
                            launchAtLogin.openSystemSettings()
                        }
                    }
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
                Toggle("Show notifications", isOn: Binding(
                    get: { appState.notificationsEnabled },
                    set: { appState.notificationsEnabled = $0 }
                ))

                HStack {
                    Label(notificationStatusText, systemImage: notificationStatusIcon)
                        .foregroundStyle(notificationStatusColor)
                    Spacer()
                    if notificationService.authorizationStatus == .denied {
                        Button("Open Settings") {
                            notificationService.openSystemSettings()
                        }
                    }
                }

                Toggle("Show Tips", isOn: Binding(
                    get: { appState.showTips },
                    set: { appState.showTips = $0 }
                ))
            }
        }
        .formStyle(.grouped)
        .onAppear {
            refreshSystemStatuses()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshSystemStatuses()
            }
        }
        .alert(
            "Couldn’t Update Launch at Login",
            isPresented: Binding(
                get: { launchAtLogin.operationError != nil },
                set: { if !$0 { launchAtLogin.dismissOperationError() } }
            )
        ) {
            Button("OK", role: .cancel) {
                launchAtLogin.dismissOperationError()
            }
        } message: {
            Text(launchAtLogin.operationError ?? "Unknown error")
        }
        .alert(
            "Couldn’t Request Notification Permission",
            isPresented: Binding(
                get: { notificationService.operationError != nil },
                set: { if !$0 { notificationService.dismissOperationError() } }
            )
        ) {
            Button("OK", role: .cancel) {
                notificationService.dismissOperationError()
            }
        } message: {
            Text(notificationService.operationError ?? "Unknown error")
        }
    }

    private var launchAtLoginStatusText: String {
        switch launchAtLogin.status {
        case .notRegistered:
            "Not registered"
        case .enabled:
            "Enabled"
        case .requiresApproval:
            "Requires approval in System Settings"
        case .notFound:
            "Unavailable for this app"
        @unknown default:
            "Unknown status"
        }
    }

    private var launchAtLoginStatusIcon: String {
        switch launchAtLogin.status {
        case .enabled:
            "checkmark.circle.fill"
        case .requiresApproval:
            "exclamationmark.triangle.fill"
        case .notRegistered, .notFound:
            "circle"
        @unknown default:
            "questionmark.circle"
        }
    }

    private var launchAtLoginStatusColor: Color {
        switch launchAtLogin.status {
        case .enabled:
            .green
        case .requiresApproval:
            .orange
        case .notRegistered, .notFound:
            .secondary
        @unknown default:
            .secondary
        }
    }

    private var shouldShowLoginItemsSettings: Bool {
        switch launchAtLogin.status {
        case .requiresApproval, .notFound:
            true
        case .notRegistered, .enabled:
            false
        @unknown default:
            true
        }
    }

    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case nil:
            "Checking notification permission…"
        case .some(.notDetermined):
            "Not requested"
        case .some(.denied):
            "Denied in System Settings"
        case .some(.authorized):
            "Authorized"
        case .some(.provisional):
            "Provisionally authorized"
        case .some(.ephemeral):
            "Temporarily authorized"
        @unknown default:
            "Unknown authorization status"
        }
    }

    private var notificationStatusIcon: String {
        switch notificationService.authorizationStatus {
        case .some(.authorized), .some(.provisional), .some(.ephemeral):
            "checkmark.circle.fill"
        case .some(.denied):
            "xmark.circle.fill"
        case nil, .some(.notDetermined):
            "circle"
        @unknown default:
            "questionmark.circle"
        }
    }

    private var notificationStatusColor: Color {
        switch notificationService.authorizationStatus {
        case .some(.authorized), .some(.provisional), .some(.ephemeral):
            .green
        case .some(.denied):
            .red
        case nil, .some(.notDetermined):
            .secondary
        @unknown default:
            .secondary
        }
    }

    private func refreshSystemStatuses() {
        launchAtLogin.refreshStatus()
        Task {
            await notificationService.refreshAuthorizationStatus()
        }
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
                ShortcutRow(shortcut: "⌘↩", description: "Start/Pause/Resume turn timer")
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
