;__________________________________________________________________________________________________
;
;	PARALLEL PORT KEYBOARD DRIVER FOR N8VEM
;       SUPPORT KEYBOARD/MOUSE ON VDU AND N8
;
;	ORIGINAL CODE BY DR JAMES MOXHAM
;	ROMWBW ADAPTATION BY WAYNE WARTHEN
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
; DATA CONSTANTS
;__________________________________________________________________________________________________
;
#IF (PLATFORM == PLT_N8)
PPK_PPI		.EQU	PPI2		; PPI PORT BASE FOR N8
#ELSE 
PPK_PPI		.EQU	0F4H		; PPI PORT BASE FOR VDU
#ENDIF

PPK_PPIA	.EQU	PPK_PPI + 0	; KEYBOARD PPI PORT A
PPK_PPIB	.EQU	PPK_PPI + 1	; KEYBOARD PPI PORT B
PPK_PPIC	.EQU	PPK_PPI + 2	; KEYBOARD PPI PORT C
PPK_PPIX	.EQU	PPK_PPI + 3	; KEYBOARD PPI CONTROL PORT
;
;__________________________________________________________________________________________________
; KEYBOARD INITIALIZATION
;__________________________________________________________________________________________________
;
PPK_INIT:
	CALL 	PPK_SETPORTC		; SETS PORT C SO CAN INPUT AND OUTPUT
	CALL 	PPK_RESET		; RESET TO THE KEYBOARD
	LD 	A,200			; 1 SECOND DELAY AS KEYBOARD SENDS STUFF BACK WHEN RESET
	CALL 	PPK_DELAY		; IGNORE ANYTHING BACK AFTER A RESET
	LD	A,0			; EMPTY KB QUEUE
	LD	(PPK_QLEN),A
	XOR	A
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD STATUS
;__________________________________________________________________________________________________
;
PPK_STAT:
	CALL 	PPK_PROCESS		; CALL KEYBOARD ROUTINE
	LD 	A,(PPK_QLEN)		; ASK IF KEYBOARD HAS KEY WAITING
	OR	A			; SET FLAGS
	JP	Z,CIO_IDLE		; NO DATA, EXIT VIA IDLE PROCESSING
	LD	A,$FF			; SIGNAL DATA PENDING
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD READ
;__________________________________________________________________________________________________
;
PPK_READ:
	CALL	PPK_STAT		; CHECK TO SEE IF KEY READY
	JR	Z,PPK_READ		; IF NOT, LOOP
	CALL	PPK_GETKEY		; GET IT
	LD	E,A			; PUT KEY WHERE IT BELONGS
	XOR	A			; SIGNAL SUCCESS
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD FLUSH
;__________________________________________________________________________________________________
;
PPK_FLUSH:
	LD	A,0			; EMPTY KB QUEUE
	LD	(PPK_QLEN),A		; SAVE IT
	XOR	A			; SIGNAL SUCCESS
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;__PPK_GETKEY______________________________________________________________________________________
;
; 	GET KEY PRESS VALUE
;__________________________________________________________________________________________________			
PPK_GETKEY:
	LD	A,(PPK_QLEN)		; GET QUEUE POINTER
	OR	A
	RET	Z			; ABORT IF QUEUE EMPTY
	PUSH	BC			; STORE BC
	LD	B,A			; STORE QUEUE COUNT FOR LATER
	PUSH	HL			; STORE HL
	LD	A,(PPK_QUEUE)		; GET TOP BYTE FROM QUEUE
	PUSH 	AF			; STORE IT
	LD	HL,PPK_QUEUE		; GET POINTER TO QUEUE
PPK_GETKEY1:				;
	INC	HL			; POINT TO NEXT VALUE IN QUEUE
	LD	A,(HL)			; GET VALUE
	DEC 	HL			;
	LD	(HL),A			; MOVE IT UP ONE
	INC	HL			;
	DJNZ	PPK_GETKEY1		; LOOP UNTIL DONE
	LD	A,(PPK_QLEN)		; DECREASE QUEUE POINTER BY ONE	
	DEC	A			;
	LD	(PPK_QLEN),A
	POP	AF			; RESTORE VALUE
	POP	HL			; RESTORE HL
	POP	BC			; RESTORE BC
	RET

