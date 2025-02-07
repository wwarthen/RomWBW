;======================================================================
;	VIDEO DRIVER FOR FPGA VGA
;	http://s100computers.com/My%20System%20Pages/FPGA%20Z80%20SBC/FPGA%20Z80%20SBC.htm
;
;	WRITTEN BY: WAYNE WARTHEN -- 9/2/2024
;======================================================================
;
; FPGA VGA EXPOSES A FRAME BUFFER STARTING AT $E000.
; PORT $08 CONTROLS ACCESS TO THE FRAME BUFFER.
;   - WHEN $01, FRAME BUFFER APPEARS AT $E000 IN CPU ADDRESS SPACE
;   - WHEN $00, FRAME BUFFER IS INACCESSIBLE BY CPU
; PORT $C0: SET/GET CURSOR COL
; PORT $C1: SET/GET CURSOR ROW
; PORT $C2: CONTROLS VGA OUTPUT
;  BIT 0: BLUE
;  BIT 1: GREEN
;  BIT 2: RED
;  BIT 3: UNUSED?
;  BIT 4: CURSOR MODE
;  BIT 5: CURSOR BLINK
;  BIT 6: CURSOR ENABLE
;  BIT 7: VGA SIGNAL OUTPUT ENABLE
; PORT $08: BUFFER SELECT, 1=SELECTED
;
; TODO:
;
;======================================================================
; FPGA VGA DRIVER - CONSTANTS
;======================================================================
;
FV_FBUF		.EQU	$E000		; ADDRESS OF FRAME BUFFER
FV_BASE		.EQU	$C0		; BASE I/O ADDRESS
FV_CCOL		.EQU	FV_BASE+0	; CUR COL PORT
FV_CROW		.EQU	FV_BASE+1	; CUR ROW PORT
FV_CTL		.EQU	FV_BASE+2	; VGA CONTROL PORT
;
FV_BUFCTL	.EQU	$08
;
FV_KBDDATA	.EQU	$03		; KBD CTLR DATA PORT
FV_KBDST	.EQU	$02		; KBD CTLR STATUS/CMD PORT
;
FV_ROWS	.EQU	40
FV_COLS	.EQU	80
;
TERMENABLE	.SET	TRUE		; INCLUDE TERMINAL PSEUDODEVICE DRIVER
KBDENABLE	.SET	TRUE		; INCLUDE KBD KEYBOARD SUPPORT
;
		DEVECHO	"FV: IO="
		DEVECHO	FV_BASE
		DEVECHO	", KBD MODE=FV"
		DEVECHO	", KBD IO="
		DEVECHO	FV_KBDDATA
		DEVECHO	"\n"
;
;======================================================================
; FPGA VGA DRIVER - INITIALIZATION
;======================================================================
;
FV_INIT:
	LD	IY,FV_IDAT		; POINTER TO INSTANCE DATA
;
	CALL	NEWLINE			; FORMATTING
	PRTS("FV: IO=0x$")
	LD	A,FV_BASE
	CALL	PRTHEXBYTE
	CALL	FV_PROBE		; CHECK FOR HW PRESENCE
	JR	Z,FV_INIT1		; CONTINUE IF HW PRESENT
;
	; HARDWARE NOT PRESENT
	PRTS(" NOT PRESENT$")
	OR	$FF			; SIGNAL FAILURE
	RET
;
FV_INIT1:
	; RECORD DRIVER ACTIVE
	OR	$FF
	LD	(FV_ACTIVE),A
	; DISPLAY CONSOLE DIMENSIONS
	LD	A,FV_COLS
	CALL	PC_SPACE
	CALL	PRTDECB
	LD	A,'X'
	CALL	COUT
	LD	A,FV_ROWS
	CALL	PRTDECB
	PRTS(" TEXT$")

	; HARDWARE INITIALIZATION
	CALL 	FV_CRTINIT		; SETUP THE FPGA VGA CHIP REGISTERS
	CALL	FV_VDAINI		; INITIALIZE
	CALL	KBD_INIT		; INITIALIZE KEYBOARD DRIVER

	; ADD OURSELVES TO VDA DISPATCH TABLE
	LD	BC,FV_FNTBL		; BC := FUNCTION TABLE ADDRESS
	LD	DE,FV_IDAT		; DE := FPGA VGA INSTANCE DATA PTR
	CALL	VDA_ADDENT		; ADD ENTRY, A := UNIT ASSIGNED

	; INITIALIZE EMULATION
	LD	C,A			; C := ASSIGNED VIDEO DEVICE NUM
	LD	DE,FV_FNTBL		; DE := FUNCTION TABLE ADDRESS
	LD	HL,FV_IDAT		; HL := FPGA VGA INSTANCE DATA PTR
	CALL	TERM_ATTACH		; DO IT

	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
