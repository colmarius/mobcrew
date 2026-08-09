import SwiftUI

struct RosterView: View {
    @Bindable var roster: Roster
    @State private var newMobsterName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            addMobsterSection
            
            if roster.activeMobsters.isEmpty && roster.inactiveMobsters.isEmpty {
                emptyStateSection
            } else {
                rosterList
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No mobsters yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add your first mobster above to get started")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private var addMobsterSection: some View {
        HStack {
            TextField("New mobster name", text: $newMobsterName)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addMobster)
            
            Button(action: addMobster) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .disabled(newMobsterName.trimmingCharacters(in: .whitespaces).isEmpty)
            .buttonStyle(.borderless)
            .help("Add participant to the active roster")
            .accessibilityLabel("Add participant")
            .accessibilityHint("Adds the entered name to the active rotation.")
        }
    }
    
    private var rosterList: some View {
        List {
            if !roster.activeMobsters.isEmpty {
                Section {
                    ForEach(Array(roster.activeMobsters.enumerated()), id: \.element.id) { index, mobster in
                        MobsterRow(
                            mobster: mobster,
                            role: role(for: index),
                            isActive: true,
                            onRemove: { removeActiveMobster(id: mobster.id) },
                            onToggleActive: { benchMobster(id: mobster.id) },
                            onMoveUp: index > 0
                                ? { moveActiveMobster(id: mobster.id, by: -1) }
                                : nil,
                            onMoveDown: index < roster.activeMobsters.count - 1
                                ? { moveActiveMobster(id: mobster.id, by: 1) }
                                : nil
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onMove { source, destination in
                        roster.moveMobster(from: source, to: destination)
                    }
                } header: {
                    HStack {
                        Text("Active")
                        Spacer()
                        Button(action: { roster.shuffle() }) {
                            Image(systemName: "shuffle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(roster.activeMobsters.count < 2)
                        .help("Shuffle roster order")
                        .accessibilityLabel("Shuffle active roster")
                        .accessibilityHint("Randomizes active participants and makes the first person Driver.")
                    }
                }
            }

            if !roster.inactiveMobsters.isEmpty {
                Section("Benched") {
                    ForEach(roster.inactiveMobsters) { mobster in
                        MobsterRow(
                            mobster: mobster,
                            role: nil,
                            isActive: false,
                            onRemove: { removeInactiveMobster(id: mobster.id) },
                            onToggleActive: { activateMobster(id: mobster.id) }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Roster")
    }
    
    private func role(for index: Int) -> MobsterRole? {
        guard !roster.activeMobsters.isEmpty else { return nil }
        let driverIndex = roster.nextDriverIndex % roster.activeMobsters.count
        if index == driverIndex {
            return .driver
        }
        if roster.activeMobsters.count >= 2 {
            let navigatorIndex = (roster.nextDriverIndex + 1) % roster.activeMobsters.count
            if index == navigatorIndex {
                return .navigator
            }
        }
        return nil
    }
    
    private func addMobster() {
        let trimmedName = newMobsterName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        roster.addMobster(name: trimmedName)
        newMobsterName = ""
    }
    
    private func moveActiveMobster(id: UUID, by offset: Int) {
        guard let source = roster.activeMobsters.firstIndex(where: { $0.id == id }) else { return }
        roster.moveActiveMobster(at: source, to: source + offset)
    }

    private func benchMobster(id: UUID) {
        guard let index = roster.activeMobsters.firstIndex(where: { $0.id == id }) else { return }
        roster.benchMobster(at: index)
    }

    private func activateMobster(id: UUID) {
        guard let index = roster.inactiveMobsters.firstIndex(where: { $0.id == id }) else { return }
        roster.rotateIn(at: index)
    }

    private func removeActiveMobster(id: UUID) {
        guard let index = roster.activeMobsters.firstIndex(where: { $0.id == id }) else { return }
        roster.removeActiveMobster(at: index)
    }

    private func removeInactiveMobster(id: UUID) {
        guard let index = roster.inactiveMobsters.firstIndex(where: { $0.id == id }) else { return }
        roster.removeInactiveMobster(at: index)
    }
}

enum MobsterRole {
    case driver
    case navigator
}

#Preview {
    let roster = Roster(
        activeMobsters: [Mobster(name: "Alice"), Mobster(name: "Bob"), Mobster(name: "Charlie")],
        inactiveMobsters: [Mobster(name: "Dave")]
    )
    return RosterView(roster: roster)
        .frame(width: 300, height: 400)
}
