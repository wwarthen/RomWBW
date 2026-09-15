;==================================================================================================
; BFI2C.INC, BF_I2C ($60) RST 8 WRAPPERS, ASM EQUIVALENT OF
; Source/Apps/Test/HTechI2C/bfi2c.c.
;
; STATUS CODES (BF_I2CSTART/REPSTART/WRITE/READ):
; 0=OK
; 1=NAK
; 3=BUS BUSY
; 0FFH=TIMEOUT
; ERR_NOHW (0F8H)=BUS-MASTER FAILED ITS OWN INIT SELF-CHECK
;
; BF_I2CBUSBUSY REUSES CODE 3 (BUSY) / 0 (FREE). NON-BLOCKING, NEVER WAITS.
;==================================================================================================
;
ERR_NOHW	.EQU	0F8H		; MIRRORS hbios.inc's ERR_NOHW (-8)
;
BF_I2C		.EQU	060H
BF_I2CDEVICE	.EQU	BF_I2C+0
BF_I2CSTART	.EQU	BF_I2C+1
BF_I2CREPSTART	.EQU	BF_I2C+2
BF_I2CWRITE	.EQU	BF_I2C+3
BF_I2CREAD	.EQU	BF_I2C+4
BF_I2CXFER	.EQU	BF_I2C+5
BF_I2CBUSBUSY	.EQU	BF_I2C+6
BF_I2CSTOP	.EQU	BF_I2C+7
;
BF_SYSGETBNK	.EQU	0F3H		; GET CURRENT BANK (BF_SYS+3)
;
;-----------------------------------------------------------------------------
; REPORT I2C BUS-MASTER PRESENCE/IDENTITY.
;   EXIT: A=STATUS (0=PRESENT), B=BACKEND (1=PCF8584, 2=BITBANG), HL=BASE PORT
;
BF_I2CDEV:
	LD	C,0
	LD	B,BF_I2CDEVICE
	RST	08
	RET
;
;-----------------------------------------------------------------------------
; ISSUE START CONDITION + ADDRESS BYTE.
;   ENTRY: A=7-BIT ADDRESS, R/W ALREADY MERGED INTO BIT 0
;   EXIT: A=STATUS
;
BF_START:
	LD	E,A
	LD	C,0
	LD	B,BF_I2CSTART
	RST	08
	RET
;
;-----------------------------------------------------------------------------
; ISSUE REPEATED START + ADDRESS BYTE, SAME ARGS/RETURN AS BF_START.
;
BF_REPSTART:
	LD	E,A
	LD	C,0
	LD	B,BF_I2CREPSTART
	RST	08
	RET
;
;-----------------------------------------------------------------------------
; WRITE ONE DATA BYTE.
;   ENTRY: A=DATA BYTE
;   EXIT: A=STATUS
;
BF_WRITE:
	LD	E,A
	LD	C,0
	LD	B,BF_I2CWRITE
	RST	08
	RET
;
;-----------------------------------------------------------------------------
; READ ONE DATA BYTE.
;   ENTRY: A=1 IF THIS IS THE LAST BYTE OF THE READ (SEND NACK), ELSE 0
;   EXIT: A=STATUS, L=DATA BYTE
;
BF_READ:
	LD	E,A
	LD	C,0
	LD	B,BF_I2CREAD
	RST	08
	RET
;
;-----------------------------------------------------------------------------
; TRANSFER COUNT BYTES FROM A BUFFER, WRITE-ONLY. ASSUMES BF_START WAS
; ALREADY CALLED SEPARATELY. ONE RST 08 CALL FOR THE WHOLE BUFFER, NOT ONE
; PER BYTE, SAME BULK PATH bfi2c.c'S bf_i2cxfer() USES.
;   ENTRY: HL=BUFFER, B=BYTE COUNT (0-255, 0 MEANS 256)
;   EXIT: A=STATUS
;
BF_XFER:
	PUSH	BC
	PUSH	HL
	CALL	BF_GETBANK
	LD	D,A
	POP	HL
	POP	BC
	LD	E,B
	LD	C,0
	LD	B,BF_I2CXFER
	RST	08
	RET
;
;-----------------------------------------------------------------------------
; NON-BLOCKING BUS-BUSY CHECK. DOES NOT WAIT.
;   EXIT: A=STATUS (0=FREE, 3=BUSY)
;
BF_BUSBUSY:
	LD	C,0
	LD	B,BF_I2CBUSBUSY
	RST	08
	RET
;
;-----------------------------------------------------------------------------
; ISSUE STOP CONDITION (SINGLE STOP, E RESERVED, NOT YET HONORED, SEE
; bfi2c.c'S OWN COMMENT).
;   EXIT: A=STATUS (ALWAYS 0)
;
BF_STOP:
	LD	C,0
	LD	B,BF_I2CSTOP
	LD	E,0
	RST	08
	RET
;
;-----------------------------------------------------------------------------
; CURRENT HBIOS BANK ID, FOR BF_XFER'S OWN USE ABOVE.
;   EXIT: A=BANK
;
BF_GETBANK:
	LD	B,BF_SYSGETBNK
	RST	08
	LD	A,C
	RET
