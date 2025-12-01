//
//  Extensions.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation

// MARK: - Double Formatting

extension Double {
    /// Formata segundos em "MM:SS" ou "HH:MM:SS"
    /// Ex: 65.0 -> "01:05"
    var formattedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = self >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? String(format: "%.0fs", self)
    }
    
    /// Converte m/s para km/h e formata
    /// Ex: 10.0 -> "36 km/h"
    var asKmhString: String {
        let kmh = self * 3.6
        return String(format: "%.0f km/h", kmh)
    }
    
    /// Formata metros para km se necessário
    /// Ex: 1500 -> "1.50 km", 500 -> "500 m"
    var asDistanceString: String {
        if self >= 1000 {
            return String(format: "%.2f km", self / 1000)
        } else {
            return String(format: "%.0f m", self)
        }
    }
    
    /// Formata com precisão específica
    func toString(decimalPlaces: Int) -> String {
        return String(format: "%.\(decimalPlaces)f", self)
    }
}

// MARK: - Date Extensions

extension Date {
    /// Formata data para uso seguro em nomes de arquivo
    /// Ex: "2023-11-30_14-30-00"
    func formattedForFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: self)
    }
    
    /// Formata para exibição curta (pt-BR locale friendly)
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - URL Extensions (System)

extension URL {
    /// Garante conformidade Codable segura para URLs
    /// Útil para salvar caminhos de arquivo no UserDefaults ou JSON
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let urlString = try container.decode(String.self)
        
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "URL inválida: \(urlString)"
            )
        }
        
        self = url
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.absoluteString)
    }
    
    /// Retorna o tamanho do arquivo formatado (ex: "1.5 GB")
    var formattedFileSize: String {
        do {
            let resources = try self.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resources.fileSize {
                return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            }
        } catch {
            print("Erro ao ler tamanho: \(error)")
        }
        return "?"
    }
}

// MARK: - Collection Extensions

extension Array {
    /// Helper seguro para acessar índices que podem não existir
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
