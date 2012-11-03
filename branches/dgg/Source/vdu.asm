;__VDUDRIVER_______________________________________________________________________________________
;
;	VDUDRIVER FOR CBIOS 2.2, PAGED.
;
;	VDU DRIVERS BY:  ANDREW LYNCH
;	KEYBOARD DRIVERS BY: DR  JAMES MOXHAM
;	REMAINDER WRITTEN BY: DAN WERNER -- 11/7/2009
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
; DATA CONSTANTS
;__________________________________________________________________________________________________
;
VDU_RD		 .EQU	0F0h		; READ VDU
VDU_WR		 .EQU	0F1h		; WRITE VDU
VDU_STREG	 .EQU	0F2h		; VDU STATUS/REGISTER
VDU_DATA	 .EQU	0F3h		; VDU DATA REGISTER
;
;__________________________________________________________________________________________________
; BOARD INITIALIZATION
;__________________________________________________________________________________________________
;
VDU_INIT:
	CALL	INITVDU
	CALL	PPK_INIT
	XOR	A
	RET
;	
;__________________________________________________________________________________________________
; CHARACTER I/O (CIO) FUNCTION JUMP TABLE
;__________________________________________________________________________________________________
;
VDU_DISPCIO:
	LD	A,B	; GET REQUESTED FUNCTION
	AND	$0F	; ISOLATE SUB-FUNCTION
	JR	Z,VDU_CIOIN
	DEC	A
	JR	Z,VDU_CIOOUT
	DEC	A
	JR	Z,VDU_CIOIST
	DEC	A
	JR	Z,VDU_CIOOST
	CALL	PANIC
;	
VDU_CIOIN:
	JP	PPK_READ
;
VDU_CIOIST:
	JP	PPK_STAT
;
VDU_CIOOUT:
	JP	VDU_VDAWRC
;
VDU_CIOOST:
	XOR	A
	INC	A
	RET
;	
;__________________________________________________________________________________________________
; VIDEO DISPLAY ADAPTER (VDA) FUNCTION JUMP TABLE
;__________________________________________________________________________________________________
;
VDU_DISPVDA:
	LD	A,B		; GET REQUESTED FUNCTION
	AND	$0F		; ISOLATE SUB-FUNCTION

	JR	Z,VDU_VDAINI
	DEC	A
	JR	Z,VDU_VDAQRY
	DEC	A
	JR	Z,VDU_VDARES
	DEC	A
	JR	Z,VDU_VDASCS
	DEC	A
	JR	Z,VDU_VDASCP
	DEC	A
	JR	Z,VDU_VDASAT
	DEC	A
	JR	Z,VDU_VDASCO
	DEC	A
	JR	Z,VDU_VDAWRC
	DEC	A
	JR	Z,VDU_VDAFIL
	DEC	A
	JR	Z,VDU_VDASCR
	DEC	A
	JP	Z,PPK_STAT
	DEC	A
	JP	Z,PPK_FLUSH
	DEC	A
	JP	Z,PPK_READ
	CALL	PANIC

VDU_VDAINI:
	CALL	INITVDU
	XOR	A
	RET

VDU_VDAQRY:
	CALL	PANIC
	
VDU_VDARES:
	JR	VDU_INIT
	
VDU_VDASCS:
	CALL	PANIC
	
VDU_VDASCP:
	LD	A,E
	LD	(VDU_X),A
	LD	A,D
	LD	(VDU_Y),A
	CALL	VDU_XY
	XOR	A
	RET
	
VDU_VDASAT:
	; FIX: NOT IMPLEMENTED!!!
	CALL	PANIC
	
VDU_VDASCO:
	; NOT SUPPORTED!!!
	CALL	PANIC
	
