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
	CALL 	CVDU_CRTINIT
	CALL	CVDU_LOADFONT

CVDU_RESET:
	LD	A,14
	LD	(CVDU_ATTR),A
	XOR	A
	LD	(CVDU_X),A
	LD	(CVDU_Y),A
	LD	DE,0
	LD	(CVDU_DISPLAYPOS),DE
	
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
	LD	A,B		; GET REQUESTED FUNCTION
	AND	$0F		; ISOLATE SUB-FUNCTION
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

	JR	Z,CVDU_VDAINI	; $40
	DEC	A
	JR	Z,CVDU_VDAQRY	; $41
	DEC	A
	JR	Z,CVDU_VDARES	; $42
	DEC	A
	JR	Z,CVDU_VDASCS	; $43
	DEC	A
	JR	Z,CVDU_VDASCP	; $44
	DEC	A
	JR	Z,CVDU_VDASAT	; $45
	DEC	A
	JR	Z,CVDU_VDASCO	; $46
	DEC	A
	JR	Z,CVDU_VDAWRC	; $47
	DEC	A
	JR	Z,CVDU_VDAFIL	; $48
	DEC	A
	JR	Z,CVDU_VDASCR	; $49
	DEC	A
	JP	Z,KBD_STAT	; $4A
	DEC	A
	JP	Z,KBD_FLUSH	; $4B
	DEC	A
	JP	Z,KBD_READ	; $4C
	CALL	PANIC

CVDU_VDAINI:
	CALL	CVDU_INIT	; INITIALIZE
	XOR	A		; SIGNAL SUCCESS
	RET

CVDU_VDAQRY:
	LD	C,$00		; MODE ZERO IS ALL WE KNOW
	LD	DE,$1950	; 25 ROWS ($19), 80 COLS ($50)
	LD	HL,0		; EXTRACTION OF CURRENT BITMAP DATA NOT SUPPORTED YET
	XOR	A		; SIGNAL SUCCESS
	RET
	
CVDU_VDARES:
	JP	CVDU_RESET
	
CVDU_VDASCS:
	CALL	PANIC		; NOT IMPLEMENTED (YET)
	
CVDU_VDASCP:
	LD	A,E		; GET E
	LD	(CVDU_X),A	; SAVE AS COLUMN (X)
	LD	A,D		; GET D
	LD	(CVDU_Y),A	; SAVE AS ROW (Y)
	CALL	CVDU_XY		; MOVE THE CURSOR
	XOR	A		; SIGNAL SUCCESS
	RET
	
CVDU_VDASAT:
	; INCOMING IS:  -----RUB (R=REVERSE, U=UNDERLINE, B=BLINK)
	; TRANSFORM TO: -RUB----
	LD	A,E		; GET THE INCOMING ATTRIBUTE
	RLCA			; TRANSLATE TO OUR DESIRED BIT
	RLCA			; "
	RLCA			; "
	RLCA			; "
	AND	%01110000	; REMOVE ANYTHING EXTRANEOUS
	LD	E,A		; SAVE IT IN E
	LD	A,(CVDU_ATTR)	; GET CURRENT ATTRIBUTE SETTING
	AND	%10001111	; CLEAR OUT OLD ATTRIBUTE BITS
	OR	E		; STUFF IN THE NEW ONES
	LD	A,(CVDU_ATTR)	; AND SAVE THE RESULT
	XOR	A		; SIGNAL SUCCESS
	RET
	
CVDU_VDASCO:
	; INCOMING IS:  IBGRIBGR (I=INTENSITY, B=BLUE, G=GREEN, R=RED)
	; TRANSFORM TO: ----RGBI (DISCARD BACKGROUND COLOR IN HIGH NIBBLE)
	XOR	A		; CLEAR A
	LD	B,4		; LOOP 4 TIMES (4 BITS)
CVDU_VDASCO1:
	RRC	E		; ROTATE LOW ORDER BIT OUT OF E INTO CF
	RLA			; ROTATE CF INTO LOW ORDER BIT OF A
	DJNZ	CVDU_VDASCO1	; DO FOUR BITS OF THIS
	LD	E,A		; SAVE RESULT IN E
	LD	A,(CVDU_ATTR)	; GET CURRENT VALUE INTO A
	AND	%11110000	; CLEAR OUT OLD COLOR BITS
	OR	E		; STUFF IN THE NEW ONES
	LD	A,(CVDU_ATTR)	; AND SAVE THE RESULT
	XOR	A		; SIGNAL SUCCESS
	RET
	
