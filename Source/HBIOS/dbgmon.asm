;___ROM_MONITOR_PROGRAM_______________________________________________________
;
;  ORIGINAL CODE BY:	ANDREW LYNCH (LYNCHAJ@YAHOO COM)	13 FEB 2007
;
;  MODIFIED BY : 	DAN WERNER 03 09.2009
;
;__REFERENCES_________________________________________________________________
; THOMAS SCHERRER BASIC HAR.DWARE TEST ASSEMBLER SOURCES FROM THE Z80 INFO PAGE
; INCLUDING ORIGINAL SCHEMATIC CONCEPT
; HTTP://Z80.INFO/Z80SOURC.TXT
; CODE SAMPLES FROM BRUCE JONES PUBLIC DOMAIN ROM MONITOR FOR THE SBC-200C
; HTTP://WWW.RETROTECHNOLOGY.COM/HERBS_STUFF/SD_BRUCE_CODE.ZIP
; INSPIRATION FROM JOEL OWENS "Z-80 SPACE-TIME PRODUCTIONS SINGLE BOARD COMPUTER"
; HTTP://WWW.JOELOWENS.ORG/Z80/Z80INDEX.HTML
; GREAT HELP AND TECHNICAL ADVICE FROM ALLISON AT ALPACA_DESIGNERS
; HTTP://GROUPS.YAHOO.COM/GROUP/ALPACA_DESIGNERS
; INTEL SDK-85 ROM DEBUG MONITOR
;_____________________________________________________________________________
;
#INCLUDE "std.asm"
;
BUFLEN	.EQU	40			; INPUT LINE LENGTH
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
#IF DSKYENABLE
  #DEFINE USEDELAY
#ENDIF
;
#INCLUDE "util.asm"
;
;__UART_ENTRY_________________________________________________________________
;
;	SERIAL MONITOR STARTUP
;_____________________________________________________________________________
;
UART_ENTRY:
	LD	SP,MON_STACK		; SET THE STACK POINTER
	EI				; INTS OK NOW
	LD	HL,UART_ENTRY		; RESTART ADDRESS
	CALL	INITIALIZE		; INITIALIZE SYSTEM

	LD	HL,TXT_READY		; POINT AT TEXT
	CALL	PRTSTRH			; SHOW WE'RE HERE
;
;__SERIAL_MONITOR_COMMANDS____________________________________________________
;
; B - BOOT SYSTEM
; D XXXX YYYY - DUMP MEMORY FROM XXXX TO YYYY
; F XXXX YYYY ZZ - FILL MEMORY FROM XXXX TO YYYY WITH ZZ
; I XX - SHOW VALUE AT PORT XX
; K - ECHO KEYBOARD INPUT
; L - LOAD INTEL HEX FORMAT DATA
; M XXXX YYYY ZZZZ - MOVE MEMORY BLOCK XXXX-YYYY TO ZZZZ
; O XX YY - WRITE VALUE YY TO PORT XX
; P XXXX - PROGRAM RAM STARTING AT XXXX, PROMPT FOR VALUES
; R XXXX - RUN A PROGRAM AT ADDRESS XXXX
;
;__COMMAND_PARSE______________________________________________________________
;
;	PROMPT USER FOR COMMANDS, THEN PARSE THEM
;_____________________________________________________________________________
;
SERIALCMDLOOP:
	LD	SP,MON_STACK		; RESET STACK
	LD	HL,TXT_PROMPT		;
	CALL	PRTSTR			;
	LD	HL,KEYBUF		; SET POINTER TO KEYBUF AREA
	CALL 	GETLN			; GET A LINE OF INPUT FROM THE USER
	LD	HL,KEYBUF		; RESET POINTER TO START OF KEYBUF
	LD	A,C			; GET LINE LENGTH ENTERED
	OR	A			; ZERO?
	JR	Z,SERIALCMDLOOP		; NOTHING ENTERED, LOOP
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
	CP	'L'			; IS IT A "L" (Y/N)
	JP	Z,HXLOAD		; INTEL HEX FORMAT LOAD DATA
	CP	'I'			; IS IT AN "I" (Y/N)
	JP	Z,PIN			; PORT INPUT
	CP	'D'			; IS IT A "D" (Y/N)
	JP	Z,DUMPMEM		; DUMP MEMORY
	CP	'K'			; IS IT A "K" (Y/N)
	JP	Z,KLOP			; LOOP ON KEYBOARD
	CP	'M'			; IS IT A "M" (Y/N)
	JP	Z,MOVEMEM		; MOVE MEMORY COMMAND
	CP	'F'			; IS IT A "F" (Y/N)
	JP	Z,FILLMEM		; FILL MEMORY COMMAND
	CP	'H'			; IS IT A "H" (Y/N)
	JP	Z,HELP			; HELP COMMAND
	CP	'S'			; IS IT A "H" (Y/N)
	JP	Z,STOP			; STOP COMMAND
	CP	'X'			; IS IT A "X" (Y/N)
	JP	Z,EXIT			; EXIT COMMAND
	LD	HL,TXT_COMMAND		; POINT AT ERROR TEXT
	CALL	PRTSTRH			; PRINT COMMAND LABEL

	JR	SERIALCMDLOOP
;
;__INITIALIZE_________________________________________________________________
;
;	INITIALIZE SYSTEM
;	AT ENTRY, HL SHOULD HAVE ADDRESS OF DESIRED RESTART ADDRESS
;_____________________________________________________________________________
;
INITIALIZE:
	LD	A,$C3		; JP OPCODE
	LD	(0),A		; STORE AT $0000
	LD	(1),HL		; STORE AT $0001

#IF (BIOS == BIOS_UNA)
	; INSTALL UNA INVOCATION VECTOR FOR RST 08
	LD	A,$C3		; JP INSTRUCTION
	LD	(8),A		; STORE AT 0x0008
	LD	HL,($FFFE)	; UNA ENTRY VECTOR
	LD	(9),HL		; STORE AT 0x0009
#ENDIF

;#IF (BIOS == BIOS_WBW)
;	CALL	DELAY_INIT
;#ENDIF

	RET
;
;__BOOT_______________________________________________________________________
;
;	PERFORM BOOT ACTION
;_____________________________________________________________________________
;
BOOT:
#IF (BIOS == BIOS_UNA)
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,0			; ROM BANK 0
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)
	JP	0			; JUMP TO RESTART ADDRESS
#ELSE
	;LD	A,BID_BOOT		; BOOT BANK
	;LD	HL,0			; ADDRESS ZERO
	;CALL	HB_BNKCALL		; DOES NOT RETURN
	LD	B,BF_SYSRESET		; SYSTEM RESTART
	LD	C,BF_SYSRES_COLD	; COLD START
	CALL	$FFF0			; CALL HBIOS
