;======================================================================
;	VDU DRIVER FOR N8VEM PROJECT
;
;	ORIGINALLY WRITTEN BY: ANDREW LYNCH
;	REVISED/ENHANCED BY DAN WERNER -- 11/7/2009
;	ROMWBW ADAPTATION BY: WAYNE WARTHEN -- 11/9/2012
;======================================================================
;
; TODO:
;   - ADD REMAINING REGISTERS TO INIT
;   - TRY 25 ROW MODE?
;   - IMPLEMENT CONSTANTS FOR SCREEN DIMENSIONS
;   - IMPLEMENT SET CURSOR STYLE (VDASCS) FUNCTION
;   - IMPLEMENT ALTERNATE DISPLAY MODES?
;
;======================================================================
; CVDU DRIVER - CONSTANTS
;======================================================================
;
VDU_RAMRD	 .EQU	0F0h		; READ VDU
VDU_RAMWR	 .EQU	0F1h		; WRITE VDU
VDU_STAT	 .EQU	0F2h		; VDU STATUS/REGISTER
VDU_REG		 .EQU	0F2h		; VDU STATUS/REGISTER
VDU_DATA	 .EQU	0F3h		; VDU DATA REGISTER
;
;======================================================================
; VDU DRIVER - INITIALIZATION
;======================================================================
;
VDU_INIT:
	CALL 	VDU_CRTINIT		; INIT SY6845 VDU CHIP
	
VDU_RESET:
	LD	DE,0
	LD	(VDU_OFFSET),DE
	CALL	VDU_XY
	LD	A,' '
	LD	DE,1024*16
	CALL	VDU_FILL
	XOR	A
	RET
;	
;======================================================================
; VDU DRIVER - CHARACTER I/O (CIO) DISPATCHER AND FUNCTIONS
;======================================================================
;
VDU_DISPCIO:
	LD	A,B			; GET REQUESTED FUNCTION
	AND	$0F			; ISOLATE SUB-FUNCTION
	JR	Z,VDU_CIOIN		; $00
	DEC	A
	JR	Z,VDU_CIOOUT		; $01
	DEC	A
	JR	Z,VDU_CIOIST		; $02
	DEC	A
	JR	Z,VDU_CIOOST		; $03
	CALL	PANIC
;	
VDU_CIOIN:
	JP	PPK_READ		; CHAIN TO KEYBOARD DRIVER
;
VDU_CIOIST:
	JP	PPK_STAT		; CHAIN TO KEYBOARD DRIVER
;
VDU_CIOOUT:
	JP	VDU_VDAWRC		; WRITE CHARACTER
;
VDU_CIOOST:
	XOR	A			; A := 0
	INC	A			; A := 1, SIGNAL OUTPUT BUFFER READY
	RET
;	
;======================================================================
; VDU DRIVER - VIDEO DISPLAY ADAPTER (VDA) DISPATCHER AND FUNCTIONS
;======================================================================
;
VDU_DISPVDA:
	LD	A,B		; GET REQUESTED FUNCTION
	AND	$0F		; ISOLATE SUB-FUNCTION

	JR	Z,VDU_VDAINI	; $40
	DEC	A
	JR	Z,VDU_VDAQRY	; $41
	DEC	A
	JR	Z,VDU_VDARES	; $42
	DEC	A
	JR	Z,VDU_VDASCS	; $43
	DEC	A
	JR	Z,VDU_VDASCP	; $44
	DEC	A
	JR	Z,VDU_VDASAT	; $45
	DEC	A
	JR	Z,VDU_VDASCO	; $46
	DEC	A
	JR	Z,VDU_VDAWRC	; $47
	DEC	A
	JR	Z,VDU_VDAFIL	; $48
	DEC	A
	JR	Z,VDU_VDASCR	; $49
	DEC	A
	JP	Z,PPK_STAT	; $4A
	DEC	A
	JP	Z,PPK_FLUSH	; $4B
	DEC	A
	JP	Z,PPK_READ	; $4C
	CALL	PANIC

VDU_VDAINI:
	JR	VDU_INIT	; INITIALIZE

