;
;==================================================================================================
;   HBIOS
;==================================================================================================
;
	.ORG	$1000
;
; INCLUDE GENERIC STUFF
;
#INCLUDE "std.asm"
;
;==================================================================================================
;   ENTRY VECTORS (JUMP TABLE)
;==================================================================================================
;
	JP	HB_START
	JP	HB_DISPATCH
;
;==================================================================================================
;   HBIOS INTERNAL PROXY JUMP TABLE
;==================================================================================================
;
; THE FOLLOWING VECTOR TABLE IS USED BY HBIOS TO CALLBACK TO THE
; HBIOS PROXY INTERNALLY.  IT SHOULD NEVER BE CALLED OUTSIDE OF HBIOS.
; IT IS PROVIDED SO THAT THE LOCATION OF THE HBIOS PROXY CAN BE LOCATED
; AT ARBITRARY ADDRESSES AND THE TABLE BELOW ADJUSTED AS NEEDED.
;
HBXX:
HBXX_SETBNK	JP	HBXI_SETBNK
HBXX_GETBNK	JP	HBXI_GETBNK
HBXX_COPY	JP	HBXI_COPY
HBXX_XCOPY	JP	HBXI_XCOPY
;
;==================================================================================================
;   SYSTEM INITIALIZATION
;==================================================================================================
;
HB_START:
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
	LD	HL,HBX_IMG	; HL := SOURCE OF HBIOS PROXY IMAGE
	LD	DE,HBX_LOC	; DE := DESTINATION TO INSTALL IT
	LD	BC,HBX_SIZ	; SIZE
	LDIR			; DO THE COPY
;
; UDPATE THE PROXY CALLBACK VECTOR TABLE
;
	LD	HL,HBXI_SETBNK
	LD	(HBXX_SETBNK + 1),HL
	LD	HL,HBXI_GETBNK
	LD	(HBXX_GETBNK + 1),HL
	LD	HL,HBXI_COPY
	LD	(HBXX_COPY + 1),HL
	LD	HL,HBXI_XCOPY
	LD	(HBXX_XCOPY + 1),HL
;
; DURING INITIALIZATION, CONSOLE IS ALWAYS PRIMARY SERIAL PORT
; POST-INITIALIZATION, WILL BE SWITCHED TO USER CONFIGURED CONSOLE
;
	LD	A,BOOTCON
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
	POP	BC
	POP	DE
	DJNZ	INITSYS2
;
; SET UP THE DEFAULT DISK BUFFER ADDRESS
;
	LD	HL,HBX_IMG	; DEFAULT DISK XFR BUF ADDRESS
	LD	(DIOBUF),HL	; SAVE IT
;
; NOW SWITCH TO USER CONFIGURED CONSOLE
;
#IF ((PLATFORM == PLT_N8) | (PLATFORM == PLT_MK4) | (PLATFORM == PLT_S100))
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
#IF (ASCIENABLE)
	.DW	ASCI_INIT
#ENDIF
#IF (SIMRTCENABLE)
	.DW	SIMRTC_INIT
#ENDIF
#IF (DSRTCENABLE)
	.DW	DSRTC_INIT
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
#IF (MDENABLE)
	.DW	MD_INIT
#ENDIF
#IF (FDENABLE)
	.DW	FD_INIT
#ENDIF
#IF (RFENABLE)
	.DW	RF_INIT
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
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
#IF (FDENABLE)
	CALL	FD_IDLE
#ENDIF
	POP	HL
	POP	DE
	POP	BC
	POP	AF
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
HB_DISPATCH:
	LD	A,B		; REQUESTED FUNCTION IS IN B
	CP	BF_CIO + $10	; $00-$0F: CHARACTER I/O
	JP	C,CIO_DISPATCH
	CP	BF_DIO + $10	; $10-$1F: DISK I/O
	JP	C,DIO_DISPATCH
	CP	BF_RTC + $10	; $20-$2F: REAL TIME CLOCK (RTC)
	JP	C,RTC_DISPATCH
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
#IF (ASCIENABLE)
	CP	CIODEV_ASCI
	JP	Z,ASCI_DISPATCH
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
	CP	CIODEV_CONSOLE
	JR	Z,CIOCON
	CALL	PANIC
