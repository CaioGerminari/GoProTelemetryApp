//
//  ContentView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = TelemetryViewModel()
    @State private var selectedTab: Int = 0
    @State private var isDropTargeted: Bool = false
    
    var body: some View {
        ZStack {
            // 1. Conteúdo Principal
            if viewModel.session != nil {
                MainTabView(viewModel: viewModel, selectedTab: $selectedTab)
            } else {
                WelcomeView(viewModel: viewModel, isTargeted: isDropTargeted)
            }
            
            // 2. Overlays Globais (Loading & Erro)
            if viewModel.isProcessing {
                LoadingView(message: viewModel.processingMessage)
            }
        }
        // Configurações da Janela
        .frame(minWidth: 1000, minHeight: 900)
        .background(Theme.background)
        .alert("Ocorreu um erro", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Erro desconhecido.")
        }
        // Suporte a Drag & Drop
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Helpers
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
            DispatchQueue.main.async {
                if let data = urlData as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    Task {
                        await viewModel.processVideo(url: url)
                    }
                }
            }
        }
        return true
    }
}

// MARK: - Subviews

/// Tela principal com abas quando há uma sessão ativa
struct MainTabView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    @Binding var selectedTab: Int
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Aba 1: Dashboard
            TelemetryView(viewModel: viewModel)
                .tabItem {
                    Label("Resumo", systemImage: "speedometer")
                }
                .tag(0)
            
            // Aba 2: Mapa
            MapView(telemetryData: viewModel.session?.dataPoints ?? [])
                .tabItem {
                    Label("Mapa", systemImage: "map")
                }
                .tag(1)
            
            // Aba 3: Gráficos
            ChartsView(data: viewModel.session?.dataPoints ?? [])
                .tabItem {
                    Label("Gráficos", systemImage: "chart.xyaxis.line")
                }
                .tag(2)
            
            // Aba 4: Lista de Dados
            DataView(data: viewModel.session?.dataPoints ?? [])
                .tabItem {
                    Label("Dados", systemImage: "list.bullet.rectangle")
                }
                .tag(3)
            
            // Aba 5: Exportação
            ExportView(viewModel: viewModel)
                .tabItem {
                    Label("Exportar", systemImage: "square.and.arrow.up")
                }
                .tag(4)
        }
        .padding(Theme.Spacing.small)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: viewModel.clearSession) {
                    Label("Fechar Vídeo", systemImage: "xmark.circle")
                }
            }
        }
    }
}

/// Tela de boas-vindas (Estado vazio)
struct WelcomeView: View {
    @ObservedObject var viewModel: TelemetryViewModel
    var isTargeted: Bool
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: Theme.Spacing.extraLarge) {
            Spacer()
            
            // Header
            VStack(spacing: Theme.Spacing.medium) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 80))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .symbolEffect(.bounce, options: .repeating, value: isHovering)
                
                Text("GoPro Telemetry Extractor")
                    .font(Theme.Font.valueLarge)
                    .foregroundColor(Theme.primary)
                
                Text("Arraste seu vídeo aqui ou clique para selecionar")
                    .font(.title3)
                    .foregroundColor(Theme.secondary)
            }
            .onHover { isHovering = $0 }
            
            // Botão Principal
            Button(action: {
                viewModel.selectFile()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Selecionar Arquivo")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Theme.primary)
            
            // Feature Grid (Resumido)
            HStack(spacing: 40) {
                FeatureItem(icon: "map.fill", text: "GPS Track")
                FeatureItem(icon: "chart.bar.fill", text: "Sensores IMU")
                FeatureItem(icon: "square.and.arrow.up.fill", text: "Exportação")
            }
            .padding(.top, 40)
            .opacity(0.6)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Feedback visual do Drag & Drop
        .background(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(isTargeted ? Theme.primary : Color.clear, lineWidth: 4)
                .background(isTargeted ? Theme.primary.opacity(0.1) : Color.clear)
        )
        .padding(20)
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(text)
                .font(.caption)
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    ContentView()
}
