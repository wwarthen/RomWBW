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
;__UART_ENTRY_________________________________________________________________
;
;	SERIAL MONITOR STARTUP
;_____________________________________________________________________________
;
UART_ENTRY:
	LD	SP,MON_STACK		; SET THE STACK POINTER
	EI				; INTS OK NOW
	CALL	INITIALIZE		; INITIALIZE SYSTEM

	LD	HL,TXT_READY		; POINT AT TEXT
	CALL	MSG			; SHOW WE'RE HERE
;
;__SERIAL_MONITOR_COMMANDS____________________________________________________
;
; B - BOOT SYSTEM
; D XXXX YYYY - DUMP MEMORY FROM XXXX TO YYYY
; F XXXX YYYY ZZ - FILL MEMORY FROM XXXX TO YYYY WITH ZZ
; H - LOAD INTEL HEX FORMAT DATA
; K - ECHO KEYBOARD INPUT
; L XX - INPUT FROM PORT XX AND SHOW HEX DATA
; M XXXX YYYY ZZZZ - MOVE MEMORY BLOCK XXXX TO YYYY TO ZZZZ
; O XX YY - OUTPUT TO PORT XX HEX DATA YY
; P XXXX - PROGRAM RAM STARTING AT XXXXH, WILL PROMPT FOR SUCCESSIVE VALUES
; R XXXX - RUN A PROGRAM FROM LOCATION XXXX
;
;__COMMAND_PARSE______________________________________________________________
;
;	PROMPT USER FOR COMMANDS, THEN PARSE THEM
;_____________________________________________________________________________
;

SERIALCMDLOOP:
	LD	SP,MON_STACK		; RESET STACK
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
	CP	'L'			; IS IT A "L" (Y/N)
	JP	Z,HXLOAD		; INTEL HEX FORMAT LOAD DATA
	CP	'I'			; IS IT AN "I" (Y/N)
	JP	Z,PIN			; PORT INPUT
	CP	'D'			; IS IT A "D" (Y/N)
	JP	Z,DUMPMEM		; DUMP MEMORY
	CP	'K'
	JP	Z,KLOP			; LOOP ON KEYBOARD
	CP	'M'			; IS IT A "M" (Y/N)
	JP	Z,MOVEMEM		; MOVE MEMORY COMMAND
	CP	'F'			; IS IT A "F" (Y/N)
	JP	Z,FILLMEM		; FILL MEMORY COMMAND
	CP	'H'			; IS IT A "H" (Y/N)
	JP	Z,HELP			; HELP COMMAND
	LD	HL,TXT_COMMAND		; POINT AT ERROR TEXT
	CALL	MSG			; PRINT COMMAND LABEL

	JR	SERIALCMDLOOP
;
;__INITIALIZE_________________________________________________________________
;
;	INITIALIZE SYSTEM
;_____________________________________________________________________________
;
INITIALIZE:
;	CALL	CIOCON_DISP + (CF_INIT * 3)
#IF (PLATFORM == PLT_UNA)
	; INSTALL UNA INVOCATION VECTOR FOR RST 08
	LD	A,$C3		; JP INSTRUCTION
	LD	(8),A		; STORE AT 0x0008
	LD	HL,($FFFE)	; UNA ENTRY VECTOR
	LD	(9),HL		; STORE AT 0x0009
#ENDIF
	RET
;
;__BOOT_______________________________________________________________________
;
;	PERFORM BOOT ACTION
;_____________________________________________________________________________
;
BOOT:
#IF (PLATFORM == PLT_UNA)
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,$0000		; ROM BANK 0
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)
	JP	0000H			; JUMP TO RESTART ADDRESS
#ELSE
	LD	A,BID_BOOT		; BOOT BANK
	LD	HL,0			; ADDRESS ZERO
	CALL	HB_BNKCALL		; DOES NOT RETURN
#ENDIF
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
	CALL	CRLF
	POP	HL
	PUSH	HL
	CALL	PHL
	LD	A,':'
	CALL	COUT
	CALL	SPACE
	CALL	COUT
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
	CALL	MSG
	JR	PROGRM1
;
;__KLOP_______________________________________________________________________
;
;	READ FROM THE SERIAL PORT AND ECHO, MONITOR COMMAND "K"
;_____________________________________________________________________________
;
KLOP:
	CALL	CRLF			;
