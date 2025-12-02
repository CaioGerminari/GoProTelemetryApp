//
//  GPMFBridge.h
//  Definição das estruturas e protótipos visíveis ao Swift
//

#ifndef GPMFBridge_h
#define GPMFBridge_h

#include <stdint.h>
#include <stdio.h>

// MARK: - ESTRUTURAS DE DADOS

/*
 * C_GPMFSample
 * Representa um único ponto de dado no tempo.
 * O array 'values' contém os dados já escalados (double).
 */
typedef struct {
    char type[5];          // Tipo (ex: "GPS5", "ACCL", "ISO")
    double timestamp;      // Tempo relativo em segundos
    double values[16];     // Valores (lat, lon, iso_lvl, g_force, etc)
} C_GPMFSample;

/*
 * C_GPMFStream
 * Representa uma lista completa de samples de um tipo específico.
 */
typedef struct {
    char type[5];
    C_GPMFSample* samples; // Array dinâmico de samples
    int32_t sample_count;  // Quantidade de samples
    int32_t elements_per_sample; // Quantos valores por sample (ex: GPS=5, ISO=1)
    double sample_rate;    // Frequência aproximada (Hz)
} C_GPMFStream;

// MARK: - FUNÇÕES EXPORTADAS

// Extrai TODOS os streams de telemetria (GPS, IMU, Câmera, etc)
C_GPMFStream* parse_gpmf_from_file(const char* file_path);

// Extrai apenas o Nome do Dispositivo (ex: "HERO11 Black")
// O caller é responsável por dar free() na string retornada.
char* get_device_name(const char* file_path);

// Verifica se o arquivo possui trilha GPMF válida
int has_gpmf_stream(const char* file_path);

// Limpeza de memória dos streams (Chamar no defer do Swift)
void free_parsed_streams(C_GPMFStream* streams);

#endif /* GPMFBridge_h */
