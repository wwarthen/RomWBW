#ifndef __MYTYPES_H
#define __MYTYPES_H 1

typedef unsigned char  byte;
typedef unsigned short word;
typedef unsigned long dword;


#ifdef __SDCC__
#define outp(port,byte)  port  =  (byte)
#define inp(port)	(port)
#endif

#define nelem(x) (sizeof(x)/sizeof(x[0]))

#endif  /* __MYTYPES_H */
