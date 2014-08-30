;___ROM0_______________________________________________________________________________________________________________
;
; HARDWARE BOOTSTRAP
;
;   TEMPORARY HARDWARE BOOTSTRAP TO USE UNTIL JOHN COFFMAN'S
;   VERSION IS READY.
;______________________________________________________________________________________________________________________
;
;
#INCLUDE "std.asm"
;
	.ORG	$0000
;
	DI			; NO INTERRUPTS
	IM	1		; INTERRUPT MODE 1
	LD	SP,$HBX_LOC	; START WITH SP BELOW HBIOS PROXY LOCATION
;
#IF ((PLATFORM == PLT_N8) | (PLATFORM == PLT_MK4))
	; SET BASE FOR CPU IO REGISTERS
   	LD	A,CPU_BASE
	OUT0	(CPU_ICR),A
	
	; SET DEFAULT CPU CLOCK MULTIPLIERS (XTAL / 2)
	XOR	A
	OUT0	(CPU_CCR),A
	OUT0	(CPU_CMR),A
	
	; SET DEFAULT WAIT STATES
	LD	A,$F0
	OUT0	(CPU_DCNTL),A

#IF (Z180_CLKDIV >= 1)
	; SET CLOCK DIVIDE TO 1 RESULTING IN FULL XTAL SPEED
	LD	A,$80
	OUT0	(CPU_CCR),A
#ENDIF

#IF (Z180_CLKDIV >= 2)
	; SET CPU MULTIPLIER TO 1 RESULTINT IN XTAL * 2 SPEED
	LD	A,$80
	OUT0	(CPU_CMR),A
#ENDIF
	; SET DESIRED WAIT STATES
	LD	A,0 + (Z180_MEMWAIT << 6) | (Z180_IOWAIT << 4)
	OUT0	(CPU_DCNTL),A

	; MMU SETUP
	LD	A,$80
	OUT0	(CPU_CBAR),A		; SETUP FOR 32K/32K BANK CONFIG
	XOR	A
	OUT0	(CPU_BBR),A		; BANK BASE = 0
	LD	A,(RAMSIZE + RAMBIAS - 64) >> 2
	OUT0	(CPU_CBR),A		; COMMON BASE = LAST (TOP) BANK
#ENDIF
;
; EMIT FIRST SIGN OF LIFE TO SERIAL PORT
;
	CALL	XIO_INIT	; INIT SERIAL PORT
	LD	HL,STR_BOOT	; POINT TO MESSAGE
	CALL	XIO_OUTS	; SAY HELLO
;
; COPY OURSELF TO HIRAM
;
; NOTE: STACK IS WIPED OUT, STACK IS ASSUMED TO BE EMPTY HERE!!!!
;
	LD	HL,$0000	; COPY MEMORY FROM LOMEM (0000H)
	LD	DE,$8000	; TO HIMEM (8000H)
	LD	BC,COD_SIZ	; COPY CODE
	LDIR
;
	CALL	XIO_DOT		; MARK PROGRESS
;
	JP	PHASE2		; JUMP TO PHASE 2 IN UPPER MEMORY
;
STR_BOOT	.DB	PLATFORM_NAME, '$'
;
; IMBED DIRECT SERIAL I/O ROUTINES
;
#INCLUDE "xio.asm"
;
;______________________________________________________________________________________________________________________
;
; THIS IS THE PHASE 2 CODE THAT MUST EXECUTE IN UPPER MEMORY
;
	.ORG	$ + $8000	; WE ARE NOW EXECUTING IN UPPER MEMORY
;
PHASE2:
	CALL	XIO_DOT		; MARK PROGRESS
	CALL	XIO_CRLF	; FINISH LINE
	CALL	XIO_CRLF	; A BLANK LINE FOR SPACING
;
; SWAP LOMEM TO BANK 1 AND CHAIN TO $0000
;
;	LD	A,1		; SPECIFY PAGE 1
;	CALL	ROMPG		; PUT ROM PAGE 1 IN LOW RAM
	LD	A,BID_COMIMG	; CHAIN TO COMMON IMAGE IN ROM
	CALL	PGSEL		; SELECT THE PAGE
	JP	$0000		; CHAIN EXECUTION TO IT
;______________________________________________________________________________________________________________________
;
; NOTE THAT MEMORY MANAGER CODE IS IN UPPER MEMORY!
;
#INCLUDE "memmgr.asm"
;______________________________________________________________________________________________________________________
;
; PAD OUT REMAINDER OF PAGE
;
	.ORG	$ - $8000	; ORG BACK TO LOWER MEMORY
COD_SIZ	.EQU	$		; SIZE OF CODE
	.FILL	$8000 - $,$FF	; PAD OUT REMAINDER OF ROM SPACE
;
	.END