CVDU_VDAWRC:
	LD	A,E		; CHARACTER TO WRITE GOES IN A
	CALL	CVDU_PUTCHAR	; PUT IT ON THE SCREEN
	XOR	A		; SIGNAL SUCCESS
	RET
	
CVDU_VDAFIL:
	LD	A,E		; FILL CHARACTER GOES IN A
	EX	DE,HL		; FILL LENGTH GOES IN DE
	CALL	CVDU_FILL	; DO THE FILL
	XOR	A		; SIGNAL SUCCESS
	RET
	
CVDU_VDASCR:
	LD	A,E		; LOAD E INTO A
	OR	A		; SET FLAGS
	RET	Z		; IF ZERO, WE ARE DONE
	PUSH	DE		; SAVE E
	JP	M,CVDU_VDASCR1	; E IS NEGATIVE, REVERSE SCROLL
	CALL	CVDU_SCROLL	; SCROLL FORWARD ONE LINE
	POP	DE		; RECOVER E
	DEC	E		; DECREMENT IT
	JR	CVDU_VDASCR	; LOOP
CVDU_VDASCR1:
	CALL	CVDU_RSCROLL	; SCROLL REVERSE ONE LINE
	POP	DE		; RECOVER E
	INC	E		; INCREMENT IT
	JR	CVDU_VDASCR	; LOOP
;
;__CVDU_CRTINIT_____________________________________________________________________________________
;
; 	INIT 8563 VDU CHIP
;
CVDU_CRTINIT:
    	LD 	C,0			; START WITH REGISTER 0
	LD	B,37			; INIT 37 REGISTERS
    	LD 	HL,CVDU_INIT8563	; HL = POINTER TO THE DEFAULT VALUES
CVDU_CRTINIT1:
	LD	A,(HL)			; GET VALUE
	CALL	CVDU_WR			; WRITE IT
	INC	HL			; POINT TO NEXT VALUE
	INC	C			; POINT TO NEXT REGISTER
	DJNZ	CVDU_CRTINIT1		; LOOP
    	RET
;
;__CVDU_LOADFONT____________________________________________________________________________________
;
; 	LOAD SCREEN FONT
;__________________________________________________________________________________________________			   	   	
CVDU_LOADFONT:
	LD	HL,$2000		; START OF FONT BUFFER
	LD	C,18			; SET BUFFER POINTER
	CALL	CVDU_WRX		; DO IT

	LD	HL,CVDU_FONTDATA	; POINTER TO FONT DATA
	LD	DE,$2000		; LENGTH OF FONT DATA
	LD	C,31			; WRITE DATA
CVDU_LOADFONT1:
	LD	A,(HL)			; LOAD NEXT BYTE OF FONT DATA
	CALL	CVDU_WR			; WRITE IT
	INC	HL			; INCREMENT FONT DATA POINTER
	DEC	DE			; DECREMENT LOOP COUNTER
	LD	A,D			; CHECK DE...
	OR	E			; FOR COUNTER EXHAUSTED
	JR	NZ,CVDU_LOADFONT1	; LOOP TILL DONE
	RET
;
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
;__CVDU_WR__________________________________________________________________________________________
;
; 	WRITE VALUE IN A TO REGISTER IN C
;__________________________________________________________________________________________________			
CVDU_WR:
	PUSH	AF			; SAVE VALUE TO WRITE
	LD	A,C			; SET A TO CVDU REGISTER TO SELECT
	OUT	(CVDU_REG),A		; WRITE IT TO SELECT THE REGISTER
CVDU_WR1:
	IN	A,(CVDU_STAT)		; GET CVDU STATUS
	BIT	7,A			; CHECK BIT 7
	JR	Z,CVDU_WR1		; LOOP WHILE NOT READY (BIT 7 NOT SET)
	POP	AF			; RESTORE VALUE TO WRITE
	OUT	(CVDU_DATA),A		; WRITE IT
	RET
