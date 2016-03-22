;___ROM_MONITOR_PROGRAM_______________________________________________________
;
;  ORIGINAL CODE BY:	ANDREW LYNCH (LYNCHAJ@YAHOO COM)	13 FEB 2007
;
;  MODIFIED BY : 	DAN WERNER 03 09.2009
;
;__REFERENCES_________________________________________________________________
; THOMAS SCHERRER BASIC HAR.DWARE TEST ASSEMBLER SOURCES FROM THE Z80 INFO PAGE
; INCLUDING ORIGINAL SCHEMATIC CONCEPT
; HTTP://Z80 INFO/Z80SOURC.TXT
; CODE SAMPLES FROM BRUCE JONES PUBLIC DOMAIN ROM MONITOR FOR THE SBC-200C 
; HTTP://WWW RETROTECHNOLOGY.COM/HERBS_STUFF/SD_BRUCE_CODE.ZIP
; INSPIRATION FROM JOEL OWENS "Z-80 SPACE-TIME PRODUCTIONS SINGLE BOARD COMPUTER"
; HTTP://WWW JOELOWENS.ORG/Z80/Z80INDEX.HTML
; GREAT HELP AND TECHNICAL ADVICE FROM ALLISON AT ALPACA_DESIGNERS
; HTTP://GROUPS YAHOO.COM/GROUP/ALPACA_DESIGNERS
; INTEL SDK-85 ROM DEBUG MONITOR
;_____________________________________________________________________________
;
#INCLUDE "std.asm"
;
;__CONSTANTS__________________________________________________________________
;	
ENDT:		 .EQU	0FFh		; MARK END OF TEXT
CR:		 .EQU	0DH		; ASCII CARRIAGE RETURN CHARACTER
LF:		 .EQU	0AH		; ASCII LINE FEED CHARACTER
ESC:		 .EQU	1BH		; ASCII ESCAPE CHARACTER
BS:		 .EQU	08H		; ASCII BACKSPACE CHARACTER
;
;__MAIN_PROGRAM_______________________________________________________________
;
;	ORG	00100h			; FOR DEBUG IN CP/M (AS .COM)
	.ORG	MON_LOC
;
;__ENTRY JUMP TABLE___________________________________________________________
;
	JP	DSKY_ENTRY
	JP	UART_ENTRY
;
#INCLUDE "util.asm"
;
#INCLUDE "memmgr.asm"
;
#IF DSKYENABLE
;
#INCLUDE "dsky.asm"
;
;
;__DSKY_ENTRY_________________________________________________________________
;
DSKY_ENTRY:
	LD	SP,MON_STACK		; SET THE STACK POINTER
	CALL	INITIALIZE		; INITIALIZE SYSTEM

;__FRONT_PANEL_STARTUP________________________________________________________
;
;	START UP THE SYSTEM WITH THE FRONT PANEL INTERFACE
;	
;_____________________________________________________________________________
;
	CALL    MTERM_INIT		; INIT 8255 FOR MTERM
	LD	HL,CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 



FRONTPANELLOOP:
	CALL	KB_GET			; GET KEY FROM KB

	CP	10H			; IS PORT READ?
	JP	Z,DOPORTREAD		; YES, JUMP
	CP	11H			; IS PORT WRITE?
	JP	Z,DOPORTWRITE		; YES, JUMP
	CP	14H			; IS DEPOSIT?
	JP	Z,DODEPOSIT		; YES, JUMP
	CP	15H			; IS EXAMINE?
	JP	Z,DOEXAMINE		; YES, JUMP
	CP	16H			; IS GO?
	JP	Z,DOGO			; YES, JUMP
	CP	17H			; IS BO?
	JP	Z,DOBOOT		; YES, JUMP

	JR	FRONTPANELLOOP		; LOOP
EXIT:
	RET	


;__DOBOOT_____________________________________________________________________
;
;	PERFORM BOOT FRONT PANEL ACTION
;_____________________________________________________________________________
;
DOBOOT:
	JP	BOOT


;__DOPORTREAD_________________________________________________________________
;
;	PERFORM PORT READ FRONT PANEL ACTION
;_____________________________________________________________________________
;
DOPORTREAD:	
	CALL 	GETPORT			; GET PORT INTO A
PORTREADLOOP:
	LD	C,A			; STORE PORT IN "C"
	SRL	A			; ROTATE HIGH NIB TO LOW
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+5),A	; SHOW HIGH NIB IN DISP 5
	LD	A,C			; RESTORE PORT VALUE INTO "A"
	AND	0FH			; CLEAR HIGH NIB, LEAVING LOW
	LD	(DISPLAYBUF+4),A	; SHOW LOW NIB IN DISP 4
	IN 	A,(C)			; GET PORT VALUE FROM PORT IN "C"
	LD	C,A			; STORE VALUE IN "C"
	SRL	A			; ROTATE HIGH NIB TO LOW
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+1),A	; SHOW HIGH NIB IN DISP 1
	LD	A,C			; RESTORE VALUE TO "A"
	AND	0FH			; CLEAR HIGH NIB, LEAVING LOW
	LD	(DISPLAYBUF),A		; DISPLAY LOW NIB IN DISP 0
	LD	A,10H			; CLEAR OTHER DISPLAYS
	LD	(DISPLAYBUF+2),A	;
	LD	(DISPLAYBUF+3),A	;
	LD	A,13H			; "P"
	LD	(DISPLAYBUF+7),A	; STORE IN DISP 7
	LD	A,14H			; "O"
	LD	(DISPLAYBUF+6),A	; STORE IN DISP 6
	LD	HL,DISPLAYBUF		; SET POINTER TO DISPLAY BUFFER
	CALL	HEXDISPLAY		; DISPLAY BUFFER CONTENTS
PORTREADGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	CP	12H			; [CL] PRESSED, EXIT
	JP	Z,PORTREADEXIT		;
	CP	10H			; [PR] PRESSED, PROMPT FOR NEW PORT
	JR	Z,DOPORTREAD		;
	JR	PORTREADGETKEY		; NO VALID KEY, LOOP
PORTREADEXIT:
	LD	HL,CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
	JP	FRONTPANELLOOP		;

;__DOPORTWRITE________________________________________________________________
;
;	PERFORM PORT WRITE FRONT PANEL ACTION
;_____________________________________________________________________________
;
DOPORTWRITE:	
	CALL 	GETPORT			; GET PORT INTO A
PORTWRITELOOP:
	LD	C,A			; STORE PORT IN "C"
	SRL	A			; ROTATE HIGH NIB INTO LOW
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+5),A	; DISPLAY HIGH NIB IN DISPLAY 5
	LD	A,C			; RESTORE PORT VALUE INTO "A"
	AND	0FH			; CLEAR OUT HIGH NIB
	LD	(DISPLAYBUF+4),A	; DISPLAY LOW NIB IN DISPLAY 4
	LD	A,10H			; CLEAR OUT DISPLAYS 2 AND 3
	LD	(DISPLAYBUF+2),A	;
	LD	(DISPLAYBUF+3),A	;
	LD	A,13H			; DISPLAY "P" IN DISP 7
	LD	(DISPLAYBUF+7),A	;
	LD	A,14H			; DISPLAY "O" IN DISP 6
	LD	(DISPLAYBUF+6),A	;
	LD	HL,DISPLAYBUF		; POINT TO DISPLAY BUFFER
	CALL	GETVALUE		; INPUT A BYTE VALUE, RETURN IN "A"
	OUT	(C),A			; OUTPUT VALUE TO PORT STORED IN "C"
	LD	HL,CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
	JP	FRONTPANELLOOP		;


;__DOGO_______________________________________________________________________
;
;	PERFORM GO FRONT PANEL ACTION
;_____________________________________________________________________________
;
DOGO:
	CALL 	GETADDR			; GET ADDRESS INTO HL
	JP	(HL)			; GO THERE!



;__DODEPOSIT__________________________________________________________________
;
;	PERFORM DEPOSIT FRONT PANEL ACTION
;_____________________________________________________________________________
;
DODEPOSIT:
	CALL 	GETADDR			; GET ADDRESS INTO HL
	PUSH 	HL