VDU_VDAWRC:
	; PUSH CHARACTER OUT AT CURRENT POSITION
	LD 	A,31           	; PREP VDU FOR DATA R/W
	OUT 	(VDU_STREG),A
	CALL 	VDU_WAITRDY		; WAIT FOR VDU TO BE READY
	LD	A,E
	OUT 	(VDU_WR),A		; OUTPUT CHAR TO VDU

	; UPDATE CURSOR POSITION TO FOLLOW CHARACTERS
	LD 	HL,(VDU_DISPLAYPOS)	; GET CURRENT DISPLAY POSITION
	INC 	HL			; INCREMENT IT
	LD 	(VDU_DISPLAYPOS),HL	; STORE NEW DISPLAY POSITION
	LD	DE,(VDU_DISPLAY_START)	; GET DISPLAY START
	ADD	HL,DE			; ADD IT TO DISPLAY POSITION
	LD 	A,14			; UPDATE CURSOR POSITION
	CALL 	VDU_HL2WREG_A		; SEND IT

	; RETURN WITH SUCCESS
	XOR	A
	RET
	
VDU_VDAFIL:
    	LD 	A, 31		; PREP VDU FOR DATA R/W
    	OUT 	(VDU_STREG),A
VDU_VDAFIL1:
	LD	A,H		; CHECK NUMBER OF FILL CHARS LEFT
	OR	L			
	JR	Z,VDU_VDAFIL2	; ALL DONE, GO TO COMPLETION
	CALL	VDU_WAITRDY	; WAIT FOR VDU TO BE READY
	LD	A,E
    	OUT 	(VDU_WR), A	; OUTPUT CHAR TO VDU
	DEC	HL		; DECREMENT COUNT
	JR	VDU_VDAFIL1	; LOOP AS NEEDED
VDU_VDAFIL2:
	CALL	VDU_XY		; YES, MOVE CURSOR BACK TO ORIGINAL POSITION
	XOR	A		; RESULT = 0
	RET
	
VDU_VDASCR:
	; FIX: IMPLEMENT REVERSE SCROLLING!!!
	LD	A,E
	OR	A
	RET	Z
	PUSH	DE
	CALL	DO_SCROLL
	POP	DE
	DEC	E
	JR	VDU_VDASCR
;
VDU_WAITRDY:
   	IN 	A,(VDU_STREG)	; READ STATUS
	OR	A		; SET FLAGS
	RET	M		; IF BIT 7 SET, THEN READY!
	JR	VDU_WAITRDY	; KEEP CHECKING
;
;__________________________________________________________________________________________________
; IMBED COMMON PARALLEL PORT KEYBOARD DRIVER
;__________________________________________________________________________________________________
;
#INCLUDE "ppk.asm"
;
;__________________________________________________________________________________________________
; INITIALIZATION
;__________________________________________________________________________________________________
INITVDU:
	CALL	VDUINIT			; INIT VDU   					
	CALL	PERF_ERASE_EOS		; CLEAR SCREEN
	CALL	PERF_CURSOR_HOME	; CURSOR HOME	
	RET
;	
;__PERF_ERASE_EOL__________________________________________________________________________________
;
; 	PERFORM ERASE FROM CURSOR POS TO END OF LINE
;__________________________________________________________________________________________________	
PERF_ERASE_EOL:
	LD	A,(VDU_X)		; GET CURRENT CURSOR X COORD
	LD	C,A			; STORE IT IN C
	LD	A,80			; MOVE CURRENT LINE WIDTH INTO A
	SUB	C			; GET REMAINING POSITIONS ON CURRENT LINE
	LD	B,A			; MOVE IT INTO B
	LD	A,31			; UPDATE TOGGLE VDU CHIP
	OUT	(VDU_STREG),A
PERF_ERASE_EOL_LOOP:		
	CALL	VDU_WAITRDY	 	; WAIT FOR VDU CHIP TO BE READY
	LD	A,32			; MOVE SPACE CHARACTER INTO A
	OUT	(VDU_WR),A    	     	; WRITE IT TO SCREEN, VDU WILL AUTO INC TO NEXT ADDRESS
	DJNZ	PERF_ERASE_EOL_LOOP	; LOOP UNTIL DONE
	CALL	VDU_XY			; MOVE CURSOR BACK TO ORIGINAL POSITION
	RET
