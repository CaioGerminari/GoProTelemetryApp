//
//  GPMFBridge.c - VERSÃO CORRIGIDA
//  Processa cada payload individualmente como o demo da GoPro
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
    if (!file_path) {
        LOG_ERROR("Null file path");
        return 0;
    }

    FILE* f = fopen(file_path, "rb");
    if (!f) {
        LOG_ERROR("Cannot open file: %s (errno: %d)", file_path, errno);
        return 0;
    }
    fclose(f);

    size_t mp4Handle = OpenMP4Source((char*)file_path, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
    if (!mp4Handle) {
        LOG_DEBUG("OpenMP4Source failed, trying UDTA");
        mp4Handle = OpenMP4SourceUDTA((char*)file_path, 0);
    }
    if (!mp4Handle) {
        LOG_ERROR("Cannot open MP4 source or UDTA");
        return 0;
    }

    uint32_t numPayloads = GetNumberPayloads(mp4Handle);
    CloseSource(mp4Handle);

    LOG_DEBUG("Found %u payloads in file %s", numPayloads, file_path);
    return numPayloads > 0 ? 1 : 0;
}

// ------------------------
// Parse GPMF data directly from MP4 file
// CORRIGIDO: Processa cada payload individualmente
// ------------------------
C_GPMFStream* parse_gpmf_from_file(const char* file_path)
{
    if (!file_path) {
        LOG_ERROR("Null file path");
        return NULL;
    }

    // Abrir MP4
    size_t mp4Handle = OpenMP4Source((char*)file_path, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
    if (!mp4Handle) {
        LOG_DEBUG("Standard MP4 open failed, trying UDTA");
        mp4Handle = OpenMP4SourceUDTA((char*)file_path, 0);
    }
    if (!mp4Handle) {
        LOG_ERROR("Failed to open MP4 or UDTA source");
        return NULL;
    }

    uint32_t numPayloads = GetNumberPayloads(mp4Handle);
    if (numPayloads == 0) {
        LOG_ERROR("No GPMF payloads found");
        CloseSource(mp4Handle);
        return NULL;
    }

    LOG_DEBUG("Found %u payloads to process", numPayloads);

    // Estrutura para acumular samples de todos os payloads
    typedef struct {
        char type[5];
        C_GPMFSample* samples;
        int32_t sample_count;
        int32_t capacity;
        int32_t elements_per_sample;
        double sample_rate;
    } TempStream;

    #define MAX_STREAM_TYPES 10
    TempStream temp_streams[MAX_STREAM_TYPES];
    int temp_stream_count = 0;
    memset(temp_streams, 0, sizeof(temp_streams));

    size_t payloadres = 0;
    
    // LOOP ATRAVÉS DE CADA PAYLOAD (como o demo da GoPro)
    for (uint32_t payload_index = 0; payload_index < numPayloads; payload_index++) {
        uint32_t payloadSize = GetPayloadSize(mp4Handle, payload_index);
        if (payloadSize == 0 || payloadSize > 1000000) {
            LOG_DEBUG("Skipping invalid payload %u (size=%u)", payload_index, payloadSize);
            continue;
        }

        payloadres = GetPayloadResource(mp4Handle, payloadres, payloadSize);
        uint32_t* payload = GetPayload(mp4Handle, payloadres, payload_index);
        if (!payload) {
            LOG_DEBUG("Failed to get payload %u", payload_index);
            continue;
        }

        // INICIALIZAR GPMF COM ESTE PAYLOAD INDIVIDUAL
        GPMF_stream gpmf_stream;
        if (GPMF_Init(&gpmf_stream, payload, payloadSize / 4) != GPMF_OK) {
            LOG_ERROR("GPMF_Init failed for payload %u", payload_index);
            continue;
        }

        LOG_DEBUG("Processing payload %u/%u", payload_index + 1, numPayloads);

        // Processar streams neste payload
        GPMF_ResetState(&gpmf_stream);
        
        while (GPMF_FindNext(&gpmf_stream, GPMF_KEY_STREAM, GPMF_RECURSE_LEVELS) == GPMF_OK) {
            // Identificar o tipo de stream
            GPMF_stream find_stream;
            GPMF_CopyState(&gpmf_stream, &find_stream);

            uint32_t fourcc_key = 0;
            while (GPMF_Next(&find_stream, GPMF_CURRENT_LEVEL) == GPMF_OK) {
                uint32_t key = GPMF_Key(&find_stream);
                if (key != GPMF_KEY_STREAM && key != 0) {
                    fourcc_key = key;
                    break;
                }
            }

            if (fourcc_key == 0) continue;

            char stream_type[5];
            stream_type[0] = (char)((fourcc_key >> 0) & 0xFF);
            stream_type[1] = (char)((fourcc_key >> 8) & 0xFF);
            stream_type[2] = (char)((fourcc_key >> 16) & 0xFF);
            stream_type[3] = (char)((fourcc_key >> 24) & 0xFF);
            stream_type[4] = '\0';

            // Encontrar ou criar stream temporária
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
                
                // Definir sample rate
                if (strncmp(stream_type, "GPS", 3) == 0)
                    ts->sample_rate = 18.0;
                else if (strncmp(stream_type, "ACCL", 4) == 0 || strncmp(stream_type, "GYRO", 4) == 0)
                    ts->sample_rate = 200.0;
                else
                    ts->sample_rate = 100.0;
            }

            if (!ts || !ts->samples) continue;

            // Extrair samples deste payload
            GPMF_SeekToSamples(&gpmf_stream);
            uint32_t samples = GPMF_PayloadSampleCount(&gpmf_stream);
            uint32_t elements = GPMF_ElementsInStruct(&gpmf_stream);

            if (ts->elements_per_sample == 0) {
                ts->elements_per_sample = elements;
            }

            if (samples > 0 && elements > 0 && elements <= 16) {
                uint32_t data_size = GPMF_FormattedDataSize(&gpmf_stream);
                if (data_size > 0 && data_size < 1000000) {
                    float* temp_buffer = malloc(data_size);
                    if (temp_buffer) {
                        if (GPMF_FormattedData(&gpmf_stream, temp_buffer, data_size, 0, samples) == GPMF_OK) {
                            // Expandir array se necessário
                            if (ts->sample_count + samples > ts->capacity) {
                                ts->capacity = ts->sample_count + samples + 1000;
                                ts->samples = realloc(ts->samples, ts->capacity * sizeof(C_GPMFSample));
                            }

                            // Adicionar samples
                            for (uint32_t i = 0; i < samples; i++) {
                                C_GPMFSample* sample = &ts->samples[ts->sample_count++];
                                strncpy(sample->type, stream_type, 5);
                                sample->timestamp = (double)ts->sample_count / ts->sample_rate;
                                
                                for (uint32_t j = 0; j < elements && j < 16; j++) {
                                    sample->values[j] = (double)temp_buffer[i * elements + j];
                                }
                            }
                        }
                        free(temp_buffer);
                    }
                }
            }
        }

        GPMF_Free(&gpmf_stream);
    }

    if (payloadres) FreePayloadResource(mp4Handle, payloadres);
    CloseSource(mp4Handle);

    // Converter temp_streams para C_GPMFStream
    C_GPMFStream* streams = calloc(temp_stream_count + 1, sizeof(C_GPMFStream));
    if (!streams) {
        for (int i = 0; i < temp_stream_count; i++) {
            if (temp_streams[i].samples) free(temp_streams[i].samples);
        }
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
    LOG_DEBUG("Successfully parsed %d streams with total samples", temp_stream_count);

    return streams;
}

// ------------------------
// MANTER COMPATIBILIDADE: extract + parse (ainda funcionais para transição)
// ------------------------
uint8_t* extract_gpmf_from_mp4(const char* file_path, int32_t* out_size)
{
    // Função mantida apenas para compatibilidade, mas retorna dados válidos
    if (!file_path || !out_size) {
        LOG_ERROR("Null parameters");
        return NULL;
    }
    *out_size = 0;
    
    // Abrir MP4
    size_t mp4Handle = OpenMP4Source((char*)file_path, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
    if (!mp4Handle) {
        mp4Handle = OpenMP4SourceUDTA((char*)file_path, 0);
    }
    if (!mp4Handle) {
        LOG_ERROR("Failed to open MP4");
        return NULL;
    }

    uint32_t numPayloads = GetNumberPayloads(mp4Handle);
    if (numPayloads == 0) {
        CloseSource(mp4Handle);
        return NULL;
    }

    // Somar tamanho total
    uint32_t totalSize = 0;
    for (uint32_t i = 0; i < numPayloads; i++) {
        totalSize += GetPayloadSize(mp4Handle, i);
    }

    uint8_t* outData = (uint8_t*)malloc(totalSize);
    if (!outData) {
        CloseSource(mp4Handle);
        return NULL;
    }

    // Copiar todos os payloads
    uint32_t offset = 0;
    size_t payloadres = 0;
    for (uint32_t i = 0; i < numPayloads; i++) {
        uint32_t payloadSize = GetPayloadSize(mp4Handle, i);
        if (payloadSize == 0) continue;

        payloadres = GetPayloadResource(mp4Handle, payloadres, payloadSize);
        uint32_t* payload = GetPayload(mp4Handle, payloadres, i);
        if (!payload) continue;

        memcpy(outData + offset, payload, payloadSize);
        offset += payloadSize;
    }

    if (payloadres) FreePayloadResource(mp4Handle, payloadres);
    CloseSource(mp4Handle);
    
    *out_size = (int32_t)totalSize;
    return outData;
}

C_GPMFStream* parse_gpmf_data(const uint8_t* data, int32_t size)
{
    // NOTA: Esta função NÃO funciona corretamente porque tenta processar
    // dados concatenados. Use parse_gpmf_from_file() para resultados corretos.
    LOG_ERROR("parse_gpmf_data: Dados concatenados não são válidos. Use parse_gpmf_from_file()");
    return NULL;
}

// ------------------------
// Free functions
// ------------------------
void free_gpmf_data(uint8_t* data)
{
    if (data) {
        free(data);
        LOG_DEBUG("Freed GPMF data");
    }
}

void free_parsed_streams(C_GPMFStream* streams)
{
    if (!streams) return;

    C_GPMFStream* current = streams;
    while (current->type[0] != '\0') {
        if (current->samples) {
            free(current->samples);
            LOG_DEBUG("Freed samples for stream %s", current->type);
        }
        current++;
    }

    free(streams);
    LOG_DEBUG("Freed all streams");
}