;
;__CVDU_WRX_________________________________________________________________________________________
;
; 	WRITE VALUE IN HL TO REGISTER PAIR C/C+1
;__________________________________________________________________________________________________			
CVDU_WRX:
	LD	A,H			; SETUP MSB TO WRITE
	CALL	CVDU_WR			; DO IT
	INC	C			; NEXT CVDU REGISTER
	LD	A,L			; SETUP LSB TO WRITE
	JR	CVDU_WR			; DO IT & RETURN
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
;
CVDU_XY:
	LD	A,(CVDU_Y)		; GET CURRENT ROW (Y)
	LD	H,A			; PLACE IN Y
	LD	DE,80			; DE := 80 (ROW LENGTH)
	CALL	MULT8			; HL := H * E (D IS CLEARED)
	LD	A,(CVDU_X)		; GET CURRENT COLUMN (X)
	LD	E,A			; PUT IN E, D IS ALREADY 0
	ADD	HL,DE			; ADD IN COLUMN OFFSET
	LD	(CVDU_DISPLAYPOS),HL	; SAVE THE RESULT (DISPLAY POSITION)
    	LD 	C,14			; FUNCTION TO SET CURSOR POSITION
	JP	CVDU_WRX		; DO IT AND RETURN
;
;__________________________________________________________________________________________________			   	   	
CVDU_PUTCHAR:
;
; PLACE CHARACTER ON SCREEN, ADVANCE CURSOR
; A: CHARACTER TO OUTPUT
;
	PUSH	AF			; SAVE CHARACTER
	
	; SET MEMORY LOCATION FOR CHARACTER
	LD	HL,(CVDU_DISPLAYPOS)
	LD	C,18
	CALL	CVDU_WRX

	; PUT THE CHARACTER THERE
	POP	AF
	LD	C,31
	CALL	CVDU_WR

	; BUMP THE CURSOR FORWARD
	INC	HL
	LD	(CVDU_DISPLAYPOS),HL
	LD	C,14
	CALL	CVDU_WRX

	; SET MEMORY LOCATION FOR ATTRIBUTE
	LD	DE,$800 - 1
	ADD	HL,DE
	LD	C,18
	CALL	CVDU_WRX
	
	; PUT THE ATTRIBUTE THERE
	LD	A,(CVDU_ATTR)
	LD	C,31
	JP	CVDU_WR
;
;__________________________________________________________________________________________________			   	   	
CVDU_FILL:
;
; FILL AREA IN BUFFER WITH SPECIFIED CHARACTER AND CURRENT COLOR/ATTRIBUTE
; STARTING WITH THE CURRENT FRAME BUFFER POSITION
;   A: FILL CHARACTER
;   DE: NUMBER OF CHARACTERS TO FILL
;
	PUSH	DE			; SAVE FILL COUNT
	LD	HL,(CVDU_DISPLAYPOS)	; SET CHARACTER BUFFER POSITION TO FILL
	PUSH	HL			; SAVE BUF POS
	CALL	CVDU_FILL1		; DO THE CHARACTER FILL
	POP	HL			; RECOVER BUF POS
	LD	DE,$800			; INCREMENT FOR ATTRIBUTE FILL
	ADD	HL,DE			; HL := BUF POS FOR ATTRIBUTE FILL
	POP	DE			; RECOVER FILL COUNT
	LD	A,(CVDU_ATTR)		; SET ATTRIBUTE VALUE FOR ATTRIBUTE FILL
	JR	CVDU_FILL1		; DO ATTRIBUTE FILL AND RETURN
	
CVDU_FILL1:
	; SAVE FILL VALUE
	LD	B,A			; SAVE REQUESTED FILL VALUE
	
	; CHECK FOR VALID FILL LENGTH
	LD	A,D			; LOAD D
	OR	E			; OR WITH E
	RET	Z			; BAIL OUT IF LENGTH OF ZERO SPECIFIED
	
	; POINT TO BUFFER LOCATION TO START FILL
	LD	C,18			; USE CVDU REG 18/19 TO SET BUF LOC
	CALL	CVDU_WRX		; DO IT
	
	; SET MODE TO BLOCK WRITE
	XOR	A			; WRITE VALUE 0 (BIT 7 CLR FOR BLOCK WRITE)
	LD	C,24			; TO CVDU REG 24
	CALL	CVDU_WR			; DO IT

	; SET CHARACTER TO WRITE (WRITES ONE CHARACTER)
	LD	A,B			; RECOVER FILL VALUE
	LD	C,31			; USE CVDU REG 31 TO WRITE VALUE
	CALL	CVDU_WR			; DO IT
	DEC	DE			; REFLECT ONE CHARACTER WRITTEN
	
	; LOOP TO DO BULK WRITE
	EX	DE,HL			; NOW USE HL FOR COUNT
	LD	C,30			; BYTE COUNT REGISTER
