//
//  TelemetryData.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import CoreLocation

// MARK: - Main Data Point

/// Representa um "frame" de telemetria sincronizado.
/// O 'timestamp' é relativo ao início do vídeo.
struct TelemetryData: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Double
    
    // MARK: - Sensores de Navegação (GPS)
    // Opcionais pois podem falhar em túneis/interiores
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
    let speed2D: Double?
    let speed3D: Double?
    
    // MARK: - Sensores Inerciais (IMU - Alta Frequência)
    var acceleration: Vector3? // Acelerômetro (Força G Total)
    var gravity: Vector3?      // Vetor de Gravidade (Direção "Baixo")
    var gyro: Vector3?         // Giroscópio (Rotação)
    
    // MARK: - Orientação
    var cameraOrientation: Vector4? // Quaterniões (CORI)
    var imageOrientation: Vector4?  // (IORI)
    
    // MARK: - Configurações da Câmera (Cinematografia)
    var iso: Double?           // Sensibilidade
    var shutterSpeed: Double?  // Tempo de exposição (segundos)
    var whiteBalance: Double?  // Kelvin
    var whiteBalanceRGB: Vector3? // Ganhos RGB
    
    // MARK: - Ambiente & Diagnóstico
    var temperature: Double?   // Celsius
    var audioDiagnostic: AudioDiagnostic? // Vento/Água
    
    // MARK: - Inteligência (IA)
    var faces: [DetectedFace]? // Rostos detectados neste frame
    var scene: String?         // Classificação (ex: "Snow", "Underwater")
    
    // MARK: - Propriedades Computadas (Helpers UI)
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude, abs(lat) > 0.001, abs(lon) > 0.001 else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var distanceAccumulated: Double = 0.0
    
    var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: timestamp) ?? String(format: "%.1fs", timestamp)
    }
    
    var formattedSpeed: String {
        guard let s = speed2D else { return "-" }
        return String(format: "%.1f km/h", s * 3.6)
    }
    
    var formattedShutter: String {
        guard let s = shutterSpeed, s > 0 else { return "-" }
        let denominator = Int(round(1.0 / s))
        return "1/\(denominator)"
    }
    
    var formattedISO: String {
        guard let i = iso else { return "-" }
        return String(format: "%.0f", i)
    }
}

// MARK: - Helper Structures

struct Vector3: Hashable, Codable {
    let x: Double
    let y: Double
    let z: Double
    
    var magnitude: Double {
        sqrt(x*x + y*y + z*z)
    }
}

/// Estrutura para Quaterniões (Rotação 3D)
struct Vector4: Hashable, Codable {
    let w: Double
    let x: Double
    let y: Double
    let z: Double
}

struct DetectedFace: Hashable, Codable {
    let id: Int      // ID único para tracking
    let x: Double    // 0.0 a 1.0 (Posição relativa na imagem)
    let y: Double
    let w: Double
    let h: Double
}

struct AudioDiagnostic: Hashable, Codable {
    let windNoiseLevel: Double // 0.0 (Silêncio) a 1.0 (Muito vento)
    let isWet: Bool            // Microfone molhado?
}

// MARK: - Session & Statistics

struct TelemetrySession: Identifiable {
    let id = UUID()
    let videoUrl: URL
    let creationDate: Date
    let cameraModel: String? // Ex: "GoPro Hero 11 Black"
    let dataPoints: [TelemetryData]
    let statistics: TelemetryStatistics
}

struct TelemetryStatistics {
    let duration: TimeInterval
    let totalDistance: Double
    let maxSpeed: Double
    let avgSpeed: Double
    let maxAltitude: Double
    let minAltitude: Double
    let maxGForce: Double
    let cameraName: String
    
    // Novos resumos para Dashboard
    let detectedScenes: [String] // Lista única de cenas (ex: ["Praia", "Urbano"])
    let audioIssuesCount: Int    // Frames com problemas de áudio
    let maxTemperature: Double   // Pico de temperatura da câmera
    
    static let empty = TelemetryStatistics(
        duration: 0, totalDistance: 0, maxSpeed: 0, avgSpeed: 0,
        maxAltitude: 0, minAltitude: 0, maxGForce: 0, cameraName: "Desconhecida",
        detectedScenes: [], audioIssuesCount: 0, maxTemperature: 0
    )
}