;__PPK_RESET________________________________________________________________________________________
;
; 	RESET THE KEYBOARD
;__________________________________________________________________________________________________			   	   	
PPK_RESET:
	CALL 	PPK_DATAHIGH		;
	CALL 	PPK_CLOCKHIGH		;
	LD 	B,255			;
SF1:	DJNZ 	SF1			;
	CALL 	PPK_CLOCKLOW		; STEP 1
	LD 	B,255			;
SF2:	DJNZ 	SF2			;
	CALL 	PPK_DATALOW		; STEP 2
	CALL 	PPK_CLOCKHIGH		; STEP 3
	CALL 	PPK_WAITCLOCKLOW		; STEP 4
	LD	B,9			; 8 DATA BITS + 1 PARITY BIT LOW
SF3:	PUSH 	BC			;
	CALL 	PPK_DATAHIGH		; STEP 5
	CALL 	PPK_WAITCLOCKHIGH	; STEP 6
	CALL 	PPK_WAITCLOCKLOW		; STEP 7
	POP 	BC			;
	DJNZ 	SF3			;
	CALL 	PPK_DATAHIGH		; STEP9
	CALL 	PPK_WAITCLOCKLOW		; STEP 10 COULD READ THE ACK BIT HERE IF WANT TO
	CALL 	PPK_WAITCLOCKHIGH	; STEP 11
	LD 	B,255			;
SF4:	DJNZ 	SF4			; FINISH UP DELAY
	RET

;__PPK_SETPORTC_____________________________________________________________________________________
;
; 	SETUP PORT C OF 8255 FOR KEYBOARD
;__________________________________________________________________________________________________			   	   	
PPK_SETPORTC:
	LD 	A,10000010B		; A=OUT B=IN, C HIGH=OUT, CLOW=OUT
	OUT 	(PPK_PPIX),A		; PPI CONTROL PORT
	LD 	A,00000000B		; PORT A TO ZERO AS NEED THIS FOR COMMS TO WORK
	OUT	(PPK_PPIA),A		; PPI PORT A
	CALL 	PPK_DATAHIGH		;
	CALL 	PPK_CLOCKHIGH		;
	LD 	A,0			;
	LD 	(CAPSLOCK),A		; SET CAPSLOCK OFF TO START
	LD 	(CTRL),A		; CONTROL OFF
	LD 	(NUMLOCK),A		; NUMLOCK OFF
	RET
;_________________________________________________________________________________________________
;
; 	PORT C BIT ROUTINES
;__________________________________________________________________________________________________			   	   	
PPK_PORTCBIT0HIGH:			;
	LD 	A,01110001B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_PORTCBIT1HIGH:			;
	LD 	A,01110011B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_PORTCBIT2HIGH:			;
	LD 	A,01110101B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_PORTCBIT3HIGH:			;
	LD 	A,01110111B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_PORTCBIT0LOW:			;
	LD 	A,01110000B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_PORTCBIT1LOW:			;
	LD 	A,01110010B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_PORTCBIT2LOW:			;
	LD 	A,01110100B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_PORTCBIT3LOW:			;
	LD 	A,01110110B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_DATAHIGH:
PPK_PORTCBIT4HIGH:			;
	LD 	A,01111001B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_DATALOW:				;
PPK_PORTCBIT4LOW:			;
	LD 	A,01111000B		; SEE THE 8255 DATA SHEET
	JP	PPK_SETBITS		;
PPK_CLOCKHIGH:				;
PPK_PORTCBIT5HIGH:			;
	LD 	A,01111011B		; BIT 5 HIGH
	JP	PPK_SETBITS		;
PPK_CLOCKLOW:				;
PORTCBIT5LOW:				;
	LD 	A,01111010B		;
PPK_SETBITS:				;
	OUT 	(PPK_PPIX),A		;
	RET				;

;__PPK_WAITCLOCKLOW_________________________________________________________________________________
;
; WAITCLOCKLOW SAMPLES DATA BIT 0, AND WAITS TILL
; IT GOES LOW, THEN RETURNS
; ALSO TIMES OUT AFTER 0 001 SECONDS
; USES A, CHANGES B
;__________________________________________________________________________________________________			   	   	
PPK_WAITCLOCKLOW:
	LD 	B,255			; FOR TIMEOUT COUNTER
