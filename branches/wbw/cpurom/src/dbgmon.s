	.title dbgmon.s derived from dbgmon.asm
	.sbttl Ported by Douglas Goodall

	.module dbgmon
	.optsdcc -mz80
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _dbgmon
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
;  ram data
;--------------------------------------------------------
	.area _DATA
;--------------------------------------------------------
; overlayable items in  ram 
;--------------------------------------------------------
	.area _OVERLAY
;--------------------------------------------------------
; external initialized ram data
;--------------------------------------------------------
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _DBGMON
_dbgmon_start::
_dbgmon:


;___ROM_MONITOR_PROGRAM_____________________________________________________________________________________________________________
;
;  ORIGINAL CODE BY:	ANDREW LYNCH (LYNCHAJ@YAHOO COM)	13 FEB 2007
;
;  MODIFIED BY : 	DAN WERNER 03 09.2009
;
;__REFERENCES________________________________________________________________________________________________________________________ 
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
;
;__HARDWARE_INTERFACES________________________________________________________________________________________________________________ 
;
; PIO 82C55 I/O IS DECODED TO PORT 60-67
;
PORTA		 = 	0x60
PORTB		 = 	0x61
PORTC		 = 	0x62
PIOCONT 	 = 	0x63
;
; UART 16C450 SERIAL IS DECODED TO 68-6F
;
UART0		 =	0x68		;   DATA IN/OUT
UART1		 =	0x69		;   CHECK RX
UART2		 =	0x6A		;   INTERRUPTS
UART3		 =	0x6B		;   LINE CONTROL
UART4		 =	0x6C		;   MODEM CONTROL
UART5		 =	0x6D		;   LINE STATUS
UART6		 =	0x6E		;   MODEM STATUS
UART7		 =	0x6F		;   SCRATCH REG.
;
; MEMORY PAGE CONFIGURATION LATCH IS DECODED TO 78
;
MPCL		 =	0x78		; CONTROL PORT, SHOULD ONLY BE CHANGED WHILE
;					  IN UPPER MEMORY PAGE 08000h-$FFFF OR LIKELY
MPCL_RAM	 = 	0x78		; BASE IO ADDRESS OF RAM MEMORY PAGER CONFIGURATION LATCH
MPCL_ROM	 = 	0x7C		; BASE IO ADDRESS OF ROM MEMORY PAGER CONFIGURATION LATCH
;					  LOSS OF CPU MEMORY CONTEXT 
;
; MEMORY PAGE CONFIGURATION LATCH CONTROL PORT ( IO_Y3 ) INFORMATION
;
;	7 6 5 4  3 2 1 0      ONLY APPLICABLE TO THE LOWER MEMORY PAGE 00000h-$7FFF
;	^ ^ ^ ^  ^ ^ ^ ^
;	: : : :  : : : :--0 = A15 RAM/ROM ADDRESS LINE DEFAULT IS 0
;	: : : :  : : :----0 = A16 RAM/ROM ADDRESS LINE DEFAULT IS 0
;	: : : :  : :------0 = A17 RAM/ROM ADDRESS LINE DEFAULT IS 0
;	: : : :  :--------0 = A18 RAM/ROM ADDRESS LINE DEFAULT IS 0
;	: : : :-----------0 = A19 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: : :-------------0 = 
;	: :---------------0 = 
;	:-----------------0 = ROM SELECT (0=ROM, 1=RAM) DEFAULT IS 0
;
;
;IDE REGISTER		IO PORT		; FUNCTION
IDELO		 =	0x020		; DATA PORT (LOW BYTE)
IDEERR		 =	0x021		; READ: ERROR REGISTER; WRITE: PRECOMP
IDESECTC	 =	0x022		; SECTOR COUNT
IDESECTN	 =	0x023		; SECTOR NUMBER
IDECYLLO	 =	0x024		; CYLINDER LOW
IDECYLHI	 =	0x025		; CYLINDER HIGH
IDEHEAD		 =	0x026		; DRIVE/HEAD
IDESTTS		 =	0x027		; READ: STATUS; WRITE: COMMAND
IDEHI		 =	0x028		; DATA PORT (HIGH BYTE)
IDECTRL		 =	0x02E		; READ: ALTERNATIVE STATUS; WRITE; DEVICE CONTROL
IDEADDR		 =	0x02F		; DRIVE ADDRESS (READ ONLY)

;
;
;__CONSTANTS_________________________________________________________________________________________________________________________ 
;	
RAMTOP		 =	0x0FFFF		; HIGHEST ADDRESSABLE MEMORY LOCATION
STACKSTART	 =	0x0CFFF		; START OF STACK
RAMBOTTOM	 =	0x08000		; START OF FIXED UPPER 32K PAGE OF 512KB X 8 RAM 8000H-FFFFH
MONSTARTCOLD	 =	0x08000		; COLD START MONITOR IN HIGH RAM
ENDT		 =	0x0FF		; MARK END OF TEXT
CR		 =	0x0D		; ASCII CARRIAGE RETURN CHARACTER
LF		 =	0x0A		; ASCII LINE FEED CHARACTER
ESC		 =	0x1B		; ASCII ESCAPE CHARACTER
BS		 =	0x08		; ASCII BACKSPACE CHARACTER

