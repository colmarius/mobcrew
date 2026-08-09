import SwiftUI

struct BreakScreenView: View {
    let appState: AppState
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.teal.opacity(0.3), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Text(appState.sessionPhase == .breakDue ? "Break Due" : "Break Time!")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(formatTime(appState.timerState.secondsRemaining))
                    .font(.system(.largeTitle, design: .monospaced, weight: .light))
                    .foregroundStyle(.primary)
                    .accessibilityLabel(appState.timerAccessibilityLabel)
                    .accessibilityValue(appState.timerAccessibilityValue)
                    .accessibilityHint(appState.timerAccessibilityHint)
                
                ProgressView(value: appState.timerState.progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 300)
                    .tint(.teal)
                    .accessibilityHidden(true)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { appState.performPrimaryAction() }) {
                        Text(appState.primaryActionLabel)
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!appState.canPerformPrimaryAction)
                    .help(appState.primaryActionLabel)
                    .accessibilityLabel(appState.primaryActionAccessibilityLabel)
                    .accessibilityHint(appState.primaryActionAccessibilityHint)

                    Button(action: { appState.performSkipAction() }) {
                        Text(appState.skipActionLabel)
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!appState.canPerformSkipAction)
                    .help(appState.skipActionLabel)
                    .accessibilityLabel(appState.skipActionAccessibilityLabel)
                    .accessibilityHint(appState.skipActionAccessibilityHint)
                    .keyboardShortcut(.escape, modifiers: [])
                }
                
                Spacer()
                    .frame(height: 40)
            }
            .padding()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    BreakScreenView(appState: AppState.previewing(.breakDue))
    .frame(width: 500, height: 400)
}