PPK_WAITCLOCKLOW1:
	IN 	A,(PPK_PPIB)		; GET A BYTE FROM PORT B
	BIT 	1,A			; TEST THE CLOCK BIT
	RET 	Z			; EXIT IF IT WENT LOW
	DJNZ 	PPK_WAITCLOCKLOW1	; LOOP B TIMES
	RET
	
;__PPK_WAITCLOCKHIGH_________________________________________________________________________________
;
; WAITCLOCKHIGH SAMPLES DATA BIT 0, AND WAITS TILL
; IT GOES HIGH, THEN RETURNS
; ALSO TIMES OUT AFTER 0 001 SECONDS
; USES A, CHANGES B
;__________________________________________________________________________________________________			   	   	
PPK_WAITCLOCKHIGH:	
	LD 	B,255			; FOR TIMEOUT COUNTER
PPK_WAITCLOCKHIGH1:
	IN 	A,(PPK_PPIB)		; GET A BYTE FROM PORT B
	BIT 	1,A			; TEST THE CLOCK BIT
	RET 	NZ			; EXIT IF IT WENT HIGH
	DJNZ 	PPK_WAITCLOCKHIGH1	; LOOP B TIMES
	RET

;__PPK_DELAY________________________________________________________________________________________
;
; PASS A - DELAY IS B*0 005 SECONDS, BCDEHL ALL PRESERVED
;__________________________________________________________________________________________________			   	   	
PPK_DELAY:	
	PUSH 	BC		; STORE ALL VARIABLES
	PUSH 	DE		;
	PUSH 	HL		;
	LD 	B,A		; PUT THE VARIABLE DELAY IN B
	LD 	DE,1		;
PPK_DELAY1:
	LD 	HL,740		; ADJUST THIS VALUE FOR YOUR CLOCK 1481=3 68MHZ, 3219=8MHZ (TEST WITH A=1000=10 SECS)
PPK_DELAY2:
	SBC 	HL,DE		; HL-1
	JR 	NZ,PPK_DELAY2
	DJNZ 	PPK_DELAY1
	POP 	HL		; RESTORE VARIABLES
	POP 	DE		;
	POP 	BC		;
	RET			;

;__PPK_PROCESS______________________________________________________________________________________
;
;  A=0 IF WANT TO KNOW IF A BYTE IS AVAILABLE, AND A=1 TO ASK FOR THE BYTE
;__________________________________________________________________________________________________			   	   	
PPK_PROCESS:	
	CALL	PPK_SKIP	; DON'T TEST EVERY ONE AS TAKES TIME
	OR	A		; IS IT ZERO
	RET	Z		; RETURN IF ZERO
 	CALL	PPK_WAITBYTE	; TEST KEYBOARD  TIMES OUT AFTER A BIT
	CALL 	PPK_DECODECHAR	; RETURNS CHAR OR 0 FOR THINGS LIKE KEYUP, SOME RETURN DIRECTLY TO CP/M
	RET			; RETURN TO CP/M

;-----------------------------------------------
; CPM CALLS THE KEYBOARD QUITE FREQUENTLY  IF A KEYBOARD WAS LIKE A UART WHICH CAN BE CHECKED
; WITH ONE INSTRUCTION, THAT WOULD BE FINE  BUT CHECKING A KEYBOARD INVOLVES PUTTING THE CLOCK LINE LOW
; THEN WAITING SOME TIME FOR A POSSIBLE REPLY, THEN READING IN BITS WITH TIMEOUTS AND THEN RETURNING
; THIS SLOWS DOWN A LOT OF CP/M PROCESSES, EG TRY TYPE MYPROG AND PRINTING OUT TEXT
PPK_SKIP:
	LD	B,0		;
	LD 	A,(SKIPCOUNT)	;
	DEC	A		; SUBTRACT 1
	LD	(SKIPCOUNT),A	; STORE IT BACK
	CP 	0		;
	JP	NZ,PPK_SKIP1	; WORDSTAR IS VERY SLOW EVEN TRIED A VALUE OF 5 TO 200 HERE
	LD	A,200		; ONLY ACT ON EVERY N CALLS - BIGGER=BETTER BECAUSE THIS SUB IS QUICKER THAN READBITS
	LD	(SKIPCOUNT),A	; RESET COUNTER
	LD 	B,1		; FLAG TO SAY RESET COUNTER
