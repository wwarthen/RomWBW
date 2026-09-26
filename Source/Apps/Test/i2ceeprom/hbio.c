/* HBIO.C -- HBIOS RST 8 DIO helpers.
   Args are read straight off the IX frame (IX+6), (IX+8), ...
   Return values are left in HL/L */

#include <stdio.h>
#include "hbio.h"

#define BF_DIOSEEK	012H
#define BF_DIOREAD	013H
#define BF_DIOWRITE	014H
#define BF_DIODEVICE	017H
#define BF_DIOCAP	01AH
#define BF_SYSGETBNK	0F3H

/* returns the current HBIOS bank id */
getbank()
{
#asm
    LD	B,BF_SYSGETBNK
    RST	8
    LD	L,C
    LD	H,0
#endasm
}

/* device type for unit u into *dtype, I2C address into *addr.
   returns 0 ok, nonzero if the unit doesn't exist */
devinfo(u, dtype, addr)
unsigned char u;
unsigned char *dtype;
unsigned int *addr;
{
#asm
    LD	A,(IX+6)
    LD	C,A
    LD	B,BF_DIODEVICE
    RST	8
    LD	C,A			; STASH STATUS (B,C FREE AFTER RST 8)
    LD	B,D			; STASH DEVICE TYPE
    EX	DE,HL			; DE := I2C ADDRESS RESULT (D=0,E=ADDR)
    LD	L,(IX+8)		; DTYPE POINTER
    LD	H,(IX+9)
    LD	(HL),B			; *DTYPE = DEVICE TYPE
    LD	L,(IX+10)		; ADDR POINTER
    LD	H,(IX+11)
    LD	(HL),E			; *ADDR LOW = I2C ADDRESS
    INC	HL
    LD	(HL),D			; *ADDR HIGH = 0
    LD	A,C			; RESTORE STATUS FOR RETURN
    LD	L,A
    LD	H,0
#endasm
}

/* real per-unit block size in bytes, via BF_DIOCAP. driver returns
   DE:HL=block count, BC=block size. block count is stored into *cnt,
   block size is the return value */
blksize(u, cnt)
unsigned char u;
unsigned int *cnt;
{
#asm
    LD	A,(IX+6)
    LD	C,A
    LD	B,BF_DIOCAP
    RST	8
    PUSH	HL			; SAVE BLOCK COUNT
    LD	L,(IX+8)		; CNT POINTER
    LD	H,(IX+9)
    POP	DE			; DE = BLOCK COUNT
    LD	(HL),E
    INC	HL
    LD	(HL),D
    LD	H,B			; RETURN VALUE = BLOCK SIZE
    LD	L,C
#endasm
}

/* seek to block blk on unit u, LBA mode, returns status in A (0=ok) */
seekblock(u, blk)
unsigned char u;
unsigned int blk;
{
#asm
    LD	A,(IX+6)
    LD	C,A
    LD	D,080H		; LBA FLAG SET, HIGH BYTE 0
    LD	E,0
    LD	L,(IX+8)
    LD	H,(IX+9)
    LD	B,BF_DIOSEEK
    RST	8
    LD	L,A
    LD	H,0
#endasm
}

/* read one block (size given by BF_DIOCAP) from unit u into dst,
   using the given bank, returns status in A (0=ok) */
readblock(u, dst, bank)
unsigned char u;
unsigned char *dst;
unsigned char bank;
{
#asm
    LD	A,(IX+6)
    LD	C,A
    LD	E,1
    LD	L,(IX+8)
    LD	H,(IX+9)
    LD	A,(IX+10)
    LD	D,A
    LD	B,BF_DIOREAD
    RST	8
    LD	L,A
    LD	H,0
#endasm
}

/* write one block (size given by BF_DIOCAP) from src to unit u,
   using the given bank, returns status in A (0=ok) */
writeblock(u, src, bank)
unsigned char u;
unsigned char *src;
unsigned char bank;
{
#asm
    LD	A,(IX+6)
    LD	C,A
    LD	E,1
    LD	L,(IX+8)
    LD	H,(IX+9)
    LD	A,(IX+10)
    LD	D,A
    LD	B,BF_DIOWRITE
    RST	8
    LD	L,A
    LD	H,0
#endasm
}

/* Shared helpers for the I2CEEPROM test programs: command tail
   parsing, unit scan/list and a hex dump. Kept in this module rather
   than a third object: one more .obj overflows the 128-byte CP/M
   command line the linker gets. */

unsigned char *tail = (unsigned char *)0x80;
unsigned char tailidx, taillen;

inittail()
{
    taillen = tail[0];
    tailidx = 1;
}

nexttoken(buf, maxlen)
char *buf;
unsigned char maxlen;
{
    unsigned char n;

    while (tailidx <= taillen && tail[tailidx] == ' ')
	tailidx++;
    n = 0;
    while (tailidx <= taillen && tail[tailidx] != ' ' && n < maxlen - 1) {
	buf[n] = tail[tailidx];
	n++;
	tailidx++;
    }
    buf[n] = 0;
    return n;
}

parsenum(s)
char *s;
{
    unsigned int v;

    v = 0;
    while (*s >= '0' && *s <= '9') {
	v = v * 10 + (*s - '0');
	s++;
    }
    return v;
}

dumpbuf(label, buf, len)
char *label;
unsigned char *buf;
unsigned int len;
{
    unsigned char i;

    printf("%s:", label);
    for (i = 0; i < len; i++) {
	if ((i & 0x0F) == 0)
	    printf("\n%5u: ", i);
	printf("%02x", buf[i]);
	putchar(' ');
    }
    putchar('\n');
}

/* scan all DIO units for I2CEEPROM devices, filling units[] with their
   unit numbers. returns the count found (0 if none) */
scanunits(units)
unsigned char *units;
{
    unsigned char u, dtype, cnt;
    unsigned int addr;

    cnt = 0;
    for (u = 0; u < MAXUNITS; u++) {
	if (devinfo(u, &dtype, &addr) == 0 && dtype == DIODEV_I2CEEPROM) {
	    units[cnt] = u;
	    cnt++;
	}
    }
    return cnt;
}

/* print one line per active unit: number, I2C address, geometry */
listunits(units, cnt)
unsigned char *units;
unsigned char cnt;
{
    unsigned char i, u, dtype;
    unsigned int addr, blksz, blkcnt;

    for (i = 0; i < cnt; i++) {
	u = units[i];
	devinfo(u, &dtype, &addr);
	blksz = blksize(u, &blkcnt);
	printf("Unit %u: I2C ADDR=0x%02x BLKSIZ=%u BLKCNT=%u\n",
	    u, addr, blksz, blkcnt);
    }
}
