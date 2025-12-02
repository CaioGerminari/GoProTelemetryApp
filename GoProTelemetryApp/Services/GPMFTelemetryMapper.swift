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
    
    static func makeSession(from streams: [GPMFStream], videoUrl: URL, metadata: VideoMetadata, deviceName: String?) -> TelemetrySession {
        print("🔄 Mapeando sensores avançados (IA, Áudio, Cine)...")
        
        guard let masterStream = findMasterStream(in: streams) else {
            print("❌ Erro: Nenhum stream mestre encontrado.")
            return TelemetrySession(videoUrl: videoUrl, creationDate: metadata.creationDate, cameraModel: deviceName, dataPoints: [], statistics: .empty)
        }
        
        // Mapeamento rápido dos streams
        let sensorMap = Dictionary(grouping: streams, by: { $0.type }).mapValues { $0.first! }
        
        let dataPoints = processTimeline(master: masterStream, sensors: sensorMap)
        
        let statistics = calculateStatistics(
            points: dataPoints,
            videoDuration: metadata.duration,
            cameraName: deviceName ?? "GoPro Desconhecida"
        )
        
        return TelemetrySession(
            videoUrl: videoUrl,
            creationDate: metadata.creationDate,
            cameraModel: deviceName,
            dataPoints: dataPoints,
            statistics: statistics
        )
    }
    
    // MARK: - Core Processing
    
    private static func findMasterStream(in streams: [GPMFStream]) -> GPMFStream? {
        let priorityOrder: [GPMFStreamType] = [.accl, .gyro, .gps9, .gps5]
        return priorityOrder.compactMap { type in streams.first(where: { $0.type == type }) }.first ?? streams.first
    }
    
    private static func processTimeline(master: GPMFStream, sensors: [GPMFStreamType: GPMFStream]) -> [TelemetryData] {
        var points: [TelemetryData] = []
        points.reserveCapacity(master.samples.count)
        
        // --- Estado Acumulado (Sample-and-Hold) ---
        var lastGPS: (lat: Double, lon: Double, alt: Double, s2d: Double, s3d: Double)?
        var lastISO: Double?
        var lastShutter: Double?
        var lastWBAL: Double?
        var lastTemp: Double?
        var lastScene: String?
        var lastFaces: [DetectedFace]?
        
        var totalDistance: Double = 0.0
        var previousCoord: CLLocationCoordinate2D?
        
        // Índices para busca otimizada
        var indices: [GPMFStreamType: Int] = [:]
        
        for sample in master.samples {
            let time = sample.timestamp
            
            // 1. Alta Frequência (IMU)
            var accel: Vector3?
            if let stream = sensors[.accl], let vals = findNearest(time: time, stream: stream, indices: &indices) {
                accel = Vector3(x: vals[0], y: vals[1], z: vals[2])
            } else if master.type == .accl { // Se o mestre for ACCL, usa os dados dele
                accel = Vector3(x: sample.values[0], y: sample.values[1], z: sample.values[2])
            }
            
            var gyro: Vector3?
            if let stream = sensors[.gyro], let vals = findNearest(time: time, stream: stream, indices: &indices) {
                gyro = Vector3(x: vals[0], y: vals[1], z: vals[2])
            }
            
            var gravity: Vector3?
            if let stream = sensors[.grav], let vals = findNearest(time: time, stream: stream, indices: &indices) {
                gravity = Vector3(x: vals[0], y: vals[1], z: vals[2])
            }
            
            // 2. GPS
            var currentGPS = lastGPS
            let gpsStream = sensors[.gps9] ?? sensors[.gps5]
            if let stream = gpsStream, let vals = findNearest(time: time, stream: stream, indices: &indices, tolerance: 0.2) {
                if let parsed = parseGPS(vals, type: stream.type), abs(parsed.lat) > 0.001 {
                    currentGPS = parsed
                    lastGPS = parsed
                }
            } else {
                currentGPS = nil // GPS caiu
            }
            
            // Distância
            if let gps = currentGPS {
                let coord = CLLocationCoordinate2D(latitude: gps.lat, longitude: gps.lon)
                if let prev = previousCoord {
                    let dist = prev.distance(to: coord)
                    if dist > 0.05 && dist < 100 { totalDistance += dist }
                }
                previousCoord = coord
            }
            
            // 3. Dados Lentos (Sample-and-Hold)
            
            // Temperatura
            if let stream = sensors[.temp], let vals = findNearest(time: time, stream: stream, indices: &indices, tolerance: 2.0) {
                lastTemp = vals[0]
            }
            
            // Câmera (ISO/Shut/WBAL)
            if let stream = sensors[.iso], let vals = findNearest(time: time, stream: stream, indices: &indices, tolerance: 1.0) {
                lastISO = vals[0]
            }
            if let stream = sensors[.shut], let vals = findNearest(time: time, stream: stream, indices: &indices, tolerance: 1.0) {
                lastShutter = vals[0]
            }
            if let stream = sensors[.wbal], let vals = findNearest(time: time, stream: stream, indices: &indices, tolerance: 1.0) {
                lastWBAL = vals[0]
            }
            
            // 4. Inteligência (Cena e Rosto)
            
            // Cenas (SCEN): Decodificar FourCC do Double
            if let stream = sensors[.scen], let vals = findNearest(time: time, stream: stream, indices: &indices, tolerance: 2.0) {
                // vals[0] é o FourCC (ex: 'SNOW' como double), vals[1] é probabilidade
                lastScene = decodeFourCC(vals[0])
            }
            
            // Rostos (FACE): Decodificar Bounding Boxes
            if let stream = sensors[.face], let vals = findNearest(time: time, stream: stream, indices: &indices, tolerance: 0.5) {
                // Estrutura típica: [ID, x, y, w, h] ou apenas [x, y, w, h] dependendo da versão
                // Assumindo blocks de 5 valores se elementsPerSample for 5
                if vals.count >= 4 {
                    lastFaces = parseFaces(vals, elements: stream.elementsPerSample)
                }
            } else {
                lastFaces = nil // Rostos não persistem se pararem de ser detectados
            }
            
            // 5. Diagnóstico de Áudio
            var audioDiag: AudioDiagnostic?
            if let stream = sensors[.wndm], let vals = findNearest(time: time, stream: stream, indices: &indices) {
                // WNDM: [enabled, level 0-100?]
                let level = vals.count > 1 ? vals[1] : vals[0]
                audioDiag = AudioDiagnostic(windNoiseLevel: level > 1 ? level/100.0 : level, isWet: false)
            }
            
            // Montagem
            var point = TelemetryData(
                timestamp: time,
                latitude: currentGPS?.lat,
                longitude: currentGPS?.lon,
                altitude: currentGPS?.alt,
                speed2D: currentGPS?.s2d,
                speed3D: currentGPS?.s3d,
                acceleration: accel,
                gravity: gravity,
                gyro: gyro,
                iso: lastISO,
                shutterSpeed: lastShutter,
                whiteBalance: lastWBAL,
                temperature: lastTemp,
                audioDiagnostic: audioDiag,
                faces: lastFaces,
                scene: lastScene
            )
            point.distanceAccumulated = totalDistance
            points.append(point)
        }
        
        return points
    }
    
    // MARK: - Decoders
    
    /// Converte um Double que representa um FourCC (ex: 'SNOW') de volta para String
    private static func decodeFourCC(_ value: Double) -> String {
        // GoPro armazena 'SNOW' como um inteiro de 32 bits interpretado como float/double
        let intVal = UInt32(value)
        
        // Extrai bytes (Big Endian)
        let bytes = [
            UInt8((intVal >> 24) & 0xFF),
            UInt8((intVal >> 16) & 0xFF),
            UInt8((intVal >> 8) & 0xFF),
            UInt8(intVal & 0xFF)
        ]
        
        // Filtra caracteres imprimíveis válidos (ASCII)
        let validBytes = bytes.filter { $0 >= 32 && $0 <= 126 }
        return String(bytes: validBytes, encoding: .ascii) ?? "?"
    }
    
    /// Parse de múltiplos rostos (se houver mais de um no mesmo sample)
    private static func parseFaces(_ values: [Double], elements: Int) -> [DetectedFace] {
        var faces: [DetectedFace] = []
        let step = max(1, elements) // Evita divisão por zero
        
        // Itera sobre os blocos de dados (cada rosto é um bloco)
        for i in stride(from: 0, to: values.count, by: step) {
            let end = min(i + step, values.count)
            let faceData = Array(values[i..<end])
            
            if faceData.count >= 4 {
                // Tenta identificar o formato. Geralmente ID é o primeiro se tiver 5
                let id = faceData.count >= 5 ? Int(faceData[0]) : 0
                let x = faceData.count >= 5 ? faceData[1] : faceData[0]
                let y = faceData.count >= 5 ? faceData[2] : faceData[1]
                let w = faceData.count >= 5 ? faceData[3] : faceData[2]
                let h = faceData.count >= 5 ? faceData[4] : faceData[3]
                
                faces.append(DetectedFace(id: id, x: x, y: y, w: w, h: h))
            }
        }
        return faces
    }
    
    // MARK: - Helpers Padrão (FindNearest, ParseGPS...)
    
    private static func findNearest(time: Double, stream: GPMFStream, indices: inout [GPMFStreamType: Int], tolerance: Double = 0.05) -> [Double]? {
        let startIndex = indices[stream.type] ?? 0
        let samples = stream.samples
        guard startIndex < samples.count else { return nil }
        
        var bestIndex = startIndex
        var minDiff = abs(samples[startIndex].timestamp - time)
        
        let maxSearch = min(startIndex + 500, samples.count)
        for i in startIndex..<maxSearch {
            let diff = abs(samples[i].timestamp - time)
            if diff < minDiff {
                minDiff = diff
                bestIndex = i
            } else if diff > minDiff {
                break
            }
        }
        indices[stream.type] = bestIndex
        if minDiff > tolerance { return nil }
        return samples[bestIndex].values
    }
    
    private static func parseGPS(_ values: [Double], type: GPMFStreamType) -> (lat: Double, lon: Double, alt: Double, s2d: Double, s3d: Double)? {
        guard values.count >= 5 else { return nil }
        return (values[0], values[1], values[2], values[3], values[4])
    }
    
    // MARK: - Statistics
    
    private static func calculateStatistics(points: [TelemetryData], videoDuration: Double, cameraName: String) -> TelemetryStatistics {
        let validSpeeds = points.compactMap { $0.speed2D }.filter { $0 < 300 }
        let maxSpeed = validSpeeds.max() ?? 0
        let avgSpeed = validSpeeds.isEmpty ? 0 : validSpeeds.reduce(0, +) / Double(validSpeeds.count)
        
        let altitudes = points.compactMap { $0.altitude }
        let maxAlt = altitudes.max() ?? 0
        let minAlt = altitudes.min() ?? 0
        
        let maxG = points.compactMap { $0.acceleration?.magnitude }.max() ?? 0
        let totalDistance = points.last?.distanceAccumulated ?? 0
        
        // Estatísticas Novas
        let scenes = Set(points.compactMap { $0.scene }).sorted()
        let maxTemp = points.compactMap { $0.temperature }.max() ?? 0
        let audioIssues = points.filter { ($0.audioDiagnostic?.windNoiseLevel ?? 0) > 0.8 }.count
        
        return TelemetryStatistics(
            duration: max(videoDuration, points.last?.timestamp ?? 0),
            totalDistance: totalDistance,
            maxSpeed: maxSpeed,
            avgSpeed: avgSpeed,
            maxAltitude: maxAlt,
            minAltitude: minAlt,
            maxGForce: maxG,
            cameraName: cameraName,
            detectedScenes: scenes,
            audioIssuesCount: audioIssues,
            maxTemperature: maxTemp
        )
    }
}

// Extension privada
fileprivate extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }
}
