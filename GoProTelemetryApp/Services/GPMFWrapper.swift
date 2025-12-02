//
//  GPMFWrapper.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation

/// Wrapper responsável por invocar o parser C e converter os resultados para estruturas Swift seguras.
class GPMFWrapper {
    
    // MARK: - Public API
    
    /// Processa um arquivo de vídeo e retorna os streams e metadados.
    /// - Parameter url: URL local do arquivo de vídeo.
    /// - Returns: Tupla contendo os streams de dados e o nome da câmera (se encontrado).
    static func parse(url: URL) throws -> (streams: [GPMFStream], deviceName: String?) {
        // 1. Validação de Acesso
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw GPMFError.fileAccessDenied
        }
        
        guard let cFilePath = (url.path as NSString).utf8String else {
            throw GPMFError.invalidData
        }
        
        print("🔌 GPMFWrapper: Iniciando extração nativa de \(url.lastPathComponent)")
        
        // 2. Extrair Nome do Dispositivo (Nova Função C)
        var deviceName: String? = nil
        if let cDeviceName = get_device_name(cFilePath) {
            deviceName = String(cString: cDeviceName)
            free(cDeviceName) // Importante: Liberar a string alocada no C
        }
        
        // 3. Extrair Streams de Telemetria
        guard let cStreamsPtr = parse_gpmf_from_file(cFilePath) else {
            print("⚠️ GPMFWrapper: parse_gpmf_from_file retornou NULL")
            // Retorna vazio mas com sucesso, pois pode ser um vídeo sem telemetria mas válido
            return ([], deviceName)
        }
        
        // 4. Gestão de Memória
        defer {
            free_parsed_streams(cStreamsPtr)
        }
        
        // 5. Conversão para Swift
        let streams = convertToSwift(cStreamsPtr: cStreamsPtr)
        print("🔌 GPMFWrapper: Sucesso. \(streams.count) streams de \(deviceName ?? "Câmera Desconhecida").")
        
        return (streams, deviceName)
    }
    
    /// Verifica rapidamente se o arquivo possui trilha GPMF válida.
    static func hasTelemetry(url: URL) -> Bool {
        guard let cFilePath = (url.path as NSString).utf8String else { return false }
        return has_gpmf_stream(cFilePath) != 0
    }
    
    // MARK: - Private Conversion Helpers
    
    private static func convertToSwift(cStreamsPtr: UnsafeMutablePointer<C_GPMFStream>) -> [GPMFStream] {
        var swiftStreams: [GPMFStream] = []
        var currentPtr = cStreamsPtr
        
        // Itera sobre a lista encadeada C
        while currentPtr.pointee.type.0 != 0 {
            let cStream = currentPtr.pointee
            
            if let stream = convertSingleStream(cStream) {
                swiftStreams.append(stream)
            }
            
            currentPtr = currentPtr.advanced(by: 1)
        }
        
        return swiftStreams
    }
    
    private static func convertSingleStream(_ cStream: C_GPMFStream) -> GPMFStream? {
        // 1. Converter Tipo (FourCC -> Enum)
        let typeStr = fourCCString(from: cStream.type)
        let type = GPMFStreamType.from(fourCC: typeStr)
        
        // Se for um tipo desconhecido, podemos ignorar ou manter para debug.
        // Aqui mantemos para garantir que dados novos (como WNDM) passem.
        
        let count = Int(cStream.sample_count)
        guard count > 0, let samplesPtr = cStream.samples else { return nil }
        
        let elements = Int(cStream.elements_per_sample)
        
        // 2. Converter Amostras
        // Otimização: reserveCapacity evita realocações múltiplas
        var swiftSamples: [GPMFSample] = []
        swiftSamples.reserveCapacity(count)
        
        for i in 0..<count {
            let cSample = samplesPtr[i]
            
            // Converte a tupla C fixa para Array Swift dinâmico
            let values = tupleToArray(cSample.values, validCount: elements)
            
            swiftSamples.append(GPMFSample(
                timestamp: cSample.timestamp,
                values: values
            ))
        }
        
        return GPMFStream(
            type: type,
            samples: swiftSamples,
            sampleCount: count,
            elementsPerSample: elements,
            sampleRate: cStream.sample_rate
        )
    }
    
    // MARK: - Low Level Utils
    
    /// Converte a tupla de caracteres C para String Swift
    private static func fourCCString(from tuple: (CChar, CChar, CChar, CChar, CChar)) -> String {
        let bytes = [tuple.0, tuple.1, tuple.2, tuple.3]
        let validBytes = bytes.map { UInt8(bitPattern: $0) }.filter { $0 != 0 }
        return String(bytes: validBytes, encoding: .ascii) ?? "UNKN"
    }
    
    /// Converte buffer de memória C (tuple double[16]) para [Double]
    private static func tupleToArray(_ tuple: (Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double), validCount: Int) -> [Double] {
        var t = tuple
        return withUnsafePointer(to: &t) { ptr in
            ptr.withMemoryRebound(to: Double.self, capacity: 16) { doublePtr in
                let safeCount = min(validCount, 16)
                // Cria array copiando os valores
                return Array(UnsafeBufferPointer(start: doublePtr, count: safeCount))
            }
        }
    }
}
