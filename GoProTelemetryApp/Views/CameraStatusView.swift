//
//  CameraStatusView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 02/12/25.
//

//
//  CameraStatusView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 02/12/25.
//  Design System: macOS 26 Tahoe (LiquidGlass)
//

import SwiftUI

struct CameraStatusView: View {
    // MARK: - Properties
    
    // Os dados são opcionais pois podem não existir em todo frame
    let iso: Double?
    let shutter: Double?
    let wb: Double?
    let orientation: Vector4? // Quaternião (x, y, z, w)
    
    // MARK: - Body
    
    var body: some View {
        GlassCard(depth: 0.8, tint: .indigo.opacity(0.3)) {
            HStack(spacing: 0) {
                
                // 1. ISO (Sensibilidade)
                StatusItem(
                    icon: "camera.aperture",
                    label: "ISO",
                    value: iso != nil ? String(format: "%.0f", iso!) : "--",
                    color: .yellow
                )
                
                Divider()
                    .overlay(Color.white.opacity(0.2))
                    .frame(height: 40)
                    .padding(.horizontal, 16)
                
                // 2. Shutter (Velocidade)
                StatusItem(
                    icon: "shutter",
                    label: "SHUTTER",
                    value: formatShutter(shutter),
                    color: .cyan
                )
                
                Divider()
                    .overlay(Color.white.opacity(0.2))
                    .frame(height: 40)
                    .padding(.horizontal, 16)
                
                // 3. White Balance (Temp)
                StatusItem(
                    icon: "thermometer.sun",
                    label: "WB",
                    value: wb != nil ? String(format: "%.0fK", wb!) : "--",
                    color: .orange
                )
                
                Spacer()
                
                // 4. Horizonte Artificial (Visualização de Orientação)
                if let orientation = orientation {
                    ArtificialHorizonView(quaternion: orientation)
                        .frame(width: 80, height: 40)
                } else {
                    // Placeholder se não tiver dados de orientação
                    Image(systemName: "gyroscope")
                        .font(.title)
                        .foregroundStyle(.secondary.opacity(0.3))
                        .frame(width: 80)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 90) // Altura fixa consistente para o Dashboard
    }
    
    // MARK: - Helpers
    
    private func formatShutter(_ val: Double?) -> String {
        guard let s = val, s > 0 else { return "--" }
        // Se for menor que 1s, mostra como fração (ex: 1/60)
        if s < 1.0 {
            let denominator = Int(round(1.0 / s))
            return "1/\(denominator)"
        }
        return String(format: "%.1f\"", s)
    }
}

// MARK: - Subcomponents

/// Item individual de métrica (Ícone + Valor + Label)
private struct StatusItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Ícone com brilho Neon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(color.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.5), radius: 4)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white) // Contraste máximo sobre vidro
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(0.5)
            }
        }
        .frame(minWidth: 100)
    }
}

/// Visualizador Minimalista de Horizonte (Pitch/Roll)
/// Simula a inclinação da câmera usando os dados do giroscópio/quaternião
private struct ArtificialHorizonView: View {
    let quaternion: Vector4
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fundo (Céu/Terra simplificado)
                Circle()
                    .fill(.black.opacity(0.3))
                    .overlay(
                        Circle().strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
                
                // Linha do Horizonte
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.8), .cyan.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geo.size.width + 20, height: 1)
                    .overlay(
                        Rectangle() // Marcador central
                            .fill(.white)
                            .frame(height: 2)
                    )
                    // Aplica rotação (Roll)
                    .rotationEffect(.degrees(rollAngle))
                    // Aplica deslocamento vertical (Pitch)
                    .offset(y: pitchOffset * (geo.size.height / 2))
                    // Máscara circular para manter tudo dentro do vidro
                    .clipShape(Circle())
                
                // Marcador Fixo (Crosshair)
                Image(systemName: "plus")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
    
    // Cálculos simplificados de Euler a partir de Quaterniões para UI
    // Nota: Isso é uma aproximação visual.
    var rollAngle: Double {
        let q = quaternion
        // Roll (rotação eixo Z)
        let sinr_cosp = 2 * (q.w * q.z + q.x * q.y)
        let cosr_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
        let roll = atan2(sinr_cosp, cosr_cosp)
        return roll * 180 / .pi
    }
    
    var pitchOffset: Double {
        let q = quaternion
        // Pitch (rotação eixo X)
        let sinp = 2 * (q.w * q.y - q.z * q.x)
        // Normaliza entre -1 e 1 para offset visual
        if abs(sinp) >= 1 {
            return sinp > 0 ? 1 : -1
        } else {
            return asin(sinp) / (.pi / 2) // Retorna % de inclinação (90 graus = 1.0)
        }
    }
}

// MARK: - Preview

#Preview("Camera Status Panel") {
    ZStack {
        // Background Wallpaper
        Image(systemName: "mountain.2.fill")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 800, height: 200)
            .overlay(.black.opacity(0.4))
            .blur(radius: 10)
        
        VStack(spacing: 20) {
            // Estado Normal
            CameraStatusView(
                iso: 100,
                shutter: 0.0166, // 1/60
                wb: 5500,
                orientation: Vector4(w: 1, x: 0, y: 0, z: 0.1) // Leve inclinação
            )
            .padding()
            
            // Estado Sem Dados (Placeholder)
            CameraStatusView(
                iso: nil,
                shutter: nil,
                wb: nil,
                orientation: nil
            )
            .padding()
        }
    }
}
