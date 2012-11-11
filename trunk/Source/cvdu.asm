;__CVDUDRIVER_______________________________________________________________________________________
;
;	COLOR VDU DRIVER FOR N8VEM PROJECT
;
;	WRITTEN BY: DAN WERNER -- 11/4/2011
;	REMAINDER WRITTEN BY: DAN WERNER -- 11/7/2009
;	ROMWBW ADAPTATION BY: WAYNE WARTHEN -- 11/9/2012
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
; DATA CONSTANTS
;__________________________________________________________________________________________________
;
CVDU_STAT	 .EQU	$E4		; READ M8563 STATUS
CVDU_REG	 .EQU	$E4		; SELECT M8563 REGISTER
CVDU_DATA	 .EQU	$EC		; READ/WRITE M8563 DATA
;
;__________________________________________________________________________________________________
; BOARD INITIALIZATION
;__________________________________________________________________________________________________
;
CVDU_INIT:
	LD	A,14
	LD	(CVDU_COLOR),A
	XOR	A
	LD	(CVDU_X),A
	LD	(CVDU_Y),A
	LD	DE,0
	LD	(CVDU_DISPLAYPOS),DE
	LD	(CVDU_DISPLAY_START),DE
	
	CALL 	CVDU_CRTINIT
	CALL	CVDU_LOADFONT
	LD	A,'#'
	LD	DE,$800
	CALL	CVDU_FILL
	CALL	CVDU_XY
	
	XOR	A
	RET
;	
;__________________________________________________________________________________________________
; CHARACTER I/O (CIO) FUNCTION JUMP TABLE
;__________________________________________________________________________________________________
;
CVDU_DISPCIO:
	LD	A,B	; GET REQUESTED FUNCTION
	AND	$0F	; ISOLATE SUB-FUNCTION
	JR	Z,CVDU_CIOIN
	DEC	A
	JR	Z,CVDU_CIOOUT
	DEC	A
	JR	Z,CVDU_CIOIST
	DEC	A
	JR	Z,CVDU_CIOOST
	CALL	PANIC
;	
CVDU_CIOIN:
	JP	KBD_READ
;
CVDU_CIOIST:
	JP	KBD_STAT
;
CVDU_CIOOUT:
	JP	CVDU_VDAWRC
;
CVDU_CIOOST:
	XOR	A
	INC	A
	RET
;	
;__________________________________________________________________________________________________
; VIDEO DISPLAY ADAPTER (VDA) FUNCTION JUMP TABLE
;__________________________________________________________________________________________________
;
CVDU_DISPVDA:
	LD	A,B		; GET REQUESTED FUNCTION
	AND	$0F		; ISOLATE SUB-FUNCTION

	JR	Z,CVDU_VDAINI
	DEC	A
	JR	Z,CVDU_VDAQRY
	DEC	A
	JR	Z,CVDU_VDARES
	DEC	A
	JR	Z,CVDU_VDASCS
	DEC	A
	JR	Z,CVDU_VDASCP
	DEC	A
	JR	Z,CVDU_VDASAT
	DEC	A
	JR	Z,CVDU_VDASCO
	DEC	A
	JR	Z,CVDU_VDAWRC
	DEC	A
	JR	Z,CVDU_VDAFIL
	DEC	A
	JR	Z,CVDU_VDASCR
	DEC	A
	JP	Z,KBD_STAT
	DEC	A
	JP	Z,KBD_FLUSH
	DEC	A
	JP	Z,KBD_READ
	CALL	PANIC

CVDU_VDAINI:
	CALL	CVDU_INIT
	XOR	A
	RET

CVDU_VDAQRY:
	CALL	PANIC
	
CVDU_VDARES:
	JP	CVDU_INIT
	
CVDU_VDASCS:
	CALL	PANIC
	
CVDU_VDASCP:
	LD	A,E
	LD	(CVDU_X),A
	LD	A,D
	LD	(CVDU_Y),A
	CALL	CVDU_XY
	XOR	A
	RET
	