#ENDIF
;
;__EXIT_______________________________________________________________________
;
;	PERFORM EXIT ACTION
;_____________________________________________________________________________
;
EXIT:
#IF (BIOS == BIOS_UNA)
	JR	BOOT
#ELSE
	LD	B,BF_SYSRESET		; SYSTEM RESTART
	LD	C,BF_SYSRES_WARM	; WARM START
	CALL	$FFF0			; CALL HBIOS
#ENDIF
;
;__STOP_______________________________________________________________________
;
;	PERFORM STOP ACTION (HALT SYSTEM)
;_____________________________________________________________________________
;
STOP:
	DI
	HALT
;
;__RUN________________________________________________________________________
;
;	TRANSFER OUT OF MONITOR, USER OPTION "R"
;	SYNTAX: R <ADDR>
;_____________________________________________________________________________
;
RUN:
	CALL	WORDPARM		; GET START ADDRESS
	JP	C,ERR			; HANDLE ERRORS
	PUSH	DE			; SAVE VALUE
	CALL	NONBLANK		; LOOK FOR EXTRANEOUS PARAMETERS
	CP	0			; TEST FOR TERMINATING NULL
	JP	NZ,ERR			; ERROR IF NOT TERMINATING NULL
	POP	HL			; RECOVER START ADDRESS
	JP	(HL)			; GO
;
;__PROGRM_____________________________________________________________________
;
;	PROGRAM RAM LOCATIONS, USER OPTION "P"
;_____________________________________________________________________________
;
PROGRM:
	CALL	WORDPARM		; GET STARTING LOCATION
	JP	C,ERR			; HANDLE SYNTAX ERRORS
	PUSH	DE			; SAVE VALUE
	CALL	NONBLANK		; LOOK FOR EXTRANEOUS PARAMETERS
	CP	0			; TEST FOR TERMINATING NULL
	JP	NZ,ERR			; ERROR IF NOT TERMINATING NULL
PROGRM1:
	CALL	NEWLINE
	POP	HL
	PUSH	HL
	CALL	PHL
	CALL	PC_COLON
	CALL	PC_SPACE
	LD	HL,KEYBUF
	CALL	GETLN
	LD	HL,KEYBUF
	CALL	NONBLANK
	CP	0
	JP	Z,SERIALCMDLOOP
	CALL	BYTEPARM
	JR	C,PROGRM2		; SYNTAX ERROR
	POP	DE
	LD	(DE),A
	INC	DE
	PUSH	DE
	JR	PROGRM1
PROGRM2:
	LD	HL,TXT_BADNUM
	CALL	PRTSTR
	JR	PROGRM1
;
;__KLOP_______________________________________________________________________
;
;	READ FROM THE SERIAL PORT AND ECHO, MONITOR COMMAND "K"
;_____________________________________________________________________________
;
KLOP:
	CALL	NEWLINE			;
KLOP1:
	CALL	KIN			; GET A KEY
	CP	CHR_ESC			; IS <ESC>?
	JP	Z,SERIALCMDLOOP		; IF SO, ALL DONE
	CALL	COUT			; OUTPUT KEY TO SCREEN
	JR	KLOP1			; LOOP
;
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
;
HXLOAD:
	CALL	NEWLINE			; SHOW READY
HXLOADLINE:
	CALL	CIN			; GET THE FIRST CHARACTER, EXPECTING A ':'
	CP	':'			; IS IT COLON ':'? WAIT FOR START OF NEXT LINE OF INTEL HEX FILE
	JR	NZ,HXLOADLINE		; IF NOT, GO BACK TO WAIT
	LD	E,0			; RESET THE CHECKSUM BYTE <E>
	CALL	HEXINS			; FIRST TWO CHARACTERS IS THE RECORD LENGTH FIELD <D>
	LD	D,A			; LOAD RECORD LENGTH COUNT INTO D
	CALL	HEXINS			; GET NEXT TWO CHARACTERS, MEMORY LOAD ADDRESS <H>
	LD	H,A			; PUT VALUE IN H REGISTER
	CALL	HEXINS			; GET NEXT TWO CHARACTERS, MEMORY LOAD ADDRESS <L>
	LD	L,A			; PUT VALUE IN L REGISTER
	CALL	HEXINS			; GET NEXT TWO CHARACTERS, RECORD FIELD TYPE
	DEC A				; RECORD FIELD TYPE 01 IS END OF FILE
	JR	Z,HXLOADEXIT		; MUST BE THE END OF THAT FILE
	INC A				; RECORD FIELD TYPE 00 IS DATA
	JR	NZ,HXLOADTYPERR		; RECORD TYPE IS INCORRECT, ERROR OUT
HXLOADDATA:
	CALL	HEXINS			; GET NEXT TWO CHARACTERS, ASSEMBLE INTO BYTE
	LD	(HL),A			; MOVE CONVERTED BYTE IN A TO MEMORY LOCATION
	INC	HL			; INCREMENT POINTER TO NEXT MEMORY LOCATION
	DEC	D			; DECREMENT LINE CHARACTER COUNTER
	JR	NZ,HXLOADDATA		; AND KEEP LOADING INTO MEMORY UNTIL LINE IS COMPLETE
	CALL	HEXINS			; GET NEXT TWO CHARACTERS, ASSEMBLE INTO CHECKSUM BYTE
	LD	A,E			; RECALL THE CHECKSUM BYTE
	OR	A			; IT SHOULD BE ZERO
	JR	Z,HXLOADLINE		; ZERO, SO WE HAVE NO ERROR, GO GET ANOTHER LINE
HXLOADCHKERR:
	LD	HL,TXT_CKSUMERR		; GET "CHECKSUM ERROR" MESSAGE
	CALL	PRTSTR			; PRINT MESSAGE FROM (HL) AND TERMINATE THE LOAD
	JP	SERIALCMDLOOP		; RETURN TO PROMPT
HXLOADTYPERR:
	LD	HL,TXT_RECORDERR	; GET "RECORD TYPE ERROR" MESSAGE
	CALL	PRTSTR			; PRINT MESSAGE FROM (HL) AND TERMINATE THE LOAD
	JP	SERIALCMDLOOP		; RETURN TO PROMPT
HXLOADEXIT:
	CALL	HEXINS			; GET LAST TWO CHARACTERS, ASSEMBLE INTO CHECKSUM BYTE
	LD	A,E			; RECALL THE CHECKSUM BYTE
	OR	A		    	; IT SHOULD BE ZERO
	JR	NZ,HXLOADCHKERR		; CHECKUM IS INCORRECT, ERROR OUT
	LD	HL,TXT_LOADED		; GET "LOADED" MESSAGE
	CALL	PRTSTR			; PRINT MESSAGE FROM (HL)
	JP	SERIALCMDLOOP		; RETURN TO PROMPT
