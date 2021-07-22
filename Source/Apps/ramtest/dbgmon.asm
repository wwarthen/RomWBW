;___RAM_TEST_PROGRAM_____________________________________________________________________________________________________________
;
;  ORIGINAL CODE BY:	ANDREW LYNCH (LYNCHAJ@YAHOO COM)	17 JUL 2021
;
;  HELP FROM WAYNE WARTHEN
;
;__REFERENCES________________________________________________________________________________________________________________________ 
; THOMAS SCHERRER BASIC HARDWARE TEST ASSEMBLER SOURCES FROM THE Z80 INFO PAGE
; INCLUDING ORIGINAL SCHEMATIC CONCEPT
; HTTP://Z80 INFO/Z80SOURC.TXT
; CODE SAMPLES FROM BRUCE JONES PUBLIC DOMAIN ROM MONITOR FOR THE SBC-200C 
; HTTP://WWW RETROTECHNOLOGY.COM/HERBS_STUFF/SD_BRUCE_CODE.ZIP
; INSPIRATION FROM JOEL OWENS "Z-80 SPACE-TIME PRODUCTIONS SINGLE BOARD COMPUTER"
; HTTP://WWW JOELOWENSORG/Z80/Z80INDEX.HTML
; GREAT HELP AND TECHNICAL ADVICE FROM ALLISON AT ALPACA_DESIGNERS
; HTTP://GROUPS YAHOO.COM/GROUP/ALPACA_DESIGNERS
; INTEL SDK-85 ROM DEBUG MONITOR
;
;__HARDWARE_INTERFACES________________________________________________________________________________________________________________ 
;
; PIO 82C55 I/O IS DECODED TO PORT 60-67
;
PORTA:		 .EQU 	60H
PORTB:		 .EQU 	61H
PORTC:		 .EQU 	62H
PIOCONT: 	 .EQU 	63H
;
; UART 16C450 SERIAL IS DECODED TO 68-6F
;
UART0:		 .EQU	68H		;   DATA IN/OUT
UART1:		 .EQU	69H		;   CHECK RX
UART2:		 .EQU	6AH		;   INTERRUPTS
UART3:		 .EQU	6BH		;   LINE CONTROL
UART4:		 .EQU	6CH		;   MODEM CONTROL
UART5:		 .EQU	6DH		;   LINE STATUS
UART6:		 .EQU	6EH		;   MODEM STATUS
UART7:		 .EQU	6FH		;   SCRATCH REG.
;
; MEMORY PAGE CONFIGURATION LATCH IS DECODED TO 7CH
;
MPCL_ROM:		 .EQU	7CH		; CONTROL PORT, SHOULD ONLY BE CHANGED WHILE
;					  IN UPPER MEMORY PAGE 08000h-$FFFF OR LIKELY
;					  LOSS OF CPU MEMORY CONTEXT 
;
; ROM MEMORY PAGE CONFIGURATION LATCH CONTROL PORT ( IO_Y3 ) INFORMATION
;
;	7 6 5 4  3 2 1 0      ONLY APPLICABLE TO THE LOWER MEMORY PAGE 00000h-$7FFF
;	^ ^ ^ ^  ^ ^ ^ ^
;	: : : :  : : : :--0 = A15 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  : : :----0 = A16 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  : :------0 = A17 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  :--------0 = A18 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :-----------0 = A19 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: : :-------------0 = A20 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: :---------------0 = ROM BOOT OVERRIDE DEFAULT IS 0 
;	:-----------------0 = LOWER PAGE ROM SELECT (0=ROM, 1=NOTHING) DEFAULT IS 0
;
; MEMORY PAGE CONFIGURATION LATCH IS DECODED TO 78H
;
MPCL_RAM:		 .EQU	78H		; CONTROL PORT, SHOULD ONLY BE CHANGED WHILE
;					  IN UPPER MEMORY PAGE 08000h-$FFFF OR LIKELY
;					  LOSS OF CPU MEMORY CONTEXT 
;
; MEMORY PAGE CONFIGURATION LATCH CONTROL PORT ( IO_Y1 ) INFORMATION
;
;	7 6 5 4  3 2 1 0      ONLY APPLICABLE TO THE LOWER MEMORY PAGE 00000h-$7FFF
;	^ ^ ^ ^  ^ ^ ^ ^
;	: : : :  : : : :--0 = A15 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  : : :----0 = A16 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  : :------0 = A17 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  :--------0 = A18 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :-----------0 = A19 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : :-------------0 = UNDEFINED DEFAULT IS 0
;	: :---------------0 = RAM BOOT OVERRIDE DEFAULT IS 0
;	:-----------------0 = LOWER PAGE RAM SELECT (0=NOTHING, 1=RAM) DEFAULT IS 0;
;
;;
;
;__CONSTANTS_________________________________________________________________________________________________________________________ 
;	
RAMTOP:		 .EQU	0FFFFh		; HIGHEST ADDRESSABLE MEMORY LOCATION
STACKSTART:	 .EQU	0CFFFh		; START OF STACK
RAMBOTTOM:	 .EQU	08000h		; START OF FIXED UPPER 32K PAGE OF 512KB X 8 RAM 8000H-FFFFH
MONSTARTCOLD:	 .EQU	08000h		; COLD START MONITOR IN HIGH RAM
ENDT:		 .EQU	0FFh		; MARK END OF TEXT
CR:		 .EQU	0DH		; ASCII CARRIAGE RETURN CHARACTER
LF:		 .EQU	0AH		; ASCII LINE FEED CHARACTER
ESC:		 .EQU	1BH		; ASCII ESCAPE CHARACTER
BS:		 .EQU	08H		; ASCII BACKSPACE CHARACTER
;



