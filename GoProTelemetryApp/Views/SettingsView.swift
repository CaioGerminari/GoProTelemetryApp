//
//  SettingsView.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

struct SettingsView: View {
    // A SettingsView recebe o objeto de configurações global
    // Pode ser injetado via .environmentObject ou passado diretamente
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        TabView {
            GeneralSettingsTab(settings: $settings.general)
                .tabItem {
                    Label("Geral", systemImage: "gear")
                }
            
            AppearanceSettingsTab(settings: $settings.appearance)
                .tabItem {
                    Label("Aparência", systemImage: "paintbrush")
                }
            
            AdvancedSettingsTab(settings: $settings.advanced)
                .tabItem {
                    Label("Avançado", systemImage: "hammer")
                }
        }
        .frame(width: 500, height: 400) // Tamanho padrão para janela de configurações macOS
        .padding()
    }
}

// MARK: - Tabs

struct GeneralSettingsTab: View {
    @Binding var settings: GeneralSettings
    
    var body: some View {
        Form {
            Section {
                Toggle("Processar vídeos automaticamente", isOn: $settings.autoProcessVideos)
                    .help("Inicia a extração de telemetria assim que o vídeo é aberto.")
                
                Toggle("Habilitar Notificações", isOn: $settings.enableNotifications)
                
                Toggle("Manter arquivos originais", isOn: $settings.keepOriginalFiles)
            } header: {
                Text("Comportamento")
            }
            
            Section {
                Picker("Taxa de Amostragem Padrão", selection: $settings.sampleRate) {
                    Text("100% (Todos os pontos)").tag(1.0)
                    Text("50% (Metade)").tag(0.5)
                    Text("25% (Rápido)").tag(0.25)
                }
                .pickerStyle(.menu)
                
                HStack {
                    Text("Tamanho Máx. do Cache")
                    Spacer()
                    TextField("MB", value: $settings.maxCacheSize, format: .number)
                        .frame(width: 60)
                    Text("MB")
                }
            } header: {
                Text("Performance & Armazenamento")
            }
        }
        .formStyle(.grouped)
    }
}

struct AppearanceSettingsTab: View {
    @Binding var settings: AppearanceSettings
    
    var body: some View {
        Form {
            Section {
                Picker("Tema do App", selection: $settings.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Cor de Destaque", selection: $settings.accentColor) {
                    ForEach(AppAccentColor.allCases, id: \.self) { color in
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(color.color) // Usa a extensão visual
                            Text(color.rawValue)
                        }
                        .tag(color)
                    }
                }
                
                Toggle("Mostrar Animações", isOn: $settings.showAnimations)
            } header: {
                Text("Interface")
            }
            
            Section {
                Picker("Estilo de Gráfico", selection: $settings.chartStyle) {
                    ForEach(ChartStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                
                Toggle("Mostrar Linhas de Grade", isOn: $settings.showGridLines)
                
                Picker("Tamanho da Fonte", selection: $settings.fontSize) {
                    ForEach(FontSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
            } header: {
                Text("Visualização de Dados")
            }
        }
        .formStyle(.grouped)
    }
}

struct AdvancedSettingsTab: View {
    @Binding var settings: AdvancedSettings
    
    @State private var showClearCacheAlert = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Logs de Debug", isOn: $settings.enableDebugLogs)
                Toggle("Modo Desenvolvedor", isOn: $settings.developerMode)
                    .help("Habilita visualização de dados brutos não processados.")
            } header: {
                Text("Desenvolvimento")
            }
            
            Section {
                Toggle("Forçar Decodificação via Software", isOn: $settings.forceSoftwareDecoding)
                    .help("Use se tiver problemas gráficos. Pode ser mais lento.")
                
                Toggle("Limpar cache ao sair", isOn: $settings.clearCacheOnExit)
            } header: {
                Text("Motor de Processamento")
            }
            
            Section {
                Button(role: .destructive) {
                    showClearCacheAlert = true
                } label: {
                    Text("Limpar Cache Agora")
                }
                .alert("Limpar Cache?", isPresented: $showClearCacheAlert) {
                    Button("Cancelar", role: .cancel) { }
                    Button("Limpar", role: .destructive) {
                        // Ação de limpeza real seria chamada aqui, ex: via NotificationCenter ou ViewModel injetado
                        // Por enquanto, apenas simulação visual
                        print("Cache limpo")
                    }
                } message: {
                    Text("Isso removerá todos os arquivos temporários de exportação. Esta ação não pode ser desfeita.")
                }
            } header: {
                Text("Manutenção")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Visual Extensions for Settings
// Necessário pois AppSettings.swift não importa SwiftUI

fileprivate extension AppAccentColor {
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        case .yellow: return .yellow
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(settings: AppSettings())
}
