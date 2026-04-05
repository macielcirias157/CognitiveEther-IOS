import SwiftUI

struct ResourceMonitorView: View {
    @State private var ramUsage: Double = 0.45
    @State private var gpuUsage: Double = 0.12
    @State private var tps: [Double] = [12.4, 15.6, 14.2, 18.9, 16.5, 20.1, 19.8]
    
    @ObservedObject var theme = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Resource Monitor")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                HStack(spacing: 24) {
                    ResourceGauge(label: "RAM", value: ramUsage, color: theme.primary)
                    ResourceGauge(label: "GPU", value: gpuUsage, color: theme.electricIndigo)
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
                        Text("Cool")
                            .font(theme.appFont(size: 16))
                            .foregroundColor(theme.primary)
                        Spacer()
                        Image(systemName: "thermometer.snowflake")
                            .foregroundColor(theme.primary)
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