KLOP1:
	CALL	KIN			; GET A KEY
	CP	ESC			; IS <ESC>?
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
;
;__POUT_______________________________________________________________________
;
;	OUTPUT TO AN I/O PORT, MONITOR COMMAND "O"
;	SYNTAX: O <PORT> <VALUE>
;	NOTE: A WORD VALUE IS USED FOR THE PORT NUMBER BECAUSE THE
;             Z80 WILL ACTUALLY PLACE 16 BITS ON THE BUS USING
;             THE B AND C REGISTERS IN AN "OUT (C),A"
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
;             THE B AND C REGISTERS IN AN "INC A,(C)"
;_____________________________________________________________________________
;
PIN:
	CALL	WORDPARM		; GET PORT NUMBER
	JP	C,ERR			; HANDLE ERRORS
	PUSH	DE			; SAVE IT
	CALL	CRLF			;
	POP	BC			; RESTORE TO BC
	IN	A,(C)			; GET PORT VALUE
	CALL	HXOUT			; PRINT HEX VALUE
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
	CALL	CRLF			;	
BLKRD:
	CALL	PHL			; PRINT START LOCATION
	LD	A,':'
	CALL	COUT
	CALL	SPACE
	CALL	COUT
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
	CALL	MSG			; DISPLAY IT
	JP	SERIALCMDLOOP		; AND BACK TO COMMAND LOOP
;
;__ERR________________________________________________________________________
;
;	SYNTAX ERROR
;_____________________________________________________________________________
;
ERR:
	LD	HL,TXT_ERR		; POINT AT ERROR TEXT
	CALL	MSG			; DISPLAY IT
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
	JP	NZ,BYTEPARM1		; IF NOT, ERR
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
	JP	NZ,WORDPARM1		; IF NOT, ERR
	JP	HEXWORD			; RETURN VIA HEXWORD
WORDPARM1:
	SCF				; SIGNAL ERROR
	RET				; RETURN
;
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
	CP	CR			; IS <CR>?
	JR	Z,GETLNDONE		; YES, EXIT 
	CALL	COUT			; OUTPUT KEY TO SCREEN
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
	JR	NC,ALPH			;
	AND	0FH			; GET THE BITS
	RET				;
ALPH:
	AND	0FH			; GET THE BITS
	ADD	A,09H			; MAKE IT HEX A-F
	RET				;
;
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
;
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
	RET				; DONE  
;
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
;
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
;
;__MSG________________________________________________________________________
;
;	PRINT A STRING  TO THE SERIAL PORT
;_____________________________________________________________________________
;
MSG:
	LD	A,(HL)			; GET CHARACTER TO A
	OR	A			; SET FLAGS
	RET	Z			; DONE IF NULL
	CALL	COUT			; PRINT CHARACTER
	INC	HL			; INC POINTER, TO NEXT CHAR
	JR	MSG			; LOOP
;
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
;
#ENDIF
;
;__WORK_AREA__________________________________________________________________
;
;	RESERVED RAM FOR MONITOR WORKING AREA
;_____________________________________________________________________________
;
KEYBUF:  	.FILL	80,' '
;
;__TEXT_STRINGS_______________________________________________________________
;
;	SYSTEM TEXT STRINGS
;_____________________________________________________________________________
;
TCRLF:
	.DB  	CR,LF,0

PROMPT:
	.DB  	CR,LF,'>',0

TXT_READY:
	.DB	CR,LF
	.TEXT   "MONITOR READY ('H' FOR HELP)"
	.DB	0

TXT_COMMAND:
	.DB	CR,LF
	.TEXT   "UNKNOWN COMMAND ('H' FOR HELP)"
	.DB	0

TXT_ERR:
	.DB	CR,LF
	.TEXT	"SYNTAX ERROR ('H' FOR HELP)"
	.DB	0

TXT_CKSUMERR:
	.DB	CR,LF
	.TEXT   "CHECKSUM ERROR"
	.DB	0

TXT_BADNUM:
	.TEXT	"  *INVALID VALUE*"
	.DB	0

