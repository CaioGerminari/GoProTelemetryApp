//
//  SettingsView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "Geral"
        case export = "Exportar"
        case appearance = "Aparência"
        case advanced = "Avançado"
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .export: return "square.and.arrow.up"
            case .appearance: return "paintbrush"
            case .advanced: return "wrench.and.screwdriver"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            
            contentSection
        }
        .background(Theme.backgroundColor)
        .environmentObject(settings)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Configurações")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Personalize o GoPro Telemetry Extractor")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, Theme.spacingLarge)
        .padding(.top, Theme.spacingLarge)
        .padding(.bottom, Theme.spacingMedium)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        HStack(alignment: .top, spacing: 0) {
            // Sidebar
            sidebarSection
            
            // Content Area
            contentAreaSection
        }
    }
    
    // MARK: - Sidebar Section
    private var sidebarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                SettingsTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
            
            Spacer()
            
            versionInfoSection
        }
        .frame(width: 200)
        .padding(Theme.spacingMedium)
        .background(Color.black.opacity(0.1))
    }
    
    // MARK: - Content Area Section
    private var contentAreaSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingLarge) {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .export:
                    ExportSettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .advanced:
                    AdvancedSettingsView()
                }
            }
            .padding(Theme.spacingLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Version Info Section
    private var versionInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GoPro Telemetry Extractor")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)
            
            Text("Versão 1.0.0")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(Theme.textSecondary)
            
            Text("Build 2024.11")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(Theme.textSecondary.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Settings Tab Button
struct SettingsTabButton: View {
    let tab: SettingsView.SettingsTab
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20)
                    .foregroundColor(isSelected ? .white : Theme.textSecondary)
                
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.primaryColor : Color.clear)
            )
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.primaryColor : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingLarge) {
            sectionHeader("Configurações Gerais")
            
            VStack(spacing: Theme.spacingMedium) {
                ToggleOption(
                    icon: "play.circle",
                    title: "Processar automaticamente",
                    subtitle: "Processar vídeos automaticamente ao serem carregados",
                    isOn: $settings.generalSettings.autoProcessVideos
                )
                
                ToggleOption(
                    icon: "folder",
                    title: "Manter arquivos originais",
                    subtitle: "Manter cópias dos arquivos de vídeo originais",
                    isOn: $settings.generalSettings.keepOriginalFiles
                )
                
                ToggleOption(
                    icon: "bell",
                    title: "Notificações",
                    subtitle: "Receber notificações quando o processamento for concluído",
                    isOn: $settings.generalSettings.enableNotifications
                )
                
                sliderSetting(
                    icon: "chart.line.downtrend.xyaxis",
                    title: "Taxa de Amostragem Padrão",
                    subtitle: "Número de amostras por segundo para processamento",
                    value: $settings.generalSettings.sampleRate,
                    range: 0.1...5.0,
                    step: 0.1,
                    format: "\(settings.generalSettings.sampleRate.formatted(precision: 1))x"
                )
                
                sliderSetting(
                    icon: "internaldrive",
                    title: "Tamanho Máximo do Cache",
                    subtitle: "Armazenamento máximo para dados em cache",
                    value: Binding(
                        get: { Double(settings.generalSettings.maxCacheSize) },
                        set: { settings.generalSettings.maxCacheSize = Int($0) }
                    ),
                    range: 100...5000,
                    step: 100,
                    format: "\(settings.generalSettings.maxCacheSize) MB"
                )
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(Theme.textPrimary)
    }
    
    private func sliderSetting(
        icon: String,
        title: String,
        subtitle: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.primaryColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Text(format)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Slider(value: value, in: range, step: step)
                .accentColor(Theme.primaryColor)
        }
        .padding()
        .modernCard()
    }
}

// MARK: - Export Settings
struct ExportSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingLarge) {
            sectionHeader("Configurações de Exportação")
            
            VStack(spacing: Theme.spacingMedium) {
                // Default Format
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc")
                            .foregroundColor(Theme.primaryColor)
                            .frame(width: 20)
                        
                        Text("Formato de Exportação Padrão")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                    }
                    
                    Picker("", selection: $settings.exportSettings.defaultFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .modernCard()
                
                // Data to Include
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(Theme.primaryColor)
                            .frame(width: 20)
                        
                        Text("Dados para Incluir")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        Toggle("Dados GPS", isOn: $settings.exportSettings.includeGPS)
                        Toggle("Dados de Movimento (IMU)", isOn: $settings.exportSettings.includeIMU)
                        Toggle("Dados da Câmera", isOn: $settings.exportSettings.includeCameraData)
                        Toggle("Compactar arquivos", isOn: $settings.exportSettings.compressionEnabled)
                        Toggle("Abrir após exportar", isOn: $settings.exportSettings.autoOpenAfterExport)
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
                .padding()
                .modernCard()
                
                // Formatting
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Theme.primaryColor)
                            .frame(width: 20)
                        
                        Text("Formatação")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        PickerSetting(
                            title: "Formato de Timestamp",
                            selection: $settings.exportSettings.timestampFormat
                        )
                        
