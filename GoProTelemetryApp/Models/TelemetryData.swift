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
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
    let speed2D: Double?
    let speed3D: Double?
    
    // MARK: - Sensores Inerciais (IMU)
    var acceleration: Vector3? // Acelerômetro (Força G)
    var gravity: Vector3?      // Vetor de Gravidade
    var gyro: Vector3?         // Giroscópio (Rotação rad/s)
    
    // MARK: - Orientação (Spatial)
    var cameraOrientation: Vector4? // Quaternião (CORI)
    var imageOrientation: Vector4?  // (IORI)
    
    // MARK: - Câmera & Fotografia
    var iso: Double?           // Sensibilidade
    var shutterSpeed: Double?  // Tempo de exposição (s)
    var whiteBalance: Double?  // Kelvin
    var whiteBalanceRGB: Vector3? // Ganhos RGB
    
    // MARK: - Ambiente
    var temperature: Double?   // Celsius
    var audioDiagnostic: AudioDiagnostic? // Vento/Água
    
    // MARK: - Inteligência (IA)
    var faces: [DetectedFace]? // Rostos detectados
    var scene: String?         // Classificação (ex: "Snow", "Underwater")
    
    // MARK: - Propriedades Computadas (UI Helpers)
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude, abs(lat) > 0.001, abs(lon) > 0.001 else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var distanceAccumulated: Double = 0.0
    
    // -- Formatadores de Texto --
    
    var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = self.timestamp >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: timestamp) ?? String(format: "%.0fs", timestamp)
    }
    
    var formattedSpeed: String {
        guard let s = speed2D else { return "-" }
        return String(format: "%.1f km/h", s * 3.6)
    }
    
    var formattedShutter: String {
        guard let s = shutterSpeed, s > 0 else { return "-" }
        if s < 1.0 {
            let denominator = Int(round(1.0 / s))
            return "1/\(denominator)"
        }
        return String(format: "%.1f\"", s)
    }
    
    var formattedISO: String {
        guard let i = iso else { return "-" }
        return String(format: "%.0f", i)
    }
    
    var formattedTemp: String {
        guard let t = temperature else { return "-" }
        return String(format: "%.0f°C", t)
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

/// Estrutura para Quaterniões (Rotação 3D) com helpers de Euler
struct Vector4: Hashable, Codable {
    let w: Double
    let x: Double
    let y: Double
    let z: Double
    
    // MARK: - Math Helpers (Euler Angles)
    // Converte o quaternion para ângulos legíveis para UI (Horizonte Artificial)
    
    /// Rotação no eixo Z (Inclinação lateral) em Graus
    var rollDegrees: Double {
        let sinr_cosp = 2 * (w * z + x * y)
        let cosr_cosp = 1 - 2 * (y * y + z * z)
        return atan2(sinr_cosp, cosr_cosp) * 180 / .pi
    }
    
    /// Rotação no eixo X (Inclinação frente/trás) em Graus
    var pitchDegrees: Double {
        let sinp = 2 * (w * y - z * x)
        if abs(sinp) >= 1 {
            return sinp > 0 ? 90 : -90
        } else {
            return asin(sinp) * 180 / .pi
        }
    }
    
    /// Fator de inclinação normalizado (-1.0 a 1.0) para animações de UI
    var pitchFactor: Double {
        let sinp = 2 * (w * y - z * x)
        // Clampa entre -1 e 1
        return max(-1, min(1, sinp))
    }
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
    let cameraModel: String?
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
    
    // Estatísticas Avançadas
    let detectedScenes: [String] // Ex: ["Snow", "Beach"]
    let audioIssuesCount: Int    // Frames com vento excessivo
    let maxTemperature: Double
    
    // Novos
    let minISO: Double
    let maxISO: Double
    let avgWB: Double
    
    static let empty = TelemetryStatistics(
        duration: 0, totalDistance: 0, maxSpeed: 0, avgSpeed: 0,
        maxAltitude: 0, minAltitude: 0, maxGForce: 0, cameraName: "Desconhecida",
        detectedScenes: [], audioIssuesCount: 0, maxTemperature: 0,
        minISO: 0, maxISO: 0, avgWB: 0
    )
}
