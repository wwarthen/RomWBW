;
;==================================================================================================
;   HBIOS
;==================================================================================================
;

; bnk1.asm 11/16/2012 dwg - specify hl=0 before calling N8V_INIT 
; 	This causes the TMS9918 character bitmaps to be loaded from the 
; 	default bitmaps included in bnk1.asm
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
; ANNOUNCE HBIOS
;
	CALL	NEWLINE
	CALL	NEWLINE
	PRTX(STR_PLATFORM)
	PRTS(" @ $")
	LD	HL,CPUFREQ
	CALL	PRTDEC
	PRTS("MHz ROM=$")
	LD	HL,ROMSIZE
	CALL	PRTDEC
	PRTS("KB RAM=$")
	LD	HL,RAMSIZE
	CALL	PRTDEC
	PRTS("KB$")
;
; INSTALL HBIOS PROXY IN UPPER MEMORY
;
	LD	HL,HB_IMG	; HL := SOURCE OF HBIOS PROXY IMAGE
	LD	DE,HB_LOC	; DE := DESTINATION TO INSTALL IT
	LD	BC,HB_SIZ	; SIZE
	LDIR			; DO THE COPY
;
; DURING INITIALIZATION, CONSOLE IS UART!
; POST-INITIALIZATION, WILL BE SWITCHED TO USER CONFIGURED CONSOLE
;
	LD	A,CIODEV_UART
	LD	(CONDEV),A
;
; PERFORM DEVICE INITIALIZATION
;
	LD	B,HB_INITTBLLEN
	LD	DE,HB_INITTBL
INITSYS2:
	CALL	NEWLINE
	LD	A,(DE)
	LD	L,A
	INC	DE
	LD	A,(DE)
	LD	H,A
	INC	DE
	PUSH	DE
	PUSH	BC
	CALL	JPHL
	OR	A
	JR	Z,INITSYS3
	PUSH	AF
	CALL	PC_SPACE
	POP	AF
	CALL	PC_LBKT
	CALL	PRTHEXBYTE
	CALL	PC_RBKT
	JR	INITSYS4
INITSYS3:
	PRTS(" [OK]$")
INITSYS4:
	POP	BC
	POP	DE
	DJNZ	INITSYS2
;
; SET UP THE DEFAULT DISK BUFFER ADDRESS
;
	LD	HL,$8000	; DEFAULT DISK XFR BUF ADDRESS
	LD	(DIOBUF),HL	; SAVE IT
;
; NOW SWITCH TO USER CONFIGURED CONSOLE
;
#IF (PLATFORM == PLT_N8)
	LD	A,DEFCON
#ELSE
	IN	A,(RTC)		; RTC PORT, BIT 6 HAS STATE OF CONFIG JUMPER
	BIT	6,A		; BIT 6 HAS CONFIG JUMPER STATE
	LD	A,DEFCON	; ASSUME WE WANT DEFAULT CONSOLE
	JR	NZ,INITSYS1	; IF NZ, JUMPER OPEN, DEF CON IS CORRECT
	LD	A,ALTCON	; JUMPER SHORTED, USE ALTERNATE CONSOLE
INITSYS1:
#ENDIF
	LD	(CONDEV),A	; SET THE ACTIVE CONSOLE DEVICE
;
; DISPLAY THE POST-INITIALIZATION BANNER
;
	CALL	NEWLINE
	CALL	NEWLINE
	PRTX(STR_BANNER)
	CALL	NEWLINE
;
	RET
;
;==================================================================================================
;   TABLE OF INITIALIZATION ENTRY POINTS
;==================================================================================================
;
HB_INITTBL:
#IF (UARTENABLE)
	.DW	UART_INIT
#ENDIF
#IF (VDUENABLE)
	.DW	VDU_INIT
#ENDIF
#IF (CVDUENABLE)
	.DW	CVDU_INIT
#ENDIF
#IF (UPD7220ENABLE)
	.DW	UPD7220_INIT
#ENDIF
#IF (N8VENABLE)
	.DW	N8V_INIT
#ENDIF
#IF (PRPENABLE)
	.DW	PRP_INIT
#ENDIF
#IF (PPPENABLE)
	.DW	PPP_INIT