CVDU_VDASAT:
	; FIX: NOT IMPLEMENTED!!!
	CALL	PANIC
	
CVDU_VDASCO:
	; NOT SUPPORTED!!!
	CALL	PANIC
	
CVDU_VDAWRC:
	LD	A,E
	CALL	CVDU_PUTCHAR

	; RETURN WITH SUCCESS
	XOR	A
	RET
	
CVDU_VDAFIL:
	LD	A,E
	EX	DE,HL
	CALL	CVDU_FILL
	XOR	A		; RESULT = 0
	RET
	
CVDU_VDASCR:
	; FIX: IMPLEMENT REVERSE SCROLLING!!!
	LD	A,E
	OR	A
	RET	Z
	PUSH	DE
	CALL	CVDU_SCROLL
	POP	DE
	DEC	E
	JR	CVDU_VDASCR
;
CVDU_WAITRDY:
;   	IN 	A,(CVDU_STREG)	; READ STATUS
;	OR	A		; SET FLAGS
;	RET	M		; IF BIT 7 SET, THEN READY!
;	JR	CVDU_WAITRDY	; KEEP CHECKING
;	
;__CVDU_CRTINIT_____________________________________________________________________________________
;
; 	INIT 8563 VDU CHIP
;__________________________________________________________________________________________________			   	
CVDU_CRTINIT:
    	LD 	B,$00			; B = 0 
    	LD 	HL,CVDU_INIT8563	; HL = POINTER TO THE DEFAULT VALUES
CVDU_CRTINIT1:
	LD	A,(HL)			; GET VALUE
	CALL	CVDU_WREG		; WRITE IT
	INC	HL
	INC	B
	LD	A,B
	CP	37
	JR	NZ,CVDU_CRTINIT1	; LOOP UNTIL DONE
    	RET
;
;__CVDU_LOADFONT____________________________________________________________________________________
;
; 	LOAD SCREEN FONT
;__________________________________________________________________________________________________			   	   	
CVDU_LOADFONT:
	LD	HL,$2000		; SET FONT LOCATION
   	LD 	B,18			; SET UPDATE ADDRESS IN VDU
    	LD	A,H
    	CALL	CVDU_WREG		; WRITE IT
    	LD 	B,19			; SET UPDATE ADDRESS IN VDU
    	LD	A,L
    	CALL	CVDU_WREG		; WRITE IT
    	LD	BC,$0020		; FONT SIZE
	LD	HL,CVDU_FONTDATA	; FONT DATA
CVDU_LOADFONT1:
	IN	A,(CVDU_STAT)		; READ ADDRESS/STATUS REGISTER
    	BIT	7,A			; IF BIT 7 = 1 THAN AN UPDATE STROBE HAS BEEN OCCURED
    	JR	Z,CVDU_LOADFONT1  	; WAIT FOR READY
	LD	A,31
	OUT	(CVDU_REG),A		; SELECT REGISTER 
CVDU_LOADFONT2:
	IN	A,(CVDU_STAT)		; READ ADDRESS/STATUS REGISTER
	BIT	7,A             	; IF BIT 7 = 1 THAN AN UPDATE STROBE HAS BEEN OCCURED
	JR	Z,CVDU_LOADFONT2  	; WAIT FOR READY
	LD	A,(HL)
	OUT	(CVDU_DATA),A      	; PUT DATA
	INC	HL
	DJNZ	CVDU_LOADFONT1
	DEC	C
	JP	NZ,CVDU_LOADFONT1
	RET
;__CVDU_WREG________________________________________________________________________________________
;
; 	WRITE VALUE IN A TO REGISTER IN B
;	B: REGISTER TO UPDATE
;	A: VALUE TO WRITE
;__________________________________________________________________________________________________			
CVDU_WREG:
	PUSH 	AF			; STORE AF
CVDU_WREG1:	
	IN 	A,(CVDU_STAT)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,CVDU_WREG1	  	; wait for ready
	LD	A,B			;
       	OUT 	(CVDU_REG),A      	; select register 