ASCIIA	= 	0x41
ASCIIB	=	0x42
ASCIIC	=	0x43
ASCIID	=	0x44
ASCIIE	=	0x45
ASCIIF	=	0x46
ASCIIG	=	0x47
ASCIIH	=	0x48
ASCIII	=	0x49
ASCIIJ	=	0x4A
ASCIIK	=	0x4B
ASCIIL	=	0x4C
ASCIIM	=	0x4D
ASCIIN	=	0x4E
ASCIIO	=	0x4F
ASCIIP	=	0x50
ASCIIQ	=	0x51
ASCIIR	=	0x52
ASCIIS	=	0x53
ASCIIT	=	0x54
ASCIIU	=	0x55
ASCIIV	=	0x56
ASCIIW	=	0x57
ASCIIX	=	0x58
ASCIIY	=	0x59
ASCIIZ	=	0x5A

;
;
;
;__MAIN_PROGRAM_____________________________________________________________________________________________________________________ 
;
;	 ORG	00100h			; FOR DEBUG IN CP/M (AS .COM)

;dwg;	 .ORG	8000H			; NORMAL OP

	LD	SP,#STACKSTART		; SET THE STACK POINTER TO STACKSTART
	CALL	INITIALIZE		; INITIALIZE SYSTEM



;__FRONT_PANEL_STARTUP___________________________________________________________________________________________________________ 
;
;	START UP THE SYSTEM WITH THE FRONT PANEL INTERFACE
;	
;________________________________________________________________________________________________________________________________
;
	CALL    MTERM_INIT		; INIT 8255 FOR MTERM
	LD	HL,#CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 



FRONTPANELLOOP:
	CALL	KB_GET			; GET KEY FROM KB

	CP	#0x10			; IS PORT READ?
	JP	Z,DOPORTREAD		; YES, JUMP
	CP	#0x11			; IS PORT WRITE?
	JP	Z,DOPORTWRITE		; YES, JUMP
	CP	#0x14			; IS DEPOSIT?
	JP	Z,DODEPOSIT		; YES, JUMP
	CP	#0x15			; IS EXAMINE?
	JP	Z,DOEXAMINE		; YES, JUMP
	CP	#0x16			; IS GO?
	JP	Z,DOGO			; YES, JUMP
	CP	#0x17			; IS BO?
	JP	Z,DOBOOT		; YES, JUMP

	JR	FRONTPANELLOOP		; LOOP
EXIT:
	RET	


;__DOBOOT________________________________________________________________________________________________________________________ 
;
;	PERFORM BOOT FRONT PANEL ACTION
;________________________________________________________________________________________________________________________________
;
DOBOOT:
	LD	A,#0		; LOAD VALUE TO SWITCH OUT ROM
	OUT	(MPCL_ROM),A	; SWITCH OUT ROM, BRING IN LOWER 32K RAM PAGE
				;
				;
	OUT	(MPCL_RAM),A	;
	JP	0			; GO TO CP/M


;__DOPORTREAD____________________________________________________________________________________________________________________ 
;
;	PERFORM PORT READ FRONT PANEL ACTION
;________________________________________________________________________________________________________________________________
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
	AND	#0x0F			; CLEAR HIGH NIB, LEAVING LOW
	LD	(DISPLAYBUF+4),A	; SHOW LOW NIB IN DISP 4
	IN 	A,(C)			; GET PORT VALUE FROM PORT IN "C"
	LD	C,A			; STORE VALUE IN "C"
	SRL	A			; ROTATE HIGH NIB TO LOW
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+1),A	; SHOW HIGH NIB IN DISP 1
	LD	A,C			; RESTORE VALUE TO "A"
	AND	#0x0F			; CLEAR HIGH NIB, LEAVING LOW
	LD	(DISPLAYBUF),A		; DISPLAY LOW NIB IN DISP 0
	LD	A,#0x10			; CLEAR OTHER DISPLAYS
	LD	(DISPLAYBUF+2),A	;
	LD	(DISPLAYBUF+3),A	;
	LD	A,#0x13			; "P"
	LD	(DISPLAYBUF+7),A	; STORE IN DISP 7
	LD	A,#0x14			; "O"
	LD	(DISPLAYBUF+6),A	; STORE IN DISP 6
	LD	HL,#DISPLAYBUF		; SET POINTER TO DISPLAY BUFFER
	CALL	HEXDISPLAY		; DISPLAY BUFFER CONTENTS
PORTREADGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	CP	#0x12			; [CL] PRESSED, EXIT
	JP	Z,PORTREADEXIT		;
	CP	#0x10			; [PR] PRESSED, PROMPT FOR NEW PORT
	JR	Z,DOPORTREAD		;
	JR	PORTREADGETKEY		; NO VALID KEY, LOOP
PORTREADEXIT:
	LD	HL,#CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
	JP	FRONTPANELLOOP		;

;__DOPORTWRITE____________________________________________________________________________________________________________________ 
;
;	PERFORM PORT WRITE FRONT PANEL ACTION
;________________________________________________________________________________________________________________________________
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
	AND	#0x0F			; CLEAR OUT HIGH NIB
	LD	(DISPLAYBUF+4),A	; DISPLAY LOW NIB IN DISPLAY 4
	LD	A,#0x10			; CLEAR OUT DISPLAYS 2 AND 3
	LD	(DISPLAYBUF+2),A	;
	LD	(DISPLAYBUF+3),A	;
	LD	A,#0x13			; DISPLAY "P" IN DISP 7
	LD	(DISPLAYBUF+7),A	;
	LD	A,#0x14			; DISPLAY "O" IN DISP 6
	LD	(DISPLAYBUF+6),A	;
	LD	HL,#DISPLAYBUF		; POINT TO DISPLAY BUFFER
	CALL	GETVALUE		; INPUT A BYTE VALUE, RETURN IN "A"
	OUT	(C),A			; OUTPUT VALUE TO PORT STORED IN "C"
	LD	HL,#CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
	JP	FRONTPANELLOOP		;


