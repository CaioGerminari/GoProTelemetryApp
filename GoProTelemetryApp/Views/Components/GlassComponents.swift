//
//  GlassComponents.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 02/12/25.
//

import SwiftUI

// MARK: - Design Tokens (Especificações)

/// Constantes baseadas no Design System do macOS 26
struct LiquidGlassSpec {
    static let cornerRadius: CGFloat = 20.0 // Borda mais arredondada e fluida
    static let baseOpacity: CGFloat = 0.2   // Transparência base da tintura
    static let borderOpacity: CGFloat = 0.5 // Intensidade do brilho nas bordas
}

// MARK: - Modificador Principal

struct LiquidGlassModifier: ViewModifier {
    // Parâmetros personalizáveis
    var cornerRadius: CGFloat
    var depth: CGFloat // Simula a elevação (0.0 = plano, 1.0 = flutuando alto)
    var tint: Color?   // Cor da "tintura" do vidro
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 1. A Matéria do Vidro (Blur Nativo do OS)
                    // .ultraThinMaterial se adapta automaticamente ao fundo (Papel de parede/Janela)
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        
                    // 2. Tintura (Base Color) - Transparência Adaptativa
                    // No modo Dark, o vidro é mais sutil; no Light, mais visível.
                    if let tint = tint {
                        Rectangle()
                            .fill(tint)
                            .opacity(LiquidGlassSpec.baseOpacity * (colorScheme == .dark ? 0.6 : 0.8))
                    } else {
                        // Tintura neutra para vidros sem cor semântica
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.2))
                    }
                    
                    // 3. Simulação de Refração (Luz Líquida)
                    // Um gradiente diagonal sutil que "quebra" a uniformidade do material
                    LinearGradient(
                        colors: [
                            .white.opacity(colorScheme == .dark ? 0.1 : 0.4),
                            .clear,
                            .white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.overlay)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // 4. Borda Especular (Inner Glow / Specular Highlight)
                // Simula luz batendo nas quinas superiores
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(LiquidGlassSpec.borderOpacity), location: 0),
                                .init(color: .white.opacity(0.1), location: 0.2),
                                .init(color: .clear, location: 0.5), // Meio transparente
                                .init(color: .white.opacity(0.1), location: 0.8),
                                .init(color: .white.opacity(LiquidGlassSpec.borderOpacity * 0.5), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.screen) // Garante que o brilho se some à luz
            )
            .shadow(
                // 5. Sombra Difusa Colorida (Ambient Glow)
                // A sombra herda a cor da tintura, criando um efeito de "luz vazando"
                color: (tint ?? .black).opacity(colorScheme == .dark ? 0.5 : 0.2),
                radius: 15 * depth,
                x: 0,
                y: 8 * depth
            )
    }
}

// MARK: - Componentes Reutilizáveis

/// Card container padrão do estilo LiquidGlass.
/// Substitui containers opacos. Use para agrupar métricas, gráficos ou textos.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = LiquidGlassSpec.cornerRadius
    var depth: CGFloat = 1.0
    var tint: Color? = nil
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .padding(padding)
            .liquidGlass(cornerRadius: cornerRadius, depth: depth, tint: tint)
    }
}

/// Botão com estilo de vidro tátil.
/// Possui animação de pressão que reduz a profundidade (depth) e o brilho.
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var tint: Color = .blue
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headline)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle()) // Garante hit-test na área transparente
        }
        .buttonStyle(LiquidGlassButtonStyle(tint: tint))
    }
}

/// Estilo de botão personalizado para suportar animações de estado (Pressed)
struct LiquidGlassButtonStyle: ButtonStyle {
    var tint: Color
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                // Feedback visual de clique: fundo levemente mais opaco
                ZStack {
                    if configuration.isPressed {
                        Rectangle()
                            .fill(tint.opacity(0.2))
                    }
                }
            )
            .liquidGlass(
                cornerRadius: 14,
                // Ao clicar, o botão "afunda" (depth diminui)
                depth: configuration.isPressed ? 0.2 : 1.0,
                tint: tint
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Extensions (API Fluida)

extension View {
    /// Aplica o efeito LiquidGlass (macOS 26) à view atual.
    /// - Parameters:
    ///   - cornerRadius: Raio da borda (padrão: 20).
    ///   - depth: Multiplicador de profundidade para sombras (0.0 a 2.0).
    ///   - tint: Cor semântica para o vidro (ex: .blue para GPS).
    func liquidGlass(cornerRadius: CGFloat = LiquidGlassSpec.cornerRadius,
                     depth: CGFloat = 1.0,
                     tint: Color? = nil) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, depth: depth, tint: tint))
    }
    
    /// Estilo de texto "Neon" para destacar valores importantes dentro do vidro.
    /// Adiciona brilho externo ao texto e um miolo branco brilhante.
    func liquidNeon(color: Color) -> some View {
        self
            .foregroundStyle(color) // Cor base
            .shadow(color: color.opacity(0.8), radius: 8, x: 0, y: 0) // Glow externo
            .overlay(
                self.foregroundStyle(.white.opacity(0.6))
                    .blur(radius: 0.5) // Brilho interno (core)
                    .blendMode(.overlay)
            )
    }
}

// MARK: - Preview (Design System Gallery)

#Preview("LiquidGlass Gallery") {
    ZStack {
        // Fundo simulando um Wallpaper abstrato do macOS
        LinearGradient(
            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6), Color.orange.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // Simulação de Janela
        VStack(spacing: 40) {
            
            // 1. Card Informativo (Dashboard)
            GlassCard(depth: 1.0) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "speedometer")
                            .liquidNeon(color: .cyan)
                            .font(.title2)
                        Spacer()
                        Text("AO VIVO")
                            .font(.caption2.bold())
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(4)
                    }
                    
                    Text("124 km/h")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    
                    Text("Velocidade Atual")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(width: 220)
            }
            
            // 2. Alerta Crítico (Tinted Glass)
            GlassCard(depth: 1.5, tint: .red) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .shadow(color: .orange, radius: 10)
                    
                    VStack(alignment: .leading) {
                        Text("Força G Elevada")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Pico de 2.4G detectado")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 10)
            }
            
            // 3. Botões de Ação
            HStack(spacing: 20) {
                GlassButton(title: "Exportar", icon: "square.and.arrow.up", action: {}, tint: .blue)
                GlassButton(title: "Cancelar", icon: "xmark", action: {}, tint: .gray)
            }
        }
        .padding()
    }
    .frame(width: 600, height: 700)
}
