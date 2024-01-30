#pragma once
#include <stdint.h>
#include <stdbool.h>
#include "disk.h"
#include "x86.h" 

#define MAX_HANDLES            10
#define FAT_CACHE_SIZE         5
#define ROOT_DIRECTORY_HANDLE -1
#define MAX_PATH_SIZE          256

typedef struct{
    uint8_t Name[11];
    uint8_t Attributes;
    uint8_t _Reserved;
    uint8_t CreatedTimeTenths;
    uint16_t CreatedTime;
    uint16_t CreatedDate;
    uint16_t AccessedDate;
    uint16_t FirstClusterHigh;
    uint16_t ModifiedTime;
    uint16_t ModifiedDate;
    uint16_t FirstClusterLow;
    uint32_t Size;
} PACKED Fat_Entry;

typedef struct{
    int handle;
    bool is_dir;
    uint32_t pos, size;
} Fat_File;

typedef struct{
    uint8_t Buffer[SECTOR_SIZE];
    Fat_File Public;
    bool Opened;
    uint32_t FirstCluster;
    uint32_t CurrentCluster;
    uint32_t CurrentSectorInCluster;
} Fat_FileData;

typedef struct{
    Disk *disk;
    Fat_FileData handles[MAX_HANDLES];
    uint8_t FatCache[FAT_CACHE_SIZE * SECTOR_SIZE];
    uint32_t FatCachePosition;
    Fat_FileData RootDirectory;
} Fat;

enum FAT_Attributes
{
    FAT_ATTRIBUTE_READ_ONLY         = 0x01,
    FAT_ATTRIBUTE_HIDDEN            = 0x02,
    FAT_ATTRIBUTE_SYSTEM            = 0x04,
    FAT_ATTRIBUTE_VOLUME_ID         = 0x08,
    FAT_ATTRIBUTE_DIRECTORY         = 0x10,
    FAT_ATTRIBUTE_ARCHIVE           = 0x20,
    FAT_ATTRIBUTE_LFN               = FAT_ATTRIBUTE_READ_ONLY | FAT_ATTRIBUTE_HIDDEN | FAT_ATTRIBUTE_SYSTEM | FAT_ATTRIBUTE_VOLUME_ID
};

bool Fat_Init(Fat *fat, uint16_t bootdrive);
Fat_File *Fat_Open(Fat *fat, const char* path);
uint32_t Fat_Read(Fat *fat, Fat_File *file, uint32_t size, void* dataOut);
bool Fat_ReadEntry(Fat *fat, Fat_File *file, Fat_Entry *entry);
void Fat_Close(Fat* fat, Fat_File *file);