#ENDIF
#IF (DSKYENABLE)
	.DW	DSKY_INIT
#ENDIF
#IF (FDENABLE)
	.DW	FD_INIT
#ENDIF
#IF (IDEENABLE)
	.DW	IDE_INIT
#ENDIF
#IF (PPIDEENABLE)
	.DW	PPIDE_INIT
#ENDIF
#IF (SDENABLE)
	.DW	SD_INIT
#ENDIF
#IF (HDSKENABLE)
	.DW	HDSK_INIT
#ENDIF
#IF (PPKENABLE)
	.DW	PPK_INIT
#ENDIF
#IF (KBDENABLE)
	.DW	KBD_INIT
#ENDIF
#IF (TTYENABLE)
	.DW	TTY_INIT
#ENDIF
#IF (ANSIENABLE)
	.DW	ANSI_INIT
#ENDIF
;
HB_INITTBLLEN	.EQU	(($ - HB_INITTBL) / 2)
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
	CP	BF_CIO + $10	; $00-$0F: CHARACTER I/O
	JR	C,CIO_DISPATCH
	CP	BF_DIO + $10	; $10-$1F: DISK I/O
	JR	C,DIO_DISPATCH
	CP	BF_RTC + $10	; $20-$2F: REAL TIME CLOCK (RTC)
	JR	C,RTC_DISPATCH
	CP	BF_EMU + $10	; $30-$3F: EMULATION
	JP	C,EMU_DISPATCH
	CP	BF_VDA + $10	; $40-$4F: VIDEO DISPLAY ADAPTER
	JP	C,VDA_DISPATCH
	
	CP	BF_SYS		; SKIP TO BF_SYS VALUE AT $F0
	CALL	C,PANIC		; PANIC IF LESS THAN BF_SYS
	JP	SYS_DISPATCH	; OTHERWISE SYS CALL
	CALL	PANIC		; THIS SHOULD NEVER BE REACHED
;
;==================================================================================================
;   CHARACTER I/O DEVICE DISPATCHER
;==================================================================================================
;
; ROUTE CALL TO SPECIFIED CHARACTER I/O DRIVER
;   B: FUNCTION
;   C: DEVICE/UNIT
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
	JP	Z,VDU_DISPCIO
#ENDIF
#IF (CVDUENABLE)
	CP	CIODEV_CVDU
	JP	Z,CVDU_DISPCIO
#ENDIF
#IF (UPD7220ENABLE)
	CP	CIODEV_UPD7220
	JP	Z,UPD7220_DISPCIO
#ENDIF
#IF (N8VENABLE)
	CP	CIODEV_N8V
	JP	Z,N8V_DISPCIO
#ENDIF
	CP	CIODEV_CRT
	JR	Z,CIOEMU
	CALL	PANIC
;
CIOEMU:
	LD	A,B
	ADD	A,BF_EMU - BF_CIO	; TRANSLATE FUNCTION CIOXXX -> EMUXXX
	LD	B,A
	JP	EMU_DISPATCH
;
;==================================================================================================
;   DISK I/O DEVICE DISPATCHER
;==================================================================================================
;
; ROUTE CALL TO SPECIFIED DISK I/O DRIVER
;   B: FUNCTION
;   C: DEVICE/UNIT
;
DIO_DISPATCH:
	; GET THE REQUESTED FUNCTION TO SEE IF SPECIAL HANDLING
	; IS NEEDED
	LD	A,B
;
	; DIO FUNCTIONS STARTING AT DIOGETBUF ARE COMMON FUNCTIONS
	; AND DO NOT DISPATCH TO DRIVERS (HANDLED GLOBALLY)
	CP	BF_DIOGETBUF	; TEST FOR FIRST OF THE COMMON FUNCTIONS
	JR	NC,DIO_COMMON	; IF >= DIOGETBUF HANDLE AS COMMON DIO FUNCTION
;
	; HACK TO FILL IN HSTTRK AND HSTSEC
	; BUT ONLY FOR READ/WRITE FUNCTION CALLS
	; ULTIMATELY, HSTTRK AND HSTSEC ARE TO BE REMOVED
	CP	BF_DIOST		; BEYOND READ/WRITE FUNCTIONS ?
	JR	NC,DIO_DISPATCH1	; YES, BYPASS
	LD	(HSTTRK),HL		; RECORD TRACK
	LD	(HSTSEC),DE		; RECORD SECTOR
