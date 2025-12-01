//
//  UIComponents.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI
import MapKit


// MARK: - Buttons
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isLoading ? Color.gray : Theme.primaryColor)
                    .shadow(color: .black.opacity(0.3), radius: isHovered ? 16 : 8, x: 0, y: isHovered ? 8 : 4)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .disabled(isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(Theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.primaryColor.opacity(0.3), lineWidth: 1)
                    .background(Color.black.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Theme.primaryColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Statistics & Badges
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @State private var isHovered = false
    
    init(icon: String, value: String, label: String, color: Color = Theme.primaryColor) {
        self.icon = icon
        self.value = value
        self.label = label
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Filter & Toggle Components
struct DataTypeFilterButton: View {
    let type: TelemetryType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(type.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ToggleOption: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.primaryColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
        }
    }
}

// MARK: - Map Components
struct InteractiveMapView: View {
    let points: [TelemetryDataPoint]
    
    @State private var region: MKCoordinateRegion
    @State private var mapType: MapViewType = .standard
    
    // Renamed to avoid conflict with MapKit's MapStyle
    enum MapViewType: CaseIterable {
        case standard, hybrid, satellite
        
        var name: String {
            switch self {
            case .standard: return "Padrão"
            case .hybrid: return "Híbrido"
            case .satellite: return "Satélite"
            }
        }
    }
    
    init(points: [TelemetryDataPoint]) {
        self.points = points
        let coordinates = points.compactMap { $0.coordinate }
        
        if let firstCoord = coordinates.first, coordinates.count > 1 {
            var minLat = firstCoord.latitude
            var maxLat = firstCoord.latitude
            var minLon = firstCoord.longitude
            var maxLon = firstCoord.longitude
            
            for coord in coordinates {
                minLat = min(minLat, coord.latitude)
                maxLat = max(maxLat, coord.latitude)
                minLon = min(minLon, coord.longitude)
                maxLon = max(maxLon, coord.longitude)
            }
            
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: (maxLat - minLat) * 1.2,
                longitudeDelta: (maxLon - minLon) * 1.2
            )
            
            _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(coordinateRegion: $region, annotationItems: points.compactMap { $0.coordinate }.map { CoordinateWrapper(coordinate: $0) }) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Image(systemName: "location.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .background(Circle().fill(.white))
                }
            }
            
            VStack(spacing: 8) {
                MapTypePicker(mapType: $mapType)
                MapControls(region: $region, points: points)
            }
            .padding(8)
        }
    }
}

struct MapTypePicker: View {
    @Binding var mapType: InteractiveMapView.MapViewType
    
    var body: some View {
        Picker("Tipo de Mapa", selection: $mapType) {
            ForEach(InteractiveMapView.MapViewType.allCases, id: \.self) { type in
                Text(type.name).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct MapControls: View {
    @Binding var region: MKCoordinateRegion
    let points: [TelemetryDataPoint]
    
    var coordinates: [CLLocationCoordinate2D] {
        points.compactMap { $0.coordinate }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            MapControlButton(icon: "plus", action: zoomIn)
            MapControlButton(icon: "minus", action: zoomOut)
            MapControlButton(icon: "location", action: fitToRoute)
        }
    }
    
    private func zoomIn() {
        withAnimation {
            region.span.latitudeDelta /= 1.5
            region.span.longitudeDelta /= 1.5
        }
    }
    
    private func zoomOut() {
        withAnimation {
            region.span.latitudeDelta *= 1.5
            region.span.longitudeDelta *= 1.5
        }
    }
    
    private func fitToRoute() {
        guard let firstCoord = coordinates.first, coordinates.count > 1 else { return }
        
        var minLat = firstCoord.latitude
        var maxLat = firstCoord.latitude
        var minLon = firstCoord.longitude
        var maxLon = firstCoord.longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2,
            longitudeDelta: (maxLon - minLon) * 1.2
        )
        
        withAnimation {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct MapControlButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.8))
                .cornerRadius(8)
                .scaleEffect(isHovered ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Progress & Loading
struct ProcessingView: View {
    let progress: Double
    let status: String
    
    var body: some View {
        VStack(spacing: Theme.spacingXLarge) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Theme.cardBackground, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.primaryGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(Theme.primaryGradient)
            }
            
            VStack(spacing: Theme.spacingMedium) {
                Text("Processando Telemetria")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text(status)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                ProgressBar(progress: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
        }
        .padding(Theme.spacingXLarge)
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.primaryGradient)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 8)
        .padding(.horizontal, 100)
    }
}