;
;__POUT_______________________________________________________________________
;
;	OUTPUT TO AN I/O PORT, MONITOR COMMAND "O"
;	SYNTAX: O <PORT> <VALUE>
;	NOTE: A WORD VALUE IS USED FOR THE PORT NUMBER BECAUSE THE
;             Z80 WILL ACTUALLY PLACE 16 BITS ON THE BUS USING
;             THE B AND C REGISTERS WITH AN "OUT (C),A" INSTRUCTION
;_____________________________________________________________________________
;
POUT:
	CALL	WORDPARM		; GET PORT NUMBER
	JP	C,ERR			; HANDLE ERRORS
	PUSH	DE			; SAVE IT FOR NOW
	CALL	BYTEPARM		; GET VALUE TO WRITE
	JP	C,ERR			; HANDLE ERRORS
	POP	BC			; RESTORE PORT NUMBER TO BC
	OUT	(C),A			; SEND VALUE TO PORT
	JP	SERIALCMDLOOP		; DONE, BACK TO COMMAND LOOP
;
;__PIN________________________________________________________________________
;
;	INPUT FROM AN I/O PORT, MONITOR COMMAND "I"
;	SYNTAX: I <PORT>
;       NOTE: A WORD VALUE IS USED FOR THE PORT NUMBER BECAUSE THE
;             Z80 WILL ACTUALLY PLACE 16 BITS ON THE BUS USING
;             THE B AND C REGISTERS WITH AN "IN A,(C)" INSTRUCTION
;_____________________________________________________________________________
;
PIN:
	CALL	WORDPARM		; GET PORT NUMBER
	JP	C,ERR			; HANDLE ERRORS
	PUSH	DE			; SAVE IT
	CALL	NEWLINE			;
	POP	BC			; RESTORE TO BC
	IN	A,(C)			; GET PORT VALUE
	CALL	PRTHEXBYTE		; DISPLAY IT
	JP	SERIALCMDLOOP		; DONE, BACK TO COMMAND LOOP
;
;__DUMPMEM____________________________________________________________________
;
;	PRINT A MEMORY DUMP, USER OPTION "D"
;	SYNTAX: D <START ADR> <END ADR>
;_____________________________________________________________________________
;
DUMPMEM:
	CALL	WORDPARM		; GET START ADDRESS
	JP	C,ERR			; HANDLE ERRORS
	PUSH	DE			; SAVE IT
	CALL	WORDPARM		; GET END ADDRESS
	JP	C,ERR			; HANDLE ERRORS
	PUSH	DE			; SAVE IT
	
	POP	DE			; DE := END ADDRESS
	POP	HL			; HL := START ADDRESS

GDATA:
	INC	DE			; BUMP DE FOR LATER COMPARE
	CALL	NEWLINE			;
BLKRD:
	CALL	PHL			; PRINT START LOCATION
	CALL	PC_COLON
	CALL	PC_SPACE
	LD	C,16			; SET FOR 16 LOCS
	PUSH	HL			; SAVE STARTING HL
NXTONE:
	EXX				;
	LD	C,E			;
	IN	A,(C)			;
	EXX				;
	AND	7FH			;
	CP	CHR_ESC			;
	JP	Z,SERIALCMDLOOP		;
	CP	19			;
	JR	Z,NXTONE		;
	LD 	A,(HL)			; GET BYTE
	CALL	PRTHEXBYTE		; DISPLAY IT
	CALL	PC_SPACE		;
UPDH:
	INC	HL			; POINT NEXT
	DEC	C			; DEC  LOC COUNT
	JR	NZ,NXTONE		; IF LINE NOT DONE
					; NOW PRINT 'DECODED' DATA TO RIGHT OF DUMP
PCRLF:
	CALL	PC_SPACE		; SPACE IT
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
	CALL	NEWLINE			;
	JR	BLKRD			;
;
;__MOVEMEM____________________________________________________________________
;
;	MOVE MEMORY, USER OPTION "M"
;	SYNTAX: M <SRC-START> <SRC-END> <TGT>
;_____________________________________________________________________________
;
MOVEMEM:
	CALL	WORDPARM		; GET WORD VALUE INTO DE (MOVE SRC START ADR)
	JP	C,ERR			; SYNTAX ERROR IF HEXWORD FAILED
	PUSH	DE			; SAVE IT
	CALL	WORDPARM		; GET WORD VALUE INTO DE (MOVE SRC END ADR)
	JP	C,ERR			; SYNTAX ERROR IF HEXWORD FAILED
	PUSH	DE			; SAVE IT
	CALL	WORDPARM		; GET WORD VALUE INTO DE (MOVE TGT ADR)
	JP	C,ERR			; SYNTAX ERROR IF HEXBYTE FAILED
	PUSH	DE			; SAVE IT
	CALL	NONBLANK		; LOOK FOR EXTRANEOUS PARAMETERS
	CP	0			; TEST FOR TERMINATING NULL
	JP	NZ,ERR			; ERROR IF NOT TERMINATING NULL

	POP	DE			; TGT ADR TO DE
	POP	BC			; SRC END ADR TO BC
	POP	HL			; SRC START ADR TO HL
	DEC	HL			; PRE-DECREMENT
	DEC	DE			; PRE-DECREMENT
MOVEMEM1:
	INC	HL			; BUMP CUR SRC ADR
	INC	DE			; BUMP CUR TGT ADR
	LD	A,(HL)			; GET SOURCE VAUEE
	LD	(DE),A			; WRITE TO TARGET LOC
	LD	A,H			; CHECK MSB OF END ADR
	CP	B			;
	JR	NZ,MOVEMEM1		; NO MATCH, LOOP
	LD	A,L			; CHECK LSB OF END ADR
	CP	C			;
	JR	NZ,MOVEMEM1		; NO MATCH, LOOP
	JP	SERIALCMDLOOP		; LSB AND MSB MATCH, ALL DONE
;
;__FILLMEM____________________________________________________________________
;
;	FILL MEMORY, USER OPTION "M"
;	SYNTAX: F <START> <END> <VALUE>
;_____________________________________________________________________________
;
FILLMEM:
	CALL	WORDPARM		; GET WORD VALUE INTO DE (FILL START ADR)
	JP	C,ERR			; SYNTAX ERROR IF HEXWORD FAILED
	PUSH	DE			; SAVE IT
	CALL	WORDPARM		; GET WORD VALUE INTO DE (FILL END ADR)
	JP	C,ERR			; SYNTAX ERROR IF HEXWORD FAILED
	PUSH	DE			; SAVE IT
	CALL	BYTEPARM		; GET BYTE VALUE (FILL VALUE) INTO A
	JP	C,ERR			; SYNTAX ERROR IF HEXBYTE FAILED
	LD	C,A			; FILL VALUE TO C
	CALL	NONBLANK		; LOOK FOR EXTRANEOUS PARAMETERS
	CP	0			; TEST FOR TERMINATING NULL
	JP	NZ,ERR			; ERROR IF NOT TERMINATING NULL
	
	POP	DE			; END ADR TO DE
	POP	HL			; START ADR TO HL
	DEC	HL			; PRE-DECREMENT