;
;
;__MAIN_PROGRAM_____________________________________________________________________________________________________________________ 
;
	 .ORG	8000H			; NORMAL OP




;__MONSTARTWARM___________________________________________________________________________________________________________________ 
;
;	SERIAL MONITOR STARTUP
;________________________________________________________________________________________________________________________________
;

MONSTARTWARM:				; CALL HERE FOR SERIAL MONITOR WARM START
	LD	SP,STACKSTART		; SET THE STACK POINTER TO STACKSTART
	CALL	INITIALIZE		; INITIALIZE SYSTEM

	XOR	A			;ZERO OUT ACCUMULATOR (ADDED)
	PUSH	HL			;PROTECT HL FROM OVERWRITE     
	LD	HL,TXT_READY		;POINT AT TEXT
	CALL	MSG			;SHOW WE'RE HERE
	POP	HL			;PROTECT HL FROM OVERWRITE

;
;__SERIAL_MONITOR_COMMANDS_________________________________________________________________________________________________________ 
;
; A RAM TEST LOWER 32KB RAM PAGE
; B XX BOOT CPM FROM DRIVE XX
; D XXXXH YYYYH  DUMP MEMORY FROM XXXX TO YYYY
; F XXXXH YYYYH ZZH FILL MEMORY FROM XXXX TO YYYY WITH ZZ
; H LOAD INTEL HEX FORMAT DATA
; I INPUT FROM PORT AND SHOW HEX DATA
; K ECHO KEYBOARD INPUT
; M XXXXH YYYYH ZZZZH MOVE MEMORY BLOCK XXXX TO YYYY TO ZZZZ
; O OUTPUT TO PORT HEX DATA
; P XXXXH YYH PROGRAM RAM FROM XXXXH WITH VALUE IN YYH, WILL PROMPT FOR NEXT LINES FOLLOWING UNTIL CR
; R RUN A PROGRAM FROM CURRENT LOCATION



;__COMMAND_PARSE_________________________________________________________________________________________________________________ 
;
;	PROMPT USER FOR COMMANDS, THEN PARSE THEM
;________________________________________________________________________________________________________________________________
;

SERIALCMDLOOP:
	LD	HL,TXT_MAIN_MENU	; POINT AT MAIN MENU TEXT
	CALL	MSG			; PRINT COMMAND LABEL
	CALL	CRLFA			; CR,LF,>
	LD	HL,KEYBUF		; SET POINTER TO KEYBUF AREA
	CALL 	GETLN			; GET A LINE OF INPUT FROM THE USER
	LD	HL,KEYBUF		; RESET POINTER TO START OF KEYBUF
        LD      A,(HL)			; LOAD FIRST CHAR INTO A (THIS SHOULD BE THE COMMAND)
	INC	HL			; INC POINTER

	CP	'A'			; IS IT "A" (Y/N)
	JP	Z,DORAMTEST		; IF YES DO RAM TEST
	CP	'B'			; IS IT "B" (Y/N)
	JP	Z,DOBOOT		; IF YES DO BOOT
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
	JP	Z,FILL			; FILL MEMORY COMMAND
	LD	HL,TXT_COMMAND		; POINT AT ERROR TEXT
	CALL	MSG			; PRINT COMMAND LABEL

	JR	SERIALCMDLOOP





;__KLOP__________________________________________________________________________________________________________________________ 
;
;	READ FROM THE SERIAL PORT AND ECHO, MONITOR COMMAND "K"
;________________________________________________________________________________________________________________________________
;
KLOP:
	CALL	KIN			; GET A KEY
	CALL	COUT			; OUTPUT KEY TO SCREEN
	CP	ESC			; IS <ESC>?
	JR	NZ,KLOP			; NO, LOOP
	JP	SERIALCMDLOOP		;

;__GETLN_________________________________________________________________________________________________________________________ 
;
;	READ A LINE(80) OF TEXT FROM THE SERIAL PORT, HANDLE <BS>, TERM ON <CR> 
;       EXIT IF TOO MANY CHARS    STORE RESULT IN HL.  CHAR COUNT IN C.
;________________________________________________________________________________________________________________________________
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


