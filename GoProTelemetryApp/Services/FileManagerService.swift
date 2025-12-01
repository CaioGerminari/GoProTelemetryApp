//
//  FileManagerService.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - Errors
enum FileError: LocalizedError, Equatable {
    case operationCancelled
    case fileNotFound
    case accessDenied
    case invalidDestination
    case systemError(String)
    
    var errorDescription: String? {
        switch self {
        case .operationCancelled: return "Operação cancelada pelo usuário."
        case .fileNotFound: return "O arquivo de origem não foi encontrado."
        case .accessDenied: return "Permissão negada para acessar o arquivo."
        case .invalidDestination: return "Destino inválido."
        case .systemError(let msg): return "Erro do sistema: \(msg)"
        }
    }
}

// MARK: - Service Logic
class FileManagerService {
    
    // MARK: - Dialogs (UI)
    
    @MainActor
    func pickVideoFile() async throws -> URL {
        let panel = NSOpenPanel()
        panel.title = "Selecionar Vídeo GoPro"
        panel.message = "Escolha um arquivo de vídeo da GoPro (MP4, MOV)"
        panel.allowedContentTypes = [
            UTType.mpeg4Movie,
            UTType.quickTimeMovie,
            UTType(filenameExtension: "m4v") ?? .mpeg4Movie
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        
        // CORREÇÃO 1: Usar 'withCheckedThrowingContinuation' para permitir erros
        return try await withCheckedThrowingContinuation { continuation in
            panel.begin { response in
                if response == .OK, let url = panel.url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: FileError.operationCancelled)
                }
            }
        }
    }
    
    @MainActor
    func saveExportedFile(from tempURL: URL, defaultName: String, contentType: UTType) async throws {
        guard FileManager.default.fileExists(atPath: tempURL.path) else {
            throw FileError.fileNotFound
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Salvar Telemetria"
        savePanel.nameFieldStringValue = defaultName
        savePanel.allowedContentTypes = [contentType]
        savePanel.canCreateDirectories = true
        
        // CORREÇÃO 1: Usar 'withCheckedThrowingContinuation'
        return try await withCheckedThrowingContinuation { continuation in
            savePanel.begin { response in
                if response == .OK, let destinationURL = savePanel.url {
                    do {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        
                        try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                        try? FileManager.default.removeItem(at: tempURL)
                        
                        // CORREÇÃO 2: Label correto é 'returning', não 'return'
                        continuation.resume(returning: ())
                    } catch {
                        continuation.resume(throwing: FileError.systemError(error.localizedDescription))
                    }
                } else {
                    continuation.resume(throwing: FileError.operationCancelled)
                }
            }
        }
    }
    
    // MARK: - Utilities
    
    func getFormattedFileSize(for url: URL) -> String {
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resources.fileSize {
                return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            }
        } catch {
            print("Erro ao ler tamanho do arquivo: \(error)")
        }
        return "Desconhecido"
    }
    
    func isValidVideoExtension(_ url: URL) -> Bool {
        let validExtensions = ["mp4", "mov", "m4v"]
        return validExtensions.contains(url.pathExtension.lowercased())
    }
}

// MARK: - UTType Extensions
extension UTType {
    static let kml = UTType(filenameExtension: "kml") ?? UTType.xml
    static let gpx = UTType(filenameExtension: "gpx") ?? UTType.xml
    static let mgjson = UTType(filenameExtension: "mgjson") ?? UTType.json
}