VDU_VDAQRY:
	LD	C,$00		; MODE ZERO IS ALL WE KNOW
	LD	DE,$1850	; 24 ROWS ($18), 80 COLS ($50)
	LD	HL,0		; EXTRACTION OF CURRENT BITMAP DATA NOT SUPPORTED
	XOR	A		; SIGNAL SUCCESS
	RET
	
VDU_VDARES:
	JR	VDU_RESET	; DO THE RESET
	
VDU_VDASCS:
	CALL	PANIC		; NOT IMPLEMENTED (YET)
	
VDU_VDASCP:
	CALL	VDU_XY
	XOR	A
	RET
	
VDU_VDASAT:
	XOR	A
	RET
	
VDU_VDASCO:
	XOR	A
	RET
	
VDU_VDAWRC:
	LD	A,E
	CALL	VDU_PUTCHAR
	XOR	A
	RET
	
VDU_VDAFIL:
	LD	A,E		; FILL CHARACTER GOES IN A
	EX	DE,HL		; FILL LENGTH GOES IN DE
	CALL	VDU_FILL	; DO THE FILL
	XOR	A		; SIGNAL SUCCESS
	RET
	
VDU_VDASCR:
	LD	A,E		; LOAD E INTO A
	OR	A		; SET FLAGS
	RET	Z		; IF ZERO, WE ARE DONE
	PUSH	DE		; SAVE E
	JP	M,VDU_VDASCR1	; E IS NEGATIVE, REVERSE SCROLL
	CALL	VDU_SCROLL	; SCROLL FORWARD ONE LINE
	POP	DE		; RECOVER E
	DEC	E		; DECREMENT IT
	JR	VDU_VDASCR	; LOOP
VDU_VDASCR1:
	CALL	VDU_RSCROLL	; SCROLL REVERSE ONE LINE
	POP	DE		; RECOVER E
	INC	E		; INCREMENT IT
	JR	VDU_VDASCR	; LOOP
;
;======================================================================
; CVDU DRIVER - PRIVATE DRIVER FUNCTIONS
;======================================================================
;
;----------------------------------------------------------------------
; WAIT FOR VDU TO BE READY FOR A DATA READ/WRITE
;----------------------------------------------------------------------
;
VDU_WAITRDY:
   	IN 	A,(VDU_STAT)	; READ STATUS
	OR	A		; SET FLAGS
	RET	M		; IF BIT 7 SET, THEN READY!
	JR	VDU_WAITRDY	; KEEP CHECKING
;
;----------------------------------------------------------------------
; UPDATE SY6845 REGISTERS
;   VDU_WRREG WRITES VALUE IN A TO VDU REGISTER SPECIFIED IN C
;   VDU_WRREGX WRITES VALUE IN DE TO VDU REGISTER PAIR IN C, C+1
;----------------------------------------------------------------------
;
VDU_WRREG:
	PUSH	AF			; SAVE VALUE TO WRITE
	LD	A,C			; SET A TO CVDU REGISTER TO SELECT
	OUT	(VDU_REG),A		; WRITE IT TO SELECT THE REGISTER
	POP	AF			; RECOVER VALUE TO WRITE
	OUT	(VDU_DATA),A		; WRITE IT
	RET
;
VDU_WRREGX:
	LD	A,H			; SETUP MSB TO WRITE
	CALL	VDU_WRREG		; DO IT
	INC	C			; NEXT CVDU REGISTER
	LD	A,L			; SETUP LSB TO WRITE
	JR	VDU_WRREG		; DO IT & RETURN
;
;----------------------------------------------------------------------
; READ SY6845 REGISTERS
;   VDU_RDREG READS VDU REGISTER SPECIFIED IN C AND RETURNS VALUE IN A
;   VDU_RDREGX READS VDU REGISTER PAIR SPECIFIED BY C, C+1 
;     AND RETURNS VALUE IN HL
;----------------------------------------------------------------------
;
VDU_RDREG:
	LD	A,C			; SET A TO CVDU REGISTER TO SELECT
	OUT	(VDU_REG),A		; WRITE IT TO SELECT THE REGISTER
	IN	A,(VDU_DATA)		; READ IT
	RET
;
VDU_RDREGX:
	CALL	VDU_RDREG			; GET VALUE FROM REGISTER IN C
	LD	H,A			; SAVE IN H
	INC	C			; BUMP TO NEXT REGISTER OF PAIR
	CALL	VDU_RDREG			; READ THE VALUE
	LD	L,A			; SAVE IT IN L
	RET
