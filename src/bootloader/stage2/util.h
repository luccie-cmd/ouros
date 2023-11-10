#pragma once
#define CDECL __attribute__((cdecl))
#define SCREEN_WIDTH 80
#define SCREEN_HEIGHT 25
#include <stdint.h>

static inline uint16_t inports(uint16_t port) {
    uint16_t r;
    __asm__ __volatile__ ("inw %1, %0" : "=a" (r) : "dN" (port));
    return r;
}

static inline void outports(uint16_t port, uint16_t data) {
    __asm__ __volatile__ ("outw %0, %1" : : "a" (data), "dN" (port));
}

static inline uint8_t inportb(uint16_t port) {
    uint8_t r;
    __asm__ __volatile__ ("inb %1, %0" : "=a" (r) : "dN" (port));
    return r;
}

static inline void outportb(uint16_t port, uint8_t data) {
    __asm__ __volatile__ ("outb %0, %1" : : "a" (data), "dN" (port));
}

#ifndef SCREEN_STUFF
#define SCREEN_STUFF

uint16_t* ScreenBuffer = (uint16_t*)0xB8000;
int ScreenX = 0, ScreenY = 0;

#endif