;
;__PERF_ERASE_EOS__________________________________________________________________________________
;
; 	PERFORM ERASE FROM CURSOR POS TO END OF SCREEN
;__________________________________________________________________________________________________	
PERF_ERASE_EOS:	
	LD	HL,0780H		; SET SCREEN SIZE INTO HL
	PUSH	HL			; MOVE IT TO DE
	POP	DE
	LD	A,31			; UPDATE TOGGLE VDU CHIP
	OUT	(VDU_STREG),A
PERF_ERASE_EOS_LOOP:		
	CALL	VDU_WAITRDY		; WAIT FOR VDU CHIP TO BE READY
	LD	A, ' '           	; MOVE SPACE CHARACTER INTO A
	OUT	(VDU_WR),A         	; WRITE IT TO SCREEN, VDU WILL AUTO INC TO NEXT ADDRESS
	DEC	DE			; DEC COUNTER
	LD	A,D			; IS COUNTER 0 YET?
	OR	E
	JP	NZ,PERF_ERASE_EOS_LOOP	; NO, LOOP
	CALL	VDU_XY			; YES, MOVE CURSOR BACK TO ORIGINAL POSITION
	RET
;	
;__PERF_CURSOR_HOME________________________________________________________________________________
;
; 	PERFORM CURSOR HOME
;__________________________________________________________________________________________________	
PERF_CURSOR_HOME:
	LD	A,0			; LOAD 0 INTO A
	LD	(VDU_X),A		; SET X COORD
	LD	(VDU_Y),A		; SET Y COORD
	JP	VDU_XY			; MOVE CURSOR TO POSITION
;
;__DO_SCROLL_______________________________________________________________________________________
;
; 	SCROLL THE SCREEN UP ONE LINE
;__________________________________________________________________________________________________			
DO_SCROLL:
	PUSH	AF			; STORE AF	
