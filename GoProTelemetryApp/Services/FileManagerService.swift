//
//  FileManagerService.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import Combine
import AppKit
import UniformTypeIdentifiers

class FileManagerService: ObservableObject {
    @Published var isSelectingFile = false
    @Published var isSavingFile = false
    @Published var lastError: String?
    
    func selectVideoFile() async -> URL? {
        await MainActor.run {
            isSelectingFile = true
        }
        
        defer {
            Task { @MainActor in
                isSelectingFile = false
            }
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.title = "Selecionar Vídeo GoPro"
                panel.message = "Escolha um arquivo de vídeo da GoPro"
                panel.allowedContentTypes = [
                    UTType.mpeg4Movie,
                    UTType.quickTimeMovie,
                    UTType(exportedAs: "com.apple.quicktime-movie")
                ]
                panel.allowedFileTypes = ["mp4", "mov", "m4v", "MP4", "MOV", "M4V"]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.canCreateDirectories = false
                
                panel.begin { response in
                    if response == .OK, let url = panel.url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
    func saveFile(_ fileURL: URL, suggestedName: String) async -> Bool {
        await MainActor.run {
            isSavingFile = true
        }
        
        defer {
            Task { @MainActor in
                isSavingFile = false
            }
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let savePanel = NSSavePanel()
                savePanel.title = "Salvar Arquivo de Telemetria"
                savePanel.nameFieldStringValue = suggestedName
                
                // Determine the file extension and set allowed content types
                let fileExtension = (fileURL.pathExtension as NSString).lowercased
                switch fileExtension {
                case "csv":
                    savePanel.allowedContentTypes = [UTType.commaSeparatedText]
                case "gpx":
                    savePanel.allowedContentTypes = [UTType(exportedAs: "com.topografix.gpx")]
                case "json":
                    savePanel.allowedContentTypes = [UTType.json]
                case "fcpxml":
                    savePanel.allowedContentTypes = [UTType.xml]
                default:
                    savePanel.allowedContentTypes = [UTType.plainText]
                }
                
                savePanel.allowedFileTypes = [fileExtension]
                
                savePanel.begin { response in
                    if response == .OK, let destinationURL = savePanel.url {
                        do {
                            // Remove file if it already exists
                            if FileManager.default.fileExists(atPath: destinationURL.path) {
                                try FileManager.default.removeItem(at: destinationURL)
                            }
                            
                            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                            continuation.resume(returning: true)
                        } catch {
                            self.lastError = "Erro ao salvar arquivo: \(error.localizedDescription)"
                            continuation.resume(returning: false)
                        }
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    func getFileSize(_ url: URL) -> Int64? {
        do {
            let resources = try url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resources.fileSize ?? 0)
        } catch {
            lastError = "Erro ao obter tamanho do arquivo: \(error.localizedDescription)"
            return nil
        }
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func getVideoFileTypes() -> [String] {
        return [
            "MP4 (GoPro HERO 5-11)",
            "MOV (GoPro HERO 4 e anteriores)",
            "M4V (Alternativo)"
        ]
    }
    
    func isValidGoProFile(_ url: URL) -> Bool {
        let pathExtension = (url.pathExtension as NSString).lowercased
        return ["mp4", "mov", "m4v"].contains(pathExtension)
    }
}