;__KIN___________________________________________________________________________________________________________________________ 
;
;	READ FROM THE SERIAL PORT AND ECHO & CONVERT INPUT TO UCASE
;________________________________________________________________________________________________________________________________
;
KIN:
	IN	A,(UART5)		; READ LINE STATUS REGISTER
	BIT	0,A			; TEST IF DATA IN RECEIVE BUFFER
	JP	Z,KIN			; LOOP UNTIL DATA IS READY
	IN	A,(UART0)		; THEN READ THE CHAR FROM THE UART
	AND	7FH			; STRIP HI BIT
	CP	'A'			; KEEP NUMBERS, CONTROLS
	RET	C			; AND UPPER CASE
	CP	7BH			; SEE IF NOT LOWER CASE
	RET	NC			; 
	AND	5FH			; MAKE UPPER CASE
	RET


;__COUT__________________________________________________________________________________________________________________________ 
;
;	WRITE THE VALUE IN "A" TO THE SERIAL PORT
;________________________________________________________________________________________________________________________________
;
COUT:
	PUSH   AF			; STORE AF
TX_BUSYLP:
	IN	A,(UART5)		; READ LINE STATUS REGISTER
	BIT	5,A			; TEST IF UART IS READY TO SEND
	JP	Z,TX_BUSYLP		; IF NOT REPEAT
	POP	AF			; RESTORE AF
	OUT	(UART0),A		; THEN WRITE THE CHAR TO UART
	RET				; DONE


;__CRLF__________________________________________________________________________________________________________________________ 
;
;	SEND CR & LF TO THE SERIAL PORT
;________________________________________________________________________________________________________________________________
;
CRLF:
	PUSH	HL			; PROTECT HL FROM OVERWRITE
	LD	HL,TCRLF		; LOAD MESSAGE POINTER
	CALL	MSG			; SEBD MESSAGE TO SERIAL PORT
	POP	HL			; PROTECT HL FROM OVERWRITE
	RET				;


;__LDHL__________________________________________________________________________________________________________________________ 
;
;	GET ONE WORD OF HEX DATA FROM BUFFER POINTED TO BY HL SERIAL PORT, RETURN IN HL
;________________________________________________________________________________________________________________________________
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


;__HEXIN__________________________________________________________________________________________________________________________ 
;
;	GET ONE BYTE OF HEX DATA FROM BUFFER IN HL, RETURN IN A
;________________________________________________________________________________________________________________________________
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


;__HEXINS_________________________________________________________________________________________________________________________ 
;
;	GET ONE BYTE OF HEX DATA FROM SERIAL PORT, RETURN IN A
;________________________________________________________________________________________________________________________________
;
HEXINS:
	PUSH	BC			;SAVE BC REGS 
	PUSH	HL			;SAVE HL REGS
	CALL	NIBLS			;DO A NIBBLE
	RLC	A			;MOVE FIRST BYTE UPPER NIBBLE  
	RLC	A			; 
	RLC	A			; 
	RLC	A			; 
	LD	B,A			; SAVE ROTATED BYTE
	CALL	NIBLS			; DO NEXT NIBBLE
	ADD	A,B			; COMBINE NIBBLES IN ACC 
	POP	HL			; RESTORE HL
	POP	BC			; RESTORE BC
	RET				; DONE  
NIBLS:
	CALL	KIN			; GET K B. DATA
	INC	HL			; INC KB POINTER
	CP	40H			; TEST FOR ALPHA
	JR	NC,ALPH			;
	AND	0FH			; GET THE BITS
	RET				;


;__HXOUT_________________________________________________________________________________________________________________________ 
;
;	PRINT THE ACCUMULATOR CONTENTS AS HEX DATA ON THE SERIAL PORT
;________________________________________________________________________________________________________________________________
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


;__SPACE_________________________________________________________________________________________________________________________ 
;
;	PRINT A SPACE CHARACTER ON THE SERIAL PORT
;________________________________________________________________________________________________________________________________
;
SPACE:
	PUSH	AF			; STORE AF
	LD	A,20H			; LOAD A "SPACE"
	CALL	COUT			; SCREEN IT
	POP	AF			; RESTORE AF
	RET				; DONE

;__PHL_________________________________________________________________________________________________________________________ 
;
;	PRINT THE HL REG ON THE SERIAL PORT
;________________________________________________________________________________________________________________________________
;
PHL:
	LD	A,H			; GET HI BYTE
	CALL	HXOUT			; DO HEX OUT ROUTINE
	LD	A,L			; GET LOW BYTE
	CALL	HXOUT			; HEX IT
	CALL	SPACE			; 
	RET				; DONE  

;__POUT__________________________________________________________________________________________________________________________ 
;
;	OUTPUT TO AN I/O PORT, MONITOR COMMAND "O"
;________________________________________________________________________________________________________________________________
;
POUT:
POUT1:
	INC	HL			;
	CALL	HEXIN			; GET PORT
	LD	C,A			; SAVE PORT POINTER
	INC	HL			;
	CALL	HEXIN			; GET DATA
OUTIT:
	OUT	(C),A			;
	JP	SERIALCMDLOOP		;


;__PIN___________________________________________________________________________________________________________________________ 
;
;	INPUT FROM AN I/O PORT, MONITOR COMMAND "I"
;________________________________________________________________________________________________________________________________
;
PIN:
	INC 	HL			;
	CALL	HEXIN			; GET PORT
	LD	C,A			; SAVE PORT POINTER
	CALL	CRLF			;
	IN	A,(C)			; GET DATA
	CALL	HXOUT			; SHOW IT
	JP	SERIALCMDLOOP	        ;