;__DOGO__________________________________________________________________________________________________________________________ 
;
;	PERFORM GO FRONT PANEL ACTION
;________________________________________________________________________________________________________________________________
;
DOGO:
	CALL 	GETADDR			; GET ADDRESS INTO HL
	JP	(HL)			; GO THERE!



;__DODEPOSIT________________________________________________________________________________________________________________________ 
;
;	PERFORM DEPOSIT FRONT PANEL ACTION
;________________________________________________________________________________________________________________________________
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
	AND	#0x0F			;
	LD	(DISPLAYBUF+6),A	;
	LD	A,L			;
	SRL	A			;
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+5),A	;
	LD	A,L			;
	AND	#0x0F			;
	LD	(DISPLAYBUF+4),A	;
	LD	A,#0x10			;
	LD	(DISPLAYBUF+3),A	;
	LD	HL,#DISPLAYBUF		;
	CALL	GETVALUE		;
	POP	HL			;
	LD	(HL),A			;
DEPOSITGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	CP	#0x12			; [CL] PRESSED, EXIT
	JP	Z,DEPOSITEXIT		;
	CP	#0x13			; [EN] PRESSED, INC ADDRESS AND LOOP
	JR	Z,DEPOSITFW		; 
	CP	#0x14			; [DE] PRESSED, PROMPT FOR NEW ADDRESS
	JR	Z,DODEPOSIT		;
	JR	DEPOSITGETKEY		; NO VALID KEY, LOOP
DEPOSITFW:
	INC	HL			;
	PUSH	HL			; STORE HL
	JR 	DEPOSITLOOP		;	
DEPOSITEXIT:
	LD	HL,#CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
	JP	FRONTPANELLOOP		;




;__DOEXAMINE________________________________________________________________________________________________________________________ 
;
;	PERFORM EXAMINE FRONT PANEL ACTION
;________________________________________________________________________________________________________________________________
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
	AND	#0x0F			; CLEAR HIGH NIBBLE
	LD	(DISPLAYBUF+6),A	; DISPLAY LOW NIBBLE IN DISP 6
	LD	A,L			; PUT LOW BYTE IN "A"
	SRL	A			; SHOW HIGH NIBBLE IN DISP 5
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+5),A	;
	LD	A,L			; RESTORE LOW BYTE IN "A"
	AND	#0x0F			; CLEAR OUT HIGH NIBBLE
	LD	(DISPLAYBUF+4),A	; DISPLAY LOW NIBBLE IN DISP 4
	LD	A,#0x10			; CLEAR OUT DISP 3
	LD	(DISPLAYBUF+3),A	;
	LD	A,(HL)			; GET VALUE FROM ADDRESS IN HL
	SRL	A			; DISPLAY HIGH NIB IN DISPLAY 1
	SRL	A			;
	SRL	A			;
	SRL	A			;
	LD	(DISPLAYBUF+1),A	;
	LD	A,(HL)			; GET VALUE FROM ADDRESS IN HL
	AND	#0x0F			; CLEAR OUT HIGH NIBBLE
	LD	(DISPLAYBUF),A		; DISPLAY LOW NIBBLE IN DISPLAY 0
	LD	HL,#DISPLAYBUF		; POINT TO DISPLAY BUFFER
	CALL	HEXDISPLAY		; DISPLAY BUFFER ON DISPLAYS
	POP	HL			; RESTORE HL
EXAMINEGETKEY:
	CALL	KB_GET			; GET KEY FROM KB
	CP	#0x12			; [CL] PRESSED, EXIT
	JP	Z,EXAMINEEXIT		;
	CP	#0x13			; [EN] PRESSED, INC ADDRESS AND LOOP
	JR	Z,EXAMINEFW		; 
	CP	#0x15			; [DE] PRESSED, PROMPT FOR NEW ADDRESS
	JR	Z,DOEXAMINE		;
	JR	EXAMINEGETKEY		; NO VALID KEY, LOOP
EXAMINEFW:
	INC	HL			; HL++
	PUSH	HL			; STORE HL
	JR 	EXAMINELOOP		;	
EXAMINEEXIT:
	LD	HL,#CPUUP		; SET POINTER TO DATA BUFFER
	CALL	SEGDISPLAY		; DISPLAY 
	JP	FRONTPANELLOOP		;


;__GETADDR_______________________________________________________________________________________________________________________ 
;
;	GET ADDRESS FROM FRONT PANEL
;________________________________________________________________________________________________________________________________
;
GETADDR:
	PUSH	BC			; STORE BC
	JR	GETADDRCLEAR		; 
GETADDR1:
	LD	HL,#ADDR			; DISPLAY PROMPT
	CALL	SEGDISPLAY		; 
GETADDRLOOP:
	CALL	KB_GET			;	
	CP	#0x10			;
	JP	M,GETADDRNUM		; NUMBER PRESSED, STORE IT
	CP	#0x13			; EN PRESSED, DONE
	JR	Z,GETADDRDONE		;
	CP	#0x12			; CLEAR PRESSED, CLEAR
	JR	Z,GETADDRCLEAR		; 
	JR	GETADDRLOOP		; INVALID KEY, LOOP
