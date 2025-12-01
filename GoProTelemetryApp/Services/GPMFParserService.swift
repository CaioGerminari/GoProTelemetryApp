//
//  GPMFParserService.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation
import Combine

class GPMFParserService: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var progress: Double = 0
    @Published var currentStatus: String = ""
    
    private let queue = DispatchQueue(label: "com.gopro.telemetry.parser", qos: .userInitiated)
    
    func parseTelemetry(from videoURL: URL) async throws -> TelemetrySession {
        await MainActor.run {
            isProcessing = true
            progress = 0
            currentStatus = "Inicializando parser GPMF..."
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    // ✅ PROCESSAMENTO REAL - PASSO 1: Validação
                    self.updateProgress(0.1, status: "Validando arquivo de vídeo...")
                    
                    guard FileManager.default.fileExists(atPath: videoURL.path) else {
                        throw GPMFError.fileAccessDenied
                    }
                    
                    // ✅ PASSO 2: Extração GPMF
                    self.updateProgress(0.3, status: "Extraindo dados GPMF do vídeo...")
                    let telemetryData = try self.extractTelemetryData(from: videoURL)
                    
                    // ✅ PASSO 3: Processamento
                    self.updateProgress(0.8, status: "Processando dados de telemetria...")
                    
                    self.updateProgress(1.0, status: "Processamento concluído!")
                    
                    Task { @MainActor in
                        self.isProcessing = false
                    }
                    
                    continuation.resume(returning: telemetryData)
                } catch {
                    Task { @MainActor in
                        self.isProcessing = false
                        self.currentStatus = "Erro no processamento: \(error.localizedDescription)"
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func updateProgress(_ progress: Double, status: String) {
        Task { @MainActor in
            self.progress = progress
            self.currentStatus = status
        }
    }
    
    // ✅ IMPLEMENTAÇÃO REAL - Extração GPMF
    private func extractTelemetryData(from videoURL: URL) throws -> TelemetrySession {
        let points = try extractRealTelemetryData(from: videoURL)
        
        guard !points.isEmpty else {
            throw GPMFError.invalidData
        }
        
        return TelemetrySession(
            videoURL: videoURL,
            duration: calculateDuration(from: points),
            points: points,
            startTime: extractStartTime(from: points) ?? Date(),
            deviceName: extractDeviceName(from: videoURL) ?? "GoPro Camera"
        )
    }
    
    // ✅ EXTRAÇÃO REAL DE DADOS GPMF
    private func extractRealTelemetryData(from videoURL: URL) throws -> [TelemetryDataPoint] {
        print("🔍 Extraindo telemetria de: \(videoURL.lastPathComponent)")
        
        // Verificar se o arquivo contém dados GPMF
        guard GPMFExtractor.hasGPMFData(videoURL) else {
            throw GPMFError.invalidData
        }
        
        // Extrair streams via wrapper
        let gpmfStreams = GPMFWrapper.parseGPMFFromVideo(videoURL)
        
        guard !gpmfStreams.isEmpty else {
            throw GPMFError.parsingFailed
        }
        
        print("✅ Streams extraídos: \(gpmfStreams.count)")
        
        // Mapear para telemetria
        var points = GPMFTelemetryMapper.mapToTelemetryDataPoints(gpmfStreams)
        
        guard !points.isEmpty else {
            throw GPMFError.parsingFailed
        }
        
        // Limpar dados
        points = GPMFTelemetryMapper.cleanTelemetryData(points)
        
        // Aprimorar dados
        points = GPMFTelemetryMapper.enhanceTelemetryData(points)
        
        print("📈 Pipeline completa: \(points.count) pontos de telemetria gerados")
        return points
    }
    
    private func calculateDuration(from points: [TelemetryDataPoint]) -> TimeInterval {
        guard let first = points.first, let last = points.last else { return 0 }
        return last.timestamp - first.timestamp
    }
    
    private func extractStartTime(from points: [TelemetryDataPoint]) -> Date? {
        guard let firstPoint = points.first else { return nil }
        return Date(timeIntervalSince1970: firstPoint.timestamp)
    }
    
    private func extractDeviceName(from videoURL: URL) -> String? {
        // TODO: Extrair do metadata do vídeo
        let fileName = videoURL.deletingPathExtension().lastPathComponent
        if fileName.uppercased().contains("GOPRO") || fileName.uppercased().contains("GP") {
            return "GoPro Hero"
        }
        return "GoPro Camera"
    }
    
    func getAvailableStreams(from videoURL: URL) async -> [GPMFStreamInfo] {
        guard GPMFExtractor.hasGPMFData(videoURL) else {
            return []
        }
        
        return GPMFWrapper.getStreamInfo(from: videoURL)
    }
}
