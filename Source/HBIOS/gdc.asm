;======================================================================
;	UPD7220 GRAPHICS DEVICE CONTROLLER
;======================================================================
;
;======================================================================
; GDC DRIVER - CONSTANTS
;======================================================================
;
#IF (GDCMODE == GDCMODE_ECB)
GDC_BASE	.EQU	$??		; GDC BASE I/O PORT
GDC_DAC_BASE	.EQU	$??		; RAMDAC BASE I/O PORT
#ENDIF
;
#IF (GDCMODE == GDCMODE_RPH)
GDC_KBDDATA	.EQU	$8C		; KBD CTLR DATA PORT
GDC_KBDST	.EQU	$8D		; KBD CTLR STATUS/CMD PORT
GDC_BASE	.EQU	$90		; GDC BASE I/O PORT
GDC_DAC_BASE	.EQU	$98		; RAMDAC BASE I/O PORT
#ENDIF
;
GDC_STAT	.EQU	GDC_BASE + 0		; STATUS PORT
GDC_CMD		.EQU	GDC_BASE + 1		; COMMAND PORT
GDC_PARAM	.EQU	GDC_BASE + 0		; PARAM PORT
GDC_READ	.EQU	GDC_BASE + 1		; READ PORT
GDC_DAC_WR	.EQU	GDC_DAC_BASE + 0	; RAMDAC ADR WRITE
GDC_DAC_RD      .EQU	GDC_DAC_BASE + 3	; RAMDAC ADR READ
GDC_DAC_PALRAM  .EQU	GDC_DAC_BASE + 1	; RAMDAC PALETTE RAM
GDC_DAC_PIXMSK  .EQU	GDC_DAC_BASE + 2	; RAMDAC PIXEL READ MASK
GDC_DAC_OVL_WR  .EQU	GDC_DAC_BASE + 4	; RAMDAC OVERLAY WRITE
GDC_DAC_OVL_RD  .EQU	GDC_DAC_BASE + 7	; RAMDAC OVERLAY READ
GDC_DAC_OVL_RAM .EQU	GDC_DAC_BASE + 5	; RAMDAC OVERLAY RAM
;
GDC_ROWS	.EQU	25
GDC_COLS	.EQU	80
;
; *** TODO: CGA AND EGA ARE PLACEHOLDERS.  THESE EQUATES SHOULD
; BE USED TO ALLOW FOR MULTIPLE MONITOR TIMINGS AND/OR FONT
; DEFINITIONS.
;
#IF (GDCMON == GDCMON_CGA)
  #DEFINE	USEFONTCGA
  #DEFINE	GDC_FONT FONTCGA
#ENDIF
;
#IF (GDCMON == GDCMON_EGA)
  #DEFINE	USEFONT8X16
  #DEFINE	GDC_FONT FONT8X16
#ENDIF
;
TERMENABLE	.SET	TRUE		; INCLUDE TERMINAL PSEUDODEVICE DRIVER
;
;======================================================================
; GDC DRIVER - INITIALIZATION
;======================================================================
;
GDC_INIT:
	LD	IY,GDC_IDAT		; POINTER TO INSTANCE DATA
	
	CALL	NEWLINE
	PRTS("GDC: MODE=$")
#IF (GDCMODE == GDCMODE_ECB)
	PRTS("ECB$")
#ENDIF
#IF (GDCMODE == GDCMODE_RPH)
	PRTS("RPH$")
#ENDIF
;
#IF (GDCMON == GDCMON_CGA)
	PRTS(" CGA$")
#ENDIF	
#IF (GDCMON == GDCMON_EGA)
	PRTS(" EGA$")
#ENDIF	
;
	PRTS(" IO=0x$")
	LD	A,GDC_BASE
	CALL	PRTHEXBYTE
	CALL	GDC_PROBE		; CHECK FOR HW PRESENCE
	JR	Z,GDC_INIT1		; CONTINUE IF HW PRESENT
;
	; HARDWARE NOT PRESENT
	PRTS(" NOT PRESENT$")
	OR	$FF			; SIGNAL FAILURE
	RET
;
GDC_INIT1:
	CALL 	GDC_CRTINIT		; SETUP THE GDC CHIP REGISTERS
	CALL	GDC_VDARES		; RESET GDC
	CALL	KBD_INIT		; INITIALIZE KEYBOARD DRIVER

	; ADD OURSELVES TO VDA DISPATCH TABLE
	LD	BC,GDC_FNTBL		; BC := FUNCTION TABLE ADDRESS
	LD	DE,GDC_IDAT		; DE := GDC INSTANCE DATA PTR
	CALL	VDA_ADDENT		; ADD ENTRY, A := UNIT ASSIGNED

	; INITIALIZE EMULATION
	LD	C,A			; C := ASSIGNED VIDEO DEVICE NUM
	LD	DE,GDC_FNTBL		; DE := FUNCTION TABLE ADDRESS
	LD	HL,GDC_IDAT		; HL := GDC INSTANCE DATA PTR
	CALL	TERM_ATTACH		; DO IT

	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