;
CIOEMU:
	LD	A,B
	ADD	A,BF_EMU - BF_CIO	; TRANSLATE FUNCTION CIOXXX -> EMUXXX
	LD	B,A
	JP	EMU_DISPATCH
;
CIOCON:
	LD	A,(CONDEV)
	LD	C,A
	JR	CIO_DISPATCH
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
#IF (MDENABLE)
	CP	DIODEV_MD
	JP	Z,MD_DISPATCH
#ENDIF
#IF (FDENABLE)
	CP	DIODEV_FD
	JP	Z,FD_DISPATCH
#ENDIF
#IF (RFENABLE)
	CP	DIODEV_RF
	JP	Z,RF_DISPATCH
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
;	BIT	7,H		; IS HIGH ORDER BIT SET?
;	CALL	Z,PANIC		; IF NOT, ADR IS IN LOWER 32K, NOT ALLOWED!!!
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
#IF (SIMRTCENABLE)
	JP	SIMRTC_DISPATCH
#ENDIF
#IF (DSRTCENABLE)
	JP	DSRTC_DISPATCH
#ENDIF
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
; VDA_DISPERR IS FAILSAFE EMULATION DISPATCH ADDRESS WHICH JUST
; CHAINS TO SYSTEM PANIC
;
VDA_DISPERR:
	JP	PANIC
;
; BELOW IS USED TO INITIALIZE THE EMULATION VDA DISPATCH TARGET
; BASED ON THE DEFAULT VDA.
;
VDA_DISPADR	.EQU	VDA_DISPERR
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
EMU_VDADISP:
	JP	VDA_DISPADR
;
EMU_VDADISPADR	.EQU	$ - 2		; ADDRESS PORTION OF JP INSTRUCTION ABOVE
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
	JR	Z,SYS_SETBNK	; $F0
	DEC	A
	JR	Z,SYS_GETBNK	; $F1
	DEC	A
	JP	Z,HBXI_COPY	; $F2
	DEC	A
	JP	Z,HBX_XCOPY	; $F2
	DEC	A
	JR	Z,SYS_GETCFG	; $F3
	DEC	A
	JR	Z,SYS_SETCFG	; $F4
	DEC	A
	JR	Z,SYS_GETVER	; $F5
	CALL	PANIC		; INVALID
;
; SET ACTIVE MEMORY BANK AND RETURN PREVIOUSLY ACTIVE MEMORY BANK
;   NOTE THAT IT GOES INTO EFFECT AS HBIOS IS EXITED
;   HERE, WE JUST SET THE CURRENT BANK
;   CALLER MUST EXTABLISH UPPER MEMORY STACK BEFORE INVOKING THIS FUNCTION!
;
SYS_SETBNK:
	LD	A,(HBX_CURBNK)	; GET THE PREVIOUS ACTIVE MEMORY BANK
	PUSH	AF		; SAVE IT
	LD	A,C		; LOAD THE NEW BANK REQUESTED
	LD	(HBX_CURBNK),A	; SET IT FOR ACTIVATION UPON HBIOS RETURN
	POP	AF		; GET PREVIOUS BANK INTO A
	OR	A
	RET
;
; GET ACTIVE MEMORY BANK
;
SYS_GETBNK:
	LD	A,(HBX_CURBNK)	; GET THE PREVIOUS ACTIVE MEMORY BANK
	OR	A
	RET
;
; GET ACTIVE MEMORY BANK
;
SYS_COPY:
	PUSH	IX
	POP	BC
	CALL	HBXI_COPY
	XOR	A
	RET