FILLMEM1:
	INC	HL			; BUMP CUR ADR
	LD	A,C			; FILL VALUE TO A
	LD	(HL),A			; WRITE FILL VALUE TO CUR ADR (HL)
	LD	A,H			; CHECK MSB OF END ADR
	CP	D			;
	JR	NZ,FILLMEM1		; NO MATCH, LOOP
	LD	A,L			; CHECK LSB OF END ADR
	CP	E			;
	JR	NZ,FILLMEM1		; NO MATCH, LOOP
	JP	SERIALCMDLOOP		; LSB AND MSB MATCH, ALL DONE
;
;__HELP_______________________________________________________________________
;
;	SYNTAX HELP, USER OPTION "H"
;_____________________________________________________________________________
;
HELP:
	LD	HL,TXT_HELP		; POINT AT SYNTAX HELP TEXT
	CALL	PRTSTR			; DISPLAY IT
	JP	SERIALCMDLOOP		; AND BACK TO COMMAND LOOP
;
;__ERR________________________________________________________________________
;
;	SYNTAX ERROR
;_____________________________________________________________________________
;
ERR:
	LD	HL,TXT_ERR		; POINT AT ERROR TEXT
	CALL	PRTSTRH			; DISPLAY IT
	JP	SERIALCMDLOOP		; AND BACK TO COMMAND LOOP
;
;__BYTEPARM___________________________________________________________________
;
;	ATTEMPT TO GET A BYTE PARM, VALUE RETURNED IN A
;       CF SET ON ERROR
;_____________________________________________________________________________
;
BYTEPARM:
	CALL	NONBLANK		; SKIP LEADING BLANKS
	JP	Z,ERR			; SYNTAX ERROR IF PARM NOT FOUND
	CALL	ISHEX			; HEX CHAR?
	JR	NZ,BYTEPARM1		; IF NOT, ERR
	JP	HEXBYTE			; RETURN VIA HEXBYTE
BYTEPARM1:
	SCF				; SIGNAL ERROR
	RET				; RETURN
;
;__WORDPARM___________________________________________________________________
;
;	ATTEMPT TO GET A WORD PARM, VALUE RETURNED IN DE
;       CF SET ON ERROR
;_____________________________________________________________________________
;
WORDPARM:
	CALL	NONBLANK		; SKIP LEADING BLANKS
	JP	Z,ERR			; SYNTAX ERROR IF PARM NOT FOUND
	CALL	ISHEX			; HEX CHAR?
	JR	NZ,BYTEPARM1		; IF NOT, ERR
	JP	HEXWORD			; RETURN VIA HEXWORD
;
;__GETLN______________________________________________________________________
;
;	READ A LINE OF TEXT FROM THE SERIAL PORT, HANDLE <BS>, TERM ON <CR>
;       EXIT IF TOO MANY CHARS    STORE RESULT IN HL.  CHAR COUNT IN C.
;_____________________________________________________________________________
;
GETLN:
	LD	C,0			; ZERO CHAR COUNTER
	PUSH	DE			; SAVE DE
GETLNLOP:
	; ENTRY LOOP
	CALL	KIN			; GET A KEY
	CP	CHR_CR			; IS <CR>?
	JR	Z,GETLNDONE		; YES, EXIT
	CP	CHR_BS			; IS <BS>?
	JR	Z,GETLNBS		; IF SO, HANDLE IT
	CP	' '			; UNEXPECTED CONTROL CHAR?
	JR	C,GETLNLOP		; IF SO, IGNORE IT AND GET NEXT
	LD	B,A			; SAVE CHAR IN B FOR NOW
	LD	A,C			; GET COUNTER
	CP	BUFLEN - 1		; MAX OF BUFLEN CHARS LESS SPACE FOR TERM NULL
	JR	Z,GETLNOVF		; IF AT MAX, HANDLE OVERFLOW
	LD	A,B			; GET INPUT CHAR BACK
	CALL	COUT			; OUTPUT KEY TO SCREEN
	LD	(HL),A			; STORE CHAR IN BUFFER
	INC	HL			; INC POINTER
	INC	C			; INC CHAR COUNTER
	JR	GETLNLOP		; GET NEXT CHAR
GETLNOVF:
	; OVERFLOW
	LD	A,CHR_BEL		; BELL CHARACTER
	CALL	COUT			; SEND IT TO CONSOLE
	JR	GETLNLOP		; LOOP
GETLNBS:
	; BACKSPACE
	LD	A,C			; A=C
	OR	A			; ZERO?
	JR	Z,GETLNLOP		; IF EMPTY LINE, IGNORE BS & LOOP
	DEC	HL			; BACKUP BUF PTR 1 CHAR
	DEC	C			; DECREMENT CHAR COUNTER
	LD	A,CHR_BS		; BACKSPACE
	CALL	COUT			; TO CONSOLE
	LD	A,20H			; BLANK OUT CHAR ON TERM
	CALL	COUT			; TO CONSOLE
	LD	A,CHR_BS		; BACKSPACE
	CALL	COUT			; TO CONSOLE
	JR	GETLNLOP		; GET NEXT KEY
	; DONE
GETLNDONE:
	LD	(HL),00H		; STORE NULL IN BUFFER
	POP	DE			; RESTORE DE
	RET				;
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
;__NONBLANK___________________________________________________________________
;
;	FIND NEXT NONBLANK CHARACTER IN BUFFER AT (HL)
;_____________________________________________________________________________
;
NONBLANK:
	LD	A,(HL)			; GET NEXT CHAR
	CP	' '			; COMPARE TO BLANK
	RET	NZ			; DONE IF NOT BLANK
	INC	HL			; BUMP TO NEXT CHAR
	JR	NONBLANK		; AND LOOP
;
;__ISHEX______________________________________________________________________
;
;	CHECK BYTE AT (HL) FOR HEX CHAR, RET Z IF SO, ELSE NZ
;_____________________________________________________________________________
;
ISHEX:
	LD	A,(HL)			; CHAR TO AS
	CP	'0'			; < '0'?
	JR	C,ISHEX1		; YES, NOT 0-9, CHECK A-F
	CP	'9' + 1			; > '9'
	JR	NC,ISHEX1		; YES, NOT 0-9, CHECK A-F
	XOR	A			; MUST BE 0-9, SET ZF
	RET				; AND DONE
ISHEX1:
	CP	'A'			; < 'A'?
	JR	C,ISHEX2		; YES, NOT A-F, FAIL
	CP	'F' + 1			; > 'F'
	JR	NC,ISHEX2		; YES, NOT A-F, FAIL
	XOR	A			; MUST BE 0-9, SET ZF
	RET				; AND DONE
