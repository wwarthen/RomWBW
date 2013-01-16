; ansi.asm 12/3/2012 dwg - changed polarity of conditional jump for normal processing

; Status: Still very experimental, either doesn't work or is buggy
 
; WBW: BOGUS EQUATE TO GET MODULE TO BUILD FOR NON-N8 HARDWARE
; NEEDS TO BE FIXED BEFORE IT WILL WORK FOR ANYTHING OTHER THAN N8
#IF (!N8VENABLE)
#DEFINE	N8V_OFFSET	PANIC
#ENDIF

;
;==================================================================================================
;   ANSI EMULATION MODULE
;==================================================================================================
;

; The ANSI handler is a superset of the TTY handler in that is does simple 
; processing of control characters such as CR, LF... But in addition is Hasbro
; a state machine driven escape sequence parser that accepts parameters and 
; command characters and builds a table of data required to perform the indicated
; operation.

; For instance, a screen clear escaper sequence such as <esc>[2J is parsed as
; a leading CSI ()escape which places us in state1 (waiting for [ ). When the 
; next character arrives and turns out to be [, the parser's next state is 
; state2.

; State2 processing is a little more complex. If the next character is a numeral,
; it is placed in the parameter1 buffer and the next state is state3 (collecting 
; parameter1).

; State3 processing implies that the buffer already has 1 byte of a parameter in 
; the parameter1 buffer. If the next character is a semi-colon, that implies that 
; the parameter1 buffer is complete and the next state should be state4. If the 
; next byte is a numeral, it is appended to the parameter1 buffer and we stay INC
; state3. If the nect character is a semi-colon, that indicates the parameter1 is 
; complete and we need to enter state4 to begin collection of parameter2. If the 
; next character is neither a numeral or a semi-colon, then it needs 
; to be decoded as a command. Commands result in the calling of low-level driver 
; functions to perform the indicated operation. Subsequently we return to state0.

; State4 processing implies we are collecting parameter2 data. If the next byte
; is a numeral, it is assigned to the parameter2 buffer. In this case we go to 
; state5 which is used to finish collection of parameter2.

; State5 processing is for collecting additional parameter2 bytes to be appended
; to the parameter2 buffer. When a non-numeral arrives, that implies that parameter2
; is complete and the new character is either a semi-colon or the awaited command 
; character. If it is a semi-colon, that would imply the existance of a parameter3,
; which may or may not be supported in this implementation. If it is the command
; character, then the propper low-level driver calls need to be invoked to perform
; the desired operations on the video screen.

; Once state5 is complete, we re-enter state0.

ANSI_ERR1		.EQU	1


ANSI_CMD_DISP:
	LD	A,B
	CP	'J'
	JR	ANSI_CMD_NOT_CRTCLR
	
	; THIS IS THE CRTCLR FUNCTIONAL CODE	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LD	DE,0			; row 0 column 0
	LD	B,BF_VDASCP		; FUNCTION IS SET CURSOR POSITION
	CALL EMU_VDADISP	; CALL THE VIDEO HARDWARE DRIVER
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LD	DE,0		; row 0 column 0
	LD	B,BF_VDAQRY	; FUNCTION IS QUERY FOR SCREEN SIZE
	LD	HL,0		; WE DO NOT WANT A COPY OF THE CHARACTER BITMAP DATA
	CALL	EMU_VDADISP	; PERFORM THE QUERY FUNCTION
	; on return, D=row count, E=column count	
	; for the fill call, we need hl=number of chars to fill
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	LD	E,' '		; fill with spaces
	;
	LD	A,(ANSI_ROWS)	; given A = number of rows
	CALL N8V_OFFSET		; return HL = num_rows * num_cols
	;	
	LD	B,BF_VDAFIL	; FUNCTION IS FILL
	CALL	EMU_VDADISP	; PERFORM THE QUERY FUNCTION
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	XOR	A
	RET					; return SUCCESS to caller
	;
ANSI_CMD_NOT_CRTCLR:

	CP	66h			; is it cursor position?
	JR	ANSI_CMD_NOT_CRTLC
	
ANSI_CMD_NOT_CRTLC:

; since only the crtclr and crtlc are supported right now...
; any other command is an error
	CALL	PANIC	; A has the unknown command byte

;------------------------------------------------------------------------------------
ANSI_IS_NUMERAL:
	RET

;------------------------------------------------------------------------------------
ANSI_IS_ALPHA:
	RET
;------------------------------------------------------------------------------------
ANSI_MARSHALL_PARM1:
	RET
;------------------------------------------------------------------------------------
ANSI_MARSHALL_PARM2:
	RET
;------------------------------------------------------------------------------------
ANSI_PROC_COMMAND:
	RET
;------------------------------------------------------------------------------------
	

ANSI_STATE1:
	; Waiting for [
	; (the only valid character to follow an ESC would be the [ )
	; (if we get something else, we go back to state0 and begin again)
	LD	A,B 
	CP	'['
	JR	NZ,ANSI_STATE1_ERR	; if not the expected [, go around
	LD	HL,ANSI_STATE2		; having found the [, set the next state
	LD	(ANSI_STATE),HL		; to state2 (waiting for a parm1 char).
	XOR	A					; set retcode to SUCCESS
	RET						; and return to caller
ANSI_STATE1_ERR:
	LD	HL,ANSI_STATE0
	LD	(ANSI_STATE),HL	; set next state to state 0
	LD	A,ANSI_ERR1		; "state1 expected [ not found"
	RET

;------------------------------------------------------------------------------------

ANSI_STATE2:
	; waiting for parm1
	LD	A,B
	CALL	ANSI_IS_NUMERAL
	JR		NZ,ANSI_STATE2_NOT_NUMERAL
	CALL	ANSI_MARSHALL_PARM1
	XOR	A					; set SUCCESS return code
	RET
ANSI_STATE2_NOT_NUMERAL:
	LD	A,B
	CP	59		; semi-colon	
	JR	NZ,ANSI_STATE2_NOT_SEMI
	LD	HL,ANSI_STATE3
	LD	(ANSI_STATE),HL		; set next state to waiting for parm2
	XOR	A
	RET						; return SUCCESS
ANSI_STATE2_NOT_SEMI:
	; if it is not a semi, or a numeral, it must be a command char
	LD HL,ANSI_STATE0		; after we do the command dispatcher, the
	LD	(ANSI_STATE),HL		; next state we will want is the default state
	JP	ANSI_CMD_DISP
	
ANSI_INIT:
	PRTS("ANSI: RESET$")
;
	JR	ANSI_INI	; REUSE THE INI FUNCTION BELOW
;

ANSI_STATE3:
	; waiting for parm2
	LD	A,B
	CALL	ANSI_IS_NUMERAL
	JR	NZ,ANSI_STATE3_NOT_NUMERAL
	CALL	ANSI_MARSHALL_PARM2
	XOR	A
	RET
ANSI_STATE3_NOT_NUMERAL:
	LD	A,B
	CALL	ANSI_PROC_COMMAND
	LD	HL,ANSI_STATE0
	LD	(ANSI_STATE),HL
	RET
;
;
ANSI_DISPATCH:
	LD	A,B		; GET REQUESTED FUNCTION
	AND	$0F		; ISOLATE SUB-FUNCTION
	JR	Z,ANSI_IN	; $30
	DEC	A
	JR	Z,ANSI_OUT	; $31
	DEC	A
	JR	Z,ANSI_IST	; $32
	DEC	A
	JR	Z,ANSI_OST	; $33
	DEC	A
	JR	Z,ANSI_CFG	; $34
	CP	8
	JR	Z,ANSI_INI	; $38
	CP	9
	JR	Z,ANSI_QRY	; $39
	CALL	PANIC
;
;
;
ANSI_IN:
	LD	B,BF_VDAKRD	; SET FUNCTION TO KEYBOARD READ
	JP	EMU_VDADISP	; CHAIN TO VDA DISPATCHER
;
;
;
ANSI_OUT:
	LD	HL,(ANSI_STATE)
	JP	(HL)

;;	CALL	ANSI_DOCHAR	; HANDLE THE CHARACTER (EMULATION ENGINE)
;;	XOR	A		; SIGNAL SUCCESS
;;	RET

;
;
;
ANSI_IST:
	LD	B,BF_VDAKST	; SET FUNCTION TO KEYBOARD STATUS
	JP	EMU_VDADISP	; CHAIN TO VDA DISPATCHER
;
;
;
ANSI_OST:
	XOR	A		; ZERO ACCUM
	INC	A		; A := $FF TO SIGNAL OUTPUT BUFFER READY
	RET
;
;
;
ANSI_CFG:
	XOR	A		; SIGNAL SUCCESS
	RET
;
;
;
ANSI_INI:
	LD	HL,ANSI_STATE0		; load the address of the default state function
	LD	(ANSI_STATE),HL		; and place it in the ANSI_STATE variable for later.
	
	LD	B,BF_VDAQRY	; FUNCTION IS QUERY
	LD	HL,0		; WE DO NOT WANT A COPY OF THE CHARACTER BITMAP DATA
	CALL	EMU_VDADISP	; PERFORM THE QUERY FUNCTION
	LD	(ANSI_DIM),DE	; SAVE THE SCREEN DIMENSIONS RETURNED
	LD	DE,0		; DE := 0, CURSOR TO HOME POSITION 0,0
	LD	(ANSI_POS),DE	; SAVE CURSOR POSITION
	LD	B,BF_VDARES	; SET FUNCTION TO RESET
	JP	EMU_VDADISP	; RESET VDA AND RETURN
;
;
;
ANSI_QRY:
	XOR	A		; SIGNAL SUCCESS
	RET
;
;
;

	
	; This is probably the best place to insert a state sensitive 
	; dispatcher for handling ANSI escape sequences. Ansi sequences
	; are unusual because they contain a number of parameters 
	; subsequently followed by a command character that comes last.
	
	; It is wise to create a list of supported sequences so we know
	; before writing the parser what the most complex sequence will
	; consist of.
	
	; RomWBW utilities written by Douglas Goodall only use several
	; sequences. A screen clear, and a cursor position. 
	;
	; crtclr() uses <esc>[2J
	; crtlc()  uses <esc>[<line>;<column><0x66>
	
	; Programs such as wordstar use more complex operations.
	;
	;
;; ANSI_DOCHAR:
ANSI_STATE0:
	; ANSI_STATE0 is the default state where random output characters May
	; be normal visible characters, a control character such as BS, CR, LF...
	; or a CSI such as an escape character (27).


	LD	A,E		; CHARACTER TO PROCESS
	CP	8		; BACKSPACE
	JR	Z,ANSI_BS
	CP	12		; FORMFEED
	JR	Z,ANSI_FF
	CP	13		; CARRIAGE RETURN
	JR	Z,ANSI_CR
	CP	10		; LINEFEED
	JR	Z,ANSI_LF
	
	CP	27		; ESCAPE	; This is the hook into the escape handler
	JR	NZ,ANSI_NOT_ESC		; go around if not CSI
	LD	HL,ANSI_STATE1
	LD	(ANSI_STATE),HL
	XOR	A					; setup SUCCESS as return status
	RET
ANSI_NOT_ESC:

	CP	32		; COMPARE TO SPACE (FIRST PRINTABLE CHARACTER)
	RET	C		; SWALLOW OTHER CONTROL CHARACTERS

	; A reg has next character from BIOS CONOUT
	LD	B,BF_VDAWRC
	CALL	EMU_VDADISP	; SPIT OUT THE RAW CHARACTER

	LD	A,(ANSI_COL)	; GET CUR COL
	INC	A		; INCREMENT
	LD	(ANSI_COL),A	; SAVE IT
	LD	DE,(ANSI_DIM)	; GET SCREEN DIMENSIONS
	CP	E		; COMPARE TO COLS IN LINE
	RET	C		; NOT PAST END OF LINE, ALL DONE
	CALL	ANSI_CR		; CARRIAGE RETURN
	JR	ANSI_LF		; LINEFEED AND RETURN
;
ANSI_FF:
	LD	DE,0		; PREPARE TO HOME CURSOR
	LD	(ANSI_POS),DE	; SAVE NEW CURSOR POSITION
	CALL	ANSI_XY		; EXECUTE
	LD	DE,(ANSI_DIM)	; GET SCREEN DIMENSIONS
	LD	H,D		; SET UP TO MULTIPLY ROWS BY COLS
	CALL	MULT8		; HL := H * E TO GET TOTAL SCREEN POSITIONS
	LD	E,' '		; FILL SCREEN WITH BLANKS
	LD	B,BF_VDAFIL	; SET FUNCTION TO FILL
	CALL	EMU_VDADISP	; PERFORM FILL
	JR	ANSI_XY		; HOME CURSOR AND RETURN
;
ANSI_BS:
	LD	DE,(ANSI_POS)	; GET CURRENT ROW/COL IN DE
	LD	A,E		; GET CURRENT COLUMN
	CP	1		; COMPARE TO COLUMN 1
	RET	C		; LESS THAN 1, NOTHING TO DO
	DEC	E		; POINT TO PREVIOUS COLUMN
	LD	(ANSI_POS),DE	; SAVE NEW COLUMN VALUE
	CALL	ANSI_XY		; MOVE CURSOR TO NEW TARGET COLUMN
	LD	E,' '		; LOAD A SPACE CHARACTER
	LD	B,BF_VDAWRC	; SET FUNCTION TO WRITE CHARACTER
	CALL	EMU_VDADISP	; OVERWRITE WITH A SPACE CHARACTER
	JR	ANSI_XY		; NEED TO MOVE CURSOR BACK TO NEW TARGET COLUMN
;
ANSI_CR:
	XOR	A		; ZERO ACCUM
	LD	(ANSI_COL),A	; COL := 0
	JR	ANSI_XY		; REPOSITION CURSOR AND RETURN
;
ANSI_LF:
	LD	A,(ANSI_ROW)	; GET CURRENT ROW
	INC	A		; BUMP TO NEXT
	LD	(ANSI_ROW),A	; SAVE IT
	LD	DE,(ANSI_DIM)	; GET SCREEN DIMENSIONS
	CP	D		; COMPARE TO SCREEN ROWS
	JR	C,ANSI_XY	; NOT PAST END, ALL DONE
	DEC	D		; D NOW HAS MAX ROW NUM (ROWS - 1)
	SUB	D		; A WILL NOW HAVE NUM LINES TO SCROLL
	LD	E,A		; LINES TO SCROLL -> E
	LD	B,BF_VDASCR	; SET FUNCTION TO SCROLL
	CALL	EMU_VDADISP	; DO THE SCROLLING
	LD	A,(ANSI_ROWS)	; GET SCREEN ROW COUNT
	DEC	A		; A NOW HAS LAST ROW
	LD	(ANSI_ROW),A	; SAVE IT
	JR	ANSI_XY		; RESPOSITION CURSOR AND RETURN
;
ANSI_XY:
	LD	DE,(ANSI_POS)	; GET THE DESIRED CURSOR POSITION
	LD	B,BF_VDASCP	; SET FUNCTIONT TO SET CURSOR POSITION
	JP	EMU_VDADISP	; REPOSITION CURSOR
;
; The ANSI_STATE variable (word) contains the 
;    address of the next state function 
ANSI_STATE	.DW	ANSI_STATE0	; by default, ANSI_STATE0 
;
ANSI_POS:
ANSI_COL	.DB	0	; CURRENT COLUMN - 0 BASED
ANSI_ROW	.DB	0	; CURRENT ROW - 0 BASED
;
ANSI_DIM:
ANSI_COLS	.DB	80	; NUMBER OF COLUMNS ON SCREEN
ANSI_ROWS	.DB	24	; NUMBER OF ROWS ON SCREEN
