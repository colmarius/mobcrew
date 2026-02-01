import SwiftUI

struct MobsterRow: View {
    let mobster: Mobster
    let role: MobsterRole?
    let isActive: Bool
    let onRemove: () -> Void
    let onToggleActive: () -> Void
    
    var body: some View {
        HStack {
            if let role {
                RoleIndicator(role: role)
            }
            
            Text(mobster.name)
                .fontWeight(role != nil ? .semibold : .regular)
            
            Spacer()
            
            Button(action: onToggleActive) {
                Image(systemName: isActive ? "arrow.down.circle" : "arrow.up.circle")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.borderless)
            .help(isActive ? "Bench" : "Activate")
            
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("Remove")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(role != nil ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

private struct RoleIndicator: View {
    let role: MobsterRole
    
    var body: some View {
        Text(role == .driver ? "D" : "N")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(Circle().fill(role == .driver ? .green : .blue))
    }
}

#Preview {
    VStack {
        MobsterRow(
            mobster: Mobster(name: "Alice"),
            role: .driver,
            isActive: true,
            onRemove: {},
            onToggleActive: {}
        )
        MobsterRow(
            mobster: Mobster(name: "Bob"),
            role: .navigator,
            isActive: true,
            onRemove: {},
            onToggleActive: {}
        )
        MobsterRow(
            mobster: Mobster(name: "Charlie"),
            role: nil,
            isActive: true,
            onRemove: {},
            onToggleActive: {}
        )
        MobsterRow(
            mobster: Mobster(name: "Dave"),
            role: nil,
            isActive: false,
            onRemove: {},
            onToggleActive: {}
        )
    }
    .padding()
    .frame(width: 250)
}
