//
//  ChartsView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

//
//  ChartsView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//  Updated for macOS 26 Tahoe (LiquidGlass)
//

import SwiftUI
import Charts

struct ChartsView: View {
    // MARK: - Properties
    
    let data: [TelemetryData]
    
    // Cursor Sincronizado (Shared State)
    @State private var selectedTime: Double?
    
    // Otimização: Cache de dados reduzidos para renderização
    @State private var downsampledData: [TelemetryData] = []
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Fundo
            LinearGradient(
                colors: [Theme.background, Theme.background.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if data.isEmpty {
                EmptyStateView(
                    title: "Sem Dados para Gráfico",
                    systemImage: "chart.xyaxis.line",
                    description: "Importe um vídeo com telemetria para visualizar os gráficos."
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Gráfico de Navegação (Velocidade + Altitude)
                        GlassCard(depth: 0.5) {
                            VStack(alignment: .leading, spacing: 10) {
                                ChartHeader(
                                    title: "NAVEGAÇÃO",
                                    icon: "location.north.circle.fill",
                                    primaryValue: formatValue(for: .speed),
                                    secondaryValue: formatValue(for: .altitude)
                                )
                                
                                NavigationChart(data: downsampledData, selectedTime: $selectedTime)
                                    .frame(height: 250)
                            }
                        }
                        
                        // 2. Gráfico de Dinâmica (Força G)
                        GlassCard(depth: 0.5) {
                            VStack(alignment: .leading, spacing: 10) {
                                ChartHeader(
                                    title: "FORÇA G",
                                    icon: "waveform.path.ecg",
                                    primaryValue: formatValue(for: .gForce),
                                    secondaryValue: nil
                                )
                                
                                DynamicsChart(data: downsampledData, selectedTime: $selectedTime)
                                    .frame(height: 180)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            // Prepara os dados uma única vez ao aparecer
            self.downsampledData = prepareData(data)
        }
        .onChange(of: data) { newData in
            self.downsampledData = prepareData(newData)
        }
    }
    
    // MARK: - Helpers
    
    private func prepareData(_ raw: [TelemetryData]) -> [TelemetryData] {
        let maxPoints = 800 // Limite para manter 60fps
        if raw.count <= maxPoints { return raw }
        
        let step = raw.count / maxPoints
        var result: [TelemetryData] = []
        for index in stride(from: 0, to: raw.count, by: step) {
            result.append(raw[index])
        }
        return result
    }
    
    private enum MetricType { case speed, altitude, gForce }
    
    private func formatValue(for type: MetricType) -> String {
        // Se tiver cursor, mostra valor do cursor. Senão, mostra "-"
        guard let time = selectedTime,
              let point = downsampledData.min(by: { abs($0.timestamp - time) < abs($1.timestamp - time) })
        else { return "--" }
        
        switch type {
        case .speed:
            return String(format: "%.1f km/h", (point.speed2D ?? 0) * 3.6)
        case .altitude:
            return String(format: "%.0f m", point.altitude ?? 0)
        case .gForce:
            return String(format: "%.2f G", point.acceleration?.magnitude ?? 0)
        }
    }
}

// MARK: - Sub-Charts (Faixas)

struct NavigationChart: View {
    let data: [TelemetryData]
    @Binding var selectedTime: Double?
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                // Área de Velocidade (Gradiente Azul)
                if let speed = point.speed2D {
                    AreaMark(
                        x: .value("Tempo", point.timestamp),
                        y: .value("Velocidade", speed * 3.6)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.neonBlue.opacity(0.4), Theme.Colors.neonBlue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Tempo", point.timestamp),
                        y: .value("Velocidade", speed * 3.6)
                    )
                    .foregroundStyle(Theme.Colors.neonBlue)
                    .interpolationMethod(.catmullRom)
                }
                
                // Linha de Altitude (Roxa - Eixo Y secundário visual)
                // Nota: Charts do SwiftUI não suportam 2 eixos Y nativos facilmente no mesmo container
                // Para simplificar, normalizamos ou apenas plotamos a linha
                if let alt = point.altitude {
                    // Hack visual: Plotar em escala diferente ou usar RuleMark se crítico.
                    // Aqui plotaremos apenas a linha para correlação visual de tendência
                    LineMark(
                        x: .value("Tempo", point.timestamp),
                        y: .value("Altitude", alt / 10) // Escala visual ajustada
                    )
                    .foregroundStyle(Theme.Colors.neonPurple.opacity(0.8))
                    .interpolationMethod(.monotone)
                }
            }
            
            // Cursor (RuleMark)
            if let selectedTime {
                RuleMark(x: .value("Cursor", selectedTime))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.white.opacity(0.1))
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(formatTime(d))
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.white.opacity(0.1))
                AxisValueLabel().foregroundStyle(Theme.secondary)
            }
        }
        // Interatividade Unificada
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onHover { isHovering in
                        if !isHovering { selectedTime = nil }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                if let date = proxy.value(atX: x, as: Double.self) {
                                    selectedTime = date
                                }
                            }
                            .onEnded { _ in selectedTime = nil }
                    )
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let min = Int(seconds) / 60
        let sec = Int(seconds) % 60
        return String(format: "%02d:%02d", min, sec)
    }
}