DEPOSITLOOP:
	LD	A,H			;
	SRL	A			;
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+7),A	;
	LD	A,H			;
	AND	0FH			;
	LD	(DISPLAYBUF+6),A	;
	LD	A,L			;
	SRL	A			;
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+5),A	;
	LD	A,L			;
	AND	0FH			;
	LD	(DISPLAYBUF+4),A	;
	LD	A,10H			;
	LD	(DISPLAYBUF+3),A	;
	LD	HL,DISPLAYBUF		;
	CALL	GETVALUE		;
	POP	HL			;
	LD	(HL),A			;
DEPOSITGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	CP	12H			; [CL] PRESSED, EXIT
	JP	Z,DEPOSITEXIT		;
	CP	13H			; [EN] PRESSED, INC ADDRESS AND LOOP
	JR	Z,DEPOSITFW		; 
	CP	14H			; [DE] PRESSED, PROMPT FOR NEW ADDRESS
	JR	Z,DODEPOSIT		;
	JR	DEPOSITGETKEY		; NO VALID KEY, LOOP
DEPOSITFW:
	INC	HL			;
	PUSH	HL			; STORE HL
	JR 	DEPOSITLOOP		;	
DEPOSITEXIT:
	LD	HL,CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
	JP	FRONTPANELLOOP		;




;__DOEXAMINE__________________________________________________________________
;
;	PERFORM EXAMINE FRONT PANEL ACTION
;_____________________________________________________________________________
;
DOEXAMINE:
	CALL 	GETADDR			; GET ADDRESS INTO HL
	PUSH 	HL			; STORE HL
EXAMINELOOP:
	LD	A,H			; MOVE HIGH BYTE IN "A"
	SRL	A			; SHOW HIGH NIBBLE IN DISP 7
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+7),A	;
	LD	A,H			; RESTORE HIGH BYTE
	AND	0FH			; CLEAR HIGH NIBBLE
	LD	(DISPLAYBUF+6),A	; DISPLAY LOW NIBBLE IN DISP 6
	LD	A,L			; PUT LOW BYTE IN "A"
	SRL	A			; SHOW HIGH NIBBLE IN DISP 5
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+5),A	;
	LD	A,L			; RESTORE LOW BYTE IN "A"
	AND	0FH			; CLEAR OUT HIGH NIBBLE
	LD	(DISPLAYBUF+4),A	; DISPLAY LOW NIBBLE IN DISP 4
	LD	A,10H			; CLEAR OUT DISP 3
	LD	(DISPLAYBUF+3),A	;
	LD	A,(HL)			; GET VALUE FROM ADDRESS IN HL
	SRL	A			; DISPLAY HIGH NIB IN DISPLAY 1
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+1),A	;
	LD	A,(HL)			; GET VALUE FROM ADDRESS IN HL
	AND	0FH			; CLEAR OUT HIGH NIBBLE
	LD	(DISPLAYBUF),A		; DISPLAY LOW NIBBLE IN DISPLAY 0
	LD	HL,DISPLAYBUF		; POINT TO DISPLAY BUFFER
	CALL	HEXDISPLAY		; DISPLAY BUFFER ON DISPLAYS
	POP	HL			; RESTORE HL
EXAMINEGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	CP	12H			; [CL] PRESSED, EXIT
	JP	Z,EXAMINEEXIT		;
	CP	13H			; [EN] PRESSED, INC ADDRESS AND LOOP
	JR	Z,EXAMINEFW		; 
	CP	15H			; [DE] PRESSED, PROMPT FOR NEW ADDRESS
	JR	Z,DOEXAMINE		;
	JR	EXAMINEGETKEY		; NO VALID KEY, LOOP
EXAMINEFW:
	INC	HL			; HL++
	PUSH	HL			; STORE HL
	JR 	EXAMINELOOP		;	
EXAMINEEXIT:
	LD	HL,CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
	JP	FRONTPANELLOOP		;


;__GETADDR____________________________________________________________________
;
;	GET ADDRESS FROM FRONT PANEL
;_____________________________________________________________________________
;
GETADDR:
	PUSH	BC			; STORE BC
	JR	GETADDRCLEAR		; 
GETADDR1:
	LD	HL,ADDR			; DISPLAY PROMPT
	CALL	SEGDISPLAY		; 
GETADDRLOOP:
	CALL	KB_GET			;	
	CP	10H			;
	JP	M,GETADDRNUM		; NUMBER PRESSED, STORE IT
	CP	13H			; EN PRESSED, DONE
	JR	Z,GETADDRDONE		;
	CP	12H			; CLEAR PRESSED, CLEAR
	JR	Z,GETADDRCLEAR		; 
	JR	GETADDRLOOP		; INVALID KEY, LOOP
GETADDRDONE:
	LD	HL,00H			; HL=0
	LD	A,(DISPLAYBUF+1)	; GET DIGIT IN DISPLAY 1
	SLA	A			; ROTATE IT TO HIGH NIBBLE
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			; STORE IT IN "C"	
	LD	A,(DISPLAYBUF)		; GET DIGIT IN DISPLAY 0
	AND	0FH			; CLEAR HIGH NIBBLE
	OR	C			; ADD IN NIBBLE STORED IN C
	LD	L,A			; STORE IT IN LOW BYTE OF ADDRESS POINTER
	LD	A,(DISPLAYBUF+3)	; GET DIGIT IN DISPLAY 3
	SLA	A			; ROTATE IT TO HIGH NIBBLE
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			; STORE IT IN "C"	
	LD	A,(DISPLAYBUF+2)	; GET DIGIT IN DISPLAY 2
	AND	0FH			; CLEAR HIGH NIBBLE
	OR	C			; ADD IN NIBBLE STORED IN "C"
	LD	H,A			; STORE BYTE IN HIGH BYTE OF ADDRESS POINTER
	LD	A,10H			; CLEAR OUT DISPLAYS 0,1,2 & 3
	LD	(DISPLAYBUF),A		;
	LD	(DISPLAYBUF+1),A	;
	LD	(DISPLAYBUF+2),A	;
	LD	(DISPLAYBUF+3),A	;	
	POP	BC			; RESTORE BC	
	RET
GETADDRNUM:
	LD	C,A			;
	LD	A,(DISPLAYBUF+2)	; SHIFT BYTES IN DISPLAY BUF TO THE LEFT
	LD      (DISPLAYBUF+3),A	;
	LD	A,(DISPLAYBUF+1)	;	
	LD	(DISPLAYBUF+2),A	;
	LD	A,(DISPLAYBUF)		;	
	LD	(DISPLAYBUF+1),A	;
	LD	A,C			; DISPLAY KEYSTROKE IN RIGHT MOST DISPLAY (0)
	LD	(DISPLAYBUF+0),A	;
	JR	GETADDRDISP		;
GETADDRCLEAR:
	LD	A,12H			; CLEAR OUT DISPLAYS 0,1,2 & 3
	LD	(DISPLAYBUF),A		;
	LD	(DISPLAYBUF+1),A	;
	LD	(DISPLAYBUF+2),A	;
	LD	(DISPLAYBUF+3),A	;	
GETADDRDISP:
	LD	A,(DISPLAYBUF)		; ENCODE DIGITS IN DISPLAY BUFFER TO DISPLAY
	CALL 	DECODEDISPLAY		;
	LD	(ADDR),A		;
	LD	A,(DISPLAYBUF+1)	;
	CALL 	DECODEDISPLAY		;
	LD	(ADDR+1),A		;
	LD	A,(DISPLAYBUF+2)	;
	CALL 	DECODEDISPLAY		;
	LD	(ADDR+2),A		;
	LD	A,(DISPLAYBUF+3)	;
	CALL 	DECODEDISPLAY		;
	LD	(ADDR+3),A		;
	JP	GETADDR1		;



