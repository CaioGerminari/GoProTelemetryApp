//
//  AppSettings.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import Combine
import SwiftUI

class AppSettings: ObservableObject {
    @Published var generalSettings: GeneralSettings
    @Published var exportSettings: ExportSettings
    @Published var appearanceSettings: AppearanceSettings
    @Published var advancedSettings: AdvancedSettings

    // Moved from extension: stored properties must live in the type declaration
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.generalSettings = GeneralSettings()
        self.exportSettings = ExportSettings()
        self.appearanceSettings = AppearanceSettings()
        self.advancedSettings = AdvancedSettings()
    }
    
    // MARK: - Reset Methods
    func resetToDefaults() {
        generalSettings = GeneralSettings()
        exportSettings = ExportSettings()
        appearanceSettings = AppearanceSettings()
        advancedSettings = AdvancedSettings()
    }
    
    func resetGeneralSettings() {
        generalSettings = GeneralSettings()
    }
    
    func resetExportSettings() {
        exportSettings = ExportSettings()
    }
    
    func resetAppearanceSettings() {
        appearanceSettings = AppearanceSettings()
    }
    
    func resetAdvancedSettings() {
        advancedSettings = AdvancedSettings()
    }
}

// MARK: - General Settings
struct GeneralSettings: Codable {
    var autoProcessVideos: Bool = true
    var keepOriginalFiles: Bool = true
    var defaultOutputDirectory: String = ""
    var maxCacheSize: Int = 1000 // MB
    var enableNotifications: Bool = true
    var sampleRate: Double = 1.0
    var autoSaveSession: Bool = false
    var promptBeforeOverwrite: Bool = true
    
    // Performance
    var enableHardwareAcceleration: Bool = true
    var maxConcurrentProcesses: Int = 2
    var memoryUsageLimit: Int = 512 // MB
}

// MARK: - Export Settings
struct ExportSettings: Codable {
    var defaultFormat: ExportFormat = .csv
    var includeGPS: Bool = true
    var includeIMU: Bool = true
    var includeCameraData: Bool = false
    var includeMetadata: Bool = true
    var timestampFormat: TimestampFormat = .relative
    var coordinateFormat: CoordinateFormat = .decimal
    var autoOpenAfterExport: Bool = false
    var compressionEnabled: Bool = true
    var exportPreview: Bool = true
    
    // Quality settings
    var exportQuality: ExportQuality = .high
    var includeThumbnails: Bool = false
    var customFileNameTemplate: String = "{device}_{date}_{time}"
}

// MARK: - Appearance Settings
struct AppearanceSettings: Codable {
    var theme: AppTheme = .dark
    var accentColor: AccentColor = .blue
    var chartStyle: ChartStyle = .linear
    var mapStyle: MapStyle = .hybrid
    var showAnimations: Bool = true
    var fontSize: FontSize = .medium
    var reduceMotion: Bool = false
    var highContrast: Bool = false
    
    // Layout
    var sidebarPosition: SidebarPosition = .leading
    var compactMode: Bool = false
    var showGridLines: Bool = true
    var dataPointDensity: DataPointDensity = .normal
}

// MARK: - Advanced Settings
struct AdvancedSettings: Codable {
    // Debug
    var enableDebugLogs: Bool = false
    var developerMode: Bool = false
    var exportRawData: Bool = false
    var showPerformanceMetrics: Bool = false
    
    // Processing
    var enableExperimentalFeatures: Bool = false
    var customGPMFPath: String = ""
    var forceSoftwareDecoding: Bool = false
    var preserveTimestamps: Bool = true
    
    // Security
    var allowUntrustedSources: Bool = false
    var clearCacheOnExit: Bool = false
}

// MARK: - Settings Container for Codable
struct AppSettingsContainer: Codable {
    let generalSettings: GeneralSettings
    let exportSettings: ExportSettings
    let appearanceSettings: AppearanceSettings
    let advancedSettings: AdvancedSettings
    
