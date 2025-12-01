//
//  GPMFKeys.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import CoreLocation

// GPMF FourCC keys
struct GPMFKeys {
    static let DEVICE: UInt32 = 0x44455643 // 'DEVC'
    static let GPS5: UInt32 = 0x47505335   // 'GPS5'
    static let ACCL: UInt32 = 0x4143434C   // 'ACCL'
    static let GYRO: UInt32 = 0x4759524F   // 'GYRO'
    static let TEMP: UInt32 = 0x54454D50   // 'TEMP'
    static let SCAL: UInt32 = 0x5343414C   // 'SCAL'
    static let STMP: UInt32 = 0x53544D50   // 'STMP'
    static let STRM: UInt32 = 0x5354524D   // 'STRM'
    static let DVID: UInt32 = 0x44564944   // 'DVID'
    static let DVNM: UInt32 = 0x44564E4D   // 'DVNM'
}

struct TelemetryCalculator {
    static func totalDistance(points: [TelemetryDataPoint]) -> Double {
        var total: Double = 0
        let gpsPoints = points.compactMap { $0.coordinate }
        
        for i in 1..<gpsPoints.count {
            let prev = gpsPoints[i-1]
            let curr = gpsPoints[i]
            total += calculateDistance(coord1: prev, coord2: curr)
        }
        
        return total
    }
    
    private static func calculateDistance(coord1: CLLocationCoordinate2D, coord2: CLLocationCoordinate2D) -> Double {
        let earthRadius: Double = 6371000 // meters
        
        let dLat = (coord2.latitude - coord1.latitude) * .pi / 180.0
        let dLon = (coord2.longitude - coord1.longitude) * .pi / 180.0
        
        let a = sin(dLat/2) * sin(dLat/2) +
               cos(coord1.latitude * .pi / 180.0) * cos(coord2.latitude * .pi / 180.0) *
               sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    static func calculateSpeedStatistics(points: [TelemetryDataPoint]) -> (min: Double, max: Double, average: Double) {
        let speeds = points.compactMap { $0.speed }
        guard !speeds.isEmpty else { return (0, 0, 0) }
        
        let minSpeed = speeds.min() ?? 0
        let maxSpeed = speeds.max() ?? 0
        let averageSpeed = speeds.reduce(0, +) / Double(speeds.count)
        
        return (minSpeed, maxSpeed, averageSpeed)
    }
    
    static func calculateAccelerationMagnitude(x: Double?, y: Double?, z: Double?) -> Double? {
        guard let x = x, let y = y, let z = z else { return nil }
        return sqrt(x*x + y*y + z*z)
    }
    
    static func filterPointsByTimeInterval(_ points: [TelemetryDataPoint], interval: TimeInterval) -> [TelemetryDataPoint] {
        guard let firstPoint = points.first else { return [] }
        
        var filteredPoints: [TelemetryDataPoint] = [firstPoint]
        var lastTime = firstPoint.timestamp
        
        for point in points.dropFirst() {
            if point.timestamp - lastTime >= interval {
                filteredPoints.append(point)
                lastTime = point.timestamp
            }
        }
        
        return filteredPoints
    }
}
