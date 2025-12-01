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
 * Representa um único ponto de dado no tempo (ex: 1 leitura de GPS)
 */
typedef struct {
    char type[5];          // Tipo (ex: "GPS5", "ACCL")
    double timestamp;      // Tempo relativo em segundos
    double values[16];     // Valores já convertidos/escalados (lat, lon, etc)
} C_GPMFSample;

/*
 * C_GPMFStream
 * Representa uma lista completa de samples de um tipo específico
 */
typedef struct {
    char type[5];
    C_GPMFSample* samples; // Array dinâmico de samples
    int32_t sample_count;  // Quantidade de samples
    int32_t elements_per_sample;
    double sample_rate;    // Frequência (Hz)
} C_GPMFStream;

// MARK: - FUNÇÕES EXPORTADAS

// Função principal de extração
C_GPMFStream* parse_gpmf_from_file(const char* file_path);

// Validação simples
int has_gpmf_stream(const char* file_path);

// Limpeza de memória (Importante chamar no Swift via defer)
void free_parsed_streams(C_GPMFStream* streams);

#endif /* GPMFBridge_h */
