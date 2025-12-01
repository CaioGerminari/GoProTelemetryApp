//
//  MapView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    let points: [TelemetryDataPoint]
    
    var coordinates: [CLLocationCoordinate2D] {
        points.compactMap { $0.coordinate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMedium) {
            headerSection
            
            if coordinates.count > 1 {
                InteractiveMapView(points: points)
                    .frame(height: 350)
                    .cornerRadius(12)
            } else {
                noDataView
            }
        }
        .padding(Theme.spacingLarge)
        .modernCard()
        .padding(Theme.spacingLarge)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Label("Trajeto GPS", systemImage: "map")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            Text("\(coordinates.count) pontos no mapa")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
    }
    
    // MARK: - No Data View
    private var noDataView: some View {
        ZStack {
            Color.black.opacity(0.2)
            VStack(spacing: Theme.spacingSmall) {
                Image(systemName: "location.slash")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.textSecondary)
                Text("Sem dados GPS disponíveis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(height: 200)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    MapView(points: [
        TelemetryDataPoint(
            timestamp: 0,
            latitude: -23.5505,
            longitude: -46.6333,
            altitude: 760,
            speed: 15.0,
            accelerationX: 0.1,
            accelerationY: 0.2,
            accelerationZ: 9.8,
            gyroX: 0.05,
            gyroY: 0.1,
            gyroZ: 0.02,
            temperature: 25.0
        ),
        TelemetryDataPoint(
            timestamp: 1,
            latitude: -23.5510,
            longitude: -46.6340,
            altitude: 765,
            speed: 18.0,
            accelerationX: 0.2,
            accelerationY: 0.1,
            accelerationZ: 9.7,
            gyroX: 0.06,
            gyroY: 0.09,
            gyroZ: 0.03,
            temperature: 26.0
        ),
        TelemetryDataPoint(
            timestamp: 2,
            latitude: -23.5515,
            longitude: -46.6350,
            altitude: 770,
            speed: 20.0,
            accelerationX: 0.3,
            accelerationY: 0.05,
            accelerationZ: 9.6,
            gyroX: 0.07,
            gyroY: 0.08,
            gyroZ: 0.04,
            temperature: 27.0
        )
    ])
    .frame(width: 800, height: 500)
}

#Preview("No Data") {
    MapView(points: [
        TelemetryDataPoint(
            timestamp: 0,
            latitude: nil,
            longitude: nil,
            altitude: nil,
            speed: nil,
            accelerationX: 0.1,
            accelerationY: 0.2,
            accelerationZ: 9.8,
            gyroX: 0.05,
            gyroY: 0.1,
            gyroZ: 0.02,
            temperature: 25.0
        )
    ])
    .frame(width: 800, height: 500)
}
