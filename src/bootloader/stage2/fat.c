#include "fat.h"
#include "stdio.h"
#include "memdefs.h"
#include "string.h"
#include "ctype.h"
#include "minmax.h"
#include <stddef.h>

uint32_t DataLBA = 0;

uint32_t Fat_ClusterToLba(Fat* fat, uint32_t cluster){
    return DataLBA + (cluster - 2) * fat->disk->Bs.BootSector.SectorsPerCluster;
}

bool Fat_ReadFat(Fat* fat, size_t lbaIndex)
{
    return Disk_Read_Sectors(fat->disk, fat->disk->Bs.BootSector.ReservedSectors + lbaIndex, FAT_CACHE_SIZE, fat->FatCache);
}

uint32_t FAT_NextCluster(Fat* fat, uint32_t currentCluster)
{    
    // Determine the byte offset of the entry we need to read
    uint32_t fatIndex = currentCluster * 4;
    uint32_t fatIndexSector = fatIndex / SECTOR_SIZE;
    if (fatIndexSector < fat->FatCachePosition 
        || fatIndexSector >= fat->FatCachePosition + FAT_CACHE_SIZE)
    {
        Fat_ReadFat(fat, fatIndexSector);
        fat->FatCachePosition = fatIndexSector;
    }

    fatIndex -= (fat->FatCachePosition * SECTOR_SIZE);
    return *(uint32_t*)(fatIndex);
}


bool Fat_Init(Fat *fat, uint16_t bootdrive){
    printf("Initializing Disk!\n");
    if(!Disk_Init(fat->disk, bootdrive)){
        printf("Failed to init disk!!!\n");
        return false;
    }
    printf("Disk initialized!\n");
    


    // read FAT
    fat->FatCachePosition = 0xFFFFFFFF;
    
    uint32_t SectorsPerFat = fat->disk->Bs.BootSector.EBR32.SectorsPerFat;
    
    // open root directory file
    uint32_t rootDirLba;
    DataLBA = fat->disk->Bs.BootSector.ReservedSectors + SectorsPerFat * fat->disk->Bs.BootSector.FatCount;
    rootDirLba = Fat_ClusterToLba(fat, fat->disk->Bs.BootSector.EBR32.RootDirectoryCluster);
    printf("RootDirLBA = %u\nDataLBA = %u\n", rootDirLba, DataLBA);

    fat->RootDirectory.Public.handle = ROOT_DIRECTORY_HANDLE;
    fat->RootDirectory.Public.is_dir = true;
    fat->RootDirectory.Public.pos = 0;
    fat->RootDirectory.Public.size = sizeof(Fat_Entry) * fat->disk->Bs.BootSector.DirEntryCount;
    fat->RootDirectory.Opened = true;
    fat->RootDirectory.FirstCluster = rootDirLba;
    fat->RootDirectory.CurrentCluster = rootDirLba;
    fat->RootDirectory.CurrentSectorInCluster = 0;

    printf("Reading RootDIR!\n");

    if (!Disk_Read_Sectors(fat->disk, rootDirLba, 1, fat->RootDirectory.Buffer)){
        printf("FAT: read root directory failed\r\n");
        return false;
    }

    printf("Resseting opened files!\n");

    // reset opened files
    for (int i = 0; i < MAX_HANDLES; i++)
        fat->handles[i].Opened = false;

    printf("Everything worked!\n");
    return true;
}

Fat_File* Fat_OpenEntry(Fat* fat, Fat_Entry* entry)
{
    // find empty handle
    int handle = -1;
    for (int i = 0; i < MAX_HANDLES && handle < 0; i++)
    {
        if (!fat->handles[i].Opened)
            handle = i;
    }

    // out of handles
    if (handle < 0)
    {
        printf("Fat: out of file handles\r\n");
        return NULL;
    }

    // setup vars
    Fat_FileData* fd = &fat->handles[handle];
    fd->Public.handle = handle;
    fd->Public.is_dir = (entry->Attributes & FAT_ATTRIBUTE_DIRECTORY) != 0;
    fd->Public.pos = 0;
    fd->Public.size = entry->Size;
    fd->FirstCluster = entry->FirstClusterLow + ((uint32_t)entry->FirstClusterHigh << 16);
    fd->CurrentCluster = fd->FirstCluster;
    fd->CurrentSectorInCluster = 0;

    if (!Disk_Read_Sectors(fat->disk, Fat_ClusterToLba(fat, fd->CurrentCluster), 1, fd->Buffer))
    {
        printf("Fat: open entry failed - read error cluster=%d lba=%d\n", fd->CurrentCluster, Fat_ClusterToLba(fat, fd->CurrentCluster));
        for (int i = 0; i < 11; i++)
            printf("%c", entry->Name[i]);
        printf("\n");
        for(;;);
    }

    fd->Opened = true;
    return &fd->Public;
}

static void Fat_GetShortName(const char *name, char *shortName){
    // convert from name to fat name
    memset(shortName, ' ', 12);
    shortName[11] = '\0';

    const char* ext = strchr(name, '.');
    if (ext == NULL)
        ext = name + 11;

    for (int i = 0; i < 8 && name[i] && name + i < ext; i++)
        shortName[i] = toupper(name[i]);

    if (ext != name + 11)
    {
        for (int i = 0; i < 3 && ext[i + 1]; i++)
            shortName[i + 8] = toupper(ext[i + 1]);
    }
}

