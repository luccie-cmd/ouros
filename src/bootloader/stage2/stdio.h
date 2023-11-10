#pragma once
#include <stdarg.h>

void clrscr();
void putcharPos(int x, int y, char c);
void setcrs(int x, int y);
void putc(char c);
void puts(const char* str);
void printf_unsigned(unsigned long long number, int radix);
void printf_signed(long long number, int radix);
void vprintf(const char* fmt, va_list args);
void printf(const char* fmt, ...);