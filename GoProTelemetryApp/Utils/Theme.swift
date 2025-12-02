//
//  Theme.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI
import AppKit

struct Theme {
    
    // MARK: - Colors
    
    static let primary = Color.blue
    static let secondary = Color.gray
    
    // Cores de Fundo do Sistema
    static let background = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let surfaceSecondary = Color(nsColor: .underPageBackgroundColor)
    
    // Cores de Status
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // MARK: - Sensor Styling (CORREÇÃO AQUI)
    
    struct Data {
        static func color(for type: TelemetryType) -> Color {
            switch type {
            case .gps: return .blue
            case .accelerometer: return .orange
            case .gyroscope: return .purple
            case .gravity: return .pink           // Novo
            case .orientation: return .indigo     // Novo
            case .temperature: return .red        // Novo
            case .camera: return .teal    // Renomeado de 'camera'
            case .environment: return .green      // Novo (Rosto/Cena)
            case .audio: return .yellow           // Novo
            case .unknown: return .gray
            }
        }
        
        static func icon(for type: TelemetryType) -> String {
            switch type {
            case .gps: return "location.fill"
            case .accelerometer: return "gauge.with.dots.needle.bottom.50percent"
            case .gyroscope: return "gyroscope"
            case .gravity: return "arrow.down.to.line"
            case .orientation: return "safari.fill"
            case .temperature: return "thermometer"
            case .camera: return "camera.aperture"
            case .environment: return "tree.fill"
            case .audio: return "waveform"
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
            case .mgjson: return .purple
            case .kml: return .green
            default: return .blue
            }
        }
    }
    
    // MARK: - Layout & Fonts
    
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }
    
    static let shadowRadius: CGFloat = 4
    static let shadowColor = Color.black.opacity(0.1)
    
    struct Font {
        static let valueLarge = SwiftUI.Font.system(size: 28, weight: .bold, design: .rounded)
        static let valueMedium = SwiftUI.Font.system(size: 18, weight: .semibold, design: .rounded)
        static let label = SwiftUI.Font.caption.weight(.medium)
        static let mono = SwiftUI.Font.system(.body, design: .monospaced)
        static let title = SwiftUI.Font.title3.weight(.bold)
    }
}

// MARK: - View Modifiers

extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.surface)
            .cornerRadius(Theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Theme.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    func badgeStyle(color: Color) -> some View {
        self
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// MARK: - AppTheme UI Extension

extension AppTheme {
    var systemColorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .auto: return nil
        }
    }
}