PPK_SKIP1:				;
	LD	A,B		; RETURN THE VALUE IN A
	RET

;__PPK_DECODECHAR____________________________________________________________________________________
;
; DECODE CHARACTER PASS A AND PRINTS OUT THE CHAR
; ON THE LCD SCREEN
;__________________________________________________________________________________________________			   	   	
PPK_DECODECHAR:
	CP	0		; IS IT ZERO
	RET	Z		; RETURN IF A ZERO - NO NEED TO DO ANYTHING
	CP 	0F0H		; IS A KEY UP (NEED TO DO SPECIAL CODE FOR SHIFT)
	JP 	Z,DECKEYUP	; IGNORE CHAR UP
	CP	0E0H		; TWO BYTE KEYPRESSES
	JP 	Z,TWOBYTE	;
	CP 	058H		; CAPS LOCK SO TOGGLE
	JP 	Z,CAPSTOG	;
	CP	12H		; SHIFT (DOWN, BECAUSE UP WOULD BE TRAPPED BY 0F ABOVE)
	JP 	Z,SHIFTDOWN	;
	CP	59H		; OTHER SHIFT KEY
	JP 	Z,SHIFTDOWN	;
	CP	014H		; CONTROL KEY
	JP 	Z,CONTROLDOWN	;
	CP	05AH		; ENTER KEY
	JP	Z,RETURN	;
	CP	066H		; BACKSPACE KEY
	JP	Z,BACKSPACE	;
	CP	0DH		; TAB KEY
	JP 	Z,TABKEY	;
	CP	076H		; ESCAPE KEY
	JP	Z,ESCAPE	;
	LD 	C,A		;
	LD 	B,0		; ADD BC TO HL
	LD 	HL,PPK_KEYMAP	; OFFSET TO ADD
	ADD 	HL,BC		;
	JP	TESTCONTROL	; IS THE CONTROL KEY DOWN?
DC1:	LD 	A,(CAPSLOCK)	;
	CP 	0		; IS IT 0, IF SO THEN DON'T ADD THE CAPS OFFSET
	JR 	Z,DC2		;
	LD 	C,080H		; ADD ANOTHER 50H TO SMALLS TO GET CAPS
	ADD 	HL,BC		;
DC2:	LD 	A,(HL)		;
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
TESTCONTROL:
	LD 	A,(CTRL)	;
	CP 	0		; IS CONTROL BEING HELD DOWN?
	JP	Z,DC1		; NO SO GO BACK TO TEST CAPS LOCK ON
	LD	A,(HL)		; GET THE LETTER, SHOULD BE SMALLS 
	SUB	96		; A=97 SO SUBTRACT 96 A=1=^A
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			; RETURN INSTEAD OF THE RET AFTER DC2
TABKEY:				;
	LD 	A,9		;
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;TAB
BACKSPACE:			;
	LD	A,8		; BACKSPACE
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
ESCAPE:				;
	LD	A,27		;
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
RETURN:				;
	LD	A,13		; CARRIAGE RETURN
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
DECKEYUP:
	CALL PPK_WAITBYTE	; IGNORE KEY UP THROW AWAY THE CHARACTER UNLESS A SHIFT 
	CP	012H		; IS IT A SHIFT
	JP 	Z,SHIFTUP	;
	CP	59H		; OTHER SHIFT KEY
	JP	Z,SHIFTUP	;
	CP	014H		; CONTROL UP
	JP 	Z,CONTROLUP	; CONTROL UP
	LD	A,0		; NOTHING CAPTURED SO SEND BACK A ZERO 
	RET