;
;----------------------------------------------------------------------
; SY6845 DISPLAY CONTROLLER CHIP INITIALIZATION
;----------------------------------------------------------------------
;
VDU_CRTINIT:
    	LD 	C,0			; START WITH REGISTER 0
	LD	B,16			; INIT 16 REGISTERS
    	LD 	HL,VDU_INIT6845		; HL = POINTER TO THE DEFAULT VALUES
VDU_CRTINIT1:
	LD	A,(HL)			; GET VALUE
	CALL	VDU_WRREG		; WRITE IT
	INC	HL			; POINT TO NEXT VALUE
	INC	C			; POINT TO NEXT REGISTER
	DJNZ	VDU_CRTINIT1		; LOOP
    	RET
;
;----------------------------------------------------------------------
; SET CURSOR POSITION TO ROW IN D AND COLUMN IN E
;----------------------------------------------------------------------
;
VDU_XY:
	LD	A,E			; SAVE COLUMN NUMBER IN A
	LD	H,D			; SET H TO ROW NUMBER
	LD	E,80			; SET E TO ROW LENGTH
	CALL	MULT8			; MULTIPLY TO GET ROW OFFSET
	LD	E,A			; GET COLUMN BACK
	ADD	HL,DE			; ADD IT IN
	LD	(VDU_POS),HL		; SAVE THE RESULT (DISPLAY POSITION)
	LD	DE,(VDU_OFFSET)		; NOW GET THE BUFFER OFFSET
	ADD	HL,DE			; AND ADD THAT IN
    	LD 	C,14			; CURSOR POSITION REGISTER PAIR
	JP	VDU_WRREGX		; DO IT AND RETURN
;
;----------------------------------------------------------------------
; WRITE VALULE IN A TO CURRENT VDU BUFFER POSTION, ADVANCE CURSOR
;----------------------------------------------------------------------
;
VDU_PUTCHAR:
	LD	B,A		; SAVE THE CHARACTER

	; SET BUFFER WRITE POSITION
	LD	HL,(VDU_OFFSET)
	LD	DE,(VDU_POS)
	ADD	HL,DE
	INC	DE		; INC
	LD	(VDU_POS),DE	; SAVE NEW SCREEN POSITION
	LD	C,18		; UPDATE ADDRESS REGISTER PAIR
	CALL	VDU_WRREGX	; DO IT
	INC	HL		; NEW CURSOR POSITION
	LD	C,14		; CURSOR POSITION REGISTER PAIR
	CALL	VDU_WRREGX	; DO IT
	
    	LD 	A,31		; PREP VDU FOR DATA R/W
    	OUT 	(VDU_REG),A
	CALL	VDU_WAITRDY	; WAIT FOR VDU TO BE READY
	LD	A,B
    	OUT 	(VDU_RAMWR),A	; OUTPUT CHAR TO VDU
	
	RET
;
;----------------------------------------------------------------------
; FILL AREA IN BUFFER WITH SPECIFIED CHARACTER AND CURRENT COLOR/ATTRIBUTE
; STARTING AT THE CURRENT FRAME BUFFER POSITION
;   A: FILL CHARACTER
;   DE: NUMBER OF CHARACTERS TO FILL
;----------------------------------------------------------------------
;
VDU_FILL:
	LD	B,A		; SAVE THE FILL CHARACTER

	; SET FILL START POSITION
	PUSH	DE
	LD	HL,(VDU_OFFSET)
	LD	DE,(VDU_POS)
	ADD	HL,DE
	LD	C,18
	CALL	VDU_WRREGX
	POP	DE

	; FILL LOOP
    	LD 	A,31		; PREP VDU FOR DATA R/W
    	OUT 	(VDU_REG),A
VDU_FILL1:
	LD	A,D		; CHECK NUMBER OF FILL CHARS LEFT
	OR	E			
	RET	Z		; ALL DONE, RETURN
	CALL	VDU_WAITRDY	; WAIT FOR VDU TO BE READY
	LD	A,B
    	OUT 	(VDU_RAMWR),A	; OUTPUT CHAR TO VDU
	DEC	DE		; DECREMENT COUNT
	JR	VDU_FILL1	; LOOP