;__CRLFA_________________________________________________________________________________________________________________________ 
;
;	PRINT COMMAND PROMPT TO THE SERIAL PORT
;________________________________________________________________________________________________________________________________
;
CRLFA:
	PUSH	HL			; PROTECT HL FROM OVERWRITE
	LD	HL,PROMPT		;
	CALL	MSG			;
	POP	HL			; PROTECT HL FROM OVERWRITE
	RET				; DONE


;__MSG___________________________________________________________________________________________________________________________ 
;
;	PRINT A STRING  TO THE SERIAL PORT
;________________________________________________________________________________________________________________________________
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

;__RUN___________________________________________________________________________________________________________________________ 
;
;	TRANSFER OUT OF MONITOR, USER OPTION "R"
;________________________________________________________________________________________________________________________________
;
RUN:
	INC	HL			; SHOW READY
	CALL	LDHL			; GET START ADDRESS
	JP	(HL)			;	


;__PROGRM________________________________________________________________________________________________________________________ 
;
;	PROGRAM RAM LOCATIONS, USER OPTION "P"
;________________________________________________________________________________________________________________________________
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







;__DUMP__________________________________________________________________________________________________________________________ 
;
;	PRINT A MEMORY DUMP, USER OPTION "D"
;________________________________________________________________________________________________________________________________
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


;__HXLOAD__________________________________________________________________________________________________________________________ 
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
;________________________________________________________________________________________________________________________________
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
	SUB	C			; THE CHECKSUM SHOULD ALWAYS EQUAL ZERO WHEN CHECKED
	LD	E,A			; SAVE THE CHECKSUM BACK WHERE IT CAME FROM
	LD	A,C			; RETRIEVE THE BYTE AND GO BACK
	RET				; BACK TO CALLER
HXLOADAGAIN:
	CALL	KIN			; CATCH THE TRAILING CARRIAGE RETURN
	JP	HXLOAD0			; LOAD ANOTHER LINE OF DATA
HXLOADEXIT:
	CALL	KIN			; CATCH ANY STRAY TRAILING CHARACTERS
	JP	SERIALCMDLOOP		; RETURN TO PROMPT


;__MOVE__________________________________________________________________________________________________________________________ 
;
;	MOVE MEMORY, USER OPTION "M"
;________________________________________________________________________________________________________________________________
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
               
;__FILL__________________________________________________________________________________________________________________________ 
;
;	FILL MEMORY, USER OPTION "M"
;________________________________________________________________________________________________________________________________
;
FILL:
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


;__DOBOOT________________________________________________________________________________________________________________________ 
;
;	PERFORM BOOT
;________________________________________________________________________________________________________________________________
;
DOBOOT:
;	LD	A,0H		; LOAD VALUE TO SWITCH OUT ROM
	LD	A,80H		; LOAD VALUE TO SWITCH OUT ROM
	OUT	(MPCL_ROM),A	; SWITCH OUT ROM, BRING IN LOWER 32K RAM PAGE
				;
				;
	OUT	(MPCL_RAM),A	;
;	JP	0000H			; GO TO CP/M



;__GOCPM_________________________________________________________________________________________________________________________ 
;
;	BOOT CP/M FROM ROM DRIVE, USER OPTION "C"
;________________________________________________________________________________________________________________________________
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

;	JP	0EA00h			; CP/M COLD BOOT ENTRY POINT
	RET				; RETURN TO CP/M

;
;__INIT_UART_____________________________________________________________________________________________________________________ 
;
;	INITIALIZE UART
;	PARAMS:	SER_BAUD NEEDS TO BE SET TO BAUD RATE
;	1200:	96	 = 1,843,200 / ( 16 X 1200 )
;	2400:	48	 = 1,843,200 / ( 16 X 2400 )
;	4800:	24	 = 1,843,200 / ( 16 X 4800 )
;	9600:	12	 = 1,843,200 / ( 16 X 9600 )
;	19K2:	06	 = 1,843,200 / ( 16 X 19,200 )
;	38K4:	03	
;	57K6:	02
;	115K2:	01	
;
;_________________________________________________________________________________________________________________________________
;
INIT_UART:
	LD	A,80H			;
	OUT	(UART3),A		; SET DLAB FLAG
	LD	A,(SER_BAUD)		;
	OUT	(UART0),A		;
	LD	A,00H			;
	OUT	(UART1),A		;
	LD	A,03H			;
	OUT	(UART3),A		; SET 8 BIT DATA, 1 STOPBIT
	LD    	A,03H        		; set DTR & RTS
        OUT  	(UART4),A		;
	RET


;
;__FILL_MEM_______________________________________________________________________________________________________________________ 
;
;	FUNCTION	: FILL MEMORY WITH A VALUE
;	INPUT		: HL = START ADDRESS BLOCK
;			: BC = LENGTH OF BLOCK
;			: A = VALUE TO FILL WITH
;	USES		: DE, BC
;	OUTPUT		:
;	CALLS		: 
;	TESTED		: 13 FEB 2007
;_________________________________________________________________________________________________________________________________
;
FILL_MEM:
	LD	E,L			;
	LD	D,H			;
	INC	DE			;
	LD	(HL),A			; INITIALISE FIRST BYTE OF BLOCK WITH DATA BYTE IN A
	DEC	BC			;
	LDIR				; FILL MEMORY
	RET				; RETURN TO CALLER
