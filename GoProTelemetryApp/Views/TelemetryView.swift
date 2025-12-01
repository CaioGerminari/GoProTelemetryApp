//
//  TelemetryView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct TelemetryView: View {
    let session: TelemetrySession
    let exportService: ExportService
    
    @State private var selectedTab = 0
    @State private var showingExportSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingExportSuccess = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            TelemetryHeaderView(session: session)
                .padding(.horizontal, Theme.spacingLarge)
                .padding(.top, Theme.spacingLarge)
                .padding(.bottom, Theme.spacingMedium)
            
            // Tab Bar
            TelemetryTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, Theme.spacingLarge)
                .padding(.bottom, Theme.spacingMedium)
            
            // Content
            Group {
                switch selectedTab {
                case 0:
                    MapView(points: session.points)
                case 1:
                    ChartsView(session: session)
                case 2:
                    DataView(session: session)
                default:
                    MapView(points: session.points)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Footer with Export Button
            footerView
                .padding(.horizontal, Theme.spacingLarge)
                .padding(.vertical, Theme.spacingMedium)
        }
        .background(Theme.backgroundColor)
        .sheet(isPresented: $showingExportSheet) {
            ExportView(
                session: session,
                exportService: exportService
            ) { exportedURL in
                exportedFileURL = exportedURL
                showingExportSuccess = true
            }
        }
        .alert("Exportado com Sucesso", isPresented: $showingExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Arquivo exportado: \(exportedFileURL?.lastPathComponent ?? "Unknown")")
        }
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        HStack {
            Text("Pronto para exportar")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            
            Spacer()
            
            PrimaryButton(
                title: "Exportar Dados",
                icon: "square.and.arrow.up"
            ) {
                showingExportSheet = true
            }
        }
        .padding(Theme.spacingMedium)
    }
}

// MARK: - Telemetry Header View (Renamed to avoid conflict)
struct TelemetryHeaderView: View {
    let session: TelemetrySession
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingLarge) {
            VStack(alignment: .leading, spacing: Theme.spacingSmall) {
                Text(session.deviceName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("\(session.points.count) pontos • \(formatDuration(session.duration)) • \(session.statistics.totalDistance.formatted(precision: 1))m percorridos")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            TelemetryStatisticsGrid(stats: session.statistics)
        }
        .padding(Theme.spacingLarge)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

// MARK: - Telemetry Statistics Grid (Renamed to avoid conflict)
struct TelemetryStatisticsGrid: View {
    let stats: TelemetryStatistics
    
    var body: some View {
        HStack(spacing: Theme.spacingMedium) {
            StatBadge(icon: "ruler", value: "\(stats.totalDistance.formatted(precision: 1))m", label: "Distância")
            StatBadge(icon: "speedometer", value: "\(stats.maxSpeed.formatted(precision: 1))", label: "Vel. Máx")
            StatBadge(icon: "mountain.2", value: "\(stats.maxAltitude.formatted(precision: 0))m", label: "Altitude")
            StatBadge(icon: "timer", value: "\(stats.duration.formatted(precision: 0))s", label: "Duração")
        }
    }
}

// MARK: - Telemetry Tab Bar (Renamed to avoid conflict)
struct TelemetryTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        ("map", "Mapa"),
        ("chart.xyaxis.line", "Gráficos"),
        ("table", "Dados")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabButton(
                    title: tabs[index].1,
                    icon: tabs[index].0,
                    isSelected: selectedTab == index
                ) {
                    selectedTab = index
                }
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    TelemetryView(
        session: TelemetrySession(
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
        ),
        exportService: ExportService()
    )
    .frame(width: 1000, height: 700)
}