GETADDRDONE:
	LD	HL,#0			; HL=0
	LD	A,(DISPLAYBUF+1)	; GET DIGIT IN DISPLAY 1
	SLA	A			; ROTATE IT TO HIGH NIBBLE
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			; STORE IT IN "C"	
	LD	A,(DISPLAYBUF)		; GET DIGIT IN DISPLAY 0
	AND	#0x0F			; CLEAR HIGH NIBBLE
	OR	C			; ADD IN NIBBLE STORED IN C
	LD	L,A			; STORE IT IN LOW BYTE OF ADDRESS POINTER
	LD	A,(DISPLAYBUF+3)	; GET DIGIT IN DISPLAY 3
	SLA	A			; ROTATE IT TO HIGH NIBBLE
	SLA	A			;
	SLA	A			;
	SLA	A			;
	LD	C,A			; STORE IT IN "C"	
	LD	A,(DISPLAYBUF+2)	; GET DIGIT IN DISPLAY 2
	AND	#0x0F			; CLEAR HIGH NIBBLE
	OR	C			; ADD IN NIBBLE STORED IN "C"
	LD	H,A			; STORE BYTE IN HIGH BYTE OF ADDRESS POINTER
	LD	A,#0x10			; CLEAR OUT DISPLAYS 0,1,2 & 3
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
	LD	A,#0x12			; CLEAR OUT DISPLAYS 0,1,2 & 3
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



;__DSPSECTOR_______________________________________________________________________________________________________________________ 
;
;	DISPLAY SECTOR IN HL ON FRONT PANEL
;________________________________________________________________________________________________________________________________
;
DSPSECTOR:
	PUSH	BC			; STORE BC
	PUSH	HL			; STORE HL
	LD	A,H			; DISPLAY HIGH BYTE, HIGH NIBBLE
	SRL 	A			;	
	SRL 	A			;	
	SRL 	A			;	
	SRL 	A			;	
	AND	#0x0F			;
	CALL 	DECODEDISPLAY		;
	LD	(SEC+3),A		;
	LD      A,H			; DISPLAY HIGH BYTE, LOW NIBBLE
	AND	#0x0F			;
	CALL 	DECODEDISPLAY		;
	LD	(SEC+2),A		;
	LD	A,L			; DISPLAY LOW BYTE, HIGH NIBBLE
	AND	#0x0F0			;
	SRL 	A			;	
	SRL 	A			;	
	SRL 	A			;	
	SRL 	A			;		
	AND	#0x0F			;
	CALL 	DECODEDISPLAY		;
	LD	(SEC+1),A		; DISPLAY LOW BYTE, LOW NIBBLE
	LD      A,L			;
	AND	#0x0F			;
	CALL 	DECODEDISPLAY		;
	LD	(SEC),A			;
	LD	HL,#SEC			; DISPLAY PROMPT
	CALL	SEGDISPLAY		; 
	POP	HL			; RESTORE HL
	POP	BC			; RESTORE BC
	RET



;__GETPORT_______________________________________________________________________________________________________________________ 
;
;	GET PORT FROM FRONT PANEL
;________________________________________________________________________________________________________________________________
;
GETPORT:
	PUSH	BC			; STORE BC
	JR	GETPORTCLEAR		;
GETPORT1:
	LD	HL,#PORT			; DISPLAY PROMPT
	CALL	SEGDISPLAY		; 
GETPORTLOOP:
	CALL	KB_GET			;	
	CP	#0x10			;
	JP	M,GETPORTNUM		; NUMBER PRESSED, STORE IT
	CP	#0x13			; EN PRESSED, DONE
	JR	Z,GETPORTDONE		;
	CP	#0x12			; CLEAR PRESSED, CLEAR
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
	AND	#0x0F			;
	OR	C			;
	LD	C,A			;
	LD	A,#0x10			;
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
	LD	A,#0x12			;
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


;__GETVALUE______________________________________________________________________________________________________________________ 
;
;	GET VALUE FROM FRONT PANEL
;________________________________________________________________________________________________________________________________
;
GETVALUE:
	PUSH	BC			; STORE BC
	JR	GETVALUECLEAR		;
GETVALUE1:
	CALL	HEXDISPLAY		; 
	
GETVALUELOOP:
	CALL	KB_GET			;	
	CP	#0x10			;
	JP	M,GETVALUENUM		; NUMBER PRESSED, STORE IT
	CP	#0x13			; EN PRESSED, DONE
	JR	Z,GETVALUEDONE		;
	CP	#0x12			; CLEAR PRESSED, CLEAR
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
	AND	#0x0F			;
	OR	C			;
        LD	C,A			;
	LD	A,#0x10			;
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
	LD	A,#0x12			;
	LD	(DISPLAYBUF),A		;
	LD	(DISPLAYBUF+1),A	;
	JP	GETVALUE1		;


;__MONSTARTWARM___________________________________________________________________________________________________________________ 
;
;	SERIAL MONITOR STARTUP
;________________________________________________________________________________________________________________________________
;