;
;__RAM_TEST________________________________________________________________________
;
;	TEST FUNCTIONALITY OF LOWER 32KB RAM PAGE, USER OPTION "A"
;	SYNTAX: A
;_____________________________________________________________________________
;

DORAMTEST:

; VERIFY DATA BUS FUNCTIONALITY BEFORE STARTING MEMORY TEST
DATABUSTEST:
	LD	A,$80			; FIRST 32KB PAGE ONLY
	LD	(PAGE_NUM),A		; STORE WORKING PAGE NUMBER
	OUT	(MPCL_ROM),A		; SWITCH OUT LOWER 32KB ROM PAGE
	OUT	(MPCL_RAM),A		; SWITCH IN LOWER 32KB RAM PAGE
	LD	A,$00			; INITIALIZE A TO 0

DATABUSCHECK:
	LD	C,A
	LD	($0000),A		; WRITE TO LOWEST RAM ADDRESS
	LD	A,($0000)		; READ VALUE FROM LOWEST RAM ADDRESS
	CP	C			; IS IT SAME AS WRITTEN?
	JP	NZ,DATABUSFAIL		; NO? DATA BUS FAIL HANDLER ROUTINE
	INC	A			; YES, GET NEXT VALUE
	JP	NZ,DATABUSCHECK		; REPEAT FOR ALL 256 VALUES
	LD	HL,TXT_DATA_BUS_PASS	; POINT AT DATA BUS PASS TEXT
	CALL	MSG			; PRINT DATA BUS PASS LABEL
	JP	ADDRBUSTEST		; CONTINUE WITH ADDRESS BUS TEST	
	
DATABUSFAIL:
	PUSH	AF			; STORE FAILED VALUE
	LD	HL,TXT_DATA_BUS_FAIL	; POINT AT DATA BUS FAIL TEXT
	CALL	MSG			; PRINT DATA BUS FAIL LABEL
	POP	AF			; RETRIEVE FAILED VALUE
	CALL	HXOUT			; SHOW VALUE THAT FAILED
	LD	HL,TCRLF		; CR & LF
	CALL	MSG			; DISPLAY IT
	JP	SERIALCMDLOOP		; AND BACK TO COMMAND LOOP

; VERIFY ADDRESS BUS FUNCTIONALITY BEFORE STARTING MEMORY TEST
ADDRBUSTEST:
	LD	A,$80			; FIRST 32KB PAGE ONLY
	LD	(PAGE_NUM),A		; STORE WORKING PAGE NUMBER
	OUT	(MPCL_ROM),A		; SWITCH OUT LOWER 32KB ROM PAGE
	OUT	(MPCL_RAM),A		; SWITCH IN LOWER 32KB RAM PAGE
	LD	A,$00			; INITIALIZE A TO 0
	LD	($0000),A		; WRITE TO LOWEST RAM ADDRESS
	LD	HL,$0001		; INITIALIZE HL TO CHECK A0
	
ADDRBUSCHECK:
	LD	(HL),$FF		; WRITE ALL ONES INTO HL ADDRESS
	LD	C,$00
	LD	A,($0000)		; READ VALUE FROM LOWEST RAM ADDRESS
	CP	C			; IS IT SAME AS WRITTEN?  SHOULD BE 0
	JP	NZ,ADDRBUSFAIL		; NO? ADDR BUS FAIL HANDLER ROUTINE
	PUSH	HL			; STORE HL, FOR COPY TO BC
	POP	BC			; RETRIEVE BC (SAME AS HL)
	ADD	HL,BC			; INCREMENT TO NEXT ADDR LINE
	LD	A,H			; WHICH ADDRESS LINE ARE WE AT
	CP	$80			; ARE WE AT A15?
	JP	NZ,ADDRBUSCHECK		; NO? REPEAT FOR ALL 15 VALUES
	LD	HL,TXT_ADDR_BUS_PASS	; YES? POINT AT ADDR BUS PASS TEXT
	CALL	MSG			; PRINT ADDR BUS PASS LABEL
	JP	MEMSIZELOOP		; CONTINUE WITH REST OF RAM TEST	
	
ADDRBUSFAIL:
	PUSH	HL			; STORE FAILED ADDR LINE VALUE	
	LD	HL,TXT_ADDR_BUS_FAIL	; POINT AT ADDR BUS FAIL TEXT
	CALL	MSG			; PRINT ADDR BUS FAIL LABEL
	POP	HL			; RETRIEVE FAILED ADDR LINE VALUE
	LD	A,H			; PRINT UPPER HALF OF ADDRESS
	PUSH	HL			; STORE FAILED ADDR LINE VALUE
	CALL	HXOUT			; PRINT HIGH ADDR HALF THAT FAILED
	POP	HL			; RETRIEVE FAILED ADDR LINE VALUE
	LD	A,L			; PRINT LOWER HALF OF ADDRESS
	CALL	HXOUT			; PRINT LOW ADDR HALF THAT FAILED
	LD	HL,TCRLF		; CR & LF
	CALL	MSG			; DISPLAY IT
	JP	SERIALCMDLOOP		; AND BACK TO COMMAND LOOP

