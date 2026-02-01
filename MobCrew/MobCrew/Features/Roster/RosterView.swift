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
                if !roster.activeMobsters.isEmpty {
                    activeSection
                }
                
                if !roster.inactiveMobsters.isEmpty {
                    inactiveSection
                }
            }
            
            Spacer()
        }
        .padding()
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
        }
    }
    
    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: { roster.shuffle() }) {
                    Image(systemName: "shuffle")
                        .font(.body)
                }
                .buttonStyle(.borderless)
                .disabled(roster.activeMobsters.count < 2)
                .help("Shuffle roster order")
            }
            
            List {
                ForEach(Array(roster.activeMobsters.enumerated()), id: \.element.id) { index, mobster in
                    MobsterRow(
                        mobster: mobster,
                        role: role(for: index),
                        isActive: true,
                        onRemove: { removeMobster(at: index) },
                        onToggleActive: { roster.benchMobster(at: index) }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onMove { source, destination in
                    roster.moveMobster(from: source, to: destination)
                }
            }
            .listStyle(.plain)
            .frame(minHeight: CGFloat(roster.activeMobsters.count) * 44)
            .scrollDisabled(true)
        }
    }
    
    private var inactiveSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Benched")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ForEach(Array(roster.inactiveMobsters.enumerated()), id: \.element.id) { index, mobster in
                MobsterRow(
                    mobster: mobster,
                    role: nil,
                    isActive: false,
                    onRemove: { removeInactiveMobster(at: index) },
                    onToggleActive: { roster.rotateIn(at: index) }
                )
            }
        }
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
    
    private func removeMobster(at index: Int) {
        guard roster.activeMobsters.indices.contains(index) else { return }
        roster.activeMobsters.remove(at: index)
    }
    
    private func removeInactiveMobster(at index: Int) {
        guard roster.inactiveMobsters.indices.contains(index) else { return }
        roster.inactiveMobsters.remove(at: index)
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
