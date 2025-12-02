//
//  MapView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

//
//  MapView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//  Refatorado: Correção de optionals para MapKit.
//

import SwiftUI
import MapKit

struct MapView: View {
    // MARK: - Properties
    
    let telemetryData: [TelemetryData]
    
    @State private var mapType: MKMapType = .standard
    @State private var showControls: Bool = true
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 1. O Mapa Nativo
            if telemetryData.isEmpty {
                EmptyStateView(
                    title: "Sem Dados de GPS",
                    systemImage: "location.slash",
                    description: "Este vídeo não possui dados de localização válidos."
                )
                .background(Theme.background)
            } else {
                MapContainer(data: telemetryData, mapType: mapType)
                    .ignoresSafeArea()
            }
            
            // 2. Controles Flutuantes
            if !telemetryData.isEmpty {
                mapControls
                    .padding(Theme.padding)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var mapControls: some View {
        VStack(spacing: 8) {
            Picker("Tipo de Mapa", selection: $mapType) {
                Text("Padrão").tag(MKMapType.standard)
                Text("Híbrido").tag(MKMapType.hybrid)
                Text("Satélite").tag(MKMapType.satellite)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .padding(8)
            .background(.thinMaterial)
            .cornerRadius(Theme.cornerRadius)
            .shadow(radius: 4)
        }
    }
}

// MARK: - MapKit Wrapper (NSViewRepresentable)

struct MapContainer: NSViewRepresentable {
    let data: [TelemetryData]
    let mapType: MKMapType
    
    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsZoomControls = true
        
        return mapView
    }
    
    func updateNSView(_ mapView: MKMapView, context: Context) {
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }
        
        let currentSessionId = data.first?.id
        
        if context.coordinator.lastSessionId != currentSessionId {
            updateOverlays(on: mapView, context: context)
            context.coordinator.lastSessionId = currentSessionId
        }
    }
    
    private func updateOverlays(on mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        // CORREÇÃO: Filtrar apenas coordenadas válidas (não opcionais)
        let coordinates = data.compactMap { $0.coordinate }
        
        guard !coordinates.isEmpty else { return }
        
        // 1. Criar Polyline
        // O construtor do MKPolyline espera um ponteiro UnsafePointer<CLLocationCoordinate2D>
        // Swift converte array [CLLocationCoordinate2D] automaticamente para ponteiro
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        // 2. Adicionar Pinos
        if let start = coordinates.first {
            let startPin = MKPointAnnotation()
            startPin.coordinate = start
            startPin.title = "Início"
            mapView.addAnnotation(startPin)
        }
        
        if let end = coordinates.last {
            let endPin = MKPointAnnotation()
            endPin.coordinate = end
            endPin.title = "Fim"
            mapView.addAnnotation(endPin)
        }
        
        // 3. Zoom
        let rect = polyline.boundingMapRect
        mapView.setVisibleMapRect(rect, edgePadding: NSEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapContainer
        var lastSessionId: UUID?
        
        init(_ parent: MapContainer) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = NSColor(Theme.Data.color(for: .gps))
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is MKPointAnnotation else { return nil }
            
            let identifier = "Pin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if annotation.title == "Início" {
                annotationView?.markerTintColor = .green
                annotationView?.glyphImage = NSImage(systemSymbolName: "play.fill", accessibilityDescription: nil)
            } else {
                annotationView?.markerTintColor = .red
                annotationView?.glyphImage = NSImage(systemSymbolName: "flag.checkered", accessibilityDescription: nil)
            }
            
            return annotationView
        }
    }
}

// MARK: - Preview (Mock Data Updated)

#Preview {
    MapView(telemetryData: [
        TelemetryData(
            timestamp: 0,
            latitude: -25.4284, longitude: -49.2733, altitude: 0,
            speed2D: 0, speed3D: 0,
            acceleration: nil, gravity: nil, gyro: nil,
            cameraOrientation: nil, imageOrientation: nil,
            iso: nil, shutterSpeed: nil, whiteBalance: nil, whiteBalanceRGB: nil,
            temperature: nil, audioDiagnostic: nil, faces: nil, scene: nil
        ),
        TelemetryData(
            timestamp: 1,
            latitude: -25.4290, longitude: -49.2740, altitude: 0,
            speed2D: 0, speed3D: 0,
            acceleration: nil, gravity: nil, gyro: nil,
            cameraOrientation: nil, imageOrientation: nil,
            iso: nil, shutterSpeed: nil, whiteBalance: nil, whiteBalanceRGB: nil,
            temperature: nil, audioDiagnostic: nil, faces: nil, scene: nil
        )
    ])
    .frame(width: 800, height: 600)
}
