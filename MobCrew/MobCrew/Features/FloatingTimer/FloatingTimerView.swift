import SwiftUI

struct FloatingTimerView: View {
    let displayTime: String
    let driverName: String?
    let navigatorName: String?
    let isRunning: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text(displayTime)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            HStack(spacing: 12) {
                RoleLabel(role: "D", name: driverName)
                RoleLabel(role: "N", name: navigatorName)
            }
            
            Button(action: onToggle) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(isRunning ? Color.orange : Color.green)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
        )
    }
}

private struct RoleLabel: View {
    let role: String
    let name: String?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(role)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 16, height: 16)
                .background(Circle().fill(.white))
            
            Text(name ?? "—")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
    }
}

#Preview {
    FloatingTimerView(
        displayTime: "05:00",
        driverName: "Alice",
        navigatorName: "Bob",
        isRunning: false,
        onToggle: {}
    )
    .padding()
    .background(Color.gray)
}