;
; SET BANKS FOR EXTENDED (INTERBANK) MEMORY COPY
;
SYS_XCOPY:
	PUSH	DE
	POP	BC
	CALL	HBX_XCOPY
	XOR	A
	RET
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
; GET THE CURRENT HBIOS VERSION
;   RETURNS VERSION IN DE AS BCD
;     D: MAJOR VERION IN TOP 4 BITS, MINOR VERSION IN LOW 4 BITS
;     E: UPDATE VERION IN TOP 4 BITS, PATCH VERSION IN LOW 4 BITS
;
SYS_GETVER:
	LD	DE,0 | (RMJ << 12) | (RMN << 8) | (RUP << 4) | RTP
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
	PUSH	AF			; PRESERVE AF
	LD	A,(IDLECOUNT)		; GET CURRENT IDLE COUNT
	DEC	A			; DECREMENT
	LD	(IDLECOUNT),A		; SAVE UPDATED VALUE
	CALL	Z,IDLE			; IF ZERO, DO IDLE PROCESSING
	POP	AF			; RECOVER AF
	RET
;
;==================================================================================================
;   DEVICE DRIVERS
;==================================================================================================
;
#IF (SIMRTCENABLE)
ORG_SIMRTC	.EQU	$
  #INCLUDE "simrtc.asm"
SIZ_SIMRTC	.EQU	$ - ORG_SIMRTC
		.ECHO	"SIMRTC occupies "
		.ECHO	SIZ_SIMRTC
		.ECHO	" bytes.\n"
#ENDIF
;
#IF (DSRTCENABLE)
ORG_DSRTC	.EQU	$
  #INCLUDE "dsrtc.asm"
SIZ_DSRTC	.EQU	$ - ORG_DSRTC
		.ECHO	"DSRTC occupies "
		.ECHO	SIZ_DSRTC
		.ECHO	" bytes.\n"
#ENDIF
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
#IF (ASCIENABLE)
ORG_ASCI	.EQU	$
  #INCLUDE "asci.asm"
SIZ_ASCI	.EQU	$ - ORG_ASCI
		.ECHO	"ASCI occupies "
		.ECHO	SIZ_ASCI
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
#IF (MDENABLE)
ORG_MD		.EQU	$
  #INCLUDE "md.asm"
SIZ_MD		.EQU	$ - ORG_MD
		.ECHO	"MD occupies "
		.ECHO	SIZ_MD
		.ECHO	" bytes.\n"
#ENDIF

#IF (FDENABLE)
ORG_FD		.EQU	$
  #INCLUDE "fd.asm"
SIZ_FD		.EQU	$ - ORG_FD
		.ECHO	"FD occupies "
		.ECHO	SIZ_FD
		.ECHO	" bytes.\n"
#ENDIF

#IF (RFENABLE)
ORG_RF	.EQU	$
  #INCLUDE "rf.asm"
SIZ_RF	.EQU	$ - ORG_RF
		.ECHO	"RF occupies "
		.ECHO	SIZ_RF
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
#INCLUDE "time.asm"
;
;==================================================================================================
;   HBIOS GLOBAL DATA
;==================================================================================================
;
CONDEV		.DB	BOOTCON
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
DIOBUF		.DW	HBX_IMG		; PTR TO 1024 BYTE DISK XFR BUFFER
;
STR_BANNER	.DB	"N8VEM HBIOS v", BIOSVER, ", ", BIOSBLD, ", ", TIMESTAMP, "$"
STR_PLATFORM	.DB	PLATFORM_NAME, "$"
;
;==================================================================================================
;   FILL REMAINDER OF HBIOS
;==================================================================================================
;
SLACK		.EQU	(HBX_LOC - $8000 - $)
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
; THE FOLLOWING CODE IS RELOCATED TO THE TOP OF MEMORY TO HANDLE INVOCATION DISPATCHING
;
HBX_IMG		.EQU	$
		.ORG	HBX_LOC
;
;==================================================================================================
;   HBIOS JUMP TABLE
;==================================================================================================
;
	JP	HBX_INIT
	JP	HBX_INVOKE
	JP	HBX_SETBNK
	JP	HBX_GETBNK
	JP	HBX_COPY
	JP	HBX_XCOPY
	JP	HBX_FRGETB
	JP	HBX_FRGETW
	JP	HBX_FRPUTB
	JP	HBX_FRPUTW