;__DSPSECTOR__________________________________________________________________
;
;	DISPLAY SECTOR IN HL ON FRONT PANEL
;_____________________________________________________________________________
;
DSPSECTOR:
	PUSH	BC			; STORE BC
	PUSH	HL			; STORE HL
	LD	A,H			; DISPLAY HIGH BYTE, HIGH NIBBLE
	SRL 	A			;	
	SRL 	A			;	
	SRL 	A			;	
	SRL 	A			;	
	AND	0FH			;
	CALL 	DECODEDISPLAY		;
	LD	(SEC+3),A		;
	LD      A,H			; DISPLAY HIGH BYTE, LOW NIBBLE
	AND	0FH			;
	CALL 	DECODEDISPLAY		;
	LD	(SEC+2),A		;
	LD	A,L			; DISPLAY LOW BYTE, HIGH NIBBLE
	AND	0F0H			;
	SRL 	A			;	
	SRL 	A			;	
	SRL 	A			;	
	SRL 	A			;		
	AND	0FH			;
	CALL 	DECODEDISPLAY		;
	LD	(SEC+1),A		; DISPLAY LOW BYTE, LOW NIBBLE
	LD      A,L			;
	AND	0FH			;
	CALL 	DECODEDISPLAY		;
	LD	(SEC),A			;
	LD	HL,SEC			; DISPLAY PROMPT
	CALL	SEGDISPLAY		; 
	POP	HL			; RESTORE HL
	POP	BC			; RESTORE BC
	RET



;__GETPORT____________________________________________________________________
;
;	GET PORT FROM FRONT PANEL
;_____________________________________________________________________________
;
GETPORT:
	PUSH	BC			; STORE BC
	JR	GETPORTCLEAR		;
GETPORT1:
	LD	HL,PORT			; DISPLAY PROMPT
	CALL	SEGDISPLAY		; 
GETPORTLOOP:
	CALL	KB_GET			;	
	CP	10H			;
	JP	M,GETPORTNUM		; NUMBER PRESSED, STORE IT
	CP	13H			; EN PRESSED, DONE
	JR	Z,GETPORTDONE		;
	CP	12H			; CLEAR PRESSED, CLEAR
	JR	Z,GETPORTCLEAR		; 
	JR	GETPORTLOOP		; INVALID KEY, LOOP
GETPORTDONE:
	LD	A,(DISPLAYBUF+1)	;
	SLA	A			;
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			;	
	LD	A,(DISPLAYBUF)		;
	AND	0FH			;
	OR	C			;
	LD	C,A			;
	LD	A,10H			;
	LD	(DISPLAYBUF),A		;
	LD	(DISPLAYBUF+1),A	;
	LD	A,C			;
	POP	BC			; RESTORE BC	
	RET
GETPORTNUM:
	LD	C,A			;
	LD	A,(DISPLAYBUF)		;	
	LD	(DISPLAYBUF+1),A	;
	LD	A,C			;
	LD	(DISPLAYBUF+0),A	;
	JR	GETPORTDISP		;
GETPORTCLEAR:
	LD	A,12H			;
	LD	(DISPLAYBUF),A		;
	LD	(DISPLAYBUF+1),A	;
GETPORTDISP:
	LD	A,(DISPLAYBUF)		;
	CALL 	DECODEDISPLAY		;
	LD	(PORT),A		;
	LD	A,(DISPLAYBUF+1)	;
	CALL 	DECODEDISPLAY		;
	LD	(PORT+1),A		;
	JP	GETPORT1		;


;__GETVALUE___________________________________________________________________
;
;	GET VALUE FROM FRONT PANEL
;_____________________________________________________________________________
;
GETVALUE:
	PUSH	BC			; STORE BC
	JR	GETVALUECLEAR		;
GETVALUE1:
	CALL	HEXDISPLAY		; 
	
GETVALUELOOP:
	CALL	KB_GET			;	
	CP	10H			;
	JP	M,GETVALUENUM		; NUMBER PRESSED, STORE IT
	CP	13H			; EN PRESSED, DONE
	JR	Z,GETVALUEDONE		;
	CP	12H			; CLEAR PRESSED, CLEAR
	JR	Z,GETVALUECLEAR		; 
	JR	GETVALUELOOP		; INVALID KEY, LOOP
GETVALUEDONE:
	LD	A,(DISPLAYBUF+1)	;
	SLA	A			;
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			;	
	LD	A,(DISPLAYBUF)		;
	AND	0FH			;
	OR	C			;
        LD	C,A			;
	LD	A,10H			;
	LD	(DISPLAYBUF),A		;
	LD	(DISPLAYBUF+1),A	;
	LD	A,C			;
	POP	BC			; RESTORE BC		
	RET
GETVALUENUM:
	LD	C,A			;
	LD	A,(DISPLAYBUF)		;	
	LD	(DISPLAYBUF+1),A	;
	LD	A,C			;
	LD	(DISPLAYBUF+0),A	;
	JR	GETVALUE1		;
GETVALUECLEAR:
	LD	A,12H			;
	LD	(DISPLAYBUF),A		;
	LD	(DISPLAYBUF+1),A	;
	JP	GETVALUE1		;
;
#ELSE
DSKY_ENTRY:
	CALL	PANIC
#ENDIF


;__UART_ENTRY_________________________________________________________________
;
;	SERIAL MONITOR STARTUP
;_____________________________________________________________________________
;
UART_ENTRY:
	LD	SP,MON_STACK		; SET THE STACK POINTER
	CALL	INITIALIZE		; INITIALIZE SYSTEM

	XOR	A			;ZERO OUT ACCUMULATOR (ADDED)
	PUSH	HL			;PROTECT HL FROM OVERWRITE     
	LD	HL,TXT_READY		;POINT AT TEXT
	CALL	MSG			;SHOW WE'RE HERE
	POP	HL			;PROTECT HL FROM OVERWRITE

;
;__SERIAL_MONITOR_COMMANDS____________________________________________________
;
; B XX BOOT CPM FROM DRIVE XX
; D XXXXH YYYYH  DUMP MEMORY FROM XXXX TO YYYY
; F XXXXH YYYYH ZZH FILL MEMORY FROM XXXX TO YYYY WITH ZZ
; H LOAD INTEL HEX FORMAT DATA
; IXX INPUT FROM PORT XX AND SHOW HEX DATA
; K ECHO KEYBOARD INPUT
; M XXXXH YYYYH ZZZZH MOVE MEMORY BLOCK XXXX TO YYYY TO ZZZZ
; OXX YY OUTPUT TO PORT XX HEX DATA YY
; P XXXXH YYH PROGRAM RAM FROM XXXXH WITH VALUE IN YYH, WILL PROMPT FOR NEXT LINES FOLLOWING UNTIL CR
; R RUN A PROGRAM FROM CURRENT LOCATION
;
;__COMMAND_PARSE______________________________________________________________
;
;	PROMPT USER FOR COMMANDS, THEN PARSE THEM
;_____________________________________________________________________________
;

SERIALCMDLOOP:
	CALL	CRLFA			; CR,LF,>
	LD	HL,KEYBUF		; SET POINTER TO KEYBUF AREA
	CALL 	GETLN			; GET A LINE OF INPUT FROM THE USER
	LD	HL,KEYBUF		; RESET POINTER TO START OF KEYBUF
	LD	A,(HL)			; LOAD FIRST CHAR INTO A (THIS SHOULD BE THE COMMAND)
	INC	HL			; INC POINTER

	CP	'B'			; IS IT "B" (Y/N)
	JP	Z,BOOT			; IF YES BOOT
	CP	'R'			; IS IT "R" (Y/N)
	JP	Z,RUN			; IF YES GO RUN ROUTINE
	CP	'P'			; IS IT "P" (Y/N)
	JP	Z,PROGRM		; IF YES GO PROGRAM ROUTINE
	CP	'O'			; IS IT AN "O" (Y/N)
	JP	Z,POUT			; PORT OUTPUT
	CP	'H'			; IS IT A "H" (Y/N)
	JP	Z,HXLOAD		; INTEL HEX FORMAT LOAD DATA
	CP	'I'			; IS IT AN "I" (Y/N)
	JP	Z,PIN			; PORT INPUT
	CP	'D'			; IS IT A "D" (Y/N)
	JP	Z,DUMP			; DUMP MEMORY
	CP	'K'
	JP	Z,KLOP			; LOOP ON KEYBOARD
	CP	'M'			; IS IT A "M" (Y/N)
	JP	Z,MOVE			; MOVE MEMORY COMMAND
	CP	'F'			; IS IT A "F" (Y/N)
	JP	Z,FILLMEM		; FILL MEMORY COMMAND
	LD	HL,TXT_COMMAND		; POINT AT ERROR TEXT
	CALL	MSG			; PRINT COMMAND LABEL

	JR	SERIALCMDLOOP