ISHEX2:
	OR	$FF			; CLEAR ZF
	RET				; AND DONE
;
;__HEXBYTE____________________________________________________________________
;
;	GET ONE BYTE OF HEX DATA FROM BUFFER IN HL, RETURN IN A
;_____________________________________________________________________________
;
HEXBYTE:
	LD	C,0			; INIT WORKING VALUE
HEXBYTE1:
	CALL	ISHEX			; DO WE HAVE A HEX CHAR?
	JR	NZ,HEXBYTE3		; IF NOT, WE ARE DONE
	LD	B,4			; SHIFT WORKING VALUE (C := C * 16)
HEXBYTE2:
	SLA	C			; SHIFT ONE BIT
	RET	C			; RETURN W/ CF SET INDICATING OVERFLOW ERROR
	DJNZ	HEXBYTE2		; LOOP FOR 4 BITS
	CALL	NIBL			; CONVERT HEX CHAR TO BINARY VALUE IN A & INC HL
	OR	C			; COMBINE WITH WORKING VALUE
	LD	C,A			; AND PUT BACK IN WORKING VALUE
	JR	HEXBYTE1		; DO ANOTHER CHARACTER
HEXBYTE3:
	LD	A,C			; WORKING VALUE TO A
	OR	A			; CLEAR CARRY
	RET				; AND DONE
;
;__HEXWORD____________________________________________________________________
;
;	GET ONE WORD OF HEX DATA FROM BUFFER IN HL, RETURN IN DE
;_____________________________________________________________________________
;
HEXWORD:
	LD	DE,0			; INIT WORKING VALUE
HEXWORD1:
	CALL	ISHEX			; DO WE HAVE A HEX CHAR?
	JR	NZ,HEXWORD3		; IF NOT, WE ARE DONE
	LD	B,4			; SHIFT WORKING VALUE (DE := DE * 16)
HEXWORD2:
	SLA	E			; SHIFT LSB ONE BIT
	RL	D			; SHIFT MSB ONE BIT
	RET	C			; RETURN W/ CF SET INDICATING OVERFLOW ERROR
	DJNZ	HEXWORD2		; LOOP FOR 4 BITS
	CALL	NIBL			; CONVERT HEX CHAR TO BINARY VALUE IN A & INC HL
	OR	E			; COMBINE WITH LSB
	LD	E,A			; AND PUT BACK IN WROKING VALUE
	JR	HEXWORD1		; DO ANOTHER CHARACTER
HEXWORD3:
	OR	A			; CLEAR CARRY
	RET				; AND DONE
;
;__NIBL_______________________________________________________________________
;
;	GET ONE BYTE OF HEX DATA FROM BUFFER IN HL, RETURN IN A
;_____________________________________________________________________________
;
NIBL:
	LD	A,(HL)			; GET K B. DATA
	INC	HL			; INC KB POINTER
	CP	40H			; TEST FOR ALPHA
	JR	NC,ALPH
	AND	0FH			; GET THE BITS
	RET
ALPH:
	AND	0FH			; GET THE BITS
	ADD	A,09H			; MAKE IT HEX A-F
	RET
;
;__HEXINS_____________________________________________________________________
;
;	GET ONE BYTE OF HEX DATA FROM SERIAL PORT, CHECKSUM IN E, RETURN IN A
;_____________________________________________________________________________
;
HEXINS:
	CALL	NIBLS			; DO A NIBBLE
	RLCA				; MOVE FIRST BYTE UPPER NIBBLE
	RLCA				;
	RLCA				;
	RLCA				;
	LD	B,A			; SAVE ROTATED NIBBLE
	CALL	NIBLS			; DO NEXT NIBBLE
	OR	B			; COMBINE NIBBLES IN ACC TO BYTE
	LD	B,A			; SAVE BYTE
	ADD	A,E			; ADD TO CHECKSUM
	LD	E,A			; SAVE CHECKSUM
	LD	A,B			; RECOVER BYTE
	RET				; DONE
NIBLS:
	CALL	CIN			; GET K B. DATA
	SUB	'0'
	CP	10	 		; TEST FOR ALPHA
	RET	C			; IF A<10 JUST RETURN
	SUB	7			; ELSE SUBTRACT 'A'-'0' (17) AND ADD 10
	RET
;
;__PHL________________________________________________________________________
;
;	PRINT THE HL REG ON THE SERIAL PORT
;_____________________________________________________________________________
;
PHL:
	LD	A,H			; GET HI BYTE
	CALL	PRTHEXBYTE		; DISPLAY IT
	LD	A,L			; GET LOW BYTE
	CALL	PRTHEXBYTE		; DISPLAY IT
	RET				; DONE
;
;__PRTSTRH____________________________________________________________________
;
;	PRINT STRING AT HL W/ MINI HELP SUFFIX
;_____________________________________________________________________________
;
PRTSTRH:
	CALL	PRTSTR
	LD	HL,TXT_MINIHELP
	JP	PRTSTR
;
#IF (BIOS == BIOS_UNA)
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
;
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
	LD	C,CIO_CONSOLE		; CONSOLE UNIT TO C
	LD	B,BF_CIOOUT		; HBIOS FUNC: OUTPUT CHAR
	RST	08			; HBIOS OUTPUTS CHARACTER
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
	LD	C,CIO_CONSOLE		; CONSOLE UNIT TO C
	LD	B,BF_CIOIN		; HBIOS FUNC: INPUT CHAR
	RST	08			; HBIOS READS CHARACTER
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
	LD	C,CIO_CONSOLE		; CONSOLE UNIT TO C
	LD	B,BF_CIOIST		; HBIOS FUNC: INPUT STATUS
	RST	08			; HBIOS RETURNS STATUS IN A
;
	; RESTORE REGISTERS (AF IS OUTPUT)
	POP	HL
	POP	DE
	POP	BC
	RET
;
#ENDIF
;
;__WORK_AREA__________________________________________________________________
;
;	RESERVED RAM FOR MONITOR WORKING AREA
;_____________________________________________________________________________
;
KEYBUF:  	.FILL	BUFLEN,0
;
;__TEXT_STRINGS_______________________________________________________________
;
;	SYSTEM TEXT STRINGS
;_____________________________________________________________________________
;
TXT_PROMPT	.TEXT	"\r\n>$"
TXT_READY	.TEXT	"\r\n\r\nMonitor Ready$"
TXT_COMMAND	.TEXT	"\r\nUnknown Command$"
TXT_ERR		.TEXT	"\r\nSyntax Error$"
TXT_CKSUMERR	.TEXT	"\r\nChecksum Error$"
TXT_RECORDERR	.TEXT	"\r\nRecord Type Error$"
TXT_LOADED	.TEXT	"\r\nLoaded$"
TXT_BADNUM	.TEXT	" *Invalid Hex Byte Value*$"
TXT_MINIHELP	.TEXT	" (H for Help)$"
TXT_HELP	.TEXT	"\r\nMonitor Commands (all values in hex):"
		.TEXT	"\r\nB                - Boot system"
		.TEXT	"\r\nD xxxx yyyy      - Dump memory from xxxx to yyyy"
		.TEXT	"\r\nF xxxx yyyy zz   - Fill memory from xxxx to yyyy with zz"
		.TEXT	"\r\nI xx             - Input from port xx"
		.TEXT	"\r\nK                - Keyboard echo"
		.TEXT	"\r\nL                - Load Intel hex data"
		.TEXT	"\r\nM xxxx yyyy zzzz - Move memory block xxxx-yyyy to zzzz"
		.TEXT	"\r\nO xx yy          - Output to port xx value yy"
		.TEXT	"\r\nP xxxx           - Program RAM at xxxx"
		.TEXT	"\r\nR xxxx           - Run code at xxxx"
		.TEXT	"\r\nS                - Stop system (HALT)"
		.TEXT	"\r\nX                - Exit monitor"
		.TEXT	"$"
