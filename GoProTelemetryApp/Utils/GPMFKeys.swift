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
        /// Device Container (Início da árvore de dispositivos)
        static let device = "DEVC"
        
        /// Device ID (Identificador único do dispositivo)
        static let deviceId = "DVID"
        
        /// Device Name (Nome legível, ex: "GoPro Hero 10")
        static let deviceName = "DVNM"
        
        /// Stream Container (Contém os dados de um sensor específico)
        static let stream = "STRM"
        
        /// Stream Name (Nome do sensor, ex: "Accelerometer")
        static let streamName = "STNM"
        
        /// Scale Factor (Divisor para descompactar os dados brutos)
        /// Ex: Valor 12345 com SCAL 100 vira 123.45
        static let scale = "SCAL"
        
        /// Standard Units (Unidades SI, ex: "m/s²", "rad/s")
        static let units = "SIUN"
        
        /// Type definition (Define o tipo de dado, ex: 'f' para float, 'L' para long)
        static let type = "TYPE"
        
        /// Total Samples (Contagem total de amostras)
        static let totalSamples = "TSMP"
    }
    
    // MARK: - Sensores Principais (Telemetria)
    
    struct Sensors {
        // --- GPS ---
        /// GPS Versão 5 (Hero 5 a 10)
        /// Dados: Lat, Lon, Alt, Speed2D, Speed3D
        static let gps5 = "GPS5"
        
        /// GPS Versão 9 (Hero 11+)
        /// Dados: Lat, Lon, Alt, Speed2D, Speed3D, Days, Secs, DOP, Fix
        static let gps9 = "GPS9"
        
        /// GPS UTC Time (Tempo universal)
        static let gpsTime = "GPSU"
        
        /// GPS Precision (Dilution of Precision)
        static let gpsPrecision = "GPSP"
        
        // --- IMU (Inertial Measurement Unit) ---
        /// Acelerômetro (Força G nos eixos X, Y, Z)
        static let accelerometer = "ACCL"
        
        /// Giroscópio (Rotação em rad/s nos eixos X, Y, Z)
        static let gyroscope = "GYRO"
        
        /// Vetor de Gravidade (Direção da gravidade isolada)
        static let gravity = "GRAV"
        
        /// Magnetômetro (Bússola) - Raro em câmeras recentes
        static let magnetometer = "MAGN"
    }
    
    // MARK: - Orientação e Ambiente
    
    struct Environment {
        /// Temperatura da Câmera (em Celsius)
        static let temperature = "TMPC"
        
        /// Camera Orientation (Orientação física da câmera em quaterniões)
        static let cameraOrientation = "CORI"
        
        /// Image Orientation (Orientação digital da imagem, ex: rotação)
        static let imageOrientation = "IORI"
    }
    
    // MARK: - Configurações da Câmera (Metadata)
    
    struct Camera {
        /// Velocidade do Obturador (Exposure Time)
        static let shutterSpeed = "SHUT"
        
        /// Sensibilidade ISO
        static let iso = "ISO" // ou ISOG em modelos mais novos
        
        /// Balanço de Branco (Kelvin)
        static let whiteBalance = "WBAL"
        
        /// Ganhos RGB do Balanço de Branco
        static let whiteBalanceRGB = "WRGB"
        
        /// Histograma (Luma)
        static let luma = "YAVG"
        
        /// Face Detection (Coordenadas de rostos detectados)
        static let face = "FACE"
    }
    
    // MARK: - Helpers
    
    /// Verifica se uma chave corresponde a algum stream de GPS conhecido
    static func isGPS(_ key: String) -> Bool {
        return key == Sensors.gps5 || key == Sensors.gps9
    }
    
    /// Verifica se uma chave corresponde a dados de orientação (IMU/Rotação)
    static func isOrientation(_ key: String) -> Bool {
        return key == Environment.cameraOrientation ||
               key == Environment.imageOrientation ||
               key == Sensors.accelerometer ||
               key == Sensors.gyroscope
    }
}
