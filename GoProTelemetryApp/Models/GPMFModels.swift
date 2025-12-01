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

/// Representa um stream completo extraído do C (Ex: Todos os dados de GPS)
struct GPMFStream {
    let type: GPMFStreamType
    let samples: [GPMFSample]
    let sampleCount: Int
    let elementsPerSample: Int
    let sampleRate: Double
}

/// Representa um único ponto de amostra (Ex: Uma coordenada latitude/longitude/altitude)
struct GPMFSample {
    let timestamp: Double
    let values: [Double]
}

// MARK: - Metadata & Info Wrappers

/// Resumo informativo sobre um stream (Para exibir na lista de "Dados Brutos")
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

/// Metadados básicos do arquivo de vídeo
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
    case temperature = "Temperatura"
    case orientation = "Orientação"
    case camera = "Câmera"
    case unknown = "Outros"
}

/// Tipos de FourCC (Códigos de 4 caracteres da GoPro) - Baixo Nível
enum GPMFStreamType: String {
    // Sensores Principais
    case gps5 = "GPS5" // GPS (Lat, Lon, Alt, 2D Speed, 3D Speed)
    case gps9 = "GPS9" // GPS Hero 11+ (Mais precisão)
    case accl = "ACCL" // Acelerômetro
    case gyro = "GYRO" // Giroscópio
    
    // Sensores Secundários
    case temp = "TMPC" // Temperatura
    case grav = "GRAV" // Vetor de Gravidade
    case cori = "CORI" // Orientação da Câmera
    case iori = "IORI" // Orientação da Imagem
    case iso  = "ISO"  // ISO da Câmera
    case shutter = "SHUT" // Velocidade do Obturador
    
    case unknown = "UNKN"
    
    /// Converte string crua do C para Enum
    static func from(fourCC: String) -> GPMFStreamType {
        // Limpa espaços extras e nulos que podem vir do C
        let clean = fourCC.trimmingCharacters(in: .whitespacesAndNewlines)
                          .replacingOccurrences(of: "\0", with: "")
                          .uppercased()
        
        return GPMFStreamType(rawValue: clean) ?? .unknown
    }
    
    /// Mapeia o código técnico para o tipo legível
    func toTelemetryType() -> TelemetryType {
        switch self {
        case .gps5, .gps9: return .gps
        case .accl: return .accelerometer
        case .gyro: return .gyroscope
        case .temp: return .temperature
        case .grav, .cori, .iori: return .orientation
        case .iso, .shutter: return .camera
        default: return .unknown
        }
    }
}
