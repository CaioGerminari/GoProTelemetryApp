//
//  GoProTelemetryApp.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

@main
struct GoProTelemetryApp: App {
    // MARK: - Global State
    
    // Instância única das configurações compartilhada por todo o ciclo de vida do app
    @StateObject private var appSettings = AppSettings()
    
    var body: some Scene {
        // 1. Janela Principal
        WindowGroup {
            ContentView()
                // Injeta as configurações no ambiente.
                // Isso permite que Views profundas acessem @EnvironmentObject var settings: AppSettings
                .environmentObject(appSettings)
                
                // Aplica o tema escolhido (Claro/Escuro) globalmente na janela
                .preferredColorScheme(appSettings.appearance.theme.systemColorScheme)
                
                // Define tamanho mínimo da janela
                .frame(minWidth: 1000, minHeight: 700)
        }
        .commands {
            // Adiciona comandos padrão de barra lateral (Sidebar) no menu "View"
            SidebarCommands()
            
            // Adiciona comandos de importação/exportação no menu "File"
            CommandGroup(replacing: .newItem) {
                Button("Abrir Vídeo...") {
                    // Envia uma notificação para o ViewModel do ContentView abrir o diálogo
                    // (Workaround comum em SwiftUI para menus globais)
                    NotificationCenter.default.post(name: Notification.Name("OpenVideoFile"), object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        
        // 2. Janela de Preferências (macOS Nativo)
        // Acessível via Menu "GoProTelemetryApp" > "Settings..." ou Cmd+,
        Settings {
            SettingsView(settings: appSettings)
                .environmentObject(appSettings) // Garante que previews dentro de Settings funcionem
        }
    }
}

// MARK: - Notifications
// Extensão para facilitar o envio de comandos via Menu Bar
extension Notification.Name {
    static let openVideoFile = Notification.Name("OpenVideoFile")
}