;
#IF DSKYENABLE
;
#DEFINE DSKY_KBD
#INCLUDE "dsky.asm"
;
KY_PR	.EQU	KY_FW		; USE [FW] FOR [PR] (PORT READ)
KY_PW	.EQU	KY_BK		; USE [BW] FOR [PW] (PORT WRITE)
;
;__DSKY_ENTRY_________________________________________________________________
;
;	DSKY FRONT PANEL STARTUP
;_____________________________________________________________________________
;
DSKY_ENTRY:
	LD	SP,MON_STACK		; SET THE STACK POINTER
	EI				; INTS OK NOW
	LD	HL,DSKY_ENTRY		; RESTART ADDRESS
	CALL	INITIALIZE
;
;__FRONT_PANEL_STARTUP________________________________________________________
;
;	START UP THE SYSTEM WITH THE FRONT PANEL INTERFACE
;_____________________________________________________________________________
;
	CALL    DSKY_INIT		; INIT 8255
;
;__COMMAND_PARSE______________________________________________________________
;
;	PROMPT USER FOR COMMANDS, THEN PARSE THEM
;_____________________________________________________________________________
;
FRONTPANELLOOP:
	LD	HL,CPUUP		; SET POINTER TO CPU UP MSG
	CALL	DSKY_SHOWSEG		; DISPLAY UNENCODED

	CALL	KB_GET			; GET KEY FROM KB

FRONTPANELLOOP1:
	CP	KY_PR			; IS PORT READ?
	JP	Z,DOPORTREAD		; YES, JUMP
	CP	KY_PW			; IS PORT WRITE?
	JP	Z,DOPORTWRITE		; YES, JUMP
	CP	KY_DE			; IS DEPOSIT?
	JP	Z,DODEPOSIT		; YES, JUMP
	CP	KY_EX			; IS EXAMINE?
	JP	Z,DOEXAMINE		; YES, JUMP
	CP	KY_GO			; IS GO?
	JP	Z,DOGO			; YES, JUMP
	CP	KY_BO			; IS BOOT?
	JP	Z,DOBOOT		; YES, JUMP

	JR	FRONTPANELLOOP		; LOOP
;
;__DOBOOT_____________________________________________________________________
;
;	PERFORM BOOT FRONT PANEL ACTION
;_____________________________________________________________________________
;
DOBOOT:
	LD	HL,MSGBOOT		; SET POINTER TO BOOT MESSAGE
	CALL	DSKY_SHOWSEG		; DISPLAY UNENCODED
	JP	BOOT			; DO BOOT
;
;__DOPORTREAD_________________________________________________________________
;
;	PERFORM PORT READ FRONT PANEL ACTION
;       PANEL TEMPLATE "Po88  88"
;                  POS  01234567
;_____________________________________________________________________________
;
DOPORTREAD:
	CALL 	GETPORT			; GET PORT INTO A
PORTREADLOOP:
	LD	C,A			; STORE PORT IN "C"
	LD	DE,DISPLAYBUF+2		; POINT TO POS 2 IN BUF
	CALL	PUTVALUE		; DISPLAY PORT NUM
	IN 	A,(C)			; GET PORT VALUE FROM PORT IN "C"
	INC	DE			; ADVANCE BUF PTR
	INC	DE			; ... TO LAST TWO POSITIONS
	CALL	PUTVALUE		; DISPLAY PORT VALUE
	CALL	ENCDISPLAY		; DISPLAY BUFFER CONTENTS
PORTREADGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	JR	PORTREADGETKEY		; NO VALID KEY, LOOP
;
;__DOPORTWRITE________________________________________________________________
;
;	PERFORM PORT WRITE FRONT PANEL ACTION
;       PANEL TEMPLATE "Po88  88"
;                  POS  01234567
;_____________________________________________________________________________
;
DOPORTWRITE:
	CALL 	GETPORT			; GET PORT INTO A
PORTWRITELOOP:
	LD	L,A			; SAVE PORT NUM
	LD	DE,DISPLAYBUF+2		; POINT TO POS 2 IN BUF
	CALL	PUTVALUE		; DISPLAY PORT NUM
	CALL	GETVALUE		; INPUT A BYTE VALUE, RETURN IN "A"
	LD	C,L			; RESTORE PORT NUM
	OUT	(C),A			; OUTPUT VALUE TO PORT STORED IN "C"
	LD	DE,DISPLAYBUF+6		; DISPLAY WRITTEN PORT VALUE
	CALL	PUTVALUE		; ... WITHOUT DP'S
	CALL	ENCDISPLAY		; DISPLAY BUFFER CONTENTS
PORTWRITEGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	JR	PORTWRITEGETKEY		; NO VALID KEY, LOOP
;
;__DOGO_______________________________________________________________________
;
;	PERFORM GO FRONT PANEL ACTION
;_____________________________________________________________________________
;
DOGO:
	CALL 	GETADDR			; GET ADDRESS INTO HL
	PUSH	HL			; EXEC ADR TO TOS
	LD	HL,GOTO			; POINT TO "GO" MSG
	CALL	INITBUF
	POP	HL
	LD	DE,DISPLAYBUF+4
	LD	A,H
	CALL	PUTVALUE
	LD	A,L
	CALL	PUTVALUE
	CALL	ENCDISPLAY		; DISPLAY
	JP	(HL)			; AND RUN
;
;__DOEXAMINE__________________________________________________________________
;
;	PERFORM EXAMINE FRONT PANEL ACTION
;       PANEL TEMPLATE "8888  88"
;                  POS  01234567
;_____________________________________________________________________________
;
DOEXAMINE:
	CALL 	GETADDR			; GET ADDRESS INTO HL