;__BOOT_______________________________________________________________________
;
;	PERFORM BOOT ACTION
;_____________________________________________________________________________
;
BOOT:
	; ENSURE DEFAULT MEMORY PAGE CONFIGURATION
;#IF (PLATFORM == PLT_N8)
;	LD	A,DEFACR
;	OUT0	(ACR),A
;	XOR	A
;	OUT0	(RMAP),A
;#ELSE
;	XOR	A
;	OUT	(MPCL_ROM),A
;	OUT	(MPCL_RAM),A
;#ENDIF
#IF (PLATFORM == PLT_UNA)
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,$0000		; ROM BANK 0
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)
#ELSE
	LD	A,BID_BOOT
	CALL	BNKSEL
#ENDIF
	; JUMP TO RESTART ADDRESS
	JP	0000H


;__KLOP_______________________________________________________________________
;
;	READ FROM THE SERIAL PORT AND ECHO, MONITOR COMMAND "K"
;_____________________________________________________________________________
;
KLOP:
	CALL	KIN			; GET A KEY
	CALL	COUT			; OUTPUT KEY TO SCREEN
	CP	ESC			; IS <ESC>?
	JR	NZ,KLOP			; NO, LOOP
	JP	SERIALCMDLOOP		;

;__GETLN______________________________________________________________________
;
;	READ A LINE(80) OF TEXT FROM THE SERIAL PORT, HANDLE <BS>, TERM ON <CR> 
;       EXIT IF TOO MANY CHARS    STORE RESULT IN HL.  CHAR COUNT IN C.
;_____________________________________________________________________________
;
GETLN:
	LD	C,00H			; ZERO CHAR COUNTER
	PUSH	DE			; STORE DE
GETLNLOP:
	CALL	KIN			; GET A KEY
	CALL	COUT			; OUTPUT KEY TO SCREEN
	CP	CR			; IS <CR>?
	JR	Z,GETLNDONE		; YES, EXIT 
	CP	BS			; IS <BS>?
	JR	NZ,GETLNSTORE		; NO, STORE CHAR
	LD	A,C			; A=C
	CP	0			;
	JR	Z,GETLNLOP		; NOTHING TO BACKSPACE, IGNORE & GET NEXT KEY
	DEC	HL			; PERFORM BACKSPACE
	DEC	C			; LOWER CHAR COUNTER	
	LD	A,0			;
	LD	(HL),A			; STORE NULL IN BUFFER
	LD	A,20H			; BLANK OUT CHAR ON TERM
	CALL	COUT			;
	LD	A,BS			;
	CALL	COUT			;
	JR	GETLNLOP		; GET NEXT KEY
GETLNSTORE:
	LD	(HL),A			; STORE CHAR IN BUFFER
	INC	HL			; INC POINTER
	INC	C			; INC CHAR COUNTER	
	LD	A,C			; A=C
	CP	4DH			; OUT OF BUFFER SPACE?
	JR	NZ,GETLNLOP		; NOPE, GET NEXT CHAR
GETLNDONE:
	LD	(HL),00H		; STORE NULL IN BUFFER
	POP	DE			; RESTORE DE
	RET				;

#IF (PLATFORM == PLT_UNA)

;
;__COUT_______________________________________________________________________
;
;	OUTPUT CHARACTER FROM A
;_____________________________________________________________________________
;
COUT:
	; SAVE ALL INCOMING REGISTERS
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
;
	; OUTPUT CHARACTER TO CONSOLE VIA UBIOS
	LD	E,A
	LD	BC,$12
	RST	08
;
	; RESTORE ALL REGISTERS
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
	RET
;
;__CIN________________________________________________________________________
;
;	INPUT CHARACTER TO A
;_____________________________________________________________________________
;
CIN:
	; SAVE INCOMING REGISTERS (AF IS OUTPUT)
	PUSH	BC
	PUSH	DE
	PUSH	HL
;
	; INPUT CHARACTER FROM CONSOLE VIA UBIOS
	LD	BC,$11
	RST	08
	LD	A,E
;
	; RESTORE REGISTERS (AF IS OUTPUT)
	POP	HL
	POP	DE
	POP	BC
	RET
	RET
;
;__CST________________________________________________________________________
;
;	RETURN INPUT STATUS IN A (0 = NO CHAR, !=0 CHAR WAITING)
;_____________________________________________________________________________
;
CST:
	; SAVE INCOMING REGISTERS (AF IS OUTPUT)
	PUSH	BC
	PUSH	DE
	PUSH	HL
;
	; GET CONSOLE INPUT STATUS VIA UBIOS
	LD	BC,$13
	RST	08
	LD	A,E
;
	; RESTORE REGISTERS (AF IS OUTPUT)
	POP	HL
	POP	DE
	POP	BC
	RET
	RET
	
#ELSE

;
;__COUT_______________________________________________________________________
;
;	OUTPUT CHARACTER FROM A
;_____________________________________________________________________________
;
COUT:
	; SAVE ALL INCOMING REGISTERS
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
;
	; OUTPUT CHARACTER TO CONSOLE VIA HBIOS
	LD	E,A			; OUTPUT CHAR TO E
	LD	C,CIODEV_CONSOLE	; CONSOLE UNIT TO C
	LD	B,BF_CIOOUT		; HBIOS FUNC: OUTPUT CHAR
	RST	08			; HBIOS OUTPUTS CHARACTDR
;
	; RESTORE ALL REGISTERS
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
;__CIN________________________________________________________________________
;
;	INPUT CHARACTER TO A
;_____________________________________________________________________________
;
CIN:
	; SAVE INCOMING REGISTERS (AF IS OUTPUT)
	PUSH	BC
	PUSH	DE
	PUSH	HL
;
	; INPUT CHARACTER FROM CONSOLE VIA HBIOS
	LD	C,CIODEV_CONSOLE	; CONSOLE UNIT TO C
	LD	B,BF_CIOIN		; HBIOS FUNC: INPUT CHAR
	RST	08			; HBIOS READS CHARACTDR
	LD	A,E			; MOVE CHARACTER TO A FOR RETURN
;
	; RESTORE REGISTERS (AF IS OUTPUT)
	POP	HL
	POP	DE
	POP	BC
	RET
;
;__CST________________________________________________________________________
;
;	RETURN INPUT STATUS IN A (0 = NO CHAR, !=0 CHAR WAITING)
;_____________________________________________________________________________
;
CST:
	; SAVE INCOMING REGISTERS (AF IS OUTPUT)
	PUSH	BC
	PUSH	DE
	PUSH	HL
;
	; GET CONSOLE INPUT STATUS VIA HBIOS
	LD	C,CIODEV_CONSOLE	; CONSOLE UNIT TO C
	LD	B,BF_CIOIST		; HBIOS FUNC: INPUT STATUS
	RST	08			; HBIOS RETURNS STATUS IN A
;
	; RESTORE REGISTERS (AF IS OUTPUT)
	POP	HL
	POP	DE
	POP	BC
	RET

#ENDIF
;
;__KIN________________________________________________________________________
;
;	READ FROM THE SERIAL PORT AND ECHO & CONVERT INPUT TO UCASE
;_____________________________________________________________________________
;
KIN:
	CALL	CIN
	AND	7FH			; STRIP HI BIT
	CP	'A'			; KEEP NUMBERS, CONTROLS
	RET	C			; AND UPPER CASE
	CP	7BH			; SEE IF NOT LOWER CASE
	RET	NC
	AND	5FH			; MAKE UPPER CASE
	RET
;
;__CRLF_______________________________________________________________________
;
;	SEND CR & LF TO THE SERIAL PORT
;_____________________________________________________________________________
;
CRLF:
	PUSH	HL			; PROTECT HL FROM OVERWRITE
	LD	HL,TCRLF		; LOAD MESSAGE POINTER
	CALL	MSG			; SEBD MESSAGE TO SERIAL PORT
	POP	HL			; PROTECT HL FROM OVERWRITE
	RET				;


;__LDHL_______________________________________________________________________
;
;	GET ONE WORD OF HEX DATA FROM BUFFER POINTED TO BY HL SERIAL PORT, RETURN IN HL
;_____________________________________________________________________________
;
LDHL:
	PUSH	DE			; STORE DE
	CALL	HEXIN			; GET K B. AND MAKE HEX
	LD	D,A			; THATS THE HI BYTE
	CALL	HEXIN			; DO HEX AGAIN
	LD	L,A			; THATS THE LOW BYTE
	LD	H,D			; MOVE TO HL
	POP	DE			; RESTORE BC
	RET				; GO BACK WITH ADDRESS  


