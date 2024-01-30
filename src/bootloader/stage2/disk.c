#include "disk.h"
#include "x86.h"
#include "stdio.h"

static void DISK_LBA2CHS(Disk* disk, uint32_t lba, uint16_t* cylinderOut, uint16_t* sectorOut, uint16_t* headOut)
{
    // sector = (LBA % sectors per track + 1)
    *sectorOut = lba % disk->spt + 1;

    // cylinder = (LBA / sectors per track) / heads
    *cylinderOut = (lba / disk->spt) / disk->heads;

    // head = (LBA / sectors per track) % heads
    *headOut = (lba / disk->spt) % disk->heads;
}

bool Disk_Read_Sectors(Disk* disk, uint32_t lba, uint8_t sectors, void* dataOut){
    printf("Lba %u sectors %u disk %x\n", lba, sectors, disk->bootDrive);
    uint16_t cylinder, sector, head;
    DISK_LBA2CHS(disk, lba, &cylinder, &sector, &head);
    printf("CHS = %d %d %d\n", cylinder, head, sector);
    for(int i = 0; i < 3; ++i){
        printf("Attempt %hd\n", i);
        if(x86_disk_read(disk->bootDrive, cylinder, sector, head, sectors, dataOut)){
            printf("Attempt %u success\n", i);
            return true;
        }
        printf("Attempt %hd failed!\n", i);
        x86_disk_reset(disk->bootDrive);
    }
    printf("Failed to read LBA %lu with sectors %u\n", lba, sectors);
    return false;
}

bool Disk_Init(Disk *disk, uint8_t bootdrive){
    disk->bootDrive = bootdrive;
    // Read the bootsector
    if(!x86_get_drive_params(disk->bootDrive, &disk->cylinders, &disk->heads, &disk->spt, &disk->absolute_sectors)){
        return false;
    }
    // disk->heads += 1;
    // disk->cylinders += 1;
    printf("Disk geomtery\n");
    printf("CH = %x %x SPT = %x ABSSEC = %x\n", disk->cylinders, disk->heads, disk->spt, disk->absolute_sectors);

    return Disk_Read_Sectors(disk, 0, 1, disk->Bs.BootSectorBytes);
}