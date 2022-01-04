;
; Test program for Z80 KBDMSE on Retrobrewcomputer.org (Load with CPM).
;
;   V0.1			;Original version 2/23/2014 by John Monahan
;   V0.2			;Update for Z80 KBDMSE with VT82C42 PS/2 Keyboard Controller by Andrew Lynch
;
;	Based on works by John Monahan S100Computers.com
;   for S100 MSDOS Support Board with HT6542B Keyboard Controller
;   Thanks to John for generously posting this program for others to use and adapt
;
; This is a simple test program to work with the Z80 KBDMSE board. It is written so
; the only other hardware use is the CP/M Console Port -- typically serial port interface.
; Note the data is displayed in crude (bulk) form. A proper scancode to ASCII translation
; routine must be written for practical use.  See the IBM PC BIOS or SKEY.Z80 docs



;	PORT ASSIGNMENTS

KEY_DATA	.EQU	0E2H		;Port used to access keyboard & Mouse (also sometimes Controller itself)
KEY_CTRL	.EQU	0E3H		;Port for VT82C42 PS/2 Keyboard & Mouse Controller

ESC		.EQU	1BH
CR		.EQU	0DH
LF		.EQU	0AH
TAB		.EQU	09H
BELL		.EQU	07H

		.ORG	0100H
START:
	LD	SP,STACK

	LD	HL,SIGNON		; Signon
	CALL	PRINT_STRING

	LD	C,0AAH			;Test PS/2 Controller
	CALL	CMD_OUT
CHK1:
	CALL	KEY_IN_STATUS		;wait for feedback
	JR	Z,CHK1
	IN	A,(KEY_DATA)
	CP	055H			;If not 55H then error
	JR	NZ,INIT_ERR
	LD	C,060H			; Set keyboard controller cmd byte
	CALL	CMD_OUT
	LD	C,$60			; XLAT ENABLED, MOUSE DISABLED, NO INTS
	CALL	KEY_OUT
	LD	C,0AEH			;Enable 1st PS/2 port
	CALL	CMD_OUT			;Send it
	JR	DONE_INIT
	
INIT_ERR:	
	LD	HL,INIT_ERR_STR		;Say error
	CALL	PRINT_STRING
	HALT				;Just Halt!

DONE_INIT:
	LD	HL,INIT_OK		;Say all OK
	CALL	PRINT_STRING

LOOP:
	CALL	KEY_IN_STATUS		;See if keyboard key available
	JR	Z,LOOP
	IN	A,(KEY_DATA)
	LD	C,A			;Store in [C]
	LD	HL,SCAN_MSG
	CALL	PRINT_STRING		;No registers changed

	CALL	A_HEXOUT		;Display Hex value of typed character + two spaces

	;CP	0F0H			;Is it an UP key
	AND	080H			;Is it an UP key
	JR	Z,DOWNKY		;Must be a down key stroke
	LD	HL,UPKEY_MSG		;Say Up Key
	CALL	PRINT_STRING
	CALL	ZCRLF
	JR	LOOP

DOWNKY:
	CP	58H			;Is it CAPS Lock key
;	CP	3AH			;Is it CAPS Lock key
	JR	NZ,NOT_CAPSKEY
	LD	HL,CAPS_MSG		;Say Caps lock key
	CALL	PRINT_STRING
	CALL	ZCRLF
	JR	LOOP

NOT_CAPSKEY:
	CP	12H			;Is it a SHIFT key
;	CP	2AH			;Is it a SHIFT key
	JR	Z,SHIFTKEY
	CP	59H			;Is it the other SHIFT key
;	CP	36H			;Is it the other SHIFT key
	JR	NZ,NOT_SHIFTKEY

SHIFTKEY:
	LD	HL,SHIFT_MSG		;Say Shift key
	CALL	PRINT_STRING
	CALL	ZCRLF
	JR	LOOP

NOT_SHIFTKEY:
	CP	14H			;Is it the CTRL key
;	CP	1DH			;Is it the CTRL key
	JR	NZ,NOT_CTRLKEY
	LD	HL,CTRL_MSG		;Say CTRL key
	CALL	PRINT_STRING
	CALL	ZCRLF
	JR	LOOP

NOT_CTRLKEY:
	CP	77H			;Is it the NUM LOCK key
;	CP	45H			;Is it the NUM LOCK key
	JR	NZ,NOT_NUMKEY
	LD	HL,NUM_MSG		;Say Number key
	CALL	PRINT_STRING
	CALL	ZCRLF
	JR	LOOP

NOT_NUMKEY:
	PUSH	BC			;Save Character
	LD	HL,IBM1_MSG		;Say Table 1 lookup
	CALL	PRINT_STRING
	LD	HL,IBM1TBL		;Point to lookup table for upper case
	CALL	SHOW_CHAR

	POP	BC			;Get back character
	LD	HL,IBM2_MSG		;Say Table 2 lookup
	CALL	PRINT_STRING
	LD	HL,IBM2TBL		;Point to lookup table for upper case
	CALL	SHOW_CHAR

	CALL	ZCRLF
	JR	LOOP