;
DIO_DISPATCH1:
	; START OF THE ACTUAL DRIVER DISPATCHING LOGIC
	LD	A,C		; GET REQUESTED DEVICE/UNIT FROM C
	LD	(HSTDSK),A	; TEMP HACK TO FILL IN HSTDSK
	AND	$F0		; ISOLATE THE DEVICE PORTION
;
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
	SUB	BF_DIOGETBUF	; FUNCTION = DIOGETBUF?
	JR	Z,DIO_GETBUF	; YES, HANDLE IT
	DEC	A		; FUNCTION = DIOSETBUF?
	JR	Z,DIO_SETBUF	; YES, HANDLE IT
	CALL	PANIC		; INVALID FUNCTION SPECFIED
;
; DISK: GET BUFFER ADDRESS
;
DIO_GETBUF:
	LD	HL,(DIOBUF)	; HL = DISK BUFFER ADDRESS
	XOR	A		; SIGNALS SUCCESS
	RET
;
; DISK: SET BUFFER ADDRESS
;
DIO_SETBUF:
	BIT	7,H		; IS HIGH ORDER BIT SET?
	CALL	Z,PANIC		; IF NOT, ADR IS IN LOWER 32K, NOT ALLOWED!!!
	LD	(DIOBUF),HL	; RECORD NEW DISK BUFFER ADDRESS
	XOR	A		; SIGNALS SUCCESS
	RET
;
;==================================================================================================
;   REAL TIME CLOCK DEVICE DISPATCHER
;==================================================================================================
;
; ROUTE CALL TO REAL TIME CLOCK DRIVER (NOT YET IMPLEMENTED)
;   B: FUNCTION
;
RTC_DISPATCH:
	CALL	PANIC
;
;==================================================================================================
;   EMULATION HANDLER DISPATCHER
;==================================================================================================
;
; ROUTE CALL TO EMULATION HANDLER CURRENTLY ACTIVE
;   B: FUNCTION
;
EMU_DISPATCH:
	; EMU FUNCTIONS STARTING AT EMUINI ARE COMMON
	; AND DO NOT DISPATCH TO DRIVERS
	LD	A,B		; GET REQUESTED FUNCTION
	CP	BF_EMUINI
	JR	NC,EMU_COMMON
;
	LD	A,(CUREMU)	; GET ACTIVE EMULATION
;
#IF (TTYENABLE)
	DEC	A		; 1 = TTY
	JP	Z,TTY_DISPATCH
#ENDIF
#IF (ANSIENABLE)
	DEC	A		; 2 = ANSI
	JP	Z,ANSI_DISPATCH
#ENDIF
	CALL	PANIC		; INVALID
;
; HANDLE COMMON EMULATION FUNCTIONS (NOT HANDLER SPECIFIC)
;
EMU_COMMON:
	; REG A CONTAINS FUNCTION ON ENTRY
	CP	BF_EMUINI
	JR	Z,EMU_INI
	CP	BF_EMUQRY
	JR	Z,EMU_QRY
	CALL	PANIC
;
; INITIALIZE EMULATION
;   C: VDA DEVICE/UNIT TO USE GOING FORWARD
;   E: EMULATION TYPE TO USE GOING FORWARD
;
EMU_INI:
	LD	A,E		; LOAD REQUESTED EMULATION TYPE
	LD	(CUREMU),A	; SAVE IT
	LD	A,C		; LOAD REQUESTED VDA DEVICE/UNIT
	LD	(CURVDA),A	; SAVE IT
;
	; UPDATE EMULATION VDA DISPATCHING ADDRESS
#IF (VDUENABLE)
	LD	HL,VDU_DISPVDA
	CP	VDADEV_VDU
	JR	Z,EMU_INI1
#ENDIF
#IF (CVDUENABLE)
	LD	HL,CVDU_DISPVDA
	CP	VDADEV_CVDU
	JR	Z,EMU_INI1
