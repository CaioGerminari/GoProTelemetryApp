//
//  GPMFWrapper.swift
//  GoProTelemetryApp
//
//  VERSÃO CORRIGIDA - Usa parse_gpmf_from_file
//

import Foundation

class GPMFWrapper {
    
    // MARK: - Public Methods (API Corrigida)
    
    /// Processa GPMF diretamente do arquivo (MÉTODO CORRETO)
    static func parseGPMFFromVideo(_ videoURL: URL) -> [GPMFStream] {
        print("🔍 Processando: \(videoURL.lastPathComponent)")
        
        guard let cFilePath = (videoURL.path as NSString).utf8String else {
            print("❌ Erro ao converter path para C string")
            return []
        }
        
        // ✅ USA A NOVA API QUE PROCESSA PAYLOAD POR PAYLOAD
        guard let cStreams = parse_gpmf_from_file(cFilePath) else {
            print("❌ parse_gpmf_from_file retornou NULL")
            return []
        }
        
        defer {
            free_parsed_streams(cStreams)
        }
        
        let swiftStreams = convertCStreamsToSwift(cStreams)
        print("✅ Convertidos \(swiftStreams.count) streams para Swift")
        
        return swiftStreams
    }
    
    /// Valida se o vídeo contém GPMF
    static func validateGPMFData(in videoURL: URL) -> Bool {
        guard let cFilePath = (videoURL.path as NSString).utf8String else {
            return false
        }
        return has_gpmf_stream(cFilePath) != 0
    }
    
    /// Obtém informações sobre os streams
    static func getStreamInfo(from videoURL: URL) -> [GPMFStreamInfo] {
        let streams = parseGPMFFromVideo(videoURL)
        return streams.map { GPMFStreamInfo(from: $0) }
    }
    
    // MARK: - Private Methods
    
    private static func convertCStreamsToSwift(_ cStreams: UnsafeMutablePointer<C_GPMFStream>) -> [GPMFStream] {
        var swiftStreams: [GPMFStream] = []
        var currentStream = cStreams
        
        // Iterar até encontrar stream vazio (type[0] == 0)
        while currentStream.pointee.type.0 != 0 {
            let swiftStream = convertCStreamToSwift(currentStream.pointee)
            swiftStreams.append(swiftStream)
            currentStream = currentStream.advanced(by: 1)
        }
        
        return swiftStreams
    }
    
    private static func convertCStreamToSwift(_ cStream: C_GPMFStream) -> GPMFStream {
        let typeString = fourCCString(from: cStream.type)
        let type = GPMFStreamType.from(fourCC: typeString)
        
        var samples: [GPMFSample] = []
        let sampleCount = Int(cStream.sample_count)
        
        // Verificação de segurança
        guard let cSamplesPtr = cStream.samples, sampleCount > 0 else {
            return GPMFStream(
                type: type,
                samples: [],
                sampleCount: 0,
                elementsPerSample: 0,
                sampleRate: 0
            )
        }
        
        // Converter cada sample
        for i in 0..<sampleCount {
            let cSample = cSamplesPtr[i]
            let timestamp = cSample.timestamp
            
            // Converter valores (tuple → array)
            let values = tuple16ToArray(
                cSample.values,
                count: Int(cStream.elements_per_sample)
            )
            
            samples.append(GPMFSample(timestamp: timestamp, values: values))
        }
        
        return GPMFStream(
            type: type,
            samples: samples,
            sampleCount: sampleCount,
            elementsPerSample: Int(cStream.elements_per_sample),
            sampleRate: cStream.sample_rate
        )
    }
    
    // MARK: - Utilities
    
    /// Converte tuple CChar (FourCC) para String
    private static func fourCCString(from tuple: (CChar, CChar, CChar, CChar, CChar)) -> String {
        let chars = [tuple.0, tuple.1, tuple.2, tuple.3]
        let bytes = chars.map { UInt8(bitPattern: $0) }
        return String(bytes: bytes, encoding: .ascii) ?? "UNKN"
    }
    
    /// Converte tuple de 16 valores (double[16]) para array Swift
    private static func tuple16ToArray(
        _ tuple: (
            Double, Double, Double, Double,
            Double, Double, Double, Double,
            Double, Double, Double, Double,
            Double, Double, Double, Double
        ),
        count: Int
    ) -> [Double] {
        let full = [
            tuple.0, tuple.1, tuple.2, tuple.3,
            tuple.4, tuple.5, tuple.6, tuple.7,
            tuple.8, tuple.9, tuple.10, tuple.11,
            tuple.12, tuple.13, tuple.14, tuple.15
        ]
        
        return Array(full.prefix(count))
    }
}