CVDU_WREG2:	
	IN 	A,(CVDU_STAT)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,CVDU_WREG2	  	; wait for ready
	POP	AF			;
       	OUT 	(CVDU_DATA),A      	; PUT DATA
    	RET
;
;__CVDU_GREG________________________________________________________________________________________
;
; 	GET VALUE FROM REGISTER IN B PLACE IN A
;	B: REGISTER TO GET
;	A: VALUE 
;__________________________________________________________________________________________________			
CVDU_GREG:
	IN 	A,(CVDU_STAT)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,CVDU_GREG	  	; wait for ready
	LD	A,B			;
       	OUT 	(CVDU_REG) , A    	; select register 
CVDU_GREG1:	
	IN 	A,(CVDU_STAT)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,CVDU_GREG1	  	; wait for ready
       	IN 	A,(CVDU_DATA)       	; GET DATA 
    	RET
;
;__CVDU_XY__________________________________________________________________________________________
;
; 	MOVE CURSOR TO POSITON IN CVDU_X AND CVDU_Y
;__________________________________________________________________________________________________			
CVDU_XY:
	LD	A,(CVDU_Y)
	LD	H,A
	LD	DE,80
	CALL	MULT8			; HL := H * E (D & L ARE CLEARED)
	LD	A,(CVDU_X)
	LD	E,A
	ADD	HL,DE
	LD	(CVDU_DISPLAYPOS),HL
	LD	DE,(CVDU_DISPLAY_START)
	ADD	HL,DE
    	LD 	B,14			; SET UPDATE CSR POS IN VDU
    	LD	A,H			;
    	CALL	CVDU_WREG		; WRITE IT
    	INC	B			; SET UPDATE CSR POS IN VDU
    	LD	A,L			;
    	CALL	CVDU_WREG		; WRITE IT
	RET
;
;__CVDU_SCROLL_______________________________________________________________________________________
;
; 	SCROLL THE SCREEN UP ONE LINE
;__________________________________________________________________________________________________			
CVDU_SCROLL:
	; SET MODE TO BLOCK COPY
	LD	A,$80
	LD	B,24
	CALL	CVDU_WREG

	LD	HL,0		; SOURCE
	LD	C,23		; ITERATIONS
CVDU_SCROLL1:
	; BLOCK COPY DESTINATION
    	LD 	B,18			
    	LD	A,H
    	CALL	CVDU_WREG		
    	INC	B			
    	LD	A,L
    	CALL	CVDU_WREG

	LD	DE,80
	ADD	HL,DE

	; BLOCK COPY SOURCE
    	LD 	B,32			
    	LD	A,H			
    	CALL	CVDU_WREG		
    	INC	B			
    	LD	A,L
    	CALL	CVDU_WREG		

CVDU_SCROLL2:
	; BLOCK COPY COUNT
	LD	A,80
	LD	B,30
	CALL	CVDU_WREG

	; LOOP TILL DONE WITH ALL LINES
	DEC	C
	JR	NZ,CVDU_SCROLL2
	
	; SET MODE TO BLOCK WRITE
	XOR	A
	LD	B,24
	CALL	CVDU_WREG
	
	; SET CHARACTER TO WRITE
	LD	A,'='
	LD	B,31
	CALL	CVDU_WREG

	; BLOCK COPY COUNT
	LD	A,80 - 1
	LD	B,30
	CALL	CVDU_WREG
	
	RET