; GDC DRIVER - VIDEO DISPLAY ADAPTER (VDA) FUNCTIONS
;======================================================================
;
GDC_FNTBL:
	.DW	GDC_VDAINI
	.DW	GDC_VDAQRY
	.DW	GDC_VDARES
	.DW	GDC_VDADEV
	.DW	GDC_VDASCS
	.DW	GDC_VDASCP
	.DW	GDC_VDASAT
	.DW	GDC_VDASCO
	.DW	GDC_VDAWRC
	.DW	GDC_VDAFIL
	.DW	GDC_VDACPY
	.DW	GDC_VDASCR
	.DW	KBD_STAT
	.DW	KBD_FLUSH
	.DW	KBD_READ
	.DW	GDC_VDARDC
#IF (($ - GDC_FNTBL) != (VDA_FNCNT * 2))
	.ECHO	"*** INVALID GDC FUNCTION TABLE ***\n"
	!!!!!
#ENDIF
;
GDC_VDAINI:
	; RESET VDA
	CALL	GDC_VDARES		; RESET VDA
	XOR	A			; SIGNAL SUCCESS
	RET
;
GDC_VDAQRY:	; VIDEO INFORMATION QUERY
	LD	C,$00		; MODE ZERO IS ALL WE KNOW
	LD	D,GDC_ROWS	; ROWS
	LD	E,GDC_COLS	; COLS
	LD	HL,0		; EXTRACTION OF CURRENT BITMAP DATA NOT SUPPORTED YET
	XOR	A		; SIGNAL SUCCESS
	RET
;
GDC_VDARES:	; VIDEO SYSTEM RESET
	; *** TODO: RESET VIDEO SYSTEM HERE, CLEAR SCREEN,
	; CURSOR TO TOP LEFT, CLEAR ATTRIBUTES
	XOR	A
	RET
;
GDC_VDADEV:	; VIDEO DEVICE INFORMATION
	LD	D,VDADEV_GDC	; D := DEVICE TYPE
	LD	E,0		; E := PHYSICAL UNIT IS ALWAYS ZERO
	LD	H,0		; H := 0, DRIVER HAS NO MODES
	LD	L,GDC_BASE	; L := BASE I/O ADDRESS
	XOR	A		; SIGNAL SUCCESS
	RET
;
GDC_VDASCS:	; SET CURSOR STYLE
	SYSCHKERR(ERR_NOTIMPL)
	RET

GDC_VDASCP:	; SET CURSOR POSITION
	CALL	GDC_XY		; SET CURSOR POSITION
	XOR	A		; SIGNAL SUCCESS
	RET

GDC_VDASAT:	; SET ATTRIBUTES
	LD	A,E		; GET THE INCOMING ATTRIBUTE
	LD	(GDC_ATTR),A	; AND SAVE FOR LATER
	XOR	A		; SIGNAL SUCCESS
	RET

GDC_VDASCO:	; SET COLOR
	LD	A,E		; GET THE INCOMING COLOR
	LD	(GDC_COLOR),A	; AND SAVE FOR LATER
	XOR	A		; SIGNAL SUCCESS
	RET

GDC_VDAWRC:	; WRITE CHARACTER
	LD	A,E		; CHARACTER TO WRITE GOES IN A
	CALL	GDC_PUTCHAR	; PUT IT ON THE SCREEN
	XOR	A		; SIGNAL SUCCESS
	RET

GDC_VDAFIL:	; FILL WITH CHARACTER
	LD	A,E		; FILL CHARACTER GOES IN A
	EX	DE,HL		; FILL LENGTH GOES IN DE
	CALL	GDC_FILL	; DO THE FILL
	XOR	A		; SIGNAL SUCCESS
	RET

GDC_VDACPY:	; COPY CHARACTERS/ATTRIBUTES
	; LENGTH IN HL, SOURCE ROW/COL IN DE, DEST IS GDC_POS
	; BLKCPY USES: HL=SOURCE, DE=DEST, BC=COUNT
	PUSH	HL		; SAVE LENGTH
	CALL	GDC_XY2IDX	; ROW/COL IN DE -> SOURCE ADR IN HL
	POP	BC		; RECOVER LENGTH IN BC
	LD	DE,(GDC_POS)	; PUT DEST IN DE
	JP	GDC_BLKCPY	; DO A BLOCK COPY