MEMSIZELOOP:
	LD	HL,TXT_RAM_TEST_MAIN	; POINT AT RAM TEST MAIN MENU TEXT
	CALL	MSG			; PRINT MENU TEXT LABEL
	CALL	CRLFA			; CR,LF,>
	LD	HL,KEYBUF		; SET POINTER TO KEYBUF AREA
	CALL 	GETLN			; GET A LINE OF INPUT FROM THE USER
	LD	HL,KEYBUF		; RESET POINTER TO START OF KEYBUF
        LD      A,(HL)			; LOAD FIRST CHAR INTO A (THIS SHOULD BE THE MEM SIZE FOR TEST)
	INC	HL			; INC POINTER

	CP	'A'			; IS IT "A" (Y/N)
	JP	Z,MEM32KB		; IF YES DO 32KB RAM TEST
	CP	'B'			; IS IT "B" (Y/N)
	JP	Z,MEM64KB		; IF YES DO 64KB RAM TEST
	CP	'C'			; IS IT "C" (Y/N)
	JP	Z,MEM128KB		; IF YES DO 128KB RAM TEST
	CP	'D'			; IS IT "D" (Y/N)
	JP	Z,MEM256KB		; IF YES DO 256KB RAM TEST
	CP	'E'			; IS IT "E" (Y/N)
	JP	Z,MEM512KB		; IF YES DO 512KB RAM TEST
	CP	'F'			; IS IT "F" (Y/N)
	JP	Z,MEM1024KB		; IF YES DO 1024KB RAM TEST
	LD	HL,TXT_COMMAND		; POINT AT ERROR TEXT
	CALL	MSG			; PRINT COMMAND LABEL

	JR	MEMSIZELOOP

MEM32KB:
	LD	HL,TXT_RAM_TEST_32KB	; 1 PAGE, 32KB RAM TEST SELECTED
	CALL	MSG			; DISPLAY IT

	LD	A,$80			; ONE 32KB PAGE ONLY
	LD	(PAGE_NUM),A		; STORE WORKING PAGE NUMBER
	JP	RAMTEST

MEM64KB:
	LD	HL,TXT_RAM_TEST_64KB	; 2 PAGE, 64KB RAM TEST SELECTED
	CALL	MSG			; DISPLAY IT

	LD	A,$81			; TWO 32KB PAGES
	LD	(PAGE_NUM),A		; STORE WORKING PAGE NUMBER
	JP	RAMTEST

MEM128KB:
	LD	HL,TXT_RAM_TEST_128KB	; 4 PAGE, 12864KB RAM TEST SELECTED
	CALL	MSG			; DISPLAY IT

	LD	A,$83			; FOUR 32KB PAGES
	LD	(PAGE_NUM),A		; STORE WORKING PAGE NUMBER
	JP	RAMTEST

MEM256KB:
	LD	HL,TXT_RAM_TEST_256KB	; 8 PAGE, 256KB RAM TEST SELECTED
	CALL	MSG			; DISPLAY IT

	LD	A,$87			; EIGHT 32KB PAGES
	LD	(PAGE_NUM),A		; STORE WORKING PAGE NUMBER
	JP	RAMTEST

MEM512KB:
	LD	HL,TXT_RAM_TEST_512KB	; 16 PAGE, 512KB RAM TEST SELECTED
	CALL	MSG			; DISPLAY IT

	LD	A,$8F			; SIXTEEN 32KB PAGES
	LD	(PAGE_NUM),A		; STORE WORKING PAGE NUMBER
	JP	RAMTEST

MEM1024KB:
	LD	HL,TXT_RAM_TEST_1024KB	; 32 PAGE, 1024KB RAM TEST SELECTED
	CALL	MSG			; DISPLAY IT

	LD	A,$9F			; THIRTY-TWO 32KB PAGES
	LD	(PAGE_NUM),A		; STORE WORKING PAGE NUMBER
	JP	RAMTEST

RAMTEST:
	LD	A,(PAGE_NUM)		; GET WORKING PAGE NUMBER
	CP	$8F			; IS IT PAGE SIXTEEN?
	JP	NZ,NEXTPAGE		; NO? DO ANOTHER 32KB PAGE
	SUB	$01			; YES? SKIP OVER PAGE SIXTEEN
					; (WHERE RAMTEST PROGRAM IS RUNNING)
	LD	(PAGE_NUM),A		; UPDATE WORKING PAGE NUMBER

	LD	HL,TXT_SKIP_16		; POINT AT SYNTAX SKIP PAGE SIXTEEN
	CALL	MSG			; DISPLAY IT

	JP	RAMTEST			; TRY AGAIN WITH NEXT RAM PAGE

