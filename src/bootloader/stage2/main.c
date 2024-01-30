#include <stdint.h>
#include "stdio.h"
#include "x86.h"
#include "fat.h"
#include "memdefs.h"
#include "string.h"

Fat *fat; // Store it globally since that i had errors when it was located on the stack

void ASMCALL cstart(uint16_t bootdrive){
    clrscr();
    printf("Boot device: %p\n", bootdrive);
    fat = (Fat*)MEMORY_FAT_ADDR;
    // if(bootdrive < 0x80){
    //     printf("Cannot boot from a floppy disk!!!\n");
    //     goto end;
    // }
    printf("Cstart called!\n");
    if(!Fat_Init(fat, bootdrive)){
        printf("Couldn't initialize FAT!\n");
        goto end;
    }
    printf("Fat initialized!\n");
    
    Fat_File *file = Fat_Open(fat, "test.txt");
    goto end;
    // printf("Fat open returned file handle %d\n", file->handle);
    // (void)file;
    Fat_Close(fat, file);
end:
    for(;;);
}