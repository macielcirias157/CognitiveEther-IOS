import SwiftUI

struct ResourceMonitorView: View {
    @ObservedObject var resourceManager = ResourceManager.shared
    @State private var tps: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Resource Monitor")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                HStack(spacing: 24) {
                    ResourceGauge(label: "RAM", value: resourceManager.ramUsage, color: theme.primary)
                    ResourceGauge(label: "CPU", value: resourceManager.cpuUsage, color: theme.electricIndigo)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Inference Speed (TPS)")
                        .font(theme.appFont(size: 18, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    TPSChart(data: tps)
                        .frame(height: 150)
                }
                .padding(24)
                .background(theme.surfaceContainer)
                .cornerRadius(32)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Thermal State")
                        .font(theme.appFont(size: 18, weight: .semibold))
                        .foregroundColor(theme.onSurface)
                    
                    HStack {
                        thermalStatusView
                        Spacer()
                        Image(systemName: "thermometer.medium")
                            .foregroundColor(thermalColor)
                    }
                }
                .padding(24)
                .background(theme.surfaceContainer)
                .cornerRadius(32)
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
    }
    
    private var thermalStatusView: some View {
        let status: String
        switch resourceManager.thermalState {
        case .nominal: status = "Nominal (Good)"
        case .fair: status = "Fair (Warm)"
        case .serious: status = "Serious (Hot)"
        case .critical: status = "Critical (Throttling)"
        @unknown default: status = "Unknown"
        }
        return Text(status)
            .font(theme.appFont(size: 16))
            .foregroundColor(thermalColor)
    }
    
    private var thermalColor: Color {
        switch resourceManager.thermalState {
        case .nominal: return theme.primary
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return theme.onSurface
        }
    }
}

struct ResourceGauge: View {
    let label: String
    let value: Double
    let color: Color
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(theme.surfaceContainerHigh, lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(value * 100))%")
                        .font(theme.appFont(size: 20, weight: .bold))
                        .foregroundColor(theme.onSurface)
                    Text(label)
                        .font(theme.appFont(size: 12))
                        .foregroundColor(theme.onSurface.opacity(0.6))
                }
            }
            .frame(width: 120, height: 120)
        }
        .padding(24)
        .background(theme.surfaceContainer)
        .cornerRadius(32)
    }
}

struct TPSChart: View {
    let data: [Double]
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(0..<data.count, id: \.self) { index in
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(theme.primary)
                        .frame(width: 20, height: CGFloat(data[index] * 5))
                        .cornerRadius(10)
                    
                    Text("\(Int(data[index]))")
                        .font(theme.appFont(size: 10))
                        .foregroundColor(theme.onSurface.opacity(0.4))
                }
            }
        }
    }
}