MONSTARTWARM:				; CALL HERE FOR SERIAL MONITOR WARM START
	LD	SP,#STACKSTART		; SET THE STACK POINTER TO STACKSTART
	CALL	INITIALIZE		; INITIALIZE SYSTEM

	XOR	A			;ZERO OUT ACCUMULATOR (ADDED)
	PUSH	HL			;PROTECT HL FROM OVERWRITE     
	LD	HL,#TXT_READY		;POINT AT TEXT
	CALL	MSG			;SHOW WE'RE HERE
	POP	HL			;PROTECT HL FROM OVERWRITE

;
;__SERIAL_MONITOR_COMMANDS_________________________________________________________________________________________________________ 
;
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
	CALL	CRLFA			; CR,LF,>
	LD	HL,#KEYBUF		; SET POINTER TO KEYBUF AREA
	CALL 	GETLN			; GET A LINE OF INPUT FROM THE USER
	LD	HL,#KEYBUF		; RESET POINTER TO START OF KEYBUF
        LD      A,(HL)			; LOAD FIRST CHAR INTO A (THIS SHOULD BE THE COMMAND)
	INC	HL			; INC POINTER

	CP	#ASCIIB			; IS IT "B" (Y/N)
	JP	Z,DOBOOT		; IF YES DO BOOT
	CP	#ASCIIR			; IS IT "R" (Y/N)
	JP	Z,RUN			; IF YES GO RUN ROUTINE
	CP	#ASCIIP			; IS IT "P" (Y/N)
	JP	Z,PROGRM		; IF YES GO PROGRAM ROUTINE
	CP	#ASCIIO			; IS IT AN "O" (Y/N)
	JP	Z,POUT			; PORT OUTPUT
	CP	#ASCIIH			; IS IT A "H" (Y/N)
	JP	Z,HXLOAD		; INTEL HEX FORMAT LOAD DATA
	CP	#ASCIII			; IS IT AN "I" (Y/N)
	JP	Z,PIN			; PORT INPUT
	CP	#ASCIID			; IS IT A "D" (Y/N)
	JP	Z,DUMP			; DUMP MEMORY
	CP	#ASCIIK
	JP	Z,KLOP			; LOOP ON KEYBOARD
	CP	#ASCIIM			; IS IT A "M" (Y/N)
	JP	Z,MOVE			; MOVE MEMORY COMMAND
	CP	#ASCIIF			; IS IT A "F" (Y/N)
	JP	Z,FILL			; FILL MEMORY COMMAND
	LD	HL,#TXT_COMMAND		; POINT AT ERROR TEXT
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
	CP	#ESC			; IS <ESC>?
	JR	NZ,KLOP			; NO, LOOP
	JP	SERIALCMDLOOP		;

;__GETLN_________________________________________________________________________________________________________________________ 
;
;	READ A LINE(80) OF TEXT FROM THE SERIAL PORT, HANDLE <BS>, TERM ON <CR> 
;       EXIT IF TOO MANY CHARS    STORE RESULT IN HL.  CHAR COUNT IN C.
;________________________________________________________________________________________________________________________________
;
GETLN:
	LD	C,#0			; ZERO CHAR COUNTER
	PUSH	DE			; STORE DE
GETLNLOP:
	CALL	KIN			; GET A KEY
	CALL	COUT			; OUTPUT KEY TO SCREEN
	CP	#CR			; IS <CR>?
	JR	Z,GETLNDONE		; YES, EXIT 
	CP	#BS			; IS <BS>?
	JR	NZ,GETLNSTORE		; NO, STORE CHAR
	LD	A,C			; A=C
	CP	#0			;
	JR	Z,GETLNLOP		; NOTHING TO BACKSPACE, IGNORE & GET NEXT KEY
	DEC	HL			; PERFORM BACKSPACE
	DEC	C			; LOWER CHAR COUNTER	
	LD	A,#0			;
	LD	(HL),A			; STORE NULL IN BUFFER
	LD	A,#0x20			; BLANK OUT CHAR ON TERM
	CALL	COUT			;
	LD	A,#BS			;
	CALL	COUT			;
	JR	GETLNLOP		; GET NEXT KEY
GETLNSTORE:
	LD	(HL),A			; STORE CHAR IN BUFFER
	INC	HL			; INC POINTER
	INC	C			; INC CHAR COUNTER	
	LD	A,C			; A=C
	CP	#0x4D			; OUT OF BUFFER SPACE?
	JR	NZ,GETLNLOP		; NOPE, GET NEXT CHAR
GETLNDONE:
	LD	(HL),#0			; STORE NULL IN BUFFER
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
	AND	#0x7F			; STRIP HI BIT
	CP	#ASCIIA			; KEEP NUMBERS, CONTROLS
	RET	C			; AND UPPER CASE
	CP	#0x7B			; SEE IF NOT LOWER CASE
	RET	NC			; 
	AND	#0x5F			; MAKE UPPER CASE
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
	LD	HL,#TCRLF		; LOAD MESSAGE POINTER
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
	CP	#0x40			; TEST FOR ALPHA
	JR	NC,ALPH			;
	AND	#0x0F			; GET THE BITS
	RET				;
ALPH:
	AND	#0x0F			; GET THE BITS
	ADD	A,#9			; MAKE IT HEX A-F
	RET				;