;
;==================================================================================================
;   HBIOS INITIALIZATION
;==================================================================================================
;
; SETUP RST 08 VECTOR TO HANDLE MAIN BIOS FUNCTIONS
;
HBX_INIT:
	LD	A,$C3		; $C3 = JP
	LD	($08),A
	LD	HL,HBX_INVOKE
	LD	($09),HL
	RET
;
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
; SETBNK - Switch Memory Bank to Bank in A and show as current.
;  Must preserve all Registers including Flags.
;  All Bank Switching MUST be done by this routine
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;
HBX_SETBNK:
	LD	(HBX_CURBNK),A
;
; Enter at HBXI_SETBNK to set bank temporarily and avoid
; updating the "current" bank.
;
HBXI_SETBNK:
#IF ((PLATFORM == PLT_N8VEM) | (PLATFORM == PLT_ZETA))
	OUT	(MPCL_ROM),A
	OUT	(MPCL_RAM),A
#ENDIF
#IF (PLATFORM == PLT_N8)
	BIT	7,A
	JR	Z,HBX_ROM
;
HBX_RAM:
	RES	7,A
	RLCA
	RLCA
	RLCA
	OUT0	(CPU_BBR),A
	LD	A,DEFACR | 80H
	OUT0	(ACR),A
	RET
;
HBX_ROM:
	OUT0	(RMAP),A
	XOR	A
	OUT0	(CPU_BBR),A
	LD	A,DEFACR
	OUT0	(ACR),A
	RET
;
#ENDIF
#IF (PLATFORM == PLT_MK4)
	RLCA
	RLCA
	RLCA
	OUT0	(CPU_BBR),A
#ENDIF
	RET
;
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
; GETBNK - Get current memory bank and return in A.
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;
HBX_GETBNK:
HBXI_GETBNK:
	LD	A,(HBX_CURBNK)
	RET
;
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;	Set Banks for Inter-Bank Xfer.  Save all Registers.
;  B = Destination Bank, C = Source Bank
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;
HBX_XCOPY:
HBXI_XCOPY:
	LD	(HBX_SRCBNK),BC	; SETS BOTH SRCBNK AND DSTBNK
	RET
;
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
; Copy Data - Possibly between banks.  This resembles CP/M 3, but
;  usage of the HL and DE registers is reversed.
; Enter: HL = Source Address
;	 DE = Destination Address
;	 BC = Number of bytes to copy
; Exit : None
; Uses : AF,BC,DE,HL
;
;::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
;
; Primary entry point activates private stack while doing work.  The
; secondary entry point MUST be used by internal HBIOS code/drivers
; because our private stack is already active!
;
HBX_COPY:
	LD	(HBX_STKSAV),SP	; Save current stack
	LD	SP,HBX_STACK	; Activate our private stack
	CALL	HBX_COPY1	; Do the work with private stack active
	LD	SP,(HBX_STKSAV)	; Back to original stack
	LD	A,(HBX_CURBNK)	; Get the "current" bank
	JR	HBXI_SETBNK	; Activate current bank and return
;
; Secondary entry point HBXI_COPY is for use internally by HBIOS and
; assumes a valid stack already exists in upper 32K.  It also ignores
; the "current" bank and terminates with HBIOS bank active.
;
HBXI_COPY:
	CALL	HBX_COPY1
	LD	A,BID_HB	; Get the HBIOS bank
	JR	HBXI_SETBNK	; .. activate and return
;
;
;
HBX_COPY1:
	; Setup for copy loop
	LD	(HBX_SRCADR),HL	; Init working source adr
	LD	(HBX_DSTADR),DE	; Init working dest adr 
	LD	H,B		; Move bytes to copy from BC...
	LD	L,C		;   to HL to use as byte counter

