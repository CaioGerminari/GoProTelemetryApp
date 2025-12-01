//
//  GPMFTelemetryMapper.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import CoreLocation

class GPMFTelemetryMapper {
    
    // MARK: - Public API
    
    /// Processa os streams brutos e retorna uma sessão completa pronta para uso.
    static func makeSession(from streams: [GPMFStream], videoUrl: URL) -> TelemetrySession {
        print("🔄 Iniciando mapeamento de telemetria...")
        
        // 1. Identificar Streams
        let gpsStream = streams.first { $0.type == .gps5 || $0.type == .gps9 }
        let acclStream = streams.first { $0.type == .accl }
        let gyroStream = streams.first { $0.type == .gyro }
        
        guard let primaryGPS = gpsStream else {
            print("❌ Erro: Nenhum stream de GPS encontrado.")
            return TelemetrySession(
                videoUrl: videoUrl,
                creationDate: Date(),
                dataPoints: [],
                statistics: .empty
            )
        }
        
        // 2. Processamento e Sincronização
        let dataPoints = processDataPoints(
            gps: primaryGPS,
            accl: acclStream,
            gyro: gyroStream
        )
        
        // 3. Gerar Estatísticas
        let statistics = calculateStatistics(points: dataPoints)
        
        print("✅ Sessão criada com \(dataPoints.count) pontos.")
        
        return TelemetrySession(
            videoUrl: videoUrl,
            creationDate: Date(), // Idealmente extraído dos metadados do vídeo
            dataPoints: dataPoints,
            statistics: statistics
        )
    }
    
    // MARK: - Core Processing
    
    /// Sincroniza dados de diferentes sensores usando o GPS como linha do tempo mestre.
    private static func processDataPoints(gps: GPMFStream, accl: GPMFStream?, gyro: GPMFStream?) -> [TelemetryData] {
        var points: [TelemetryData] = []
        var totalDistance: Double = 0.0
        var previousCoordinate: CLLocationCoordinate2D?
        
        // Otimização: Índices para busca rápida (evita percorrer o array inteiro a cada ponto)
        var acclIndex = 0
        var gyroIndex = 0
        
        for sample in gps.samples {
            // 1. Parse GPS
            guard let gpsData = parseGPS(sample, type: gps.type) else { continue }
            
            // Filtro básico de qualidade (ignora lat/lon 0.0 que é "buscando sinal")
            if gpsData.latitude == 0 && gpsData.longitude == 0 { continue }
            
            // 2. Calcular Distância Acumulada
            let currentCoord = CLLocationCoordinate2D(latitude: gpsData.latitude, longitude: gpsData.longitude)
            if let prev = previousCoordinate {
                let dist = prev.distance(to: currentCoord)
                // Filtro de ruído: Se moveu menos de 50cm em 0.05s (aprox), pode ser jitter do GPS parado
                if dist > 0.5 {
                    totalDistance += dist
                }
            }
            previousCoordinate = currentCoord
            
            // 3. Sincronizar Sensores (Encontrar amostra mais próxima no tempo)
            // Acelerômetro
            var acceleration: Vector3?
            if let stream = accl {
                if let (val, newIndex) = findNearestSample(targetTime: sample.timestamp, stream: stream, startIndex: acclIndex) {
                    acceleration = Vector3(x: val[0], y: val[1], z: val[2])
                    acclIndex = newIndex
                }
            }
            
            // Giroscópio
            var gyroscope: Vector3?
            if let stream = gyro {
                if let (val, newIndex) = findNearestSample(targetTime: sample.timestamp, stream: stream, startIndex: gyroIndex) {
                    gyroscope = Vector3(x: val[0], y: val[1], z: val[2])
                    gyroIndex = newIndex
                }
            }
            
            // 4. Criar Objeto Final
            let point = TelemetryData(
                timestamp: sample.timestamp,
                latitude: gpsData.latitude,
                longitude: gpsData.longitude,
                altitude: gpsData.altitude,
                speed2D: gpsData.speed2D,
                speed3D: gpsData.speed3D,
                acceleration: acceleration,
                gyro: gyroscope,
                distanceAccumulated: totalDistance
            )
            
            points.append(point)
        }
        
        return points
    }
    