;__HEXINS_________________________________________________________________________________________________________________________ 
;
;	GET ONE BYTE OF HEX DATA FROM SERIAL PORT, RETURN IN A
;________________________________________________________________________________________________________________________________
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
	INC	HL			; INC KB POINTER
	CP	#0x40			; TEST FOR ALPHA
	JR	NC,ALPH			;
	AND	#0x0F			; GET THE BITS
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
	AND	#0x0F			; ONLY THIS NOW
	ADD	A,#0x30			; TRY A NUMBER
	CP	#0x3A			; TEST IT
	JR	C,OUT1			; IF CY SET PRINT 'NUMBER'
	ADD	A,#0x07			; MAKE IT AN ALPHA
OUT1:
	CALL	COUT			; SCREEN IT
	LD	A,B			; NEXT NIBBLE
	AND	#0x0F			; JUST THIS
	ADD	A,#0x30			; TRY A NUMBER
	CP	#0x3A			; TEST IT
	JR	C,OUT2			; PRINT 'NUMBER'
	ADD	A,#7			; MAKE IT ALPHA
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
	LD	A,#0x20			; LOAD A "SPACE"
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
	LD	HL,#PROMPT		;
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
	CP	#ENDT			; TEST FOR END BYTE
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
	LD      A,#ASCIIP			;
	CALL	COUT			;
	CALL  	SPACE			;
	LD	H,D			;
	LD	L,E			;
	CALL	PHL			;
	LD	HL,#KEYBUF		; SET POINTER TO KEYBUF AREA
	CALL 	GETLN			; GET A LINE OF INPUT FROM THE USER
	LD	HL,#KEYBUF		; RESET POINTER TO START OF KEYBUF
        LD      A,(HL)			; LOAD FIRST CHAR INTO A 
	CP	#0			; END OF LINE?
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
	LD	C,#16			; SET FOR 16 LOCS
	PUSH	HL			; SAVE STARTING HL
NXTONE:
	EXX				;
	LD	C,E			;
	IN	A,(C)			;
	EXX				;
	AND	#0x7F			;
	CP	#ESC			;
	JP	Z,SERIALCMDLOOP		;
	CP	#19			;
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
	LD	C,#16			; SET FOR 16 CHARS
	POP	HL			; GET BACK START
PCRLF0:
	LD	A,(HL)			; GET BYTE
	AND	#0x060			; SEE IF A 'DOT'
	LD	A,(HL)			; O K. TO GET
	JR	NZ,PDOT			;
DOT:
	LD	A,#0x2E			; LOAD A DOT	
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
	CP	#0x3A			; IS IT COLON ':'? START OF LINE OF INTEL HEX FILE
	JR	NZ,HXLOADERR		; IF NOT, MUST BE ERROR, ABORT ROUTINE
	LD	E,#0			; FIRST TWO CHARACTERS IS THE RECORD LENGTH FIELD
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
	CP	#1			; RECORD FIELD TYPE 00 IS DATA, 01 IS END OF FILE
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
	LD	HL,#TXT_CKSUMERR		; GET "CHECKSUM ERROR" MESSAGE
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


;__MOVE__________________________________________________________________________________________________________________________ 
;
;	MOVE MEMORY, USER OPTION "M"
;________________________________________________________________________________________________________________________________
;
MOVE:
	LD	C,#3
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
	LD	C,#3			;
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

	JP	0x0EA00			; CP/M COLD BOOT ENTRY POINT

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
	LD	A,#0x80			;
	OUT	(UART3),A		; SET DLAB FLAG
	LD	A,(SER_BAUD)		;
	OUT	(UART0),A		;
	LD	A,#0			;
	OUT	(UART1),A		;
	LD	A,#3			;
	OUT	(UART3),A		; SET 8 BIT DATA, 1 STOPBIT
	LD    	A,#3        		; set DTR & RTS
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
;__INITIALIZE_____________________________________________________________________________________________________________________ 
;
;	INITIALIZE SYSTEM
;_________________________________________________________________________________________________________________________________
;
INITIALIZE:
	LD	A,#12			; SPECIFY BAUD RATE 9600 BPS (9600,8,NONE,1)
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
	LD	A,#0x82
	OUT (PIOCONT),A
	RET

;__KB_GET____________________________________________________________________________________________
;
;  GET A SINGLE KEY AND DECODE
;     
;____________________________________________________________________________________________________
KB_GET:
	PUSH 	HL			; STORE HL
