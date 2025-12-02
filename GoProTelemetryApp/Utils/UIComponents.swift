//
//  UIComponents.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

//
//  UIComponents.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//  Updated for macOS 26 Tahoe (LiquidGlass)
//

import SwiftUI

// MARK: - Cards

/// Card principal para exibir estatísticas (Legado/Genérico)
/// Adaptado para usar o GlassCard do novo Design System
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = Theme.primary
    
    var body: some View {
        GlassCard(depth: 0.5) {
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                // Header do Card
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(color)
                            .shadow(color: color.opacity(0.6), radius: 4)
                    }
                    
                    Spacer()
                }
                
                // Conteúdo
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(Theme.Font.valueLarge)
                        .liquidNeon(color: .white) // Texto brilhante
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    Text(title.uppercased())
                        .font(Theme.Font.label)
                        .foregroundStyle(Theme.secondary)
                }
            }
        }
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
        // Estilo Glass Mini
        .background(.ultraThinMaterial)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
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
                    .foregroundStyle(Theme.primary)
            }
            Text(title)
                .font(Theme.Font.title)
                .foregroundStyle(.primary)
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
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Caixa de diálogo de Vidro
            VStack(spacing: Theme.Spacing.large) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                    .scaleEffect(1.2)
                
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .liquidNeon(color: .white)
            }
            .padding(40)
            .liquidGlass(cornerRadius: 30, depth: 2.0) // Vidro espesso
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
            ZStack {
                Circle()
                    .fill(Theme.secondary.opacity(0.05))
                    .frame(width: 100, height: 100)
                
                Image(systemName: systemImage)
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.secondary.opacity(0.5))
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Theme.secondary)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(Theme.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Previews

#Preview("UI Components") {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            StatCard(title: "Velocidade Máx", value: "120 km/h", icon: "speedometer", color: .orange)
                .frame(width: 200)
            
            HStack {
                InfoBadge(text: "GPS", color: .cyan, icon: "location.fill")
                InfoBadge(text: "4K", color: .white)
                InfoBadge(text: "Sem Áudio", color: .red, icon: "speaker.slash")
            }
            
            LoadingView(message: "Processando...")
                .frame(height: 200)
        }
    }
}
