//
//  TelemetryData.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import CoreLocation

struct TelemetryDataPoint: Identifiable, Codable {
    let id: UUID
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
    
    init(id: UUID = UUID(),
         timestamp: Double,
         latitude: Double? = nil,
         longitude: Double? = nil,
         altitude: Double? = nil,
         speed: Double? = nil,
         accelerationX: Double? = nil,
         accelerationY: Double? = nil,
         accelerationZ: Double? = nil,
         gyroX: Double? = nil,
         gyroY: Double? = nil,
         gyroZ: Double? = nil,
         temperature: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.speed = speed
        self.accelerationX = accelerationX
        self.accelerationY = accelerationY
        self.accelerationZ = accelerationZ
        self.gyroX = gyroX
        self.gyroY = gyroY
        self.gyroZ = gyroZ
        self.temperature = temperature
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

struct TelemetrySession: Identifiable, Codable {
    let id: UUID
    let videoURL: URL
    let duration: TimeInterval
    let points: [TelemetryDataPoint]
    let startTime: Date
    let deviceName: String
    
    init(id: UUID = UUID(),
         videoURL: URL,
         duration: TimeInterval,
         points: [TelemetryDataPoint],
         startTime: Date,
         deviceName: String) {
        self.id = id
        self.videoURL = videoURL
        self.duration = duration
        self.points = points
        self.startTime = startTime
        self.deviceName = deviceName
    }
    
    var hasGPS: Bool {
        points.contains { $0.latitude != nil && $0.longitude != nil }
    }
    
    var hasIMU: Bool {
        points.contains { $0.accelerationX != nil }
    }
    
    var statistics: TelemetryStatistics {
        TelemetryStatistics(session: self)
    }
}

struct TelemetryStatistics: Codable {
    let totalDistance: Double
    let maxSpeed: Double
    let avgSpeed: Double
    let maxAltitude: Double
    let minAltitude: Double
    let maxAcceleration: Double
    let duration: TimeInterval
    
    init(session: TelemetrySession) {
        let speeds = session.points.compactMap { $0.speed }
        let altitudes = session.points.compactMap { $0.altitude }
        let accelerations = session.points.compactMap { point -> Double? in
            guard let x = point.accelerationX,
                  let y = point.accelerationY,
                  let z = point.accelerationZ else {
                return nil
            }
            return sqrt(x*x + y*y + z*z)
        }
        
        self.maxSpeed = speeds.max() ?? 0
        self.avgSpeed = speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
        self.maxAltitude = altitudes.max() ?? 0
        self.minAltitude = altitudes.min() ?? 0
        self.maxAcceleration = accelerations.max() ?? 0
        self.duration = session.duration
        
        // Calculate total distance
        self.totalDistance = TelemetryCalculator.totalDistance(points: session.points)
    }
}

// Extension para codificar/decodificar URL
extension URL: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let urlString = try container.decode(String.self)
        
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid URL string: \(urlString)"
            )
        }
        
        self = url
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.absoluteString)
    }
}
