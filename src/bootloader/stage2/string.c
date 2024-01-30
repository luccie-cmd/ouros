#include "string.h"

const char* strchr(const char* str, char c){
    if(str == NULL){
        return NULL;
    }
    while(*str){
        if(*str == c){
            return str;
        }
        str++;
    }
    return NULL;
}

char* strcpy(const char* src, char* dst){
    if(dst == NULL){
        return NULL;
    }
    if(src == NULL){
        *dst = '\0';
        return dst;
    }
    while(*src){
        *dst = *src;
        ++dst;
        ++src;
    }
    *dst = '\0';
    return dst;
}
int strlen(const char* str){
    int n = 0;
    while(*str){
        n++;
        str++;
    }
    return n;
}

void *memcpy(void *destination, const void *source, size_t num){
    uint8_t *dstPtr = (uint8_t*)destination;
    uint8_t *srcPtr = (uint8_t*)source;
    for(size_t i = 0; i < num; ++i){
        dstPtr[i] = srcPtr[i];
    }
    return destination;
}

void * memset(void * ptr, int value, size_t num)
{
    uint8_t* u8Ptr = (uint8_t *)ptr;

    for (size_t i = 0; i < num; i++)
        u8Ptr[i] = (uint8_t)value;

    return ptr;
}

int memcmp(const void* ptr1, const void* ptr2, size_t num)
{
    const uint8_t* u8Ptr1 = (const uint8_t *)ptr1;
    const uint8_t* u8Ptr2 = (const uint8_t *)ptr2;

    for (size_t i = 0; i < num; i++)
        if (u8Ptr1[i] != u8Ptr2[i])
            return 1;

    return 0;
}