; FPGA VGA DRIVER - VIDEO DISPLAY ADAPTER (VDA) FUNCTIONS
;======================================================================
;
FV_FNTBL:
	.DW	FV_VDAINI
	.DW	FV_VDAQRY
	.DW	FV_VDARES
	.DW	FV_VDADEV
	.DW	FV_VDASCS
	.DW	FV_VDASCP
	.DW	FV_VDASAT
	.DW	FV_VDASCO
	.DW	FV_VDAWRC
	.DW	FV_VDAFIL
	.DW	FV_VDACPY
	.DW	FV_VDASCR
	.DW	FV_STAT
	.DW	FV_FLUSH
	.DW	FV_READ
	.DW	FV_VDARDC
#IF (($ - FV_FNTBL) != (VDA_FNCNT * 2))
	.ECHO	"*** INVALID FV FUNCTION TABLE ***\n"
	!!!!!
#ENDIF

FV_VDAINI:
	; RESET VDA
	CALL	FV_VDARES	; RESET VDA
	LD	HL,0		; ZERO
	LD	(FV_POS),HL	; ... TO POSITION
	LD	A,' '		; BLANK THE SCREEN
	LD	DE,FV_ROWS*FV_COLS	; FILL ENTIRE BUFFER
	CALL	FV_FILL		; DO IT
	LD	DE,0		; ROW = 0, COL = 0
	CALL	FV_XY		; SEND CURSOR TO TOP LEFT
	CALL	FV_SHOWCUR	; NOW SHOW THE CURSOR
	XOR	A		; SIGNAL SUCCESS
	RET

FV_VDAQRY:
	LD	C,$00		; MODE ZERO IS ALL WE KNOW
	LD	D,FV_ROWS	; ROWS
	LD	E,FV_COLS	; COLS
	LD	HL,0		; EXTRACTION OF CURRENT BITMAP DATA NOT SUPPORTED
	XOR	A		; SIGNAL SUCCESS
	RET

FV_VDARES:
	CALL	 FV_CRTINIT
	XOR	A		; SIGNAL SUCCESS
	RET

FV_VDADEV:
	LD	D,VDADEV_FV	; D := DEVICE TYPE
	LD	E,0		; E := PHYSICAL UNIT IS ALWAYS ZERO
	LD	H,0		; H := 0, DRIVER HAS NO MODES
	LD	L,FV_BASE	; L := BASE I/O ADDRESS
	XOR	A		; SIGNAL SUCCESS
	RET

FV_VDASCS:
	SYSCHKERR(ERR_NOTIMPL)	; NOT IMPLEMENTED (YET)
	RET

FV_VDASCP:
	CALL	FV_XY		; SET CURSOR POSITION
	XOR	A		; SIGNAL SUCCESS
	RET

FV_VDASAT:
	; ATTRIBUTES NOT SUPPORTED BY HARDWARE
	XOR	A
	RET

FV_VDASCO:
	; CHARACTER COLOR NOT SUPPORT BY HARDWARE
	XOR	A		; SIGNAL SUCCESS
	RET			; DONE

FV_VDAWRC:
	LD	A,E		; CHARACTER TO WRITE GOES IN A
	CALL	FV_PUTCHAR	; PUT IT ON THE SCREEN
	XOR	A		; SIGNAL SUCCESS
	RET

FV_VDAFIL:
	LD	A,E		; FILL CHARACTER GOES IN A
	EX	DE,HL		; FILL LENGTH GOES IN DE
	CALL	FV_FILL		; DO THE FILL
	XOR	A		; SIGNAL SUCCESS
	RET