KB_GET_LOOP:				; WAIT FOR KEY
	CALL	KB_SCAN			;  SCAN KB ONCE
	CP	#0			;  NULL?
	JR	Z,KB_GET_LOOP		;  LOOP WHILE NOT ZERO
	LD      D,A			;  STORE A
	LD	A,#0x4F			;  SCAN ALL COL LINES
	OUT 	(PORTC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
KB_CLEAR_LOOP:				; WAIT FOR KEY TO CLEAR
	IN	A,(PORTB)		;  GET ROWS
	CP	#0 			;  ANYTHING PRESSED?
	JR	NZ,KB_CLEAR_LOOP	;  YES, EXIT 
	LD	A,D			;  RESTORE A
	LD	D,#0x00			;
	LD	HL,#KB_DECODE		;  POINT TO BEGINNING OF TABLE	
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



;__KB_SCAN____________________________________________________________________________________________
;
;  SCAN KEYBOARD MATRIX FOR AN INPUT
;     
;____________________________________________________________________________________________________
KB_SCAN:

	LD      C,#0
	LD	A,#0x41			;  SCAN COL ONE
	OUT 	(PORTC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
	IN	A,(PORTB)		;  GET ROWS
	CP	#0x00 			;  ANYTHING PRESSED?
	JR	NZ,KB_SCAN_FOUND	;  YES, EXIT 

	LD      C,#0x0040
	LD	A,#0x42			;  SCAN COL TWO
	OUT 	(PORTC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
	IN	A,(PORTB)		;  GET ROWS
	CP	#0 			;  ANYTHING PRESSED?
	JR	NZ,KB_SCAN_FOUND	;  YES, EXIT 

	LD      C,#0x0080
	LD	A,#0x44			;  SCAN COL THREE
	OUT 	(PORTC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
	IN	A,(PORTB)		;  GET ROWS
	CP	#0x00 			;  ANYTHING PRESSED?
	JR	NZ,KB_SCAN_FOUND	;  YES, EXIT 

	LD      C,#0x00C0			;
	LD	A,#0x48			;  SCAN COL FOUR
	OUT 	(PORTC),A		;  SEND TO COLUMN LINES
        CALL    KB_SCAN_DELAY		;  DELAY TO ALLOW LINES TO STABILIZE
	IN	A,(PORTB)		;  GET ROWS
	CP	#0x00 			;  ANYTHING PRESSED?
	JR	NZ,KB_SCAN_FOUND	;  YES, EXIT 

	LD	A, #0x40			;  TURN OFF ALL COLUMNS
	OUT 	(PORTC),A		;  SEND TO COLUMN LINES
	LD	A, #0x00			;  RETURN NULL
	RET				;  EXIT

KB_SCAN_FOUND:
	AND	#0x3F			;  CLEAR TOP TWO BITS
	OR	C			;  ADD IN ROW BITS 
	LD	C,A			;  STORE VALUE
	LD	A,#0x00			;  TURN OFF ALL COLUMNS
	OUT 	(PORTC),A		;  SEND TO COLUMN LINES
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



;__HEXDISPLAY________________________________________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF IN DECODED HEX BITS 0-3 ARE DISPLAYED DIG, BIT 7 IS DP
;     
;____________________________________________________________________________________________________
HEXDISPLAY:
	PUSH	HL			; STORE HL
	PUSH	AF			; STORE AF
	PUSH	BC			; STORE BC
	LD	BC,#0007	
	ADD	HL,BC
	LD	B,#0x08			; SET DIGIT COUNT
	LD	A,#0x40			; SET CONTROL PORT 7218 TO OFF
	OUT	(PORTC),A		; OUTPUT
	CALL 	PAUSE			; WAIT
	LD	A,#0x0F0			; SET CONTROL TO 1111 (DATA COMING, HEX DECODE,NO DECODE, NORMAL)
	OUT	(PORTA),A		; OUTPUT TO PORT
	LD	A,#0x80			; STROBE WRITE PULSE WITH CONTROL=1
	OUT	(PORTC),A		; OUTPUT TO PORT
	CALL 	PAUSE			; WAIT
	LD	A,#0x40			; SET CONTROL PORT 7218 TO OFF
	OUT	(PORTC),A		; OUTPUT
HEXDISPLAY_LP:		
	LD	A,(HL)			; GET DISPLAY DIGIT
	CALL	DECODEDISPLAY		; DECODE DISPLAY
	OUT	(PORTA),A		; OUT TO PORTA
	LD	A,#0x00			; SET WRITE STROBE
	OUT	(PORTC),A		; OUT TO PORTC
	CALL	PAUSE			; DELAY
	LD	A,#0x40			; SET CONTROL PORT OFF
	OUT	(PORTC),A		; OUT TO PORTC
	CALL	PAUSE			; WAIT
	DEC	HL			; INC POINTER
	DJNZ	HEXDISPLAY_LP		; LOOP FOR NEXT DIGIT
	POP	BC			; RESTORE BC
	POP	AF			; RESTORE AF
	POP	HL			; RESTORE HL
	RET

;__DECODEDISPLAY_____________________________________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF IN DECODED HEX BITS 0-3 ARE DISPLAYED DIG, BIT 7 IS DP
;     
;____________________________________________________________________________________________________
DECODEDISPLAY:
	PUSH	BC			; STORE BC
	PUSH	HL			; STORE HL
	LD	HL,#SEGDECODE		; POINT HL TO DECODE TABLE
	LD	B,#0x00			; RESET HIGH BYTE
	LD	C,A			; CHAR INTO LOW BYTE
	ADD	HL,BC			; SET TABLE POINTER
	LD	A,(HL)			; GET VALUE
	POP	HL			; RESTORE HL
	POP	BC			; RESTORE BC
	RET


;__SEGDISPLAY________________________________________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF IN DECODED HEX BITS 0-3 ARE DISPLAYED DIG, BIT 7 IS DP
;     
;____________________________________________________________________________________________________
SEGDISPLAY:
	PUSH	AF			; STORE AF
	PUSH	BC			; STORE BC
	LD	BC,#0x0007	
	ADD	HL,BC
	LD	B,#0x08			; SET DIGIT COUNT
	LD	A,#0x40			; SET CONTROL PORT 7218 TO OFF
	OUT	(PORTC),A		; OUTPUT
	CALL 	PAUSE			; WAIT
	LD	A,#0x0F0			; SET CONTROL TO 1111 (DATA COMING, HEX DECODE,NO DECODE, NORMAL)
	OUT	(PORTA),A		; OUTPUT TO PORT
	LD	A,#0x80			; STROBE WRITE PULSE WITH CONTROL=1
	OUT	(PORTC),A		; OUTPUT TO PORT
	CALL 	PAUSE			; WAIT
	LD	A,#0x40			; SET CONTROL PORT 7218 TO OFF
	OUT	(PORTC),A		; OUTPUT
SEGDISPLAY_LP:		
	LD	A,(HL)			; GET DISPLAY DIGIT
	OUT	(PORTA),A		; OUT TO PORTA
	LD	A,#0x00			; SET WRITE STROBE
	OUT	(PORTC),A		; OUT TO PORTC
	CALL	PAUSE			; DELAY
	LD	A,#0x40			; SET CONTROL PORT OFF
	OUT	(PORTC),A		; OUT TO PORTC
	CALL	PAUSE			; WAIT
	DEC	HL			; INC POINTER
	DJNZ	SEGDISPLAY_LP		; LOOP FOR NEXT DIGIT
	POP	BC			; RESTORE BC
	POP	AF			; RESTORE AF
	RET

;
;__WORK_AREA___________________________________________________________________________________________________________________ 
;
;	RESERVED RAM FOR MONITOR WORKING AREA
;_____________________________________________________________________________________________________________________________
;
SER_BAUD:	.DS	1		; SPECIFY DESIRED UART COM RATE IN BPS
KEYBUF:  	.ascii   	"                                  "
		.ascii	"                                              "
DISPLAYBUF:	.DB 	00,00,00,00,00,00,00,00
IDEDEVICE:	.DB	1		; IDE DRIVE SELECT FLAG (00H=PRIAMRY, 10H = SECONDARY)
IDE_SECTOR_BUFFER:
		.DS	0x00200




;
;__TEXT_STRINGS_________________________________________________________________________________________________________________ 
;
;	SYSTEM TEXT STRINGS
;_____________________________________________________________________________________________________________________________
;
TCRLF:
	.DB  	CR,LF,ENDT

PROMPT:
	.DB  	CR,LF
	.ascii	">"
	.DB	ENDT

TXT_READY:
	.DB   CR,LF
	.ascii   "         NN      NN      8888      VV      VV    EEEEEEEEEE   MM          MM"
	.DB   CR,LF
	.ascii   "        NNNN    NN    88    88    VV      VV    EE           MMMM      MMMM"
	.DB   CR,LF
	.ascii   "       NN  NN  NN    88    88    VV      VV    EE           MM  MM  MM  MM"
	.DB   CR,LF
	.ascii   "      NN    NNNN    88    88    VV      VV    EE           MM    MM    MM"
	.DB   CR,LF
	.ascii   "     NN      NN      8888      VV      VV    EEEEEEE      MM          MM"
	.DB   CR,LF
	.ascii   "    NN      NN    88    88     VV    VV     EE           MM          MM"
	.DB   CR,LF
	.ascii   "   NN      NN    88    88      VV  VV      EE           MM          MM"
	.DB   CR,LF
	.ascii   "  NN      NN    88    88        VVV       EE           MM          MM"
	.DB   CR,LF
	.ascii   " NN      NN      8888           V        EEEEEEEEEE   MM          MM    S B C"
	.DB   CR,LF
	.DB   CR,LF                                                                                                                                                
	.ascii   " ****************************************************************************"
	.DB   CR,LF
	.ascii   "MONITOR READY "
	.DB   CR,LF,ENDT

TXT_COMMAND:
	.DB   CR,LF
	.ascii   "UNKNOWN COMMAND."
	.DB   ENDT

TXT_CKSUMERR:
	.DB   CR,LF
	.ascii   "CHECKSUM ERROR."
	.DB   ENDT
CPUUP:
	.DB 	0x084,0x0EE,0x0BB,0x080,0x0BB,0x0EE,0x0CB,0x084
ADDR:
	.DB 	0x00,0x00,0x00,0x00,0x08C,0x0BD,0x0BD,0x0FE


PORT:
	.DB 	0x00,0x00,0x80,0x80,0x094,0x08C,0x09D,0x0EE
SEC:
	.DB 	0x80,0x80,0x80,0x80,0x80,0x0CB,0x0CF,0x0D7


;_KB DECODE TABLE__________________________________________________________________________________________________________
; 
;
KB_DECODE:
;                0  1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	.DB	0x41,0x02,0x42,0x82,0x04,0x44,0x84,0x08,0x48,0x88,0x10,0x50,0x90,0x20,0x60,0x0A0
;               FW  BK  CL  EN  DP  EX  GO  BO
	.DB	0x01,0x81,0x0C1,0x0C2,0x0C4,0x0C8,0x0D0,0x0E0
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
;_________________________________________________________________________________________________________________________
;_HEX 7_SEG_DECODE_TABLE__________________________________________________________________________________________________
; 
; 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F, ,-
; AND WITH 7FH TO TURN ON DP 
;_________________________________________________________________________________________________________________________
SEGDECODE:
	.DB	0x0FB,0x0B0,0x0ED,0x0F5,0x0B6,0x0D7,0x0DF,0x0F0,0x0FF,0x0F7,0x0FE,0x09F,0x0CB,0x0BD,0x0CF,0x0CE,0x080,0x084,0x00,0x0EE,0x09D

;********************* END OF PROGRAM ***********************************

;dwg; .ORG	08FFFh
;dwg; .DB  	000h
;dwg; .END

_dbgmon_end::
	.area _CODE
	.area _CABS