    init(from settings: AppSettings) {
        self.generalSettings = settings.generalSettings
        self.exportSettings = settings.exportSettings
        self.appearanceSettings = settings.appearanceSettings
        self.advancedSettings = settings.advancedSettings
    }
    
    func apply(to settings: AppSettings) {
        settings.generalSettings = generalSettings
        settings.exportSettings = exportSettings
        settings.appearanceSettings = appearanceSettings
        settings.advancedSettings = advancedSettings
    }
}

// MARK: - Enums
enum AppTheme: String, CaseIterable, Codable {
    case dark = "Escuro"
    case light = "Claro"
    case auto = "Automático"
    case system = "Sistema"
    
    var systemColorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .auto, .system: return nil
        }
    }
    
    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .auto: return "circle.lefthalf.filled"
        case .system: return "gearshape.fill"
        }
    }
}

enum AccentColor: String, CaseIterable, Codable {
    case blue = "Azul"
    case green = "Verde"
    case orange = "Laranja"
    case purple = "Roxo"
    case red = "Vermelho"
    case teal = "Verde-azulado"
    case indigo = "Índigo"
    case yellow = "Amarelo"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        case .yellow: return .yellow
        }
    }
    
    var themeColor: Color {
        switch self {
        case .blue: return Theme.primaryColor
        case .green: return Theme.successColor
        case .orange: return Theme.warningColor
        case .purple: return .purple
        case .red: return Theme.errorColor
        case .teal: return .teal
        case .indigo: return .indigo
        case .yellow: return .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .blue: return "paintbrush.fill"
        case .green: return "leaf.fill"
        case .orange: return "flame.fill"
        case .purple: return "sparkles"
        case .red: return "heart.fill"
        case .teal: return "drop.fill"
        case .indigo: return "moon.stars.fill"
        case .yellow: return "sun.max.fill"
        }
    }
}

enum TimestampFormat: String, CaseIterable, Codable {
    case relative = "Relativo"
    case absolute = "Absoluto"
    case both = "Ambos"
    case custom = "Personalizado"
    
    var icon: String {
        switch self {
        case .relative: return "clock.arrow.2.circlepath"
        case .absolute: return "calendar"
        case .both: return "clock.badge.checkmark"
        case .custom: return "pencil"
        }
    }
}

enum CoordinateFormat: String, CaseIterable, Codable {
    case decimal = "Decimal"
    case dms = "Graus, Minutos, Segundos"
    case utm = "UTM"
    case mgrs = "MGRS"
    
    var icon: String {
        switch self {
        case .decimal: return "number"
        case .dms: return "location.circle"
        case .utm: return "grid"
        case .mgrs: return "squareshape.split.3x3"
        }
    }
}

enum ChartStyle: String, CaseIterable, Codable {
    case linear = "Linear"
    case smooth = "Suavizado"
    case stepped = "Escalonado"
    case bars = "Barras"
    
    var icon: String {
        switch self {
        case .linear: return "chart.line.uptrend.xyaxis"
        case .smooth: return "waveform.path.ecg"
        case .stepped: return "chart.line.flattrend.xyaxis"
        case .bars: return "chart.bar"
        }
    }
}

enum MapStyle: String, CaseIterable, Codable {
    case standard = "Padrão"
    case hybrid = "Híbrido"
    case satellite = "Satélite"
    case terrain = "Terreno"
    
    var icon: String {
        switch self {
        case .standard: return "map"
        case .hybrid: return "map.circle"
        case .satellite: return "globe"
        case .terrain: return "mountain.2"
        }
    }
}

enum FontSize: String, CaseIterable, Codable {
    case small = "Pequeno"
    case medium = "Médio"
    case large = "Grande"
    case xlarge = "Extra Grande"
    
    var size: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        case .xlarge: return 18
        }
    }
    
    var titleSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 18
        case .large: return 20
        case .xlarge: return 24
        }
    }
    
    var icon: String {
        switch self {
        case .small: return "textformat.size.smaller"
        case .medium: return "textformat.size"
        case .large: return "textformat.size.larger"
        case .xlarge: return "textformat.size.extraLarge"
        }
    }
}