TXT_HELP:
	.DB	CR,LF
	.TEXT	"MONITOR COMMANDS (ALL VALUES IN HEX):\r\n"
	.TEXT	"B                - BOOT SYSTEM\r\n"
	.TEXT	"D XXXX YYYY      - DUMP MEMORY FROM XXXX TO YYYY\r\n"
	.TEXT	"F XXXX YYYY ZZ   - FILL MEMORY FROM XXXX TO YYYY WITH ZZ\r\n"
	.TEXT	"I XX             - SHOW VALUE FROM PORT XX\r\n"
	.TEXT	"K                - ECHO KEYBOARD INPUT\r\n"
	.TEXT	"L                - LOAD INTEL HEX FORMAT DATA\r\n"
	.TEXT	"M XXXX YYYY ZZZZ - MOVE MEMORY BLOCK XXXX-YYYY TO ZZZZ\r\n"
	.TEXT	"O XX YY          - WRITE VALUE YY TO PORT XX\r\n"
	.TEXT	"P XXXX           - PROGRAM RAM STARTING AT XXXX\r\n"
	.TEXT	"R XXXX           - RUN A PROGRAM AT ADDRESS XXXX"
	.DB	0
;
#IF DSKYENABLE
;
#DEFINE DSKY_KBD
#INCLUDE "dsky.asm"
;
;
;__DSKY_ENTRY_________________________________________________________________
;
;	DSKY FRONT PANEL STARTUP
;_____________________________________________________________________________
;
DSKY_ENTRY:
	LD	SP,MON_STACK		; SET THE STACK POINTER
	EI				; INTS OK NOW
	CALL	INITIALIZE		; INITIALIZE SYSTEM
;
;__FRONT_PANEL_STARTUP________________________________________________________
;
;	START UP THE SYSTEM WITH THE FRONT PANEL INTERFACE	
;_____________________________________________________________________________
;
	CALL    MTERM_INIT		; INIT 8255 FOR MTERM
	LD	HL,CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
;
;__COMMAND_PARSE______________________________________________________________
;
;	PROMPT USER FOR COMMANDS, THEN PARSE THEM
;_____________________________________________________________________________
;
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
;
;__DOBOOT_____________________________________________________________________
;
;	PERFORM BOOT FRONT PANEL ACTION
;_____________________________________________________________________________
;
DOBOOT:
	JP	BOOT
;
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
	LD	(DISPLAYBUF+2),A	; SHOW HIGH NIB IN DISP 5
	LD	A,C			; RESTORE PORT VALUE INTO "A"
	AND	0FH			; CLEAR HIGH NIB, LEAVING LOW
	LD	(DISPLAYBUF+3),A	; SHOW LOW NIB IN DISP 4
	IN 	A,(C)			; GET PORT VALUE FROM PORT IN "C"
	LD	C,A			; STORE VALUE IN "C"
	SRL	A			; ROTATE HIGH NIB TO LOW
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+6),A	; SHOW HIGH NIB IN DISP 1
	LD	A,C			; RESTORE VALUE TO "A"
	AND	0FH			; CLEAR HIGH NIB, LEAVING LOW
	LD	(DISPLAYBUF+7),A	; DISPLAY LOW NIB IN DISP 0
	LD	A,10H			; CLEAR OTHER DISPLAYS
	LD	(DISPLAYBUF+5),A	;
	LD	(DISPLAYBUF+4),A	;
	LD	A,13H			; "P"
	LD	(DISPLAYBUF+0),A	; STORE IN DISP 7
	LD	A,14H			; "O"
	LD	(DISPLAYBUF+1),A	; STORE IN DISP 6
	LD	HL,DISPLAYBUF		; SET POINTER TO DISPLAY BUFFER
	CALL	ENCDISPLAY		; DISPLAY BUFFER CONTENTS
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
;
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
	LD	(DISPLAYBUF+2),A	; DISPLAY HIGH NIB IN DISPLAY 5
	LD	A,C			; RESTORE PORT VALUE INTO "A"
	AND	0FH			; CLEAR OUT HIGH NIB
	LD	(DISPLAYBUF+3),A	; DISPLAY LOW NIB IN DISPLAY 4
	LD	A,10H			; CLEAR OUT DISPLAYS 2 AND 3
	LD	(DISPLAYBUF+5),A	;
	LD	(DISPLAYBUF+4),A	;
	LD	A,13H			; DISPLAY "P" IN DISP 7
	LD	(DISPLAYBUF+0),A	;
	LD	A,14H			; DISPLAY "O" IN DISP 6
	LD	(DISPLAYBUF+1),A	;
	LD	HL,DISPLAYBUF		; POINT TO DISPLAY BUFFER
	CALL	GETVALUE		; INPUT A BYTE VALUE, RETURN IN "A"
	OUT	(C),A			; OUTPUT VALUE TO PORT STORED IN "C"
	LD	HL,CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
	JP	FRONTPANELLOOP		;