SHOW_CHAR:
	LD	D,0
	LD	E,C
	ADD	HL,DE			;Add in offset
	LD	C,(HL)
	LD	A,C
	CP	ESC
	RET	Z			;ESC messes up the screen display
	CP	CR
	RET	Z			;CR messes up the screen display
	CP	LF
	RET	Z			;LF messes up the screen display
	CP	TAB
	RET	Z			;TAB messes up the screen display
	CALL	ZCO			;Display on Screen
	RET

KEY_IN_STATUS:				;Ret NZ if character is available
	IN	A,(KEY_CTRL)
	AND	1
	RET				;Ret NZ if character available

CMD_OUT:				;Send a byte (in [C]) to Control port
	IN	A,(KEY_CTRL)
	AND	2
	JR	NZ,CMD_OUT		;Chip is not ready yet to receive character
	LD	A,C
	OUT	(KEY_CTRL),A
	RET

KEY_OUT:				;Send a byte (in [C]) to Data port
	IN	A,(KEY_CTRL)
	AND	2
	JR	NZ,KEY_OUT		;Chip is not ready yet to receive character
	LD	A,C
	OUT	(KEY_DATA),A
	RET


;	A_HEXOUT			;output the 2 hex digits in [A]
A_HEXOUT:				;No registers altered
	push	AF
	push	BC
	push	AF
	srl	a
	srl	a
	srl	a
	srl	a
	call	hexdigout
	pop	AF
	call	hexdigout		;get upper nibble
	LD	C,' '
	call	ZCO			;Space for easy reading
	call	ZCO
	pop	BC
	pop	AF
	ret

hexdigout:
	and	0fh			;convert nibble to ascii
	add	a,90h
	daa
	adc	a,40h
	daa
	LD	c,a
	call	ZCO
	ret

; Main console I/O routines
;

ZCO:
	PUSH HL
	LD E,C
	LD C,02H			;BDOS Function 2 Write Console Byte
	CALL 0005H			;Call BDOS
	POP HL
	RET

ZCI:
	LD C,0BH			;BDOS Function 11 Read Console Status
	CALL 0005H			;Call BDOS
	JP Z,ZCI
	LD C,01H			;BDOS Function 1 Read Console Byte
	CALL 0005H			;Call BDOS
	RET
;
; Send CR/LF to Console
;
ZCRLF:
	PUSH	AF
	PUSH	BC
	LD	C,CR
	CALL	ZCO
	LD	C,LF
	CALL	ZCO
	POP	BC
	POP	AF
	RET


PRINT_STRING:
	PUSH	AF
	push	BC
print1:
	LD	a,(HL)			;Point to start of string
	inc	HL			;By using the CS over-ride we will always have
	CP	'$'			;a valid pointer to messages at the end of this monitor
	JP	z,print2
	CP	0			;Also terminate with 0's
	JP	Z,print2
	LD	C,A
	call	ZCO
	jp	print1
print2:
	pop	BC
	POP	AF
	ret

