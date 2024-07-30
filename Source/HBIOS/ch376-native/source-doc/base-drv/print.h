#ifndef __XPRINT
#define __XPRINT

#include <stdlib.h>

extern void print_hex(const char c) __z88dk_fastcall;
extern void print_string(const char *p) __z88dk_fastcall;
extern void print_uint16(const uint16_t n) __z88dk_fastcall;
extern void print_device_mounted(const char *const description, const uint8_t count);

#endif