HBX_COPY2:	; Copy loop
	INC	L		; Set ZF to indicate...
	DEC	L		;   if a partial page copy is needed
	LD	BC,$100		; Assume a full page copy, 100H bytes
	JR	Z,HBX_COPY3	; If full page copy, go do it
	DEC	B		; Otherwise, setup for partial page copy
	LD	C,L		; by making BC := 0

HBX_COPY3:
	PUSH	HL		; Save bytes left to copy
	CALL	HBX_COPY4	; Do it
	POP	HL		; Recover bytes left to copy
	XOR	A		; Clear CF
	SBC	HL,BC		; Reflect bytes copied in HL
	JR	NZ,HBX_COPY2	; If any left, then loop

	LD	HL,(HBX_DEFBNK)	; Get TPA Bank #
	LD	H,L		; .to both H and L
	LD	(HBX_SRCBNK),HL	; ..set Source & Destination Bank # to default

	RET			; Done

HBX_COPY4:
	; Switch to source bank
	LD	A,(HBX_SRCBNK)	; Get source bank
	CALL	HBXI_SETBNK	; Set bank without making it current

	; Copy BC bytes from HL -> BUF
	; Allow HL to increment
	PUSH	BC		; Save copy length
	LD	HL,(HBX_SRCADR)	; Point to source adr
	LD	DE,HBX_BUF	; Setup buffer as interim destination
	LDIR			; Copy BC bytes: src -> buffer
	LD	(HBX_SRCADR),HL	; Update source adr
	POP	BC		; Recover copy length
	
	; Switch to dest bank
	LD	A,(HBX_DSTBNK)	; Get destination bank
	CALL	HBXI_SETBNK	; Set bank without making it current

	; Copy BC bytes from BUF -> HL
	; Allow DE to increment
	PUSH	BC		; Save copy length
	LD	HL,HBX_BUF	; Use the buffer as source now
	LD	DE,(HBX_DSTADR)	; Setup final destination for copy
	LDIR			; Copy BC bytes: buffer -> dest
	LD	(HBX_DSTADR),DE	; Update dest adr
	POP	BC		; Recover copy length

	RET			; Done
;
;==================================================================================================
;   HBIOS ENTRY FOR RST 08 PROCESSING
;==================================================================================================
;
; MARKER IMMEDIATELY PRECEDES INVOKE ROUTINE ADDRESS
;
HBX_MARKER:
	.DB	'W',~'W'	; IDENTIFIES HBIOS
;
; ENTRY POINT FOR BIOS FUNCTIONS (TARGET OF RST 08)
;
HBX_INVOKE:
	LD	(HBX_STKSAV),SP	; SAVE ORIGINAL STACK FRAME
	LD	SP,HBX_STACK	; SETUP NEW STACK FRAME

	LD	A,BID_HB	; HBIOS BANK
	CALL	HBXI_SETBNK	; SELECT IT

	CALL	HB_DISPATCH	; CALL HBIOS FUNCTION DISPATCHER

	PUSH	AF		; SAVE AF (FUNCTION RETURN)
	LD	A,(HBX_CURBNK)	; GET ENTRY BANK
	CALL	HBXI_SETBNK	; SELECT IT
	POP	AF		; RESTORE AF

	LD	SP,(HBX_STKSAV)	; RESTORE ORIGINAL STACK FRAME

	RET			; RETURN TO CALLER
;
;==================================================================================================
;   HBIOS INTERBANK MEMORY COPY BUFFER
;==================================================================================================
;
	.FILL	$FE00 - $,$FF	; FILL TO START OF BUFFER PAGE
HBX_BUF	.FILL	$100,0		; INTER-BANK COPY BUFFER
;
;==================================================================================================
;   HBIOS INTERRUPT VECTOR TABLE
;==================================================================================================
;
	.FILL	$FF00 - $,$FF	; FILL TO START OF LAST PAGE
;
; AREA RESERVED FOR UP TO 16 INTERRUPT VECTOR ENTRIES (MODE 2)
;
HBX_IVT:
	.FILL	$20,$FF
