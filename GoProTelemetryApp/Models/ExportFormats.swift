//
//  ExportFormats.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation

// MARK: - Supported Formats

enum ExportFormat: String, CaseIterable, Codable, Identifiable {
    case gpx = "GPX"
    case kml = "KML"
    case csv = "CSV"
    case json = "JSON"
    case mgjson = "MGJSON"
    
    // Identifiable para SwiftUI
    var id: String { rawValue }
    
    // Nome para exibição na UI
    var displayName: String {
        switch self {
        case .gpx: return "GPX (GPS Exchange)"
        case .kml: return "KML (Google Earth)"
        case .csv: return "CSV (Excel/Numbers)"
        case .json: return "JSON (Raw Data)"
        case .mgjson: return "MGJSON (After Effects)"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .gpx: return "gpx"
        case .kml: return "kml"
        case .csv: return "csv"
        case .json: return "json"
        case .mgjson: return "mgjson"
        }
    }
    
    var description: String {
        switch self {
        case .gpx: return "Padrão universal para GPS. Compatível com Garmin, Strava e maioria dos softwares."
        case .kml: return "Formato nativo do Google Earth para visualização de trajetos em 3D."
        case .csv: return "Planilha simples com colunas. Ideal para análise de dados ou importação manual."
        case .json: return "Estrutura de dados para desenvolvedores ou scripts de automação."
        case .mgjson: return "Formato da Adobe para criar overlays de dados dinâmicos no After Effects."
        }
    }
    
    // Define se o formato suporta apenas GPS ou dados completos de sensores
    var supportsFullTelemetry: Bool {
        switch self {
        case .gpx, .kml: return false // Geralmente focado apenas em GPS
        case .csv, .json, .mgjson: return true // Pode conter Giroscópio, Acelerômetro, etc.
        }
    }
}

// MARK: - Export Configuration Object

/// Objeto transferido para o ExportService contendo todas as regras
struct ExportConfiguration: Codable {
    let format: ExportFormat
    let includeGPS: Bool
    let includeIMU: Bool    // Acelerômetro/Giroscópio
    let includeCameraData: Bool // ISO, Shutter, WB
    let sampleRate: Double  // Frequência de amostragem (ex: 1.0 = todos os pontos, 0.5 = metade)
    let customFileName: String?
    
    init(format: ExportFormat,
         includeGPS: Bool = true,
         includeIMU: Bool = true,
         includeCameraData: Bool = false,
         sampleRate: Double = 1.0,
         customFileName: String? = nil) {
        
        self.format = format
        self.includeGPS = includeGPS
        self.includeIMU = includeIMU
        self.includeCameraData = includeCameraData
        self.sampleRate = sampleRate
        self.customFileName = customFileName
    }
    
    // Configuração padrão segura
    static let standard = ExportConfiguration(format: .gpx)
}
