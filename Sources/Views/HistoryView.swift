import SwiftUI

struct HistoryView: View {
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Smart History")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Semantic Map")
                        .font(theme.appFont(size: 20, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    HStack(spacing: 12) {
                        CategoryChip(label: "Deep Learning", color: .blue)
                        CategoryChip(label: "UX Design", color: .purple)
                        CategoryChip(label: "SwiftUI", color: .orange)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    HistoryItem(title: "Architecture Review", model: "Llama 3 8B", date: "Today, 10:45 AM")
                    HistoryItem(title: "Design System Implementation", model: "Phi-3 Mini", date: "Yesterday, 4:20 PM")
                    HistoryItem(title: "MCP Protocol Exploration", model: "Gemma 7B", date: "2 days ago")
                }
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
    }
}

struct CategoryChip: View {
    let label: String
    let color: Color
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        Text(label)
            .font(theme.appFont(size: 14, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
    }
}

struct HistoryItem: View {
    let title: String
    let model: String
    let date: String
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.appFont(size: 16, weight: .semibold))
                    .foregroundColor(theme.onSurface)
                
                Text("\(model) • \(date)")
                    .font(theme.appFont(size: 12))
                    .foregroundColor(theme.onSurface.opacity(0.5))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(theme.onSurface.opacity(0.3))
        }
        .padding(20)
        .background(theme.surfaceContainer)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
        )
    }
}