TWOBYTE:; ALREADY GOT EO SO GET THE NEXT CHARACTER
	CALL 	PPK_WAITBYTE
	CP	0F0H		; SEE THE NOTES - KEYUP FOR E0 KEYS IS EO F0 NN NOT F0 EO!!
	JP	Z,TWOBYTEUP	;
	CP	071H		; DELETE
	JP	Z,DELETEKEY	;
	CP	05AH		; RETURN ON NUMBER PAD
	JP	Z,RETURNKEY	;
	CP	072H		;
	JP	Z,DOWNARROW	;
	CP	074H		;
	JP	Z,RIGHTARROW	;
	CP	06BH		;
	JP	Z,LEFTARROW	;
	CP	075H		;
	JP	Z,UPARROW	;
	CP	070H		;
	JP	Z,INSERT	;
	CP	07DH		;
	JP	Z,PAGEUP	;
	CP	07AH		;
	JP	Z,PAGEDOWN	;
	CP	06CH		;
	JP	Z,HOME		;
	CP	069H		;
	JP	Z,END		;
	LD 	A,0		; RETURNS NOTHING
	RET
TWOBYTEUP:			;EXPECT A BYTE AND IGNORE IT
	CALL	PPK_WAITBYTE	;
	LD	A,0		;
	RET			;
HOME:				;
	LD	A,1BH		; ESC
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'W'		; W
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
END:				;
	LD	A,1BH		; ESC
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'Q'		; Q
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
DOWNARROW:			;
	LD	A,1BH		; ESC
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'B'		; B
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
RIGHTARROW:			;
	LD	A,1BH		; ESC
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'C'		; C
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
LEFTARROW:			;
	LD	A,1BH		; ESC
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'D'		; D
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
UPARROW:			;
	LD	A,1BH		; ESC
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD 	A,'A'		; A
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;	
INSERT:				;
	LD	A,1BH		; ESC
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'P'		; P
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
PAGEUP:				;
	LD	A,1BH		; ESC
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'Y'		; Y
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
PAGEDOWN:			;
	LD	A,1BH		; ESC
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'S'		; S
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
CONTROLDOWN:			; SAME CODE AS SHIFTDOWN BUT DIFF LOCATION
	LD 	A,0FFH		;
	LD	(CTRL),A	; CONTROL DOWN
	LD	A,0		;
	RET			;
CONTROLUP:			; CONTROL KEY UP SEE SHIFT FOR EXPLANATION
	LD	A,0		;
	LD 	(CTRL),A	;
	LD 	A,0		;
	RET			;
RETURNKEY:			;
	LD 	A,13		;
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
DELETEKEY:			;
	LD 	A,07FH		; DELETE KEY VALUE THAT CP/M USES
	CALL	PPK_ENQUEUE	; STORE ON KB QUEUE
	RET			;
CAPSTOG:			;
  	LD 	A,(CAPSLOCK)	;
	XOR 	11111111B	; SWAP ALL THE BITS
	LD 	(CAPSLOCK),A	;
	LD	A,0		; RETURNS NOTHING
	RET			;
SHIFTDOWN:			; SHIFT IS SPECIAL - HOLD IT DOWN AND IT AUTOREPEATS
				; SO ONCE IT IS DOWN, TURN CAPS ON AND IGNORE ALL FURTHER SHIFTS
				; ONLY AN F0+SHIFT TURNS CAPS LOCK OFF AGAIN
	LD 	A,0FFH		;
	LD 	(CAPSLOCK),A	;
	LD 	A,0		; RETURNS NOTHING
	RET			;
SHIFTUP:			; SHIFTUP TURNS OFF CAPS LOCK DEFINITELY
	LD 	A,0		;
	LD 	(CAPSLOCK),A	;
	LD 	A,0		; RETURNS NOTHING
	RET			;

