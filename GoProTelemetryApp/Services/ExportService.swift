//
//  ExportService.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import CoreLocation

// MARK: - Export Errors
enum ExportError: Error, LocalizedError {
    case emptyData
    case fileCreationError
    case encodingError
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .emptyData: return "Não há dados de telemetria para exportar."
        case .fileCreationError: return "Falha ao criar o arquivo temporário."
        case .encodingError: return "Falha ao codificar os dados."
        case .unsupportedFormat: return "Este formato ainda não é suportado."
        }
    }
}

// MARK: - Service Logic
class ExportService {
    
    func export(session: TelemetrySession, settings: ExportSettings, sampleRate: Double) throws -> URL {
        guard !session.dataPoints.isEmpty else {
            throw ExportError.emptyData
        }
        
        let processedData = applySampling(to: session.dataPoints, rate: sampleRate)
        let fileContent: String
        
        switch settings.defaultFormat {
        case .gpx:
            fileContent = generateGPX(data: processedData, session: session)
        case .kml:
            fileContent = generateKML(data: processedData, session: session)
        case .csv:
            fileContent = generateCSV(data: processedData, settings: settings)
        case .json:
            fileContent = try generateJSON(data: processedData, settings: settings)
        case .mgjson:
            fileContent = try generateMGJSON(data: processedData, session: session, settings: settings)
        }
        
        return try createTemporaryFile(
            content: fileContent,
            settings: settings,
            originalName: session.videoUrl.lastPathComponent,
            creationDate: session.creationDate
        )
    }
    
    private func applySampling(to data: [TelemetryData], rate: Double) -> [TelemetryData] {
        if rate >= 1.0 { return data }
        let step = Int(1.0 / rate)
        guard step > 1 else { return data }
        
        var result: [TelemetryData] = []
        result.reserveCapacity(data.count / step)
        
        for index in stride(from: 0, to: data.count, by: step) {
            result.append(data[index])
        }
        return result
    }
    
    private func createTemporaryFile(content: String, settings: ExportSettings, originalName: String, creationDate: Date) throws -> URL {
        let fileName = processFileName(
            template: settings.customFileNameTemplate,
            originalName: originalName,
            date: creationDate
        )
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(fileName).\(settings.defaultFormat.fileExtension)")
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw ExportError.fileCreationError
        }
    }
    
    private func processFileName(template: String, originalName: String, date: Date) -> String {
        let videoName = originalName.replacingOccurrences(of: ".[^.]+$", with: "", options: .regularExpression)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "HH-mm-ss"
        let timeStr = dateFormatter.string(from: date)
        
        var name = template
        if name.isEmpty { name = "{video}_{date}_{time}" }
        
        name = name.replacingOccurrences(of: "{video}", with: videoName)
        name = name.replacingOccurrences(of: "{device}", with: "GoPro")
        name = name.replacingOccurrences(of: "{date}", with: dateStr)
        name = name.replacingOccurrences(of: "{time}", with: timeStr)
        
        return name
    }
}

// MARK: - Generators

extension ExportService {
    
    // MARK: GPX (Apenas GPS)
    private func generateGPX(data: [TelemetryData], session: TelemetrySession) -> String {
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="GoProTelemetryApp" xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(session.videoUrl.lastPathComponent)</name>
            <time>\(formatDateISO(session.creationDate))</time>
          </metadata>
          <trk>
            <name>GoPro Telemetry Track</name>
            <trkseg>
        """
        
        let startDate = session.creationDate
        
        for point in data {
            // GPX requer Lat/Lon. Se não tiver, pula o ponto.
            if let lat = point.latitude, let lon = point.longitude {
                let pointDate = startDate.addingTimeInterval(point.timestamp)
                
                gpx += "\n      <trkpt lat=\"\(lat)\" lon=\"\(lon)\">"
                if let alt = point.altitude {
                    gpx += "\n        <ele>\(alt)</ele>"
                }
                gpx += "\n        <time>\(formatDateISO(pointDate))</time>"
                
                if let speed = point.speed2D {
                    gpx += "\n        <extensions><speed>\(speed)</speed></extensions>"
                }
                gpx += "\n      </trkpt>"
            }
        }
        
        gpx += "\n    </trkseg>\n  </trk>\n</gpx>"
        return gpx
    }
    
    // MARK: KML (Apenas GPS)
    private func generateKML(data: [TelemetryData], session: TelemetrySession) -> String {
        // Filtra apenas pontos com coordenadas válidas
        let validCoords = data.compactMap { point -> String? in
            guard let lat = point.latitude, let lon = point.longitude else { return nil }
            let alt = point.altitude ?? 0
            return "\(lon),\(lat),\(alt)"
        }
        
        let coordinatesString = validCoords.joined(separator: " ")
        
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <kml xmlns="http://www.opengis.net/kml/2.2">
          <Document>
            <name>\(session.videoUrl.lastPathComponent)</name>
            <description>Exportado por GoPro Telemetry App</description>
            <Style id="pathStyle">
              <LineStyle>
                <color>7f00ffff</color>
                <width>4</width>
              </LineStyle>
            </Style>
            <Placemark>
              <name>Path</name>
              <styleUrl>#pathStyle</styleUrl>
              <LineString>
                <extrude>1</extrude>
                <tessellate>1</tessellate>
                <altitudeMode>absolute</altitudeMode>
                <coordinates>
                  \(coordinatesString)
                </coordinates>
              </LineString>
            </Placemark>
          </Document>
        </kml>
        """
    }
    
