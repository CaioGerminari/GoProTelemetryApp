//
//  GoProTelemetryApp.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import SwiftUI

@main
struct GoProTelemetryApp: App {
    @StateObject private var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Abrir Vídeo...") {
                    NotificationCenter.default.post(name: .openVideoFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Novo") {
                    NotificationCenter.default.post(name: .newFile, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(replacing: .importExport) {
                Button("Exportar Telemetria...") {
                    NotificationCenter.default.post(name: .exportTelemetry, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .toolbar) {
                Button("Configurações") {
                    // Abrir settings programaticamente
                    if #available(macOS 13, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(settings)
                .frame(width: 600, height: 700)
        }
    }
}

// Notifications para comandos do menu
extension Notification.Name {
    static let openVideoFile = Notification.Name("openVideoFile")
    static let newFile = Notification.Name("newFile")
    static let exportTelemetry = Notification.Name("exportTelemetry")
}