                        PickerSetting(
                            title: "Formato de Coordenadas",
                            selection: $settings.exportSettings.coordinateFormat
                        )
                    }
                }
                .padding()
                .modernCard()
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(Theme.textPrimary)
    }
}

// MARK: - Appearance Settings
struct AppearanceSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingLarge) {
            sectionHeader("Aparência")
            
            VStack(spacing: Theme.spacingMedium) {
                // Theme
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundColor(Theme.primaryColor)
                            .frame(width: 20)
                        
                        Text("Tema e Cores")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        PickerSetting(
                            title: "Tema da Aplicação",
                            selection: $settings.appearanceSettings.theme
                        )
                        
                        PickerSetting(
                            title: "Cor de Destaque",
                            selection: $settings.appearanceSettings.accentColor
                        )
                        
                        PickerSetting(
                            title: "Tamanho da Fonte",
                            selection: $settings.appearanceSettings.fontSize
                        )
                    }
                }
                .padding()
                .modernCard()
                
                // Visualization
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundColor(Theme.primaryColor)
                            .frame(width: 20)
                        
                        Text("Visualização de Dados")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        PickerSetting(
                            title: "Estilo de Gráfico",
                            selection: $settings.appearanceSettings.chartStyle
                        )
                        
                        PickerSetting(
                            title: "Estilo de Mapa",
                            selection: $settings.appearanceSettings.mapStyle
                        )
                        
                        Toggle("Mostrar animações", isOn: $settings.appearanceSettings.showAnimations)
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
                .padding()
                .modernCard()
                
                // Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Visualização")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    
                    HStack {
                        ColorPreview(color: settings.appearanceSettings.accentColor.color)
                        FontSizePreview(size: settings.appearanceSettings.fontSize)
                        ChartStylePreview(style: settings.appearanceSettings.chartStyle)
                    }
                }
                .padding()
                .modernCard()
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(Theme.textPrimary)
    }
}

// MARK: - Advanced Settings
struct AdvancedSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showResetConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingLarge) {
            sectionHeader("Configurações Avançadas")
            
            VStack(spacing: Theme.spacingMedium) {
                // Debug
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "ladybug")
                            .foregroundColor(Theme.primaryColor)
                            .frame(width: 20)
                        
                        Text("Desenvolvimento")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        Toggle("Logs detalhados", isOn: .constant(false))
                        Toggle("Modo desenvolvedor", isOn: .constant(false))
                        Toggle("Exportar dados brutos", isOn: .constant(false))
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
                .padding()
                .modernCard()
                
                // Reset
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        
                        Text("Reinicialização")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Restaura as configurações padrão do aplicativo. Esta ação não pode ser desfeita.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        PrimaryButton(
                            title: "Restaurar Configurações Padrão",
                            icon: "arrow.counterclockwise"
                        ) {
                            showResetConfirmation = true
                        }
                    }
                }
                .padding()
                .modernCard()
                .alert("Restaurar Configurações?", isPresented: $showResetConfirmation) {
                    Button("Cancelar", role: .cancel) { }
                    Button("Restaurar", role: .destructive) {
                        resetToDefaults()
                    }
                } message: {
                    Text("Todas as suas configurações personalizadas serão perdidas. Esta ação não pode ser desfeita.")
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(Theme.textPrimary)
    }
    
    private func resetToDefaults() {
        settings.generalSettings = GeneralSettings()
        settings.exportSettings = ExportSettings()
        settings.appearanceSettings = AppearanceSettings()
    }
}

// MARK: - Supporting Components
struct PickerSetting<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            Picker("", selection: $selection) {
                if let type = T.self as? any CaseIterable.Type,
                   let cases = type.allCases as? any Collection {
                    ForEach(Array(cases) as! [T], id: \.self) { value in
                        Text(String(describing: value)).tag(value)
                    }
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)
        }
    }
}

struct ColorPreview: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            Text("Cor")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(width: 60)
    }
}

struct FontSizePreview: View {
    let size: FontSize
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Aa")
                .font(.system(size: size.size + 4, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
            
            Text("Texto")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(width: 60)
    }
}

struct ChartStylePreview: View {
    let style: ChartStyle
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Simulação de gráfico
                Path { path in
                    let points: [CGPoint]
                    switch style {
                    case .linear:
                        points = [
                            CGPoint(x: 5, y: 30),
                            CGPoint(x: 15, y: 10),
                            CGPoint(x: 25, y: 25),
                            CGPoint(x: 35, y: 5)
                        ]
                    case .smooth:
                        points = [
                            CGPoint(x: 5, y: 30),
                            CGPoint(x: 15, y: 10),
                            CGPoint(x: 25, y: 25),
                            CGPoint(x: 35, y: 5)
                        ]
                    case .stepped:
                        points = [
                            CGPoint(x: 5, y: 30),
                            CGPoint(x: 15, y: 30),
                            CGPoint(x: 15, y: 10),
                            CGPoint(x: 25, y: 10),
                            CGPoint(x: 25, y: 25),
                            CGPoint(x: 35, y: 25)
                        ]
                    default:
                        points = []
                    }
                    
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Theme.primaryColor, lineWidth: 2)
                .frame(width: 40, height: 40)
            }
            
            Text("Gráfico")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(width: 60)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .frame(width: 600, height: 700)
}
