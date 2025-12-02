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
    @State private var limit: Int = 100 // Começa leve para abrir instantâneo
    @State private var step: Int = 500  // Carrega em blocos maiores
    
    // MARK: - Computed Logic
    
    /// Filtra e limita os dados para exibição segura
    var filteredData: [TelemetryData] {
        let source: [TelemetryData]
        
        if searchText.isEmpty {
            source = data
        } else {
            // Busca rápida por tempo, cena ou velocidade
            source = data.filter { point in
                point.formattedTime.contains(searchText) ||
                (point.scene?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                String(format: "%.0f", point.speed2D ?? 0 * 3.6).contains(searchText)
            }
        }
        
        // Retorna apenas o slice até o limite atual
        return Array(source.prefix(limit))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Barra de Ferramentas
            headerView
            
            // 2. Cabeçalho da Tabela
            tableHeader
            
            // 3. Lista de Dados
            if data.isEmpty {
                EmptyStateView(
                    title: "Sem Dados",
                    systemImage: "list.bullet.rectangle.portrait",
                    description: "Nenhum ponto de telemetria encontrado neste vídeo."
                )
            } else {
                dataList
            }
        }
        .background(Theme.background)
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            // Campo de Busca
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.secondary)
                
                TextField("Buscar tempo, cena (ex: SNOW) ou velocidade...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _ in
                        limit = 100 // Reseta paginação ao buscar
                    }
            }
            .padding(8)
            .background(Theme.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.secondary.opacity(0.2), lineWidth: 1)
            )
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Contador
            Text("\(filteredData.count) de \(data.count) pontos")
                .font(Theme.Font.label)
                .foregroundColor(Theme.secondary)
        }
        .padding(Theme.padding)
        .background(Theme.surfaceSecondary)
    }
    
    private var tableHeader: some View {
        HStack(spacing: Theme.Spacing.small) {
            Text("Tempo")
                .frame(width: 70, alignment: .leading)
            
            Text("Coordenadas")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Novas colunas de Câmera/IA
            Text("Cena / Cam")
                .frame(width: 80, alignment: .center)
            
            Text("Alt")
                .frame(width: 60, alignment: .trailing)
            
            Text("Vel")
                .frame(width: 70, alignment: .trailing)
            
            Text("G-Force")
                .frame(width: 60, alignment: .trailing)
        }
        .font(Theme.Font.label)
        .foregroundColor(Theme.secondary)
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, 8)
        .background(Theme.background)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Theme.secondary.opacity(0.1)), alignment: .bottom)
    }
    
    private var dataList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Linhas de Dados
                ForEach(filteredData) { point in
                    DataRow(point: point)
                        .padding(.horizontal, Theme.padding)
                        .padding(.vertical, 6)
                        .background(
                            // Zebrado para facilitar leitura
                            point.id.hashValue % 2 == 0 ? Theme.surface.opacity(0.3) : Color.clear
                        )
                    
                    Divider().opacity(0.3)
                }
                
                // Botão "Carregar Mais"
                if limit < (searchText.isEmpty ? data.count : filteredData.count) {
                    loadMoreButton
                }
            }
            .padding(.bottom, Theme.padding)
        }
    }
    
    private var loadMoreButton: some View {
        Button(action: {
            limit += step
        }) {
            HStack {
                Image(systemName: "arrow.down.circle")
                Text("Carregar mais \(step) pontos")
            }
            .font(Theme.Font.label)
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundColor(Theme.primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Row Component

struct DataRow: View {
    let point: TelemetryData
    
    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            // 1. Tempo
            Text(point.formattedTime)
                .font(Theme.Font.mono)
                .foregroundColor(Theme.primary)
                .frame(width: 70, alignment: .leading)
            
            // 2. Coordenadas (GPS)
            if let lat = point.latitude, let lon = point.longitude {
                Text(String(format: "%.5f, %.5f", lat, lon))
                    .font(Theme.Font.mono)
                    .scaleEffect(0.9) // Leve redução para caber
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            } else {
                Text("---")
                    .font(Theme.Font.mono)
                    .foregroundColor(Theme.secondary.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 3. Dados Extras (Cena / ISO) - NOVO
            VStack(alignment: .center, spacing: 2) {
                if let scene = point.scene {
                    Text(scene)
                        .font(.caption2.bold())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(3)
                }
                
                if let iso = point.iso {
                    Text("ISO \(Int(iso))")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, alignment: .center)
            
            // 4. Altitude
            if let alt = point.altitude {
                Text(String(format: "%.0f", alt))
                    .font(Theme.Font.mono)
                    .foregroundColor(Theme.secondary)
                    .frame(width: 60, alignment: .trailing)
            } else {
                Text("-")
                    .frame(width: 60, alignment: .trailing)
                    .foregroundColor(Theme.secondary.opacity(0.3))
            }
            
            // 5. Velocidade
            Text(point.formattedSpeed)
                .font(Theme.Font.mono)
                .fontWeight(.medium)
                .foregroundColor(Theme.Data.color(for: .gps))
                .frame(width: 70, alignment: .trailing)
            
            // 6. G-Force
            if let acc = point.acceleration {
                Text(String(format: "%.1f", acc.magnitude))
                    .font(Theme.Font.mono)
                    .foregroundColor(acc.magnitude > 1.5 ? Theme.warning : Theme.secondary)
                    .frame(width: 60, alignment: .trailing)
            } else {
                Text("-")
                    .font(Theme.Font.mono)
                    .foregroundColor(Theme.secondary.opacity(0.3))
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .font(.system(size: 13)) // Tamanho base para densidade de dados
    }
}

// MARK: - Preview

#Preview {
    DataView(data: [
        TelemetryData(
            timestamp: 0.0,
            latitude: -25.4284, longitude: -49.2733, altitude: 930,
            speed2D: 0, speed3D: 0,
            acceleration: Vector3(x: 0, y: 0, z: 1.0),
            gravity: nil, gyro: nil, cameraOrientation: nil, imageOrientation: nil,
            iso: 100, shutterSpeed: 0.01, whiteBalance: 5500, whiteBalanceRGB: nil,
            temperature: 35, audioDiagnostic: nil, faces: nil,
            scene: "SNOW"
        ),
        TelemetryData(
            timestamp: 1.0,
            latitude: -25.4285, longitude: -49.2734, altitude: 931,
            speed2D: 15.5, speed3D: 0,
            acceleration: Vector3(x: 0.5, y: 0.2, z: 1.2),
            gravity: nil, gyro: nil, cameraOrientation: nil, imageOrientation: nil,
            iso: 200, shutterSpeed: 0.005, whiteBalance: 5500, whiteBalanceRGB: nil,
            temperature: 36, audioDiagnostic: nil, faces: nil,
            scene: nil
        )
    ])
    .frame(width: 900, height: 500)
}
