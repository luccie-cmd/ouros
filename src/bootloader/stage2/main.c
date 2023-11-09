#include "util.h"
#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 25

uint16_t* ScreenBuffer = (uint16_t*)0xB8000;
int ScreenX = 0, ScreenY = 0;

void putcharPos(int x, int y, char c) {
    uint16_t color = 0x0F00;  // White text on black background
    ScreenBuffer[y * SCREEN_WIDTH + x] = color | c;
}

void setcrs(int x, int y){
    int pos = y * SCREEN_WIDTH + x;

    outportb(0x3D4, 0x0F);
    outportb(0x3D5, (uint8_t)(pos & 0xFF));
    outportb(0x3D4, 0x0E);
    outportb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

void putc(char c){
    putcharPos(ScreenX, ScreenY, c);
    ScreenX++;
    if(c == '\n' || ScreenX >= SCREEN_WIDTH){
        ScreenY++;
        ScreenX = 0;
    }
    setcrs(ScreenX, ScreenY);
}

void clrscr(){
    for (int y = 0; y < SCREEN_HEIGHT; y++)
        for (int x = 0; x < SCREEN_WIDTH; x++)
        {
            putcharPos(x, y, '\0');
        }

    ScreenX = 0;
    ScreenY = 0;
    setcrs(ScreenX, ScreenY);
}

extern void cstart() {
    clrscr();
    putc('H');
    for (;;) ;
}