FV_VDACPY:
	; LENGTH IN HL, SOURCE ROW/COL IN DE, DEST IS FV_POS
	; BLKCPY USES: HL=SOURCE, DE=DEST, BC=COUNT
	PUSH	HL		; SAVE LENGTH
	CALL	FV_XY2IDX	; ROW/COL IN DE -> SOURCE ADR IN HL
	POP	BC		; RECOVER LENGTH IN BC
	LD	DE,(FV_POS)	; PUT DEST IN DE
	JP	FV_BLKCPY	; DO A BLOCK COPY

FV_VDASCR:
	LD	A,E		; LOAD E INTO A
	OR	A		; SET FLAGS
	RET	Z		; IF ZERO, WE ARE DONE
	PUSH	DE		; SAVE E
	JP	M,FV_VDASCR1	; E IS NEGATIVE, REVERSE SCROLL
	CALL	FV_SCROLL	; SCROLL FORWARD ONE LINE
	POP	DE		; RECOVER E
	DEC	E		; DECREMENT IT
	JR	FV_VDASCR	; LOOP
FV_VDASCR1:
	CALL	FV_RSCROLL	; SCROLL REVERSE ONE LINE
	POP	DE		; RECOVER E
	INC	E		; INCREMENT IT
	JR	FV_VDASCR	; LOOP

FV_STAT:
	IN	A,(FV_KBDST)		; GET STATUS
	AND	$01			; ISOLATE DATA WAITING BIT
	JP	Z,CIO_IDLE		; NO DATA, EXIT VIA IDLE PROCESS
	RET

FV_FLUSH:
	XOR	A			; SIGNAL SUCCESS
	RET

FV_READ:
	CALL	FV_STAT			; GET STATUS
	JR	Z,FV_READ		; LOOP TILL DATA READY
	IN	A,(FV_KBDDATA)		; GET BYTE
	LD	E,A			; PUT IN E FOR RETURN
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE

;----------------------------------------------------------------------
; READ VALUE AT CURRENT VDU BUFFER POSITION
; RETURN E = CHARACTER, B = COLOUR, C = ATTRIBUTES
;----------------------------------------------------------------------

FV_VDARDC:
	CALL	FV_GETCHAR	; GET THE CHARACTER AT CUR CUR POS
	LD	E,A		; PUT IN E
	LD	BC,0		; COLOR AND ATTR NOT SUPPORTED
	XOR	A		; SIGNAL SUCCESS
	RET
;
;======================================================================
; FPGA VGA DRIVER - PRIVATE DRIVER FUNCTIONS
;======================================================================
;
;
;----------------------------------------------------------------------
; PROBE FOR FPGA VGA HARDWARE
;----------------------------------------------------------------------
;
; ON RETURN, ZF SET INDICATES HARDWARE FOUND
;
FV_PROBE:
	XOR	A			; ASSUME H/W EXISTS
	RET
;
;----------------------------------------------------------------------
; CRTC DISPLAY CONTROLLER CHIP INITIALIZATION
;----------------------------------------------------------------------
;
FV_CRTINIT:
	LD	A,%11001111		; WHITE ON BLACK, CURSOR ON, ENABLE OUTPUT
	OUT	(FV_CTL),A		; WRITE TO CONTROL PORT
	XOR	A			; ZERO ACCUM
	RET				; DONE
;
;----------------------------------------------------------------------
; SET CURSOR POSITION TO ROW IN D AND COLUMN IN E
;----------------------------------------------------------------------
;
FV_XY:
	CALL	FV_HIDECUR		; HIDE THE CURSOR
	PUSH	DE			; SAVE NEW POSITION FOR NOW
	CALL	FV_XY2IDX		; CONVERT ROW/COL TO BUF IDX
	LD	(FV_POS),HL		; SAVE THE RESULT (DISPLAY POSITION)
	POP	DE			; RECOVER INCOMING ROW/COL
	LD	A,D			; GET ROW
	OUT	(FV_CROW),A		; SET ROW REGISTER
	LD	A,E			; GET COL
	INC	A			; 1..79,0 (WHY???)
	CP	80			; COL 80?
	JR	NZ, FV_XY1		; SKIP IF NOT
	XOR	A			; ELSE MAKE IT ZERO!
FV_XY1:
	OUT	(FV_CCOL),A		; SET COL REGISTER
	JP	FV_SHOWCUR		; SHOW THE CURSOR AND EXIT
