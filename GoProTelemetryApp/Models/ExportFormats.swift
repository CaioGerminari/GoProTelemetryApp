//
//  ExportFormats.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation

enum ExportFormat: String, CaseIterable, Codable {
    case csv = "CSV"
    case gpx = "GPX"
    case json = "JSON"
    case fcpxml = "FCPXML"
    case davinci = "DaVinci Resolve"
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .gpx: return "gpx"
        case .json: return "json"
        case .fcpxml: return "fcpxml"
        case .davinci: return "txt"
        }
    }
    
    var description: String {
        switch self {
        case .csv: return "Comma-separated values"
        case .gpx: return "GPS Exchange Format"
        case .json: return "JavaScript Object Notation"
        case .fcpxml: return "Final Cut Pro XML"
        case .davinci: return "DaVinci Resolve Telemetry"
        }
    }
}

struct ExportConfiguration: Codable {
    let format: ExportFormat
    let includeGPS: Bool
    let includeIMU: Bool
    let includeCamera: Bool
    let sampleRate: Double
    
    init(format: ExportFormat,
         includeGPS: Bool = true,
         includeIMU: Bool = true,
         includeCamera: Bool = false,
         sampleRate: Double = 1.0) {
        self.format = format
        self.includeGPS = includeGPS
        self.includeIMU = includeIMU
        self.includeCamera = includeCamera
        self.sampleRate = sampleRate
    }
}