NEXTPAGE:
	OUT	(MPCL_ROM),A		; SWITCH OUT LOWER 32KB ROM PAGE
	OUT	(MPCL_RAM),A		; SWITCH IN LOWER 32KB RAM PAGE

	LD	HL,$7FFF		; INITIALIZE MEMORY ADDRESS COUNT
	LD	DE,$0001		; DECREMENT VALUE
	LD	IX,TEST_VALUES		; MEMORY TEST VALUES

START:
	LD	A,(IX+0)		; LOAD TEST VALUE
	LD	B,A			; STORE TEST VALUE IN B
	CP	'$'			; IS IT LAST ONE?
	JP	Z,RAM_PASS		; YES?, RAM PASSED TEST, EXIT RAM TEST

	LD	(HL),A			; NO?, WRITE TO MEMORY ADDRESS
	LD	C,(HL)			; LOAD VALUE FROM MEMORY ADDRESS
	CP	C			; IS IT SAME AS WRITTEN?
	JP	NZ,RAM_FAIL		; NO?, JUMP TO ERROR HANDLER ROUTINE

	SBC     HL,DE			; REDUCE MEMORY ADDRESS COUNT BY 1
	JP	NZ,START		; LOOP THROUGH ALL MEMORY IN LOWER 32KB PAGE

					; DO $0000 MEMORY ADDRESS
	LD	(HL),A			; NO?, WRITE TO MEMORY ADDRESS
	LD	C,(HL)			; LOAD VALUE FROM MEMORY ADDRESS
	CP	C			; IS IT SAME AS WRITTEN?
	JP	NZ,RAM_FAIL		; NO?, JUMP TO ERROR HANDLER ROUTINE

	INC	IX			; POINT TO NEXT TEST VALUE
	LD	HL,$7FFF		; INITIALIZE MEMORY ADDRESS COUNT
	JP	START			; START AGAIN, TEST ALL MEMORY LOCATIONS WITH NEW TEST VALUE

RAM_PASS:
	LD	HL,TXT_RAM_PASS		; POINT AT SYNTAX RAM PASS TEXT
	CALL	MSG			; DISPLAY IT

	LD	A,(PAGE_NUM)		; GET WORKING PAGE NUMBER
	SUB	$80			; CONVERT MPCL VALUE TO PAGE NUMBER
	CALL	HXOUT			; SHOW IT

	LD	A,(PAGE_NUM)		; GET WORKING PAGE NUMBER
	DEC	A			; MARK PAGE COMPLETE, MOVE TO NEXT
	LD	(PAGE_NUM),A		; STORE UPDATED PAGE NUMBER

	CP	$7F			; WAS THAT THE LAST PAGE?
	JP	NZ,RAMTEST		; NO? DO ANOTHER 32KB PAGE

	LD	HL,TCRLF		; CR & LF
	CALL	MSG			; DISPLAY IT
	JP	SERIALCMDLOOP		; YES? BACK TO COMMAND LOOP


RAM_FAIL:
	PUSH	HL
	LD	HL,TXT_RAM_FAIL1	; POINT AT 1ST SYNTAX RAM FAIL TEXT
	CALL	MSG			; DISPLAY IT
	LD	A,(PAGE_NUM)		; GET CURRENT PAGE NUMBER
	SUB	$80
	CALL	HXOUT			; SHOW IT
	LD	HL,TXT_RAM_FAIL2	; POINT AT 2ND SYNTAX RAM FAIL TEXT
	CALL	MSG			; DISPLAY IT
	
	POP	HL			; RETRIEVE FAILED ADDR VALUE
	LD	A,H			; PRINT UPPER HALF OF ADDRESS
	PUSH	HL			; STORE FAILED ADDR VALUE
	CALL	HXOUT			; PRINT HIGH ADDR HALF THAT FAILED
	POP	HL			; RETRIEVE FAILED ADDR LINE VALUE
	LD	A,L			; PRINT LOWER HALF OF ADDRESS
	CALL	HXOUT			; PRINT LOW ADDR HALF THAT FAILED
	LD	HL,TCRLF		; CR & LF
	CALL	MSG			; DISPLAY IT

	LD	A,(PAGE_NUM)		; GET WORKING PAGE NUMBER
	DEC	A			; MARK PAGE COMPLETE, MOVE TO NEXT
	LD	(PAGE_NUM),A		; STORE UPDATED PAGE NUMBER
	CP	$7F			; WAS THAT THE LAST PAGE?
	JP	NZ,RAMTEST		; NO? DO ANOTHER 32KB PAGE
	JP	SERIALCMDLOOP		; AND BACK TO COMMAND LOOP


;
;__INITIALIZE_____________________________________________________________________________________________________________________ 
;
;	INITIALIZE SYSTEM
;_________________________________________________________________________________________________________________________________
;
INITIALIZE:
;	LD	A,12			; SPECIFY BAUD RATE 9600 BPS (9600,8,NONE,1)
	LD	A,3			; SPECIFY BAUD RATE 38400 BPS (9600,8,NONE,1)
	LD	(SER_BAUD),A		; 
	CALL	INIT_UART		; INIT THE UART 
	RET	 			; 
;

