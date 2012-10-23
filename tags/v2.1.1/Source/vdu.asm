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
;IDE REGISTER		IO PORT		; FUNCTION
READR		 .EQU	0F0h		; READ VDU
WRITR		 .EQU	0F1h		; WRITE VDU
SY6545S		 .EQU	0F2h		; VDU STATUS/REGISTER
SY6545D		 .EQU	0F3h		;
PPIA		 .EQU	0F4h		; PPI PORT A
PPIB		 .EQU	0F5h		; PPI PORT B
PPIC		 .EQU	0F6h		; PPI PORT C
PPICONT		 .EQU	0F7h		; PPI CONTROL PORT

STATE_NORMAL	 .EQU	00H		; NORMAL TERMINAL OPS
STATE_ESC	 .EQU	01H		; ESC MODE
STATE_DIR_L	 .EQU	02H		; ESC-Y X *
STATE_DIR_C	 .EQU	03H		; ESC-Y * X

ESC_KEY		 .EQU	1BH		; ESCAPE CODE
;	
;__________________________________________________________________________________________________
; FUNCTION JUMP TABLE
;__________________________________________________________________________________________________
;
VDU_DISPATCH:
	LD	A,B	; GET REQUESTED FUNCTION
	AND	$0F	; ISOLATE SUB-FUNCTION
	JR	Z,VDU_IN
	DEC	A
	JR	Z,VDU_OUT
	DEC	A
	JR	Z,VDU_IST
	DEC	A
	JR	Z,VDU_OST
	CALL	PANIC
;
VDU_INIT:
	CALL	INITVDU
	RET
;	
VDU_IN:
	CALL	GET_KEY
	LD	E,A
	RET
;
VDU_IST:
	CALL	IS_KBHIT
	RET
;
VDU_OUT:
	LD	C,E
	CALL	CHARIN
	RET
;
VDU_OST:
	CALL	PANIC
;
;__________________________________________________________________________________________________
; INITIALIZATION
;__________________________________________________________________________________________________
INITVDU:
    	CALL	VDUINIT			; INIT VDU   					
	CALL 	KB_INITIALIZE		; INIT KB
;	CALL	PR_INITIALIZE		; INIT PR
    	
;    	CALL	DSPMATRIX		; DISPLAY INIT MATRIX SCREEN
;	CALL	WAIT_KBHIT		; WAIT FOR A KEYSTROKE
	LD	A,0			; EMPTY KB QUEUE
	LD	(KB_QUEUE_PTR),A	; 
	
	CALL	PERF_ERASE_EOS		; CLEAR SCREEN
	CALL	PERF_CURSOR_HOME	; CURSOR HOME	
	RET
;
;__CHARIN__________________________________________________________________________________________
;
; 	PROCESS INCOMMING CHARACTER AND DISPLAY ON SCREEN OR PERFORM FUNCTION
;	C:  INCOMMING CHARACTER
;__________________________________________________________________________________________________
CHARIN:
	LD	A,C
	PUSH	AF			; STORE AF
	LD	A,(TERMSTATE)		; MOVE CURRENT STATE INTO A
	CP	STATE_NORMAL		; NORMAL PROCESSING STATE?
	JP	Z,CHARIN_NORM		;
	CP	STATE_ESC		; ESCAPE PROCESSING STATE?
	JP	Z,CHARIN_ESCSTATE	;
	CP	STATE_DIR_L		; WAITING FOR Y COORD STATE?
	JP	Z,CHARIN_DIR_L_STATE	;
	CP	STATE_DIR_C		; WAITING FOR X COORD STATE?
	JP	Z,CHARIN_DIR_C_STATE	;
	LD	A,STATE_NORMAL		; UNKNOWN STATE, RESET STATE
	LD	(TERMSTATE),A		;
	POP	AF			; 
	RET				;

;__CHARIN_DIR_L_STATE______________________________________________________________________________
;
; 	PROCESS "WAITING FOR Y COORD STATE"
;__________________________________________________________________________________________________
CHARIN_DIR_L_STATE:
	LD	A,32			; MOVE 32 (' ') INTO A
	LD	C,A			; PARK INTO C
	POP	AF			; GET CHAR FROM STACK
	SUB	C			; DECODE CHAR INTO USABLE Y COORD
	CP	24			; IS OFF SCREEN?
	JP	M,CHARIN_DIR_L_STATE_CONT
	LD	A,23			; YES, PLACE CRSR ON LAST ROW
CHARIN_DIR_L_STATE_CONT:	
	LD	(TERM_Y),A		; NO, USE DECODED VALUE	
	LD	A,STATE_DIR_C		; SET UP STATE TO GET X COORD
	LD	(TERMSTATE),A		;
	RET

;__CHARIN_DIR_C_STATE______________________________________________________________________________
;
; 	PROCESS "WAITING FOR X COORD STATE"
;__________________________________________________________________________________________________	
CHARIN_DIR_C_STATE:
	LD	A,32			; MOVE 32 (' ') INTO A
	LD	C,A			; PARK INTO C
	POP	AF			; GET CHAR FROM STACK
	SUB	C			; DECODE CHAR INTO USABLE X COORD
	CP	80			; IS OFF SCREEN?
	JP	M,CHARIN_DIR_C_STATE_CONT
	LD	A,79			; YES, PLACE CRSR IN LAST COLUMN
CHARIN_DIR_C_STATE_CONT:	
	LD	(TERM_X),A		; NO, USE DECODED VALUE
	CALL 	GOTO_XY			; SET CURSOR POS
	LD	A,STATE_NORMAL		; RESET STATE TO NORMAL
	LD	(TERMSTATE),A		;
	RET
	
	
;__CHARIN_NORM_____________________________________________________________________________________
;
; 	PROCESS NORMAL STATE
;__________________________________________________________________________________________________	
CHARIN_NORM:
	POP	AF			; GET CHAR FROM STACK
	CP	0AH			; IS LINEFEED?
	JP	Z,CHARIN_LF		;
	CP	09H			; IS TAB?
	JP	Z,CHARIN_TAB		;
	CP	08H			; IS BS?
	JP	Z,CHARIN_BS		;
	CP	0DH			; IS CR?
	JP	Z,CHARIN_CR		;
	CP	07H			; IS BELL?
	JP	Z,CHARIN_BELL		;
	CP	13H			; IS XOFF?
	JP	Z,CHARIN_XOFF		;
	CP	11H			; IS XON?
	JP	Z,CHARIN_XON		;
	CP	ESC_KEY			; IS ESC?
	JP	Z,CHARIN_ESC		;
	JP	VDU_PUTCHAR		; NORMAL OUTPUT CHAR
	
;__CHARIN_ESC______________________________________________________________________________________
;
; 	PROCESS "ESC" STATE
;__________________________________________________________________________________________________	
CHARIN_ESC:	
	LD	A,STATE_ESC		; ESC PRESSED, STATE TO ESCPRESSED
	LD	(TERMSTATE),A		;
    	RET
    	
;__CHARIN_LF_______________________________________________________________________________________
;
; 	PROCESS LINE FEED
;__________________________________________________________________________________________________	
CHARIN_LF:
	LD	A,(TERM_Y)		; MOVE CRSR Y COORD INTO A
	INC	A			; INC A
	LD	(TERM_Y),A		; STORE NEW Y COORD 
	JP	GOTO_XY			; SET CRSR POSITION
	
	
;__CHARIN_TAB______________________________________________________________________________________
;
; 	PROCESS TABS
;__________________________________________________________________________________________________	
CHARIN_TAB:
	LD	HL,TABSTOPS		; SET HL TO TAB STOP TABLE
	LD	A,(TERM_X)		; MOVE CURENT CRSR X COORD INTO A
	INC	A			; INC A
	LD	C,A			; STORE CRSR X COORD INTO A
