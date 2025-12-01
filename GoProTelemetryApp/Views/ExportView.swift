//
//  ExportView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct ExportView: View {
    let session: TelemetrySession
    let exportService: ExportService
    let onExport: (URL) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .csv
    @State private var includeGPS = true
    @State private var includeIMU = true
    @State private var includeCamera = false
    @State private var sampleRate = 1.0
    @State private var isExporting = false
    @State private var exportError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            ScrollView {
                VStack(spacing: Theme.spacingLarge) {
                    // Format Selection
                    formatSelectionSection
                    
                    // Data Options
                    dataOptionsSection
                    
                    // Export Summary
                    exportSummarySection
                }
                .padding(Theme.spacingLarge)
            }
            
            // Footer Actions
            footerActionsSection
        }
        .frame(width: 600, height: 700)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Exportar Telemetria")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("\(session.points.count) pontos • \(session.deviceName)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            SecondaryButton(
                title: "Cancelar",
                icon: "xmark"
            ) {
                dismiss()
            }
        }
        .padding(Theme.spacingLarge)
        .background(Color.black.opacity(0.02))
    }
    
    // MARK: - Format Selection Section
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMedium) {
            Text("Formato de Saída")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Theme.spacingMedium) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    ExportFormatCard(
                        format: format,
                        isSelected: selectedFormat == format
                    ) {
                        selectedFormat = format
                    }
                }
            }
        }
        .padding(Theme.spacingLarge)
        .modernCard()
    }
    
    // MARK: - Data Options Section
    private var dataOptionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMedium) {
            Text("Opções de Dados")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: Theme.spacingMedium) {
                ToggleOption(
                    icon: "location.fill",
                    title: "Dados GPS",
                    subtitle: "Coordenadas, altitude e velocidade",
                    isOn: $includeGPS
                )
                
                ToggleOption(
                    icon: "gyroscope",
                    title: "Dados de Movimento",
                    subtitle: "Acelerômetro e giroscópio",
                    isOn: $includeIMU
                )
                
                if includeIMU {
                    sampleRateSection
                }
                
                ToggleOption(
                    icon: "camera.fill",
                    title: "Dados da Câmera",
                    subtitle: "Configurações e metadados",
                    isOn: $includeCamera
                )
            }
        }
        .padding(Theme.spacingLarge)
        .modernCard()
    }
    
    // MARK: - Sample Rate Section
    private var sampleRateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Taxa de Amostragem")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textPrimary)
            
            HStack {
                Slider(value: $sampleRate, in: 0.1...10.0, step: 0.1)
                    .accentColor(Theme.primaryColor)
                
                Text("\(sampleRate.formatted(precision: 1))x")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .frame(width: 40)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Text("\(calculateSampleCount()) pontos serão exportados")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .padding()
        .background(Color.black.opacity(0.03))
        .cornerRadius(8)
    }
    
    // MARK: - Export Summary Section
    private var exportSummarySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMedium) {
            Text("Resumo da Exportação")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.spacingMedium) {
                ExportSummaryItem(title: "Formato", value: selectedFormat.rawValue)
                ExportSummaryItem(title: "Pontos", value: "\(calculateSampleCount())")
                ExportSummaryItem(title: "Arquivo", value: "\(session.deviceName)_telemetry.\(selectedFormat.fileExtension)")
                ExportSummaryItem(title: "Tamanho Estimado", value: estimateFileSize())
            }
        }
        .padding(Theme.spacingLarge)
        .modernCard()
    }
    
    // MARK: - Footer Actions Section
    private var footerActionsSection: some View {
        VStack(spacing: Theme.spacingMedium) {
            if let error = exportError {
                errorSection(error: error)
            }
            
            HStack {
                Text("Pronto para exportar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                PrimaryButton(
                    title: isExporting ? "Exportando..." : "Exportar",
                    icon: isExporting ? nil : "square.and.arrow.up",
                    action: performExport,
                    isLoading: isExporting
                )
            }
        }
        .padding(Theme.spacingLarge)
        .background(Color.black.opacity(0.02))
    }
    
    // MARK: - Error Section
    private func errorSection(error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(error)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    private func calculateSampleCount() -> Int {
        let baseCount = session.points.count
        return Int(Double(baseCount) / sampleRate)
    }
    
    private func estimateFileSize() -> String {
        let sampleCount = calculateSampleCount()
        var bytesPerSample = 0.0
        if includeGPS { bytesPerSample += 100.0 }
        if includeIMU { bytesPerSample += 50.0 }
        let estimatedSize = Double(sampleCount) * bytesPerSample / 1024.0
        return "\(Int(estimatedSize)) KB"
    }
    
    private func performExport() {
        isExporting = true
        exportError = nil
        
        let configuration = ExportConfiguration(
            format: selectedFormat,
            includeGPS: includeGPS,
            includeIMU: includeIMU,
            includeCamera: includeCamera,
            sampleRate: sampleRate
        )
        
        Task {
            do {
                let exportedURL = try await exportService.exportTelemetry(
                    session,
                    format: selectedFormat,
                    configuration: configuration
                )
                
                await MainActor.run {
                    isExporting = false
                    onExport(exportedURL)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Supporting Views (Renamed to avoid conflicts)
struct ExportFormatCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: getIconName())
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.primaryColor)
                
                VStack(spacing: 4) {
                    Text(format.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Theme.textPrimary)
                    
                    Text(format.fileExtension.uppercased())
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.primaryColor : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.primaryColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func getIconName() -> String {
        switch format {
        case .csv: return "tablecells"
        case .gpx: return "map"
        case .json: return "curlybraces"
        case .fcpxml: return "film"
        case .davinci: return "video"
        }
    }
}

struct ExportSummaryItem: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Preview
#Preview {
    ExportView(
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
                )
            ],
            startTime: Date(),
            deviceName: "GoPro Hero 11"
        ),
        exportService: ExportService(),
        onExport: { _ in }
    )
}
