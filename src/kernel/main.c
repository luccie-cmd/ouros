#include <stdint.h>

void __attribute__((section(".entry"))) start(uint16_t bootDrive){
    (void)bootDrive;
    for(;;);
}