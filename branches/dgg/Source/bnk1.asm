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
; PERFORM INTERRUPT INITIALISATION
;
#IF (INTMODE = 2)
	LD	A,0FFH		; INTERRUPT VECTOR TABLE PAGE
	LD	I,A		; INTERRUPT VECTOR REGISTER
	IM	2		; MODE 2 INTERRUPTS
#IF (PLATFORM = PLT_N8)
	XOR	A		; PUT Z180 VECTORS ON PAGE BOUNDARY
	OUT	(CPU_IL),A
#ENDIF
#IF ((PLATFORM = PLT_N8VEM) & (ZPBASE !=0))
				; INIT VECTORS ON ZILOG PERIPHERALS BOARD
				; INIT Z80-CTC
	XOR	A		; VECTOR AT FF00H
	OUT	(ZPBASE+0),A	; ALL CHANNELS

				; INIT Z80-PIO1
	LD	A,08H		; VECTOR AT FF08H
	OUT	(ZPBASE+0AH),A	; PORT A
	LD	A,0AH		; VECTOR AT FF0AH
	OUT	(ZPBASE+0BH),A	; PORT B

				; INIT Z80-PIO2
	LD	A,0CH		; VECTOR AT FF0CH
	OUT	(ZPBASE+0EH),A	; PORT A
	LD	A,0EH		; VECTOR AT FF0EH
	OUT	(ZPBASE+0FH),A	; PORT B

				; INIT Z80-DART/SIO
	LD	A,02		; POINT TO REGISTER 2
	OUT	(ZPBASE+7),A	; CHANNEL B COMMAND
	LD	A,10H		; VECTOR AT FF10H
	OUT	(ZPBASE+7),A	; ONE VECTOR FOR WHOLE CHIP
#ENDIF
#IF ((PLATFORM = PLT_N8VEM) & (PIO4BASE !=0))
				; INIT VECTORS ON A 4PIO BOARD
	XOR	A		; VECTOR AT FF00H
	OUT	(PIO4BASE+1)	; PIO0 PORT A
	LD	A,02		; VECTOR AT FF02H
	OUT	(PIO4BASE+3)	; PIO0 PORT B
	LD	A,04		; VECTOR AT FF04H
	OUT	(PIO4BASE+5)	; PIO1 PORT A
	LD	A,06		; VECTOR AT FF02H
	OUT	(PIO4BASE+7)	; PIO1 PORT B
	LD	A,08		; VECTOR AT FF02H
	OUT	(PIO4BASE+9)	; PIO2 PORT A
	LD	A,0AH		; VECTOR AT FF02H
	OUT	(PIO4BASE+B)	; PIO2 PORT B
	LD	A,0CH		; VECTOR AT FF02H
	OUT	(PIO4BASE+D)	; PIO3 PORT A
	LD	A,0EH		; VECTOR AT FF02H
	OUT	(PIO4BASE+F)	; PIO3 PORT B
#ENDIF
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
	LD	DE,STR_BANNER
	CALL	WRITESTR
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
	AND	$0F
	
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
	BIT	7,H			; IS HIGH ORDER BIT SET?
	CALL	Z,PANIC			; IF NOT, ADR IS IN LOWER 32K, NOT ALLOWED!!!
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
	JP	HB_BNKCPY		; JUST PASS CONTROL TO HBIOS STUB IN UPPER MEMORY