EXAMINELOOP:
	LD	DE,DISPLAYBUF+0
	LD	A,H
	CALL	PUTVALUE
	LD	A,L
	CALL	PUTVALUE
	LD	A,$10
	LD	(DE),A
	INC	DE
	LD	(DE),A
	INC	DE
	LD	A,(HL)			; GET VALUE FROM ADDRESS IN HL
	CALL	PUTVALUE
	CALL	ENCDISPLAY		; DISPLAY BUFFER ON DISPLAYS
EXAMINEGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	CP	KY_EN			; [EN] PRESSED, INC ADDRESS AND LOOP
	JR	Z,EXAMINEFW		;
	JR	EXAMINEGETKEY		; NO VALID KEY, LOOP
EXAMINEFW:
	INC	HL			; HL++
	JR 	EXAMINELOOP		;
;
;__DODEPOSIT__________________________________________________________________
;
;	PERFORM DEPOSIT FRONT PANEL ACTION
;       PANEL TEMPLATE "8888  88"
;                  POS  01234567
;_____________________________________________________________________________
;
DODEPOSIT:
	CALL 	GETADDR			; GET ADDRESS INTO HL
DEPOSITLOOP:
	LD	DE,DISPLAYBUF+0
	LD	A,H
	CALL	PUTVALUE
	LD	A,L
	CALL	PUTVALUE
	LD	A,$10
	LD	(DE),A
	INC	DE
	LD	(DE),A
	CALL	GETVALUE		;
	LD	(HL),A			;
	LD	DE,DISPLAYBUF+6		; DISPLAY WRITTEN MEM VALUE
	CALL	PUTVALUE		; ... WITHOUT DP'S
	CALL	ENCDISPLAY		; DISPLAY BUFFER CONTENTS
DEPOSITGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	CP	KY_EN			; [EN] PRESSED, INC ADDRESS AND LOOP
	JR	Z,DEPOSITFW		;
	JR	DEPOSITGETKEY		; NO VALID KEY, LOOP
DEPOSITFW:
	INC	HL			;
	JR 	DEPOSITLOOP		;
;
;__GETADDR____________________________________________________________________
;
;	GET ADDRESS FROM FRONT PANEL
;       PANEL TEMPLATE "Adr 8888"
;                  POS  01234567
;_____________________________________________________________________________
;
GETADDR:
	LD	HL,ADDR			; INITIALIZE DISPLAYBUF
	CALL	INITBUF
	JR	GETVALW
;
;__GETVAL16___________________________________________________________________
;
;	GET 16 BIT VALUE FROM FRONT PANEL
;       PANEL TEMPLATE "????8888"
;                  POS  01234567
;_____________________________________________________________________________
;
GETVALW:
	LD	A,$80			;
	LD	(DISPLAYBUF+4),A	;
	LD	(DISPLAYBUF+5),A	;
	LD	(DISPLAYBUF+6),A	;
	LD	(DISPLAYBUF+7),A	;
GETVALW1:
	CALL	ENCDISPLAY		;
GETVALWLOOP:
	CALL	KB_GET			;
	CP	$10			;
	JP	M,GETVALWNUM		; NUMBER PRESSED, STORE IT
	CP	KY_EN			; [EN] PRESSED, DONE
	JR	Z,GETVALWDONE		;
	JR	GETVALWLOOP		; INVALID KEY, LOOP
GETVALWNUM:
	OR	$80			; SET DP
	LD	C,A			;
	LD	A,(DISPLAYBUF+5)	; SHIFT BYTES IN DISPLAY BUF TO THE LEFT
	LD      (DISPLAYBUF+4),A	;
	LD	A,(DISPLAYBUF+6)	;
	LD	(DISPLAYBUF+5),A	;
	LD	A,(DISPLAYBUF+7)	;
	LD	(DISPLAYBUF+6),A	;
	LD	A,C			; DISPLAY KEYSTROKE IN RIGHT MOST DISPLAY (0)
	LD	(DISPLAYBUF+7),A	;
	JR	GETVALW1		;
GETVALWDONE:
	LD	A,(DISPLAYBUF+6)	; GET DIGIT IN DISPLAY 6
	AND	$0F
	SLA	A			; ROTATE IT TO HIGH NIBBLE
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			; STORE IT IN "C"
	LD	A,(DISPLAYBUF+7)	; GET DIGIT IN DISPLAY 7
	AND	$0F
	OR	C			; ADD IN NIBBLE STORED IN C
	LD	L,A			; STORE IT IN LOW BYTE OF ADDRESS POINTER
	LD	A,(DISPLAYBUF+4)	; GET DIGIT IN DISPLAY 4
	AND	$0F
	SLA	A			; ROTATE IT TO HIGH NIBBLE
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			; STORE IT IN "C"
	LD	A,(DISPLAYBUF+5)	; GET DIGIT IN DISPLAY 5
	AND	$0F
	OR	C			; ADD IN NIBBLE STORED IN "C"
	LD	H,A			; STORE BYTE IN HIGH BYTE OF ADDRESS POINTER
	RET
;
;__GETPORT____________________________________________________________________
;
;	GET PORT FROM FRONT PANEL
;       PANEL TEMPLATE "Port  88"
;                  POS  01234567
;_____________________________________________________________________________
;
GETPORT:
	LD	HL,PORT			; INITIALIZE DISPLAYBUF
	CALL	INITBUF
	JR	GETVALUE
;
;__GETVALUE___________________________________________________________________
;
;	GET 8 BIT VALUE FROM FRONT PANEL
;       PANEL TEMPLATE "??????88"
;                  POS  01234567
;_____________________________________________________________________________
;
GETVALUE:
	LD	A,$80			;
	LD	(DISPLAYBUF+6),A	;
	LD	(DISPLAYBUF+7),A	;
GETVALUE1:
	CALL	ENCDISPLAY		;
GETVALUELOOP:
	CALL	KB_GET			;
	CP	$10			;
	JP	M,GETVALUENUM		; NUMBER PRESSED, STORE IT
	CP	KY_EN			; [EN] PRESSED, DONE
	JR	Z,GETVALUEDONE		;
	JR	GETVALUELOOP		; INVALID KEY, LOOP
GETVALUENUM:
	OR	$80			; SET DP
	LD	C,A			;
	LD	A,(DISPLAYBUF+7)	;
	LD	(DISPLAYBUF+6),A	;
	LD	A,C			;
	LD	(DISPLAYBUF+7),A	;
	JR	GETVALUE1		;
GETVALUEDONE:
	LD	A,(DISPLAYBUF+6)	;
	AND	$0F
	RLCA				;
	RLCA				;
	RLCA				;
	RLCA				;
	LD	C,A			;
	LD	A,(DISPLAYBUF+7)	;
	AND	$0F
	OR	C			;
	RET
