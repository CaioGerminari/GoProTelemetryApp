//
//  GPMFTelemetryMapper.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import CoreLocation

class GPMFTelemetryMapper {
    
    // MARK: - Public Methods
    
    /// Mapeia streams GPMF para pontos de telemetria
    static func mapToTelemetryDataPoints(_ streams: [GPMFStream]) -> [TelemetryDataPoint] {
        print("🔄 Mapeando \(streams.count) streams GPMF para telemetria...")
        
        var allPoints: [TelemetryDataPoint] = []
        
        // Encontrar o stream principal (geralmente GPS para timestamps)
        guard let primaryStream = findPrimaryStream(streams) else {
            print("❌ Nenhum stream principal encontrado")
            return []
        }
        
        print("🎯 Stream principal: \(primaryStream.type.rawValue) com \(primaryStream.sampleCount) amostras")
        
        // Para cada amostra no stream principal, criar um ponto de telemetria
        for (index, primarySample) in primaryStream.samples.enumerated() {
            let point = createTelemetryDataPoint(
                from: primarySample,
                streams: streams,
                sampleIndex: index
            )
            allPoints.append(point)
        }
        
        print("✅ Mapeamento concluído: \(allPoints.count) pontos criados")
        return allPoints
    }
    
    // MARK: - Private Methods
    
    /// Encontra o stream principal para usar como referência temporal
    private static func findPrimaryStream(_ streams: [GPMFStream]) -> GPMFStream? {
        // Prioridade: GPS > Acelerômetro > Giroscópio > Outros
        let prioritizedStreams = streams.sorted { stream1, stream2 in
            let priority1 = streamPriority(stream1.type)
            let priority2 = streamPriority(stream2.type)
            return priority1 > priority2
        }
        
        return prioritizedStreams.first
    }
    
    /// Define prioridade dos streams para referência temporal
    private static func streamPriority(_ type: GPMFStreamType) -> Int {
        switch type {
        case .gps5, .gps9, .gpsu:
            return 100 // Alta prioridade - timestamps mais confiáveis
        case .accl:
            return 80
        case .gyro:
            return 70
        case .temp:
            return 50
        case .cori, .grav, .iorients:
            return 40
        case .unknown:
            return 10
        }
    }
    
    /// Cria um ponto de telemetria a partir dos streams
    private static func createTelemetryDataPoint(
        from primarySample: GPMFSample,
        streams: [GPMFStream],
        sampleIndex: Int
    ) -> TelemetryDataPoint {
        
        var latitude: Double?
        var longitude: Double?
        var altitude: Double?
        var speed: Double?
        var accelerationX: Double?
        var accelerationY: Double?
        var accelerationZ: Double?
        var gyroX: Double?
        var gyroY: Double?
        var gyroZ: Double?
        var temperature: Double?
        
        // Processar cada stream para extrair dados
        for stream in streams {
            switch stream.type {
            case .gps5:
                // GPS5: [lat, lon, alt, speed, 3D speed]
                if let gpsSample = getSample(from: stream, at: sampleIndex) {
                    (latitude, longitude, altitude, speed) = parseGPS5Sample(gpsSample)
                }
                
            case .gps9:
                // GPS9: dados GPS mais detalhados
                if let gpsSample = getSample(from: stream, at: sampleIndex) {
                    (latitude, longitude, altitude, speed) = parseGPS9Sample(gpsSample)
                }
                
            case .accl:
                // ACCL: [x, y, z] em Gs
                if let accelSample = getSample(from: stream, at: sampleIndex) {
                    (accelerationX, accelerationY, accelerationZ) = parseAccelerometerSample(accelSample)
                }
                
            case .gyro:
                // GYRO: [x, y, z] em rad/s
                if let gyroSample = getSample(from: stream, at: sampleIndex) {
                    (gyroX, gyroY, gyroZ) = parseGyroscopeSample(gyroSample)
                }
                
            case .temp:
                // TMPC: [temperature] em Celsius
                if let tempSample = getSample(from: stream, at: sampleIndex) {
                    temperature = parseTemperatureSample(tempSample)
                }
                
            default:
                break // Ignorar outros streams por enquanto
            }
        }
        
        return TelemetryDataPoint(
            timestamp: primarySample.timestamp,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            speed: speed,
            accelerationX: accelerationX,
            accelerationY: accelerationY,
            accelerationZ: accelerationZ,
            gyroX: gyroX,
            gyroY: gyroY,
            gyroZ: gyroZ,
            temperature: temperature
        )
    }
    
    /// Obtém uma amostra de um stream, com fallback para interpolação
    private static func getSample(from stream: GPMFStream, at index: Int) -> GPMFSample? {
        guard index < stream.samples.count else { return nil }
        return stream.samples[index]
    }
    
    // MARK: - Stream Parsers
    
