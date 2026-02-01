import SwiftUI

struct TipView: View {
    let tip: Tip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text(tip.title)
                    .font(.headline)
            }
            
            Text(tip.body)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("— \(tip.author)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    TipView(tip: .random())
        .padding()
        .frame(width: 300)
}
