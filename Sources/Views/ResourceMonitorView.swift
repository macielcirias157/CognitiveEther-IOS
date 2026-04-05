import SwiftUI

struct ResourceMonitorView: View {
    @ObservedObject private var resourceManager = ResourceManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Resource Monitor")
                    .font(theme.appFont(size: 32, weight: .bold))
                    .foregroundColor(theme.onSurface)

                HStack(spacing: 16) {
                    ResourceGauge(label: "RAM", value: resourceManager.ramUsage, color: theme.primary)
                    ResourceGauge(label: "CPU", value: resourceManager.cpuUsage, color: theme.electricIndigo)
                }

                inferenceCard
                thermalCard
            }
            .padding()
        }
        .background(theme.surface.ignoresSafeArea())
    }

    private var inferenceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inference Metrics")
                .font(theme.appFont(size: 18, weight: .semibold))
                .foregroundColor(theme.onSurface)

            if resourceManager.lastInference.model.isEmpty {
                Text("No AI responses recorded yet. Send a message to capture real throughput and latency.")
                    .font(theme.appFont(size: 14))
                    .foregroundColor(theme.onSurface.opacity(0.6))
            } else {
                HStack(spacing: 12) {
                    MetricPill(title: "Provider", value: resourceManager.lastInference.provider.displayName)
                    MetricPill(title: "Model", value: resourceManager.lastInference.model)
                }

                HStack(spacing: 12) {
                    MetricPill(title: "Latency", value: String(format: "%.2fs", resourceManager.lastInference.latency))
                    MetricPill(title: "Est. TPS", value: String(format: "%.1f", resourceManager.lastInference.estimatedTokensPerSecond))
                }

                TPSChart(data: resourceManager.inferenceSamples)
                    .frame(height: 150)
                    .padding(.top, 8)
            }
        }
        .padding(22)
        .background(theme.surfaceContainer)
        .cornerRadius(28)
    }

    private var thermalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thermal State")
                .font(theme.appFont(size: 18, weight: .semibold))
                .foregroundColor(theme.onSurface)

            HStack {
                Text(thermalLabel)
                    .font(theme.appFont(size: 16))
                    .foregroundColor(thermalColor)

                Spacer()

                Image(systemName: "thermometer.medium")
                    .foregroundColor(thermalColor)
            }
        }
        .padding(22)
        .background(theme.surfaceContainer)
        .cornerRadius(28)
    }

    private var thermalLabel: String {
        switch resourceManager.thermalState {
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        @unknown default:
            return "Unknown"
        }
    }

    private var thermalColor: Color {
        switch resourceManager.thermalState {
        case .nominal:
            return theme.primary
        case .fair:
            return .yellow
        case .serious:
            return .orange
        case .critical:
            return .red
        @unknown default:
            return theme.onSurface
        }
    }
}

struct ResourceGauge: View {
    let label: String
    let value: Double
    let color: Color

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(theme.surfaceContainerHigh, lineWidth: 12)

                Circle()
                    .trim(from: 0, to: min(max(value, 0), 1))
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
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
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(theme.surfaceContainer)
        .cornerRadius(28)
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(theme.appFont(size: 10, weight: .semibold))
                .foregroundColor(theme.onSurface.opacity(0.45))

            Text(value)
                .font(theme.appFont(size: 14, weight: .semibold))
                .foregroundColor(theme.onSurface)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(theme.surfaceContainerLow)
        .cornerRadius(18)
    }
}

struct TPSChart: View {
    let data: [Double]

    @ObservedObject private var theme = ThemeManager.shared

    private var normalizedValues: [Double] {
        guard let maxValue = data.max(), maxValue > 0 else {
            return Array(repeating: 0, count: max(data.count, 8))
        }

        return data.map { $0 / maxValue }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(normalizedValues.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primary)
                        .frame(width: 18, height: max(CGFloat(value) * 110, 6))

                    if index < data.count {
                        Text(String(format: "%.0f", data[index]))
                            .font(theme.appFont(size: 10))
                            .foregroundColor(theme.onSurface.opacity(0.45))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