CVDU_FILL2:
	LD	A,H			; GET HIGH BYTE
	OR	A			; SET FLAGS
	LD	A,L			; PRESUME WE WILL WRITE L COUNT BYTES
	JR	Z,CVDU_FILL3		; IF H WAS ZERO, READY TO WRITE L BYTES
	LD	A,$FF			; H WAS > 0, WRITE 255 BYTES
CVDU_FILL3:
	CALL	CVDU_WR			; DO IT
	LD	D,0			; CLEAR D
	LD	E,A			; SET E TO BYTES WRITTEN
	SBC	HL,DE			; SUBTRACT FROM HL
	RET	Z			; IF ZERO, WE ARE DONE
	JR	CVDU_FILL2		; OTHERWISE, WRITE SOME MORE
;
;__CVDU_SCROLL_______________________________________________________________________________________
;
; 	SCROLL THE SCREEN FORWARD ONE LINE
;
CVDU_SCROLL:
	; SCROLL THE CHARACTER BUFFER
	LD	A,'='			; CHAR VALUE TO FILL NEW EXPOSED LINE
	LD	HL,0			; SOURCE ADDRESS OF CHARACER BUFFER
	CALL	CVDU_SCROLL1		; SCROLL CHARACTER BUFFER
	
	; SCROLL THE ATTRIBUTE BUFFER
	LD	A,(CVDU_ATTR)		; ATTRIBUTE VALUE TO FILL NEW EXPOSED LINE
	LD	HL,$800			; SOURCE ADDRESS OF ATTRIBUTE BUFFER
	JR	CVDU_SCROLL1		; SCROLL ATTRIBUTE BUFFER

CVDU_SCROLL1:
	PUSH	AF			; SAVE FILL VALUE FOR NOW
	
	; SET MODE TO BLOCK COPY
	LD	A,$80			; SET BIT 7 FOR BLOCK COPY
	LD	C,24			; IN CVDU REG 24
	CALL	CVDU_WR			; DO IT

	; SET INITIAL BLOCK COPY DESTINATION (USING HL PASSED IN)
    	LD 	C,18			; SET DESTINATION ADDRESS IN REG 18/19
	CALL	CVDU_WRX		; DO IT

	; COMPUTE SOURCE (INCREMENT ONE ROW)
	LD	DE,80			; SOURCE ADDRESS IS ONE ROW PAST DESTINATION
	ADD	HL,DE			; ADD IT TO BUF ADDRESS

	; SET INITIAL BLOCK COPY SOURCE
    	LD 	C,32			; PUT THE SOURCE ADDRESS IN CVDU REG 32
	CALL	CVDU_WRX		; DO IT

	LD	B,23			; ITERATIONS (23 ROWS)
CVDU_SCROLL2:
	; SET BLOCK COPY COUNT (WILL EXECUTE COPY)
	LD	A,80			; COPY 80 BYTES
	LD	C,30			; PUT LENGTH TO COPY IN REG 30
	CALL	CVDU_WR			; DO IT

	; LOOP TILL DONE WITH ALL LINES
	DJNZ	CVDU_SCROLL2		; REPEAT FOR ALL LINES
	
	; SET MODE TO BLOCK WRITE TO CLEAR NEW LINE EXPOSED BY SCROLL
	XOR	A			; CLR BIT 7
	LD	C,24			; OF CVDU REG 24
	CALL	CVDU_WR
	
	; SET CHARACTER TO WRITE
	POP	AF	; RESTORE THE FILL VALUE PASSED IN
	LD	C,31
	CALL	CVDU_WR

	; SET BLOCK WRITE COUNT (WILL EXECUTE THE WRITE)
	LD	A,80 - 1
	LD	C,30
	CALL	CVDU_WR
	
	RET