;
; COMMON ROUTINE THAT IS CALLED BY CHARACTER IO DRIVERS WHEN
; AN IDLE CONDITION IS DETECTED (WAIT FOR INPUT/OUTPUT)
;
CIO_IDLE:
	LD	HL,IDLECOUNT		; POINT TO IDLE COUNT
	DEC	(HL)			; 256 TIMES?
	CALL	Z,IDLE			; RUN IDLE PROCESS EVERY 256 ITERATIONS
	XOR	A			; SIGNAL NO CHAR READY
	RET				; AND RETURN
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
STR_BANNER	.DB	"N8VEM HBIOS v", BIOSVER, " ("
VAR_LOC		.DB	VARIANT, "-"
TST_LOC		.DB	TIMESTAMP, ")\r\n"
		.DB	PLATFORM_NAME, DSKYLBL, VDULBL, FDLBL, IDELBL, PPIDELBL, 
		.DB	SDLBL, PRPLBL, PPPLBL, HDSKLBL, "\r\n$"
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
;   HBIOS INTERRUPT VECTOR TABLE
;==================================================================================================
;
; AREA RESERVED FOR UP TO 16 INTERRUPT VECTOR ENTRIES (MODE 2)
;
; DEFAULT VECTORS ALL POINT TO DUMMY INTERRUPT SERVICE ROUTINE
HB_IVT:				; *** = NOT USED
				; VECTOR ADDR	N8	4PIO	ZILOG PERIPHERAL
	.DW	DUMISR		; FF00		/INT1	PIO0 A	CTC CHANNEL 0
	.DW	DUMISR		; FF02		/INT2	PIO0 B	CTC CHANNEL 1
	.DW	DUMISR		; FF04		PRT0	PIO1 A	CTC CHANNEL 2
	.DW	DUMISR		; FF06		PRT1	PIO1 B	CTC CHANNEL 3
	.DW	DUMISR		; FF08		DMA0	PIO2 A	PIO1 A
	.DW	DUMISR		; FF0A		DMA1	PIO2 B	PIO1 B
	.DW	DUMISR		; FF0C		CSI/O	PIO3 A	PIO2 A
	.DW	DUMISR		; FF0E		ASCI0	PIO3 B	PIO2 B
	.DW	DUMISR		; FF10		ASCI1	***	DART - ANY OR CH.B TX EMPTY
	.DW	DUMISR		; FF12		***	***	DART CH.B EXTERNAL STATUS CHANGE
	.DW	DUMISR		; FF14		***	***	DART CH.B RX CHAR AVAILABLE
	.DW	DUMISR		; FF16		***	***	DART CH.B SPECIAL RECEIVE CONDITION
	.DW	DUMISR		; FF18		***	***	DART CH.A TX EMPTY
	.DW	DUMISR		; FF1A		***	***	DART CH.A EXTERNAL STATUS CHANGE
	.DW	DUMISR		; FF1C		***	***	DART CH.A RX CHAR AVAILABLE
	.DW	DUMISR		; FF1E		***	***	DART CH.A SPECIAL RECEIVE CONDITION
;	.FILL	20H,0FFH
;
;==================================================================================================
;   HBIOS INITIALIZATION
;==================================================================================================
;
; SETUP RST 08 VECTOR TO HANDLE MAIN BIOS FUNCTIONS
;
HB_INIT:
	LD	A,0C3H		; $C3 = JP
	LD	(8H),A
	LD	HL,HB_ENTRY
	LD	(9H),HL
	RET
;
; MEMORY MANAGER
;
#INCLUDE "memmgr.asm"
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
	PGRAMF(1)		; MAP RAM PAGE 1 INTO LOWER 32K
	
	LD	(HB_STKSAV),SP	; SAVE ORIGINAL STACK FRAME
	LD	SP,HB_STACK	; SETUP NEW STACK FRAME

	CALL	BIOS_DISPATCH	; CALL HBIOS FUNCTION DISPATCHER

	PUSH	AF		; SAVE AF
	PGRAMF(0)		; MAP RAM PAGE 0 INTO LOWER 32K
	POP	AF		; RESTORE AF

	LD	SP,(HB_STKSAV)	; RESTORE ORIGINAL STACK FRAME

	RET			; RETURN TO CALLER
;
HB_STKSAV	.DW	0	; PREVIOUS STACK POINTER (SEE PROXY)
;
;==================================================================================================
;   DUMMY INTERRUPT SERVICE ROUTINE
;==================================================================================================
;
HB_DUMISR:
DUMISR	.EQU	$
	EI			; RE-ENABLE INTERRUPTS
	RETI			; RETURN FROM INTERRUPT
;
HB_SLACK	.EQU	(HB_END - $)
		.ECHO	"HBIOS space remaining: "
		.ECHO	HB_SLACK
		.ECHO	" bytes.\n"
;
		.FILL	HB_SLACK,0FFH
;
;==================================================================================================
;   HBIOS STACK LIVES IN THE SLACK SPACE!!!
;==================================================================================================
;
HB_STACK	.EQU	$ & 0FFFFH
;
		.END
