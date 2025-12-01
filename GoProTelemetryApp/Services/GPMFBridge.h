//
//  GPMFBridge.h
//  GoProTelemetryApp
//
//  Created by Caio Germinari on 30/11/25.
//

#ifndef GPMFBridge_h
#define GPMFBridge_h

#include <stdint.h>

// Estruturas compatíveis com Swift
typedef struct {
    char type[5]; // FourCC + null terminator
    double timestamp;
    double values[16]; // Máximo 16 elementos por sample
} C_GPMFSample;

typedef struct {
    char type[5]; // FourCC + null terminator
    C_GPMFSample *samples;
    int32_t sample_count;
    int32_t elements_per_sample;
    double sample_rate;
} C_GPMFStream;

// Funções bridge
uint8_t* extract_gpmf_from_mp4(const char* file_path, int32_t* out_size);
int has_gpmf_stream(const char* file_path);
void free_gpmf_data(uint8_t* data);

C_GPMFStream* parse_gpmf_from_file(const char* file_path);  // Adicionada declaração
void free_parsed_streams(C_GPMFStream* streams);

#endif /* GPMFBridge_h */