;
;__DOGO_______________________________________________________________________
;
;	PERFORM GO FRONT PANEL ACTION
;_____________________________________________________________________________
;
DOGO:
	CALL 	GETADDR			; GET ADDRESS INTO HL
	JP	(HL)			; GO THERE!
;
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
	LD	(DISPLAYBUF+0),A	;
	LD	A,H			;
	AND	0FH			;
	LD	(DISPLAYBUF+1),A	;
	LD	A,L			;
	SRL	A			;
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+2),A	;
	LD	A,L			;
	AND	0FH			;
	LD	(DISPLAYBUF+3),A	;
	LD	A,10H			;
	LD	(DISPLAYBUF+4),A	;
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
;
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
	LD	(DISPLAYBUF+0),A	;
	LD	A,H			; RESTORE HIGH BYTE
	AND	0FH			; CLEAR HIGH NIBBLE
	LD	(DISPLAYBUF+1),A	; DISPLAY LOW NIBBLE IN DISP 6
	LD	A,L			; PUT LOW BYTE IN "A"
	SRL	A			; SHOW HIGH NIBBLE IN DISP 5
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+2),A	;
	LD	A,L			; RESTORE LOW BYTE IN "A"
	AND	0FH			; CLEAR OUT HIGH NIBBLE
	LD	(DISPLAYBUF+3),A	; DISPLAY LOW NIBBLE IN DISP 4
	LD	A,10H			; CLEAR OUT DISP 3
	LD	(DISPLAYBUF+4),A	;
	LD	A,(HL)			; GET VALUE FROM ADDRESS IN HL
	SRL	A			; DISPLAY HIGH NIB IN DISPLAY 1
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+6),A	;
	LD	A,(HL)			; GET VALUE FROM ADDRESS IN HL
	AND	0FH			; CLEAR OUT HIGH NIBBLE
	LD	(DISPLAYBUF+7),A	; DISPLAY LOW NIBBLE IN DISPLAY 0
	LD	HL,DISPLAYBUF		; POINT TO DISPLAY BUFFER
	CALL	ENCDISPLAY		; DISPLAY BUFFER ON DISPLAYS
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
;
;__GETADDR____________________________________________________________________
;
;	GET ADDRESS FROM FRONT PANEL
;_____________________________________________________________________________
;
GETADDR:
	PUSH	BC			; STORE BC
GETADDR0:
	LD	HL,ADDR			; INITIALIZE DISPLAYBUF
	LD	DE,DISPLAYBUF
	LD	BC,8
	LDIR
GETADDR1:
	LD	HL,DISPLAYBUF		; DISPLAY PROMPT
	CALL	ENCDISPLAY		; 
GETADDRLOOP:
	CALL	KB_GET			;	
	CP	10H			;
	JP	M,GETADDRNUM		; NUMBER PRESSED, STORE IT
	CP	13H			; EN PRESSED, DONE
	JR	Z,GETADDRDONE		;
	CP	12H			; CLEAR PRESSED, CLEAR
	JR	Z,GETADDR0		; 
	JR	GETADDRLOOP		; INVALID KEY, LOOP