;__HEXIN______________________________________________________________________
;
;	GET ONE BYTE OF HEX DATA FROM BUFFER IN HL, RETURN IN A
;_____________________________________________________________________________
;
HEXIN:
	PUSH	BC			;SAVE BC REGS 
	CALL	NIBL			;DO A NIBBLE
	RLC	A			;MOVE FIRST BYTE UPPER NIBBLE  
	RLC	A			; 
	RLC	A			; 
	RLC	A			; 
	LD	B,A			; SAVE ROTATED BYTE
	CALL	NIBL			; DO NEXT NIBBLE
	ADD	A,B			; COMBINE NIBBLES IN ACC 
	POP	BC			; RESTORE BC
	RET				; DONE  
NIBL:
	LD	A,(HL)			; GET K B. DATA
	INC	HL			; INC KB POINTER
	CP	40H			; TEST FOR ALPHA
	JR	NC,ALPH			;
	AND	0FH			; GET THE BITS
	RET				;
ALPH:
	AND	0FH			; GET THE BITS
	ADD	A,09H			; MAKE IT HEX A-F
	RET				;


;__HEXINS_____________________________________________________________________
;
;	GET ONE BYTE OF HEX DATA FROM SERIAL PORT, RETURN IN A
;_____________________________________________________________________________
;
HEXINS:
	PUSH	BC			;SAVE BC REGS 
	CALL	NIBLS			;DO A NIBBLE
	RLC	A			;MOVE FIRST BYTE UPPER NIBBLE  
	RLC	A			; 
	RLC	A			; 
	RLC	A			; 
	LD	B,A			; SAVE ROTATED BYTE
	CALL	NIBLS			; DO NEXT NIBBLE
	ADD	A,B			; COMBINE NIBBLES IN ACC 
	POP	BC			; RESTORE BC
	RET				; DONE  
NIBLS:
	CALL	KIN			; GET K B. DATA
	CP	40H			; TEST FOR ALPHA
	JR	NC,ALPH			;
	AND	0FH			; GET THE BITS
	RET				;


;__HXOUT______________________________________________________________________
;
;	PRINT THE ACCUMULATOR CONTENTS AS HEX DATA ON THE SERIAL PORT
;_____________________________________________________________________________
;
HXOUT:
	PUSH	BC			; SAVE BC
	LD	B,A			;
	RLC	A			; DO HIGH NIBBLE FIRST  
	RLC	A			;
	RLC	A			;
	RLC	A			;
	AND	0FH			; ONLY THIS NOW
	ADD	A,30H			; TRY A NUMBER
	CP	3AH			; TEST IT
	JR	C,OUT1			; IF CY SET PRINT 'NUMBER'
	ADD	A,07H			; MAKE IT AN ALPHA
OUT1:
	CALL	COUT			; SCREEN IT
	LD	A,B			; NEXT NIBBLE
	AND	0FH			; JUST THIS
	ADD	A,30H			; TRY A NUMBER
	CP	3AH			; TEST IT
	JR	C,OUT2			; PRINT 'NUMBER'
	ADD	A,07H			; MAKE IT ALPHA
OUT2:
	CALL	COUT			; SCREEN IT
	POP	BC			; RESTORE BC
	RET				;


;__SPACE______________________________________________________________________
;
;	PRINT A SPACE CHARACTER ON THE SERIAL PORT
;_____________________________________________________________________________
;
SPACE:
	PUSH	AF			; STORE AF
	LD	A,20H			; LOAD A "SPACE"
	CALL	COUT			; SCREEN IT
	POP	AF			; RESTORE AF
	RET				; DONE

;__PHL________________________________________________________________________
;
;	PRINT THE HL REG ON THE SERIAL PORT
;_____________________________________________________________________________
;
PHL:
	LD	A,H			; GET HI BYTE
	CALL	HXOUT			; DO HEX OUT ROUTINE
	LD	A,L			; GET LOW BYTE
	CALL	HXOUT			; HEX IT
	CALL	SPACE			; 
	RET				; DONE  

;__POUT_______________________________________________________________________
;
;	OUTPUT TO AN I/O PORT, MONITOR COMMAND "O"
;_____________________________________________________________________________
;
POUT:
POUT1:
;	INC	HL			;
	CALL	HEXIN			; GET PORT
	LD	C,A			; SAVE PORT POINTER
	INC	HL			;
	CALL	HEXIN			; GET DATA
OUTIT:
	OUT	(C),A			;
	JP	SERIALCMDLOOP		;


;__PIN________________________________________________________________________
;
;	INPUT FROM AN I/O PORT, MONITOR COMMAND "I"
;_____________________________________________________________________________
;
PIN:
;	INC 	HL			;
	CALL	HEXIN			; GET PORT
	LD	C,A			; SAVE PORT POINTER
	CALL	CRLF			;
	IN	A,(C)			; GET DATA
	CALL	HXOUT			; SHOW IT
	JP	SERIALCMDLOOP	        ;





;__CRLFA______________________________________________________________________
;
;	PRINT COMMAND PROMPT TO THE SERIAL PORT
;_____________________________________________________________________________
;
CRLFA:
	PUSH	HL			; PROTECT HL FROM OVERWRITE
	LD	HL,PROMPT		;
	CALL	MSG			;
	POP	HL			; PROTECT HL FROM OVERWRITE
	RET				; DONE


;__MSG________________________________________________________________________
;
;	PRINT A STRING  TO THE SERIAL PORT
;_____________________________________________________________________________
;
MSG:

TX_SERLP:
	LD	A,(HL)			; GET CHARACTER TO A
	CP	ENDT			; TEST FOR END BYTE
	JP	Z,TX_END		; JUMP IF END BYTE IS FOUND
	CALL	COUT			;
	INC	HL			; INC POINTER, TO NEXT CHAR
	JP	TX_SERLP		; TRANSMIT LOOP
TX_END:
	RET				;ELSE DONE

;__RUN________________________________________________________________________
;
;	TRANSFER OUT OF MONITOR, USER OPTION "R"
;_____________________________________________________________________________
;
RUN:
	INC	HL			; SHOW READY
	CALL	LDHL			; GET START ADDRESS
	JP	(HL)			;	


;__PROGRM_____________________________________________________________________
;
;	PROGRAM RAM LOCATIONS, USER OPTION "P"
;_____________________________________________________________________________
;
PROGRM:
	INC	HL			; SHOW READY
	PUSH	HL			; STORE HL
	CALL	LDHL			; GET START ADDRESS
	LD	D,H			;
	LD	E,L			; DE POINTS TO ADDRESS TO PROGRAM
	POP	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			;
PROGRMLP:
	CALL	HEXIN			; GET NEXT HEX NUMBER
	LD	(DE),A			; STORE IT
	INC	DE			; NEXT ADDRESS;
	CALL	CRLFA			; CR,LF,>
	LD      A,'P'			;
	CALL	COUT			;
	CALL  	SPACE			;
	LD	H,D			;
	LD	L,E			;
	CALL	PHL			;
	LD	HL,KEYBUF		; SET POINTER TO KEYBUF AREA
	CALL 	GETLN			; GET A LINE OF INPUT FROM THE USER
	LD	HL,KEYBUF		; RESET POINTER TO START OF KEYBUF
        LD      A,(HL)			; LOAD FIRST CHAR INTO A 
	CP	00H			; END OF LINE?
	JP	Z,PROGRMEXIT		; YES, EXIT
	JP	PROGRMLP		; NO, LOOP
PROGRMEXIT:
	JP	SERIALCMDLOOP	







;__DUMP_______________________________________________________________________
;
;	PRINT A MEMORY DUMP, USER OPTION "D"
;_____________________________________________________________________________
;
DUMP:
	INC	HL			; SHOW READY
	PUSH	HL			; STORE HL
	CALL	LDHL			; GET START ADDRESS
	LD	D,H			;
	LD	E,L			;
	POP	HL			;
	PUSH	DE			; SAVE START
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			;
	CALL	LDHL			; GET END ADDRESS
	INC	HL			; ADD ONE MORE FOR LATER COMPARE
	EX	DE,HL			; PUT END ADDRESS IN DE
	POP	HL			; GET BACK START
