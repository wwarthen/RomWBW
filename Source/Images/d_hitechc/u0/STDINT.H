#ifndef _HTC_STDINT_H
#define _HTC_STDINT_H

#if z80||i8086||i8096||m68k
typedef unsigned char uint8_t;
typedef char int8_t;
typedef unsigned short uint16_t;
typedef short int16_t;
typedef unsigned long uint32_t;
typedef long int32_t;
typedef unsigned short intptr_t;
#endif

#endif
