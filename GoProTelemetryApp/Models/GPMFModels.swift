//
//  GPMFModels.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import CoreGraphics

enum GPMFError: Error {
    case invalidData
    case parsingFailed
    case unsupportedFormat
    case fileAccessDenied
}

enum TelemetryType: String, CaseIterable {
    case gps = "GPS"
    case accelerometer = "Acelerômetro"
    case gyroscope = "Giroscópio"
    case temperature = "Temperatura"
    case camera = "Câmera"
    
    var icon: String {
        switch self {
        case .gps: return "location.fill"
        case .accelerometer: return "gauge.with.dots.needle.bottom.50percent"
        case .gyroscope: return "gyroscope"
        case .temperature: return "thermometer"
        case .camera: return "camera.fill"
        }
    }
}

struct GPMFStreamInfo {
    let type: TelemetryType
    let sampleCount: Int
    let elementsPerSample: Int
    let dataSize: Int
    
    init(type: TelemetryType, sampleCount: Int, elementsPerSample: Int, dataSize: Int) {
        self.type = type
        self.sampleCount = sampleCount
        self.elementsPerSample = elementsPerSample
        self.dataSize = dataSize
    }
    
    init(from stream: GPMFStream) {
        self.type = stream.type.toTelemetryType()
        self.sampleCount = stream.sampleCount
        self.elementsPerSample = stream.elementsPerSample
        self.dataSize = stream.samples.count * stream.elementsPerSample * 8 // Aproximação: 8 bytes por valor double
    }
}

// MARK: - VideoInfo
struct VideoInfo {
    let duration: TimeInterval
    let creationDate: Date?
    let resolution: CGSize?
    let frameRate: Float?
    let fileSize: Int64?
    let codec: String?
}

// MARK: - GPMFStream
struct GPMFStream {
    let type: GPMFStreamType
    let samples: [GPMFSample]
    let sampleCount: Int
    let elementsPerSample: Int
    let sampleRate: Double
}

// MARK: - GPMFSample
struct GPMFSample {
    let timestamp: Double
    let values: [Double]
}

// MARK: - GPMFStreamType
enum GPMFStreamType: String {
    case gps5 = "GPS5"
    case gps9 = "GPS9"
    case gpsu = "GPSU"
    case accl = "ACCL"
    case gyro = "GYRO"
    case temp = "TMPC"
    case cori = "CORI"
    case grav = "GRAV"
    case iorients = "IORI"
    case unknown = "UNKN"
    
    static func from(fourCC: String) -> GPMFStreamType {
        let upper = fourCC.uppercased()
        switch upper {
        case "GPS5": return .gps5
        case "GPS9": return .gps9
        case "GPSU": return .gpsu
        case "ACCL": return .accl
        case "GYRO": return .gyro
        case "TMPC": return .temp
        case "CORI": return .cori
        case "GRAV": return .grav
        case "IORI": return .iorients
        default: return .unknown
        }
    }
    
    func toTelemetryType() -> TelemetryType {
        switch self {
        case .gps5, .gps9, .gpsu:
            return .gps
        case .accl:
            return .accelerometer
        case .gyro:
            return .gyroscope
        case .temp:
            return .temperature
        default:
            return .camera
        }
    }
}