GETADDRDONE:
	LD	HL,00H			; HL=0
	LD	A,(DISPLAYBUF+6)	; GET DIGIT IN DISPLAY 1
	SLA	A			; ROTATE IT TO HIGH NIBBLE
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			; STORE IT IN "C"	
	LD	A,(DISPLAYBUF+7)	; GET DIGIT IN DISPLAY 0
	AND	0FH			; CLEAR HIGH NIBBLE
	OR	C			; ADD IN NIBBLE STORED IN C
	LD	L,A			; STORE IT IN LOW BYTE OF ADDRESS POINTER
	LD	A,(DISPLAYBUF+4)	; GET DIGIT IN DISPLAY 3
	SLA	A			; ROTATE IT TO HIGH NIBBLE
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			; STORE IT IN "C"	
	LD	A,(DISPLAYBUF+5)	; GET DIGIT IN DISPLAY 2
	AND	0FH			; CLEAR HIGH NIBBLE
	OR	C			; ADD IN NIBBLE STORED IN "C"
	LD	H,A			; STORE BYTE IN HIGH BYTE OF ADDRESS POINTER
	LD	A,10H			; CLEAR OUT DISPLAYS 0,1,2 & 3
	LD	(DISPLAYBUF+7),A	;
	LD	(DISPLAYBUF+6),A	;
	LD	(DISPLAYBUF+5),A	;
	LD	(DISPLAYBUF+4),A	;	
	POP	BC			; RESTORE BC	
	RET
GETADDRNUM:
	LD	C,A			;
	LD	A,(DISPLAYBUF+5)	; SHIFT BYTES IN DISPLAY BUF TO THE LEFT
	LD      (DISPLAYBUF+4),A	;
	LD	A,(DISPLAYBUF+6)	;	
	LD	(DISPLAYBUF+5),A	;
	LD	A,(DISPLAYBUF+7)	;	
	LD	(DISPLAYBUF+6),A	;
	LD	A,C			; DISPLAY KEYSTROKE IN RIGHT MOST DISPLAY (0)
	LD	(DISPLAYBUF+7),A	;
	JR	GETADDR1		;
;
;__GETPORT____________________________________________________________________
;
;	GET PORT FROM FRONT PANEL
;_____________________________________________________________________________
;
GETPORT:
	PUSH	BC			; STORE BC
GETPORT0:
	LD	HL,PORT			; INITIALIZE DISPLAYBUF
	LD	DE,DISPLAYBUF
	LD	BC,8
	LDIR
GETPORT1:
	LD	HL,DISPLAYBUF		; DISPLAY PROMPT
	CALL	ENCDISPLAY		;
GETPORTLOOP:
	CALL	KB_GET			;	
	CP	10H			;
	JP	M,GETPORTNUM		; NUMBER PRESSED, STORE IT
	CP	13H			; EN PRESSED, DONE
	JR	Z,GETPORTDONE		;
	CP	12H			; CLEAR PRESSED, CLEAR
	JR	Z,GETPORT0
	JR	GETPORTLOOP		; INVALID KEY, LOOP
GETPORTDONE:
	LD	A,(DISPLAYBUF+6)	;
	SLA	A			;
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			;	
	LD	A,(DISPLAYBUF+7)	;
	AND	0FH			;
	OR	C			;
	LD	C,A			;
	LD	A,10H			;
	LD	(DISPLAYBUF+7),A	;
	LD	(DISPLAYBUF+6),A	;
	LD	A,C			;
	POP	BC			; RESTORE BC	
	RET
GETPORTNUM:
	LD	C,A			;
	LD	A,(DISPLAYBUF+7)	;	
	LD	(DISPLAYBUF+6),A	;
	LD	A,C			;
	LD	(DISPLAYBUF+7),A	;
	JR	GETPORT1		;
;
;__GETVALUE___________________________________________________________________
;
;	GET VALUE FROM FRONT PANEL
;_____________________________________________________________________________
;
GETVALUE:
	PUSH	BC			; STORE BC
	JR	GETVALUECLEAR		;
GETVALUE1:
	CALL	ENCDISPLAY		; 
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
	LD	A,(DISPLAYBUF+6)	;
	SLA	A			;
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			;	
	LD	A,(DISPLAYBUF+7)	;
	AND	0FH			;
	OR	C			;
        LD	C,A			;
	LD	A,10H			;
	LD	(DISPLAYBUF+7),A	;
	LD	(DISPLAYBUF+6),A	;
	LD	A,C			;
	POP	BC			; RESTORE BC		
	RET
GETVALUENUM:
	LD	C,A			;
	LD	A,(DISPLAYBUF+7)	;	
	LD	(DISPLAYBUF+6),A	;
	LD	A,C			;
	LD	(DISPLAYBUF+7),A	;
	JR	GETVALUE1		;
