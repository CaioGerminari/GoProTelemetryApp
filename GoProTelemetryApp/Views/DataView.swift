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
        let source = searchText.isEmpty ? data : data.filter { point in
            // Busca rápida por tempo ou velocidade
            point.formattedTime.contains(searchText) ||
            String(format: "%.0f", point.speed2D * 3.6).contains(searchText)
        }
        
        // Retorna apenas o slice até o limite atual
        return Array(source.prefix(limit))
    }
    
    var totalCount: Int {
        searchText.isEmpty ? data.count : filteredData.count
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Barra de Ferramentas (Busca e Contagem)
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
                
                TextField("Buscar tempo (ex: 12.5) ou velocidade...", text: $searchText)
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
                .frame(width: 80, alignment: .leading)
            
            Text("Coordenadas (Lat, Lon)")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Alt")
                .frame(width: 70, alignment: .trailing)
            
            Text("Vel (2D)")
                .frame(width: 80, alignment: .trailing)
            
            Text("G-Force")
                .frame(width: 70, alignment: .trailing)
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
                            // Alternância de cor zebrada (opcional, mas ajuda a leitura)
                            point.id.hashValue % 2 == 0 ? Theme.surface.opacity(0.3) : Color.clear
                        )
                    
                    Divider().opacity(0.3)
                }
                
                // Botão "Carregar Mais"
                if limit < (searchText.isEmpty ? data.count : Int.max) {
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
            // Tempo
            Text(point.formattedTime)
                .font(Theme.Font.mono)
                .foregroundColor(Theme.primary)
                .frame(width: 80, alignment: .leading)
            
            // Lat/Lon
            Text(String(format: "%.5f, %.5f", point.latitude, point.longitude))
                .font(Theme.Font.mono)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            
            // Altitude
            Text(point.formattedAltitude)
                .font(Theme.Font.mono)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)
            
            // Velocidade
            Text(point.formattedSpeed)
                .font(Theme.Font.mono)
                .fontWeight(.medium)
                .foregroundColor(Theme.Data.color(for: .gps))
                .frame(width: 80, alignment: .trailing)
            
            // Aceleração (Magnitude)
            if let acc = point.acceleration {
                Text(String(format: "%.1f G", acc.magnitude))
                    .font(Theme.Font.mono)
                    .foregroundColor(acc.magnitude > 1.5 ? Theme.warning : Theme.secondary)
                    .frame(width: 70, alignment: .trailing)
            } else {
                Text("-")
                    .font(Theme.Font.mono)
                    .foregroundColor(Theme.secondary.opacity(0.3))
                    .frame(width: 70, alignment: .trailing)
            }
        }
        .font(.system(size: 13)) // Tamanho base para densidade de dados
    }
}

// MARK: - Preview

#Preview {
    DataView(data: [
        TelemetryData(timestamp: 0.0, latitude: -25.4284, longitude: -49.2733, altitude: 930, speed2D: 0, speed3D: 0, acceleration: nil, gyro: nil),
        TelemetryData(timestamp: 1.0, latitude: -25.4285, longitude: -49.2734, altitude: 931, speed2D: 5.5, speed3D: 5.6, acceleration: Vector3(x: 0, y: 0, z: 1.2), gyro: nil),
        TelemetryData(timestamp: 2.0, latitude: -25.4286, longitude: -49.2735, altitude: 932, speed2D: 12.0, speed3D: 12.1, acceleration: Vector3(x: 0.5, y: 0.2, z: 0.9), gyro: nil)
    ])
    .frame(width: 800, height: 500)
}
