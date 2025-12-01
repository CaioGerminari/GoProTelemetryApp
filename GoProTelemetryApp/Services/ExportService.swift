//
//  ExportService.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import Combine

class ExportService: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0
    
    func exportTelemetry(_ session: TelemetrySession,
                        format: ExportFormat,
                        configuration: ExportConfiguration) async throws -> URL {
        
        await MainActor.run {
            isExporting = true
            exportProgress = 0
        }
        
        defer {
            Task { @MainActor in
                isExporting = false
                exportProgress = 1.0
            }
        }
        
        switch format {
        case .csv:
            return try exportToCSV(session, configuration: configuration)
        case .gpx:
            return try exportToGPX(session, configuration: configuration)
        case .json:
            return try exportToJSON(session, configuration: configuration)
        case .fcpxml:
            return try exportToFCPXML(session, configuration: configuration)
        case .davinci:
            return try exportToDaVinci(session, configuration: configuration)
        }
    }
    
    private func exportToCSV(_ session: TelemetrySession, configuration: ExportConfiguration) throws -> URL {
        var csvString = "Timestamp,Latitude,Longitude,Altitude,Speed,AccelX,AccelY,AccelZ,GyroX,GyroY,GyroZ,Temperature\n"
        
        let filteredPoints = filterPoints(session.points, configuration: configuration)
        
        for point in filteredPoints {
            let line = String(format: "%.3f,%.6f,%.6f,%.2f,%.2f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.1f\n",
                            point.timestamp,
                            point.latitude ?? 0,
                            point.longitude ?? 0,
                            point.altitude ?? 0,
                            point.speed ?? 0,
                            point.accelerationX ?? 0,
                            point.accelerationY ?? 0,
                            point.accelerationZ ?? 0,
                            point.gyroX ?? 0,
                            point.gyroY ?? 0,
                            point.gyroZ ?? 0,
                            point.temperature ?? 0)
            csvString += line
        }
        
        return try saveStringToFile(csvString, format: .csv, session: session)
    }
    
    private func exportToGPX(_ session: TelemetrySession, configuration: ExportConfiguration) throws -> URL {
        var gpxString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="GoProTelemetryApp">
        <trk>
        <name>\(session.deviceName)</name>
        <trkseg>
        """
        
        let filteredPoints = filterPoints(session.points, configuration: configuration)
        
        for point in filteredPoints {
            if let lat = point.latitude, let lon = point.longitude {
                let time = Date(timeIntervalSince1970: point.timestamp)
                let isoTime = ISO8601DateFormatter().string(from: time)
                
                gpxString += """
                <trkpt lat="\(lat)" lon="\(lon)">
                <ele>\(point.altitude ?? 0)</ele>
                <time>\(isoTime)</time>
                <speed>\(point.speed ?? 0)</speed>
                </trkpt>
                """
            }
        }
        
        gpxString += """
        </trkseg>
        </trk>
        </gpx>
        """
        
        return try saveStringToFile(gpxString, format: .gpx, session: session)
    }
    
    private func exportToJSON(_ session: TelemetrySession, configuration: ExportConfiguration) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Create a simplified structure for JSON export
        let exportData = TelemetryExportData(session: session, configuration: configuration)
        let data = try encoder.encode(exportData)
        return try saveDataToFile(data, format: .json, session: session)
    }
    
    private func exportToFCPXML(_ session: TelemetrySession, configuration: ExportConfiguration) throws -> URL {
        // Simplified FCPXML structure for telemetry data
        let fcpxmlString = """
        <?xml version="1.0" encoding="UTF-8"?>
        <fcpxml version="1.9">
        <resources>
            <format id="r1" name="FFVideoFormat1080p25"/>
        </resources>
        <library>
            <event name="GoPro Telemetry">
                <project name="\(session.deviceName) Telemetry">
                    <sequence format="r1">
                        <spine>
                            <!-- Telemetry markers would go here -->
                        </spine>
                    </sequence>
                </project>
            </event>
        </library>
        </fcpxml>
        """
        
        return try saveStringToFile(fcpxmlString, format: .fcpxml, session: session)
    }
    
    private func exportToDaVinci(_ session: TelemetrySession, configuration: ExportConfiguration) throws -> URL {
        var resolveString = "Frame,Time,GPS Latitude,GPS Longitude,Altitude,Speed,Acceleration X,Acceleration Y,Acceleration Z\n"
        
        let filteredPoints = filterPoints(session.points, configuration: configuration)
        let startTime = filteredPoints.first?.timestamp ?? 0
        
        for (index, point) in filteredPoints.enumerated() {
            let time = point.timestamp - startTime
            let line = "\(index),\(String(format: "%.3f", time)),\(point.latitude ?? 0),\(point.longitude ?? 0),\(point.altitude ?? 0),\(point.speed ?? 0),\(point.accelerationX ?? 0),\(point.accelerationY ?? 0),\(point.accelerationZ ?? 0)\n"
            resolveString += line
        }
        
        return try saveStringToFile(resolveString, format: .davinci, session: session)
    }
    
    private func filterPoints(_ points: [TelemetryDataPoint], configuration: ExportConfiguration) -> [TelemetryDataPoint] {
        var filteredPoints = points
        
        // Apply sampling rate
        if configuration.sampleRate != 1.0 {
            let sampleInterval = Int(1.0 / configuration.sampleRate)
            filteredPoints = filteredPoints.enumerated().compactMap { index, point in
                index % sampleInterval == 0 ? point : nil
            }
        }
        
        // Filter based on configuration
        if !configuration.includeGPS {
            filteredPoints = filteredPoints.map { point in
                TelemetryDataPoint(
                    timestamp: point.timestamp,
                    latitude: nil,
                    longitude: nil,
                    altitude: nil,
                    speed: nil,
                    accelerationX: point.accelerationX,
                    accelerationY: point.accelerationY,
                    accelerationZ: point.accelerationZ,
                    gyroX: point.gyroX,
                    gyroY: point.gyroY,
                    gyroZ: point.gyroZ,
                    temperature: point.temperature
                )
            }
        }
        
        if !configuration.includeIMU {
            filteredPoints = filteredPoints.map { point in
                TelemetryDataPoint(
                    timestamp: point.timestamp,
                    latitude: point.latitude,
                    longitude: point.longitude,
                    altitude: point.altitude,
                    speed: point.speed,
                    accelerationX: nil,
                    accelerationY: nil,
                    accelerationZ: nil,
                    gyroX: nil,
                    gyroY: nil,
                    gyroZ: nil,
                    temperature: point.temperature
                )
            }
        }
        
        return filteredPoints
    }
    
    private func saveStringToFile(_ string: String, format: ExportFormat, session: TelemetrySession) throws -> URL {
        guard let data = string.data(using: .utf8) else {
            throw GPMFError.parsingFailed
        }
        return try saveDataToFile(data, format: format, session: session)
    }
    
    private func saveDataToFile(_ data: Data, format: ExportFormat, session: TelemetrySession) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "\(session.deviceName)_telemetry_\(dateString).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try data.write(to: tempURL)
        return tempURL
    }
}

// MARK: - Supporting Structures for JSON Export

struct TelemetryExportData: Codable {
    let deviceName: String
    let duration: TimeInterval
    let startTime: Date
    let points: [TelemetryDataPointExport]
    let statistics: TelemetryStatisticsExport
    
    init(session: TelemetrySession, configuration: ExportConfiguration) {
        self.deviceName = session.deviceName
        self.duration = session.duration
        self.startTime = session.startTime
        self.points = session.points.map { TelemetryDataPointExport(point: $0, configuration: configuration) }
        self.statistics = TelemetryStatisticsExport(stats: session.statistics)
    }
}

struct TelemetryDataPointExport: Codable {
    let timestamp: Double
    let latitude: Double?
    let longitude: Double?
    let altitude: Double?
    let speed: Double?
    let accelerationX: Double?
    let accelerationY: Double?
    let accelerationZ: Double?
    let gyroX: Double?
    let gyroY: Double?
    let gyroZ: Double?
    let temperature: Double?
    
    init(point: TelemetryDataPoint, configuration: ExportConfiguration) {
        self.timestamp = point.timestamp
        self.latitude = configuration.includeGPS ? point.latitude : nil
        self.longitude = configuration.includeGPS ? point.longitude : nil
        self.altitude = configuration.includeGPS ? point.altitude : nil
        self.speed = configuration.includeGPS ? point.speed : nil
        self.accelerationX = configuration.includeIMU ? point.accelerationX : nil
        self.accelerationY = configuration.includeIMU ? point.accelerationY : nil
        self.accelerationZ = configuration.includeIMU ? point.accelerationZ : nil
        self.gyroX = configuration.includeIMU ? point.gyroX : nil
        self.gyroY = configuration.includeIMU ? point.gyroY : nil
        self.gyroZ = configuration.includeIMU ? point.gyroZ : nil
        self.temperature = point.temperature
    }
}

struct TelemetryStatisticsExport: Codable {
    let totalDistance: Double
    let maxSpeed: Double
    let avgSpeed: Double
    let maxAltitude: Double
    let minAltitude: Double
    let maxAcceleration: Double
    let duration: TimeInterval
    
    init(stats: TelemetryStatistics) {
        self.totalDistance = stats.totalDistance
        self.maxSpeed = stats.maxSpeed
        self.avgSpeed = stats.avgSpeed
        self.maxAltitude = stats.maxAltitude
        self.minAltitude = stats.minAltitude
        self.maxAcceleration = stats.maxAcceleration
        self.duration = stats.duration
    }
}
