//
//  GPMFExtractor.swift
//  GoProTelemetryApp
//
//  VERSÃO CORRIGIDA - Usa parse_gpmf_from_file
//

import Foundation
import AVFoundation

class GPMFExtractor {
    
    // MARK: - Public Methods
    
    /// Verifica se o vídeo contém dados GPMF
    static func hasGPMFData(_ videoURL: URL) -> Bool {
        let fileExtension = videoURL.pathExtension.lowercased()
        guard ["mp4", "mov", "m4v"].contains(fileExtension) else {
            print("❌ Extensão não suportada: \(fileExtension)")
            return false
        }
        
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            print("❌ Arquivo não existe: \(videoURL.path)")
            return false
        }
        
        guard let cFilePath = (videoURL.path as NSString).utf8String else {
            print("❌ Erro ao converter path para C")
            return false
        }
        
        let result = has_gpmf_stream(cFilePath)
        print(result != 0 ? "✅ GPMF detectado" : "❌ Sem GPMF")
        return result != 0
    }
    
    /// Extrai streams GPMF do vídeo (usa nova API)
    static func extractStreams(from videoURL: URL) -> [GPMFStream] {
        print("📊 Extraindo streams de: \(videoURL.lastPathComponent)")
        
        guard let cFilePath = (videoURL.path as NSString).utf8String else {
            print("❌ Erro ao converter path")
            return []
        }
        
        // ✅ USA A NOVA API
        guard let cStreams = parse_gpmf_from_file(cFilePath) else {
            print("❌ parse_gpmf_from_file falhou")
            return []
        }
        
        defer {
            free_parsed_streams(cStreams)
        }
        
        return convertCStreamsToSwift(cStreams)
    }
    
    // MARK: - Deprecated Methods (mantidos para compatibilidade)
    
    @available(*, deprecated, message: "Use extractStreams(from:) que usa parse_gpmf_from_file")
    static func extractGPMFData(from videoURL: URL) -> Data? {
        print("⚠️ extractGPMFData está deprecated - use extractStreams")
        
        let filePath = videoURL.path
        guard let cFilePath = (filePath as NSString).utf8String else { return nil }
        
        var gpmfSize: Int32 = 0
        guard let gpmfData = extract_gpmf_from_mp4(cFilePath, &gpmfSize) else {
            print("❌ Falha na extração GPMF")
            return nil
        }
        
        let data = Data(bytes: gpmfData, count: Int(gpmfSize))
        free_gpmf_data(gpmfData)
        return data
    }
    
    @available(*, deprecated, message: "Use extractStreams(from:)")
    static func parseGPMFData(_ data: Data) -> [GPMFStream] {
        print("⚠️ parseGPMFData não funciona corretamente com dados concatenados")
        return []
    }
    
    // MARK: - Private Methods
    
    private static func convertCStreamsToSwift(_ cStreams: UnsafeMutablePointer<C_GPMFStream>) -> [GPMFStream] {
        var streams: [GPMFStream] = []
        var current = cStreams
        
        while current.pointee.type.0 != 0 {
            let typeStr = String(cString: withUnsafePointer(to: &current.pointee.type.0) { $0 })
            let type = GPMFStreamType.from(fourCC: typeStr)
            
            var samples: [GPMFSample] = []
            let sampleCount = Int(current.pointee.sample_count)
            
            if let samplesPtr = current.pointee.samples, sampleCount > 0 {
                for i in 0..<sampleCount {
                    let cSample = samplesPtr[i]
                    let tuple = cSample.values
                    
                    let values: [Double] = [
                        tuple.0, tuple.1, tuple.2, tuple.3,
                        tuple.4, tuple.5, tuple.6, tuple.7,
                        tuple.8, tuple.9, tuple.10, tuple.11,
                        tuple.12, tuple.13, tuple.14, tuple.15
                    ].prefix(Int(current.pointee.elements_per_sample)).map { $0 }
                    
                    samples.append(GPMFSample(
                        timestamp: cSample.timestamp,
                        values: values
                    ))
                }
            }
            
            streams.append(GPMFStream(
                type: type,
                samples: samples,
                sampleCount: sampleCount,
                elementsPerSample: Int(current.pointee.elements_per_sample),
                sampleRate: current.pointee.sample_rate
            ))
            
            current = current.advanced(by: 1)
        }
        
        print("✅ Convertidos \(streams.count) streams")
        return streams
    }
}
