//
//  TimelineInspector.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 02/12/25.
//

import SwiftUI
import MapKit

struct TimelineInspector: View {
    // MARK: - Properties
    
    let data: TelemetryData
    var onClose: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Header Fixo
            headerView
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 2. Mini Mapa Contextual
                    if let coord = data.coordinate {
                        MapSection(coordinate: coord)
                    }
                    
                    // 3. Dinâmica do Veículo (Mini Gauges)
                    dynamicsSection
                    
                    // 4. Orientação Espacial (Horizonte)
                    if let orientation = data.cameraOrientation {
                        OrientationSection(orientation: orientation)
                    }
                    
                    // 5. Dados da Câmera (Grid)
                    cameraDataSection
                    
                    // 6. Diagnóstico & Ambiente (IA)
                    environmentSection
                }
                .padding(20)
            }
        }
        .frame(width: 320) // Largura padrão de sidebar macOS
        .background(.ultraThinMaterial) // Base do vidro
        .overlay(
            // Borda esquerda brilhante (separador)
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.1), .clear, .white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                Spacer()
            }
        )
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("INSPEÇÃO")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(2)
                
                Text(data.formattedTime)
                    .font(.system(size: 28, weight: .light, design: .monospaced))
                    .liquidNeon(color: .white)
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.white.opacity(0.05))
    }
    
    private var dynamicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Dinâmica", icon: "speedometer")
            
            GlassCard(depth: 0.5) {
                VStack(spacing: 16) {
                    if let speed = data.speed2D {
                        MiniGlassGauge(
                            title: "Velocidade 2D",
                            value: speed * 3.6,
                            range: 0...120, // Idealmente viria de stats globais
                            color: .cyan
                        )
                    }
                    
                    if let speed3d = data.speed3D {
                        MiniGlassGauge(
                            title: "Velocidade 3D",
                            value: speed3d * 3.6,
                            range: 0...120,
                            color: .blue
                        )
                    }
                    
                    if let acc = data.acceleration {
                        MiniGlassGauge(
                            title: "Força G Total",
                            value: acc.magnitude,
                            range: 0...3.0,
                            color: .orange
                        )
                    }
                    
                    if let alt = data.altitude {
                        HStack {
                            Text("Altitude")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.0f m", alt))
                                .font(.body.monospaced())
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
    }
    
    private var cameraDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Sensor Óptico", icon: "camera.aperture")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                
                InfoTile(
                    label: "ISO",
                    value: data.formattedISO,
                    color: .yellow
                )
                
                InfoTile(
                    label: "Shutter",
                    value: data.formattedShutter,
                    color: .cyan
                )
                
                if let wb = data.whiteBalance {
                    InfoTile(
                        label: "White Bal",
                        value: String(format: "%.0fK", wb),
                        color: .orange
                    )
                }
                
                // Temperatura do sensor
                if let temp = data.temperature {
                    InfoTile(
                        label: "Temp",
                        value: String(format: "%.0f°C", temp),
                        color: temp > 60 ? .red : .green
                    )
                }
            }
        }
    }
    
    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Ambiente & IA", icon: "cpu")
            
            GlassCard(depth: 0.5) {
                VStack(alignment: .leading, spacing: 12) {
                    // Cena
                    HStack {
                        Image(systemName: "scenekit")
                        Text("Cena Detectada")
                        Spacer()
                        if let scene = data.scene {
                            Text(scene)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.3))
                                .cornerRadius(4)
                        } else {
                            Text("--")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                    
                    Divider().overlay(.white.opacity(0.1))
                    
                    // Rostos
                    HStack {
                        Image(systemName: "face.dashed")
                        Text("Rostos")
                        Spacer()
                        if let faces = data.faces, !faces.isEmpty {
                            Text("\(faces.count)")
                                .font(.caption.bold())
                                .liquidNeon(color: .green)
                        } else {
                            Text("0")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }
}

// MARK: - Subcomponents Isolados

struct MapSection: View {
    let coordinate: CLLocationCoordinate2D
    @State private var position: MapCameraPosition
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self._position = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Map(position: $position) {
                Annotation("Ponto", coordinate: coordinate) {
                    Image(systemName: "circle.circle.fill")
                        .foregroundStyle(.cyan)
                        .background(.white)
                        .clipShape(Circle())
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .frame(height: 140)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            
            HStack {
                Text(String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Link(destination: URL(string: "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)")!) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                }
            }
        }
    }
}

struct OrientationSection: View {
    let orientation: Vector4
    
    var body: some View {
        GlassCard(tint: .indigo.opacity(0.2)) {
            HStack {
                // Reutilizando o ArtificialHorizonView definido no CameraStatusView
                // Se ele estiver privado lá, precisará ser movido para um arquivo compartilhado ou copiado.
                // Aqui assumo uma implementação visual simplificada para o Inspector.
                InspectorHorizonView(quaternion: orientation)
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Orientação")
                        .font(.caption.bold())
                    
                    Text("Giroscópio + Acelerômetro")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
        }
    }
}

struct InfoTile: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .liquidNeon(color: color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SectionLabel: View {
    let title: String
    let icon: String
    
    init(_ title: String, icon: String) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Internal Helper for Horizon

struct InspectorHorizonView: View {
    let quaternion: Vector4
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(.black.opacity(0.5))
                // Linha simples indicando o horizonte
                Rectangle()
                    .fill(.cyan)
                    .frame(width: 40, height: 2)
                    .rotationEffect(.degrees(rollAngle))
                    .offset(y: pitchOffset * 20)
            }
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.2)))
        }
    }
    
    var rollAngle: Double {
        let q = quaternion
        let sinr_cosp = 2 * (q.w * q.z + q.x * q.y)
        let cosr_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
        return atan2(sinr_cosp, cosr_cosp) * 180 / .pi
    }
    
    var pitchOffset: Double {
        let q = quaternion
        let sinp = 2 * (q.w * q.y - q.z * q.x)
        return abs(sinp) >= 1 ? (sinp > 0 ? 1 : -1) : asin(sinp) / (.pi / 2)
    }
}