;
;__CVDU_RSCROLL_______________________________________________________________________________________
;
; 	SCROLL THE SCREEN REVERSE ONE LINE
;
CVDU_RSCROLL:
	; SCROLL THE CHARACTER BUFFER
	LD	A,'='			; CHAR VALUE TO FILL NEW EXPOSED LINE
	LD	HL,80*23		; SOURCE ADDRESS OF CHARACER BUFFER (LINE 24)
	CALL	CVDU_RSCROLL1		; SCROLL CHARACTER BUFFER
	
	; SCROLL THE ATTRIBUTE BUFFER
	LD	A,(CVDU_ATTR)		; ATTRIBUTE VALUE TO FILL NEW EXPOSED LINE
	LD	HL,$800+(80*23)		; SOURCE ADDRESS OF ATTRIBUTE BUFFER (LINE 24)
	JR	CVDU_RSCROLL1		; SCROLL ATTRIBUTE BUFFER

CVDU_RSCROLL1:
	PUSH	AF			; SAVE FILL VALUE FOR NOW
	
	; SET MODE TO BLOCK COPY
	LD	A,$80			; SET BIT 7 FOR BLOCK COPY
	LD	C,24			; IN CVDU REG 24
	CALL	CVDU_WR			; DO IT

	LD	B,23			; ITERATIONS (23 ROWS)
CVDU_RSCROLL2:

	; SET BLOCK COPY DESTINATION (USING HL PASSED IN)
    	LD 	C,18			; SET DESTINATION ADDRESS IN REG 18/19
	CALL	CVDU_WRX		; DO IT

	; COMPUTE SOURCE (DECREMENT ONE ROW)
	LD	DE,80			; SOURCE ADDRESS IS ONE ROW PAST DESTINATION
	SBC	HL,DE			; SUBTRACT IT FROM BUF ADDRESS

	; SET BLOCK COPY SOURCE
    	LD 	C,32			; PUT THE SOURCE ADDRESS IN CVDU REG 32
	CALL	CVDU_WRX		; DO IT

	; SET BLOCK COPY COUNT (WILL EXECUTE COPY)
	LD	A,80			; COPY 80 BYTES
	LD	C,30			; PUT LENGTH TO COPY IN REG 30
	CALL	CVDU_WR			; DO IT

	; LOOP TILL DONE WITH ALL LINES
	DJNZ	CVDU_RSCROLL2		; REPEAT FOR ALL LINES
	
	; SET MODE TO BLOCK WRITE TO CLEAR NEW LINE EXPOSED BY SCROLL
	XOR	A			; CLR BIT 7
	LD	C,24			; OF CVDU REG 24
	CALL	CVDU_WR
	
	; SET CHARACTER TO WRITE
	POP	AF	; RESTORE THE FILL VALUE PASSED IN
	LD	C,31
	CALL	CVDU_WR

	; SET BLOCK WRITE COUNT (WILL EXECUTE THE WRITE)
	LD	A,80 - 1
	LD	C,30
	CALL	CVDU_WR
	
	RET
