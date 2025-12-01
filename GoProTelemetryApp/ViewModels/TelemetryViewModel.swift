//
//  TelemetryViewModel.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 01/12/25.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers // CORREÇÃO: Import necessário para UTType

@MainActor
class TelemetryViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var session: TelemetrySession?
    @Published var appSettings = AppSettings()
    
    @Published var isProcessing: Bool = false
    @Published var processingMessage: String = ""
    
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    @Published var showExportSuccess: Bool = false
    @Published var lastExportedURL: URL?
    
    // MARK: - Dependencies
    
    private let fileManager = FileManagerService()
    private let exportService = ExportService()
    
    // MARK: - Actions: Importação
    
    func selectFile() {
        Task {
            do {
                let url = try await fileManager.pickVideoFile()
                await processVideo(url: url)
            } catch {
                // CORREÇÃO: Agora funciona porque FileError é Equatable
                if let fileError = error as? FileError, fileError == .operationCancelled {
                    return
                } else {
                    handleError(error)
                }
            }
        }
    }
    
    func processVideo(url: URL) async {
        guard GPMFWrapper.hasTelemetry(url: url) else {
            handleError(GPMFError.invalidData)
            return
        }
        
        startLoading("Extraindo telemetria...")
        
        Task.detached(priority: .userInitiated) {
            do {
                let streams = try GPMFWrapper.parse(url: url)
                
                await MainActor.run {
                    self.processingMessage = "Sincronizando sensores..."
                }
                
                let newSession = GPMFTelemetryMapper.makeSession(from: streams, videoUrl: url)
                
                await MainActor.run {
                    self.session = newSession
                    self.stopLoading()
                }
                
            } catch {
                await MainActor.run {
                    self.stopLoading()
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - Actions: Exportação
    
    func exportTelemetry(settings: ExportSettings) {
        guard let currentSession = session else { return }
        
        startLoading("Gerando arquivo \(settings.defaultFormat.rawValue)...")
        
        Task.detached {
            do {
                // Acessar sampleRate de forma segura (copiando valor antes da task)
                let sampleRate = await self.appSettings.general.sampleRate
                
                let tempURL = try self.exportService.export(
                    session: currentSession,
                    settings: settings,
                    sampleRate: sampleRate
                )
                
                await MainActor.run {
                    self.stopLoading()
                    self.saveExportedFile(tempURL: tempURL, format: settings.defaultFormat)
                }
                
            } catch {
                await MainActor.run {
                    self.stopLoading()
                    self.handleError(error)
                }
            }
        }
    }
    
    private func saveExportedFile(tempURL: URL, format: ExportFormat) {
        Task {
            do {
                // CORREÇÃO: Sintaxe limpa para UTType
                let contentType: UTType
                switch format {
                case .gpx: contentType = .gpx
                case .kml: contentType = .kml
                case .csv: contentType = .commaSeparatedText
                case .json: contentType = .json
                case .mgjson: contentType = .mgjson
                }
                
                let defaultName = tempURL.lastPathComponent
                
                try await fileManager.saveExportedFile(
                    from: tempURL,
                    defaultName: defaultName,
                    contentType: contentType
                )
                
                self.showExportSuccess = true
                self.lastExportedURL = tempURL
                
            } catch {
                if let fileError = error as? FileError, fileError == .operationCancelled {
                    return
                }
                handleError(error)
            }
        }
    }
    
    // MARK: - Helpers
    
    func clearSession() {
        session = nil
        errorMessage = nil
        showError = false
        showExportSuccess = false
    }
    
    private func startLoading(_ message: String) {
        processingMessage = message
        isProcessing = true
    }
    
    private func stopLoading() {
        isProcessing = false
        processingMessage = ""
    }
    
    private func handleError(_ error: Error) {
        print("❌ Erro no ViewModel: \(error.localizedDescription)")
        self.errorMessage = error.localizedDescription
        self.showError = true
    }
}
