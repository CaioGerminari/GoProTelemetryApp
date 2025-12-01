//
//  TelemetryData.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import CoreLocation

// MARK: - Main Data Point
/// Representa um único "frame" de dados de telemetria sincronizados.
/// Usado em Listas, Gráficos e Mapas.
struct TelemetryData: Identifiable, Hashable {
    let id = UUID()
    
    /// Tempo relativo ao início do vídeo (em segundos)
    let timestamp: Double
    
    // MARK: - GPS Data
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let speed2D: Double // Velocidade horizontal (m/s)
    let speed3D: Double // Velocidade tridimensional (m/s)
    
    // MARK: - Sensors (Opcionais)
    var acceleration: Vector3? // Acelerômetro (m/s²)
    var gyro: Vector3?        // Giroscópio (rad/s)
    
    // MARK: - Computed Properties (Helpers para UI)
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Distância acumulada até este ponto (preenchido pelo Mapper)
    var distanceAccumulated: Double = 0.0
    
    // Formatadores estáticos para performance em Listas
    private static let timeFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.zeroFormattingBehavior = .pad
        return f
    }()
    
    var formattedTime: String {
        return TelemetryData.timeFormatter.string(from: timestamp) ?? String(format: "%.1fs", timestamp)
    }
    
    var formattedSpeed: String {
        return String(format: "%.1f km/h", speed2D * 3.6)
    }
    
    var formattedAltitude: String {
        return String(format: "%.0f m", altitude)
    }
}

// MARK: - Helper Structures

/// Estrutura auxiliar para dados vetoriais (IMU)
struct Vector3: Hashable, Codable {
    let x: Double
    let y: Double
    let z: Double
    
    /// Magnitude do vetor (útil para força G total)
    var magnitude: Double {
        sqrt(x*x + y*y + z*z)
    }
}

// MARK: - Session & Statistics

/// Representa a sessão completa de um vídeo processado
struct TelemetrySession: Identifiable {
    let id = UUID()
    let videoUrl: URL
    let creationDate: Date
    let dataPoints: [TelemetryData]
    let statistics: TelemetryStatistics
}

/// Estatísticas sumarizadas (Calculadas pelo Mapper, apenas armazenadas aqui)
struct TelemetryStatistics {
    let duration: TimeInterval
    let totalDistance: Double // Metros
    let maxSpeed: Double      // m/s
    let avgSpeed: Double      // m/s
    let maxAltitude: Double   // Metros
    let minAltitude: Double   // Metros
    let maxGForce: Double     // G
    
    // Placeholder para sessão vazia
    static let empty = TelemetryStatistics(
        duration: 0,
        totalDistance: 0,
        maxSpeed: 0,
        avgSpeed: 0,
        maxAltitude: 0,
        minAltitude: 0,
        maxGForce: 0
    )
}