CHARIN_TAB_LOOP:	
	LD	A,(HL)			; GET NEXT TAB STOP
	OR	A			; IS ZERO?
	JP	Z,CHARIN_TAB_EXIT	; END OF TABLE, PROCESS 73+
	INC	HL			; SET POINTER TO NEXT TABLE ENTRY
	CP	C			; IS CURRENT ENTRY > X COORD?
	JP	M,CHARIN_TAB_LOOP	; NO, LOOP
	LD	(TERM_X),A		; YES, USE IT
	JP	GOTO_XY			; SET CRSR POSITION
CHARIN_TAB_EXIT:	
	LD	A,(TERM_X)		; COLUMN IS PAST LAST TAB STOP, SET A TO CRSR POS
	CP	79			; IS LAST PHYSICAL POS?	
	RET	Z			; YES, DO NOTHING
	INC	A			; NO, INC CRSR BY ONE
	LD	(TERM_X),A		; STORE NEW X COORD
	JP	GOTO_XY			; SET CRSR POSITION
	
TABSTOPS:	
	 .DB	09,17,25,33,41,49,57,65,73,00
	
		
;__CHARIN_BS_______________________________________________________________________________________
;
; 	PROCESS BACKSPACE
;__________________________________________________________________________________________________	
CHARIN_BS:		
	JP	PERF_CURSOR_LEFT	; PERFORM CRSR LEFT FUNCTION
	
	
;__CHARIN_CR_______________________________________________________________________________________
;
; 	PROCESS CARRAGE RETURN
;__________________________________________________________________________________________________	
CHARIN_CR:
	LD	A,00H			; MOVE 0 TO X COORD 
	LD	(TERM_X),A		;
	JP	GOTO_XY			; GOTO XY COORDS
	
	
;__CHARIN_BELL_____________________________________________________________________________________
;
; 	PROCESS BELL 
;__________________________________________________________________________________________________	
CHARIN_BELL:
	;
	; NO HARDWARE FOR THIS, DO NOTHING
	;
	RET
	
	
;__CHARIN_XOFF_____________________________________________________________________________________
;
; 	PROCESS XOFF 
;__________________________________________________________________________________________________	
CHARIN_XOFF:
	;
	; SHOULD NOT BE NECESSARY FOR LOCAL IMPLIMENTATION
	;
	RET	

	
;__CHARIN_XON______________________________________________________________________________________
;
; 	PROCESS XON 
;__________________________________________________________________________________________________	
CHARIN_XON:
	;
	; SHOULD NOT BE NECESSARY FOR LOCAL IMPLIMENTATION
	;
	RET	
	
	
;__CHARIN_ESCSTATE_________________________________________________________________________________
;
; 	PROCESS ESC STATE 
;__________________________________________________________________________________________________	
CHARIN_ESCSTATE:
	POP	AF			;
	CP	'A'			; IS CURSOR UP?
	JP	Z, PERF_CURSOR_UP	;
	CP	'B'			; IS CURSOR DOWN?
	JP	Z, PERF_CURSOR_DOWN	;
	CP	'C'			; IS CURSOR RIGHT?
	JP	Z, PERF_CURSOR_RIGHT	;
	CP	'D'			; IS CURSOR LEFT?
	JP	Z, PERF_CURSOR_LEFT	;
	CP	'F'			; IS ENTER GRAPHICS MODE?
	JP	Z, PERF_ENTER_GR	;
	CP	'G'			; IS EXIT GRAPHICS MODE?
	JP	Z, PERF_EXIT_GR		;
	CP	'H'			; IS CURSOR HOME?
	JP	Z, PERF_CURSOR_HOME	;
	CP	'I'			; IS CURSOR HOME?
	JP	Z, PERF_REVERSE_LF	;
	CP	'Y'			; IS REVERSE LINE FEED?
	JP	Z, PERF_DIRECT_ADDRESS	;
	CP	'K'			; IS ERASE TO END OF LINE?
	JP	Z,PERF_ERASE_EOL	;
	CP	'J'			; IS ERASE TO END OF SCREEN?
	JP	Z,PERF_ERASE_EOS	;	
	CP	'Z'			; IS TERMINAL IDENTIFY?
	JP	Z,PERF_IDENTIFY		;	
	CP	'{'			; IS ENTER HOLD SCREEN MODE?
	JP	Z,PERF_ENTER_HOLD	;	
	CP	05CH			; IS EXIT HOLD SCREEN MODE?
	JP	Z,PERF_EXIT_HOLD	;	
	CP	'='			; IS ENTER ALT KEYPAD MODE?
	JP	Z,PERF_ENTER_ALT	;	
	CP	'}'			; IS EXIT ALT KEYPAD MODE?
	JP	Z,PERF_EXIT_ALT		;	
	CALL	VDU_PUTCHAR		; NORMAL OUTPUT CHAR
	JP	SET_STATE_NORMAL	;


;__PERF_REVERSE_LF_________________________________________________________________________________
;
; 	PERFORM REVERSE LINE FEED
;__________________________________________________________________________________________________	
PERF_REVERSE_LF:
	CALL	SET_STATE_NORMAL	; SET STATE TO NORMAL
	LD	A,(TERM_Y)		; GET CURRENT Y COORD INTO A
	OR	A			; IS ZERO
	JP	Z,REVERSE_SCROLL	; YES, SCROLL SCREEN DOWN ONE LINE
	DEC	A			; NO, MOVE CRSR UP ONE LINE
	LD	(TERM_Y),A		; STORE NEW CRSR POSITION
	JP	GOTO_XY			; POSITION CRSR
	
	
;__PERF_DIRECT_ADDRESS_____________________________________________________________________________
;
; 	PERFORM DIRECT CURSOR ADDRESSING
;__________________________________________________________________________________________________	
PERF_DIRECT_ADDRESS:	
	LD	A,STATE_DIR_L		; SET STATE "WAITING FOR Y COORD"
	LD	(TERMSTATE),A		;
    	RET				;
    	
;__PERF_ENTER_GR___________________________________________________________________________________
;
; 	PERFORM ENTER GRAPHICS MODE
;__________________________________________________________________________________________________	
PERF_ENTER_GR:
	LD	A,0FFH			;
	LD	(GR_MODE),A		; GRAPHICS MODE
	JP	SET_STATE_NORMAL	;	

	
;__PERF_EXIT_GR____________________________________________________________________________________
;
; 	PERFORM EXIT GRAPHICS MODE
;__________________________________________________________________________________________________	
PERF_EXIT_GR:
	LD	A,00FH			;
	LD	(GR_MODE),A		; GRAPHICS MODE
	JP	SET_STATE_NORMAL	;	
	
	
;__PERF_ENTER_ALT___________________________________________________________________________________
;
; 	PERFORM ENTER ALTERNATE KEYPAD MODE
;__________________________________________________________________________________________________	
PERF_ENTER_ALT:
	LD	A,0FFH			;
	LD	(ALT_KEYPAD),A		; ALT KEYPAD
	JP	SET_STATE_NORMAL	;	
	
	
;__PERF_EXIT_ALT___________________________________________________________________________________
;
; 	PERFORM EXIT ALTERNATE KEYPAD MODE
;__________________________________________________________________________________________________	
PERF_EXIT_ALT:
	LD	A,00H			;
	LD	(ALT_KEYPAD),A		; ALT KEYPAD
	JP	SET_STATE_NORMAL	;
	
;__PERF_ENTER_HOLD_________________________________________________________________________________
;
; 	PERFORM ENTER HOLD MODE
;__________________________________________________________________________________________________	
PERF_ENTER_HOLD:
	;  ********* IGNORE HOLD MODE !!
	JP	SET_STATE_NORMAL	;	
	
	
