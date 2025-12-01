//
//  MapView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
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

/// Wrapper para usar o MKMapView clássico no SwiftUI (necessário para Polylines customizadas no macOS 13)
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
        // Atualiza o tipo do mapa
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }
        
        // Verifica se os dados mudaram para não redesenhar à toa
        // Usamos o ID do primeiro ponto como "hash" simples da sessão
        let currentSessionId = data.first?.id
        
        if context.coordinator.lastSessionId != currentSessionId {
            updateOverlays(on: mapView, context: context)
            context.coordinator.lastSessionId = currentSessionId
        }
    }
    
    private func updateOverlays(on mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        guard !data.isEmpty else { return }
        
        // 1. Criar Polyline (Linha do trajeto)
        let coordinates = data.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        
        // 2. Adicionar Pinos de Início e Fim
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
        
        // 3. Ajustar Zoom para caber tudo
        // Adiciona um padding para a linha não ficar colada na borda
        let rect = polyline.boundingMapRect
        mapView.setVisibleMapRect(rect, edgePadding: NSEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapContainer
        var lastSessionId: UUID? // Para evitar updates desnecessários
        
        init(_ parent: MapContainer) {
            self.parent = parent
        }
        
        // Renderizador da Linha (Cor e Espessura)
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Usa a cor do Tema (convertida para NSColor)
                renderer.strokeColor = NSColor(Theme.Data.color(for: .gps))
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // Renderizador dos Pinos (Start/End)
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
            
            // Customiza as cores dos pinos
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

// MARK: - Preview

#Preview {
    MapView(telemetryData: [
        TelemetryData(timestamp: 0, latitude: -25.4284, longitude: -49.2733, altitude: 0, speed2D: 0, speed3D: 0, acceleration: nil, gyro: nil),
        TelemetryData(timestamp: 1, latitude: -25.4290, longitude: -49.2740, altitude: 0, speed2D: 0, speed3D: 0, acceleration: nil, gyro: nil),
        TelemetryData(timestamp: 2, latitude: -25.4300, longitude: -49.2750, altitude: 0, speed2D: 0, speed3D: 0, acceleration: nil, gyro: nil)
    ])
    .frame(width: 800, height: 600)
}