;
;----------------------------------------------------------------------
; SCROLL ENTIRE SCREEN FORWARD BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
VDU_SCROLL:
	; SCROLL FORWARD BY ADDING ONE ROW TO DISPLAY START ADDRESS
	LD	HL,(VDU_OFFSET)
	LD	DE,80
	ADD	HL,DE
	LD	(VDU_OFFSET),HL
	LD	C,12
	CALL	VDU_WRREGX
	
	; FILL EXPOSED LINE
	LD	HL,(VDU_POS)
	PUSH	HL
	LD	HL,23*80
	LD	(VDU_POS),HL
	LD	DE,80
	LD	A,' '
	CALL	VDU_FILL
	POP	HL
	LD	(VDU_POS),HL
	
	; ADJUST CURSOR POSITION
	LD	HL,(VDU_OFFSET)
	LD	DE,(VDU_POS)
	ADD	HL,DE
	LD	C,14
	JP	VDU_WRREGX
;
;----------------------------------------------------------------------
; REVERSE SCROLL ENTIRE SCREEN BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
VDU_RSCROLL:
	RET
;
;==================================================================================================
;   VDU DRIVER - DATA
;==================================================================================================
;
VDU_POS		.DW 	0		; CURRENT DISPLAY POSITION
VDU_OFFSET	.DW 	0		; CURRENT DISPLAY POSITION
;
;==================================================================================================
;   VDU DRIVER - SY6845 REGISTER INITIALIZATION
;==================================================================================================
;
VDU_INIT6845:
;     DB  07FH, 50H, 60H, 7CH, 19H, 1FH, 19H, 1AH, 78H, 09H, 60H, 09H, 00H, 00H, 00H, 00H
;
					; CCIR 625/50 VERSION (USED IN MOST OF THE WORLD)
					; JUMPER K1 2-3, K2 1-2 FOR 2MHz CHAR CLOCK
	.DB	07FH			; R0 TOTAL NUMBER OF HORIZONTAL CHARACTERS (DETERMINES HSYNC)
	.DB	050H			; R1 NUMBER OF HORIZONTAL CHARACTERS DISPLAYED (80 COLUMNS)
	.DB	060H			; R2 HORIZONTAL SYNC POSITION
	.DB	00CH			; R3 SYNC WIDTHS
	.DB	01EH			; R4 VERTICAL TOTAL (TOTAL CHARS IN A FRAME -1)
	.DB	002H			; R5 VERTICAL TOTAL ADJUST (
	.DB	018H			; R6 VERTICAL DISPLAYED (24 ROWS)
	.DB	01AH			; R7 VERTICAL SYNC
	.DB	078H			; R8 MODE	B7=0 TRANSPARENT UPDATE DURING BLANKING
					;		B6=1 PIN 34 IS UPDATE STROBE
					;		B5=1 DELAY CURSOR 1 CHARACTER
					;		B4=1 DELAY DISPLAY ENABLE 1 CHARACTER
					;		B3=1 TRANSPARENT MEMORY ADDRESSING
					;		B2=0 RAM STRAIGHT BINARY ADDRESSING
					;		B1,B0=0 NON-INTERLACE
	.DB	009H			; R9 SCAN LINE (LINES PER CHAR AND SPACING -1)
	.DB	060H			; R10 CURSOR START RASTER
	.DB	009H			; R11 CURSOR END RASTER
	.DB	00H			; R12 START ADDRESS HI
	.DB	00H			; R13 START ADDRESS LO
	.DB	00H			; R14 CURSOR ADDRESS HI
	.DB	00H			; R15 CURSOR ADDRESS LO
;
; THE CCIR 625/50 TELEVISION STANDARD HAS 625 LINES INTERLACED AT 50 FIELDS PER SECOND.  THIS WORKS 
; OUT AS 50 FIELDS OF 312.5 LINES PER SECOND NON-INTERLACED AS USED HERE.
; HORIZONTAL LINE WIDTH IS 64uS.  FOR A 2 MHz CHARACTER CLOCK (R0+1)/2000000 = 64uS
; NEAREST NUMBER OF LINES IS 312 = (R4+1) * (R9+1) + R5.
; 15625 / 312 = 50.08 FIELDS PER SECOND (NEAR ENOUGH-DGG)
;
