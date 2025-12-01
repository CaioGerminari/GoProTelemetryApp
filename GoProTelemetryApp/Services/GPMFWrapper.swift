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
    
    /// Processa um arquivo de vídeo e retorna os streams de telemetria brutos.
    /// - Parameter url: URL local do arquivo de vídeo (MP4/MOV).
    /// - Returns: Array de `GPMFStream` contendo os dados brutos.
    /// - Throws: `GPMFError` em caso de falha de acesso ou parse.
    static func parse(url: URL) throws -> [GPMFStream] {
        // 1. Validação de Acesso ao Arquivo
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw GPMFError.fileAccessDenied
        }
        
        // 2. Conversão de Path para C String
        guard let cFilePath = (url.path as NSString).utf8String else {
            throw GPMFError.invalidData
        }
        
        print("🔌 GPMFWrapper: Iniciando extração nativa de \(url.lastPathComponent)")
        
        // 3. Chamada ao Código C
        // parse_gpmf_from_file retorna um ponteiro para um array de C_GPMFStream alocado no heap
        guard let cStreamsPtr = parse_gpmf_from_file(cFilePath) else {
            // Se retornou NULL, significa que não achou telemetria ou falhou ao abrir
            print("⚠️ GPMFWrapper: parse_gpmf_from_file retornou NULL")
            return []
        }
        
        // 4. Gestão de Memória (CRÍTICO)
        // Garante que a memória alocada pelo 'malloc' no C seja liberada ao final desta função
        defer {
            free_parsed_streams(cStreamsPtr)
        }
        
        // 5. Conversão para Swift
        let streams = convertToSwift(cStreamsPtr: cStreamsPtr)
        print("🔌 GPMFWrapper: Sucesso. \(streams.count) streams convertidos.")
        
        return streams
    }
    
    /// Verifica rapidamente se o arquivo possui trilha GPMF válida sem extrair todos os dados.
    static func hasTelemetry(url: URL) -> Bool {
        guard let cFilePath = (url.path as NSString).utf8String else { return false }
        return has_gpmf_stream(cFilePath) != 0
    }
    
    // MARK: - Private Conversion Helpers
    
    /// Converte a lista encadeada/array C em array Swift
    private static func convertToSwift(cStreamsPtr: UnsafeMutablePointer<C_GPMFStream>) -> [GPMFStream] {
        var swiftStreams: [GPMFStream] = []
        var currentPtr = cStreamsPtr
        
        // Itera sobre o array C até encontrar o terminador (onde type[0] == '\0')
        while currentPtr.pointee.type.0 != 0 {
            let cStream = currentPtr.pointee
            
            if let stream = convertSingleStream(cStream) {
                swiftStreams.append(stream)
            }
            
            // Avança o ponteiro para o próximo item do array C (aritmética de ponteiros)
            currentPtr = currentPtr.advanced(by: 1)
        }
        
        return swiftStreams
    }
    
    /// Converte uma única struct C_GPMFStream para GPMFStream (Swift)
    private static func convertSingleStream(_ cStream: C_GPMFStream) -> GPMFStream? {
        // 1. Converter Tipo (FourCC Tuple -> String -> Enum)
        let typeStr = fourCCString(from: cStream.type)
        let type = GPMFStreamType.from(fourCC: typeStr)
        
        // 2. Validação de Segurança
        let count = Int(cStream.sample_count)
        guard count > 0, let samplesPtr = cStream.samples else { return nil }
        
        let elements = Int(cStream.elements_per_sample)
        
        // 3. Converter Amostras
        var swiftSamples: [GPMFSample] = []
        swiftSamples.reserveCapacity(count)
        
        for i in 0..<count {
            let cSample = samplesPtr[i] // Acesso direto ao buffer C
            
            // Converte a tupla fixa C (double[16]) para Array dinâmico [Double]
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
    
    /// Converte a tupla de caracteres C (char, char, char, char, char) para String Swift
    private static func fourCCString(from tuple: (CChar, CChar, CChar, CChar, CChar)) -> String {
        let bytes = [tuple.0, tuple.1, tuple.2, tuple.3]
        // Filtra nulos e converte para UInt8
        let validBytes = bytes.map { UInt8(bitPattern: $0) }.filter { $0 != 0 }
        return String(bytes: validBytes, encoding: .ascii) ?? "UNKN"
    }
    
    /// Converte a tupla gigante de 16 doubles do C para [Double] do Swift
    /// Swift importa arrays de tamanho fixo C (double values[16]) como tuplas gigantes.
    private static func tupleToArray(_ tuple: (Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double, Double), validCount: Int) -> [Double] {
        // Usamos ponteiros inseguros para ler a tupla como um buffer contíguo de memória
        var t = tuple
        return withUnsafePointer(to: &t) { ptr in
            ptr.withMemoryRebound(to: Double.self, capacity: 16) { doublePtr in
                // Cria um array Swift copiando apenas os elementos válidos
                // Limitamos a 16 para segurança, caso validCount venha errado do C
                let safeCount = min(validCount, 16)
                return Array(UnsafeBufferPointer(start: doublePtr, count: safeCount))
            }
        }
    }
}