static bool Fat_FindFile(Fat* fat, Fat_File* file, const char* name, Fat_Entry* entryOut)
{
    char shortName[12];
    Fat_Entry entry;

    Fat_GetShortName(name, shortName);

    printf("Fat_Find_File name: `%s` shortname: `%s`\n", name, shortName);

    while (Fat_ReadEntry(fat, file, &entry))
    {
        printf("Shortname = `%s` entry.name = `%s`\n", shortName, entry.Name);
        if (memcmp(shortName, entry.Name, 11) == 0)
        {
            *entryOut = entry;
            return true;
        }
    }
    
    return false;
}


uint32_t Fat_Read(Fat *fat, Fat_File *file, uint32_t byteCount, void* dataOut){
    // get file data
    Fat_FileData* fd = (file->handle == ROOT_DIRECTORY_HANDLE) 
        ? &fat->RootDirectory 
        : &fat->handles[file->handle];
    printf("Fat_Read\n");
    printf("Is rootdir handle = %d\n", (file->handle == ROOT_DIRECTORY_HANDLE));
    uint8_t* u8DataOut = (uint8_t*)dataOut;

    // don't read past the end of the file
    if (!fd->Public.is_dir || (fd->Public.is_dir && fd->Public.size != 0))
        byteCount = min(byteCount, fd->Public.size - fd->Public.pos);
    printf("Bytecount = %lu\n", byteCount);

    while (byteCount > 0){
        uint32_t leftInBuffer = SECTOR_SIZE - (fd->Public.pos % SECTOR_SIZE);
        uint32_t take = min(byteCount, leftInBuffer);

        memcpy(u8DataOut, fd->Buffer + fd->Public.pos % SECTOR_SIZE, take);
        u8DataOut += take;
        fd->Public.pos += take;
        byteCount -= take;
        printf("Left in buffer = %u take = %u\n", leftInBuffer, take);
        // See if we need to read more data
        if (leftInBuffer == take)
        {
            // Special handling for root directory
            if (fd->Public.handle == ROOT_DIRECTORY_HANDLE)
            {
                ++fd->CurrentCluster;

                // read next sector
                printf("Reading next sector root dir!\n");
                if (!Disk_Read_Sectors(fat->disk, fd->CurrentCluster, 1, fd->Buffer))
                {
                    printf("FAT: read error!\r\n");
                    break;
                }
                for(;;);
                printf("Read sectors!\n");
            }
            else
            {
                printf("Handle wasn't root dir but %d\n", fd->Public.handle);
                for(;;);
                // calculate next cluster & sector to read
                if (++fd->CurrentSectorInCluster >= fat->disk->Bs.BootSector.SectorsPerCluster)
                {
                    fd->CurrentSectorInCluster = 0;
                    fd->CurrentCluster = FAT_NextCluster(fat, fd->CurrentCluster);
                }

                if (fd->CurrentCluster >= 0xFFFFFFF8)
                {
                    // Mark end of file
                    fd->Public.size = fd->Public.pos;
                    break;
                }

                // read next sector
                if (!Disk_Read_Sectors(fat->disk, Fat_ClusterToLba(fat, fd->CurrentCluster) + fd->CurrentSectorInCluster, 1, fd->Buffer))
                {
                    printf("FAT: read error!\r\n");
                    break;
                }
            }
        }
    }

    return u8DataOut - (uint8_t*)dataOut;
}
bool Fat_ReadEntry(Fat *fat, Fat_File *file, Fat_Entry *entry){
    return Fat_Read(fat, file, sizeof(Fat_Entry), entry) == sizeof(Fat_Entry);
}
void Fat_Close(Fat* fat, Fat_File *file){
    if (file->handle == ROOT_DIRECTORY_HANDLE){
        file->pos = 0;
        fat->RootDirectory.CurrentCluster = fat->RootDirectory.FirstCluster;
    }
    else{
        fat->handles[file->handle].Opened = false;
    }
}

Fat_File *Fat_Open(Fat *fat, const char* path){
    char name[MAX_PATH_SIZE];
    printf("Fat open stuff!\n");
    printf("Path = %s\n", path);
    // for(;;);

    // ignore leading slash
    if (path[0] == '/')
        path++;

    Fat_File* current = &fat->RootDirectory.Public;
    printf("Current handle: %d\n", current->handle);

    while (*path) {
        // extract next file name from path
        bool isLast = false;
        const char* delim = strchr(path, '/');
        if (delim != NULL){
            memcpy(name, path, delim - path);
            name[delim - path] = '\0';
            path = delim + 1;
        } else{
            unsigned len = strlen(path);
            memcpy(name, path, len);
            name[len + 1] = '\0';
            path += len;
            isLast = true;
        }
        printf("Is last = %s\n", isLast ? "true" : "false");

        // find directory entry in current directory
        Fat_Entry entry;
        if (Fat_FindFile(fat, current, name, &entry)){
            Fat_Close(fat, current);

            // check if directory
            if (!isLast && (entry.Attributes & FAT_ATTRIBUTE_DIRECTORY) == 0){
                printf("FAT: %s not a directory\r\n", name);
                return NULL;
            }

            // open new directory entry
            current = Fat_OpenEntry(fat, &entry);
        } else {
            Fat_Close(fat, current);

            printf("FAT: %s not found\r\n", name);
            return NULL;
        }
    }
    return current;
}