GDATA:	
	CALL	CRLF			;	
BLKRD:
	CALL	PHL			; PRINT START LOCATION
	LD	C,16			; SET FOR 16 LOCS
	PUSH	HL			; SAVE STARTING HL
NXTONE:
	EXX				;
	LD	C,E			;
	IN	A,(C)			;
	EXX				;
	AND	7FH			;
	CP	ESC			;
	JP	Z,SERIALCMDLOOP		;
	CP	19			;
	JR	Z,NXTONE		;
	LD 	A,(HL)			; GET BYTE
	CALL	HXOUT			; PRINT IT
	CALL	SPACE			;
UPDH:	
	INC	HL			; POINT NEXT
	DEC	C			; DEC  LOC COUNT
	JR	NZ,NXTONE		; IF LINE NOT DONE
					; NOW PRINT 'DECODED' DATA TO RIGHT OF DUMP
PCRLF:
	CALL	SPACE			; SPACE IT
	LD	C,16			; SET FOR 16 CHARS
	POP	HL			; GET BACK START
PCRLF0:
	LD	A,(HL)			; GET BYTE
	AND	060H			; SEE IF A 'DOT'
	LD	A,(HL)			; O K. TO GET
	JR	NZ,PDOT			;
DOT:
	LD	A,2EH			; LOAD A DOT	
PDOT:
	CALL	COUT			; PRINT IT
	INC	HL			; 
	LD	A,D			;
	CP	H			;
	JR	NZ,UPDH1		;
	LD	A,E			;
	CP	L			;
	JP	Z,SERIALCMDLOOP		;
;
;IF BLOCK NOT DUMPED, DO NEXT CHARACTER OR LINE
UPDH1:
	DEC	C			; DEC  CHAR COUNT
	JR	NZ,PCRLF0		; DO NEXT
CONTD:
	CALL	CRLF			;
	JP	BLKRD			;


;__HXLOAD_____________________________________________________________________
;
;	LOAD INTEL HEX FORMAT FILE FROM THE SERIAL PORT, USER OPTION "H"
;
;	 [INTEL HEX FORMAT IS:
;	 1) COLON (FRAME 0)
;	 2) RECORD LENGTH FIELD (FRAMES 1 AND 2)
;	 3) LOAD ADDRESS FIELD (FRAMES 3,4,5,6)
;	 4) RECORD TYPE FIELD (FRAMES 7 AND 8)
;	 5) DATA FIELD (FRAMES 9 TO 9+2*(RECORD LENGTH)-1
;	 6) CHECKSUM FIELD - SUM OF ALL BYTE VALUES FROM RECORD LENGTH TO AND 
;	   INCLUDING CHECKSUM FIELD = 0 ]
;
; EXAMPLE OF INTEL HEX FORMAT FILE
; EACH LINE CONTAINS A CARRIAGE RETURN AS THE LAST CHARACTER
; :18F900002048454C4C4F20574F524C4420FF0D0AFF0D0A3EFF0D0A54BF
; :18F918006573742050726F746F7479706520524F4D204D6F6E69746FF1
; :18F9300072205265616479200D0AFF0D0A434F4D4D414E4420524543F2
; :18F948004549564544203AFF0D0A434845434B53554D204552524F52CD
; :16F96000FF0A0D20202D454E442D4F462D46494C452D20200A0DA4
; :00000001FF
;_____________________________________________________________________________
HXLOAD:
	CALL	CRLF			; SHOW READY
HXLOAD0:
	CALL	KIN			; GET THE FIRST CHARACTER, EXPECTING A ':'
HXLOAD1:
	CP	03Ah			; IS IT COLON ':'? START OF LINE OF INTEL HEX FILE
	JR	NZ,HXLOADERR		; IF NOT, MUST BE ERROR, ABORT ROUTINE
	LD	E,0			; FIRST TWO CHARACTERS IS THE RECORD LENGTH FIELD
	CALL	HEXINS			; GET US TWO CHARACTERS INTO BC, CONVERT IT TO A BYTE <A>
	CALL	HXCHKSUM		; UPDATE HEX CHECK SUM
	LD	D,A			; LOAD RECORD LENGTH COUNT INTO D
	CALL	HEXINS			; GET NEXT TWO CHARACTERS, MEMORY LOAD ADDRESS <H>
	CALL	HXCHKSUM		; UPDATE HEX CHECK SUM
	LD	H,A			; PUT VALUE IN H REGISTER 
	CALL	HEXINS			; GET NEXT TWO CHARACTERS, MEMORY LOAD ADDRESS <L>
	CALL	HXCHKSUM		; UPDATE HEX CHECK SUM
	LD	L,A			; PUT VALUE IN L REGISTER 
	CALL	HEXINS			; GET NEXT TWO CHARACTERS, RECORD FIELD TYPE
	CALL	HXCHKSUM		; UPDATE HEX CHECK SUM
	CP	001h			; RECORD FIELD TYPE 00 IS DATA, 01 IS END OF FILE
	JR	NZ,HXLOAD2		; MUST BE THE END OF THAT FILE
	CALL	HEXINS			; GET NEXT TWO CHARACTERS, ASSEMBLE INTO BYTE
	CALL	HXCHKSUM		; UPDATE HEX CHECK SUM
	LD	A,E			; RECALL THE CHECKSUM BYTE
	AND	A			; IS IT ZERO?
        JP      Z,HXLOADEXIT		; MUST BE O K., GO BACK FOR SOME MORE, ELSE
	JR	HXLOADERR		; CHECKSUMS DON'T ADD UP, ERROR OUT	
HXLOAD2:
	LD	A,D			; RETRIEVE LINE CHARACTER COUNTER	
	AND	A			; ARE WE DONE WITH THIS LINE?
	JR	Z,HXLOAD3		; GET TWO MORE ASCII CHARACTERS, BUILD A BYTE AND CHECKSUM
	CALL	HEXINS			; GET NEXT TWO CHARS, CONVERT TO BYTE IN A, CHECKSUM IT
	CALL	HXCHKSUM		; UPDATE HEX CHECK SUM
	LD	(HL),A			; CHECKSUM OK, MOVE CONVERTED BYTE IN A TO MEMORY LOCATION
	INC	HL			; INCREMENT POINTER TO NEXT MEMORY LOCATION	
	DEC	D			; DECREMENT LINE CHARACTER COUNTER
	JR	HXLOAD2			; AND KEEP LOADING INTO MEMORY UNTIL LINE IS COMPLETE		
HXLOAD3:
	CALL	HEXINS			; GET TWO CHARS, BUILD BYTE AND CHECKSUM
	CALL	HXCHKSUM		; UPDATE HEX CHECK SUM
	LD	A,E			; CHECK THE CHECKSUM VALUE
	AND	A			; IS IT ZERO?
	JR	Z,HXLOADAGAIN		; IF THE CHECKSUM IS STILL OK, CONTINUE ON, ELSE
HXLOADERR:
	LD	HL,TXT_CKSUMERR		; GET "CHECKSUM ERROR" MESSAGE
	CALL	MSG			; PRINT MESSAGE FROM (HL) AND TERMINATE THE LOAD
	JP	HXLOADEXIT		; RETURN TO PROMPT
HXCHKSUM:
	LD	C,A			; BUILD THE CHECKSUM
	LD	A,E			;
	SUB	C			; THE CHECKSUM SHOULD ALWAYS .EQUAL ZERO WHEN CHECKED
	LD	E,A			; SAVE THE CHECKSUM BACK WHERE IT CAME FROM
	LD	A,C			; RETRIEVE THE BYTE AND GO BACK
	RET				; BACK TO CALLER
HXLOADAGAIN:
	CALL	KIN			; CATCH THE TRAILING CARRIAGE RETURN
	JP	HXLOAD0			; LOAD ANOTHER LINE OF DATA
HXLOADEXIT:
	CALL	KIN			; CATCH ANY STRAY TRAILING CHARACTERS
	JP	SERIALCMDLOOP		; RETURN TO PROMPT


