#include "stdio.h"
#include "disk.h"
#include <stdarg.h>
#include <stdint.h>

extern void __attribute__((cdecl)) cstart(uint16_t bootdrive){
    DISK disk;
    if(!disk_init(bootdrive, &disk)){
        printf("Could not initialize disk!\n");
        goto end;
    }
    printf("Everything worked\r\n");
end:
    for (;;);
}