DO_SCROLL1:
	PUSH	HL			; STORE HL
	PUSH	BC			; STORE BC
	LD 	A, 31            	; TOGGLE VDU FOR UPDATE
	OUT 	(VDU_STREG),A
	CALL 	VDU_WAITRDY	 	; WAIT FOR VDU TO BE READY
	LD 	HL, (VDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	DE,0050H		; SET AMOUNT TO ADD
	ADD	HL,DE			; ADD TO START POS
	LD	(VDU_DISPLAY_START),HL	; STORE DISPLAY START
	LD 	A, 12			; SAVE START OF DISPLAY TO VDU
	CALL 	VDU_HL2WREG_A
	LD	A,23			; SET CURSOR TO BEGINNING OF LAST LINE
	LD	(VDU_Y),A
	LD	A,(VDU_X)
	PUSH	AF			; STORE X COORD
	LD	A,0
	LD	(VDU_X),A
	CALL	VDU_XY			; SET CURSOR POSITION TO BEGINNING OF LINE
	CALL	PERF_ERASE_EOL		; ERASE SCROLLED LINE
	POP	AF			; RESTORE X COORD
	LD	(VDU_X),A
	CALL	VDU_XY			; SET CURSOR POSITION
	POP	BC			; RESTORE BC
	POP	HL			; RESTORE HL
	POP	AF			; RESTORE AF
	RET				;
;    	
;__REVERSE_SCROLL__________________________________________________________________________________
;
; 	SCROLL THE SCREEN DOWN ONE LINE
;__________________________________________________________________________________________________			
REVERSE_SCROLL:
	PUSH	AF			; STORE AF
	PUSH	HL			; STORE HL
	PUSH	BC			; STORE BC
	LD	A, 31            	; TOGGLE VDU FOR UPDATE
	OUT	(VDU_STREG),A
	CALL	VDU_WAITRDY	 	; WAIT FOR VDU TO BE READY
	LD	HL, (VDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	DE,0FFB0H		; SET AMOUNT TO SUBTRACT (TWOS COMPLEMENT 50H)
	ADD	HL,DE			; ADD TO START POS
	LD	(VDU_DISPLAY_START),HL	; STORE DISPLAY START
	LD	A, 12			; SAVE START OF DISPLAY TO VDU
	CALL	VDU_HL2WREG_A
	LD	A,23			; SET CURSOR TO BEGINNING OF LAST LINE
	LD	(VDU_Y),A
	LD	A,(VDU_X)
	PUSH	AF			; STORE X COORD
	LD	A,0
	LD	(VDU_X),A
	CALL	VDU_XY			; SET CURSOR POSITION TO BEGINNING OF LINE
	CALL	PERF_ERASE_EOL		; ERASE SCROLLED LINE
	POP	AF			; RESTORE X COORD
	LD	(VDU_X),A
	CALL	VDU_XY			; SET CURSOR POSITION
	POP	BC			; RESTORE BC
	POP	HL			; RESTORE HL
	POP	AF			; RESTORE AF
	RET
;
;__VDUINIT__________________________________________________________________________________________
;
; 	INITIALIZE VDU
;__________________________________________________________________________________________________			
VDUINIT:
	PUSH 	AF			; STORE AF
	PUSH 	DE			; STORE DE
	PUSH 	HL			; STORE HL

	CALL 	VDU_CRTINIT		; INIT 6545 VDU CHIP	
	LD 	A, 31			; TOGGLE VDU FOR UPDATE
	OUT 	(VDU_STREG),A
	LD	HL,0			; SET-UP START OF DISPLAY 
	LD 	DE, 2048    		; SET-UP DISPLAY SIZE
	LD 	A, 18            	; WRITE HL TO R18 AND R19 (UPDATE ADDRESS)
	CALL 	VDU_HL2WREG_A  		;
	LD 	A, 31            	; TOGGLE VDU FOR UPDATE
	OUT 	(VDU_STREG),A
VDU_CRTSPACELOOP:			;
	CALL 	VDU_WAITRDY	 	; WAIT FOR VDU TO BE READY
	LD 	A, ' '           	; CLEAR SCREEN
	OUT 	(VDU_WR),A         	; SEND SPACE TO DATAPORT
	DEC	DE			; DECREMENT DE
	LD 	A,D			; IS ZERO?
	OR 	E			;
	JP 	NZ, VDU_CRTSPACELOOP	; NO, LOOP
	LD 	A, 31            	; TOGGLE VDU FOR UPDATE
	OUT 	(VDU_STREG),A
	LD 	HL, 0			; SET UP START OF DISPLAY
	LD	(VDU_DISPLAY_START),HL	; STORE DISPLAY START
	LD 	A, 12			; SAVE START OF DISPLAY TO VDU
	CALL 	VDU_HL2WREG_A		;
	POP 	HL			;
	POP 	DE			;
	POP 	AF			;
	CALL	PERF_CURSOR_HOME	; CURSOR HOME	
	CALL	PERF_ERASE_EOS		; CLEAR SCREEN
	RET	
;	
;__VDU_HL2WREG_A___________________________________________________________________________________
;
; 	WRITE VALUE IN HL TO REGISTER IN A
;	A: REGISTER TO UPDATE
;	HL: WORD VALUE TO WRITE
;__________________________________________________________________________________________________			
VDU_HL2WREG_A:
	PUSH 	BC		; STORE BC
    	LD 	C,VDU_STREG	; ADDRESS REGISTER
    	OUT 	(C),A		; SELECT REGISTER (A)
    	INC 	C		; NEXT WRITE IN REGISTER
    	OUT 	(C),H		; WRITE H TO SELECTED REGISTER
    	DEC 	C		; NEXT WRITE SELECT REGISTER
    	INC 	A		; INCREASE REGISTER NUMBER
    	OUT 	(C),A		; SELECT REGISTER (A+1)
    	INC 	C		; NEXT WRITE IN REGISTER
    	OUT 	(C),L		; WRITE L TO SELECTED REGISTER
    	POP 	BC		; RESTORE BC
    	RET
;
;__VDU_CRTINIT_____________________________________________________________________________________
;
; 	INIT VDU CHIP
;__________________________________________________________________________________________________			   	
VDU_CRTINIT:
    	PUSH 	AF			; STORE AF
    	PUSH 	BC			; STORE BC
    	PUSH 	DE			; STORE DE
    	PUSH 	HL			; STORE HL
    	LD 	BC,010F2h         	; B = 16, C = VDU_STREG
    	LD 	HL,VDU_INIT6845  	; HL = POINTER TO THE DEFAULT VALUES
    	XOR 	A               	; A = 0
VDU_CRTINITLOOP:
    	OUT 	(C), A          	; VDU_STREG SET REGISTER
    	INC 	C               	; 0F3h
    	LD 	D,(HL)          	; LOAD THE NEXT DEFAULT VALUE IN D
    	OUT 	(C),D          		; 0F3h ADDRESS
    	DEC 	C               	; VDU_STREG
    	INC 	HL              	; TAB + 1
    	INC 	A               	; REG + 1
    	DJNZ 	VDU_CRTINITLOOP		; LOOP UNTIL DONE
    	POP 	HL			; RESTORE HL
    	POP 	DE			; RESTORE DE
    	POP	BC			; RESTORE BC
    	POP	AF			; RESTORE AF
    	RET
;
;__VDU_XY__________________________________________________________________________________________
;
; 	MOVE CURSOR TO POSITON IN VDU_X AND VDU_Y
;__________________________________________________________________________________________________			
VDU_XY:
	PUSH	AF			; STORE AF

	LD	A,(VDU_Y)		; PLACE Y COORD IN A
	CP	24			; IS 24?
	JP	Z,DO_SCROLL1		; YES, MUST SCROLL

    	PUSH 	BC			; STORE BC
    	PUSH 	DE			; STORE DE
	LD	A,(VDU_X)		;
	LD	H,A			;
    	LD	A,(VDU_Y)		;
    	LD	L,A			;    	
    	PUSH 	HL			; STORE HL
    	LD 	B, A             	; B = Y COORD
    	LD 	DE, 80			; MOVE LINE LENGTH INTO DE
    	LD 	HL, 0			; MOVE 0 INTO HL
    	LD 	A, B             	; A=B
    	CP 	0			; Y=0?
    	JP 	Z, VDU_YLOOPEND  	; THEN DO NOT MULTIPLY BY 80
VDU_YLOOP:              		; HL = 80 * Y
    	ADD 	HL, DE			; HL=HL+DE
    	DJNZ 	VDU_YLOOP		; LOOP 
VDU_YLOOPEND:				;
    	POP 	DE              	; DE = ORG HL
    	LD 	E, D             	; E = X
    	LD 	D, 0             	; D = 0
    	ADD 	HL, DE          	; HL = HL + X
    	LD 	(VDU_DISPLAYPOS), HL	;
	PUSH	HL			;
	POP	DE			;
	LD	HL,(VDU_DISPLAY_START)	;
	ADD	HL,DE			;    	
    	LD 	A, 18			; SET UPDATE ADDRESS IN VDU
    	CALL 	VDU_HL2WREG_A		;
    	LD 	A, 31            	; TOGGLE VDU FOR UPDATE
    	OUT 	(VDU_STREG),A
    	LD 	A, 14            	; SET CURSOR POS
    	CALL 	VDU_HL2WREG_A		;
    	POP 	DE			; RESTORE DE
   	POP 	BC			; RESTORE BC
    	POP 	AF			; RESTORE AF
    	RET
;
;==================================================================================================
;   VDU DRIVER - DATA
;==================================================================================================
;
VDU_X			.DB	0		; CURSOR X
VDU_Y			.DB	0		; CURSOR Y
VDU_DISPLAYPOS		.DW 	0		; CURRENT DISPLAY POSITION
VDU_DISPLAY_START	.DW 	0		; CURRENT DISPLAY POSITION
;
;==================================================================================================
;   VDU DRIVER - 6845 REGISTER INITIALIZATION
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
