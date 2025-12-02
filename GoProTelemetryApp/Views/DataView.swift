//
//  DataView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct DataView: View {
    // MARK: - Properties
    
    let data: [TelemetryData]
    
    @State private var searchText = ""
    @State private var limit: Int = 100
    @State private var step: Int = 200
    
    // Estado de Seleção para o Inspector
    @State private var selectedPoint: TelemetryData?
    
    // MARK: - Computed Logic
    
    var filteredData: [TelemetryData] {
        let source: [TelemetryData]
        
        if searchText.isEmpty {
            source = data
        } else {
            source = data.filter { point in
                point.formattedTime.contains(searchText) ||
                (point.scene?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                String(format: "%.0f", (point.speed2D ?? 0) * 3.6).contains(searchText)
            }
        }
        
        return Array(source.prefix(limit))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 1. Fundo Imersivo
            LinearGradient(
                colors: [
                    Theme.background,
                    Theme.background.opacity(0.9),
                    Theme.Colors.neonPurple.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // 2. Área Principal (Lista)
                VStack(spacing: 0) {
                    toolbarView
                    tableHeader
                    
                    if data.isEmpty {
                        emptyState
                    } else {
                        dataList
                    }
                }
                .layoutPriority(1) // Garante que a lista ocupe o espaço disponível
                
                // 3. Painel de Inspeção Lateral (Slide-in)
                if let point = selectedPoint {
                    // Divisor Vertical Neon
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Theme.primary.opacity(0.5), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1)
                    
                    // O componente Inspector criado anteriormente
                    TimelineInspector(data: point) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedPoint = nil
                        }
                    }
                    .frame(maxWidth: 320)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(2)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var toolbarView: some View {
        HStack {
            // Busca Estilo Vidro
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.secondary)
                
                TextField("Filtrar por tempo, cena ou velocidade...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.primary)
                    .onChange(of: searchText) { _ in limit = 100 }
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Contador
            HStack(spacing: 4) {
                Text("\(filteredData.count)")
                    .liquidNeon(color: .white)
                    .font(.caption.bold().monospaced())
                Text("de \(data.count) frames")
                    .font(.caption)
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
        .padding(Theme.padding)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
    }
    
    private var tableHeader: some View {
        HStack(spacing: Theme.Spacing.small) {
            Text("TIMECODE")
                .frame(width: 80, alignment: .leading)
            
            Text("COORDENADAS / VEL")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("CENA")
                .frame(width: 80, alignment: .center)
            
            Text("SENSOR")
                .frame(width: 100, alignment: .trailing)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(Theme.secondary)
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.2)) // Header levemente mais escuro
    }
    
    private var dataList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredData) { point in
                    GlassRow(point: point, isSelected: selectedPoint?.id == point.id)
                        .contentShape(Rectangle()) // Área de clique total
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPoint = point
                            }
                        }
                }
                
                // Botão Carregar Mais
                if limit < (searchText.isEmpty ? data.count : filteredData.count) {
                    Button(action: { limit += step }) {
                        Text("Carregar mais...")
                            .font(.caption)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Theme.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 48))
                .foregroundStyle(Theme.secondary.opacity(0.3))
            Text("Aguardando Dados")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.secondary)
            Spacer()
        }
    }
}

// MARK: - Row Component (Glass Style)

struct GlassRow: View {
    let point: TelemetryData
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            // 1. Tempo (Destacado)
            Text(point.formattedTime)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Theme.primary : .primary)
                .frame(width: 80, alignment: .leading)
            
            // 2. Info Principal (Lat/Lon + Speed)
            VStack(alignment: .leading, spacing: 2) {
                if let lat = point.latitude, let lon = point.longitude {
                    Text(String(format: "%.5f, %.5f", lat, lon))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No GPS")
                        .font(.caption2)
                        .foregroundStyle(.gray.opacity(0.5))
                }
                
                // Velocidade embutida na linha principal para economizar espaço
                if let speed = point.speed2D {
                    Text(String(format: "%.1f km/h", speed * 3.6))
                        .font(.caption.bold())
                        .foregroundStyle(Theme.Colors.neonBlue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 3. Tags de Cena / Rosto (Visual Pills)
            HStack(spacing: 4) {
                if let scene = point.scene {
                    Text(scene.prefix(4)) // Abrevia (SNOW, URBA...)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.neonPurple.opacity(0.2))
                        .foregroundStyle(Theme.Colors.neonPurple)
                        .cornerRadius(4)
                }
                
                if let faces = point.faces, !faces.isEmpty {
                    Image(systemName: "face.dashed")
                        .font(.caption2)
                        .foregroundStyle(Theme.Colors.neonGreen)
                }
            }
            .frame(width: 80, alignment: .center)
            
            // 4. Dados Técnicos (Direita)
            VStack(alignment: .trailing, spacing: 2) {
                if let acc = point.acceleration {
                    Text(String(format: "%.1f G", acc.magnitude))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(acc.magnitude > 1.5 ? Theme.Colors.neonOrange : .secondary)
                }
                
                if let iso = point.iso {
                    Text("ISO \(Int(iso))")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 8)
        .background(
            // Highlight de Seleção
            isSelected ? Theme.primary.opacity(0.1) : Color.clear
        )
        .overlay(
            // Borda inferior sutil
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.white.opacity(0.05)),
            alignment: .bottom
        )
    }
}

// MARK: - Preview

#Preview("Data Timeline") {
    DataView(data: [
        TelemetryData(
            timestamp: 0.0,
            latitude: -23.5505, longitude: -46.6333, altitude: 760,
            speed2D: 12.5, speed3D: 12.6,
            acceleration: Vector3(x: 0.1, y: 0.1, z: 0.98),
            gravity: nil, gyro: nil, cameraOrientation: nil, imageOrientation: nil,
            iso: 100, shutterSpeed: 0.01, whiteBalance: 5500, whiteBalanceRGB: nil,
            temperature: 42, audioDiagnostic: nil, faces: nil, scene: "CITY"
        ),
        TelemetryData(
            timestamp: 1.0,
            latitude: -23.5506, longitude: -46.6334, altitude: 761,
            speed2D: 15.0, speed3D: 15.1,
            acceleration: Vector3(x: 0.5, y: 0.2, z: 1.2), // High G
            gravity: nil, gyro: nil, cameraOrientation: nil, imageOrientation: nil,
            iso: 200, shutterSpeed: 0.005, whiteBalance: 5500, whiteBalanceRGB: nil,
            temperature: 43, audioDiagnostic: nil, faces: [DetectedFace(id: 1, x: 0, y: 0, w: 0, h: 0)], scene: nil
        )
    ])
    .frame(width: 900, height: 500)
}
