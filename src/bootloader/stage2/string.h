#pragma once
#include <stddef.h>
#include <stdint.h>

const char* strchr(const char* src, char c);
char* strcpy(const char* src, char* dst);
int strlen(const char* str);
void *memcpy(void *destination, const void *source, size_t num);
int memcmp(const void *ptr1, const void *ptr2, size_t num);
void * memset(void * ptr, int value, size_t num);