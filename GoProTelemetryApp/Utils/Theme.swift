//
//  Theme.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI
import AppKit

struct Theme {
    
    // MARK: - Neon Palette (Liquid Tints)
    // Cores vibrantes projetadas para "brilhar" dentro dos componentes de vidro
    
    struct Colors {
        static let neonBlue = Color(red: 0.0, green: 0.8, blue: 1.0)      // Ciano Elétrico
        static let neonPurple = Color(red: 0.7, green: 0.3, blue: 1.0)    // Roxo Fluorescente
        static let neonOrange = Color(red: 1.0, green: 0.6, blue: 0.0)    // Laranja Neon
        static let neonRed = Color(red: 1.0, green: 0.2, blue: 0.3)       // Vermelho Laser
        static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.5)     // Verde Matrix
        static let neonYellow = Color(red: 1.0, green: 0.9, blue: 0.0)    // Amarelo Sol
        static let neonIndigo = Color(red: 0.4, green: 0.0, blue: 1.0)    // Índigo Profundo
        static let glassWhite = Color.white.opacity(0.9)
    }
    
    // MARK: - Semantic Colors
    
    static let primary = Colors.neonBlue
    static let secondary = Color.gray.opacity(0.8)
    
    // Cores de Status
    static let success = Colors.neonGreen
    static let warning = Colors.neonOrange
    static let error = Colors.neonRed
    
    // Backgrounds (Para janelas que precisam de um fundo base atrás do vidro)
    static let background = Color(nsColor: .windowBackgroundColor)
    static let surface = Color.clear // LiquidGlass usa blur, não cor sólida
    
    // MARK: - Sensor Styling (Atualizado)
    
    struct Data {
        static func color(for type: TelemetryType) -> Color {
            switch type {
            case .gps: return Colors.neonBlue
            case .accelerometer: return Colors.neonOrange
            case .gyroscope: return Colors.neonIndigo
            case .gravity: return Color.pink
            case .orientation: return Colors.neonPurple
            case .temperature: return Colors.neonRed
            case .camera: return Colors.neonYellow
            case .environment: return Colors.neonGreen
            case .audio: return Color.teal
            case .unknown: return Color.gray
            }
        }
        
        static func icon(for type: TelemetryType) -> String {
            switch type {
            case .gps: return "location.fill"
            case .accelerometer: return "speedometer"
            case .gyroscope: return "gyroscope"
            case .gravity: return "arrow.down.to.line.compact"
            case .orientation: return "safari.fill"
            case .temperature: return "thermometer.sun.fill"
            case .camera: return "camera.aperture"
            case .environment: return "sparkles"
            case .audio: return "waveform.path"
            case .unknown: return "questionmark.square.dashed"
            }
        }
    }
    
    // MARK: - Export Styling
    
    struct Export {
        static func icon(for format: ExportFormat) -> String {
            switch format {
            case .gpx: return "map"
            case .kml: return "globe.americas.fill"
            case .csv: return "tablecells"
            case .json: return "curlybraces"
            case .mgjson: return "film.fill"
            }
        }
        
        static func color(for format: ExportFormat) -> Color {
            switch format {
            case .mgjson: return Colors.neonPurple
            case .kml: return Colors.neonGreen
            case .csv: return Colors.neonOrange
            default: return Colors.neonBlue
            }
        }
    }
    
    // MARK: - Layout & Fonts (Modernizado)
    
    static let padding: CGFloat = 20
    static let cornerRadius: CGFloat = 20 // Mais arredondado (Squircle)
    static let smallCornerRadius: CGFloat = 12
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 40
    }
    
    // Sombras agora são coloridas (glow), definido no GlassModifier
    static let shadowRadius: CGFloat = 10
    static let shadowColor = Color.black.opacity(0.2)
    
    struct Font {
        // Tipografia arredondada para números e títulos (Friendly/Modern)
        static let valueLarge = SwiftUI.Font.system(size: 32, weight: .bold, design: .rounded)
        static let valueMedium = SwiftUI.Font.system(size: 20, weight: .semibold, design: .rounded)
        static let label = SwiftUI.Font.caption.weight(.semibold)
        
        // Mono para dados técnicos precisos (Lat/Lon, ISO)
        static let mono = SwiftUI.Font.system(.body, design: .monospaced)
        
        static let title = SwiftUI.Font.title2.weight(.bold)
        static let display = SwiftUI.Font.system(size: 48, weight: .heavy, design: .rounded)
    }
}

// MARK: - UI Extensions

extension AppTheme {
    var systemColorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light // LiquidGlass funciona melhor no Dark, mas suporta Light
        case .auto: return nil
        }
    }
}
