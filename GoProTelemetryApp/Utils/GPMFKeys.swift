//
//  GPMFKeys.swift
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

import Foundation

struct GPMFKeys {
    
    // MARK: - Estrutura GPMF (Container)
    
    struct Structure {
        static let device = "DEVC"       // Device Container
        static let deviceId = "DVID"     // Device ID
        static let deviceName = "DVNM"   // Nome da Câmera (ex: "GoPro Hero 13 Black")
        static let stream = "STRM"       // Stream Container
        static let streamName = "STNM"   // Nome do Stream
        static let scale = "SCAL"        // Fator de Escala
        static let type = "TYPE"         // Tipo de Dado
        static let totalSamples = "TSMP" // Total de Amostras
    }
    
    // MARK: - Sensores Principais (Telemetria)
    
    struct Sensors {
        // --- GPS ---
        static let gps5 = "GPS5" // Hero 5 a 10 (Lat, Lon, Alt, Speed2D, Speed3D)
        static let gps9 = "GPS9" // Hero 11+ (Mais precisão)
        static let gpsTime = "GPSU" // Tempo UTC
        
        // --- IMU (Inertial Measurement Unit) ---
        static let accelerometer = "ACCL" // Aceleração (m/s²) - Nosso novo Backbone!
        static let gyroscope = "GYRO"     // Rotação (rad/s)
        static let gravity = "GRAV"       // Vetor de Gravidade (exclui movimento)
        static let magnetometer = "MAGN"  // Bússola (modelos antigos/360)
    }
    
    // MARK: - Orientação e Ambiente
    
    struct Environment {
        static let temperature = "TMPC"        // Temperatura interna
        static let cameraOrientation = "CORI"  // Orientação da Câmera (Quaterniões)
        static let imageOrientation = "IORI"   // Orientação da Imagem
    }
    
    // MARK: - Configurações e IA
    
    struct Camera {
        // Exposição
        static let shutterSpeed = "SHUT" // Velocidade do Obturador (s)
        static let iso = "ISO"           // Sensibilidade ISO
        static let whiteBalance = "WBAL" // Balanço de Branco (K)
        static let whiteBalanceRGB = "WRGB" // Ganhos de cor
        
        // Inteligência / Análise
        static let face = "FACE"         // Detecção Facial (Bounding Boxes)
        static let scene = "SCEN"        // Classificação de Cena (ex: "Snow", "Beach")
    }
    
    // MARK: - Áudio e Diagnóstico
    
    struct Audio {
        static let windProcessing = "WNDM" // Medição de Vento
        static let microphoneWet = "MWET"  // Detecção de Microfone Molhado
        static let audioLevel = "AALP"     // Nível de Áudio RMS
    }
    
    // MARK: - Helpers
    
    /// Verifica se uma chave corresponde a GPS
    static func isGPS(_ key: String) -> Bool {
        return key == Sensors.gps5 || key == Sensors.gps9
    }
    
    /// Verifica se uma chave pode ser usada como Backbone (alta frequência)
    static func isHighFrequency(_ key: String) -> Bool {
        return key == Sensors.accelerometer || key == Sensors.gyroscope
    }
}
