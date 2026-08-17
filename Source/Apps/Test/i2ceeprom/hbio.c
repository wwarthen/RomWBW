/* HBIO.C -- HBIOS RST 8 DIO helpers.
   Args are read straight off the IX frame (IX+6), (IX+8), ...
   Return values are left in HL/L */

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
