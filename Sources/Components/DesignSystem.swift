import SwiftUI

struct GlassmorphicBackground: ViewModifier {
    let opacity: Double
    let blur: CGFloat
    let cornerRadius: CGFloat
    
    @ObservedObject var theme = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(
                theme.surfaceVariant
                    .opacity(opacity)
                    .blur(radius: blur)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(theme.surfaceVariant.opacity(opacity))
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct TonalStacking: ViewModifier {
    let cornerRadius: CGFloat
    @ObservedObject var theme = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .background(theme.surfaceContainer)
            .cornerRadius(cornerRadius)
            .padding(4)
            .background(theme.surface)
            .cornerRadius(cornerRadius + 4)
    }
}

extension View {
    func glassmorphic(opacity: Double = 0.6, blur: CGFloat = 20, cornerRadius: CGFloat = 24) -> some View {
        self.modifier(GlassmorphicBackground(opacity: opacity, blur: blur, cornerRadius: cornerRadius))
    }
    
    func tonalStacking(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(TonalStacking(cornerRadius: cornerRadius))
    }
}

// Common Components
struct LuminaButton: View {
    let label: String
    let action: () -> Void
    var isPrimary: Bool = true
    
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(theme.appFont(size: 16, weight: .semibold))
                .foregroundColor(isPrimary ? .black : theme.onSurface)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isPrimary ? theme.primaryGradient : nil
                )
                .cornerRadius(24)
                .overlay(
                    !isPrimary ? RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1) : nil
                )
        }
    }
}

struct LuminaInput: View {
    @Binding var text: String
    let placeholder: String
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(theme.surfaceContainerLow)
            .cornerRadius(32)
            .foregroundColor(theme.onSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(theme.outlineVariant.opacity(0.15), lineWidth: 1)
            )
    }
}
