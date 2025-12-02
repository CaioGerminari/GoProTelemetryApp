//
//  TelemetryView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI
import MapKit

struct TelemetryView: View {
    // MARK: - Dependencies
    
    @ObservedObject var viewModel: TelemetryViewModel
    
    // MARK: - Computed Properties (Helpers)
    
    private var session: TelemetrySession? { viewModel.session }
    private var stats: TelemetryStatistics { session?.statistics ?? .empty }
    private var dataPoints: [TelemetryData] { session?.dataPoints ?? [] }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.extraLarge) {
                
                // 1. Cabeçalho do Vídeo
                if let url = session?.videoUrl {
                    HStack(spacing: Theme.Spacing.medium) {
                        // Ícone do Arquivo
                        Image(systemName: "film.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                            .frame(width: 60, height: 60)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(url.lastPathComponent)
                                .font(Theme.Font.title)
                                .foregroundColor(Theme.primary)
                            
                            HStack {
                                InfoBadge(text: url.formattedFileSize, color: .gray, icon: "externaldrive")
                                InfoBadge(text: "\(dataPoints.count) pontos", color: .blue, icon: "chart.bar")
                                if let date = session?.creationDate {
                                    InfoBadge(text: date.shortDate, color: .secondary, icon: "calendar")
                                }
                                // Badge do Modelo da Câmera
                                if let model = session?.cameraModel {
                                    InfoBadge(text: model, color: .purple, icon: "camera")
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, Theme.Spacing.small)
                }
                
                // 2. Grid de Estatísticas (Cards)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: Theme.Spacing.medium)], spacing: Theme.Spacing.medium) {
                    
                    // Tempo Total
                    StatCard(
                        title: "Duração",
                        value: stats.duration.formattedTime,
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    // Distância
                    StatCard(
                        title: "Distância Total",
                        value: stats.totalDistance.asDistanceString,
                        icon: "map.fill",
                        color: .green
                    )
                    
                    // Velocidade Máxima
                    StatCard(
                        title: "Velocidade Máx",
                        value: stats.maxSpeed.asKmhString,
                        icon: "speedometer",
                        color: .orange
                    )
                    
                    // Altitude Máxima
                    StatCard(
                        title: "Altitude Máx",
                        value: stats.maxAltitude.asDistanceString,
                        icon: "mountain.2.fill",
                        color: .purple
                    )
                    
                    // Média de Velocidade
                    StatCard(
                        title: "Velocidade Média",
                        value: stats.avgSpeed.asKmhString,
                        icon: "gauge.medium",
                        color: .teal
                    )
                    
                    // Força G Máxima
                    if stats.maxGForce > 0 {
                        StatCard(
                            title: "Força G Máx",
                            value: String(format: "%.1f G", stats.maxGForce),
                            icon: "waveform.path.ecg",
                            color: .red
                        )
                    }
                    
                    // Temperatura Máxima
                    if stats.maxTemperature > 0 {
                        StatCard(
                            title: "Temp. Máx",
                            value: String(format: "%.0f°C", stats.maxTemperature),
                            icon: "thermometer.sun.fill",
                            color: .red
                        )
                    }
                }
                
                // 3. Visão Geral do Mapa
                if !dataPoints.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        SectionHeader("Trajeto Percorrido", icon: "map")
                        
                        // Reutiliza o MapView mas com altura fixa e sem controles complexos
                        MapView(telemetryData: dataPoints)
                            .frame(height: 350)
                            .cornerRadius(Theme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                    .stroke(Theme.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Theme.shadowColor, radius: 4, x: 0, y: 2)
                    }
                } else {
                    // Estado Vazio (Sem GPS)
                    EmptyStateView(
                        title: "Sem GPS",
                        systemImage: "location.slash",
                        description: "Não foi possível traçar o mapa para este vídeo."
                    )
                    .frame(height: 200)
                    .cardStyle()
                }
            }
            .padding(Theme.padding)
        }
        .background(Theme.background)
    }
}

// MARK: - Preview Helper & Implementation

// Extensão auxiliar para isolar a criação de dados mockados
// Isso resolve o erro "Ambiguous expression" no #Preview
extension TelemetryViewModel {
    static var preview: TelemetryViewModel {
        let vm = TelemetryViewModel()
        
        let points = [
            TelemetryData(
                timestamp: 0, latitude: -25.42, longitude: -49.27, altitude: 900, speed2D: 10, speed3D: 10,
                acceleration: Vector3(x: 0, y: 0, z: 1), gravity: nil, gyro: nil,
                cameraOrientation: nil, imageOrientation: nil,
                iso: 100, shutterSpeed: 0.01, whiteBalance: 5500, whiteBalanceRGB: nil,
                temperature: 30, audioDiagnostic: nil, faces: nil, scene: "URBAN"
            ),
            TelemetryData(
                timestamp: 10, latitude: -25.43, longitude: -49.28, altitude: 910, speed2D: 15, speed3D: 15,
                acceleration: Vector3(x: 0, y: 0, z: 1), gravity: nil, gyro: nil,
                cameraOrientation: nil, imageOrientation: nil,
                iso: 200, shutterSpeed: 0.02, whiteBalance: 5500, whiteBalanceRGB: nil,
                temperature: 32, audioDiagnostic: nil, faces: nil, scene: "URBAN"
            )
        ]
        
        let stats = TelemetryStatistics(
            duration: 120.5,
            totalDistance: 1540,
            maxSpeed: 22.5,
            avgSpeed: 12.0,
            maxAltitude: 950,
            minAltitude: 900,
            maxGForce: 1.2,
            cameraName: "GoPro Hero 11 Black",
            detectedScenes: ["URBAN"],
            audioIssuesCount: 0,
            maxTemperature: 45.0
        )
        
        let session = TelemetrySession(
            videoUrl: URL(fileURLWithPath: "/Videos/GoPro/GX0100.MP4"),
            creationDate: Date(),
            cameraModel: "GoPro Hero 11 Black",
            dataPoints: points,
            statistics: stats
        )
        
        vm.session = session
        return vm
    }
}

#Preview {
    TelemetryView(viewModel: TelemetryViewModel.preview)
        .frame(width: 900, height: 700)
}