;__PPK_ENQUEUE______________________________________________________________________________________
;
;  STORE A BYTE IN THE KEYBOARD QUEUE 
;  A: BYTE TO ENQUEUE
;__________________________________________________________________________________________________			   	   		
PPK_ENQUEUE:
	PUSH	DE		; STORE DE
	PUSH	HL		; STORE HL	
	PUSH	AF		; STORE VALUE
	LD	A,(PPK_QLEN)	; PUT QUEUE POINTER IN A
	CP	15		; IS QUEUE FULL
	JP	P,PPK_ENQUEUE1	; YES, ABORT	
	LD	HL,PPK_QUEUE	; GET QUEUE POINTER
	PUSH	HL		; MOVE HL TO BC
	POP	BC		; 
	LD	H,0		; ZERO OUT H
	LD	L,A		; PLACE QUEUE POINTER IN L
	ADD	HL,BC		; POINT HL AT THE NEXT LOACTION TO ADD VALUE
	POP	AF		; RESTORE VALUE
	LD	(HL),A		; ENQUEUE VALUE
	LD	A,(PPK_QLEN)	; GET QUEUE POINTER
	INC	A		; INC IT
	LD	(PPK_QLEN),A	;STORE QUEUE POINTER
PPK_ENQUEUE1:
	POP	HL		; RESTORE HL
	POP	DE		; RESTORE DE
	RET
	
	
;__PPK_WAITBYTE_____________________________________________________________________________________
;
; WAIT FOR A BYTE - TESTS A NUMBER OF TIMES IF THERE IS A KEYBOARD INPUT,
; OVERWRITES ALL REGISTERS, RETURNS BYTE IN A
;__________________________________________________________________________________________________			   	   		
PPK_WAITBYTE:	
	CALL	PPK_CLOCKHIGH		; TURN ON KEYBOARD
	LD 	HL,500			; NUMBER OF TIMES TO CHECK 200=SLOW TYPE
					; 10=ERROR, 25 ?ERROR 50 OK - 
					; THIS DELAY HAS TO BE THERE OTHERWISE WEIRD KEYUP ERRORS
PPK_WAITBYTE1:
	PUSH 	HL			; STORE COUNTER
	CALL 	PPK_READBITS		; TEST FOR A LOW ON THE CLOCK LINE
	POP 	HL			; GET THE COUNTER BACK
	CP	0			; TEST FOR A ZERO BACK FROM READBITS
	JR	NZ,PPK_WAITBYTE2	; IF NOT A ZERO THEN MUST HAVE A BYTE IE A KEYBOARD PRESS
	LD	DE,1			; LOAD WITH 1
	SBC 	HL,DE			; SUBTRACT 1
	JR	NZ,PPK_WAITBYTE1	; LOOP WAITING FOR A RESPONSE
PPK_WAITBYTE2:
	PUSH 	AF			; STORE THE VALUE IN A
	CALL 	PPK_CLOCKLOW		; TURN OFF KEYBOARD
	POP AF				; GET BACK BYTE AS CLOCKLOW ERASED IT
	RET

;__PPK_READBITS_____________________________________________________________________________________
;
; READBITS READS 11 BITS IN FROM THE KEYBOARD
; FIRST BIT IS A START BIT THEN 8 BITS FOR THE BYTE
; THEN A PARITY BIT AND A STOP BIT
; RETURNS AFTER ONE MACHINE CYCLE IF NOT LOW
; USES A, B,D, E 
; RETURNS A=0 IF NO DATA, A= SCANCODE (OR PART THEREOF)
;__________________________________________________________________________________________________			   	   		
PPK_READBITS:
	IN 	A,(PPK_PPIB)
	BIT 	1,A			; TEST THE CLOCK BIT
	JR 	Z,PPK_READBITS1		; IF LOW THEN START THE CAPTURE
	LD 	A,0			; RETURNS A=0 IF NOTHING
	RET
PPK_READBITS1:
	CALL 	PPK_WAITCLOCKHIGH	; IF GETS TO HERE THEN MUST BE LOW SO WAIT TILL HIGH
	LD 	B,8			; SAMPLE 8 TIMES
	LD 	E,0			; START WITH E=0