GDC_VDASCR:	; SCROLL ENTIRE SCREEN
	LD	A,E		; LOAD E INTO A
	OR	A		; SET FLAGS
	RET	Z		; IF ZERO, WE ARE DONE
	PUSH	DE		; SAVE E
	JP	M,GDC_VDASCR1	; E IS NEGATIVE, REVERSE SCROLL
	CALL	GDC_SCROLL	; SCROLL FORWARD ONE LINE
	POP	DE		; RECOVER E
	DEC	E		; DECREMENT IT
	JR	GDC_VDASCR	; LOOP
GDC_VDASCR1:
	CALL	GDC_RSCROLL	; SCROLL REVERSE ONE LINE
	POP	DE		; RECOVER E
	INC	E		; INCREMENT IT
	JR	GDC_VDASCR	; LOOP
;
GDC_VDARDC:	; READ CHAR/ATTR VALUE FROM VIDEO BUFFER
	OR	$FF		; UNSUPPORTED FUNCTION
	RET
;
;======================================================================
; GDC DRIVER - PRIVATE DRIVER FUNCTIONS
;======================================================================
;
;----------------------------------------------------------------------
; PROBE FOR GDC HARDWARE
;----------------------------------------------------------------------
;
; ON RETURN, ZF SET INDICATES HARDWARE FOUND
;
; *** TODO: IMPLEMENT THIS
;
GDC_PROBE:
	XOR	A			; SIGNAL SUCCESS
	RET				; RETURN WITH ZF SET BASED ON CP
;
;----------------------------------------------------------------------
; DISPLAY CONTROLLER CHIP INITIALIZATION
;----------------------------------------------------------------------
;
; *** TODO: IMPLEMENT THIS
;
GDC_CRTINIT:
	XOR	A			; SIGNAL SUCCESS
	RET
;
;----------------------------------------------------------------------
; SET CURSOR POSITION TO ROW IN D AND COLUMN IN E
;----------------------------------------------------------------------
;
GDC_XY:
	CALL	GDC_XY2IDX		; CONVERT ROW/COL TO BUF IDX
	LD	(GDC_POS),HL		; SAVE THE RESULT (DISPLAY POSITION)
	; *** TODO: MOVE THE CURSOR
	RET
;
;----------------------------------------------------------------------
; CONVERT XY COORDINATES IN DE INTO LINEAR INDEX IN HL
; D=ROW, E=COL
;----------------------------------------------------------------------
;
GDC_XY2IDX:
	LD	A,E			; SAVE COLUMN NUMBER IN A
	LD	H,D			; SET H TO ROW NUMBER
	LD	E,GDC_COLS		; SET E TO ROW LENGTH
	CALL	MULT8			; MULTIPLY TO GET ROW OFFSET
	LD	E,A			; GET COLUMN BACK
	ADD	HL,DE			; ADD IT IN
	RET				; RETURN
;
;----------------------------------------------------------------------
; WRITE VALUE IN A TO CURRENT VDU BUFFER POSITION, ADVANCE CURSOR
;----------------------------------------------------------------------
;
GDC_PUTCHAR:
	; *** TODO: IMPLEMENT THIS
	RET
;
;----------------------------------------------------------------------
; FILL AREA IN BUFFER WITH SPECIFIED CHARACTER AND CURRENT COLOR/ATTRIBUTE
; STARTING AT THE CURRENT FRAME BUFFER POSITION
;   A: FILL CHARACTER
;   DE: NUMBER OF CHARACTERS TO FILL
;----------------------------------------------------------------------
;
GDC_FILL:
	; *** TODO: IMPLEMENT THIS
	RET
;
;----------------------------------------------------------------------
; SCROLL ENTIRE SCREEN FORWARD BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
GDC_SCROLL:
	; *** TODO: IMPLEMENT THIS
	RET
;
;----------------------------------------------------------------------
; REVERSE SCROLL ENTIRE SCREEN BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
GDC_RSCROLL:
	; *** TODO: IMPLEMENT THIS
	RET
;
;----------------------------------------------------------------------
; BLOCK COPY BC BYTES FROM HL TO DE
;----------------------------------------------------------------------
;
GDC_BLKCPY:
	; *** TODO: IMPLEMENT THIS
	RET
;
;==================================================================================================
;   GDC DRIVER - DATA
;==================================================================================================
;
GDC_ATTR	.DB	0	; CURRENT ATTRIBUTES
GDC_COLOR	.DB	0	; CURRENT COLOR
GDC_POS		.DW 	0	; CURRENT DISPLAY POSITION
;
;==================================================================================================
;   GDC DRIVER - INSTANCE DATA
;==================================================================================================
;
GDC_IDAT:
	.DB	GDC_KBDST
	.DB	GDC_KBDDATA