;---------------------------------------------------------------------------------------------------
; Black: ESC,[30m
; Red: ESC,[31m
; Green: ESC,[32m
; Yellow: ESC,[33m
; Blue: ESC,[34m
; Magenta: ESC,[35m
; Cyan: ESC,[36m
; White: ESC,[37m
; Reset: ESC,[0m

SIGNON:
		.DB	CR,LF,LF
		.DB	ESC,"[33m","Test VT82C42 PC Keyboard & Mouse controller chip on Z80 KBDMSE Board."	; Yellow
		.DB	CR,LF,"$"
INIT_ERR_STR:
		.DB	CR,LF,BELL
		.DB	ESC,"[31m","Error:  The 0xAA Test of Controller did nor return 0x55. Program Halted."	; Red
		.DB	CR,LF,"$"
INIT_OK:
		.DB	CR,LF
		.DB	ESC,"[32m","The 0xAA Test of Controller returned 0x55. Now enter keyboard keys."	; Green
		.DB	CR,LF,LF,"$"

SCAN_MSG:
		.DB	ESC,"[34m","Scancode = $"								; Blue
UPKEY_MSG:
		.DB	"(Up Keystroke)$"
CAPS_MSG:
		.DB	"(Caps Lock)$"
SHIFT_MSG:
		.DB	"(Shift Key)$"
CTRL_MSG:
		.DB	"(CTRL Key)$"
NUM_MSG:
		.DB	"(NUM Key)$"
IBM1_MSG:
		.DB	ESC,"[36m","Table 1 lookup -> $"							; Cyan
IBM2_MSG:
		.DB	ESC,"[37m","    Table 2 lookup -> $"							; White


IBM1TBL:			;The "Normal" table
			;00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 0a, 0b, 0c, 0d, 0e, 0f
;		.DB	  0,"*",  0,"*","*","*","*","*",  0,"*","*","*","*",09H,"`",00H
		.DB 	000,027,"1","2","3","4","5","6","7","8","9","0","-","=",008,009			;00-0F

			;10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 1a, 1b, 1c, 1d, 1e, 1f
;		.DB   	  0,  0,  0,  0,  0,"q","1",  0,  0,  0,"z","s","a","w","2",0
		.DB 	"q","w","e","r","t","y","u","i","o","p","[","]",013,000,"a","s"			;10-1F

			;20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 2a, 2b, 2c, 2d, 2e, 2f
;		.DB   	  0,"c","x","d","e","4","3",  0,  0," ","v","f","t","r","5",0
		.DB 	"d","f","g","h","j","k","l",";",27H,60H,000,092,"z","x","c","v"			;20-2F

 			;30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 3a, 3b, 3c, 3d, 3e, 3f
;		.DB   	  0,"n","b","h","g","y","6",  0,  0,  0,"m","j","u","7","8",0
		.DB 	"b","n","m",",",".","/",000,000,000," ",000,000,000,000,000,000			;30-3F

			;40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 4a, 4b, 4c, 4d, 4e, 4f
;		.DB   	  0,",","k","i","o","0","9",  0,  0,".","/","l",";","p","-",0
		.DB 	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;40-4F

			;50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 5a, 5b, 5c, 5d, 5e, 5f
;		.DB   	  0,  0,27H,  0,"[","=",  0,  0,  0,  0,0DH,"]",  0,5CH,  0,0
		.DB 	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;50-5F

			;60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 6a, 6b, 6c, 6d, 6e, 6f
;		.DB   	  0,  0,  0,  0,  0,  0,08H,  0,  0,11H,  0,13H,10H,  0,  0,  0
		.DB	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;60-6F

			;70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 7a, 7b, 7c, 7d, 7e, 7f
;		.DB 	0BH,7FH,03H,15H,04H,05H,1BH,00H,"*",02H,18H,16H,0CH,17H,"*",0
		.DB	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;70-7F

			;80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 8a, 8b, 8c, 8d, 8e, 8f
;		.DB   	  0,  0,  0,"*",  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
		.DB	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;80-8F


IBM2TBL:			;If the SHIFT key or CAPS lock key is on
			;00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 0a, 0b, 0c, 0d, 0e, 0f
;		.DB	  0, "*", 0,"*","*","*","*","*",  0,"*","*","*","*",09H,"~",00H
		.DB	000,027,"!","@","#","$","%","^","&","*","(",")","_","+",008,009			;00-0F

			;10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 1a, 1b, 1c, 1d, 1e, 1f
;		.DB	  0,  0,  0,  0,  0,"Q","!",  0,  0,  0,"Z","S","A","W","@",0
		.DB 	"Q","W","E","R","T","Y","U","I","O","P","{","}",013,000,"A","S"			;10-1F

			;20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 2a, 2b, 2c, 2d, 2e, 2f
;		.DB	  0,"C","X","D","E","$","#",  0,  0," ","V","F","T","R","%",0
		.DB	"D","F","G","H","J","K","L",":",034,"~",000,"|","Z","X","C","V"			;20-2F

			;30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 3a, 3b, 3c, 3d, 3e, 3f
;		.DB	  0,"N","B","H","G","Y","^",  0,  0,  0,"M","J","U","&","*",0
		.DB	"B","N","M","<",">","?",000,000,000," ",000,000,000,000,000,000			;30-3F

			;40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 4a, 4b, 4c, 4d, 4e, 4f
;		.DB	  0,"<","K","I","O",29H,"(",  0,  0,">","?","L",":","P", "_",0
		.DB	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;40-4F

			;50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 5a, 5b, 5c, 5d, 5e, 5f
;		.DB	  0,  0,22H,  0,"{","+",  0,  0,  0,  0,0DH,"}",  0,"|",  0,0
		.DB	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;50-5F

			;60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 6a, 6b, 6c, 6d, 6e, 6f
;		.DB	  0,  0,  0,  0,  0,  0,08H,  0,  0,11H,  0,13H,10H,  0,  0,  0
		.DB	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;60-6F

			;70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 7a, 7b, 7c, 7d, 7e, 7f
;		.DB 	0BH,7FH,03H,15H,04H,05H,1BH,00H,"*",02H,18H,16H,0CH,17H,"*",0
		.DB	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;70-7F

			;80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 8a, 8b, 8c, 8d, 8e, 8f
;		.DB	  0,  0,  0,"*",  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
		.DB	000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;80-8F


		.FILL	040H,000H
STACK:		.DB	0H
		.FILL	19,000H

.END
