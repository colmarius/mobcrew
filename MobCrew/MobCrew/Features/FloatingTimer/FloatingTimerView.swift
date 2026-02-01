import SwiftUI

struct FloatingTimerView: View {
    let appState: AppState
    
    var body: some View {
        VStack(spacing: 8) {
            if appState.isOnBreak {
                FloatingBreakView(appState: appState)
            } else {
                FloatingNormalView(appState: appState)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(appState.isOnBreak 
                    ? LinearGradient(
                        colors: [Color.teal.opacity(0.9), Color.blue.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.black.opacity(0.85), Color.black.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

private struct FloatingNormalView: View {
    let appState: AppState
    
    var body: some View {
        Text(appState.timerState.displayTime)
            .font(.system(size: 36, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
        
        VStack(spacing: 6) {
            RoleLabel(role: "Driver", name: appState.roster.driver?.name, isDriver: true)
            RoleLabel(role: "Navigator", name: appState.roster.navigator?.name, isDriver: false)
        }
        
        BreakProgressView(
            breakInterval: appState.breakInterval,
            turnsSinceBreak: appState.turnsSinceBreak
        )
        
        Button(action: { appState.toggleTimer() }) {
            Image(systemName: appState.timerState.isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(appState.timerState.isRunning ? Color.orange : Color.green)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct FloatingBreakView: View {
    let appState: AppState
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 14, weight: .semibold))
            Text("Break")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.white)
        
        Text(appState.timerState.displayTime)
            .font(.system(size: 36, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
        
        Button(action: { appState.skipBreak() }) {
            Text("Skip")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct RoleLabel: View {
    let role: String
    let name: String?
    let isDriver: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(role)
                .font(.system(size: isDriver ? 11 : 10, weight: .semibold))
                .foregroundStyle(isDriver ? .green : .blue)
                .frame(width: 60, alignment: .trailing)
            
            Text(name ?? "—")
                .font(.system(size: isDriver ? 14 : 12, weight: isDriver ? .bold : .medium))
                .foregroundStyle(.white.opacity(isDriver ? 1.0 : 0.7))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("Normal State") {
    FloatingTimerView(appState: AppState())
        .padding()
        .background(Color.gray)
}

#Preview("Break State") {
    FloatingTimerView(appState: {
        let state = AppState()
        state.isOnBreak = true
        return state
    }())
    .padding()
    .background(Color.gray)
}
