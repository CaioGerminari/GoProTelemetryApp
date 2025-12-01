//
//  ChartsView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI
import Charts

struct ChartsView: View {
    // MARK: - Properties
    
    let data: [TelemetryData]
    
    @State private var selectedMetric: MetricType = .speed
    @State private var selectedX: Double? // Posição do cursor (Timestamp)
    
    // MARK: - Enums
    
    enum MetricType: String, CaseIterable, Identifiable {
        case speed = "Velocidade"
        case altitude = "Altitude"
        case acceleration = "Força G"
        
        var id: String { rawValue }
        
        var unit: String {
            switch self {
            case .speed: return "km/h"
            case .altitude: return "m"
            case .acceleration: return "G"
            }
        }
        
        var color: Color {
            switch self {
            case .speed: return Theme.Data.color(for: .gps)
            case .altitude: return Theme.Data.color(for: .gyroscope) // Usando cor secundária
            case .acceleration: return Theme.Data.color(for: .accelerometer)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            // 1. Controles
            if !data.isEmpty {
                Picker("Métrica", selection: $selectedMetric) {
                    ForEach(MetricType.allCases) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 400)
                .padding(.top, Theme.Spacing.small)
            }
            
            // 2. Área do Gráfico
            if data.isEmpty {
                EmptyStateView(
                    title: "Sem Dados para Gráfico",
                    systemImage: "chart.xyaxis.line",
                    description: "Importe um vídeo com telemetria para visualizar os gráficos."
                )
            } else {
                chartContent
                    .padding()
                    .cardStyle()
            }
        }
        .padding(Theme.padding)
        .background(Theme.background)
    }
    
    // MARK: - Chart Content
    
    @ViewBuilder
    private var chartContent: some View {
        VStack(alignment: .leading) {
            // Header com Valor Selecionado
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedMetric.rawValue)
                        .font(Theme.Font.label)
                        .foregroundColor(Theme.secondary)
                    
                    if let selectedValue = selectedValue {
                        Text("\(String(format: "%.1f", selectedValue)) \(selectedMetric.unit)")
                            .font(Theme.Font.valueLarge)
                            .foregroundColor(selectedMetric.color)
                            .contentTransition(.numericText())
                    } else {
                        // Valor padrão (Média ou Máximo) quando nada selecionado
                        Text("-")
                            .font(Theme.Font.valueLarge)
                            .foregroundColor(Theme.secondary)
                    }
                }
                Spacer()
                
                if let selectedTime = selectedTime {
                    Text("Tempo: \(selectedTime)")
                        .font(Theme.Font.mono)
                        .padding(6)
                        .background(Theme.surfaceSecondary)
                        .cornerRadius(4)
                }
            }
            
            // O Gráfico
            Chart {
                ForEach(downsampledData) { point in
                    // Linha Principal
                    LineMark(
                        x: .value("Tempo", point.timestamp),
                        y: .value("Valor", value(for: point))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [selectedMetric.color.opacity(0.8), selectedMetric.color],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .interpolationMethod(.catmullRom) // Suavização
                    
                    // Área abaixo da linha (Gradiente)
                    AreaMark(
                        x: .value("Tempo", point.timestamp),
                        y: .value("Valor", value(for: point))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [selectedMetric.color.opacity(0.3), selectedMetric.color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Cursor Interativo (RuleMark)
                if let selectedX {
                    RuleMark(x: .value("Cursor", selectedX))
                        .foregroundStyle(Theme.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .annotation(position: .top) {
                            Circle()
                                .fill(selectedMetric.color)
                                .frame(width: 10, height: 10)
                                .shadow(radius: 2)
                        }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    if let time = value.as(Double.self) {
                        AxisValueLabel(time.formattedTime)
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onHover { isHovering in
                            if !isHovering { selectedX = nil }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Converte posição X do mouse para Timestamp
                                    let origin = geometry[proxy.plotAreaFrame].origin
                                    let x = value.location.x - origin.x
                                    if let timestamp = proxy.value(atX: x, as: Double.self) {
                                        // Trava dentro dos limites do vídeo
                                        self.selectedX = min(max(0, timestamp), data.last?.timestamp ?? 0)
                                    }
                                }
                                .onEnded { _ in selectedX = nil }
                        )
                }
            }
            .frame(height: 350)
        }
    }
    
    // MARK: - Helpers & Logic
    
    /// Dados otimizados para renderização (Downsampling simples)
    /// Se tiver 50.000 pontos, o gráfico trava. Pegamos 1 a cada N pontos.
    private var downsampledData: [TelemetryData] {
        let maxPoints = 1000 // Limite visual razoável
        if data.count <= maxPoints { return data }
        
        let step = data.count / maxPoints
        var result: [TelemetryData] = []
        for index in stride(from: 0, to: data.count, by: step) {
            result.append(data[index])
        }
        return result
    }
    
    /// Extrai o valor numérico baseado na métrica selecionada
    private func value(for point: TelemetryData) -> Double {
        switch selectedMetric {
        case .speed: return point.speed2D * 3.6 // m/s -> km/h
        case .altitude: return point.altitude
        case .acceleration: return point.acceleration?.magnitude ?? 0.0
        }
    }
    
    /// Encontra o valor exato no cursor (interpolação ou busca simples)
    private var selectedValue: Double? {
        guard let time = selectedX else { return nil }
        // Busca o ponto mais próximo (pode ser otimizado com busca binária se necessário)
        if let point = data.min(by: { abs($0.timestamp - time) < abs($1.timestamp - time) }) {
            return value(for: point)
        }
        return nil
    }
    
    private var selectedTime: String? {
        guard let time = selectedX else { return nil }
        return time.formattedTime
    }
}

// MARK: - Preview

#Preview {
    ChartsView(data: [
        TelemetryData(timestamp: 0, latitude: 0, longitude: 0, altitude: 10, speed2D: 5, speed3D: 0, acceleration: nil, gyro: nil),
        TelemetryData(timestamp: 1, latitude: 0, longitude: 0, altitude: 12, speed2D: 8, speed3D: 0, acceleration: nil, gyro: nil),
        TelemetryData(timestamp: 2, latitude: 0, longitude: 0, altitude: 15, speed2D: 12, speed3D: 0, acceleration: nil, gyro: nil),
        TelemetryData(timestamp: 3, latitude: 0, longitude: 0, altitude: 14, speed2D: 10, speed3D: 0, acceleration: nil, gyro: nil),
    ])
    .frame(width: 800, height: 600)
}