;
;__PUTVALUE___________________________________________________________________
;
;  INSERT HEX DIGITS OF A INTO AN ENCODED DSKY DISPLAY BUFFER
;  AT POSTION SPECIFIED BY DE.  ON RETURN, DE POINTS TO NEXT
;  POSITION IN DISPLAY BUFFER.
;_____________________________________________________________________________
;
PUTVALUE:
	PUSH	AF			; SAVE INCOMING VALUE
	RLCA				; HIGH NIBBLE -> LOW NIBBLE
	RLCA				; ...
	RLCA				; ...
	RLCA				; ...
	AND	$0F			; ISOLATE LOW NIBBLE
	LD	(DE),A			; PLACE DIGIT VALUE IN BUFFER
	INC	DE			; NEXT BUFFER POSITION
	POP	AF			; RECOVER ORIGINAL VALUE
	AND	$0F			; ISOLATE LOW NIBBLE
	LD	(DE),A			; PLACE DIGIT VALUE IN BUFFER
	INC	DE			; NEXT BUFFER POSITION
	RET				; DONE
;
;__KB_GET_____________________________________________________________________
;
;  GET A SINGLE KEY AND DECODE
;
;_____________________________________________________________________________
;
KB_GET:
	PUSH	BC
	PUSH	DE
	PUSH 	HL			; SAVE HL
	CALL	DSKY_GETKEY		; GET A KEY
	CP	KY_EN			; ENTER?
	JR	Z,KB_GET1		; IF YES, RET TO CALLER
	CP	$10			; HEX DIGIT?
	JR	C,KB_GET1		; IF YES, RET TO CALLER
	; NOT A DIGIT OR [EN], BAIL OUT TO MAIN LOOP TO HANDLE IT
	LD	SP,MON_STACK		; CLEAR STACK
	JP	FRONTPANELLOOP1		; RESTART AT MAIN LOOP
KB_GET1:
	POP	HL			; RESTORE HL
	POP	DE
	POP	BC
	RET
;
;__INITBUF____________________________________________________________________
;
;  INITIALIZE DISPLAY BUFFER FROM VALUE AT ADDRESS IN HL
;_____________________________________________________________________________
;
INITBUF:
	LD	DE,DISPLAYBUF
	LD	BC,8
	LDIR
	RET
;
;__ENCDISPLAY_________________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF DECODED PER SEGDECODE TABLE
;_____________________________________________________________________________
;
ENCDISPLAY:
	PUSH	HL
	LD	HL,DISPLAYBUF
	JR	ENCBUF0
;
;__ENCBUF_____________________________________________________________________
;
;  DISPLAY CONTENTS OF BUFFER AT HL DECODED PER SEGDECODE TABLE
;_____________________________________________________________________________
;
ENCBUF:
	PUSH	HL			; SAVE HL
ENCBUF0:
	PUSH	AF			; SAVE AF
	PUSH	BC			; SAVE BC
	PUSH	DE			; SAVE DE
	LD	DE,DSKY_BUF		; DESTINATION FOR DECODED BYTES
	LD	B,8			; NUMBER OF BYTES TO DECODE
ENCBUF1:
	LD	A,(HL)			; GET SOURCE BYTE
	INC	HL			; BUMP TO NEXT BYTE FOR NEXT PASS
	PUSH	AF			; SAVE IT
	AND	$80			; ISOLATE HI BIT (DP)
	XOR	$80			; FLIP IT
	LD	C,A			; SAVE IN C
	POP	AF			; RECOVER ORIGINAL
	AND	$7F			; REMOVE HI BIT (DP)
	PUSH	HL			; SAVE POINTER
	LD	HL,SEGDECODE		; POINT TO DECODE TABLE
	CALL	ADDHLA			; OFFSET BY INCOMING VALUE
	LD	A,(HL)			; GET DECODED VALUE
	OR	C			; RECOMBINE WITH DP VALUE
	LD	(DE),A			; SAVE IN DEST BUF
	INC	DE			; INC DEST BUF PTR
	POP	HL			; RESTORE POINTER
	DJNZ	ENCBUF1			; LOOP THRU ALL BUF POSITIONS
	LD	HL,DSKY_BUF		; POINT TO DECODED BUFFER
	CALL	DSKY_SHOWSEG		; DISPLAY IT
	POP	DE			; RESTORE DE
	POP	BC			; RESTORE BC
	POP	AF			; RESTORE AF
	POP	HL			; RESTORE HL
	RET
;
CPUUP	.DB 	$84,$CB,$EE,$BB,$80,$BB,$EE,$84	; "-CPU UP-" (RAW SEG)
MSGBOOT	.DB	$FF,$9D,$9D,$8F,$20,$80,$80,$80 ; "Boot!   " (RAW SEG)
ADDR	.DB	$17,$18,$19,$10,$00,$00,$00,$00	; "Adr 0000" (ENCODED)
PORT	.DB	$13,$14,$15,$16,$10,$10,$00,$00	; "Port  00" (ENCODED)
GOTO	.DB	$1A,$14,$10,$10,$00,$00,$00,$00	; "Go  0000" (ENCODED)
;
;_HEX_7_SEG_DECODE_TABLE______________________________________________________
;
; SET BIT 7 TO DISPLAY W/ DECIMAL POINT
;_____________________________________________________________________________
;
SEGDECODE:
	; POS	$00  $01  $02  $03  $04  $05  $06  $07
	; GLYPH '0'  '1'  '2'  '3'  '4'  '5'  '6'  '7'
	.DB	$7B, $30, $6D, $75, $36, $57, $5F, $70
;
	; POS	$08  $09  $0A  $0B  $0C  $0D  $0E  $0F
	; GLYPH	'8'  '9'  'A'  'B'  'C'  'D'  'E'  'F'
	.DB	$7F, $77, $7E, $1F, $4B, $3D, $4F, $4E
;
	; POS	$10  $11  $12  $13  $14  $15  $16  $17  $18  $19  $1A
	; GLYPH	' '  '-'  '.'  'P'  'o'  'r'  't'  'A'  'd'  'r'  'G'
	.DB	$00, $04, $00, $6E, $1D, $0C, $0F, $7E, $3D, $0C, $5B
;
DISPLAYBUF:	.FILL	8,0
;
#ELSE
;
DSKY_ENTRY:
	JP	EXIT
;
#ENDIF
;
;
SLACK		.EQU	(MON_END - $)
		.FILL	SLACK,00H
;
MON_STACK	.EQU	$
;
		.ECHO	"DBGMON space remaining: "
		.ECHO	SLACK
		.ECHO	" bytes.\n"
;
; DBGMON CURRENTLY OCCUPIES $F000-$FDFF BECAUSE THE
; HBIOS PROXY OCCUPIES $FE00-$FFFF.  HOWEVER THE DBGMON
; IMAGE MUST OCCUPY A FULL $1000 BYTES IN THE ROM.
; BELOW WE JUST PAD OUT THE IMAGE BY $200 SO IT
; OCCUPIES THE FULL $1000 BYTES IN ROM.
;
		.FILL	$200,$00
;
		.END
