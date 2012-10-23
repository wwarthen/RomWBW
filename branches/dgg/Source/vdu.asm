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
READR		 .EQU	0F0h		; READ VDU
WRITR		 .EQU	0F1h		; WRITE VDU
SY6545S		 .EQU	0F2h		; VDU STATUS/REGISTER
SY6545D		 .EQU	0F3h		;

STATE_NORMAL	 .EQU	00H		; NORMAL TERMINAL OPS
STATE_ESC	 .EQU	01H		; ESC MODE
STATE_DIR_L	 .EQU	02H		; ESC-Y X *
STATE_DIR_C	 .EQU	03H		; ESC-Y * X

ESC_KEY		 .EQU	1BH		; ESCAPE CODE
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
; FUNCTION JUMP TABLE
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
; NEW FUNCTION JUMP TABLE
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
	LD	(TERM_X),A
	LD	A,D
	LD	(TERM_Y),A
	CALL	GOTO_XY
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
	OUT 	(SY6545S),A
	CALL 	VDU_WAITRDY		; WAIT FOR VDU TO BE READY
	LD	A,E
	OUT 	(WRITR),A		; OUTPUT CHAR TO VDU

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
    	OUT 	(SY6545S),A
VDU_VDAFIL1:
	LD	A,H		; CHECK NUMBER OF FILL CHARS LEFT
	OR	L			
	JR	Z,VDU_VDAFIL2	; ALL DONE, GO TO COMPLETION
	CALL	VDU_WAITRDY	; WAIT FOR VDU TO BE READY
	LD	A,E
    	OUT 	(WRITR), A	; OUTPUT CHAR TO VDU
	DEC	HL		; DECREMENT COUNT
	JR	VDU_VDAFIL1	; LOOP AS NEEDED
VDU_VDAFIL2:
	CALL	GOTO_XY		; YES, MOVE CURSOR BACK TO ORIGINAL POSITION
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
   	IN 	A,(SY6545S)	; READ STATUS
	OR	A		; SET FLAGS
	RET	M		; IF BIT 7 SET, THEN READY!
	JR	VDU_WAITRDY	; KEEP CHECKING
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
;	CALL 	KB_INITIALIZE		; INIT KB
;	CALL	PR_INITIALIZE		; INIT PR
    	
;    	CALL	DSPMATRIX		; DISPLAY INIT MATRIX SCREEN
;	CALL	WAIT_KBHIT		; WAIT FOR A KEYSTROKE
;	LD	A,0			; EMPTY KB QUEUE
;	LD	(KB_QUEUE_PTR),A	; 
	
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
;	LD	A,ESC_KEY		;
;	CALL	KB_ENQUEUE		; STORE ON KB QUEUE
;	LD	A,'/'			;
;	CALL	KB_ENQUEUE		; STORE ON KB QUEUE
;	LD	A,'K'			;
;	CALL	KB_ENQUEUE		; STORE ON KB QUEUE
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
	PUSH 	BC		; STORE BC
;	PUSH 	AF		; STORE AF
;    	CALL 	VDU_UPDATECHECK ; WAIT FOR VDU TO BE READY
;    	POP 	AF		; RESTORE AF
    	LD 	C, SY6545S	; ADDRESS REGISTER
    	OUT 	(C), A		; SELECT REGISTER (A)
    	INC 	C		; NEXT WRITE IN REGISTER
    	OUT 	(C), H		; WRITE H TO SELECTED REGISTER
    	DEC 	C		; NEXT WRITE SELECT REGISTER
    	INC 	A		; INCREASE REGISTER NUMBER
    	OUT 	(C), A		; SELECT REGISTER (A+1)
    	INC 	C		; NEXT WRITE IN REGISTER
    	OUT 	(C), L		; WRITE L TO SELECTED REGISTER
    	POP 	BC		; RESTORE BC
    	RET

;__VDU_UPDATECHECK_________________________________________________________________________________
;
; 	WAIT FOR VDU TO BE READY
;__________________________________________________________________________________________________			
VDU_UPDATECHECK:
   	IN 	A,(SY6545S)          ; READ ADDRESS/STATUS REGISTER
    	BIT 	7,A             	; IF BIT 7 = 1 THAN AN UPDATE STROBE HAS OCCURED
    	RET 	NZ
    	JR 	VDU_UPDATECHECK  	; WAIT FOR READY

VDU_INIT6845:
;     DB  07FH, 50H, 60H, 7CH, 19H, 1FH, 19H, 1AH, 78H, 09H, 60H, 09H, 00H, 00H, 00H, 00H

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
; THE CCIR 625/50 TELEVISION STANDARD HAS 625 LINES INTERLACED AT 50 FIELDS PER SECOND.  THIS WORKS 
; OUT AS 50 FIELDS OF 312.5 LINES PER SECOND NON-INTERLACED AS USED HERE.
; HORIZONTAL LINE WIDTH IS 64uS.  FOR A 2 MHz CHARACTER CLOCK (R0+1)/2000000 = 64uS
; NEAREST NUMBER OF LINES IS 312 = (R4+1) * (R9+1) + R5.
; 15625 / 312 = 50.08 FIELDS PER SECOND (NEAR ENOUGH-DGG)
;
; IF TRYING THE SLOWER CHAR CLOCK TO GIVE 9 PIXELS HORIZONTAL PER CHAR, CHANGE THE FOLLOWING
; JUMPER K1 1-2 TO GIVE 1.777MHz CHAR CLOCK
; CHANGE R0 TO 112 FOR A HSYNC OF 15732
; CHANGE R2 TO 91 TO CENTRE DISPLAY     
     
     
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
;	IN	A,(VPPIB)		; GET STATUS INFO	
;	AND	10000000B		; ONLY INTERESTED IN BUSY FLAG
;	JP	NZ,PR_OUTCHAR_LOOP	; LOOP IF BUSY
;	POP	AF			; RESTORE AF
;	OUT	(VPPIA),A		; OUTPUT DATA TO PORT
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