;__PERF_EXIT_HOLD__________________________________________________________________________________
;
; 	PERFORM EXIT HOLD MODE
;__________________________________________________________________________________________________	
PERF_EXIT_HOLD:
	;  ********* IGNORE HOLD MODE !!
	JP	SET_STATE_NORMAL	;	
	
	
;__SET_STATE_NORMAL________________________________________________________________________________
;
; 	SET NORMAL STATE
;__________________________________________________________________________________________________	
SET_STATE_NORMAL:
	LD	A,STATE_NORMAL		; RESET STATE
	LD	(TERMSTATE),A		;
	RET	
	
;__PERF_ERASE_EOL__________________________________________________________________________________
;
; 	PERFORM ERASE FROM CURSOR POS TO END OF LINE
;__________________________________________________________________________________________________	
PERF_ERASE_EOL:	
	LD	A,(TERM_X)		; GET CURRENT CURSOR X COORD
	LD	C,A			; STORE IT IN C
	LD	A,80			; MOVE CURRENT LINE WIDTH INTO A
	SUB	C			; GET REMAINING POSITIONS ON CURRENT LINE
	LD	B,A			; MOVE IT INTO B
	LD 	A, 31		        ; UPDATE TOGGLE VDU CHIP
    	OUT 	(SY6545S),A   		;	
PERF_ERASE_EOL_LOOP:		
	CALL 	VDU_UPDATECHECK 	; WAIT FOR VDU CHIP TO BE READY
	LD	A,32			; MOVE SPACE CHARACTER INTO A
	OUT 	(WRITR),A    	     	; WRITE IT TO SCREEN, VDU WILL AUTO INC TO NEXT ADDRESS
	DJNZ    PERF_ERASE_EOL_LOOP	; LOOP UNTIL DONE
	CALL	GOTO_XY			; MOVE CURSOR BACK TO ORIGINAL POSITION
	CALL	SET_STATE_NORMAL	; SET NORMAL STATE
	RET

;__PERF_ERASE_EOS__________________________________________________________________________________
;
; 	PERFORM ERASE FROM CURSOR POS TO END OF SCREEN
;__________________________________________________________________________________________________	
PERF_ERASE_EOS:	
	LD	HL,0780H		; SET SCREEN SIZE INTO HL
	PUSH	HL			; MOVE IT TO DE
	POP	DE			;
	LD 	A, 31		        ; UPDATE TOGGLE VDU CHIP
    	OUT 	(SY6545S),A   		;	
PERF_ERASE_EOS_LOOP:		
    	CALL 	VDU_UPDATECHECK		; WAIT FOR VDU CHIP TO BE READY
    	LD 	A, ' '           	; MOVE SPACE CHARACTER INTO A
    	OUT 	(WRITR),A         	; WRITE IT TO SCREEN, VDU WILL AUTO INC TO NEXT ADDRESS
    	DEC	DE			; DEC COUNTER
    	LD 	A,D			; IS COUNTER 0 YET?
    	OR 	E			;
    	JP 	NZ,PERF_ERASE_EOS_LOOP	; NO, LOOP
	CALL	GOTO_XY			; YES, MOVE CURSOR BACK TO ORIGINAL POSITION
	CALL	SET_STATE_NORMAL	; SET NORMAL STATE
	RET

	
;__PERF_IDENTIFY___________________________________________________________________________________
;
; 	PERFORM TERMINAL IDENTIFY FUNCTION
;__________________________________________________________________________________________________	
PERF_IDENTIFY:
	LD	A,ESC_KEY		;
	CALL	KB_ENQUEUE		; STORE ON KB QUEUE
	LD	A,'/'			;
	CALL	KB_ENQUEUE		; STORE ON KB QUEUE
	LD	A,'K'			;
	CALL	KB_ENQUEUE		; STORE ON KB QUEUE
	CALL	SET_STATE_NORMAL	; SET NORMAL STATE
	RET
	
;__PERF_CURSOR_HOME________________________________________________________________________________
;
; 	PERFORM CURSOR HOME
;__________________________________________________________________________________________________	
PERF_CURSOR_HOME:
	LD	A,0			; LOAD 0 INTO A
	LD	(TERM_X),A		; SET X COORD
	LD	(TERM_Y),A		; SET Y COORD
	CALL	SET_STATE_NORMAL	; SET NORMAL STATE
	JP	GOTO_XY			; MOVE CURSOR TO POSITION
		
;__PERF_CURSOR_LEFT________________________________________________________________________________
;
; 	PERFORM CURSOR LEFT
;__________________________________________________________________________________________________	
PERF_CURSOR_LEFT:
	LD	A,(TERM_X)		; GET CURRENT X COORD INTO A
	OR	A			; IS ZERO?
	JP	Z,PERF_CURSOR_ABORT	; YES, ABORT
	DEC	A			; MOVE ONE TO THE LEFT
	LD	(TERM_X),A		; STORE NEW CURSOR POSITION
	CALL	SET_STATE_NORMAL	; SET NORMAL STATE	 
	JP	GOTO_XY			; MOVE CURSOR TO POSITION
	
;__PERF_CURSOR_RIGHT_______________________________________________________________________________
;
; 	PERFORM CURSOR RIGHT
;__________________________________________________________________________________________________	
PERF_CURSOR_RIGHT:
	LD	A,(TERM_X)		; GET CURRENT X COORD INTO A
	CP	79			; IS END OF LINE?
	JP	Z,PERF_CURSOR_ABORT	; YES, ABORT
	INC	A			; MOVE ONE TO THE RIGHT
	LD	(TERM_X),A		; STORE NEW CURSOR POSITION
	CALL	SET_STATE_NORMAL	; SET NORMAL STATE
	JP	GOTO_XY			; MOVE CURSOR TO POSITION
	
;__PERF_CURSOR_UP__________________________________________________________________________________
;
; 	PERFORM CURSOR UP
;__________________________________________________________________________________________________		
PERF_CURSOR_UP:
	LD	A,(TERM_Y)		; GET CURRENT Y COORD INTO A
	OR	A			; IS ZERO?
	JP	Z,PERF_CURSOR_ABORT	; YES, ABORT
	DEC	A			; MOVE UP ONE POSITION
	LD	(TERM_Y),A		; STORE NEW CURSOR POSITION
	CALL	SET_STATE_NORMAL	; SET NORMAL STATE
	JP	GOTO_XY			; MOVE CURSOR TO POSTION
	
	
;__PERF_CURSOR_DOWN________________________________________________________________________________
;
; 	PERFORM CURSOR DOWN
;__________________________________________________________________________________________________		
PERF_CURSOR_DOWN:	
	LD	A,(TERM_Y)		; GET CURRENT Y COORD INTO A
	CP	23			; IS END OF SCREEN?
	JP	Z,PERF_CURSOR_ABORT	; YES, ABORT
	INC	A			; NO, MOVE DOWN ONE POSITION
	LD	(TERM_Y),A		; STORE NEW CURSOR POSITION
