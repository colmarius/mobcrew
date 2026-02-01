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
                
                Text("Break Time!")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(formatTime(appState.timerState.secondsRemaining))
                    .font(.system(size: 80, weight: .light, design: .monospaced))
                    .foregroundStyle(.primary)
                
                ProgressView(value: appState.timerState.progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 300)
                    .tint(.teal)
                
                Spacer()
                
                Button(action: { appState.skipBreak() }) {
                    Text("Skip Break")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape, modifiers: [])
                
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
    BreakScreenView(appState: {
        let state = AppState()
        state.isOnBreak = true
        return state
    }())
    .frame(width: 500, height: 400)
}