enum ExportQuality: String, CaseIterable, Codable {
    case low = "Baixa"
    case medium = "Média"
    case high = "Alta"
    case maximum = "Máxima"
    
    var icon: String {
        switch self {
        case .low: return "speedometer"
        case .medium: return "gauge"
        case .high: return "gauge.high"
        case .maximum: return "chart.line.uptrend.xyaxis"
        }
    }
}

enum SidebarPosition: String, CaseIterable, Codable {
    case leading = "Esquerda"
    case trailing = "Direita"
    case bottom = "Inferior"
    case hidden = "Oculto"
    
    var icon: String {
        switch self {
        case .leading: return "sidebar.left"
        case .trailing: return "sidebar.right"
        case .bottom: return "rectangle.bottomthird.inset.filled"
        case .hidden: return "eye.slash"
        }
    }
}

enum DataPointDensity: String, CaseIterable, Codable {
    case low = "Baixa"
    case normal = "Normal"
    case high = "Alta"
    case maximum = "Máxima"
    
    var sampleRate: Double {
        switch self {
        case .low: return 0.5
        case .normal: return 1.0
        case .high: return 2.0
        case .maximum: return 5.0
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "circle.grid.2x2"
        case .normal: return "circle.grid.3x3"
        case .high: return "circle.grid.3x3.fill"
        case .maximum: return "circle.grid.3x3.circle.fill"
        }
    }
}

// MARK: - Settings Extensions
extension AppSettings {
    var shouldUseDarkMode: Bool {
        switch appearanceSettings.theme {
        case .dark: return true
        case .light: return false
        case .auto: return true // Default to dark for this app
        case .system: return true
        }
    }
    
    var currentAccentColor: Color {
        return appearanceSettings.accentColor.themeColor
    }
    
    var effectiveFontSize: CGFloat {
        return appearanceSettings.fontSize.size
    }
    
    var effectiveTitleFontSize: CGFloat {
        return appearanceSettings.fontSize.titleSize
    }
}

extension GeneralSettings {
    var formattedCacheSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        return formatter.string(fromByteCount: Int64(maxCacheSize) * 1024 * 1024)
    }
    
    var formattedSampleRate: String {
        return "\(sampleRate.formatted(precision: 1))x"
    }
}

extension ExportSettings {
    var formattedFileName: String {
        return customFileNameTemplate
            .replacingOccurrences(of: "{device}", with: "GoPro")
            .replacingOccurrences(of: "{date}", with: Date().formattedForFileName())
            .replacingOccurrences(of: "{time}", with: Date().formatted(date: .omitted, time: .shortened))
    }
}

// MARK: - UserDefaults Integration
extension AppSettings {
    private static let userDefaultsKey = "com.gopro.telemetry.settings"
    
    func saveToUserDefaults() {
        let container = AppSettingsContainer(from: self)
        if let encoded = try? JSONEncoder().encode(container) {
            UserDefaults.standard.set(encoded, forKey: AppSettings.userDefaultsKey)
        }
    }
    
    static func loadFromUserDefaults() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let container = try? JSONDecoder().decode(AppSettingsContainer.self, from: data) else {
            return AppSettings()
        }
        
        let settings = AppSettings()
        container.apply(to: settings)
        return settings
    }
}

// MARK: - Preview Helper
extension AppSettings {
    static var preview: AppSettings {
        let settings = AppSettings()
        
        // Configure preview settings
        settings.generalSettings.autoProcessVideos = false
        settings.exportSettings.defaultFormat = .gpx
        settings.appearanceSettings.accentColor = .purple
        settings.advancedSettings.developerMode = true
        
        return settings
    }
}

// MARK: - Auto-save Extension
extension AppSettings {
    func enableAutoSave() {
        // Save when any published property changes
        objectWillChange
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveToUserDefaults()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AppSettings.preview)
        .frame(width: 600, height: 700)
}