PERF_CURSOR_ABORT:
	CALL	SET_STATE_NORMAL	; SET NORMAL STATE
	JP	GOTO_XY			; MOVE CURSOR TO POSITION

	


	
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
	OUT 	(SY6545S),A         	;
	CALL 	VDU_UPDATECHECK 	; WAIT FOR VDU TO BE READY
	LD 	HL, (VDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	DE,0050H		; SET AMOUNT TO ADD
	ADD	HL,DE			; ADD TO START POS
	LD	(VDU_DISPLAY_START),HL	; STORE DISPLAY START
	LD 	A, 12			; SAVE START OF DISPLAY TO VDU
	CALL 	VDU_HL2WREG_A		;
    	LD	A,23			; SET CURSOR TO BEGINNING OF LAST LINE
    	LD	(TERM_Y),A		;
    	LD	A,(TERM_X)		;
    	PUSH	AF			; STORE X COORD
    	LD	A,0			;
    	LD	(TERM_X),A		;
    	CALL	GOTO_XY			; SET CURSOR POSITION TO BEGINNING OF LINE
    	CALL	PERF_ERASE_EOL		; ERASE SCROLLED LINE
	POP	AF			; RESTORE X COORD
	LD	(TERM_X),A		;
    	CALL	GOTO_XY			; SET CURSOR POSITION
    	POP	BC			; RESTORE BC
    	POP	HL			; RESTORE HL
    	POP	AF			; RESTORE AF
    	RET				;
    	
;__REVERSE_SCROLL__________________________________________________________________________________
;
; 	SCROLL THE SCREEN DOWN ONE LINE
;__________________________________________________________________________________________________			
REVERSE_SCROLL:
	PUSH	AF			; STORE AF
	PUSH	HL			; STORE HL
	PUSH	BC			; STORE BC
	LD 	A, 31            	; TOGGLE VDU FOR UPDATE
	OUT 	(SY6545S),A         	;
	CALL 	VDU_UPDATECHECK 	; WAIT FOR VDU TO BE READY
	LD 	HL, (VDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	DE,0FFB0H		; SET AMOUNT TO SUBTRACT (TWOS COMPLEMENT 50H)
	ADD	HL,DE			; ADD TO START POS
	LD	(VDU_DISPLAY_START),HL	; STORE DISPLAY START
	LD 	A, 12			; SAVE START OF DISPLAY TO VDU
	CALL 	VDU_HL2WREG_A		;
    	LD	A,23			; SET CURSOR TO BEGINNING OF LAST LINE
    	LD	(TERM_Y),A		;
    	LD	A,(TERM_X)		;
    	PUSH	AF			; STORE X COORD
    	LD	A,0			;
    	LD	(TERM_X),A		;
    	CALL	GOTO_XY			; SET CURSOR POSITION TO BEGINNING OF LINE
    	CALL	PERF_ERASE_EOL		; ERASE SCROLLED LINE
	POP	AF			; RESTORE X COORD
	LD	(TERM_X),A		;
    	CALL	GOTO_XY			; SET CURSOR POSITION
    	POP	BC			; RESTORE BC
    	POP	HL			; RESTORE HL
    	POP	AF			; RESTORE AF
    	RET				;
    			
	
	
;__IS_KBHIT________________________________________________________________________________________
;
; 	WAS A KEY PRESSED?
;__________________________________________________________________________________________________			
IS_KBHIT:
	CALL 	KB_PROCESS		; CALL KEYBOARD ROUTINE
	LD 	A,(KB_QUEUE_PTR)	; ASK IF KEYBOARD HAS KEY WAITING
	OR	A
	JP	Z,CIO_IDLE
	LD	A,$FF			; SIGNAL DATA PENDING
	RET
	
				
;__WAIT_KBHIT______________________________________________________________________________________
;
; 	WAIT FOR A KEY PRESS
;__________________________________________________________________________________________________			
WAIT_KBHIT:
	CALL	IS_KBHIT
	JR	Z,WAIT_KBHIT
	RET

	
;__GET_KEY_________________________________________________________________________________________
;
; 	GET KEY PRESS VALUE
;__________________________________________________________________________________________________			
GET_KEY:
	CALL	WAIT_KBHIT		; WAIT FOR A KEY
	LD	A,(KB_QUEUE_PTR)	; GET QUEUE POINTER
	OR	A			;
	RET	Z			; ABORT IF QUEUE EMPTY
	PUSH	BC			; STORE BC
	LD	B,A			; STORE QUEUE COUNT FOR LATER
	PUSH	HL			; STORE HL
	LD	A,(KB_QUEUE)		; GET TOP BYTE FROM QUEUE
	PUSH 	AF			; STORE IT
	LD	HL,KB_QUEUE		; GET POINTER TO QUEUE
GET_KEY_LOOP:				;
	INC	HL			; POINT TO NEXT VALUE IN QUEUE
	LD	A,(HL)			; GET VALUE
	DEC 	HL			;
	LD	(HL),A			; MOVE IT UP ONE
	INC	HL			;
	DJNZ	GET_KEY_LOOP		; LOOP UNTIL DONE
	LD	A,(KB_QUEUE_PTR)	; DECREASE QUEUE POINTER BY ONE	
	DEC	A			;
	LD	(KB_QUEUE_PTR),A	;
	POP	AF			; RESTORE VALUE
	POP	HL			; RESTORE HL
	POP	BC			; RESTORE BC
	RET

		
		
	
	

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
	OUT 	(SY6545S),A		;
	LD	HL,0			; SET-UP START OF DISPLAY 
	LD 	DE, 2048    		; SET-UP DISPLAY SIZE
	LD 	A, 18            	; WRITE HL TO R18 AND R19 (UPDATE ADDRESS)
	CALL 	VDU_HL2WREG_A  		;
	LD 	A, 31            	; TOGGLE VDU FOR UPDATE
	OUT 	(SY6545S),A         	;
VDU_CRTSPACELOOP:			;
	CALL 	VDU_UPDATECHECK 	; WAIT FOR VDU TO BE READY
	LD 	A, ' '           	; CLEAR SCREEN
	OUT 	(WRITR),A         	; SEND SPACE TO DATAPORT
	DEC	DE			; DECREMENT DE
	LD 	A,D			; IS ZERO?
	OR 	E			;
	JP 	NZ, VDU_CRTSPACELOOP	; NO, LOOP
	LD 	A, 31            	; TOGGLE VDU FOR UPDATE
	OUT 	(SY6545S),A         	;
	LD 	HL, 0			; SET UP START OF DISPLAY
	LD	(VDU_DISPLAY_START),HL	; STORE DISPLAY START
	LD 	A, 12			; SAVE START OF DISPLAY TO VDU
	CALL 	VDU_HL2WREG_A		;
	POP 	HL			;
	POP 	DE			;
	POP 	AF			;
	CALL	PERF_CURSOR_HOME	; CURSOR HOME	
	CALL	PERF_ERASE_EOS		; CLEAR SCREEN
    	CALL 	VDU_CURSORON		; TURN ON CURSOR
	RET	
	

;;__DSPMATRIX_______________________________________________________________________________________
;;
;; 	DISPLAY INTRO SCREEN
;;__________________________________________________________________________________________________			
;DSPMATRIX:
;	CALL	PERF_CURSOR_HOME	; RESET CURSOR TO HOME POSITION
;   	LD	HL,TESTMATRIX		; SET HL TO SCREEN IMAGE
;	LD 	DE, 1918    		; SET IMAGE SIZE
;DSPMATRIX_LOOP:    	
;    	LD 	A,(HL)			; GET NEXT CHAR FROM IMAGE
;    	CALL 	VDU_PUTCHAR		; DUMP CHAR TO DISPLAY
;    	INC	HL			; INC POINTER
;	DEC	DE			; DEC COUNTER
;    	LD 	A,D			; IS COUNTER ZERO?
;    	OR 	E			;
;    	JP 	NZ,DSPMATRIX_LOOP	; NO, LOOP
;	CALL	PERF_CURSOR_HOME	; YES, RESET CURSOR TO HOME POSITION
;	RET

;TESTMATRIX:
;  .TEXT   "0         1         2         3         4         5         6         7         "
;  .TEXT   "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
;  .TEXT   "2                                                                               "
;  .TEXT   "3                                                                               "
;  .TEXT   "4                                                                               "
;  .TEXT   "5                                                                               "
;  .TEXT   "6           NN      NN      8888      VV      VV    EEEEEEEEEE   MM          MM "
;  .TEXT   "7          NNNN    NN    88    88    VV      VV    EE           MMMM      MMMM  "
;  .TEXT   "8         NN  NN  NN    88    88    VV      VV    EE           MM  MM  MM  MM   "
;  .TEXT   "9        NN    NNNN    88    88    VV      VV    EE           MM    MM    MM    "
;  .TEXT   "10      NN      NN      8888      VV      VV    EEEEEEE      MM          MM     "
;  .TEXT   "11     NN      NN    88    88     VV    VV     EE           MM          MM      "
;  .TEXT   "12    NN      NN    88    88      VV  VV      EE           MM          MM       "
;  .TEXT   "13   NN      NN    88    88        VVV       EE           MM          MM        "
;  .TEXT   "14  NN      NN      8888           V        EEEEEEEEEE   MM          MM   S B C "
;  .TEXT   "15                                                                              "  
;  .TEXT   "16                                                                              "
;  .TEXT   "17                                                                              "
;  .TEXT   "18                        * VDU OK *       VT-52 EMULATION                      "
;  .TEXT   "19                                                                              "
;  .TEXT   "20                  **  PRESS ANY KEY TO ENTER TERMINAL MODE **                 "
;  .TEXT   "21                                                                              "
;  .TEXT   "22                                                                              "
;  .TEXT   "23                                                                              "
;  .TEXT   "24                                                                              "


;__VDU_HL2WREG_A___________________________________________________________________________________
;
; 	WRITE VALUE IN HL TO REGISTER IN A
;	A: REGISTER TO UPDATE
;	HL: WORD VALUE TO WRITE
;__________________________________________________________________________________________________			
VDU_HL2WREG_A:
	PUSH 	BC			; STORE BC
	PUSH 	AF			; STORE AF
    	CALL 	VDU_UPDATECHECK 	; WAIT FOR VDU TO BE READY
    	POP 	AF			; RESTORE AF
    	LD 	C, SY6545S           	; ADDRESS REGISTER
    	OUT 	(C), A          	; SELECT REGISTER (A)
    	INC 	C               	; NEXT WRITE IN REGISTER
    	OUT 	(C), H          	; WRITE H TO SELECTED REGISTER
    	DEC 	C               	; NEXT WRITE SELECT REGISTER
    	INC 	A               	; INCREASE REGISTER NUMBER
    	OUT 	(C), A          	; SELECT REGISTER (A+1)
    	INC 	C              		; NEXT WRITE IN REGISTER
    	OUT 	(C), L          	; WRITE L TO SELECTED REGISTER
    	POP 	BC			; RESTORE BC
    	RET

;__VDU_UPDATECHECK_________________________________________________________________________________
;
; 	WAIT FOR VDU TO BE READY
;__________________________________________________________________________________________________			
VDU_UPDATECHECK:
    	IN 	A,(SY6545S)          	; READ ADDRESS/STATUS REGISTER
    	BIT 	7,A             	; IF BIT 7 = 1 THAN AN UPDATE STROBE HAS OCCURED
    	RET 	NZ			;
    	JR 	VDU_UPDATECHECK  	; WAIT FOR READY

VDU_INIT6845:
;     DB  07FH, 50H, 60H, 7CH, 19H, 1FH, 19H, 1AH, 78H, 09H, 60H, 09H, 00H, 00H, 00H, 00H
     .DB	 07Fh, 50h, 60h, 0Ch, 1Eh, 02h, 18h, 1Ch, 78h, 09h, 60h, 09h, 00h, 00h, 00h, 00h
     
     
;__VDU_CRTINIT_____________________________________________________________________________________
;
; 	INIT VDU CHIP
;__________________________________________________________________________________________________			   	
VDU_CRTINIT:
    	PUSH 	AF			; STORE AF
    	PUSH 	BC			; STORE BC
    	PUSH 	DE			; STORE DE
    	PUSH 	HL			; STORE HL
    	LD 	BC,010F2h         	; B = 16, C = SY6545S
    	LD 	HL,VDU_INIT6845  	; HL = POINTER TO THE DEFAULT VALUES
    	XOR 	A               	; A = 0
VDU_CRTINITLOOP:
    	OUT 	(C), A          	; SY6545S SET REGISTER
    	INC 	C               	; 0F3h
    	LD 	D,(HL)          	; LOAD THE NEXT DEFAULT VALUE IN D
    	OUT 	(C),D          		; 0F3h ADDRESS
    	DEC 	C               	; SY6545S
    	INC 	HL              	; TAB + 1
    	INC 	A               	; REG + 1
    	DJNZ 	VDU_CRTINITLOOP		; LOOP UNTIL DONE
    	POP 	HL			; RESTORE HL
    	POP 	DE			; RESTORE DE
    	POP	BC			; RESTORE BC
    	POP	AF			; RESTORE AF
    	RET


;__VDU_CURSORON____________________________________________________________________________________
;
; 	TURN ON CURSOR
;__________________________________________________________________________________________________			   	
VDU_CURSORON:
    	PUSH 	AF			; STORE AF
    	LD 	A, 060h			; SET CURSOR VALUE
    	JP 	VDU_CURSORSET		;

;__VDU_CURSOROFF___________________________________________________________________________________
;
; 	TURN OFF CURSOR
;__________________________________________________________________________________________________			   	   	
VDU_CURSOROFF:
    	PUSH 	AF			; STORE AF
    	LD 	A, 020h			; SET CURSOR VALUE
VDU_CURSORSET:
	PUSH 	BC			; STORE BC
    	LD 	C,A			; MOVE A TO C
    	CALL 	VDU_UPDATECHECK    	; WAIT FOR VDU TO BE READY
    	LD 	A, 10            	; R10, CURSOR START AND STATUS
    	OUT 	(SY6545S), A		; 
    	LD 	A,C			; STORE CURSOR VALUE
    	OUT 	(SY6545D), A        	;
    	POP 	BC			; RESTORE BC
    	POP 	AF			; RESTORE AF
    	RET

;__GOTO_XY_________________________________________________________________________________________
;
; 	MOVE CURSOR TO POSITON IN TERM_X AND TERM_Y
;__________________________________________________________________________________________________			
GOTO_XY:
	PUSH	AF			; STORE AF

	LD	A,(TERM_Y)		; PLACE Y COORD IN A
	CP	24			; IS 24?
	JP	Z,DO_SCROLL1		; YES, MUST SCROLL

    	PUSH 	BC			; STORE BC
    	PUSH 	DE			; STORE DE
	LD	A,(TERM_X)		;
	LD	H,A			;
    	LD	A,(TERM_Y)		;
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
    	OUT 	(SY6545S),A         	;
    	LD 	A, 14            	; SET CURSOR POS
    	CALL 	VDU_HL2WREG_A		;
    	POP 	DE			; RESTORE DE
   	POP 	BC			; RESTORE BC
    	POP 	AF			; RESTORE AF
    	RET

;__VDU_PUTCHAR______________________________________________________________________________________
;
; 	PLACE CHARACTER ON SCREEN
;	A: CHARACTER TO OUTPUT
;__________________________________________________________________________________________________			   	   	
VDU_PUTCHAR:
	PUSH	DE			; STORE DE
    	PUSH 	AF			; STORE AF
    	LD	A,(TERM_X)		; PLACE X COORD IN A
    	INC	A			; INC X COORD
    	LD	(TERM_X),A		; STORE IN A
    	CP	80			; IS 80?
    	JP	NZ,VDU_PUTCHAR1		; NO, PLACE CHAR ON DISPLAY
    	LD  	A,0			; YES, WRAP TO NEXT LINE
    	LD	(TERM_X),A		; STORE X
    	LD	A,(TERM_Y)		; A= Y COORD
    	INC 	A			; INC Y COORD
    	LD	(TERM_Y),A		; STORE Y
    	CP	24			; IS PAST END OF SCREEN?
    	CALL 	Z,GOTO_XY        	; YES, HANDLE SCROLLING
VDU_PUTCHAR1:				;
    	CALL 	VDU_UPDATECHECK		; WAIT FOR VDU TO BE READY
    					;
    	LD 	A, 31            	; TOGGLE VDU FOR UPDATE
    	OUT 	(SY6545S),A         	;
					;
    	CALL 	VDU_UPDATECHECK		; WAIT FOR VDU TO BE READY
					;
    	LD 	A, 31           	; TOGGLE VDU FOR UPDATE
    	OUT 	(SY6545S),A         	;
					;
    	POP 	AF			; RESTORE CHAR
    	OUT 	(WRITR), A		; OUTPUT CHAR TO VDU
    	PUSH 	AF			; STORE AF
    	PUSH 	HL			; STORE HL
    	LD 	HL, (VDU_DISPLAYPOS)	; GET CURRENT DISPLAY ADDRESS
    	INC 	HL			; INCREMENT IT
    	LD 	(VDU_DISPLAYPOS), HL	; STORE CURRENT DISPLAY ADDRESS
    	PUSH	HL			; MOVE HL TO DE
    	POP	DE			;
    	LD	HL,(VDU_DISPLAY_START)	;
    	ADD	HL,DE			;
    	LD 	A, 14			; UPDATE CURSOR POSITION IN HARDWARE
    	CALL 	VDU_HL2WREG_A		;
    	POP 	HL			; RESTORE HL
    	POP 	AF			; RESTORE AF
    	POP	DE			; RESTORE DE
    	RET

    	

    	
	

;;__PR_OUTCHAR______________________________________________________________________________________
;;
;; 	PR_OUTCHAR- OUTPUT CHAR TO PRINTER PORT
;;	A: CHAR TO OUTPUT
;;__________________________________________________________________________________________________			   	   	
;PR_OUTCHAR:
;	PUSH	AF			; STORE AF
;PR_OUTCHAR_LOOP:
;	IN	A,(PPIB)		; GET STATUS INFO	
;	AND	10000000B		; ONLY INTERESTED IN BUSY FLAG
;	JP	NZ,PR_OUTCHAR_LOOP	; LOOP IF BUSY
;	POP	AF			; RESTORE AF
;	OUT	(PPIA),A		; OUTPUT DATA TO PORT
;	LD 	A,1			;  01 SECOND DELAY 
;	CALL 	KB_DELAY		; IGNORE ANYTHING BACK AFTER A RESET
;	CALL	KB_PORTCBIT0LOW		; STROBE
;	LD 	A,1			;  01 SECOND DELAY 
;	CALL 	KB_DELAY		; IGNORE ANYTHING BACK AFTER A RESET
;	CALL	KB_PORTCBIT0HIGH	; STROBE
;	RET

;;__PR_INITIALIZE___________________________________________________________________________________
;;
;; 	INITIALISE - SET UP PORT FOR PRINTING
;;__________________________________________________________________________________________________			   	   	
;PR_INITIALIZE:
;	CALL	KB_PORTCBIT0HIGH	; STROBE
;	CALL	KB_PORTCBIT1HIGH	; FORM FEED
;	CALL	KB_PORTCBIT2LOW		; DEVICE SELECT
;	CALL	KB_PORTCBIT3LOW		; DEVICE INIT
;	LD 	A,200			; 1 SECOND DELAY 
;	CALL 	KB_DELAY		; IGNORE ANYTHING BACK AFTER A RESET
;	CALL	KB_PORTCBIT3HIGH	; DEVICE INIT
;	RET
		

;__KB_INITIALIZE___________________________________________________________________________________
;
; 	INITIALISE - CLEAR SOME LOCATIONS AND SEND A RESET TO THE KEYBOARD
;__________________________________________________________________________________________________			   	   	
KB_INITIALIZE:
	CALL 	KB_SETPORTC		; SETS PORT C SO CAN INPUT AND OUTPUT
	CALL 	KB_RESET		; RESET TO THE KEYBOARD
	LD 	A,200			; 1 SECOND DELAY AS KEYBOARD SENDS STUFF BACK WHEN RESET
	CALL 	KB_DELAY		; IGNORE ANYTHING BACK AFTER A RESET
	LD	A,0			; EMPTY KB QUEUE
	LD	(KB_QUEUE_PTR),A	; 
	RET


;__KB_RESET________________________________________________________________________________________
;
; 	RESET THE KEYBOARD
;__________________________________________________________________________________________________			   	   	
KB_RESET:
	CALL 	KB_DATAHIGH		;
	CALL 	KB_CLOCKHIGH		;
	LD 	B,255			;
SF1:	DJNZ 	SF1			;
	CALL 	KB_CLOCKLOW		; STEP 1
	LD 	B,255			;
SF2:	DJNZ 	SF2			;
	CALL 	KB_DATALOW		; STEP 2
	CALL 	KB_CLOCKHIGH		; STEP 3
	CALL 	KB_WAITCLOCKLOW		; STEP 4
	LD	B,9			; 8 DATA BITS + 1 PARITY BIT LOW
SF3:	PUSH 	BC			;
	CALL 	KB_DATAHIGH		; STEP 5
	CALL 	KB_WAITCLOCKHIGH	; STEP 6
	CALL 	KB_WAITCLOCKLOW		; STEP 7
	POP 	BC			;
	DJNZ 	SF3			;
	CALL 	KB_DATAHIGH		; STEP9
	CALL 	KB_WAITCLOCKLOW		; STEP 10 COULD READ THE ACK BIT HERE IF WANT TO
	CALL 	KB_WAITCLOCKHIGH	; STEP 11
	LD 	B,255			;
SF4:	DJNZ 	SF4			; FINISH UP DELAY
	RET

;__KB_SETPORTC_____________________________________________________________________________________
;
; 	SETUP PORT C OF 8255 FOR KEYBOARD
;__________________________________________________________________________________________________			   	   	
KB_SETPORTC:
	LD 	A,10000010B		; A=OUT B=IN, C HIGH=OUT, CLOW=OUT
	OUT 	(PPICONT),A		; PPI CONTROL PORT
	LD 	A,00000000B		; PORT A TO ZERO AS NEED THIS FOR COMMS TO WORK
	OUT	(PPIA),A		; PPI PORT A
	CALL 	KB_DATAHIGH		;
	CALL 	KB_CLOCKHIGH		;
	LD 	A,0			;
	LD 	(CAPSLOCK),A		; SET CAPSLOCK OFF TO START
	LD 	(CTRL),A		; CONTROL OFF
	LD 	(NUMLOCK),A		; NUMLOCK OFF
	RET
;_________________________________________________________________________________________________
;
; 	PORT C BIT ROUTINES
;__________________________________________________________________________________________________			   	   	
KB_PORTCBIT0HIGH:			;
	LD 	A,01110001B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_PORTCBIT1HIGH:			;
	LD 	A,01110011B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_PORTCBIT2HIGH:			;
	LD 	A,01110101B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_PORTCBIT3HIGH:			;
	LD 	A,01110111B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_PORTCBIT0LOW:			;
	LD 	A,01110000B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_PORTCBIT1LOW:			;
	LD 	A,01110010B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_PORTCBIT2LOW:			;
	LD 	A,01110100B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_PORTCBIT3LOW:			;
	LD 	A,01110110B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_DATAHIGH:
KB_PORTCBIT4HIGH:			;
	LD 	A,01111001B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_DATALOW:				;
KB_PORTCBIT4LOW:			;
	LD 	A,01111000B		; SEE THE 8255 DATA SHEET
	JP	KB_SETBITS		;
KB_CLOCKHIGH:				;
KB_PORTCBIT5HIGH:			;
	LD 	A,01111011B		; BIT 5 HIGH
	JP	KB_SETBITS		;
KB_CLOCKLOW:				;
PORTCBIT5LOW:				;
	LD 	A,01111010B		;
KB_SETBITS:				;
	OUT 	(PPICONT),A		;
	RET				;



;__KB_WAITCLOCKLOW_________________________________________________________________________________
;
; WAITCLOCKLOW SAMPLES DATA BIT 0, AND WAITS TILL
; IT GOES LOW, THEN RETURNS
; ALSO TIMES OUT AFTER 0 001 SECONDS
; USES A, CHANGES B
;__________________________________________________________________________________________________			   	   	
KB_WAITCLOCKLOW:
	LD 	B,255		; FOR TIMEOUT COUNTER
WL1:	IN 	A,(PPIB)	; GET A BYTE FROM PORT B
	BIT 	1,A		; TEST THE CLOCK BIT
	RET 	Z		; EXIT IF IT WENT LOW
	DJNZ 	WL1		; LOOP B TIMES
	RET

	
;__KB_WAITCLOCKHIGH_________________________________________________________________________________
;
; WAITCLOCKHIGH SAMPLES DATA BIT 0, AND WAITS TILL
; IT GOES HIGH, THEN RETURNS
; ALSO TIMES OUT AFTER 0 001 SECONDS
; USES A, CHANGES B
;__________________________________________________________________________________________________			   	   	
KB_WAITCLOCKHIGH:	
	LD 	B,255		; FOR TIMEOUT COUNTER
WH1:	IN 	A,(PPIB)	; GET A BYTE FROM PORT B
	BIT 	1,A		; TEST THE CLOCK BIT
	RET 	NZ		; EXIT IF IT WENT HIGH
	DJNZ 	WH1		; LOOP B TIMES
	RET

;__KB_DELAY________________________________________________________________________________________
;
; PASS A - DELAY IS B*0 005 SECONDS, BCDEHL ALL PRESERVED
;__________________________________________________________________________________________________			   	   	
KB_DELAY:	
	PUSH 	BC		; STORE ALL VARIABLES
	PUSH 	DE		;
	PUSH 	HL		;
	LD 	B,A		; PUT THE VARIABLE DELAY IN B
	LD 	DE,1		;
LOOP1:	LD 	HL,740		; ADJUST THIS VALUE FOR YOUR CLOCK 1481=3 68MHZ, 3219=8MHZ (TEST WITH A=1000=10 SECS)
LOOP2:	SBC 	HL,DE		; HL-1
	JR 	NZ,LOOP2	;
	DJNZ 	LOOP1		;
	POP 	HL		; RESTORE VARIABLES
	POP 	DE		;
	POP 	BC		;
	RET			;


;__KB_PROCESS______________________________________________________________________________________
;
;  A=0 IF WANT TO KNOW IF A BYTE IS AVAILABLE, AND A=1 TO ASK FOR THE BYTE
;__________________________________________________________________________________________________			   	   	
KB_PROCESS:	
	CALL	SKIP		; DON'T TEST EVERY ONE AS TAKES TIME
	OR	A		; IS IT ZERO
	RET	Z		; RETURN IF ZERO
 	CALL	KB_WAITBYTE	; TEST KEYBOARD  TIMES OUT AFTER A BIT
	CALL 	KB_DECODECHAR	; RETURNS CHAR OR 0 FOR THINGS LIKE KEYUP, SOME RETURN DIRECTLY TO CP/M
	RET			; RETURN TO CP/M

	
;-----------------------------------------------
; CPM CALLS THE KEYBOARD QUITE FREQUENTLY  IF A KEYBOARD WAS LIKE A UART WHICH CAN BE CHECKED
; WITH ONE INSTRUCTION, THAT WOULD BE FINE  BUT CHECKING A KEYBOARD INVOLVES PUTTING THE CLOCK LINE LOW
; THEN WAITING SOME TIME FOR A POSSIBLE REPLY, THEN READING IN BITS WITH TIMEOUTS AND THEN RETURNING
; THIS SLOWS DOWN A LOT OF CP/M PROCESSES, EG TRY TYPE MYPROG AND PRINTING OUT TEXT
SKIP:
	LD	B,0		;
	LD 	A,(SKIPCOUNT)	;
	DEC	A		; SUBTRACT 1
	LD	(SKIPCOUNT),A	; STORE IT BACK
	CP 	0		;
	JP	NZ,SK1		; WORDSTAR IS VERY SLOW EVEN TRIED A VALUE OF 5 TO 200 HERE
	LD	A,200		; ONLY ACT ON EVERY N CALLS - BIGGER=BETTER BECAUSE THIS SUB IS QUICKER THAN READBITS
	LD	(SKIPCOUNT),A	; RESET COUNTER
	LD 	B,1		; FLAG TO SAY RESET COUNTER
SK1:				;
	LD	A,B		; RETURN THE VALUE IN A
	RET

	
;__KB_DECODECHAR____________________________________________________________________________________
;
; DECODE CHARACTER PASS A AND PRINTS OUT THE CHAR
; ON THE LCD SCREEN
;__________________________________________________________________________________________________			   	   	
KB_DECODECHAR:
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
	LD 	HL,NORMALKEYS	; OFFSET TO ADD
	ADD 	HL,BC		;
	JP	TESTCONTROL	; IS THE CONTROL KEY DOWN?
DC1:	LD 	A,(CAPSLOCK)	;
	CP 	0		; IS IT 0, IF SO THEN DON'T ADD THE CAPS OFFSET
	JR 	Z,DC2		;
	LD 	C,080H		; ADD ANOTHER 50H TO SMALLS TO GET CAPS
	ADD 	HL,BC		;
DC2:	LD 	A,(HL)		;
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
TESTCONTROL:
	LD 	A,(CTRL)	;
	CP 	0		; IS CONTROL BEING HELD DOWN?
	JP	Z,DC1		; NO SO GO BACK TO TEST CAPS LOCK ON
	LD	A,(HL)		; GET THE LETTER, SHOULD BE SMALLS 
	SUB	96		; A=97 SO SUBTRACT 96 A=1=^A
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			; RETURN INSTEAD OF THE RET AFTER DC2
TABKEY:				;
	LD 	A,9		;
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;TAB
BACKSPACE:			;
	LD	A,8		; BACKSPACE
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
ESCAPE:				;
	LD	A,27		;
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
RETURN:				;
	LD	A,13		; CARRIAGE RETURN
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
DECKEYUP:
	CALL KB_WAITBYTE	; IGNORE KEY UP THROW AWAY THE CHARACTER UNLESS A SHIFT 
	CP	012H		; IS IT A SHIFT
	JP 	Z,SHIFTUP	;
	CP	59H		; OTHER SHIFT KEY
	JP	Z,SHIFTUP	;
	CP	014H		; CONTROL UP
	JP 	Z,CONTROLUP	; CONTROL UP
	LD	A,0		; NOTHING CAPTURED SO SEND BACK A ZERO 
	RET
TWOBYTE:; ALREADY GOT EO SO GET THE NEXT CHARACTER
	CALL 	KB_WAITBYTE
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
	CALL	KB_WAITBYTE	;
	LD	A,0		;
	RET			;
HOME:				;
	LD	A,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'W'		; W
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
END:				;
	LD	A,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'Q'		; Q
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
DOWNARROW:			;
	LD	A,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'B'		; B
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
RIGHTARROW:			;
	LD	A,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'C'		; C
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
LEFTARROW:			;
	LD	A,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'D'		; D
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
UPARROW:			;
	LD	A,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD 	A,'A'		; A
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;	
INSERT:				;
	LD	A,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'P'		; P
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
PAGEUP:				;
	LD	A,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'Y'		; Y
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
PAGEDOWN:			;
	LD	A,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	LD	A,'S'		; S
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
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
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	RET			;
DELETEKEY:			;
	LD 	A,07FH		; DELETE KEY VALUE THAT CP/M USES
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
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

;__KB_ENQUEUE______________________________________________________________________________________
;
;  STORE A BYTE IN THE KEYBOARD QUEUE 
;  A: BYTE TO ENQUEUE
;__________________________________________________________________________________________________			   	   		
KB_ENQUEUE:
	PUSH	DE		; STORE DE
	PUSH	HL		; STORE HL	
	PUSH	AF		; STORE VALUE
	LD	A,(KB_QUEUE_PTR); PUT QUEUE POINTER IN A
	CP	15		; IS QUEUE FULL
	JP	P,KB_ENQUEUE_AB	; YES, ABORT	
	LD	HL,KB_QUEUE	; GET QUEUE POINTER
	PUSH	HL		; MOVE HL TO BC
	POP	BC		; 
	LD	H,0		; ZERO OUT H
	LD	L,A		; PLACE QUEUE POINTER IN L
	ADD	HL,BC		; POINT HL AT THE NEXT LOACTION TO ADD VALUE
	POP	AF		; RESTORE VALUE
	LD	(HL),A		; ENQUEUE VALUE
	LD	A,(KB_QUEUE_PTR); GET QUEUE POINTER
	INC	A		; INC IT
	LD	(KB_QUEUE_PTR),A ;STORE QUEUE POINTER
KB_ENQUEUE_AB:
	POP	HL		; RESTORE HL
	POP	DE		; RESTORE DE
	RET
	
	
;__KB_WAITBYTE_____________________________________________________________________________________
;
; WAIT FOR A BYTE - TESTS A NUMBER OF TIMES IF THERE IS A KEYBOARD INPUT,
; OVERWRITES ALL REGISTERS, RETURNS BYTE IN A
;__________________________________________________________________________________________________			   	   		
KB_WAITBYTE:	
	CALL	KB_CLOCKHIGH	; TURN ON KEYBOARD
	LD 	HL,500		; NUMBER OF TIMES TO CHECK 200=SLOW TYPE
				; 10=ERROR, 25 ?ERROR 50 OK - 
				; THIS DELAY HAS TO BE THERE OTHERWISE WEIRD KEYUP ERRORS
WB1:	PUSH 	HL		; STORE COUNTER
	CALL 	KB_READBITS	; TEST FOR A LOW ON THE CLOCK LINE
	POP 	HL		; GET THE COUNTER BACK
	CP	0		; TEST FOR A ZERO BACK FROM READBITS
	JR	NZ,WB2		; IF NOT A ZERO THEN MUST HAVE A BYTE IE A KEYBOARD PRESS
	LD	DE,1		; LOAD WITH 1
	SBC 	HL,DE		; SUBTRACT 1
	JR	NZ,WB1		; LOOP WAITING FOR A RESPONSE
WB2:	PUSH 	AF		; STORE THE VALUE IN A
	CALL 	KB_CLOCKLOW	; TURN OFF KEYBOARD
	POP AF			; GET BACK BYTE AS CLOCKLOW ERASED IT
	RET

;__KB_READBITS_____________________________________________________________________________________
;
; READBITS READS 11 BITS IN FROM THE KEYBOARD
; FIRST BIT IS A START BIT THEN 8 BITS FOR THE BYTE
; THEN A PARITY BIT AND A STOP BIT
; RETURNS AFTER ONE MACHINE CYCLE IF NOT LOW
; USES A, B,D, E 
; RETURNS A=0 IF NO DATA, A= SCANCODE (OR PART THEREOF)
;__________________________________________________________________________________________________			   	   		
KB_READBITS:
	IN 	A,(PPIB)
	BIT 	1,A		; TEST THE CLOCK BIT
	JR 	Z,R1		; IF LOW THEN START THE CAPTURE
	LD 	A,0		; RETURNS A=0 IF NOTHING
	RET			;
R1:	CALL 	KB_WAITCLOCKHIGH; IF GETS TO HERE THEN MUST BE LOW SO WAIT TILL HIGH
	LD 	B,8		; SAMPLE 8 TIMES
	LD 	E,0		; START WITH E=0
R2:	LD 	D,B		; STORE BECAUSE WAITCLOCKHIGH DESTROYS
	CALL 	KB_WAITCLOCKLOW	; WAIT TILL CLOCK GOES LOW
	IN 	A,(PPIB)	; SAMPLE THE DATA LINE
	RRA			; MOVE THE DATA BIT INTO THE CARRY REGISTER
	LD 	A,E		; GET THE BYTE WE ARE BUILDING IN E
	RRA			; MOVE THE CARRY BIT INTO BIT 7 AND SHIFT RIGHT
	LD 	E,A		; STORE IT BACK  AFTER 8 CYCLES 1ST BIT READ WILL BE IN B0
	CALL 	KB_WAITCLOCKHIGH; WAIT TILL GOES HIGH
	LD 	B,D		; RESTORE FOR LOOP
	DJNZ 	R2		; DO THIS 8 TIMES
	CALL 	KB_WAITCLOCKLOW	; GET THE PARITY BIT
	CALL 	KB_WAITCLOCKHIGH;
	CALL 	KB_WAITCLOCKLOW	; GET THE STOP BIT
	CALL 	KB_WAITCLOCKHIGH;	
	LD 	A,E		; RETURNS WITH ANSWER IN A
	RET
	
NORMALKEYS:
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

SHIFTKEYS:
	.DB	$00, $00, $00, $00, $00, $00, $00, $00
	.DB	$00, $00, $00, $00, $00, 009, "~", $00	; $09=TAB
	.DB	$00, $00, $00, $00, $00, "Q", "!", $00
	.DB	$00, $00, "Z", "S", "A", "W", "@", $00
	.DB	$00, "C", "X", "D", "E", "$", "#", $00
	.DB	$00, " ", "V", "F", "T", "R", "%", $00
	.DB	$00, "N", "B", "H", "G", "Y", "^", $00
	.DB	$00, $00, "M", "J", "U", "&", "*", $00
	.DB	$00, "<", "K", "I", "O", ")", "(", $00
	.DB	$00, ">", "?", "L", ":", "P", "_", $00
	.DB	$00, $00, 034, $00, "{", "+", $00, $00	; $22=DBLQUOTE
	.DB	$00, $00, $00, "}", $00, "|", $00, $00
	.DB	$00, $00, $00, $00, $00, $00, $00, $00
	.DB	$00, "1", $00, "4", "7", $00, $00, $00
	.DB	"0", ".", "2", "5", "6", "8", $00, $00
	.DB	$00, "+", "3", "-", "*", "9", $00, $00
;
;==================================================================================================
;   VDU DRIVER - DATA
;==================================================================================================
;
ALT_KEYPAD		.DB	0		; ALT KEYPAD ENABLED?	
GR_MODE			.DB	0		; GRAPHICS MODE ENABLED?
TERM_X			.DB	0		; CURSOR X
TERM_Y			.DB	0		; CURSOR Y
TERMSTATE		.DB	0		; TERMINAL STATE
						; 0 = NORMAL
        					; 1 = ESC RCVD
VDU_DISPLAYPOS		.DW 	0		; CURRENT DISPLAY POSITION
VDU_DISPLAY_START	.DW 	0		; CURRENT DISPLAY POSITION
CAPSLOCK		.DB	0		; location for caps lock, either 00000000 or 11111111
CTRL			.DB	0		; location for ctrl on or off 00000000 or 11111111
NUMLOCK			.DB	0		; location for num lock
SKIPCOUNT		.DB	0		; only check some calls, speeds up a lot of cp/m
KB_QUEUE		.FILL	16,0 		; 16 BYTE KB QUEUE
KB_QUEUE_PTR		.DB	0		; POINTER TO QUEUE
