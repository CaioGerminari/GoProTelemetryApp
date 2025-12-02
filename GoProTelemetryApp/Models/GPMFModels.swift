//
//  GPMFModels.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation

// MARK: - Errors
enum GPMFError: Error {
    case invalidData
    case parsingFailed
    case unsupportedFormat
    case fileAccessDenied
    case bufferAllocationError
}

// MARK: - Raw Data Structures (DTOs)
struct GPMFStream {
    let type: GPMFStreamType
    let samples: [GPMFSample]
    let sampleCount: Int
    let elementsPerSample: Int
    let sampleRate: Double
}

struct GPMFSample {
    let timestamp: Double
    let values: [Double]
}

// MARK: - Metadata
struct GPMFStreamInfo: Identifiable {
    let id = UUID()
    let type: TelemetryType
    let fourCC: String
    let sampleCount: Int
    let frequency: Double
    
    init(from stream: GPMFStream) {
        self.type = stream.type.toTelemetryType()
        self.fourCC = stream.type.rawValue
        self.sampleCount = stream.sampleCount
        self.frequency = stream.sampleRate
    }
}

// MARK: - Video Info
struct VideoInfo {
    let duration: TimeInterval
    let creationDate: Date?
    let width: Int?
    let height: Int?
    let frameRate: Float?
    let fileSize: Int64?
    
    var resolutionString: String {
        guard let w = width, let h = height else { return "Desconhecida" }
        return "\(w)x\(h)"
    }
}

// MARK: - Enums & Types

/// Tipos de telemetria "Human Friendly" (Alto Nível)
enum TelemetryType: String, CaseIterable, Codable {
    case gps = "GPS"
    case accelerometer = "Acelerômetro"
    case gyroscope = "Giroscópio"
    case gravity = "Gravidade"
    case temperature = "Temperatura"    // Adicionado de volta
    case orientation = "Orientação"
    case camera = "Câmera"              // Renomeado de cameraSettings
    case environment = "Ambiente (IA)"  // Rosto, Cena
    case audio = "Áudio"
    case unknown = "Outros"
}

/// Tipos de FourCC (Códigos técnicos)
enum GPMFStreamType: String {
    // Principais
    case gps5 = "GPS5"
    case gps9 = "GPS9"
    case accl = "ACCL"
    case gyro = "GYRO"
    
    // Secundários
    case grav = "GRAV"
    case temp = "TMPC"
    case cori = "CORI"
    case iori = "IORI"
    
    // Câmera
    case iso  = "ISO"
    case shut = "SHUT"
    case wbal = "WBAL"
    
    // IA
    case face = "FACE"
    case scen = "SCEN"
    
    // Áudio
    case wndm = "WNDM"
    case mwet = "MWET"
    
    // Metadata Global
    case devNm = "DVNM"
    
    case unknown = "UNKN"
    
    static func from(fourCC: String) -> GPMFStreamType {
        let clean = fourCC.trimmingCharacters(in: .whitespacesAndNewlines)
                          .replacingOccurrences(of: "\0", with: "")
                          .uppercased()
        
        return GPMFStreamType(rawValue: clean) ?? .unknown
    }
    
    func toTelemetryType() -> TelemetryType {
        switch self {
        case .gps5, .gps9: return .gps
        case .accl: return .accelerometer
        case .gyro: return .gyroscope
        case .grav: return .gravity
        case .temp: return .temperature     // Mapeado corretamente agora
        case .cori, .iori: return .orientation
        case .iso, .shut, .wbal: return .camera // Mapeado para .camera
        case .face, .scen: return .environment
        case .wndm, .mwet: return .audio
        default: return .unknown
        }
    }
}
