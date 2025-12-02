//
//  GlassGauge.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 02/12/25.
//

import SwiftUI

// MARK: - Componente Principal

struct GlassGauge: View {
    let title: String
    let value: Double
    let range: ClosedRange<Double>
    let unit: String
    let color: Color
    
    var size: CGFloat = 160
    var thickness: CGFloat = 16
    
    var body: some View {
        VStack(spacing: 8) {
            // 1. O Arco do Medidor
            ZStack {
                // Fundo do trilho
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        Color.black.opacity(0.2),
                        style: StrokeStyle(lineWidth: thickness, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .overlay(
                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.1), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 1)
                            )
                            .rotationEffect(.degrees(135))
                            .offset(y: 1)
                            .mask(
                                Circle()
                                    .trim(from: 0, to: 0.75)
                                    .stroke(style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                                    .rotationEffect(.degrees(135))
                            )
                    )
                
                // Barra de Progresso
                Circle()
                    .trim(from: 0, to: CGFloat(progress) * 0.75)
                    .stroke(
                        AngularGradient(
                            colors: [color.opacity(0.5), color, color.opacity(0.8)],
                            center: .center,
                            startAngle: .degrees(135),
                            endAngle: .degrees(135 + 270)
                        ),
                        style: StrokeStyle(lineWidth: thickness, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .shadow(color: color.opacity(0.6), radius: 8, x: 0, y: 0)
                    .shadow(color: color.opacity(0.3), radius: 15, x: 0, y: 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: value)
                
                // Valor Central
                VStack(spacing: 0) {
                    Text("\(String(format: "%.0f", value))")
                        .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                        .foregroundStyle(color) // Fallback caso liquidNeon falhe
                        .shadow(color: color.opacity(0.8), radius: 8) // Efeito Neon manual
                        .contentTransition(.numericText())
                    
                    Text(unit)
                        .font(.system(size: size * 0.1, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)
            
            // Título
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(1.0)
        }
        // CORREÇÃO: Aplicação manual do modificador para evitar ambiguidade
        .padding(16)
        .modifier(LiquidGlassModifier(cornerRadius: 20, depth: 0.5, tint: nil))
    }
    
    private var progress: Double {
        let clampedValue = min(max(value, range.lowerBound), range.upperBound)
        return (clampedValue - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}

// MARK: - Mini Gauge (Linear)

struct MiniGlassGauge: View {
    let title: String
    let value: Double
    let range: ClosedRange<Double>
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.caption.bold().monospaced())
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.8), radius: 5)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.2))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                        .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var progress: Double {
        let clampedValue = min(max(value, range.lowerBound), range.upperBound)
        return (clampedValue - range.lowerBound) / (range.upperBound - range.lowerBound)
    }
}

// MARK: - Preview

#Preview("Glass Gauges") {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        HStack {
            GlassGauge(title: "Velocidade", value: 85, range: 0...120, unit: "km/h", color: .cyan)
            GlassGauge(title: "Força G", value: 1.8, range: 0...3.0, unit: "G", color: .orange)
        }
    }
}
