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
    
    // MARK: - State (Player Virtual)
    
    // Índice do ponto de dados atual (para o Scrubber)
    @State private var currentIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var playbackTimer: Timer?
    
    // MARK: - Computed Properties
    
    private var session: TelemetrySession? { viewModel.session }
    private var dataPoints: [TelemetryData] { session?.dataPoints ?? [] }
    private var stats: TelemetryStatistics { session?.statistics ?? .empty }
    
    /// O ponto de dados selecionado no momento (Scrubber) ou o último (se nada selecionado)
    private var currentPoint: TelemetryData? {
        guard !dataPoints.isEmpty, dataPoints.indices.contains(currentIndex) else { return nil }
        return dataPoints[currentIndex]
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 1. Fundo do App (Gradient Mesh Sutil)
            // Simula o ambiente "Desktop" por trás do vidro
            LinearGradient(
                colors: [
                    Theme.background,
                    Theme.background.opacity(0.8),
                    Theme.primary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 2. Header Flutuante
                    headerSection
                    
                    // 3. HUD Principal (Mapa + Gauges)
                    hudSection
                    
                    // 4. Controles de Reprodução (Timeline)
                    playerControlsSection
                    
                    // 5. Painel de Câmera (Novo Componente)
                    if let point = currentPoint {
                        CameraStatusView(
                            iso: point.iso,
                            shutter: point.shutterSpeed,
                            wb: point.whiteBalance,
                            orientation: point.cameraOrientation
                        )
                    }
                    
                    // 6. Estatísticas Secundárias (Glass Cards)
                    secondaryStatsGrid
                    
                    Spacer(minLength: 40)
                }
                .padding(24)
            }
        }
        .onAppear {
            // Inicia no começo ou fim
            if currentIndex == 0 && !dataPoints.isEmpty {
                currentIndex = 0
            }
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        GlassCard(depth: 0.5) {
            HStack(spacing: 16) {
                // Ícone do Arquivo
                ZStack {
                    Circle()
                        .fill(Theme.primary.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "film.stack.fill")
                        .font(.title2)
                        .liquidNeon(color: Theme.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session?.videoUrl.lastPathComponent ?? "Sem Vídeo")
                        .font(Theme.Font.title)
                        .foregroundStyle(.primary)
                    
                    HStack {
                        if let model = session?.cameraModel {
                            Label(model, systemImage: "camera.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(session?.creationDate.shortDate ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Badge de Status
                Text("\(dataPoints.count) SAMPLES")
                    .font(.caption.bold().monospaced())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
    
    private var hudSection: some View {
        ZStack(alignment: .top) {
            // Camada do Mapa (Fundo)
            // Nota: O MapView original não suporta "currentPin" ainda,
            // mas servirá como base visual para o trajeto.
            MapView(telemetryData: dataPoints)
                .frame(height: 380)
                .cornerRadius(Theme.cornerRadius)
                .overlay(
                    // Borda de Vidro e Sombra Interna
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Theme.shadowColor, radius: 15, y: 10)
            
            // Camada de Gauges (Flutuando sobre o Mapa)
            HStack(alignment: .top) {
                // Esquerda: Velocidade
                GlassGauge(
                    title: "Velocidade",
                    value: (currentPoint?.speed2D ?? 0) * 3.6,
                    range: 0...100, // Deveria ser stats.maxSpeed, mas fixo para demo visual
                    unit: "km/h",
                    color: Theme.Colors.neonBlue,
                    size: 160
                )
                
                Spacer()
                
                // Direita: Força G
                GlassGauge(
                    title: "Força G",
                    value: currentPoint?.acceleration?.magnitude ?? 0,
                    range: 0...2.5,
                    unit: "G",
                    color: Theme.Colors.neonOrange,
                    size: 160
                )
            }
            .padding(20)
        }
    }
    
    private var playerControlsSection: some View {
        GlassCard(depth: 1.0) {
            VStack(spacing: 8) {
                // Info de Tempo
                HStack {
                    Text(currentPoint?.formattedTime ?? "00:00")
                        .font(.title3.monospacedDigit())
                        .liquidNeon(color: .white)
                    
                    Spacer()
                    
                    Text(stats.duration.formattedTime)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                
                // Slider (Scrubber) Customizado
                HStack(spacing: 16) {
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.primary)
                            .shadow(color: Theme.primary.opacity(0.4), radius: 8)
                    }
                    .buttonStyle(.plain)
                    
                    Slider(
                        value: Binding(
                            get: { Double(currentIndex) },
                            set: { currentIndex = Int($0) }
                        ),
                        in: 0...Double(max(0, dataPoints.count - 1))
                    )
                    .tint(Theme.primary)
                }
            }
        }
    }
    
    private var secondaryStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            
            // Distância
            CompactGlassStat(
                title: "Distância Total",
                value: stats.totalDistance.asDistanceString,
                icon: "map.fill",
                color: Theme.Colors.neonGreen
            )
            
            // Altitude Atual
            CompactGlassStat(
                title: "Altitude Atual",
                value: String(format: "%.0f m", currentPoint?.altitude ?? 0),
                icon: "mountain.2.fill",
                color: Theme.Colors.neonPurple
            )
            
            // Média Vel
            CompactGlassStat(
                title: "Velocidade Média",
                value: stats.avgSpeed.asKmhString,
                icon: "gauge.medium",
                color: Theme.Colors.neonBlue
            )
        }
    }
    
    // MARK: - Logic (Playback)
    
    private func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            startPlayback()
        } else {
            stopPlayback()
        }
    }
    
    private func startPlayback() {
        // Timer simples para avançar o índice (~30fps visual)
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in
            Task { @MainActor in
                if currentIndex < dataPoints.count - 1 {
                    // Pula alguns pontos para acelerar se o vídeo for longo
                    // Num app real, sincronizariamos com AVPlayer
                    currentIndex += 5
                } else {
                    currentIndex = 0 // Loop ou stop
                    stopPlayback()
                }
            }
        }
    }
    
    private func stopPlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

// MARK: - Subcomponents Locais

/// Card pequeno para estatísticas secundárias (estilo Glass)
struct CompactGlassStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCard(depth: 0.3) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.system(size: 14))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(Theme.Font.valueMedium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Preview Mock

#Preview("Telemetry Dashboard") {
    TelemetryView(viewModel: TelemetryViewModel())
        .frame(width: 1000, height: 800)
}