struct DynamicsChart: View {
    let data: [TelemetryData]
    @Binding var selectedTime: Double?
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                if let acc = point.acceleration {
                    let g = acc.magnitude
                    
                    // Barra colorida baseada na intensidade
                    BarMark(
                        x: .value("Tempo", point.timestamp),
                        y: .value("Força G", g),
                        width: .fixed(2) // Barras finas parecem um espectrograma
                    )
                    .foregroundStyle(
                        g > 1.5 ? Theme.Colors.neonRed :
                        g > 1.0 ? Theme.Colors.neonOrange :
                        Theme.Colors.neonGreen.opacity(0.5)
                    )
                }
            }
            
            if let selectedTime {
                RuleMark(x: .value("Cursor", selectedTime))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .chartYScale(domain: 0...3.0) // Fixo para evitar pulos
        .chartXAxis(.hidden) // Esconde X pois já tem no de cima
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(.white.opacity(0.1))
                AxisValueLabel().foregroundStyle(Theme.secondary)
            }
        }
        // Replicar a interatividade para sincronizar
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                if let date = proxy.value(atX: x, as: Double.self) {
                                    selectedTime = date
                                }
                            }
                            .onEnded { _ in selectedTime = nil }
                    )
            }
        }
    }
}

// MARK: - Components

struct ChartHeader: View {
    let title: String
    let icon: String
    let primaryValue: String
    let secondaryValue: String?
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(Theme.secondary)
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.secondary)
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(primaryValue)
                        .font(Theme.Font.valueLarge)
                        .liquidNeon(color: .white)
                        .contentTransition(.numericText())
                    
                    if let sec = secondaryValue {
                        Text(sec)
                            .font(Theme.Font.valueMedium)
                            .foregroundStyle(Theme.Colors.neonPurple)
                            .contentTransition(.numericText())
                    }
                }
            }
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Synchronized Charts") {
    ChartsView(data: [
        TelemetryData(timestamp: 0, latitude: 0, longitude: 0, altitude: 100, speed2D: 10, speed3D: 0, acceleration: Vector3(x: 0, y: 0, z: 1.0), gravity: nil, gyro: nil, cameraOrientation: nil, imageOrientation: nil, iso: nil, shutterSpeed: nil, whiteBalance: nil, whiteBalanceRGB: nil, temperature: nil, audioDiagnostic: nil, faces: nil, scene: nil),
        TelemetryData(timestamp: 1, latitude: 0, longitude: 0, altitude: 105, speed2D: 15, speed3D: 0, acceleration: Vector3(x: 0, y: 0, z: 1.2), gravity: nil, gyro: nil, cameraOrientation: nil, imageOrientation: nil, iso: nil, shutterSpeed: nil, whiteBalance: nil, whiteBalanceRGB: nil, temperature: nil, audioDiagnostic: nil, faces: nil, scene: nil),
        TelemetryData(timestamp: 2, latitude: 0, longitude: 0, altitude: 110, speed2D: 20, speed3D: 0, acceleration: Vector3(x: 0, y: 0, z: 1.5), gravity: nil, gyro: nil, cameraOrientation: nil, imageOrientation: nil, iso: nil, shutterSpeed: nil, whiteBalance: nil, whiteBalanceRGB: nil, temperature: nil, audioDiagnostic: nil, faces: nil, scene: nil),
    ])
    .frame(width: 800, height: 600)
}