;__MTERM_INIT________________________________________________________________________________________
;
;  SETUP 8255, MODE 0, PORT A=OUT, PORT B=IN, PORT C=OUT/OUT 
;     
;____________________________________________________________________________________________________
MTERM_INIT:
	LD	A, 82H
	OUT (PIOCONT),A
	RET

;
;__TEXT_STRINGS_________________________________________________________________________________________________________________ 
;
;	SYSTEM TEXT STRINGS
;_____________________________________________________________________________________________________________________________
;
TCRLF:
	.DB  	CR,LF,ENDT

PROMPT:
	.DB  	CR,LF,'>',ENDT

TXT_READY:
	.DB   "RAM TEST PROGRAM",CR,LF
	.DB   CR,LF                                                                                                                                                
	.DB   "MONITOR READY "
	.DB   CR,LF,ENDT

TXT_COMMAND:
	.DB   CR,LF
	.DB   "UNKNOWN COMMAND."
	.DB   ENDT

TXT_MAIN_MENU:
	.DB   CR,LF
	.DB   "MAIN MENU: "
	.DB   "A RAM TEST, "
	.DB   "B BOOT, "
	.DB   "D DUMP, "
	.DB   "F FILL, "
	.DB   "H LOAD, "
	.DB   CR,LF
	.DB   "I INPUT, "
	.DB   "K ECHO, "
	.DB   "M MOVE, "
	.DB   "O OUTPUT, "
	.DB   "P PROGRAM, "
	.DB   "R RUN"
	.DB   CR,LF
	.DB   ENDT

TXT_CKSUMERR:
	.DB   CR,LF
	.DB   "CHECKSUM ERROR."
	.DB   ENDT

TXT_RAM_PASS:
	.DB   CR,LF
	.DB   "RAM PASS, PAGE = "
	.DB   ENDT

TXT_RAM_FAIL1:
	.DB   CR,LF
	.DB   "RAM FAIL, 32KB PAGE NUMBER: "
	.DB   ENDT

TXT_RAM_FAIL2:
	.DB   CR,LF
	.DB   " ADDRESS "
	.DB   CR,LF,ENDT

TXT_DATA_BUS_FAIL:
	.DB   CR,LF
	.DB   "DATA BUS FAIL, VALUE ="
	.DB   ENDT

TXT_DATA_BUS_PASS:
	.DB   CR,LF
	.DB   "DATA BUS PASS "
	.DB   CR,LF,ENDT

TXT_ADDR_BUS_FAIL:
	.DB   CR,LF
	.DB   "ADDR BUS FAIL, VALUE ="
	.DB   ENDT

TXT_ADDR_BUS_PASS:
	.DB   CR,LF
	.DB   "ADDR BUS PASS "
	.DB   CR,LF,ENDT

TXT_SKIP_16:
	.DB   CR,LF
	.DB   "SKIPPING PAGE 0F "
	.DB   ENDT

TXT_RAM_TEST_MAIN:
	.DB   CR,LF
	.DB   "ENTER RAM SIZE: A=32KB, B=64KB,"
	.DB   " C=128KB, D=256KB, E=512KB,"
	.DB   " F=1024KB"
	.DB   CR,LF,ENDT

TXT_RAM_TEST_32KB:
	.DB   CR,LF
	.DB   "ONE 32KB PAGE SELECTED"
	.DB   CR,LF,ENDT

TXT_RAM_TEST_64KB:
	.DB   CR,LF
	.DB   "TWO 32KB PAGES SELECTED"
	.DB   CR,LF,ENDT

TXT_RAM_TEST_128KB:
	.DB   CR,LF
	.DB   "FOUR 32KB PAGES SELECTED"
	.DB   CR,LF,ENDT

TXT_RAM_TEST_256KB:
	.DB   CR,LF
	.DB   "EIGHT 32KB PAGES SELECTED"
	.DB   CR,LF,ENDT

TXT_RAM_TEST_512KB:
	.DB   CR,LF
	.DB   "SIXTEEN 32KB PAGES SELECTED"
	.DB   CR,LF,ENDT

TXT_RAM_TEST_1024KB:
	.DB   CR,LF
	.DB   "THIRTY-TWO 32KB PAGES SELECTED"
	.DB   CR,LF,ENDT

;
;__RAM_TEST_VALUES____________________________________________________________
;
;	RAM TEST VALUES
;_____________________________________________________________________________
;
TEST_VALUES	.DB	$00,$FF,$33,$CC,$55,$AA,'$'

;
;__WORK_AREA___________________________________________________________________________________________________________________ 
;
;	RESERVED RAM FOR MONITOR WORKING AREA
;_____________________________________________________________________________________________________________________________
;
SER_BAUD:	.FILL	1		; SPECIFY DESIRED UART COM RATE IN BPS
PAGE_NUM	.FILL	1
KEYBUF:  	.DB   	"                "
		.DB	"                "
		.DB	"                "
		.DB	"                "
		.DB	"                "

;********************* END OF PROGRAM ***********************************
 .FILL 08FFFh-$
 .ORG	08FFFh
 .DB  	000h
 .END

 
 