GETVALUECLEAR:
	LD	A,12H			;
	LD	(DISPLAYBUF+7),A	;
	LD	(DISPLAYBUF+6),A	;
	JP	GETVALUE1		;
;
;__MTERM_INIT_________________________________________________________________
;
;  SETUP 8255, MODE 0, PORT A=OUT, PORT B=IN, PORT C=OUT/OUT
;_____________________________________________________________________________
;
MTERM_INIT:
	LD	A, 82H
	OUT	(PPIX),A
	LD	A, 30H			;set PC4,5 to disable PPISD (if used)
	OUT	(PPIC),A		;won't affect DSKY
	RET
;
;__KB_GET_____________________________________________________________________
;
;  GET A SINGLE KEY AND DECODE
;     
;_____________________________________________________________________________
;
KB_GET:
	PUSH 	HL			; SAVE HL
	CALL	KY_GET			; GET A KEY
	POP	HL			; RESTORE HL
	RET
;
;__ENCDISPLAY_________________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF DECODED PER SEGDECODE TABLE
;_____________________________________________________________________________
;
ENCDISPLAY:
	PUSH	HL			; SAVE HL
	PUSH	AF			; SAVE AF
	PUSH	BC			; SAVE BC
	PUSH	DE			; SAVE DE
	LD	DE,DECODEBUF		; DESTINATION FOR DECODED BYTES
	LD	B,8			; NUMBER OF BYTES TO DECODE
ENCDISPLAY1:
	LD	A,(HL)			; GET SOURCE BYTE
	INC	HL			; BUMP TO NEXT BYTE FOR NEXT PASS
	PUSH	HL			; SAVE POINTER
	LD	HL,SEGDECODE
	CALL	ADDHLA
	LD	A,(HL)			; GET DECODED VALUE
	LD	(DE),A			; SAVE IN DEST BUF
	INC	DE			; INC DEST BUF PTR
	POP	HL			; RESTORE POINTER
	DJNZ	ENCDISPLAY1		; LOOP THRU ALL BUF POSITIONS
	LD	HL,DECODEBUF		; POINT TO DECODED BUFFER
	CALL	SEGDISPLAY		; DISPLAY IT
	POP	DE			; RESTORE DE
	POP	BC			; RESTORE BC
	POP	AF			; RESTORE AF
	POP	HL			; RESTORE HL
	RET
;
;__SEGDISPLAY_________________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF IN DECODED HEX BITS 0-3 ARE DISPLAYED DIG, BIT 7 IS DP
;     
;_____________________________________________________________________________
;
SEGDISPLAY:
	PUSH	AF
	PUSH	BC
	CALL	DSKY_SHOWRAW
	POP	BC
	POP	AF
	RET
;
CPUUP	.DB 	$84,$CB,$EE,$BB,$80,$BB,$EE,$84	; "-CPU UP-" (RAW)
ADDR	.DB	$17,$18,$19,$10,$00,$00,$00,$00	; "Adr 0000" (ENCODED)
PORT	.DB	$13,$14,$15,$16,$10,$10,$00,$00	; "Port  00" (ENCODED)

;_KB DECODE TABLE_____________________________________________________________
;
KB_DECODE:
;               0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	.DB	$41,$02,$42,$82,$04,$44,$84,$08,$48,$88,$10,$50,$90,$20,$60,$A0
;               FW  BK  CL  EN  DP  EX  GO  BO
	.DB	$01,$81,$C1,$C2,$C4,$C8,$D0,$E0
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
;
;_HEX 7_SEG_DECODE_TABLE______________________________________________________
; 
; 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F, ,-,.,P,o
; AND WITH 7FH TO TURN ON DP 
;_____________________________________________________________________________
SEGDECODE:
	;	0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	.DB	$FB,$B0,$ED,$F5,$B6,$D7,$DF,$F0,$FF,$F7,$FE,$9F,$CB,$BD,$CF,$CE
	;	    -   .   P   o   r   t   A   d   r
	.DB	$80,$84,$00,$EE,$9D,$8C,$94,$FE,$BD,$8C

;
DISPLAYBUF:	.FILL	8,0
DECODEBUF:	.FILL	8,0
;
#ELSE
;
DSKY_ENTRY:
	CALL	PANIC
;
#ENDIF

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
