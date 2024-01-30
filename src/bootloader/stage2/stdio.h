#pragma once
#include <stdint.h>

void putchr(int x, int y, char c);
char getchr(int x, int y);
void setCursor(int x, int y);
void scrollback(int lines);
void putc(char c);
void puts(const char* str);
void clrscr();
void printf(const char* fmt, ...);