#pragma once
#include <stdint.h>
#include <stdbool.h>
#include "x86.h"

#define SECTOR_SIZE 512

typedef struct {
    // extended boot record
    uint8_t DriveNumber;
    uint8_t _Reserved;
    uint8_t Signature;
    uint32_t VolumeId;          // serial number, value doesn't matter
    uint8_t VolumeLabel[11];    // 11 bytes, padded with spaces
    uint8_t SystemId[8];
} PACKED FAT_ExtendedBootRecord;

typedef struct {
    uint32_t SectorsPerFat;
    uint16_t Flags;
    uint16_t FatVersion;
    uint32_t RootDirectoryCluster;
    uint16_t FSInfoSector;
    uint16_t BackupBootSector;
    uint8_t _Reserved[12];
    FAT_ExtendedBootRecord EBR;

} PACKED FAT32_ExtendedBootRecord;

typedef struct 
{
    uint8_t BootJumpInstruction[3];
    uint8_t OemIdentifier[8];
    uint16_t BytesPerSector;
    uint8_t SectorsPerCluster;
    uint16_t ReservedSectors;
    uint8_t FatCount;
    uint16_t DirEntryCount;
    uint16_t TotalSectors;
    uint8_t MediaDescriptorType;
    uint16_t SectorsPerFat;
    uint16_t SectorsPerTrack;
    uint16_t Heads;
    uint32_t HiddenSectors;
    uint32_t LargeSectorCount;
    FAT32_ExtendedBootRecord EBR32;
    // ... we don't care about code ...

} PACKED FAT_BootSector;

typedef struct{
    uint8_t bootDrive;
    union{
        FAT_BootSector BootSector;
        uint8_t BootSectorBytes[SECTOR_SIZE];
    } Bs;
    uint32_t cylinders, heads, spt;
    uint64_t absolute_sectors;
} Disk;

bool Disk_Read_Sectors(Disk* bootDrive, uint32_t lba, uint8_t sectors, void* dataOut);
bool Disk_Init(Disk *disk, uint8_t bootdrive);