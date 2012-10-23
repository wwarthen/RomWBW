;__________________________________________________________________________________________________
;
;	BANK1
;__________________________________________________________________________________________________
;

; bnk1.asm 5/23/2012 dwg Beta 4 - Enhanced SYS_GETCFG and SYS_SETCFG


	.ORG	1000H
;
; INCLUDE GENERIC STUFF
;
#INCLUDE "std.asm"
;
;==================================================================================================
;   BANK 1 ENTRY / JUMP TABLE
;==================================================================================================
;
; THIS IS THE ENTRY DISPATCH POINT FOR BANK1
;__________________________________________________________________________________________________
;
	JP	INITSYS
	JP	BIOS_DISPATCH
;
;==================================================================================================
;   SYSTEM INITIALIZATION
;==================================================================================================
;
; AT THIS POINT, IT IS ASSUMED WE ARE OPERATING FROM RAM PAGE 1
;
INITSYS:
;
; INSTALL HBIOS PROXY IN UPPER MEMORY
;
	LD	HL,HB_IMG
	LD	DE,HB_LOC
	LD	BC,HB_SIZ
	LDIR
;
	LD	HL,$8000	; DEFAULT DISK XFR BUF ADDRESS
	LD	(DIOBUF),HL	; SAVE IT
;
#IF (PLATFORM != PLT_N8)
	IN	A,(RTC)		; RTC PORT, BIT 6 HAS STATE OF CONFIG JUMPER
;	LD	A,40H		; *DEBUG* SIMULATE JUMPER OPEN
;	LD	A,00H		; *DEBUG* SIMULATE JUMPER SHORTED
	AND	40H		; ISOLATE BIT 6
	JR	Z,INITSYS1	; IF BIT6=0, SHORTED, USE ALT CONSOLE
	LD	A,DEFCON	; LOAD DEF CONSOLE DEVICE CODE
	JR	INITSYS2	; CONTINUE
INITSYS1:
	LD	A,ALTCON	; LOAD ALT CONSOLE DEVICE CODE
INITSYS2:	
	LD	(CONDEV),A	; SET THE ACTIVE CONSOLE DEVICE
#ENDIF
;
; PERFORM DEVICE INITIALIZATION
;
#IF (UARTENABLE)
	CALL	UART_INIT
#ENDIF
#IF (VDUENABLE)
	CALL	VDU_INIT
#ENDIF
#IF (PRPENABLE)
	CALL	PRP_INIT
#ENDIF
#IF (PPPENABLE)
	CALL	PPP_INIT
#ENDIF
#IF (DSKYENABLE)
	CALL	DSKY_INIT
#ENDIF
#IF (FDENABLE)
	CALL	FD_INIT
#ENDIF
#IF (IDEENABLE)
	CALL	IDE_INIT
#ENDIF
#IF (PPIDEENABLE)
	CALL	PPIDE_INIT
#ENDIF
#IF (SDENABLE)
	CALL	SD_INIT
#ENDIF
#IF (HDSKENABLE)
	CALL	HDSK_INIT
#ENDIF
;
	RET
;
;==================================================================================================
;   IDLE
;==================================================================================================
;
;__________________________________________________________________________________________________
;
IDLE:
#IF (FDENABLE)
	CALL	FD_IDLE
#ENDIF
	RET
;
;==================================================================================================
;   BIOS FUNCTION DISPATCHER
;==================================================================================================
;
; MAIN BIOS FUNCTION
;   B: FUNCTION
;__________________________________________________________________________________________________
;
BIOS_DISPATCH:
	LD	A,B		; REQUESTED FUNCTION IS IN B
	CP	BF_CIO + $10
	JR	C,CIO_DISPATCH
	CP	BF_DIO + $10
	JR	C,DIO_DISPATCH
	CP	BF_CLK + $10
	JR	C,CLK_DISPATCH
	CP	BF_VDU + $10
	JR	C,CRT_DISPATCH
	
	CP	BF_SYS		; SKIP TO BF_SYS VALUE AT $F0
	CALL	C,PANIC		; PANIC IF LESS THAN BF_SYS
	JR	SYS_DISPATCH	; OTHERWISE SYS CALL
	CALL	PANIC		; THIS SHOULD NEVER BE REACHED
