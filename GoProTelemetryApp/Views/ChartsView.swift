//
//  ChartsView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI
import Charts

struct ChartsView: View {
    let session: TelemetrySession
    
    @State private var selectedChart: ChartType = .speed
    @State private var hoveredDataPoint: TelemetryDataPoint?
    
    enum ChartType: String, CaseIterable {
        case speed = "Velocidade"
        case altitude = "Altitude"
        case acceleration = "Aceleração"
        case temperature = "Temperatura"
        case gyro = "Giroscópio"
        
        var icon: String {
            switch self {
            case .speed: return "speedometer"
            case .altitude: return "mountain.2"
            case .acceleration: return "bolt"
            case .temperature: return "thermometer"
            case .gyro: return "gyroscope"
            }
        }
        
        var color: Color {
            switch self {
            case .speed: return .blue
            case .altitude: return .green
            case .acceleration: return .orange
            case .temperature: return .red
            case .gyro: return .purple
            }
        }
        
        var unit: String {
            switch self {
            case .speed: return "km/h"
            case .altitude: return "m"
            case .acceleration: return "G"
            case .temperature: return "°C"
            case .gyro: return "rad/s"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: Theme.spacingLarge) {
            // Chart Type Picker
            chartTypePicker
            
            // Main Chart
            mainChartSection
            
            // Mini Charts Grid
            miniChartsGrid
        }
        .modernCard()
        .padding(Theme.spacingLarge)
    }
    
    // MARK: - Chart Type Picker
    private var chartTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingMedium) {
                ForEach(ChartType.allCases, id: \.self) { chartType in
                    ChartTypeButton(
                        chartType: chartType,
                        isSelected: selectedChart == chartType
                    ) {
                        selectedChart = chartType
                    }
                }
            }
            .padding(.horizontal, Theme.spacingLarge)
        }
        .padding(.top, Theme.spacingLarge)
    }
    
    // MARK: - Main Chart Section
    private var mainChartSection: some View {
        VStack(spacing: Theme.spacingMedium) {
            Chart {
                ForEach(session.points.prefix(500)) { point in
                    LineMark(
                        x: .value("Tempo", point.timestamp - (session.points.first?.timestamp ?? 0)),
                        y: .value(selectedChart.rawValue, getValue(for: point, chartType: selectedChart))
                    )
                    .foregroundStyle(selectedChart.color.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    if let hovered = hoveredDataPoint, hovered.id == point.id {
                        PointMark(
                            x: .value("Tempo", point.timestamp - (session.points.first?.timestamp ?? 0)),
                            y: .value(selectedChart.rawValue, getValue(for: point, chartType: selectedChart))
                        )
                        .foregroundStyle(.red)
                        .symbolSize(100)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    updateHoveredPoint(
                                        at: value.location,
                                        proxy: proxy,
                                        geometry: geometry
                                    )
                                }
                                .onEnded { _ in
                                    hoveredDataPoint = nil
                                }
                        )
                }
            }
            .frame(height: 300)
            .padding(.horizontal, Theme.spacingLarge)
            
            // Chart Info
            if let hoveredPoint = hoveredDataPoint {
                HoverInfoView(point: hoveredPoint, chartType: selectedChart)
                    .padding(.horizontal, Theme.spacingLarge)
            }
        }
    }
    
    // MARK: - Mini Charts Grid
    private var miniChartsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Theme.spacingMedium) {
            ForEach(ChartType.allCases, id: \.self) { chartType in
                if chartType != selectedChart {
                    MiniChartView(
                        session: session,
                        chartType: chartType,
                        isSelected: false
                    ) {
                        selectedChart = chartType
                    }
                }
            }
        }
        .padding(.horizontal, Theme.spacingLarge)
        .padding(.bottom, Theme.spacingLarge)
    }
    
    // MARK: - Helper Methods
    private func getValue(for point: TelemetryDataPoint, chartType: ChartType) -> Double {
        switch chartType {
        case .speed:
            return point.speed ?? 0
        case .altitude:
            return point.altitude ?? 0
        case .acceleration:
            return TelemetryCalculator.calculateAccelerationMagnitude(
                x: point.accelerationX,
                y: point.accelerationY,
                z: point.accelerationZ
            ) ?? 0
        case .temperature:
            return point.temperature ?? 0
        case .gyro:
            return TelemetryCalculator.calculateAccelerationMagnitude(
                x: point.gyroX,
                y: point.gyroY,
                z: point.gyroZ
            ) ?? 0
        }
    }
    
    private func updateHoveredPoint(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = location.x - geometry[proxy.plotAreaFrame].origin.x
        guard let timestamp: Double = proxy.value(atX: xPosition) else { return }
        
        let absoluteTimestamp = timestamp + (session.points.first?.timestamp ?? 0)
        hoveredDataPoint = session.points.min(by: {
            abs($0.timestamp - absoluteTimestamp) < abs($1.timestamp - absoluteTimestamp)
        })
    }
}

