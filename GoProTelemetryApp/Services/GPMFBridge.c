//
//  GPMFBridge.c
//  CORREÇÃO CRÍTICA: Uso de GPMF_ScaledData para aplicar escalas (SCAL)
//

#include "GPMFBridge.h"
#include "GPMF_parser.h"
#include "GPMF_utils.h"
#include "GPMF_mp4reader.h"
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>

// DEBUG MACROS
#ifdef DEBUG
#define LOG_DEBUG(fmt, ...) printf("[DEBUG] " fmt "\n", ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) printf("[ERROR] " fmt "\n", ##__VA_ARGS__)
#else
#define LOG_DEBUG(fmt, ...)
#define LOG_ERROR(fmt, ...)
#endif

// ------------------------
// Check if video has telemetry
// ------------------------
int has_gpmf_stream(const char* file_path)
{
    if (!file_path) return 0;

    FILE* f = fopen(file_path, "rb");
    if (!f) return 0;
    fclose(f);

    size_t mp4Handle = OpenMP4Source((char*)file_path, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
    if (!mp4Handle) {
        mp4Handle = OpenMP4SourceUDTA((char*)file_path, 0);
    }
    if (!mp4Handle) return 0;

    uint32_t numPayloads = GetNumberPayloads(mp4Handle);
    CloseSource(mp4Handle);

    return numPayloads > 0 ? 1 : 0;
}

// ------------------------
// Parse GPMF data directly from MP4 file
// ------------------------
C_GPMFStream* parse_gpmf_from_file(const char* file_path)
{
    if (!file_path) return NULL;

    // Abrir MP4
    size_t mp4Handle = OpenMP4Source((char*)file_path, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
    if (!mp4Handle) {
        mp4Handle = OpenMP4SourceUDTA((char*)file_path, 0);
    }
    if (!mp4Handle) {
        LOG_ERROR("Failed to open MP4 or UDTA source");
        return NULL;
    }

    uint32_t numPayloads = GetNumberPayloads(mp4Handle);
    if (numPayloads == 0) {
        CloseSource(mp4Handle);
        return NULL;
    }

    LOG_DEBUG("Found %u payloads to process", numPayloads);

    // Estrutura para acumular samples
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
    
    // LOOP ATRAVÉS DE CADA PAYLOAD
    for (uint32_t payload_index = 0; payload_index < numPayloads; payload_index++) {
        uint32_t payloadSize = GetPayloadSize(mp4Handle, payload_index);
        
        // Validação de segurança
        if (payloadSize == 0 || payloadSize > 10000000) {
            continue;
        }

        payloadres = GetPayloadResource(mp4Handle, payloadres, payloadSize);
        uint32_t* payload = GetPayload(mp4Handle, payloadres, payload_index);
        if (!payload) continue;

        GPMF_stream gpmf_stream;
        if (GPMF_Init(&gpmf_stream, payload, payloadSize) != GPMF_OK) {
            continue;
        }

        if (payload_index % 100 == 0) {
            LOG_DEBUG("Processing payload %u/%u", payload_index + 1, numPayloads);
        }

        GPMF_ResetState(&gpmf_stream);
        
        // Loop através dos streams
        while (GPMF_FindNext(&gpmf_stream, GPMF_KEY_STREAM, GPMF_RECURSE_LEVELS) == GPMF_OK) {
            
            GPMF_stream data_stream;
            GPMF_CopyState(&gpmf_stream, &data_stream);

            if (GPMF_SeekToSamples(&data_stream) != GPMF_OK) continue;

            uint32_t fourcc_key = GPMF_Key(&data_stream);
            if (fourcc_key == 0) continue;

            char stream_type[5];
            stream_type[0] = (char)((fourcc_key >> 0) & 0xFF);
            stream_type[1] = (char)((fourcc_key >> 8) & 0xFF);
            stream_type[2] = (char)((fourcc_key >> 16) & 0xFF);
            stream_type[3] = (char)((fourcc_key >> 24) & 0xFF);
            stream_type[4] = '\0';

            // Encontrar ou criar acumulador
            TempStream* ts = NULL;
            for (int i = 0; i < temp_stream_count; i++) {
                if (strncmp(temp_streams[i].type, stream_type, 4) == 0) {
                    ts = &temp_streams[i];
                    break;
                }
            }

            if (!ts && temp_stream_count < MAX_STREAM_TYPES) {
                ts = &temp_streams[temp_stream_count++];
                strncpy(ts->type, stream_type, 5);
                ts->capacity = 1000;
                ts->samples = calloc(ts->capacity, sizeof(C_GPMFSample));
                
                // Taxa de amostragem estimada
                if (strncmp(stream_type, "GPS", 3) == 0) ts->sample_rate = 18.0;
                else if (strncmp(stream_type, "ACCL", 4) == 0) ts->sample_rate = 200.0;
                else if (strncmp(stream_type, "GYRO", 4) == 0) ts->sample_rate = 200.0;
                else ts->sample_rate = 1.0;
            }

            if (!ts || !ts->samples) continue;

            uint32_t samples = GPMF_PayloadSampleCount(&data_stream);
            uint32_t elements = GPMF_ElementsInStruct(&data_stream);

            if (ts->elements_per_sample == 0) ts->elements_per_sample = elements;

            if (samples > 0 && elements > 0 && elements <= 64) {
                
                // --- MUDANÇA PRINCIPAL AQUI ---
                // Usamos GPMF_ScaledDataSize com GPMF_TYPE_DOUBLE para garantir espaço
                // Isso calcula o tamanho necessário já convertido para double
                uint32_t buffersize = samples * elements * sizeof(double);
                
                if (buffersize > 0 && buffersize < 10000000) {
                    double* temp_buffer = (double*)malloc(buffersize + 128);
                    
                    if (temp_buffer) {
                        // GPMF_ScaledData aplica a escala (SCAL) e converte para double automaticamente
                        if (GPMF_ScaledData(&data_stream, temp_buffer, buffersize, 0, samples, GPMF_TYPE_DOUBLE) == GPMF_OK) {
                            
                            // Expandir memória
                            if (ts->sample_count + samples > ts->capacity) {
                                ts->capacity += samples + 2000;
                                C_GPMFSample* new_ptr = realloc(ts->samples, ts->capacity * sizeof(C_GPMFSample));
                                if (new_ptr) ts->samples = new_ptr;
                                else { free(temp_buffer); continue; }
                            }

                            // Copiar dados já escalados
                            for (uint32_t i = 0; i < samples; i++) {
                                C_GPMFSample* sample = &ts->samples[ts->sample_count++];
                                strncpy(sample->type, stream_type, 5);
                                sample->timestamp = (double)(ts->sample_count) / ts->sample_rate;
                                
                                for (uint32_t j = 0; j < elements && j < 16; j++) {
                                    // Agora temp_buffer já contém os valores reais (graus, metros, etc.)
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

    // Finalizar e retornar
    C_GPMFStream* streams = calloc(temp_stream_count + 1, sizeof(C_GPMFStream));
    if (!streams) {
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

    streams[temp_stream_count].type[0] = '\0';
    LOG_DEBUG("Successfully parsed %d streams", temp_stream_count);
    
    return streams;
}

// ------------------------
// MANTER COMPATIBILIDADE (LEGACY)
// ------------------------
uint8_t* extract_gpmf_from_mp4(const char* file_path, int32_t* out_size) { return NULL; }
C_GPMFStream* parse_gpmf_data(const uint8_t* data, int32_t size) { return NULL; }
void free_gpmf_data(uint8_t* data) { if (data) free(data); }
void free_parsed_streams(C_GPMFStream* streams)
{
    if (!streams) return;
    C_GPMFStream* current = streams;
    while (current->type[0] != '\0') {
        if (current->samples) free(current->samples);
        current++;
    }
    free(streams);
}