;
; SETUP AND CALL CHARACTER DRIVER
;   B: FUNCTION
;   C: DEVICE/UNIT
;   E: CHARACTER IN/OUT
;
CIO_DISPATCH:
	LD	A,C		; REQUESTED DEVICE/UNIT IS IN C
	AND	$F0		; ISOLATE THE DEVICE PORTION
#IF (UARTENABLE)
	CP	CIODEV_UART
	JP	Z,UART_DISPATCH
#ENDIF
#IF (PRPENABLE & PRPCONENABLE)
	CP	CIODEV_PRPCON
	JP	Z,PRPCON_DISPATCH
#ENDIF
#IF (PPPENABLE & PPPCONENABLE)
	CP	CIODEV_PPPCON
	JP	Z,PPPCON_DISPATCH
#ENDIF
#IF (VDUENABLE)
	CP	CIODEV_VDU
	JP	Z,VDU_DISPATCH
#ENDIF
	CALL	PANIC
;
;
;
DIO_DISPATCH:
	LD	A,B
	
	; DIO FUNCTIONS STARTING AT $18 ARE COMMON
	; AND DO NOT DISPATCH TO DRIVERS
	CP	$18
	JR	NC,DIO_COMMON

	; DISPATCH FUCNTION TO APPROPRIATE DRIVER
	AND	$0F	; 
	
	; HACK TO FILL IN HSTTRK AND HSTSEC
	; BUT ONLY FOR READ/WRITE FUNCTION CALLS
	; ULTIMATELY, HSTTRK AND HSTSEC ARE TO BE REMOVED
	CP	2
	JR	NC,DIO_DISPATCH1
	LD	(HSTTRK),HL
	LD	(HSTSEC),DE
DIO_DISPATCH1:
	LD	A,C		; REQUESTED DEVICE/UNIT IS IN C
	LD	(HSTDSK),A	; TEMP HACK TO FILL IN HSTDSK
	AND	$F0		; ISOLATE THE DEVICE PORTION
#IF (FDENABLE)
	CP	DIODEV_FD
	JP	Z,FD_DISPATCH
#ENDIF
#IF (IDEENABLE)
	CP	DIODEV_IDE
	JP	Z,IDE_DISPATCH
#ENDIF
#IF (PPIDEENABLE)
	CP	DIODEV_PPIDE
	JP	Z,PPIDE_DISPATCH
#ENDIF
#IF (SDENABLE)
	CP	DIODEV_SD
	JP	Z,SD_DISPATCH
#ENDIF
#IF (PRPENABLE & PRPSDENABLE)
	CP	DIODEV_PRPSD
	JP	Z,PRPSD_DISPATCH
#ENDIF
#IF (PPPENABLE & PPPSDENABLE)
	CP	DIODEV_PPPSD
	JP	Z,PPPSD_DISPATCH
#ENDIF
#IF (HDSKENABLE)
	CP	DIODEV_HDSK
	JP	Z,HDSK_DISPATCH
#ENDIF
	CALL	PANIC
;
; HANDLE COMMON DISK FUNCTIONS (NOT DEVICE DRIVER SPECIFIC)
;
DIO_COMMON:
	SUB	$18
	JR	Z,DIO_GBA
	DEC	A
	JR	Z,DIO_SBA
	CALL	PANIC
;
; DISK: GET BUFFER ADDRESS
;
DIO_GBA:
	LD	HL,(DIOBUF)
	XOR	A
	RET
;
; DISK: SET BUFFER ADDRESS
;
DIO_SBA:
	BIT	7,H		; IS HIGH ORDER BIT SET?
	CALL	Z,PANIC		; IF NOT, ADR IS IN LOWER 32K, NOT ALLOWED!!!
	LD	(DIOBUF),HL
	XOR	A
	RET
;
;
;
CLK_DISPATCH:
	CALL	PANIC
;
;
;
CRT_DISPATCH:
	CALL	PANIC
;
;
;
SYS_DISPATCH:
	LD	A,B
	CP	BF_SYSGETCFG
	JR	Z,SYS_GETCFG
	CP	BF_SYSSETCFG
	JR	Z,SYS_SETCFG
	CP	BF_SYSBNKCPY
	JR	Z,SYS_BNKCPY
	CALL	PANIC
;
SYS_GETCFG:
	LD	HL,$0200		; SETUP SOURCE OF CONFIG DATA
	LD	BC,$0100		; SIZE OF CONFIG DATA
	LDIR				; COPY IT
	RET