;__MOVE_______________________________________________________________________
;
;	MOVE MEMORY, USER OPTION "M"
;_____________________________________________________________________________
;
MOVE:
	LD	C,03
					; START GETNM REPLACEMENT
					; GET SOURCE STARTING MEMORY LOCATION
	INC	HL			; SHOW EXAMINE READY
	PUSH	HL			;
	CALL	LDHL			; LOAD IN HL REGS 
	LD	D,H			;
	LD	E,L			;
	POP	HL			;
	PUSH	DE			; PUSH MEMORY ADDRESS ON STACK
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC 	HL			; PRINT SPACE SEPARATOR
	PUSH	HL			;
	CALL	LDHL			; LOAD IN HL REGS 
	LD	D,H			;
	LD	E,L			;
	POP	HL			;
	PUSH	DE			; PUSH MEMORY ADDRESS ON STACK
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			; PRINT SPACE SEPARATOR
	CALL	LDHL			; LOAD IN HL REGS 
	PUSH	HL			; PUSH MEMORY ADDRESS ON STACK
					; END GETNM REPLACEMENT
	POP	DE			; DEST
	POP	BC			; SOURCE END
	POP	HL			; SOURCE
	PUSH    HL			;
	LD	A,L			;
	CPL				;
	LD	L,A			;
	LD	A,H			;
	CPL				;
	LD	H,A			;
	INC	HL			;
	ADD	HL,BC			;
	LD	C,L			;
	LD	B,H			;
	POP     HL        		;
	CALL    MOVE_LOOP		;
	JP	SERIALCMDLOOP			; EXIT MOVE COMMAND ROUTINE
MOVE_LOOP:
	LD	A,(HL)			; FETCH
	LD	(DE),A			; DEPOSIT
	INC     HL			; BUMP  SOURCE
	INC     DE			; BUMP DEST
	DEC     BC			; DEC COUNT
	LD	A,C			;
	OR	B       		;
	JP	NZ,MOVE_LOOP		; TIL COUNT=0
	RET				;
               
;__FILLMEM____________________________________________________________________
;
;	FILL MEMORY, USER OPTION "M"
;_____________________________________________________________________________
;
FILLMEM:
	LD	C,03			;
					; START GETNM REPLACEMENT
					; GET FILL STARTING MEMORY LOCATION
	INC	HL			; SHOW EXAMINE READY
	PUSH	HL			;
	CALL	LDHL			; LOAD IN HL REGS 
	LD	D,H			;
	LD	E,L			;
	POP	HL			;
	PUSH	DE			; PUSH MEMORY ADDRESS ON STACK
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			; PRINT SPACE SEPARATOR
					; GET FILL ENDING MEMORY LOCATION
	PUSH	HL			;
	CALL	LDHL			; LOAD IN HL REGS 
	LD	D,H			;
	LD	E,L			;
	POP	HL			;
	PUSH	DE			; PUSH MEMORY ADDRESS ON STACK
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			;
	INC	HL			; PRINT SPACE SEPARATOR
					; GET TARGET STARTING MEMORY LOCATION
	CALL	HEXIN			; GET K B. AND MAKE HEX
	LD	C,A			; PUT FILL VALUE IN F SO IT IS SAVED FOR LATER
	PUSH	BC			; PUSH FILL VALUE BYTE ON STACK
					; END GETNM REPLACEMENT
	POP	BC			; BYTE
	POP	DE			; END
	POP	HL			; START
	LD	(HL),C			;
FILL_LOOP:
	LD	(HL),C			;
	INC     HL			;
	LD	A,E			;
	SUB     L			;
	LD	B,A			;
	LD	A,D			;
	SUB     H			;
	OR	B			;
	JP	NZ,FILL_LOOP		;
	JP	SERIALCMDLOOP		;

;__GOCPM______________________________________________________________________
;
;	BOOT CP/M FROM ROM DRIVE, USER OPTION "C"
;_____________________________________________________________________________
;
GOCPM:
;___________________________
; REMOVE COMMENTS WHEN BURNED IN ROM
;___________________________

;	LD	A,000000000b		; RESET MPCL LATCH TO DEFAULT ROM
;	OUT	(MPCL),A		;
;	LD	HL,ROMSTART_CPM		; WHERE IN ROM CP/M IS STORED (FIRST BYTE)
;        LD	DE,RAMTARG_CPM		; WHERE IN RAM TO MOVE MONITOR TO (FIRST BYTE)
;	LD	BC,MOVSIZ_CPM		; NUMBER OF BYTES TO MOVE FROM ROM TO RAM
;	LDIR				; PERFORM BLOCK COPY OF CP/M TO UPPER RAM PAGE
;	LD	A,010000000b		; RESET MPCL LATCH TO DEFAULT CP/M WITH 64K SETTING
;	OUT	(MPCL),A		;

	JP	CPM_ENT
;
;__INITIALIZE_________________________________________________________________
;
;	INITIALIZE SYSTEM
;_____________________________________________________________________________
;
INITIALIZE:
;	CALL	CIOCON_DISP + (CF_INIT * 3)
	RET
;

#IF DSKYENABLE

;__MTERM_INIT_________________________________________________________________
;
;  SETUP 8255, MODE 0, PORT A=OUT, PORT B=IN, PORT C=OUT/OUT
;     
;_____________________________________________________________________________
MTERM_INIT:
	LD	A, 82H
	OUT	(PPIX),A
	LD	A, 30H			;set PC4,5 to disable PPISD (if used)
	OUT	(PPIC),A		;won't affect DSKY
	RET

;__KB_GET_____________________________________________________________________
;
;  GET A SINGLE KEY AND DECODE
;     
;_____________________________________________________________________________
KB_GET:
	PUSH 	HL			; STORE HL
KB_GET_LOOP:				; WAIT FOR KEY
	CALL	KB_SCAN			;  SCAN KB ONCE
	CP	00H			;  NULL?
	JR	Z,KB_GET_LOOP		;  LOOP WHILE NOT ZERO
	LD      D,A			;  STORE A
	LD	A,4FH | 30H		;  SCAN ALL COL LINES
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
KB_CLEAR_LOOP:				; WAIT FOR KEY TO CLEAR
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KB_CLEAR_LOOP	;  YES, EXIT 
	LD	A,D			;  RESTORE A
	LD	D,00H			;
	LD	HL,KB_DECODE		;  POINT TO BEGINNING OF TABLE	
KB_GET_LLOOP:
	CP	(HL)			;  MATCH?	
	JR	Z,KB_GET_DONE		;  FOUND, DONE
	INC	HL
	INC	D			;  D + 1	
	JP	NZ,KB_GET_LLOOP		;  NOT FOUND, LOOP UNTIL EOT			
KB_GET_DONE:
	LD	A,D			;  RESULT INTO A
	POP	HL			; RESTORE HL
	RET
;
;__KB_SCAN____________________________________________________________________
;
;  SCAN KEYBOARD MATRIX FOR AN INPUT
;     
;_____________________________________________________________________________
;
KB_SCAN:
	LD      C,0000H
	LD	A,41H | 30H		;  SCAN COL ONE
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KB_SCAN_FOUND	;  YES, EXIT 

	LD      C,0040H
	LD	A,42H | 30H		;  SCAN COL TWO
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KB_SCAN_FOUND	;  YES, EXIT 

	LD      C,0080H
	LD	A,44H | 30H		;  SCAN COL THREE
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KB_SCAN_FOUND	;  YES, EXIT 

	LD      C,00C0H			;
	LD	A,48H | 30H		;  SCAN COL FOUR
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KB_SCAN_FOUND	;  YES, EXIT 

	LD	A, 40H | 30H		;  TURN OFF ALL COLUMNS
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
	LD	A, 00H			;  RETURN NULL
	RET				;  EXIT

KB_SCAN_FOUND:
	AND	3FH			;  CLEAR TOP TWO BITS
	OR	C			;  ADD IN ROW BITS 
	LD	C,A			;  STORE VALUE
	LD	A, 00H | 30H		;  TURN OFF ALL COLUMNS
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
	LD	A,C			;  RESTORE VALUE
	RET

PAUSE:
KB_SCAN_DELAY:
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RET