PPK_READBITS2:
	LD 	D,B			; STORE BECAUSE WAITCLOCKHIGH DESTROYS
	CALL 	PPK_WAITCLOCKLOW	; WAIT TILL CLOCK GOES LOW
	IN 	A,(PPK_PPIB)		; SAMPLE THE DATA LINE
	RRA				; MOVE THE DATA BIT INTO THE CARRY REGISTER
	LD 	A,E			; GET THE BYTE WE ARE BUILDING IN E
	RRA				; MOVE THE CARRY BIT INTO BIT 7 AND SHIFT RIGHT
	LD 	E,A			; STORE IT BACK  AFTER 8 CYCLES 1ST BIT READ WILL BE IN B0
	CALL 	PPK_WAITCLOCKHIGH	; WAIT TILL GOES HIGH
	LD 	B,D			; RESTORE FOR LOOP
	DJNZ 	PPK_READBITS2		; DO THIS 8 TIMES
	CALL 	PPK_WAITCLOCKLOW	; GET THE PARITY BIT
	CALL 	PPK_WAITCLOCKHIGH
	CALL 	PPK_WAITCLOCKLOW	; GET THE STOP BIT
	CALL 	PPK_WAITCLOCKHIGH
	LD 	A,E			; RETURNS WITH ANSWER IN A
	RET

PPK_KEYMAP:	
	; THE TI CHARACTER CODES, OFFSET FROM LABEL BY KEYBOARD SCAN CODE
	.DB	$00, $00, $00, $00, $00, $00, $00, $00 
	.DB	$00, $00, $00, $00, $00, $09, "`", $00	; $09=TAB
	.DB	$00, $00, $00, $00, $00, "q", "1", $00
	.DB	$00, $00, "z", "s", "a", "w", "2", $00
	.DB	$00, "c", "x", "d", "e", "4", "3", $00
	.DB	$00, " ", "v", "f", "t", "r", "5", $00
	.DB	$00, "n", "b", "h", "g", "y", "6", $00 
	.DB	$00, $00, "m", "j", "u", "7", "8", $00 
	.DB	$00, ",", "k", "i", "o", "0", "9", $00 
	.DB	$00, ".", "/", "l", ";", "p", "-", $00
	.DB	$00, $00, $27, $00, "[", "=", $00, $00 	; $27=APOSTROPHE
	.DB	$00, $00, $00, "]", $00, $5C, $00, $00	; $5C=BACKSLASH
	.DB	$00, $00, $00, $00, $00, $00, $00, $00
	.DB	$00, "1", $00, "4", "7", $00, $00, $00
	.DB	"0", ".", "2", "5", "6", "8", $00, $00
	.DB	$00, "+", "3", "-", "*", "9", $00, $00

PPK_SHIFTKEYMAP:
	.DB	$00, $00, $00, $00, $00, $00, $00, $00
	.DB	$00, $00, $00, $00, $00, $09, "~", $00	; $09=TAB
	.DB	$00, $00, $00, $00, $00, "Q", "!", $00
	.DB	$00, $00, "Z", "S", "A", "W", "@", $00
	.DB	$00, "C", "X", "D", "E", "$", "#", $00
	.DB	$00, " ", "V", "F", "T", "R", "%", $00
	.DB	$00, "N", "B", "H", "G", "Y", "^", $00
	.DB	$00, $00, "M", "J", "U", "&", "*", $00
	.DB	$00, "<", "K", "I", "O", ")", "(", $00
	.DB	$00, ">", "?", "L", ":", "P", "_", $00
	.DB	$00, $00, $22, $00, "{", "+", $00, $00	; $22=DBLQUOTE
	.DB	$00, $00, $00, "}", $00, "|", $00, $00
	.DB	$00, $00, $00, $00, $00, $00, $00, $00
	.DB	$00, "1", $00, "4", "7", $00, $00, $00
	.DB	"0", ".", "2", "5", "6", "8", $00, $00
	.DB	$00, "+", "3", "-", "*", "9", $00, $00
;
;==================================================================================================
;   PARALLEL PORT KEYBOARD DRIVER - DATA
;==================================================================================================
;
CAPSLOCK		.DB	0	; CAPS LOCK TOGGLED FLAG, $00=NO, $FF=YES
CTRL			.DB	0	; CTRL KEY PRESSED FLAG, $00=NO, $FF=YES
NUMLOCK			.DB	0	; NUM LOCK TOGGLED FLAG, $00=NO, $FF=YES
SKIPCOUNT		.DB	0	; SKIP COUNTER (SEE CODE COMMENTS)
PPK_QUEUE		.FILL	16,0 	; 16 BYTE KB QUEUE
PPK_QLEN		.DB	0	; COUNT OF BYTES CURRENTLY IN QUEUE
