//
//  Extensions.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import CoreLocation
import AppKit

// Remove a conformidade redundante e use uma struct wrapper
struct CoordinateWrapper: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension UInt32 {
    var fourCCString: String {
        let bytes = [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii) ?? "????"
    }
}

extension Date {
    func formattedForFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: self)
    }
}

extension Double {
    func formatted(precision: Int = 2) -> String {
        return String(format: "%.\(precision)f", self)
    }
}

// Extension para facilitar o uso com AppKit
extension NSImage {
    convenience init?(systemName: String) {
        self.init(systemSymbolName: systemName, accessibilityDescription: nil)
    }
}

// Extension para Array para facilitar o uso com Map
extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var results: [T] = []
        for element in self {
            let result = try await transform(element)
            results.append(result)
        }
        return results
    }
    
    func concurrentMap<T>(_ transform: @escaping (Element) async throws -> T) async throws -> [T] {
        try await withThrowingTaskGroup(of: T.self) { group in
            for element in self {
                group.addTask {
                    try await transform(element)
                }
            }
            
            var results: [T] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}