;
;----------------------------------------------------------------------
; CONVERT XY COORDINATES IN DE INTO LINEAR INDEX IN HL
; D=ROW, E=COL
;----------------------------------------------------------------------
;
FV_XY2IDX:
	LD	A,E			; SAVE COLUMN NUMBER IN A
	LD	H,D			; SET H TO ROW NUMBER
	LD	E,FV_COLS		; SET E TO ROW LENGTH
	CALL	MULT8			; MULTIPLY TO GET ROW OFFSET, H * E = HL, E=0, B=0
	LD	E,A			; GET COLUMN BACK
	ADD	HL,DE			; ADD IT IN
	RET				; RETURN
;
;----------------------------------------------------------------------
; SHOW OR HIDE CURSOR
;----------------------------------------------------------------------
;
FV_SHOWCUR:
	LD	A,%11001111		; CONTROL PORT VALUE
	;;;LD	A,%11111111		; CONTROL PORT VALUE
	OUT	(FV_CTL),A		; SET REGISTER
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
FV_HIDECUR:
	LD	A,%11001111		; CONTROL PORT VALUE
	;;;LD	A,%11111111		; CONTROL PORT VALUE
	OUT	(FV_CTL),A		; SET REGISTER
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
;----------------------------------------------------------------------
; (DE)SELECT FRAME BUFFER
;----------------------------------------------------------------------
;
FV_BUFSEL:
	PUSH	AF
	LD	A,$01
	OUT	(FV_BUFCTL),A
	POP	AF
	RET
;
FV_BUFDESEL:
	PUSH	AF
	XOR	A
	OUT	(FV_BUFCTL),A
	POP	AF
	RET
;
;----------------------------------------------------------------------
; WRITE VALUE IN A TO CURRENT VDU BUFFER POSITION, ADVANCE CURSOR
;----------------------------------------------------------------------
;
FV_PUTCHAR:
	; WRITE CHAR AT CURRENT CURSOR POSITION.
	PUSH	AF			; SAVE INCOMING CHAR
	CALL	FV_HIDECUR		; HIDE CURSOR
	CALL	FV_BUFSEL		; SELECT FRAME BUFFER
	POP	AF
	LD	HL,(FV_POS)		; GET CUR BUF POSITION
	LD	DE,FV_FBUF		; START OF FRAME BUF
	ADD	HL,DE			; ADD IT IN
	LD	(HL),A			; PUT THE CHAR
;
	; SET NEW POSITION
	LD	HL,(FV_POS)		; GET POSITION
	INC	HL			; BUMP POSITION
	LD	(FV_POS),HL		; SAVE NEW POSITION
;
	; PUT CUROR IN PLACE
	LD	DE,FV_COLS		; COLS PER LINE
	CALL	DIV16			; BC=ROW, HL=COL
	LD	D,C
	LD	E,L
	CALL	FV_XY
	CALL	FV_BUFDESEL		; DESELECT FRAME BUFFER
	JP	FV_SHOWCUR		; SHOW IT AND RETURN
;
;----------------------------------------------------------------------
; GET CHAR VALUE TO A FROM CURRENT VDU BUFFER POSITION
;----------------------------------------------------------------------
;
FV_GETCHAR:
	XOR	A
	RET
;
;----------------------------------------------------------------------
; FILL AREA IN BUFFER WITH SPECIFIED CHARACTER AND CURRENT COLOR/ATTRIBUTE
; STARTING AT THE CURRENT FRAME BUFFER POSITION
;   A: FILL CHARACTER
;   DE: NUMBER OF CHARACTERS TO FILL
;----------------------------------------------------------------------
;
FV_FILL:
	PUSH	AF			; SAVE INCOMING FILL CHAR
	CALL	FV_HIDECUR		; HIDE CURSOR
	CALL	FV_BUFSEL		; SELECT BUFFER
	LD	HL,(FV_POS)		; CUR POS TO HL
	LD	BC,FV_FBUF		; ADR OF FRAME
	ADD	HL,BC			; ADD IT IN
	POP	AF
	LD	C,A			; FILL CHAR TO C