;    	
;__CVDU_RSCROLL__________________________________________________________________________________
;
; 	SCROLL THE SCREEN DOWN ONE LINE
;__________________________________________________________________________________________________			
CVDU_RSCROLL:
	PUSH	AF			; STORE AF	
	PUSH	HL			; STORE HL
	PUSH	BC			; STORE BC
	
    	LD 	B, 24			; GET REGISTER 24	
	CALL	CVDU_GREG		;
	OR	80H			; TURN ON COPY BIT
       	LD	E,A			; PARK IT
     	
	LD 	HL, (CVDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	BC,0730H		;
	ADD  	HL,BC
	LD	D,23			;
CVDU_RSCROLL1:	
    	LD 	B, 18			; SET UPDATE(DEST) POS IN VDU
    	LD	A,H			;
    	CALL	CVDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE(DEST) POS IN VDU
    	LD	A,L			;
    	CALL	CVDU_WREG		; WRITE IT
    	LD	BC,0FFB0H		;
	ADD	HL,BC			;
       	LD 	B, 32			; SET SOURCE POS IN VDU
    	LD	A,H			;
    	CALL	CVDU_WREG		; WRITE IT
    	LD 	B, 33			; SET SOURCE POS IN VDU
    	LD	A,L			;
    	CALL	CVDU_WREG		; WRITE IT
    	
    	LD 	B, 24			; SET COPY
    	LD	A,E			;
    	CALL	CVDU_WREG		; WRITE IT
 	    	
    	LD 	B, 30			; SET AMOUNT TO COPY
    	LD	A,050H			;
    	CALL	CVDU_WREG		; WRITE IT

	DEC	D
    	LD	A,D			;
    	CP	00H			;
      	JP	NZ,CVDU_RSCROLL1	; LOOP TILL DONE

     	
	LD 	HL, (CVDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	BC,0F50H		;
	ADD	HL,BC
	LD	D,23			;
CVDU_RSCROLL2:	
    	LD 	B, 18			; SET UPDATE(DEST) POS IN VDU
    	LD	A,H			;
    	CALL	CVDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE(DEST) POS IN VDU
    	LD	A,L			;
    	CALL	CVDU_WREG		; WRITE IT
    	LD	BC,0FFB0H		;
	ADD	HL,BC			;
       	LD 	B, 32			; SET SOURCE POS IN VDU
    	LD	A,H			;
    	CALL	CVDU_WREG		; WRITE IT
    	LD 	B, 33			; SET SOURCE POS IN VDU
    	LD	A,L			;
    	CALL	CVDU_WREG		; WRITE IT
    	
    	LD 	B, 24			; SET COPY
    	LD	A,E			;
    	CALL	CVDU_WREG		; WRITE IT
 	    	
    	LD 	B, 30			; SET AMOUNT TO COPY
    	LD	A,050H			;
    	CALL	CVDU_WREG		; WRITE IT

	DEC	D
    	LD	A,D			;
    	CP	00H			;
      	JP	NZ,CVDU_RSCROLL2	; LOOP TILL DONE    	
    	LD	A,0			; SET CURSOR TO BEGINNING OF FIRST LINE
    	LD	(CVDU_Y),A		;
    	LD	A,(CVDU_X)		;
   	PUSH	AF			; STORE X COORD
    	LD	A,0			;
    	LD	(CVDU_X),A		;
    	CALL	CVDU_XY			; SET CURSOR POSITION TO BEGINNING OF LINE
    	POP	AF			; RESTORE AF
    	POP	BC			; RESTORE BC
    	CALL	CVDU_ERASE_EOL		; ERASE SCROLLED LINE
	LD	(CVDU_X),A		;
   	CALL	CVDU_XY			; SET CURSOR POSITION
    	POP	HL			; RESTORE HL
    	POP	AF			; RESTORE AF
    	RET				;
;
;__CVDU_ERASE_EOL__________________________________________________________________________________
;
; 	PERFORM ERASE FROM CURSOR POS TO END OF LINE
;       C=DEFAULT COLOR
;__________________________________________________________________________________________________	
CVDU_ERASE_EOL:	
	PUSH	HL
	PUSH	AF
	PUSH	BC

	LD	A,(CVDU_X)		; GET CURRENT CURSOR X COORD
	LD	D,A			; STORE IT IN C
	LD	A,80			; MOVE CURRENT LINE WIDTH INTO A
	SUB	D			; GET REMAINING POSITIONS ON CURRENT LINE
	LD	B,A			; MOVE IT INTO B
CVDU_ERASE_EOL1:		
    	LD 	A, ' '           	; MOVE SPACE CHARACTER INTO A
	CALL	CVDU_PUTCHAR		;
	DJNZ    CVDU_ERASE_EOL1	; LOOP UNTIL DONE
	CALL	CVDU_XY			; MOVE CURSOR BACK TO ORIGINAL POSITION
	POP	BC
	POP	AF
	POP	HL
	RET
;
;__CVDU_ERASE_EOS__________________________________________________________________________________
;
; 	PERFORM ERASE FROM CURSOR POS TO END OF SCREEN
;       C= DEFAULT COLOR
;__________________________________________________________________________________________________	
CVDU_ERASE_EOS:	
	PUSH	HL
	PUSH	AF
	PUSH	BC

    	LD 	HL, (CVDU_DISPLAYPOS)	; GET CURRENT DISPLAY ADDRESS
    	LD 	B, 18			; SET UPDATE CSR POS IN VDU
    	LD	A,H			;
    	CALL	CVDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE CSR POS IN VDU
    	LD	A,L			;
    	CALL	CVDU_WREG		; WRITE IT   		
	LD	DE,0820H		; SET SCREEN SIZE INTO HL
CVDU_ERASE_EOS1:		
    	LD 	A, ' '           	; MOVE SPACE CHARACTER INTO A
	LD	B,31			;
       	CALL	CVDU_WREG	 	; WRITE IT TO SCREEN, VDU WILL AUTO INC TO NEXT ADDRESS
      	DEC	DE			; DEC COUNTER
    	LD 	A,D			; IS COUNTER 0 YET?
    	OR 	E			;
    	JP 	NZ,CVDU_ERASE_EOS1	; NO, LOOP
	LD	DE,0820H		; SET SCREEN SIZE INTO HL
CVDU_ERASE_EOS2:		
    	LD 	A, (CVDU_COLOR)    	; MOVE COLOR INTO A
	LD	B,31			;
       	CALL	CVDU_WREG	 	; WRITE IT TO SCREEN, VDU WILL AUTO INC TO NEXT ADDRESS
      	DEC	DE			; DEC COUNTER
    	LD 	A,D			; IS COUNTER 0 YET?
    	OR 	E			;
    	JP 	NZ,CVDU_ERASE_EOS2	; NO, LOOP
    	
	CALL	CVDU_XY			; YES, MOVE CURSOR BACK TO ORIGINAL POSITION
	POP	BC
	POP	AF
	POP	HL
	RET
;
;__________________________________________________________________________________________________			   	   	
CVDU_PUTCHAR:
; 	PLACE CHARACTER ON SCREEN, ADVANCE CURSOR
;	A: CHARACTER TO OUTPUT
;
	PUSH	AF
	LD	HL,(CVDU_DISPLAY_START)
	LD	DE,(CVDU_DISPLAYPOS)
	ADD	HL,DE
	INC	DE
	LD	(CVDU_DISPLAYPOS),DE
	LD	B,18
	LD	A,H
	CALL	CVDU_WREG
	INC	B
	LD	A,L
	CALL	CVDU_WREG
	POP	AF
	LD	B,31
	CALL	CVDU_WREG
	PUSH	HL
	INC	HL
	LD	B,14
	LD	A,H
	CALL	CVDU_WREG
	INC	B
	LD	A,L
	CALL	CVDU_WREG
	POP	HL
	LD	DE,$800
	ADD	HL,DE
	LD	B,18
	LD	A,H
	CALL	CVDU_WREG
	INC	B
	LD	A,L
	CALL	CVDU_WREG
	LD	A,(CVDU_COLOR)
	LD	B,31
	CALL	CVDU_WREG
	RET
;__________________________________________________________________________________________________			   	   	
CVDU_FILL:
;
; FILL AREA IN BUFFER WITH SPECIFIED CHARACTER AND CURRENT COLOR/ATTRIBUTE
; STARTING WITH THE CURRENT FRAME BUFFER POSITION
;   A: FILL CHARACTER
;   DE: NUMBER OF CHARACTERS TO FILL
;
	PUSH	AF
	PUSH	DE
	LD	HL,(CVDU_DISPLAY_START)
	LD	DE,(CVDU_DISPLAYPOS)
	ADD	HL,DE
	LD	B,18
	LD	A,H
	CALL	CVDU_WREG
	INC	B
	LD	A,L
	CALL	CVDU_WREG
	POP	DE
	POP	AF
	PUSH	DE
	LD	C,A
CVDU_FILL1:
	LD	A,C
	LD	B,31
	CALL	CVDU_WREG
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,CVDU_FILL1

	LD	DE,$800
	ADD	HL,DE
	POP	DE
	LD	B,18
	LD	A,H
	CALL	CVDU_WREG
	INC	B
	LD	A,L
	CALL	CVDU_WREG
	LD	A,(CVDU_COLOR)
	LD	C,A
CVDU_FILL2:
	LD	A,C
	LD	B,31
	CALL	CVDU_WREG
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,CVDU_FILL2

	RET
;
;==================================================================================================
;   VDU DRIVER - DATA
;==================================================================================================
;
CVDU_X			.DB	0	; CURSOR X
CVDU_Y			.DB	0	; CURSOR Y
CVDU_COLOR		.DB	0	; CURRENT COLOR
CVDU_DISPLAYPOS		.DW 	0	; CURRENT DISPLAY POSITION
CVDU_DISPLAY_START	.DW 	0	; CURRENT DISPLAY POSITION
;
;==================================================================================================
;   VDU DRIVER - 8563 REGISTER INITIALIZATION
;==================================================================================================
;
; EGA 720X368  9-BIT CHARACTERS
;   - requires 16.257Mhz oscillator frequency
;
CVDU_INIT8563:
	.DB	97		; 0: hor. total - 1
	.DB	80		; 1: hor. displayed
	.DB	85		; 2: hor. sync position
	.DB	$14		; 3: vert/hor sync width 		or 0x4F -- MDA
	.DB	26		; 4: vert total
	.DB	2		; 5: vert total adjust
	.DB	25		; 6: vert. displayed
	.DB	26		; 7: vert. sync postition
	.DB	0		; 8: interlace mode
	.DB	13		; 9: char height - 1
	.DB	(2<<5)+12	; 10: cursor mode, start line
	.DB	13		; 11: cursor end line
	.DB	0		; 12: display start addr hi
	.DB	0		; 13: display start addr lo
	.DB	7		; 14: cursor position hi
	.DB	128		; 15: cursor position lo
	.DB	1		; 16: light pen vertical
	.DB	1		; 17: light pen horizontal
	.DB	0		; 18: update address hi
	.DB	0		; 19: update address lo
	.DB	8		; 20: attribute start addr hi
	.DB	0		; 21: attribute start addr lo
	.DB	$89		; 22: char hor size cntrl 		0x78
	.DB	13		; 23: vert char pixel space - 1, increase to 13 with new font
	.DB	0		; 24: copy/fill, reverse, blink rate; vertical scroll
	.DB	$48		; 25: gr/txt, color/mono, pxl-rpt, dbl-wide; horiz. scroll
	.DB	$E0		; 26: fg/bg colors (monochr)
	.DB	0		; 27: row addr display incr
	.DB	$20+(1<<4)	; 28: char set addr; RAM size (64/16)
	.DB	13		; 29: underline position
	.DB	0		; 30: word count - 1
	.DB	0		; 31: data
	.DB	0		; 32: block copy src hi
	.DB	0		; 33: block copy src lo
	.DB	6		; 34: display enable begin
	.DB	88		; 35: display enable end
	.DB	0		; 36: refresh rate

;	.DB	126,80,102,73,32,224,25,29,252,231,160,231,0,0,7,128
;	.DB	18,23,15,208,8,32,120,232,32,71,240,0,47,231,79,7,15,208,125,100,245
;
;==================================================================================================
;   CVDU DRIVER - FONT DATA
;==================================================================================================
;
#INCLUDE "cvdu_font.asm"