//
//  DataView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct DataView: View {
    let session: TelemetrySession
    
    @State private var searchText = ""
    @State private var selectedDataTypes: Set<TelemetryType> = [.gps, .accelerometer, .gyroscope, .temperature]
    @State private var sortOrder: SortOrder = .timestamp
    @State private var isAscending = true
    
    enum SortOrder: String, CaseIterable {
        case timestamp = "Tempo"
        case speed = "Velocidade"
        case altitude = "Altitude"
        case temperature = "Temperatura"
    }
    
    var filteredPoints: [TelemetryDataPoint] {
        let filtered = session.points.filter { point in
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                return String(format: "%.2f", point.timestamp).contains(searchText) ||
                       String(format: "%.6f", point.latitude ?? 0).contains(searchText) ||
                       String(format: "%.6f", point.longitude ?? 0).contains(searchText) ||
                       String(format: "%.1f", point.speed ?? 0).contains(searchText)
            }
            return true
        }
        
        return filtered.sorted { first, second in
            switch sortOrder {
            case .timestamp:
                return isAscending ? first.timestamp < second.timestamp : first.timestamp > second.timestamp
            case .speed:
                return isAscending ? (first.speed ?? 0) < (second.speed ?? 0) : (first.speed ?? 0) > (second.speed ?? 0)
            case .altitude:
                return isAscending ? (first.altitude ?? 0) < (second.altitude ?? 0) : (first.altitude ?? 0) > (second.altitude ?? 0)
            case .temperature:
                return isAscending ? (first.temperature ?? 0) < (second.temperature ?? 0) : (first.temperature ?? 0) > (second.temperature ?? 0)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: Theme.spacingMedium) {
            // Controls
            controlsSection
            
            // Data Type Filter
            dataTypeFilterSection
            
            // Data Table
            dataTableSection
            
            // Footer Info
            footerInfoSection
        }
        .modernCard()
        .padding(Theme.spacingLarge)
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textSecondary)
                
                TextField("Buscar...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
            
            Spacer()
            
            // Sort
            HStack {
                Text("Ordenar por:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                Picker("", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                
                Button(action: { isAscending.toggle() }) {
                    Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.spacingLarge)
        .padding(.top, Theme.spacingLarge)
    }
    
    // MARK: - Data Type Filter Section
    private var dataTypeFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingSmall) {
                ForEach(TelemetryType.allCases, id: \.self) { type in
                    DataTypeFilterButton(
                        type: type,
                        isSelected: selectedDataTypes.contains(type)
                    ) {
                        if selectedDataTypes.contains(type) {
                            selectedDataTypes.remove(type)
                        } else {
                            selectedDataTypes.insert(type)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.spacingLarge)
        }
    }
    
    // MARK: - Data Table Section
    private var dataTableSection: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                // Header
                HStack {
                    Text("Tempo")
                        .frame(width: 80, alignment: .leading)
                    
                    Text("Posição")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Altitude")
                        .frame(width: 80, alignment: .trailing)
                    
                    Text("Velocidade")
                        .frame(width: 80, alignment: .trailing)
                    
                    Text("Aceleração")
                        .frame(width: 100, alignment: .trailing)
                    
                    Text("Giroscópio")
                        .frame(width: 100, alignment: .trailing)
                    
                    Text("Temp")
                        .frame(width: 60, alignment: .trailing)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, Theme.spacingMedium)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.03))
                
                // Rows
                ForEach(Array(filteredPoints.prefix(200).enumerated()), id: \.offset) { index, point in
                    DataRowView(point: point, index: index)
                        .padding(.horizontal, Theme.spacingMedium)
                        .padding(.vertical, 8)
                        .background(index % 2 == 0 ? Color.clear : Color.black.opacity(0.02))
                }
            }
        }
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal, Theme.spacingLarge)
        .padding(.bottom, Theme.spacingLarge)
    }
    
    // MARK: - Footer Info Section
    private var footerInfoSection: some View {
        HStack {
            Text("Mostrando \(min(200, filteredPoints.count)) de \(session.points.count) pontos")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            
            Spacer()
            
            Text("Use ⌘F para buscar")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .padding(.horizontal, Theme.spacingLarge)
        .padding(.bottom, Theme.spacingLarge)
    }
}

// MARK: - Data Row View
struct DataRowView: View {
    let point: TelemetryDataPoint
    let index: Int
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            // Time
            Text(formatTime(point.timestamp))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .frame(width: 80, alignment: .leading)
                .foregroundColor(Theme.textPrimary)
            
            // Position
            if let lat = point.latitude, let lon = point.longitude {
                Text("\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                    .font(.system(size: 11, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Theme.textSecondary)
            } else {
                Text("—")
                    .font(.system(size: 11))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Theme.textSecondary.opacity(0.5))
            }
            
            // Altitude
            Text(point.altitude != nil ? "\(Int(point.altitude!))m" : "—")
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(Theme.textSecondary)
            
            // Speed
            Text(point.speed != nil ? "\(Int(point.speed!))" : "—")
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(Theme.textSecondary)
            
            // Acceleration
            if let accel = TelemetryCalculator.calculateAccelerationMagnitude(
                x: point.accelerationX,
                y: point.accelerationY,
                z: point.accelerationZ
            ) {
                Text("\(accel.formatted(precision: 1))")
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 100, alignment: .trailing)
                    .foregroundColor(Theme.textSecondary)
            } else {
                Text("—")
                    .font(.system(size: 11))
                    .frame(width: 100, alignment: .trailing)
                    .foregroundColor(Theme.textSecondary.opacity(0.5))
            }
            
            // Gyro
            if let gyro = TelemetryCalculator.calculateAccelerationMagnitude(
                x: point.gyroX,
                y: point.gyroY,
                z: point.gyroZ
            ) {
                Text("\(gyro.formatted(precision: 2))")
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 100, alignment: .trailing)
                    .foregroundColor(Theme.textSecondary)
            } else {
                Text("—")
                    .font(.system(size: 11))
                    .frame(width: 100, alignment: .trailing)
                    .foregroundColor(Theme.textSecondary.opacity(0.5))
            }
            
            // Temperature
            Text(point.temperature != nil ? "\(Int(point.temperature!))°" : "—")
                .font(.system(size: 11, design: .monospaced))
                .frame(width: 60, alignment: .trailing)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 4)
        .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func formatTime(_ timestamp: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: timestamp) ?? "0:00"
    }
}

// MARK: - Preview
#Preview {
    DataView(session: TelemetrySession(
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
            ),
            TelemetryDataPoint(
                timestamp: 1,
                latitude: -23.5506,
                longitude: -46.6334,
                altitude: 765,
                speed: 18.0,
                accelerationX: 0.2,
                accelerationY: 0.1,
                accelerationZ: 9.7,
                gyroX: 0.06,
                gyroY: 0.09,
                gyroZ: 0.03,
                temperature: 26.0
            )
        ],
        startTime: Date(),
        deviceName: "GoPro Hero 11"
    ))
    .frame(width: 800, height: 600)
}
