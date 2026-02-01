import SwiftUI

struct BreakSettingsView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        Form {
            Section("Break Settings") {
                Stepper(value: Binding(
                    get: { appState.breakInterval },
                    set: { appState.breakInterval = $0 }
                ), in: 1...10) {
                    HStack {
                        Text("Break after")
                        Spacer()
                        Text("\(appState.breakInterval) turns")
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
        .frame(minWidth: 300, minHeight: 150)
    }
}

#Preview {
    BreakSettingsView(appState: AppState())
}