    private static func parseGPS5Sample(_ sample: GPMFSample) -> (lat: Double?, lon: Double?, alt: Double?, speed: Double?) {
        guard sample.values.count >= 5 else { return (nil, nil, nil, nil) }
        
        // GPS5: [latitude, longitude, altitude, speed, 3D speed]
        let latitude = sample.values[0]
        let longitude = sample.values[1]
        let altitude = sample.values[2]
        let speed = sample.values[3] // speed 2D (m/s)
        
        // Converter velocidade para km/h se necessário
        let speedKmh = speed * 3.6
        
        return (latitude, longitude, altitude, speedKmh)
    }
    
    private static func parseGPS9Sample(_ sample: GPMFSample) -> (lat: Double?, lon: Double?, alt: Double?, speed: Double?) {
        guard sample.values.count >= 9 else { return (nil, nil, nil, nil) }
        
        // GPS9: [lat, lon, alt, speed, 3D speed, accuracy, etc.]
        let latitude = sample.values[0]
        let longitude = sample.values[1]
        let altitude = sample.values[2]
        let speed = sample.values[3] // m/s
        
        let speedKmh = speed * 3.6
        return (latitude, longitude, altitude, speedKmh)
    }
    
    private static func parseAccelerometerSample(_ sample: GPMFSample) -> (x: Double?, y: Double?, z: Double?) {
        guard sample.values.count >= 3 else { return (nil, nil, nil) }
        
        // ACCL: [x, y, z] em Gs
        // GoPro geralmente usa Gs, mas verificar escala
        let x = sample.values[0]
        let y = sample.values[1]
        let z = sample.values[2]
        
        return (x, y, z)
    }
    
    private static func parseGyroscopeSample(_ sample: GPMFSample) -> (x: Double?, y: Double?, z: Double?) {
        guard sample.values.count >= 3 else { return (nil, nil, nil) }
        
        // GYRO: [x, y, z] em rad/s
        let x = sample.values[0]
        let y = sample.values[1]
        let z = sample.values[2]
        
        return (x, y, z)
    }
    
    private static func parseTemperatureSample(_ sample: GPMFSample) -> Double? {
        guard sample.values.count >= 1 else { return nil }
        
        // TMPC: temperatura em Celsius
        return sample.values[0]
    }
    
    // MARK: - Data Validation & Cleaning
    
    /// Valida e limpa os pontos de telemetria
    static func cleanTelemetryData(_ points: [TelemetryDataPoint]) -> [TelemetryDataPoint] {
        var cleanedPoints: [TelemetryDataPoint] = []
        
        for point in points {
            // Remover pontos com dados inválidos
            if isValidPoint(point) {
                cleanedPoints.append(point)
            }
        }
        
        print("🧹 Limpeza de dados: \(points.count) → \(cleanedPoints.count) pontos válidos")
        return cleanedPoints
    }
    
    private static func isValidPoint(_ point: TelemetryDataPoint) -> Bool {
        // Validar coordenadas GPS
        if let lat = point.latitude, let lon = point.longitude {
            guard isValidCoordinate(latitude: lat, longitude: lon) else {
                return false
            }
        }
        
        // Validar altitude
        if let alt = point.altitude {
            guard (-1000...9000).contains(alt) else { // -1km a 9km
                return false
            }
        }
        
        // Validar velocidade
        if let speed = point.speed {
            guard speed >= 0 && speed < 500 else { // 0-500 km/h
                return false
            }
        }
        
        // Validar aceleração
        if let accel = TelemetryCalculator.calculateAccelerationMagnitude(
            x: point.accelerationX,
            y: point.accelerationY,
            z: point.accelerationZ
        ) {
            guard accel >= 0 && accel < 50 else { // 0-50 Gs
                return false
            }
        }
        
        // Validar temperatura
        if let temp = point.temperature {
            guard (-50...100).contains(temp) else { // -50°C a 100°C
                return false
            }
        }
        
        return true
    }
    
    private static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
    
    // MARK: - Data Enhancement
    
    /// Aprimora os dados com cálculos derivados
    static func enhanceTelemetryData(_ points: [TelemetryDataPoint]) -> [TelemetryDataPoint] {
        var enhancedPoints = points
        
        // Calcular aceleração magnitude se não existir
        for i in 0..<enhancedPoints.count {
            var point = enhancedPoints[i]
            
            // Se não tem magnitude de aceleração, calcular
            if TelemetryCalculator.calculateAccelerationMagnitude(
                x: point.accelerationX,
                y: point.accelerationY,
                z: point.accelerationZ
            ) == nil {
                // Já está calculado na propriedade computada, não precisa fazer nada
            }
            
            enhancedPoints[i] = point
        }
        
        print("✨ Dados aprimorados: \(enhancedPoints.count) pontos")
        return enhancedPoints
    }
}


// MARK: - Utility Extensions
extension GPMFStreamType {
    /// Descrição amigável para logging
    var description: String {
        switch self {
        case .gps5: return "GPS (5 elementos)"
        case .gps9: return "GPS (9 elementos)"
        case .gpsu: return "GPS UTC"
        case .accl: return "Acelerômetro"
        case .gyro: return "Giroscópio"
        case .temp: return "Temperatura"
        case .cori: return "Orientação da Câmera"
        case .grav: return "Gravidade"
        case .iorients: return "Orientação do IMU"
        case .unknown: return "Desconhecido"
        }
    }
}