// MARK: - Supporting Views
struct ChartTypeButton: View {
    let chartType: ChartsView.ChartType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: chartType.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(chartType.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? chartType.color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(chartType.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct MiniChartView: View {
    let session: TelemetrySession
    let chartType: ChartsView.ChartType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: chartType.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(chartType.color)
                    
                    Text(chartType.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                }
                
                Chart {
                    ForEach(session.points.prefix(100)) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Value", getValue(for: point))
                        )
                        .foregroundStyle(chartType.color.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 40)
            }
            .padding(12)
            .background(Theme.cardBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(chartType.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func getValue(for point: TelemetryDataPoint) -> Double {
        switch chartType {
        case .speed: return point.speed ?? 0
        case .altitude: return point.altitude ?? 0
        case .acceleration:
            return TelemetryCalculator.calculateAccelerationMagnitude(
                x: point.accelerationX,
                y: point.accelerationY,
                z: point.accelerationZ
            ) ?? 0
        case .temperature: return point.temperature ?? 0
        case .gyro:
            return TelemetryCalculator.calculateAccelerationMagnitude(
                x: point.gyroX,
                y: point.gyroY,
                z: point.gyroZ
            ) ?? 0
        }
    }
}

struct HoverInfoView: View {
    let point: TelemetryDataPoint
    let chartType: ChartsView.ChartType
    
    var body: some View {
        HStack(spacing: Theme.spacingLarge) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tempo: \(formatTime(point.timestamp))")
                    .font(.system(size: 12, weight: .medium))
                
                if let lat = point.latitude, let lon = point.longitude {
                    Text("Posição: \(String(format: "%.6f", lat)), \(String(format: "%.6f", lon))")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundColor(Theme.textSecondary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(getValue().formatted(precision: 2)) \(chartType.unit)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(chartType.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(12)
        .background(Theme.cardBackground)
        .cornerRadius(8)
    }
    
    private func formatTime(_ timestamp: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: timestamp) ?? "0:00"
    }
    
    private func getValue() -> Double {
        switch chartType {
        case .speed: return point.speed ?? 0
        case .altitude: return point.altitude ?? 0
        case .acceleration:
            return TelemetryCalculator.calculateAccelerationMagnitude(
                x: point.accelerationX,
                y: point.accelerationY,
                z: point.accelerationZ
            ) ?? 0
        case .temperature: return point.temperature ?? 0
        case .gyro:
            return TelemetryCalculator.calculateAccelerationMagnitude(
                x: point.gyroX,
                y: point.gyroY,
                z: point.gyroZ
            ) ?? 0
        }
    }
}

// MARK: - Preview
#Preview {
    ChartsView(session: TelemetrySession(
        videoURL: URL(string: "https://example.com/video.mp4")!,
        duration: 60.0,
        points: [
            TelemetryDataPoint(
                timestamp: 0,
                latitude: -23.5505,
                longitude: -46.6333,
                altitude: 760,
                speed: 15.0,
                accelerationX: 0.1,
                accelerationY: 0.2,
                accelerationZ: 9.8,
                gyroX: 0.05,
                gyroY: 0.1,
                gyroZ: 0.02,
                temperature: 25.0
            )
        ],
        startTime: Date(),
        deviceName: "GoPro Hero 11"
    ))
    .frame(width: 800, height: 600)
}