;
;==================================================================================================
;	Load  A,(HL)  from  Alternate  Bank  (in Reg C)
;==================================================================================================
;
HBX_FRGETB:
	LD	(HBX_STKSAV),SP	; SAVE ORIGINAL STACK FRAME
	LD	SP,HBX_STACK	; SETUP NEW STACK FRAME
	PUSH	BC
	LD	A,C
	DI
	CALL	HBXI_SETBNK	; SELECT IT
	LD	C,(HL)
	LD	A,(HBX_CURBNK)
	CALL	HBXI_SETBNK	; SELECT IT
	EI
	LD	A,C
	POP	BC
	LD	SP,(HBX_STKSAV)	; RESTORE ORIGINAL STACK FRAME
	RET
;
;==================================================================================================
;	Load  DE,(HL)  from  Alternate  Bank
;==================================================================================================
;
HBX_FRGETW:
	LD	(HBX_STKSAV),SP	; SAVE ORIGINAL STACK FRAME
	LD	SP,HBX_STACK	; SETUP NEW STACK FRAME
	LD	A,C
	DI
	CALL	HBXI_SETBNK	; SELECT IT
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	DEC	HL
	LD	A,(HBX_CURBNK)
	CALL	HBXI_SETBNK	; SELECT IT
	EI
	LD	SP,(HBX_STKSAV)	; RESTORE ORIGINAL STACK FRAME
	RET
;
;==================================================================================================
;	Load  (HL),A  to  Alternate  Bank  (in Reg C)
;==================================================================================================
;
HBX_FRPUTB:	
	LD	(HBX_STKSAV),SP	; SAVE ORIGINAL STACK FRAME
	LD	SP,HBX_STACK	; SETUP NEW STACK FRAME
	PUSH	BC
	LD	B,A
	LD	A,C
	DI
	CALL	HBXI_SETBNK	; SELECT IT
	LD	(HL),B
	LD	A,(HBX_CURBNK)
	CALL	HBXI_SETBNK	; SELECT IT
	EI
	POP	BC
	LD	SP,(HBX_STKSAV)	; RESTORE ORIGINAL STACK FRAME
	RET
;
;==================================================================================================
;	Load  (HL),DE  to  Alternate  Bank
;==================================================================================================
;
HBX_FRPUTW:	
	LD	(HBX_STKSAV),SP	; SAVE ORIGINAL STACK FRAME
	LD	SP,HBX_STACK	; SETUP NEW STACK FRAME
	LD	A,C
	DI
	CALL	HBXI_SETBNK	; SELECT IT
	LD	(HL),E
	INC	HL
	LD	(HL),D
	DEC	HL
	LD	A,(HBX_CURBNK)
	CALL	HBXI_SETBNK	; SELECT IT
	EI
	LD	SP,(HBX_STKSAV)	; RESTORE ORIGINAL STACK FRAME
	RET
;
; PRIVATE DATA
;
HBX_STKSAV	.DW	0		; Saved stack pointer during HBIOS calls
HBX_CURBNK	.DB	BID_USR		; Currently active memory bank
HBX_SAVBNK	.DB	0		; Place to save entry bank during HB processing
HBX_DEFBNK	.DB	BID_USR		; Default bank number
HBX_SRCBNK	.DB	BID_USR		; Copy Source Bank #
HBX_DSTBNK	.DB	BID_USR		; Copy Destination Bank #
HBX_SRCADR	.DW	0		; Copy Source Address
HBX_DSTADR	.DW	0		; Copy Destination Address
;
; PRIVATE STACK
;
HBX_STKSIZ	.EQU	(HBX_END - $ - 2)
		.ECHO	"STACK space remaining: "
		.ECHO	HBX_STKSIZ
		.ECHO	" bytes.\n"
;
		.FILL	HBX_STKSIZ,$FF
HBX_STACK	.EQU	$
		.DW	HBX_MARKER	; POINTER TO HBIOS MARKER
		.END
