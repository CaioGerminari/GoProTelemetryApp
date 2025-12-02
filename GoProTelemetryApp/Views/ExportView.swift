//
//  ExportView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct ExportView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    // Atalho para configurações
    private var settings: Binding<ExportSettings> {
        $viewModel.appSettings.export
    }
    
    var body: some View {
        ZStack {
            // Fundo
            LinearGradient(
                colors: [Theme.background, Theme.background.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 1. Cabeçalho
                    headerView
                    
                    HStack(alignment: .top, spacing: 24) {
                        // Coluna Esquerda: Configurações
                        VStack(spacing: 24) {
                            formatSelector
                            dataSelector
                        }
                        
                        // Coluna Direita: Preview e Ação
                        VStack(spacing: 24) {
                            filePreview
                            actionSection
                        }
                    }
                }
                .padding(Theme.padding)
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.neonPurple.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(Circle().strokeBorder(Theme.Colors.neonPurple.opacity(0.3)))
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 24))
                    .liquidNeon(color: Theme.Colors.neonPurple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Exportar Telemetria")
                    .font(Theme.Font.title)
                    .foregroundStyle(.primary)
                
                Text("Configure o formato e escolha os dados.")
                    .font(.body)
                    .foregroundStyle(Theme.secondary)
            }
            
            Spacer()
        }
        .padding(.bottom, 10)
    }
    
    private var formatSelector: some View {
        GlassCard(depth: 0.5) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader("Formato", icon: "doc.fill")
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(ExportFormat.allCases) { format in
                        FormatButton(
                            format: format,
                            isSelected: settings.defaultFormat.wrappedValue == format,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    settings.defaultFormat.wrappedValue = format
                                }
                            }
                        )
                    }
                }
                
                // Descrição dinâmica
                HStack {
                    Image(systemName: "info.circle")
                    Text(settings.defaultFormat.wrappedValue.description)
                }
                .font(.caption)
                .foregroundStyle(Theme.secondary)
                .padding(10)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
    }
    
    private var dataSelector: some View {
        GlassCard(depth: 0.5) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader("Sensores Incluídos", icon: "chart.bar.doc.horizontal.fill")
                
                VStack(spacing: 0) {
                    DataToggleRow(
                        title: "GPS",
                        subtitle: "Lat, Lon, Alt, Velocidade",
                        icon: "location.fill",
                        color: Theme.Colors.neonBlue,
                        isOn: settings.includeGPS
                    )
                    
                    Divider().overlay(Color.white.opacity(0.1))
                    
                    DataToggleRow(
                        title: "Acelerômetro",
                        subtitle: "Força G (X, Y, Z)",
                        icon: "speedometer",
                        color: Theme.Colors.neonOrange,
                        isOn: settings.includeAccelerometer
                    )
                    
                    Divider().overlay(Color.white.opacity(0.1))
                    
                    DataToggleRow(
                        title: "Giroscópio",
                        subtitle: "Rotação (Rad/s)",
                        icon: "gyroscope",
                        color: Theme.Colors.neonIndigo,
                        isOn: settings.includeGyroscope
                    )
                    
                    Divider().overlay(Color.white.opacity(0.1))
                    
                    // Novos Dados (Fase 2)
                    DataToggleRow(
                        title: "Dados da Câmera",
                        subtitle: "ISO, Shutter, WB, Orientação",
                        icon: "camera.aperture",
                        color: Theme.Colors.neonYellow,
                        isOn: settings.includeCameraData
                    )
                }
            }
        }
    }
    
    private var filePreview: some View {
        GlassCard(depth: 0.8) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Pré-visualização", systemImage: "eye.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Exemplo")
                        .font(.caption2)
                        .padding(4)
                        .background(.white.opacity(0.1))
                        .cornerRadius(4)
                }
                
                // Área de Código
                ScrollView([.horizontal, .vertical]) {
                    Text(generatePreviewText())
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            // Botão Principal
            Button(action: {
                viewModel.exportTelemetry(settings: settings.wrappedValue)
            }) {
                HStack {
                    if viewModel.isProcessing {
                        ProgressView().controlSize(.small).tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    Text(viewModel.isProcessing ? "PROCESSANDO..." : "EXPORTAR ARQUIVO")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    ZStack {
                        Theme.Colors.neonGreen.opacity(0.2) // Tintura
                        LinearGradient(colors: [Theme.Colors.neonGreen.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)
                    }
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Theme.Colors.neonGreen.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: Theme.Colors.neonGreen.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isProcessing)
            
            // Feedback
            if viewModel.showExportSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.neonGreen)
                    Text("Salvo com sucesso!")
                        .font(.caption)
                    
                    if let url = viewModel.lastExportedURL {
                        Button("Abrir") {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                }
                .padding(10)
                .background(Theme.Colors.neonGreen.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Logic Helper
    
    private func generatePreviewText() -> String {
        let format = settings.defaultFormat.wrappedValue
        let hasGPS = settings.includeGPS.wrappedValue
        let hasCam = settings.includeCameraData.wrappedValue
        
        switch format {
        case .csv:
            var headers = "Time"
            if hasGPS { headers += ",Lat,Lon,Alt,Speed" }
            if hasCam { headers += ",ISO,Shutter,WB" }
            return """
            \(headers)
            0.000, -23.5505, -46.6333, 760.0, 12.5\(hasCam ? ", 100, 0.016, 5500" : "")
            0.050, -23.5505, -46.6333, 760.1, 12.6\(hasCam ? ", 100, 0.016, 5500" : "")
            ...
            """
        case .gpx:
            return """
            <?xml version="1.0"?>
            <gpx version="1.1">
              <trk>
                <trkseg>
                  <trkpt lat="-23.5505" lon="-46.6333">
                    <ele>760.0</ele>
                    <time>2025-12-02T14:30:00Z</time>
                  </trkpt>
                  ...
                </trkseg>
              </trk>
            </gpx>
            """
        case .json:
            return """
            {
              "telemetry": [
                {
                  "time": 0.0,
                  \(hasGPS ? "\"gps\": {\"lat\": -23.55, \"lon\": -46.63}," : "")
                  \(hasCam ? "\"camera\": {\"iso\": 100, \"shutter\": 0.01}," : "")
                },
                ...
              ]
            }
            """
        case .mgjson:
            return """
            {
              "version": "MGJSON2.0.0",
              "dynamicSamples": [
                {
                  "sampleSetID": "gpsData",
                  "samples": [{"value": [-23.55, -46.63]}]
                }
              ]
            }
            """
        case .kml:
            return """
            <kml>
              <Placemark>
                <LineString>
                  <coordinates>
                    -46.6333,-23.5505,760
                    ...
                  </coordinates>
                </LineString>
              </Placemark>
            </kml>
            """
        }
    }
}

// MARK: - Subcomponents

struct FormatButton: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: Theme.Export.icon(for: format))
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : Theme.Export.color(for: format))
                    .shadow(color: isSelected ? Theme.Export.color(for: format) : .clear, radius: 8)
                
                Text(format.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                ZStack {
                    if isSelected {
                        Theme.Export.color(for: format).opacity(0.8)
                    } else {
                        Color.black.opacity(0.2)
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? .white.opacity(0.5) : .white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: isSelected ? Theme.Export.color(for: format).opacity(0.4) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct DataToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Ícone
            ZStack {
                Circle()
                    .fill(isOn ? color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isOn ? color : .gray)
                    .shadow(color: isOn ? color.opacity(0.6) : .clear, radius: 4)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isOn ? .primary : .secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview("Export Screen") {
    ExportView(viewModel: TelemetryViewModel())
        .frame(width: 900, height: 700)
}
