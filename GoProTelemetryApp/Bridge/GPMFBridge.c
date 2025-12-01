//
//  GPMFBridge.c
//  Implementação da extração e processamento GPMF
//

#include "GPMFBridge.h"
#include "GPMF_parser.h"
#include "GPMF_utils.h"
#include "GPMF_mp4reader.h"
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

// MARK: - HELPERS

// Verifica se o arquivo tem telemetria
int has_gpmf_stream(const char* file_path) {
    if (!file_path) return 0;

    // Tenta abrir como MP4 padrão ou UDTA
    size_t mp4Handle = OpenMP4Source((char*)file_path, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
    if (!mp4Handle) {
        mp4Handle = OpenMP4SourceUDTA((char*)file_path, 0);
    }
    if (!mp4Handle) return 0;

    uint32_t numPayloads = GetNumberPayloads(mp4Handle);
    CloseSource(mp4Handle);

    return numPayloads > 0 ? 1 : 0;
}

// MARK: - CORE PARSER

C_GPMFStream* parse_gpmf_from_file(const char* file_path) {
    if (!file_path) return NULL;

    // 1. Abertura do Arquivo
    size_t mp4Handle = OpenMP4Source((char*)file_path, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
    if (!mp4Handle) {
        mp4Handle = OpenMP4SourceUDTA((char*)file_path, 0);
    }
    if (!mp4Handle) return NULL;

    uint32_t numPayloads = GetNumberPayloads(mp4Handle);
    if (numPayloads == 0) {
        CloseSource(mp4Handle);
        return NULL;
    }

    // Estrutura temporária para acumular dados durante o loop
    typedef struct {
        char type[5];
        C_GPMFSample* samples;
        int32_t sample_count;
        int32_t capacity;
        int32_t elements_per_sample;
        double sample_rate;
    } TempStream;

    #define MAX_STREAM_TYPES 60
    TempStream temp_streams[MAX_STREAM_TYPES];
    int temp_stream_count = 0;
    memset(temp_streams, 0, sizeof(temp_streams));

    size_t payloadres = 0;
    
    // =========================================================
    // 2. Loop de Payloads (Itera sobre cada pacote de dados)
    // =========================================================
    for (uint32_t payload_index = 0; payload_index < numPayloads; payload_index++) {
        uint32_t payloadSize = GetPayloadSize(mp4Handle, payload_index);
        
        // Segurança: Ignora payloads vazios ou gigantes (erro de leitura)
        if (payloadSize == 0 || payloadSize > 10000000) continue;

        payloadres = GetPayloadResource(mp4Handle, payloadres, payloadSize);
        uint32_t* payload = GetPayload(mp4Handle, payloadres, payload_index);
        if (!payload) continue;

        GPMF_stream gpmf_stream;
        // CRÍTICO: Passar o tamanho exato em bytes
        if (GPMF_Init(&gpmf_stream, payload, payloadSize) != GPMF_OK) continue;

        GPMF_ResetState(&gpmf_stream);
        
        // =====================================================
        // 3. Loop de Streams (GPS, ACCL, GYRO dentro do payload)
        // =====================================================
        while (GPMF_FindNext(&gpmf_stream, GPMF_KEY_STREAM, GPMF_RECURSE_LEVELS) == GPMF_OK) {
            
            // Trabalhamos numa cópia para não perder o cursor do loop principal
            GPMF_stream data_stream;
            GPMF_CopyState(&gpmf_stream, &data_stream);

            // Entra na estrutura de dados
            if (GPMF_SeekToSamples(&data_stream) != GPMF_OK) continue;

            uint32_t fourcc_key = GPMF_Key(&data_stream);
            if (fourcc_key == 0) continue;

            // Converte FourCC int para string
            char stream_type[5];
            stream_type[0] = (char)((fourcc_key >> 0) & 0xFF);
            stream_type[1] = (char)((fourcc_key >> 8) & 0xFF);
            stream_type[2] = (char)((fourcc_key >> 16) & 0xFF);
            stream_type[3] = (char)((fourcc_key >> 24) & 0xFF);
            stream_type[4] = '\0';

            // 4. Gestão de Memória (Encontrar ou criar acumulador)
            TempStream* ts = NULL;
            for (int i = 0; i < temp_stream_count; i++) {
                if (strncmp(temp_streams[i].type, stream_type, 4) == 0) {
                    ts = &temp_streams[i];
                    break;
                }
            }

            // Novo tipo encontrado? Inicializa struct.
            if (!ts && temp_stream_count < MAX_STREAM_TYPES) {
                ts = &temp_streams[temp_stream_count++];
                strncpy(ts->type, stream_type, 5);
                ts->capacity = 1000;
                ts->samples = calloc(ts->capacity, sizeof(C_GPMFSample));
                
                // Taxas de amostragem estimadas (serão ajustadas se houver dados precisos)
                if (strncmp(stream_type, "GPS", 3) == 0) ts->sample_rate = 18.0;
                else if (strncmp(stream_type, "ACCL", 4) == 0) ts->sample_rate = 200.0;
                else if (strncmp(stream_type, "GYRO", 4) == 0) ts->sample_rate = 200.0;
                else ts->sample_rate = 1.0;
            }

            if (!ts || !ts->samples) continue;

            // =================================================
            // 5. Extração e Conversão de Dados
            // =================================================
            uint32_t samples = GPMF_PayloadSampleCount(&data_stream);
            uint32_t elements = GPMF_ElementsInStruct(&data_stream);

            if (ts->elements_per_sample == 0) ts->elements_per_sample = elements;

            if (samples > 0 && elements > 0 && elements <= 64) {
                // Tamanho necessário para Doubles
                uint32_t buffersize = samples * elements * sizeof(double);
                
                if (buffersize > 0 && buffersize < 10000000) {
                    double* temp_buffer = (double*)malloc(buffersize + 128); // Padding de segurança
                    
                    if (temp_buffer) {
                        // CRÍTICO: GPMF_ScaledData aplica o fator SCAL e converte unidades
                        if (GPMF_ScaledData(&data_stream, temp_buffer, buffersize, 0, samples, GPMF_TYPE_DOUBLE) == GPMF_OK) {
                            
                            // Realocação se o buffer encher
                            if (ts->sample_count + samples > ts->capacity) {
                                ts->capacity += samples + 2000;
                                C_GPMFSample* new_ptr = realloc(ts->samples, ts->capacity * sizeof(C_GPMFSample));
                                if (new_ptr) ts->samples = new_ptr;
                                else { free(temp_buffer); continue; }
                            }

                            // Copia os dados convertidos para nossa struct final
                            for (uint32_t i = 0; i < samples; i++) {
                                C_GPMFSample* sample = &ts->samples[ts->sample_count++];
                                strncpy(sample->type, stream_type, 5);
                                sample->timestamp = (double)(ts->sample_count) / ts->sample_rate;
                                
                                for (uint32_t j = 0; j < elements && j < 16; j++) {
                                    sample->values[j] = temp_buffer[i * elements + j];
                                }
                            }
                        }
                        free(temp_buffer);
                    }
                }
            }
        }
    }

    if (payloadres) FreePayloadResource(mp4Handle, payloadres);
    CloseSource(mp4Handle);

    // 6. Finalização e Retorno
    C_GPMFStream* streams = calloc(temp_stream_count + 1, sizeof(C_GPMFStream));
    if (!streams) {
        // Fallback de erro de memória
        for (int i = 0; i < temp_stream_count; i++) if (temp_streams[i].samples) free(temp_streams[i].samples);
        return NULL;
    }

    for (int i = 0; i < temp_stream_count; i++) {
        strncpy(streams[i].type, temp_streams[i].type, 5);
        streams[i].samples = temp_streams[i].samples;
        streams[i].sample_count = temp_streams[i].sample_count;
        streams[i].elements_per_sample = temp_streams[i].elements_per_sample;
        streams[i].sample_rate = temp_streams[i].sample_rate;
    }

    // Marcador de fim de array (Sentinela)
    streams[temp_stream_count].type[0] = '\0';
    
    return streams;
}

// MARK: - MEMORY MANAGEMENT

void free_parsed_streams(C_GPMFStream* streams) {
    if (!streams) return;
    C_GPMFStream* current = streams;
    while (current->type[0] != '\0') {
        if (current->samples) free(current->samples);
        current++;
    }
    free(streams);
}
