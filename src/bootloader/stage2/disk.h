#pragma once
#include <stdbool.h>
#include <stdint.h>

typedef struct{
    uint8_t id;
    uint16_t cylinders;
    uint16_t sectors;
    uint16_t heads;
} DISK;

bool disk_init(uint16_t bootdrive, DISK *disk);