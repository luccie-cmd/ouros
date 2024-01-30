#pragma once
#include <stdint.h>
#include <stdbool.h>
#define ASMCALL __attribute__((cdecl))
#define PACKED __attribute__((packed))

void    ASMCALL x86_outb(uint16_t port, uint8_t value);
uint8_t ASMCALL x86_inb(uint16_t port);
bool    ASMCALL x86_disk_reset(uint8_t drive);

bool    ASMCALL x86_disk_read(uint8_t drive,
                           uint16_t cylinder,
                           uint16_t sector,
                           uint16_t head,
                           uint8_t count,
                           void* lowerDataOut);
bool    ASMCALL x86_get_drive_params(uint8_t drive, uint32_t *cylinders, uint32_t *heads, uint32_t *spt, uint64_t *absolute_sectors);