;
;==================================================================================================
;   VDU DRIVER - DATA
;==================================================================================================
;
CVDU_X			.DB	0	; CURSOR X
CVDU_Y			.DB	0	; CURSOR Y
CVDU_ATTR		.DB	0	; CURRENT COLOR
CVDU_DISPLAYPOS		.DW 	0	; CURRENT DISPLAY POSITION
CVDU_DISPLAY_START	.DW 	0	; CURRENT DISPLAY POSITION
;
; ATTRIBUTE ENCODING:
;   BIT 7: ALTERNATE CHARACTER SET
;   BIT 6: REVERSE VIDEO
;   BIT 5: UNDERLINE
;   BIT 4: BLINK
;   BIT 3: RED
;   BIT 2: GREEN
;   BIT 1: BLUE
;   BIT 0: INTENSITY
;
;==================================================================================================
;   VDU DRIVER - 8563 REGISTER INITIALIZATION
;==================================================================================================
;
; Reg	Hex	Bit 7	Bit 6	Bit 5	Bit 4	Bit 3	Bit 2	Bit 1	Bit 0	Description
; 0	$00	HT7	HT6	HT5	HT4	HT3	HT2	HT1	HT0	Horizontal Total
; 1	$01	HD7	HD6	HD5	HD4	HD3	HD2	HD1	HD0	Horizontal Displayed
; 2	$02	HP7	HP6	HP5	HP4	HP3	HP2	HP1	HP0	Horizontal Sync Position
; 3	$03	VW3	VW2	VW1	VW0	HW3	HW2	HW1	HW0	Vertical/Horizontal Sync Width
; 4	$04	VT7	VT6	VT5	VT4	VT3	VT2	VT1	VT0	Vertical Total
; 5	$05	--	--	--	VA4	VA3	VA2	VA1	VA0	Vertical Adjust
; 6	$06	VD7	VD6	VD5	VD4	VD3	VD2	VD1	VD0	Vertical Displayed
; 7	$07	VP7	VP6	VP5	VP4	VP3	VP2	VP1	VP0	Vertical Sync Position
; 8	$08	--	--	--	--	--	--	IM1	IM0	Interlace Mode
; 9	$09	--	--	--	--	CTV4	CTV3	CTV2	CTV1	Character Total Vertical
; 10	$0A	--	CM1	CM0	CS4	CS3	CS2	CS1	CS0	Cursor Mode, Start Scan
; 11	$0B	--	--	--	CE4	CE3	CE2	CE1	CE0	Cursor End Scan Line
; 12	$0C	DS15	DS14	DS13	DS12	DS11	DS10	DS9	DS8	Display Start Address High Byte
; 13	$0D	DS7	DS6	DS5	DS4	DS3	DS2	DS1	DS0	Display Start Address Low Byte
; 14	$0E	CP15	CP14	CP13	CP12	CP11	CP10	CP9	CP8	Cursor Position High Byte
; 15	$0F	CP7	CP6	CP5	CP4	CP3	CP2	CP1	CP0	Cursor Position Low Byte
; 16	$10	LPV7	LPV6	LPV5	LPV4	LPV3	LPV2	LPV1	LPV0	Light Pen Vertical Position
; 17	$11	LPH7	LPH6	LPH5	LPH4	LPH3	LPH2	LPH1	LPH0	Light Pen Horizontal Position
; 18	$12	UA15	UA14	UA13	UA12	UA11	UA10	UA9	UA8	Update Address High Byte
; 19	$13	UA7	UA6	UA5	UA4	UA3	UA2	UA1	UA0	Update Address Low Byte
; 20	$14	AA15	AA14	AA13	AA12	AA11	AA10	AA9	AA8	Attribute Start Address High Byte
; 21	$15	AA7	AA6	AA5	AA4	AA3	AA2	AA1	AA0	Attribute Start Address Low Byte
; 22	$16	CTH3	CTH2	CTH1	CTH0	CDH3	CDH2	CDH1	CDH0	Character Total Horizontal, Character Display Horizontal
; 23	$17	--	--	--	CDV4	CDV3	CDV2	CDV1	CDV0	Character Display Vertical
; 24	$18	COPY	RVS	CBRATE	VSS4	VSS3	VSS2	VSS1	VSS0	Vertical Smooth Scrolling
; 25	$19	TEXT	ATR	SEMI	DBL	HSS3	HSS2	HSS1	HSS0	Horizontal Smooth Scrolling
; 26	$1A	FG3	FG2	FG1	FG0	BG3	BG2	BG1	BG0	Foreground/Background color
; 27	$1B	AI7	AI6	AI5	AI4	AI3	AI2	AI1	AI0	Address Increment per Row
; 28	$1C	CB15	CB14	CB13	RAM	--	--	--	--	Character Base Address
; 29	$1D	--	--	--	UL4	UL3	UL2	UL1	UL0	Underline Scan Line
; 30	$1E	WC7	WC6	WC5	WC4	WC3	WC2	WC1	WC0	Word Count
; 31	$1F	DA7	DA6	DA5	DA4	DA3	DA2	DA1	DA0	Data Register
; 32	$20	BA15	BA14	BA13	BA12	BA11	BA10	BA9	BA8	Block Start Address High Byte
; 33	$21	BA7	BA6	BA5	BA4	BA3	BA2	BA1	BA0	Block Start Address Low Byte
; 34	$22	DEB7	DEB6	DEB5	DEB4	DEB3	DEB2	DEB1	DEB0	Display Enable Begin
; 35	$23	DEE7	DEE6	DEE5	DEE4	DEE3	DEE2	DEE1	DEE0	Display Enable End
; 36	$24	--	--	--	--	DRR3	DRR2	DRR1	DRR0	DRAM Refresh Rate
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