;__HEXDISPLAY_________________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF IN DECODED HEX BITS 0-3 ARE DISPLAYED DIG, BIT 7 IS DP
;     
;_____________________________________________________________________________
HEXDISPLAY:
	PUSH	HL			; STORE HL
	PUSH	AF			; STORE AF
	PUSH	BC			; STORE BC
	LD	BC,0007H	
	ADD	HL,BC
	LD	B,08H			; SET DIGIT COUNT
	LD	A,40H | 30H		; SET CONTROL PORT 7218 TO OFF
	OUT	(PPIC),A		; OUTPUT
	CALL 	PAUSE			; WAIT
	LD	A,0F0H			; SET CONTROL TO 1111 (DATA COMING, HEX DECODE,NO DECODE, NORMAL)
	OUT	(PPIA),A		; OUTPUT TO PORT
	LD	A,80H | 30H		; STROBE WRITE PULSE WITH CONTROL=1
	OUT	(PPIC),A		; OUTPUT TO PORT
	CALL 	PAUSE			; WAIT
	LD	A,40H | 30H		; SET CONTROL PORT 7218 TO OFF
	OUT	(PPIC),A		; OUTPUT
HEXDISPLAY_LP:		
	LD	A,(HL)			; GET DISPLAY DIGIT
	CALL	DECODEDISPLAY		; DECODE DISPLAY
	OUT	(PPIA),A		; OUT TO PPIA
	LD	A,00H | 30H		; SET WRITE STROBE
	OUT	(PPIC),A		; OUT TO PPIC
	CALL	PAUSE			; DELAY
	LD	A,40H | 30H		; SET CONTROL PORT OFF
	OUT	(PPIC),A		; OUT TO PPIC
	CALL	PAUSE			; WAIT
	DEC	HL			; INC POINTER
	DJNZ	HEXDISPLAY_LP		; LOOP FOR NEXT DIGIT
	POP	BC			; RESTORE BC
	POP	AF			; RESTORE AF
	POP	HL			; RESTORE HL
	RET

;__DECODEDISPLAY______________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF IN DECODED HEX BITS 0-3 ARE DISPLAYED DIG, BIT 7 IS DP
;     
;_____________________________________________________________________________
DECODEDISPLAY:
	PUSH	BC			; STORE BC
	PUSH	HL			; STORE HL
	LD	HL,SEGDECODE		; POINT HL TO DECODE TABLE
	LD	B,00H			; RESET HIGH BYTE
	LD	C,A			; CHAR INTO LOW BYTE
	ADD	HL,BC			; SET TABLE POINTER
	LD	A,(HL)			; GET VALUE
	POP	HL			; RESTORE HL
	POP	BC			; RESTORE BC
	RET


;__SEGDISPLAY_________________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF IN DECODED HEX BITS 0-3 ARE DISPLAYED DIG, BIT 7 IS DP
;     
;_____________________________________________________________________________
SEGDISPLAY:
	PUSH	AF			; STORE AF
	PUSH	BC			; STORE BC
	LD	BC,0007H	
	ADD	HL,BC
	LD	B,08H			; SET DIGIT COUNT
	LD	A,40H | 30H		; SET CONTROL PORT 7218 TO OFF
	OUT	(PPIC),A		; OUTPUT
	CALL 	PAUSE			; WAIT
	LD	A,0F0H			; SET CONTROL TO 1111 (DATA COMING, HEX DECODE,NO DECODE, NORMAL)
	OUT	(PPIA),A		; OUTPUT TO PORT
	LD	A,80H | 30H		; STROBE WRITE PULSE WITH CONTROL=1
	OUT	(PPIC),A		; OUTPUT TO PORT
	CALL 	PAUSE			; WAIT
	LD	A,40H | 30H		; SET CONTROL PORT 7218 TO OFF
	OUT	(PPIC),A		; OUTPUT
SEGDISPLAY_LP:		
	LD	A,(HL)			; GET DISPLAY DIGIT
	OUT	(PPIA),A		; OUT TO PPIA
	LD	A,00H | 30H		; SET WRITE STROBE
	OUT	(PPIC),A		; OUT TO PPIC
	CALL	PAUSE			; DELAY
	LD	A,40H | 30H		; SET CONTROL PORT OFF
	OUT	(PPIC),A		; OUT TO PPIC
	CALL	PAUSE			; WAIT
	DEC	HL			; INC POINTER
	DJNZ	SEGDISPLAY_LP		; LOOP FOR NEXT DIGIT
	POP	BC			; RESTORE BC
	POP	AF			; RESTORE AF
	RET

#ENDIF

;
;__WORK_AREA__________________________________________________________________
;
;	RESERVED RAM FOR MONITOR WORKING AREA
;_____________________________________________________________________________
;
KEYBUF:  	.FILL	80,' '
DISPLAYBUF:	.FILL	8,0
;
;__TEXT_STRINGS_______________________________________________________________
;
;	SYSTEM TEXT STRINGS
;_____________________________________________________________________________
;
TCRLF:
	.DB  	CR,LF,ENDT

PROMPT:
	.DB  	CR,LF,'>',ENDT

TXT_READY:
	.DB   CR,LF
	.TEXT   "         NN      NN      8888      VV      VV    EEEEEEEEEE   MM          MM"
	.DB   CR,LF
	.TEXT   "        NNNN    NN    88    88    VV      VV    EE           MMMM      MMMM"
	.DB   CR,LF
	.TEXT   "       NN  NN  NN    88    88    VV      VV    EE           MM  MM  MM  MM"
	.DB   CR,LF
	.TEXT   "      NN    NNNN    88    88    VV      VV    EE           MM    MM    MM"
	.DB   CR,LF
	.TEXT   "     NN      NN      8888      VV      VV    EEEEEEE      MM          MM"
	.DB   CR,LF
	.TEXT   "    NN      NN    88    88     VV    VV     EE           MM          MM"
	.DB   CR,LF
	.TEXT   "   NN      NN    88    88      VV  VV      EE           MM          MM"
	.DB   CR,LF
	.TEXT   "  NN      NN    88    88        VVV       EE           MM          MM"
	.DB   CR,LF
	.TEXT   " NN      NN      8888           V        EEEEEEEEEE   MM          MM    S B C"
	.DB   CR,LF
	.DB   CR,LF                                                                                                                                                
	.TEXT   " ****************************************************************************"
	.DB   CR,LF
	.TEXT   "MONITOR READY "
	.DB   CR,LF,ENDT

TXT_COMMAND:
	.DB   CR,LF
	.TEXT   "UNKNOWN COMMAND."
	.DB   ENDT

TXT_CKSUMERR:
	.DB   CR,LF
	.TEXT   "CHECKSUM ERROR."
	.DB   ENDT
CPUUP:
	.DB 	084H,0EEH,0BBH,080H,0BBH,0EEH,0CBH,084H
ADDR:
	.DB 	00H,00H,00H,00H,08CH,0BDH,0BDH,0FEH


PORT:
	.DB 	00H,00H,80H,80H,094H,08CH,09DH,0EEH
SEC:
	.DB 	80H,80H,80H,80H,80H,0CBH,0CFH,0D7H


;_KB DECODE TABLE_____________________________________________________________
; 
;
KB_DECODE:
;                0  1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	.DB	41H,02H,42H,82H,04H,44H,84H,08H,48H,88H,10H,50H,90H,20H,60H,0A0H
;               FW  BK  CL  EN  DP  EX  GO  BO
	.DB	01H,81H,0C1H,0C2H,0C4H,0C8H,0D0H,0E0H
;
; F-KEYS,
; FW = FORWARD
; BK = BACKWARD
; CL = CLEAR
; EN = ENTER
; DP = DEPOSIT (INTO MEM)
; EX = EXAMINE (MEM)
; GO = GO
; BO = BOOT
;_____________________________________________________________________________
;_HEX 7_SEG_DECODE_TABLE______________________________________________________
; 
; 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F, ,-
; AND WITH 7FH TO TURN ON DP 
;_____________________________________________________________________________
SEGDECODE:
	.DB	0FBH,0B0H,0EDH,0F5H,0B6H,0D7H,0DFH,0F0H,0FFH,0F7H,0FEH,09FH
	.DB	0CBH,0BDH,0CFH,0CEH,080H,084H,00H,0EEH,09DH

;********************* END OF PROGRAM ***********************************
;
SLACK		.EQU	(MON_END - $)
		.FILL	SLACK,00H
;
MON_STACK	.EQU	$
;
		.ECHO	"DBGMON space remaining: "
		.ECHO	SLACK
		.ECHO	" bytes.\n"

		.END
