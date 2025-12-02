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

int has_gpmf_stream(const char* file_path) {
    if (!file_path) return 0;

    size_t mp4Handle = OpenMP4Source((char*)file_path, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
    if (!mp4Handle) {
        mp4Handle = OpenMP4SourceUDTA((char*)file_path, 0);
    }
    if (!mp4Handle) return 0;

    uint32_t numPayloads = GetNumberPayloads(mp4Handle);
    CloseSource(mp4Handle);

    return numPayloads > 0 ? 1 : 0;
}

// MARK: - METADATA EXTRACTION (NOVO)

char* get_device_name(const char* file_path) {
    if (!file_path) return NULL;

    size_t mp4Handle = OpenMP4Source((char*)file_path, MOV_GPMF_TRAK_TYPE, MOV_GPMF_TRAK_SUBTYPE, 0);
    if (!mp4Handle) return NULL;

    uint32_t numPayloads = GetNumberPayloads(mp4Handle);
    char* deviceName = NULL;

    // Procura o nome apenas nos primeiros payloads (geralmente está no início)
    for (uint32_t i = 0; i < numPayloads && i < 5; i++) {
        uint32_t payloadSize = GetPayloadSize(mp4Handle, i);
        if (payloadSize == 0) continue;

        size_t payloadres = GetPayloadResource(mp4Handle, 0, payloadSize);
        uint32_t* payload = GetPayload(mp4Handle, payloadres, i);
        if (!payload) continue;

        GPMF_stream gs;
        if (GPMF_Init(&gs, payload, payloadSize) == GPMF_OK) {
            // Procura por DEVC -> DVNM
            if (GPMF_FindNext(&gs, GPMF_KEY_DEVICE, GPMF_RECURSE_LEVELS) == GPMF_OK) {
                GPMF_stream dev_stream;
                GPMF_CopyState(&gs, &dev_stream);
                
                if (GPMF_FindNext(&dev_stream, GPMF_KEY_DEVICE_NAME, GPMF_RECURSE_LEVELS) == GPMF_OK) {
                    char* data = (char*)GPMF_RawData(&dev_stream);
                    uint32_t size = GPMF_RawDataSize(&dev_stream);
                    
                    if (data && size > 0) {
                        deviceName = (char*)malloc(size + 1);
                        memcpy(deviceName, data, size);
                        deviceName[size] = '\0'; // Null-terminate
                        
                        FreePayloadResource(mp4Handle, payloadres);
                        break; // Achou, pode sair
                    }
                }
            }
        }
        FreePayloadResource(mp4Handle, payloadres);
    }

    CloseSource(mp4Handle);
    return deviceName;
}

// MARK: - CORE PARSER (EXTRAÇÃO COMPLETA)

C_GPMFStream* parse_gpmf_from_file(const char* file_path) {
    if (!file_path) return NULL;

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

    // Estrutura temporária
    typedef struct {
        char type[5];
        C_GPMFSample* samples;
        int32_t sample_count;
        int32_t capacity;
        int32_t elements_per_sample;
        double sample_rate;
    } TempStream;

    #define MAX_STREAM_TYPES 60 // Aumentado para suportar novos sensores
    TempStream temp_streams[MAX_STREAM_TYPES];
    int temp_stream_count = 0;
    memset(temp_streams, 0, sizeof(temp_streams));

    size_t payloadres = 0;
    
    // Loop de Payloads
    for (uint32_t payload_index = 0; payload_index < numPayloads; payload_index++) {
        uint32_t payloadSize = GetPayloadSize(mp4Handle, payload_index);
        if (payloadSize == 0 || payloadSize > 10000000) continue;

        payloadres = GetPayloadResource(mp4Handle, payloadres, payloadSize);
        uint32_t* payload = GetPayload(mp4Handle, payloadres, payload_index);
        if (!payload) continue;

        GPMF_stream gpmf_stream;
        if (GPMF_Init(&gpmf_stream, payload, payloadSize) != GPMF_OK) continue;

        GPMF_ResetState(&gpmf_stream);
        
        // Loop de Streams
        while (GPMF_FindNext(&gpmf_stream, GPMF_KEY_STREAM, GPMF_RECURSE_LEVELS) == GPMF_OK) {
            
            GPMF_stream data_stream;
            GPMF_CopyState(&gpmf_stream, &data_stream);

            if (GPMF_SeekToSamples(&data_stream) != GPMF_OK) continue;

            uint32_t fourcc_key = GPMF_Key(&data_stream);
            if (fourcc_key == 0) continue;

            // Identificação do Tipo
            char stream_type[5];
            stream_type[0] = (char)((fourcc_key >> 0) & 0xFF);
            stream_type[1] = (char)((fourcc_key >> 8) & 0xFF);
            stream_type[2] = (char)((fourcc_key >> 16) & 0xFF);
            stream_type[3] = (char)((fourcc_key >> 24) & 0xFF);
            stream_type[4] = '\0';

            // Busca ou Criação do Acumulador
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
                
                // Taxas estimadas (Mapper ajustará depois)
                if (strncmp(stream_type, "GPS", 3) == 0) ts->sample_rate = 18.0;
                else if (strncmp(stream_type, "ACCL", 4) == 0) ts->sample_rate = 200.0;
                else if (strncmp(stream_type, "GYRO", 4) == 0) ts->sample_rate = 200.0;
                else if (strncmp(stream_type, "CORI", 4) == 0) ts->sample_rate = 30.0; // Orientação costuma ser mais lenta
                else ts->sample_rate = 1.0;
            }

            if (!ts || !ts->samples) continue;

            // Extração
            uint32_t samples = GPMF_PayloadSampleCount(&data_stream);
            uint32_t elements = GPMF_ElementsInStruct(&data_stream);

            if (ts->elements_per_sample == 0) ts->elements_per_sample = elements;

            if (samples > 0 && elements > 0 && elements <= 64) {
                uint32_t buffersize = samples * elements * sizeof(double);
                
                if (buffersize > 0 && buffersize < 20000000) {
                    double* temp_buffer = (double*)malloc(buffersize + 256);
                    
                    if (temp_buffer) {
                        // GPMF_ScaledData converte tudo para Double (incluindo ISO, Shutter, etc)
                        if (GPMF_ScaledData(&data_stream, temp_buffer, buffersize, 0, samples, GPMF_TYPE_DOUBLE) == GPMF_OK) {
                            
                            // Realocação Segura
                            if (ts->sample_count + samples > ts->capacity) {
                                ts->capacity += samples + 4000; // Crescimento mais agressivo
                                C_GPMFSample* new_ptr = realloc(ts->samples, ts->capacity * sizeof(C_GPMFSample));
                                if (new_ptr) ts->samples = new_ptr;
                                else { free(temp_buffer); continue; }
                            }

                            // Cópia
                            for (uint32_t i = 0; i < samples; i++) {
                                C_GPMFSample* sample = &ts->samples[ts->sample_count++];
                                strncpy(sample->type, stream_type, 5);
                                sample->timestamp = (double)(ts->sample_count) / ts->sample_rate; // Timestamp simples (será refinado no Swift)
                                
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

    // Finalização
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
    
    return streams;
}

// MARK: - CLEANUP

void free_parsed_streams(C_GPMFStream* streams) {
    if (!streams) return;
    C_GPMFStream* current = streams;
    while (current->type[0] != '\0') {
        if (current->samples) free(current->samples);
        current++;
    }
    free(streams);
}
