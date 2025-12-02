//
//  TelemetryViewModel.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 01/12/25.
//

import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers
import AVFoundation

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
    
    // Var para controle de licença (Flow Pro)
    @Published var showPurchaseSheet: Bool = false
    
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
        
        startLoading("Lendo metadados do vídeo...")
        
        // 1. Metadados do Arquivo (Data/Duração)
        let metadata = await extractVideoMetadata(from: url)
        
        startLoading("Extraindo telemetria...")
        
        Task.detached(priority: .userInitiated) {
            do {
                // 2. Extração Bruta (C)
                // CORREÇÃO 1: Desestruturar a tupla (streams + deviceName)
                let (streams, deviceName) = try GPMFWrapper.parse(url: url)
                
                await MainActor.run {
                    self.processingMessage = "Sincronizando sensores..."
                }
                
                // 3. Mapeamento e Limpeza (Swift)
                // CORREÇÃO 2: Passar o deviceName
                let newSession = GPMFTelemetryMapper.makeSession(
                    from: streams,
                    videoUrl: url,
                    metadata: metadata,
                    deviceName: deviceName
                )
                
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
    
    // MARK: - Metadata Helper
    
    private func extractVideoMetadata(from url: URL) async -> VideoMetadata {
        let asset = AVURLAsset(url: url)
        
        let duration: Double
        if let cmTime = try? await asset.load(.duration) {
            duration = cmTime.seconds
        } else {
            duration = 0
        }
        
        var creationDate = Date()
        if let commonMetadata = try? await asset.load(.commonMetadata) {
            if let dateItem = commonMetadata.first(where: { $0.commonKey == .commonKeyCreationDate }),
               let dateValue = try? await dateItem.load(.value) as? Date {
                creationDate = dateValue
            } else if let dateStringItem = commonMetadata.first(where: { $0.commonKey == .commonKeyCreationDate }),
                      let dateString = try? await dateStringItem.load(.value) as? String {
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: dateString) {
                    creationDate = date
                }
            }
        }
        
        // Fallback para atributo de arquivo se metadata interno falhar
        if creationDate.timeIntervalSinceNow > -10 {
             if let attr = try? FileManager.default.attributesOfItem(atPath: url.path),
                let fileDate = attr[.creationDate] as? Date {
                 creationDate = fileDate
             }
        }
        
        return VideoMetadata(duration: duration, creationDate: creationDate)
    }
    
    // MARK: - Actions: Exportação
    
    func exportTelemetry(settings: ExportSettings) {
        guard let currentSession = session else { return }
        
        // Exemplo de check de licença (se implementado)
        // if LicenseService.shared.requiresPro(for: settings) { self.showPurchaseSheet = true; return }
        
        startLoading("Gerando arquivo \(settings.defaultFormat.rawValue)...")
        
        Task.detached {
            do {
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

// Helper Struct para passar metadados
struct VideoMetadata {
    let duration: Double
    let creationDate: Date
}