    // MARK: - Helpers & Parsers
    
    /// Extrai dados específicos dependendo da versão do GPS (Hero 5-10 vs Hero 11+)
    private static func parseGPS(_ sample: GPMFSample, type: GPMFStreamType) -> (latitude: Double, longitude: Double, altitude: Double, speed2D: Double, speed3D: Double)? {
        let v = sample.values
        
        if type == .gps5 {
            // GPS5: lat, lon, alt, speed2d, speed3d
            guard v.count >= 5 else { return nil }
            return (v[0], v[1], v[2], v[3], v[4])
        } else if type == .gps9 {
            // GPS9: lat, lon, alt, speed2d, speed3d, days, secs, dop, fix
            guard v.count >= 5 else { return nil }
            return (v[0], v[1], v[2], v[3], v[4])
        }
        
        return nil
    }
    
    /// Algoritmo eficiente para encontrar a amostra de sensor mais próxima do timestamp do GPS.
    /// Retorna: (Valores, Novo Índice Otimizado)
    private static func findNearestSample(targetTime: Double, stream: GPMFStream, startIndex: Int) -> ([Double], Int)? {
        let samples = stream.samples
        guard startIndex < samples.count else { return nil }
        
        var bestIndex = startIndex
        var minDiff = abs(samples[startIndex].timestamp - targetTime)
        
        // Procura para frente a partir do último índice conhecido
        for i in startIndex..<samples.count {
            let diff = abs(samples[i].timestamp - targetTime)
            
            if diff < minDiff {
                minDiff = diff
                bestIndex = i
            } else if diff > minDiff {
                // Se a diferença começou a aumentar, já passamos do ponto ideal (os arrays são ordenados por tempo)
                // Podemos parar de procurar.
                break
            }
        }
        
        // Verifica se a amostra encontrada é válida (dentro de uma janela de 0.2s)
        // Se estiver muito longe, o sensor pode ter parado de gravar ou o vídeo pulou.
        if minDiff > 0.2 { return nil }
        
        return (samples[bestIndex].values, bestIndex)
    }
    
    // MARK: - Statistics Calculation
    
    private static func calculateStatistics(points: [TelemetryData]) -> TelemetryStatistics {
        guard !points.isEmpty else { return .empty }
        
        let duration = points.last?.timestamp ?? 0
        let totalDistance = points.last?.distanceAccumulated ?? 0
        
        // Cálculos usando funções de alta ordem (map/reduce)
        let maxSpeed = points.map { $0.speed2D }.max() ?? 0
        let avgSpeed = points.map { $0.speed2D }.reduce(0, +) / Double(points.count)
        
        let altitudes = points.map { $0.altitude }
        let maxAlt = altitudes.max() ?? 0
        let minAlt = altitudes.min() ?? 0
        
        // Força G Máxima (Magnitude da aceleração)
        // Normalizamos subtraindo 1G (9.8m/s²) da gravidade se necessário,
        // mas GPMF geralmente entrega bruto. Vamos pegar o max magnitude.
        let maxG = points.compactMap { $0.acceleration?.magnitude }.max() ?? 0
        
        return TelemetryStatistics(
            duration: duration,
            totalDistance: totalDistance,
            maxSpeed: maxSpeed,
            avgSpeed: avgSpeed,
            maxAltitude: maxAlt,
            minAltitude: minAlt,
            maxGForce: maxG
        )
    }
}

// MARK: - Extensions

fileprivate extension CLLocationCoordinate2D {
    /// Calcula distância em metros entre duas coordenadas (Haversine simplificado via CoreLocation)
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }
}