#ENDIF
#IF (UPD7220ENABLE)
	LD	HL,UPD7220_DISPVDA
	CP	VDADEV_UPD7220
	JR	Z,EMU_INI1
#ENDIF
#IF (N8VENABLE)
	LD	HL,N8V_DISPVDA
	CP	VDADEV_N8V
	JR	Z,EMU_INI1
#ENDIF
	CALL	PANIC
;
EMU_INI1:
	LD	(EMU_VDADISPADR),HL	; RECORD NEW VDA DISPATCH ADDRESS
	JP	EMU_VDADISP		; NOW LET EMULATOR INITIALIZE
;
; QUERY CURRENT EMULATION CONFIGURATION
;   RETURN CURRENT EMULATION TARGET VDA DEVICE/UNIT IN C
;   RETURN CURRENT EMULATION TYPE IN E
;
EMU_QRY:
	LD	A,(CURVDA)
	LD	C,A
	LD	A,(CUREMU)
	LD	E,A
	JP	EMU_VDADISP	; NOW LET EMULATOR COMPLETE THE FUNCTION
;
;==================================================================================================
;   VDA DISPATCHING FOR EMULATION HANDLERS
;==================================================================================================
;
; SINCE THE EMULATION HANDLERS WILL ONLY HAVE A SINGLE ACTIVE
; VDA TARGET AT ANY TIME, THE FOLLOWING IMPLEMENTS A FAST DISPATCHING
; MECHANISM THAT THE EMULATION HANDLERS CAN USE TO BYPASS SOME OF THE
; VDA DISPATCHING LOGIC.  EMU_VDADISP CAN BE CALLED TO DISPATCH DIRECTLY
; TO THE CURRENT VDA EMULATION TARGET.  IT IS A JUMP INSTRUCTION THAT 
; IS DYNAMICALLY MODIFIED TO POINT TO THE VDA DISPATCHER FOR THE 
; CURRENT EMULATION VDA TARGET.
;
; BELOW IS USED TO INITIALIZE THE EMULATION VDA DISPATCH TARGET
; BASED ON THE DEFAULT VDA.
;
VDA_DISPADR	.EQU	0
#IF (VDUENABLE & (DEFVDA == VDADEV_VDU))
VDA_DISPADR	.SET	VDU_DISPVDA
#ENDIF
#IF (CVDUENABLE & (DEFVDA == VDADEV_CVDU))
VDA_DISPADR	.SET	CVDU_DISPVDA
#ENDIF
#IF (VDUENABLE & (DEFVDA == VDADEV_UPD7220))
VDA_DISPADR	.SET	UPD7220_DISPVDA
#ENDIF
#IF (N8VENABLE & (DEFVDA == VDADEV_N8V))
VDA_DISPADR	.SET	N8V_DISPVDA
#ENDIF
;
; BELOW IS THE DYNAMICALLY MANAGED EMULATION VDA DISPATCH.
; EMULATION HANDLERS CAN CALL EMU_VDADISP TO INVOKE A VDA
; FUNCTION.  EMU_VDADISPADR IS USED TO MARK THE LOCATION
; OF THE VDA DISPATCH ADDRESS.  THIS ALLOWS US TO MODIFY
; THE CODE DYNAMICALLY WHEN EMULATION IS INITIALIZED AND
; A NEW VDA TARGET IS SPECIFIED.
;
EMU_VDADISPADR	.EQU	$ + 1
EMU_VDADISP:
	JP	VDA_DISPADR
;
;==================================================================================================
;   VIDEO DISPLAY ADAPTER DEVICE DISPATCHER
;==================================================================================================
;
; ROUTE CALL TO SPECIFIED VDA DEVICE DRIVER
;   B: FUNCTION
;   C: DEVICE/UNIT
;
VDA_DISPATCH:
	LD	A,C		; REQUESTED DEVICE/UNIT IS IN C
	AND	$F0		; ISOLATE THE DEVICE PORTION
#IF (VDUENABLE)
	CP	VDADEV_VDU
	JP	Z,VDU_DISPVDA
#ENDIF
#IF (CVDUENABLE)
	CP	VDADEV_CVDU
	JP	Z,CVDU_DISPVDA
