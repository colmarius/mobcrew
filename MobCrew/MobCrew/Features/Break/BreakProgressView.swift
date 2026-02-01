import SwiftUI

struct BreakProgressView: View {
    let breakInterval: Int
    let turnsSinceBreak: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<breakInterval, id: \.self) { index in
                Image(systemName: index < turnsSinceBreak ? "circle.fill" : "circle")
                    .font(.system(size: 8))
                    .foregroundStyle(index < turnsSinceBreak ? .green : .gray.opacity(0.5))
            }
        }
    }
}

#Preview("Empty Progress") {
    BreakProgressView(breakInterval: 5, turnsSinceBreak: 0)
        .padding()
}

#Preview("Partial Progress") {
    BreakProgressView(breakInterval: 5, turnsSinceBreak: 3)
        .padding()
}

#Preview("Full Progress") {
    BreakProgressView(breakInterval: 5, turnsSinceBreak: 5)
        .padding()
}
