import SwiftUI

struct MobsterRow: View {
    let mobster: Mobster
    let role: MobsterRole?
    let isActive: Bool
    let onRemove: () -> Void
    let onToggleActive: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    init(
        mobster: Mobster,
        role: MobsterRole?,
        isActive: Bool,
        onRemove: @escaping () -> Void,
        onToggleActive: @escaping () -> Void,
        onMoveUp: (() -> Void)? = nil,
        onMoveDown: (() -> Void)? = nil
    ) {
        self.mobster = mobster
        self.role = role
        self.isActive = isActive
        self.onRemove = onRemove
        self.onToggleActive = onToggleActive
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
    }

    var body: some View {
        HStack {
            if let role {
                RoleIndicator(role: role)
            } else {
                Color.clear
                    .frame(width: 64, height: 20)
                    .accessibilityHidden(true)
            }

            Text(mobster.name)
                .fontWeight(role != nil ? .semibold : .regular)
                .lineLimit(1)
                .accessibilityLabel(participantAccessibilityLabel)
                .accessibilityActions {
                    if let onMoveUp {
                        Button("Move \(mobster.name) up", action: onMoveUp)
                    }
                    if let onMoveDown {
                        Button("Move \(mobster.name) down", action: onMoveDown)
                    }
                }

            Spacer()

            if isActive {
                Button(action: { onMoveUp?() }) {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.borderless)
                .disabled(onMoveUp == nil)
                .help("Move \(mobster.name) up")
                .accessibilityLabel("Move \(mobster.name) up")
                .accessibilityHint("Moves this participant one place earlier while preserving the current Driver.")

                Button(action: { onMoveDown?() }) {
                    Image(systemName: "arrow.down")
                }
                .buttonStyle(.borderless)
                .disabled(onMoveDown == nil)
                .help("Move \(mobster.name) down")
                .accessibilityLabel("Move \(mobster.name) down")
                .accessibilityHint("Moves this participant one place later while preserving the current Driver.")
            }

            Button(action: onToggleActive) {
                Image(systemName: isActive ? "person.badge.minus" : "person.badge.plus")
                    .foregroundStyle(isActive ? .orange : .green)
            }
            .buttonStyle(.borderless)
            .help(isActive ? "Move \(mobster.name) to bench" : "Return \(mobster.name) to active rotation")
            .accessibilityLabel(isActive ? "Bench \(mobster.name)" : "Activate \(mobster.name)")
            .accessibilityHint(
                isActive
                    ? "Removes this participant from the active rotation without deleting them."
                    : "Returns this participant to the active rotation."
            )

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("Remove \(mobster.name) permanently")
            .accessibilityLabel("Remove \(mobster.name) permanently")
            .accessibilityHint("Deletes this participant from the roster.")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(role != nil ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }

    private var participantAccessibilityLabel: String {
        if let role {
            return "\(mobster.name), \(role.label)"
        }
        return "\(mobster.name), \(isActive ? "active participant" : "benched participant")"
    }
}

private struct RoleIndicator: View {
    let role: MobsterRole

    var body: some View {
        Text(role.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .frame(width: 64, height: 20)
            .background(Capsule().fill(role.color))
            .accessibilityHidden(true)
    }
}

private extension MobsterRole {
    var label: String {
        self == .driver ? "Driver" : "Navigator"
    }

    var color: Color {
        self == .driver ? .blue : .green
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