#ENDIF
#IF (UPD7220ENABLE)
	CP	VDADEV_7220
	JP	Z,UPD7220_DISPVDA
#ENDIF
#IF (N8VENABLE)
	CP	VDADEV_N8V
	JP	Z,N8V_DISPVDA
#ENDIF
	CALL	PANIC
;
;==================================================================================================
;   SYSTEM FUNCTION DISPATCHER
;==================================================================================================
;
;   B: FUNCTION
;
SYS_DISPATCH:
	LD	A,B		; GET REQUESTED FUNCTION
	AND	$0F		; ISOLATE SUB-FUNCTION
	JR	Z,SYS_GETCFG	; $F0
	DEC	A
	JR	Z,SYS_SETCFG	; $F1
	DEC	A
	JR	Z,SYS_BNKCPY	; $F2
	DEC	A
	JR	Z,SYS_GETVER	; $F3
	CALL	PANIC		; INVALID
;
; GET ACTIVE CONFIGURATION
;   DE: DESTINATION TO RECEIVE CONFIGURATION DATA BLOCK
;       MUST BE IN UPPER 32K
;
SYS_GETCFG:
	LD	HL,$0200		; SETUP SOURCE OF CONFIG DATA
	LD	BC,$0100		; SIZE OF CONFIG DATA
	LDIR				; COPY IT
	RET
;
; SET ACTIVE CONFIGURATION
;   DE: SOURCE OF NEW CONFIGURATION DATA BLOCK
;       MUST BE IN UPPER 32K
;
;   HBIOS IS NOT REALLY SET UP TO DYNAMICALLY RECONFIGURE ITSELF!!!
;   THIS FUNCTION IS NOT USEFUL YET.
;
SYS_SETCFG:
	LD	HL,$0200		; SETUP SOURCE OF CONFIG DATA
	LD	BC,$0100
	EX	DE,HL
	LDIR
	RET
;
; PERFORM A BANKED MEMORY COPY
;   C: BANK TO SWAP INTO LOWER 32K PRIOR TO COPY OPERATION
;   IX: COUNT OF BYTES TO COPY
;   HL: SOURCE ADDRESS FOR COPY
;   DE: DESTINATION ADDRESS FOR COPY
;
SYS_BNKCPY:
	LD	A,C			; BANK SELECTION TO A
	PUSH	IX
	POP	BC			; BC = BYTE COUNT TO COPY
	JP	HB_BNKCPY		; JUST PASS CONTROL TO HBIOS STUB IN UPPER MEMORY
;
; GET THE CURRENT HBIOS VERSION
;   RETURNS VERSION IN DE AS BCD
;     D: MAJOR VERION IN TOP 4 BITS, MINOR VERSION IN LOW 4 BITS
;     E: UPDATE VERION IN TOP 4 BITS, PATCH VERSION IN LOW 4 BITS
;
SYS_GETVER:
	LD	DE,0 | (RMJ<<12) | (RMN<<8) | (RUP<<4) | RTP
	XOR	A
	RET
;
;==================================================================================================
;   GLOBAL HBIOS FUNCTIONS
;==================================================================================================
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
#IF (CVDUENABLE)
ORG_CVDU	.EQU	$
  #INCLUDE "cvdu.asm"
SIZ_CVDU	.EQU	$ - ORG_CVDU
		.ECHO	"CVDU occupies "
		.ECHO	SIZ_CVDU
		.ECHO	" bytes.\n"
#ENDIF
;
#IF (UPD7220ENABLE)
ORG_UPD7220	.EQU	$
  #INCLUDE "upd7220.asm"
SIZ_UPD7220	.EQU	$ - ORG_UPD7220
		.ECHO	"UPD7220 occupies "
		.ECHO	SIZ_UPD7220
		.ECHO	" bytes.\n"
#ENDIF
;
#IF (N8VENABLE)
ORG_N8V		.EQU	$
  #INCLUDE "n8v.asm"
SIZ_N8V		.EQU	$ - ORG_N8V
		.ECHO	"N8V occupies "
		.ECHO	SIZ_N8V
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

#IF (PPKENABLE)
ORG_PPK		.EQU	$
  #INCLUDE "ppk.asm"
