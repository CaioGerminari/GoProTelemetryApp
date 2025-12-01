//
//  UIComponents.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

// MARK: - Cards

/// Card principal para exibir estatísticas no Dashboard (ex: Velocidade Máx)
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = Theme.primary // Cor padrão do tema
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            // Header do Card
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .cornerRadius(Theme.smallCornerRadius)
                
                Spacer()
            }
            
            // Conteúdo
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(Theme.Font.valueLarge)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text(title)
                    .font(Theme.Font.label)
                    .foregroundColor(Theme.secondary)
            }
        }
        .padding(Theme.padding)
        .cardStyle() // Usa o modificador definido no Theme.swift
    }
}

// MARK: - Badges & Labels

/// Etiqueta colorida para status ou categorias (ex: "4K", "GPS")
struct InfoBadge: View {
    let text: String
    var color: Color = Theme.secondary
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption2.weight(.bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(4)
    }
}

/// Cabeçalho de seção padronizado para listas
struct SectionHeader: View {
    let title: String
    let icon: String?
    
    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(Theme.primary)
            }
            Text(title)
                .font(Theme.Font.title)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.small)
    }
}

// MARK: - Feedback & Loading

/// Tela de carregamento modal (Overlay)
struct LoadingView: View {
    let message: String
    
    var body: some View {
        ZStack {
            // Fundo escurecido
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Caixa de diálogo
            VStack(spacing: Theme.Spacing.medium) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(Theme.Spacing.extraLarge)
            .background(.ultraThinMaterial) // Efeito de vidro (Blur)
            .cornerRadius(Theme.cornerRadius)
            .shadow(radius: 20)
        }
    }
}

/// Estado de "Vazio" (Empty State) para listas ou gráficos
struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(Theme.secondary.opacity(0.5))
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Previews

#Preview("Components Gallery") {
    VStack(spacing: 20) {
        HStack {
            StatCard(title: "Velocidade Máxima", value: "120 km/h", icon: "speedometer", color: .orange)
            StatCard(title: "Distância Total", value: "15.4 km", icon: "map", color: .blue)
        }
        .frame(height: 150)
        
        HStack {
            InfoBadge(text: "GPS", color: .blue, icon: "location.fill")
            InfoBadge(text: "4K 60fps", color: .gray)
            InfoBadge(text: "Sem Áudio", color: .red, icon: "speaker.slash")
        }
        
        SectionHeader("Dados do Sensor", icon: "chart.xyaxis.line")
            .background(Color.gray.opacity(0.1))
        
        Spacer()
    }
    .padding()
    .frame(width: 500)
}
