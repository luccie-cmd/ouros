#include "disk.h"
#include "x86.h"

bool disk_init(uint16_t bootdrive, DISK *disk){
    uint8_t driveType;
    uint16_t cylinders, sectors, heads;
    disk->id = bootdrive;

    if (!x86_Disk_GetDriveParams(disk->id, &driveType, &cylinders, &sectors, &heads))
        return false;

    disk->cylinders = cylinders;
    disk->heads = heads;
    disk->sectors = sectors;

    return true;
}