SIZ_PPK		.EQU	$ - ORG_PPK
		.ECHO	"PPK occupies "
		.ECHO	SIZ_PPK
		.ECHO	" bytes.\n"
#ENDIF

#IF (KBDENABLE)
ORG_KBD		.EQU	$
  #INCLUDE "kbd.asm"
SIZ_KBD		.EQU	$ - ORG_KBD
		.ECHO	"KBD occupies "
		.ECHO	SIZ_KBD
		.ECHO	" bytes.\n"
#ENDIF

#IF (TTYENABLE)
ORG_TTY		.EQU	$
  #INCLUDE "tty.asm"
SIZ_TTY	.EQU	$ - ORG_TTY
		.ECHO	"TTY occupies "
		.ECHO	SIZ_TTY
		.ECHO	" bytes.\n"
#ENDIF

#IF (ANSIENABLE)
ORG_ANSI	.EQU	$
  #INCLUDE "ansi.asm"
SIZ_ANSI	.EQU	$ - ORG_ANSI
		.ECHO	"ANSI occupies "
		.ECHO	SIZ_ANSI
		.ECHO	" bytes.\n"
#ENDIF
;
#DEFINE	CIOMODE_CONSOLE
#DEFINE	DSKY_KBD
#INCLUDE "util.asm"
;
;==================================================================================================
;   HBIOS GLOBAL DATA
;==================================================================================================
;
CONDEV		.DB	CIODEV_UART
;
IDLECOUNT	.DB	0
;
HSTDSK		.DB	0		; DISK IN BUFFER
HSTTRK		.DW	0		; TRACK IN BUFFER
HSTSEC		.DW	0		; SECTOR IN BUFFER
;
CUREMU		.DB	DEFEMU		; CURRENT EMULATION
CURVDA		.DB	DEFVDA		; CURRENT VDA TARGET FOR EMULATION
;
DIOBUF		.DW	$FD00		; PTR TO 512 BYTE DISK XFR BUFFER
;
STR_BANNER	.DB	"N8VEM HBIOS v", BIOSVER, " ("
VAR_LOC		.DB	VARIANT, "-"
TST_LOC		.DB	TIMESTAMP, ")"
;		.DB	"\r\n", PLATFORM_NAME, DSKYLBL, VDULBL, CVDULBL, UPD7220LBL, N8VLBL
;		.DB	FDLBL, IDELBL, PPIDELBL, SDLBL, PRPLBL, PPPLBL, HDSKLBL
		.DB	"$"
STR_PLATFORM	.DB	PLATFORM_NAME, "$"
;
;==================================================================================================
;   FILL REMAINDER OF HBIOS
;==================================================================================================
;
SLACK:		.EQU	(7F00H - $)
		.FILL	SLACK,0FFH
;
		.ECHO	"HBIOS space remaining: "
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
HB_IVT:
	.FILL	20H,0FFH
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
	EX	AF,AF'		; SAVE AF' SO WE CAN USE IT BELOW
	PUSH	AF		; "

	PGRAMF(1)		; MAP RAM PAGE 1 INTO LOWER 32K
	
	LD	(HB_STKSAV),SP	; SAVE ORIGINAL STACK FRAME
	LD	SP,8000H	; SETUP NEW STACK FRAME AT END OF HBIOS

	CALL	BIOS_DISPATCH	; CALL HBIOS FUNCTION DISPATCHER

	EX	AF,AF'		; SAVE AF IN AF'
	PGRAMF(0)		; MAP RAM PAGE 0 INTO LOWER 32K

	LD	SP,(HB_STKSAV)	; RESTORE ORIGINAL STACK FRAME
	
	POP	AF		; RECOVER ORIGINAL AF'
	EX	AF,AF'		; RESTORE AF' AND GET AF RETURNED FROM DISPATCH BACK

	RET			; RETURN TO CALLER
;
HB_STKSAV	.DW	0	; PREVIOUS STACK POINTER
;
HB_SLACK	.EQU	(HB_END - $)
		.ECHO	"STACK space remaining: "
		.ECHO	HB_SLACK
		.ECHO	" bytes.\n"
;
		.FILL	HB_SLACK,0FFH
		.END