;
SYS_SETCFG:
	LD	HL,$0200		; SETUP SOURCE OF CONFIG DATA
	LD	BC,$0100
	EX	DE,HL
	LDIR
	RET
;
SYS_BNKCPY:
	LD	A,C			; BANK SELECTION TO A
	PUSH	IX
	POP	BC			; BC = BYTE COUNT TO COPY
	JP	$FF03			; JUST PASS CONTROL TO HBIOS STUB IN UPPER MEMORY
;
; COMMON ROUTINE THAT IS CALLED BY CHARACTER IO DRIVERS WHEN
; AN IDLE CONDITION IS DETECTED (WAIT FOR INPUT/OUTPUT)
;
CIO_IDLE:
	LD	HL,IDLECOUNT	; POINT TO IDLE COUNT
	DEC	(HL)		; 256 TIMES?
	CALL	Z,IDLE		; RUN IDLE PROCESS EVERY 256 ITERATIONS
	XOR	A		; SIGNAL NO CHAR READY
	RET			; AND RETURN
;
;==================================================================================================
;   DEVICE DRIVERS
;==================================================================================================
;
#IF (UARTENABLE)
ORG_UART	.EQU	$
  #INCLUDE "uart.asm"
SIZ_UART	.EQU	$ - ORG_UART
		.ECHO	"UART occupies "
		.ECHO	SIZ_UART
		.ECHO	" bytes.\n"
#ENDIF
;
#IF (VDUENABLE)
ORG_VDU		.EQU	$
  #INCLUDE "vdu.asm"
SIZ_VDU		.EQU	$ - ORG_VDU
		.ECHO	"VDU occupies "
		.ECHO	SIZ_VDU
		.ECHO	" bytes.\n"
#ENDIF
;
#IF (PRPENABLE)
ORG_PRP		.EQU	$
  #INCLUDE "prp.asm"
SIZ_PRP		.EQU	$ - ORG_PRP
		.ECHO	"PRP occupies "
		.ECHO	SIZ_PRP
		.ECHO	" bytes.\n"
#ENDIF
;
#IF (PPPENABLE)
ORG_PPP		.EQU	$
  #INCLUDE "ppp.asm"
SIZ_PPP		.EQU	$ - ORG_PPP
		.ECHO	"PPP occupies "
		.ECHO	SIZ_PPP
		.ECHO	" bytes.\n"
#ENDIF
;
#IF (FDENABLE)
ORG_FD		.EQU	$
  #INCLUDE "fd.asm"
SIZ_FD		.EQU	$ - ORG_FD
		.ECHO	"FD occupies "
		.ECHO	SIZ_FD
		.ECHO	" bytes.\n"
#ENDIF

#IF (IDEENABLE)
ORG_IDE		.EQU	$
  #INCLUDE "ide.asm"
SIZ_IDE		.EQU	$ - ORG_IDE
		.ECHO	"IDE occupies "
		.ECHO	SIZ_IDE
		.ECHO	" bytes.\n"
#ENDIF

#IF (PPIDEENABLE)
ORG_PPIDE	.EQU	$
  #INCLUDE "ppide.asm"
SIZ_PPIDE	.EQU	$ - ORG_PPIDE
		.ECHO	"PPIDE occupies "
		.ECHO	SIZ_PPIDE
		.ECHO	" bytes.\n"
#ENDIF

#IF (SDENABLE)
ORG_SD		.EQU	$
  #INCLUDE "sd.asm"
SIZ_SD		.EQU	$ - ORG_SD
		.ECHO	"SD occupies "
		.ECHO	SIZ_SD
		.ECHO	" bytes.\n"
#ENDIF

#IF (HDSKENABLE)
ORG_HDSK	.EQU	$
  #INCLUDE "hdsk.asm"
SIZ_HDSK	.EQU	$ - ORG_HDSK
		.ECHO	"HDSK occupies "
		.ECHO	SIZ_HDSK
		.ECHO	" bytes.\n"
