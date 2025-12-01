//
//  ExportView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct ExportView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    
    // Atalho para acessar as configurações de exportação
    private var settings: Binding<ExportSettings> {
        $viewModel.appSettings.export
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.large) {
                
                // 1. Cabeçalho
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    Text("Exportar Telemetria")
                        .font(Theme.Font.valueLarge)
                    
                    Text("Escolha o formato e os dados que deseja salvar.")
                        .foregroundColor(Theme.secondary)
                }
                .padding(.top, Theme.Spacing.large)
                
                // 2. Seletor de Formato (Exclusivo)
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    SectionHeader("Formato do Arquivo", icon: "doc.fill")
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                        ForEach(ExportFormat.allCases) { format in
                            FormatSelectionCard(
                                format: format,
                                isSelected: settings.defaultFormat.wrappedValue == format,
                                action: {
                                    withAnimation {
                                        settings.defaultFormat.wrappedValue = format
                                    }
                                }
                            )
                        }
                    }
                    
                    // Descrição do formato selecionado
                    Text(settings.defaultFormat.wrappedValue.description)
                        .font(.caption)
                        .foregroundColor(Theme.secondary)
                        .padding(.horizontal, 4)
                }
                .padding()
                .cardStyle()
                
                // 3. Seletor de Dados (Múltipla Escolha)
                VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                    SectionHeader("Dados Incluídos", icon: "chart.bar.doc.horizontal.fill")
                    
                    VStack(spacing: 0) {
                        DataToggleRow(
                            title: "GPS",
                            subtitle: "Latitude, Longitude, Altitude, Velocidade 2D/3D",
                            icon: "location.fill",
                            color: Theme.Data.color(for: .gps),
                            isOn: settings.includeGPS
                        )
                        
                        Divider().padding(.leading, 44)
                        
                        DataToggleRow(
                            title: "Acelerômetro",
                            subtitle: "Força G nos eixos X, Y, Z (Alta frequência)",
                            icon: "gauge.with.dots.needle.bottom.50percent",
                            color: Theme.Data.color(for: .accelerometer),
                            isOn: settings.includeAccelerometer
                        )
                        
                        Divider().padding(.leading, 44)
                        
                        DataToggleRow(
                            title: "Giroscópio",
                            subtitle: "Rotação (Rad/s) nos eixos X, Y, Z",
                            icon: "gyroscope",
                            color: Theme.Data.color(for: .gyroscope),
                            isOn: settings.includeGyroscope
                        )
                        
                        // Opcionais (se implementados no futuro)
                        // Divider().padding(.leading, 44)
                        // DataToggleRow(...)
                    }
                }
                .padding()
                .cardStyle()
                
                // 4. Botão de Ação
                Button(action: {
                    viewModel.exportTelemetry(settings: settings.wrappedValue)
                }) {
                    HStack {
                        if viewModel.isProcessing {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text(viewModel.isProcessing ? "Gerando..." : "Exportar Arquivo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Theme.success)
                .disabled(viewModel.isProcessing)
                .padding(.top, Theme.Spacing.medium)
                
                // Feedback de Sucesso
                if viewModel.showExportSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Arquivo salvo com sucesso!")
                        
                        if let url = viewModel.lastExportedURL {
                            Button("Mostrar no Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                            .buttonStyle(.link)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(Theme.padding)
            .padding(.bottom, 40)
        }
        .background(Theme.background)
    }
}

// MARK: - Subcomponents

/// Card selecionável para o formato de arquivo
struct FormatSelectionCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: Theme.Export.icon(for: format))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Theme.Export.color(for: format))
                
                Text(format.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .height(80)
            .background(
                RoundedRectangle(cornerRadius: Theme.smallCornerRadius)
                    .fill(isSelected ? Theme.primary : Theme.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.smallCornerRadius)
                    .stroke(isSelected ? Theme.primary : Color.gray.opacity(0.2), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

/// Linha de Toggle com ícone e descrição
struct DataToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
        .toggleStyle(SwitchToggleStyle(tint: Theme.primary))
    }
}

// MARK: - Helpers
fileprivate extension View {
    func height(_ value: CGFloat) -> some View {
        frame(height: value)
    }
}

// MARK: - Preview
#Preview {
    ExportView(viewModel: TelemetryViewModel())
        .frame(width: 600, height: 700)
}