    // MARK: CSV (Safely Unwrapped)
    private func generateCSV(data: [TelemetryData], settings: ExportSettings) -> String {
        var header = "Time (s)"
        
        if settings.includeGPS {
            header += ",Latitude,Longitude,Altitude (m),Speed 2D (m/s),Speed 3D (m/s)"
        }
        
        if settings.includeAccelerometer {
            header += ",Accel X (m/s²),Accel Y (m/s²),Accel Z (m/s²)"
        }
        
        if settings.includeGyroscope {
            header += ",Gyro X (rad/s),Gyro Y (rad/s),Gyro Z (rad/s)"
        }
        
        var csv = header + "\n"
        
        for point in data {
            var line = String(format: "%.3f", point.timestamp)
            
            // GPS (Optional Check)
            if settings.includeGPS {
                if let lat = point.latitude, let lon = point.longitude {
                    line += String(format: ",%.6f,%.6f,%.2f,%.2f,%.2f",
                                   lat, lon, point.altitude ?? 0,
                                   point.speed2D ?? 0, point.speed3D ?? 0)
                } else {
                    line += ",,,,,"
                }
            }
            
            // Accel (Optional Check)
            if settings.includeAccelerometer {
                if let acc = point.acceleration {
                    line += String(format: ",%.3f,%.3f,%.3f", acc.x, acc.y, acc.z)
                } else {
                    line += ",,,"
                }
            }
            
            // Gyro (Optional Check)
            if settings.includeGyroscope {
                if let gyro = point.gyro {
                    line += String(format: ",%.3f,%.3f,%.3f", gyro.x, gyro.y, gyro.z)
                } else {
                    line += ",,,"
                }
            }
            
            csv += line + "\n"
        }
        
        return csv
    }
    
    // MARK: JSON (Safely Unwrapped)
    private func generateJSON(data: [TelemetryData], settings: ExportSettings) throws -> String {
        let mappedData = data.map { point -> [String: Any] in
            var dict: [String: Any] = ["time": point.timestamp]
            
            if settings.includeGPS {
                if let lat = point.latitude, let lon = point.longitude {
                    dict["lat"] = lat
                    dict["lon"] = lon
                    dict["alt"] = point.altitude ?? 0
                    dict["speed2d"] = point.speed2D ?? 0
                    dict["speed3d"] = point.speed3D ?? 0
                }
            }
            
            if settings.includeAccelerometer, let acc = point.acceleration {
                dict["accel"] = ["x": acc.x, "y": acc.y, "z": acc.z]
            }
            
            if settings.includeGyroscope, let gyro = point.gyro {
                dict["gyro"] = ["x": gyro.x, "y": gyro.y, "z": gyro.z]
            }
            
            return dict
        }
        
        let wrapper = ["telemetry": mappedData]
        let jsonData = try JSONSerialization.data(withJSONObject: wrapper, options: .prettyPrinted)
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ExportError.encodingError
        }
        
        return jsonString
    }
    
    // MARK: MGJSON (Safely Unwrapped)
    private func generateMGJSON(data: [TelemetryData], session: TelemetrySession, settings: ExportSettings) throws -> String {
        let startDate = session.creationDate
        var dynamicSamples: [[String: Any]] = []
        var dataOutline: [[String: Any]] = []
        
        // 1. GPS Stream
        if settings.includeGPS {
            // Filtra apenas pontos com GPS válido para o MGJSON
            let samples = data.compactMap { point -> [String: Any]? in
                guard let lat = point.latitude, let lon = point.longitude else { return nil }
                let date = startDate.addingTimeInterval(point.timestamp)
                let speed = (point.speed2D ?? 0) * 3.6
                
                return [
                    "time": formatDateISO(date),
                    "value": [lat, lon, speed]
                ]
            }
            
            if !samples.isEmpty {
                dynamicSamples.append([
                    "sampleSetID": "gpsData",
                    "dataType": "numberArray",
                    "sampleCount": samples.count,
                    "frameRate": 0,
                    "samples": samples
                ])
                
                dataOutline.append([
                    "objectType": "dataDynamic",
                    "displayName": "GPS (Lat, Lon, Speed)",
                    "sampleSetID": "gpsData",
                    "dataType": "numberArray",
                    "matchName": "gpsData",
                    "interpolation": "linear",
                    "displayNameURI": "gps"
                ])
            }
        }
        
        // 2. Accelerometer Stream
        if settings.includeAccelerometer {
            let samples = data.compactMap { point -> [String: Any]? in
                guard let acc = point.acceleration else { return nil }
                let date = startDate.addingTimeInterval(point.timestamp)
                return [
                    "time": formatDateISO(date),
                    "value": [acc.x, acc.y, acc.z]
                ]
            }
            
            if !samples.isEmpty {
                dynamicSamples.append([
                    "sampleSetID": "accelData",
                    "dataType": "numberArray",
                    "sampleCount": samples.count,
                    "frameRate": 0,
                    "samples": samples
                ])
                
                dataOutline.append([
                    "objectType": "dataDynamic",
                    "displayName": "Accelerometer (X, Y, Z)",
                    "sampleSetID": "accelData",
                    "dataType": "numberArray",
                    "matchName": "accelData",
                    "interpolation": "linear",
                    "displayNameURI": "accel"
                ])
            }
        }
        
        // Montagem Final
        let mgjson: [String: Any] = [
            "version": "MGJSON2.0.0",
            "creator": "GoProTelemetryApp",
            "dynamicSamples": dynamicSamples,
            "dataOutline": dataOutline
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: mgjson, options: .prettyPrinted)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ExportError.encodingError
        }
        
        return jsonString
    }
    
    // MARK: - Helpers
    
    private func formatDateISO(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