#ENDIF
;
#DEFINE	CIOMODE_CONSOLE
#DEFINE	DSKY_KBD
#INCLUDE "util.asm"
;
;;;;#INCLUDE "memmgr.asm"
;
;==================================================================================================
;   BANK ONE GLOBAL DATA
;==================================================================================================
;
CONDEV		.DB	DEFCON
;
IDLECOUNT	.DB	0
;
HSTDSK		.DB	0		; DISK IN BUFFER
HSTTRK		.DW	0		; TRACK IN BUFFER
HSTSEC		.DW	0		; SECTOR IN BUFFER
;
DIOBUF		.DW	$FD00		; PTR TO 512 BYTE DISK XFR BUFFER
;
;==================================================================================================
;   FILL REMAINDER OF BANK
;==================================================================================================
;
SLACK:		.EQU	(7F00H - $)
		.FILL	SLACK,0FFH
;
		.ECHO	"BNK1 space remaining: "
		.ECHO	SLACK
		.ECHO	" bytes.\n"
;
;==================================================================================================
;   HBIOS UPPER MEMORY STUB
;==================================================================================================
;
; THE FOLLOWING CODE IS RELOCATED TO THE TOP PAGE IN MEMORY TO HANDLE INVOCATION DISPATCHING
;
HB_IMG	.EQU	$
	.ORG	HB_LOC
;
;==================================================================================================
;   HBIOS DISPATCH
;==================================================================================================
;
; DISPATCH JUMP TABLE FOR UPPER MEMORY HBIOS FUNCTIONS
;
	JP	HB_INIT
	JP	HB_BNKCPY
;
; MEMORY MANAGER
;
#INCLUDE "memmgr.asm"
;
;==================================================================================================
;   HBIOS BOOT ROUTINE
;==================================================================================================
;
; SETUP RST 08 TO HANDLE MAIN BIOS FUNCTIONS
;
HB_INIT:
	LD	A,0C3H		; $C3 = JP
	LD	(8H),A
	LD	HL,HB_ENTRY
	LD	(9H),HL
	RET
;
;==================================================================================================
;   HBIOS BNKCPY ROUTINE
;==================================================================================================
;
; SELECT A DESIGNATED RAM/ROM BANK INTO LOWER 32K, THEN PERFORM A BULK MEMORY COPY
;   A: BANK SELECTION (BIT 7: 1=RAM/0=ROM, BITS 0-6: BANK NUMBER)
;   DE: DESTINATION ADDRESS
;   HL: SOURCE ADDRESS
;   BC: COUNT OF BYTES TO COPY;
;
HB_BNKCPY:
	BIT	7,A		; CHECK BIT 7
	JR	NZ,HB_BNKCPY1	; RAM PAGE
;
	CALL	ROMPG		; SELECT ROM PAGE
	JR	HB_BNKCPY2	; GO TO COMMON STUFF
;
HB_BNKCPY1:
	RES	7,A		; CLEAR BIT 7
	CALL	RAMPG		; SELECT RAM PAGE AND FALL THRU
;
HB_BNKCPY2:
	LDIR			; DO THE COPY
	LD	A,1		; RESELECT RAM PAGE 1
	CALL	RAMPG		; DO IT
	RET			; BACK TO LOWER MEMORY
;
;==================================================================================================
;   HBIOS ENTRY FOR RST 08 PROCESSING
;==================================================================================================
;
; ENTRY POINT FOR BIOS FUNCTIONS (TARGET OF RST 08)
;
HB_ENTRY:
	LD	(STACKSAV),SP	; SAVE ORIGINAL STACK FRAME
	LD	SP,STACK	; SETUP NEW STACK FRAME

	PGRAMF(1)		; MAP RAM PAGE 1 INTO LOWER 32K
	
	CALL	1003H		; CALL BANK 1 HBIOS FUNCTION DISPATCHER

	PUSH	AF		; SAVE AF (FUNCTION RETURN)
	PGRAMF(0)		; MAP RAM PAGE 0 INTO LOWER 32K
	POP	AF		; RESTORE AF

	LD	SP,(STACKSAV)	; RESTORE ORIGINAL STACK FRAME

	RET			; RETURN TO CALLER
;
; PRIVATE DATA
;
STACKSAV	.DW	0
;
; JUST FOR FUN, PRIVATE STACK IS LOCATED AT TOP OF MEMORY...
;
STACK		.EQU	0
;
;
;
HB_SLACK	.EQU	(HB_END - $)
		.ECHO	"STACK space remaining: "
		.ECHO	HB_SLACK
		.ECHO	" bytes.\n"
;
		.FILL	HB_SLACK,0FFH
;
		.END