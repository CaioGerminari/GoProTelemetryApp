//
//  ContentView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var parserService = GPMFParserService()
    @StateObject private var fileService = FileManagerService()
    @StateObject private var exportService = ExportService()
    
    @State private var selectedVideoURL: URL?
    @State private var telemetrySession: TelemetrySession?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundColor.ignoresSafeArea()
                
                Group {
                    if parserService.isProcessing {
                        ProcessingView(
                            progress: parserService.progress,
                            status: parserService.currentStatus
                        )
                    } else if let session = telemetrySession {
                        TelemetryView(
                            session: session,
                            exportService: exportService
                        )
                    } else {
                        WelcomeContentView(onSelectVideo: selectVideo)
                    }
                }
            }
            .navigationTitle("GoPro Telemetry Extractor")
            .toolbar {
                if telemetrySession != nil {
                    ToolbarItem(placement: .primaryAction) {
                        SecondaryButton(
                            title: "Novo Arquivo",
                            icon: "plus"
                        ) {
                            resetSelection()
                        }
                    }
                }
            }
            .alert("Erro", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingExportSheet) {
                if let session = telemetrySession {
                    ExportView(
                        session: session,
                        exportService: exportService
                    ) { exportedURL in
                        // Handle successful export if needed
                        print("Arquivo exportado: \(exportedURL.lastPathComponent)")
                    }
                }
            }
        }
        .frame(minWidth: 1000, idealWidth: 1200, minHeight: 700, idealHeight: 900)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .openVideoFile)) { _ in
            selectVideo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newFile)) { _ in
            resetSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportTelemetry)) { _ in
            if telemetrySession != nil {
                showingExportSheet = true
            }
        }
    }
    
    // MARK: - Actions
    private func selectVideo() {
        Task {
            if let url = await fileService.selectVideoFile() {
                await processVideo(url)
            }
        }
    }
    
    private func processVideo(_ url: URL) async {
        do {
            selectedVideoURL = url
            let session = try await parserService.parseTelemetry(from: url)
            await MainActor.run {
                telemetrySession = session
            }
        } catch let error as GPMFError {
            await MainActor.run {
                switch error {
                case .invalidData:
                    errorMessage = "Este vídeo não contém dados de telemetria GPMF. Apenas vídeos GoPro com telemetria habilitada são suportados."
                case .parsingFailed:
                    errorMessage = "Falha ao processar dados de telemetria do vídeo. O arquivo pode estar corrompido."
                case .unsupportedFormat:
                    errorMessage = "Formato de vídeo não suportado. Use arquivos MP4, MOV ou M4V da GoPro."
                case .fileAccessDenied:
                    errorMessage = "Não foi possível acessar o arquivo de vídeo. Verifique as permissões."
                }
                showingError = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Falha ao processar vídeo: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func resetSelection() {
        selectedVideoURL = nil
        telemetrySession = nil
    }
}

// MARK: - Welcome Content View
struct WelcomeContentView: View {
    let onSelectVideo: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: Theme.spacingXLarge) {
            // Header
            VStack(spacing: Theme.spacingMedium) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundStyle(Theme.primaryGradient)
                    .symbolEffect(.bounce, options: .repeating, value: isHovered)
                
                Text("GoPro Telemetry Extractor")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Extraia dados de telemetria avançados de seus vídeos GoPro")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            
            // Feature Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.spacingMedium) {
                WelcomeFeatureCard(
                    icon: "location.fill",
                    title: "GPS Preciso",
                    description: "Dados de localização com alta precisão",
                    color: .blue
                )
                
                WelcomeFeatureCard(
                    icon: "gyroscope",
                    title: "Sensores IMU",
                    description: "Acelerômetro, giroscópio e magnetômetro",
                    color: .green
                )
                
                WelcomeFeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Análise Avançada",
                    description: "Gráficos e estatísticas detalhadas",
                    color: .orange
                )
                
                WelcomeFeatureCard(
                    icon: "square.and.arrow.up",
                    title: "Multi-Formato",
                    description: "Exporte para DaVinci, FCPX e mais",
                    color: .purple
                )
            }
            .padding(.horizontal, Theme.spacingXLarge)
            
            Spacer()
            
            // Action Button
            PrimaryButton(
                title: "Selecionar Vídeo GoPro",
                icon: "video.fill",
                action: onSelectVideo
            )
            .padding(.bottom, 60)
        }
        .padding(Theme.spacingXLarge)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isHovered.toggle()
            }
        }
    }
}

// MARK: - Welcome Feature Card
struct WelcomeFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: Theme.spacingMedium) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .scaleEffect(isHovered ? 1.1 : 1.0)
            
            VStack(spacing: Theme.spacingSmall) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Theme.spacingLarge)
        .modernCard()
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

#Preview("Processing") {
    ContentView()
        .overlay(
            ProcessingView(
                progress: 0.75,
                status: "Processando dados de telemetria..."
            )
        )
}

#Preview("With Session") {
    let mockSession = TelemetrySession(
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
    )
    
    return ContentView()
        .overlay(
            TelemetryView(
                session: mockSession,
                exportService: ExportService()
            )
        )
}
