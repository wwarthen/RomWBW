/* BFI2C.C, BF_I2C ($60) RST 8 wrappers. See Source/HBIOS/hbios.inc. */

#define BF_I2CDEVICE	060H
#define BF_I2CSTART	061H
#define BF_I2CREPSTART	062H
#define BF_I2CWRITE	063H
#define BF_I2CREAD	064H
#define BF_I2CXFER	065H
#define BF_I2CBUSBUSY	066H
#define BF_I2CSTOP	067H

#define BF_SYSGETBNK	0F3H

/* current HBIOS bank id, for bf_i2cxfer()'s bank argument. */
getbank()
{
#asm
    LD	B,BF_SYSGETBNK
    RST	8
    LD	L,C
    LD	H,0
#endasm
}

/* Backend into *backend (1=PCF8584, 2=bitbang), HL=base port discarded.
   returns status (0=present, nonzero if no I2C backend is configured) */
bf_i2cdevice(backend)
unsigned char *backend;
{
#asm
    PUSH	IX
    LD	C,0			; UNIT 0, ONE LOGICAL BUS
    LD	B,BF_I2CDEVICE
    RST	8
    LD	C,A			; STASH STATUS (A CLOBBERED BELOW)
    LD	A,B			; BACKEND ID
    LD	L,(IX+6)		; BACKEND POINTER
    LD	H,(IX+7)
    LD	(HL),A
    LD	A,C			; RESTORE STATUS FOR RETURN
    LD	L,A
    LD	H,0
    POP	IX
#endasm
}

/* Issue START + address byte. addr = 7 bit address, R/W already
   merged into bit 0. Returns status, 0 = OK, nonzero = error. */
bf_i2cstart(addr)
unsigned char addr;
{
#asm
    PUSH	IX
    LD	A,(IX+6)
    LD	E,A			; ADDRESS BYTE, BF_I2CSTART TAKES IT IN E
    LD	C,0			; UNIT 0, ONE LOGICAL BUS
    LD	B,BF_I2CSTART
    RST	8
    LD	L,A
    LD	H,0
    POP	IX
#endasm
}

/* Issue REPEATED START + address byte, addr = 7 bit address, R/W already
   merged into bit 0. Returns status, 0 = OK, nonzero = error. */
bf_i2crepstart(addr)
unsigned char addr;
{
#asm
    PUSH	IX
    LD	A,(IX+6)
    LD	E,A			; ADDRESS BYTE, BF_I2CREPSTART TAKES IT IN E
    LD	C,0			; UNIT 0, ONE LOGICAL BUS
    LD	B,BF_I2CREPSTART
    RST	8
    LD	L,A
    LD	H,0
    POP	IX
#endasm
}

/* Write one data byte. Returns status, 0 = OK, nonzero = error. */
bf_i2cwrite(b)
unsigned char b;
{
#asm
    PUSH	IX
    LD	A,(IX+6)
    LD	E,A			; DATA BYTE, BF_I2CWRITE TAKES IT IN E
    LD	C,0			; UNIT 0, ONE LOGICAL BUS
    LD	B,BF_I2CWRITE
    RST	8
    LD	L,A
    LD	H,0
    POP	IX
#endasm
}

/* Read one data byte into *data. last=1 sends NACK (this is the final
   byte of the read), else 0. Returns status, 0 = OK, nonzero = error */
bf_i2cread(last, data)
unsigned char last;
unsigned char *data;
{
#asm
    PUSH	IX
    LD	A,(IX+6)		; LAST-BYTE FLAG
    LD	E,A
    LD	C,0			; UNIT 0, ONE LOGICAL BUS
    LD	B,BF_I2CREAD
    RST	8
    LD	C,A			; STASH STATUS
    LD	A,L			; DATA BYTE
    LD	L,(IX+8)		; DATA POINTER
    LD	H,(IX+9)
    LD	(HL),A
    LD	A,C			; RESTORE STATUS FOR RETURN
    LD	L,A
    LD	H,0
    POP	IX
#endasm
}

/* Transfer count bytes from buf, write-only. count=0 means 256;
   *written=0 alone is ambiguous, check status. */
bf_i2cxfer(buf, count, bank, written)
unsigned char *buf;
unsigned char count;
unsigned char bank;
unsigned char *written;
{
#asm
    PUSH	IX
    LD	L,(IX+6)		; BUFFER POINTER
    LD	H,(IX+7)
    LD	A,(IX+8)		; BYTE COUNT
    LD	E,A
    LD	A,(IX+10)		; BUFFER BANK
    LD	D,A
    LD	C,0			; UNIT 0, ONE LOGICAL BUS
    LD	B,BF_I2CXFER
    RST	8
    PUSH	AF
    LD	C,(IX+12)		; WRITTEN POINTER, LOW BYTE
    LD	B,(IX+13)		; WRITTEN POINTER, HIGH BYTE
    LD	A,B
    OR	C
    JR	Z,BFI2CXFER_NOCOUNT	; NULL, CALLER DOESN'T WANT THE COUNT
    LD	A,E			; BYTES ACTUALLY SENT
    LD	(BC),A
BFI2CXFER_NOCOUNT:
    POP	AF
    LD	L,A
    LD	H,0
    POP	IX
#endasm
}

/* Non-blocking bus-busy check, does not wait. Returns status, 0 = free,
   nonzero = busy. */
bf_i2cbusbusy()
{
#asm
    LD	C,0			; UNIT 0, ONE LOGICAL BUS
    LD	B,BF_I2CBUSBUSY
    RST	8
    LD	L,A
    LD	H,0
#endasm
}

/* issue STOP. dbl=1 for a double stop (some devices need two STOPs in
   succession to fully clear their internal state), 0 for a single
   stop. returns status (always 0) */
bf_i2cstop(dbl)
unsigned char dbl;
{
#asm
    PUSH	IX
    LD	A,(IX+6)
    LD	E,A			; DOUBLE-STOP FLAG, BF_I2CSTOP TAKES IT IN E
    LD	C,0			; UNIT 0, ONE LOGICAL BUS
    LD	B,BF_I2CSTOP
    RST	8
    LD	L,A
    LD	H,0
    POP	IX
#endasm
}