FV_FILL1:
	LD	A,D			; CHECK FILL
	OR	E			; ... COUNTER
	JR	Z,FV_FILL2		; DONE IF ZERO
	LD	(HL),C			; FILL ONE CHAR
	INC	HL			; BUMP BUF PTR
	DEC	DE			; DEC FILL COUNTER
	JR	FV_FILL1		; LOOP
;
FV_FILL2:
	CALL	FV_BUFDESEL		; DESELECT BUFFER
	JP	FV_SHOWCUR		; EXIT VIA SHOW CURSOR
;
;----------------------------------------------------------------------
; SCROLL ENTIRE SCREEN FORWARD BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
FV_SCROLL:
	CALL	FV_BUFSEL				; SELECT FRAME BUFFER
;
	; COPY "UP" ONE LINE
	LD	HL,FV_FBUF + FV_COLS 			; FROM SECOND LINE
	LD	DE,FV_FBUF				; TO FIRST LINE
	LD	BC,+(FV_ROWS - 1) * FV_COLS		; ALL BUT ONE LINE
	LDIR						; DO IT
;
	; FILL LAST LINE OF SCREEN
	LD	HL,FV_FBUF + ((FV_ROWS - 1) * FV_COLS)	; LAST LINE
	LD	A,' '					; FILL CHAR
	LD	(HL),A					; COPY 1 CHAR
	LD	DE,FV_FBUF + ((FV_ROWS - 1) * FV_COLS) + 1	; SECOND POS IN LAST LINE
	LD	BC,FV_COLS - 1				; COLS PER LINE - 1
	LDIR						; FILL IT
;
	CALL	FV_BUFDESEL				; DESELECT FRAME BUFFER
	RET						; DONE
;
;----------------------------------------------------------------------
; REVERSE SCROLL ENTIRE SCREEN BY ONE LINE (CURSOR POSITION UNCHANGED)
;----------------------------------------------------------------------
;
FV_RSCROLL:
	CALL	FV_BUFSEL				; SELECT FRAME BUFFER
;
	; COPY "DOWN" ONE LINE
	LD	HL,FV_FBUF + (FV_COLS * (FV_ROWS - 1)) - 1 	; FROM END OF SECOND TO LAST LINE
	LD	DE,FV_FBUF + (FV_COLS * FV_ROWS) - 1	; TO END OF LAST LINE
	LD	BC,+(FV_ROWS - 1) * FV_COLS		; ALL BUT ONE LINE
	LDDR						; DO IT IN REVERSE
;
	; FILL FIRST LINE OF SCREEN
	LD	HL,FV_FBUF				; FIRST LINE
	LD	A,' '					; FILL CHAR
	LD	(HL),A					; COPY 1 CHAR
	LD	DE,FV_FBUF + 1				; SECOND POS IN FIRST LINE
	LD	BC,FV_COLS - 1				; COLS PER LINE - 1
	LDIR						; FILL IT
;
	CALL	FV_BUFDESEL				; DESELECT FRAME BUFFER
	RET						; DONE
;
;----------------------------------------------------------------------
; BLOCK COPY BC BYTES FROM HL TO DE
;----------------------------------------------------------------------
;
FV_BLKCPY:

	CALL	FV_BUFSEL				; SELECT FRAME BUFFER
	PUSH	BC					; SAVE LENGTH
	LD	BC,FV_FBUF				; FRAME BUFFER ADR
	ADD	HL,BC					; ADD TO SOURCE
	EX	DE,HL					; EXCHANGE
	ADD	HL,BC					; ADD TO DEST
	EX	DE,HL					; EXCHANGE
	POP	BC					; RECOVER LENGTH
	LDIR						; LDIR DOES THE COPY
	CALL	FV_BUFDESEL				; DESELECT FRAME BUFFER
	RET						; DONE
;
;==================================================================================================
;   FPGA VGA DRIVER - DATA
;==================================================================================================
;
FV_POS		.DW 	0	; CURRENT DISPLAY POSITION
FV_ACTIVE	.DB	FALSE	; FLAG FOR DRIVER ACTIVE
;
;==================================================================================================
;   VGA DRIVER - INSTANCE DATA
;==================================================================================================
;
FV_IDAT:
	.DB	KBDMODE_FV	; FPGA VGA KEYBOARD CONTROLLER
	.DB	FV_KBDST
	.DB	FV_KBDDATA
