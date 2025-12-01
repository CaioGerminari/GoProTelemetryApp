//
//  AppSettings.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import Combine

// MARK: - Main Observable Store
class AppSettings: ObservableObject {
    // Public Properties
    @Published var general: GeneralSettings
    @Published var export: ExportSettings
    @Published var appearance: AppearanceSettings
    @Published var advanced: AdvancedSettings

    // Private
    private var cancellables = Set<AnyCancellable>()
    private static let userDefaultsKey = "com.gopro.telemetry.settings"
    
    init() {
        // Tenta carregar do disco, ou usa padrão
        if let saved = Self.loadFromDisk() {
            self.general = saved.generalSettings
            self.export = saved.exportSettings
            self.appearance = saved.appearanceSettings
            self.advanced = saved.advancedSettings
        } else {
            self.general = GeneralSettings()
            self.export = ExportSettings()
            self.appearance = AppearanceSettings()
            self.advanced = AdvancedSettings()
        }
        
        setupAutoSave()
    }
    
    // MARK: - Actions
    
    func resetToDefaults() {
        general = GeneralSettings()
        export = ExportSettings()
        appearance = AppearanceSettings()
        advanced = AdvancedSettings()
    }
    
    // MARK: - Persistence
    
    private func setupAutoSave() {
        // Salva automaticamente 1 segundo após qualquer mudança
        objectWillChange
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveToDisk()
            }
            .store(in: &cancellables)
    }
    
    private func saveToDisk() {
        let container = AppSettingsContainer(from: self)
        if let encoded = try? JSONEncoder().encode(container) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }
    
    private static func loadFromDisk() -> AppSettingsContainer? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let container = try? JSONDecoder().decode(AppSettingsContainer.self, from: data) else {
            return nil
        }
        return container
    }
}

// MARK: - Data Structures (Structs)

struct GeneralSettings: Codable {
    var autoProcessVideos: Bool = true
    var keepOriginalFiles: Bool = true
    var defaultOutputDirectory: String = ""
    var maxCacheSize: Int = 1000 // MB
    var enableNotifications: Bool = true
    var sampleRate: Double = 1.0
}

// MARK: - Export Settings
struct ExportSettings: Codable {
    // Formato do Arquivo (Usuário escolhe 1)
    var defaultFormat: ExportFormat = .gpx
    
    // Seleção de Dados (Usuário escolhe N)
    var includeGPS: Bool = true
    var includeAccelerometer: Bool = true
    var includeGyroscope: Bool = true
    var includeTemperature: Bool = false // Novo
    var includeOrientation: Bool = false // Novo (CORI/IORI)
    var includeCameraData: Bool = false  // ISO, Shutter, etc.
    
    // Outras configurações existentes...
    var includeMetadata: Bool = true
    var timestampFormat: TimestampFormat = .relative
    var coordinateFormat: CoordinateFormat = .decimal
    var customFileNameTemplate: String = "{device}_{date}_{time}"
    var exportQuality: ExportQuality = .high
}

struct AppearanceSettings: Codable {
    var theme: AppTheme = .dark
    var accentColor: AppAccentColor = .blue
    var chartStyle: ChartStyle = .linear
    var mapStyle: MapStyle = .hybrid
    var showAnimations: Bool = true
    var fontSize: FontSize = .medium
    var showGridLines: Bool = true
}

struct AdvancedSettings: Codable {
    var enableDebugLogs: Bool = false
    var developerMode: Bool = false
    var forceSoftwareDecoding: Bool = false
    var preserveTimestamps: Bool = true
    var clearCacheOnExit: Bool = false
}

// MARK: - Container for Persistence (Internal)
// Ajuda a salvar tudo de uma vez no UserDefaults
private struct AppSettingsContainer: Codable {
    let generalSettings: GeneralSettings
    let exportSettings: ExportSettings
    let appearanceSettings: AppearanceSettings
    let advancedSettings: AdvancedSettings
    
    init(from settings: AppSettings) {
        self.generalSettings = settings.general
        self.exportSettings = settings.export
        self.appearanceSettings = settings.appearance
        self.advancedSettings = settings.advanced
    }
}

// MARK: - Enums (Options)

enum AppTheme: String, CaseIterable, Codable {
    case dark = "Escuro"
    case light = "Claro"
    case auto = "Automático"
}

// Renomeado para evitar conflito com SwiftUI.AccentColor se importado errado
enum AppAccentColor: String, CaseIterable, Codable {
    case blue = "Azul"
    case green = "Verde"
    case orange = "Laranja"
    case purple = "Roxo"
    case red = "Vermelho"
    case teal = "Verde-azulado"
    case indigo = "Índigo"
    case yellow = "Amarelo"
}

enum TimestampFormat: String, CaseIterable, Codable {
    case relative = "Relativo"
    case absolute = "Absoluto"
    case both = "Ambos"
}

enum CoordinateFormat: String, CaseIterable, Codable {
    case decimal = "Decimal"
    case dms = "Graus, Minutos, Segundos"
    case utm = "UTM"
}

enum ChartStyle: String, CaseIterable, Codable {
    case linear = "Linear"
    case smooth = "Suavizado"
    case stepped = "Escalonado"
}

enum MapStyle: String, CaseIterable, Codable {
    case standard = "Padrão"
    case hybrid = "Híbrido"
    case satellite = "Satélite"
}

enum FontSize: String, CaseIterable, Codable {
    case small = "Pequeno"
    case medium = "Médio"
    case large = "Grande"
    
    // Lógica de tamanho de fonte é UI, mas valores numéricos crus (CGFloat)
    // podem ficar aqui se o model precisar calcular layout,
    // ou idealmente movidos para o Theme.swift.
    // Deixei simples por enquanto.
}

enum ExportQuality: String, CaseIterable, Codable {
    case low = "Baixa"
    case medium = "Média"
    case high = "Alta"
}
