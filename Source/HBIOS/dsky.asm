;
;==================================================================================================
; DSKY (DISPLAY AND KEYBOARD) ROUTINES 
;==================================================================================================
;
; THE DSKY MAY COINCIDE ON THE SAME PPI BUS AS A PPISD.  IT MAY NOT
; SHARE A PPI BUS WITH A PPIDE.  SEE PPI_BUS.TXT FOR MORE INFORMATION.
;
; LED SEGMENTS (BIT VALUES)
;
;	+--40--+
;	02    20
;	+--04--+
;	08    10
;	+--01--+  80
;
; DSKY SCAN CODES ARE ONE BYTE: CCRRRRRR
; BITS 7-6 IDENTFY THE COLUMN OF THE KEY PRESSED
; BITS 5-0 ARE A BITMAP, WITH A BIT ON TO INDICATE ROW OF KEY PRESSED
;
;      ____PC0________PC1________PC2________PC3____
; PB5 |	 $20 [D]    $60 [E]    $A0 [F]	  $E0 [BO]
; PB4 |	 $10 [A]    $50 [B]    $90 [C]	  $D0 [GO]
; PB3 |	 $08 [7]    $48 [8]    $88 [9]	  $C8 [EX]
; PB2 |	 $04 [4]    $44 [5]    $84 [6]	  $C4 [DE]
; PB1 |	 $02 [1]    $42 [2]    $82 [3]	  $C2 [EN]
; PB0 |	 $01 [FW]   $41 [0]    $81 [BK]	  $C1 [CL]
;
;
PPIA		.EQU 	DSKYPPIBASE + 0	; PORT A
PPIB		.EQU 	DSKYPPIBASE + 1	; PORT B
PPIC		.EQU 	DSKYPPIBASE + 2	; PORT C
PPIX	 	.EQU 	DSKYPPIBASE + 3	; PPI CONTROL PORT
;
;__DSKY_INIT_________________________________________________________________________________________
;
;  CONFIGURE PARALLEL PORT AND CLEAR KEYPAD BUFFER
;____________________________________________________________________________________________________
;
DSKY_PREINIT:
	OR	$FF			; SIGNAL TO WAIT FOR KEY RELEASE
	LD	(DSKY_KEYBUF),A		; SET IT
;
	; PPI PORT B IS NORMALLY SET TO INPUT, BUT HERE WE
	; TEMPORARILY SET IT TO OUTPUT.  WHILE IN OUTPUT MODE, WE
	; WRITE A VALUE OF $FF WHICH WILL BE PERSISTED BY THE PPI
	; CHIP BUS HOLD CIRCUIT IF THERE IS NO DSKY PRESENT.  SO,
	; WE CAN SUBSEQUENTLY TEST FOR PPIB=$FF TO SEE IF THERE IS
	; NO DSKY AND PREVENT PROBLEMS WITH PHANTOM DSKY KEY PRESSES.
	; IF A DSKY IS PRESENT, IT WILL SIMPLY OVERPOWER THE PPI
	; BUS HOLD CIRCUIT.
	LD	A,$80			; PA OUT, PB OUT, PC OUT
	OUT	(PPIX),A
	LD	A,$FF			; SET PPIB=$FF, BUS HOLD
	OUT	(PPIB),A
;
	LD	A,$82			; PA OUT, PB IN, PC OUT
	OUT 	(PPIX),A
;
	;IN	A,(PPIB)		; *DEBUG*
	;CALL	PRTHEXBYTE		; *DEBUG*
;
	IN	A,(PPIB)		; READ PPIB
	XOR	$FF			; INVERT RESULT
	LD	(DSKY_PRESENT),A	; SAVE AS PRESENT FLAG
;
DSKY_RESET:
	PUSH	AF
;
	LD	A,$70			; PPISD AND 7218 INACTIVE
	OUT	(PPIC),A
;
	POP	AF
	RET
;
#IFDEF HBIOS
;
DSKY_INIT:
	CALL	NEWLINE			; FORMATTING
	PRTS("DSKY:$")			; FORMATTING
;
	PRTS(" IO=0x$")			; FORMATTING
	LD	A,DSKYPPIBASE		; GET BASE PORT
	CALL	PRTHEXBYTE		; PRINT BASE PORT
	PRTS(" MODE=$")			; FORMATTING
	PRTS("V1$")			; PRINT DSKY TYPE
;
	LD	A,(DSKY_PRESENT)	; PRESENT?
	OR	A			; SET FLAGS
	RET	NZ			; YES, ALL DONE
	PRTS(" NOT PRESENT$")		; NOT PRESENT
;
	RET
;
#ENDIF
;
#IFDEF DSKY_KBD
;
KY_0	.EQU	$00
KY_1	.EQU	$01
KY_2	.EQU	$02
KY_3	.EQU	$03
KY_4	.EQU	$04
KY_5	.EQU	$05
KY_6	.EQU	$06
KY_7	.EQU	$07
KY_8	.EQU	$08
KY_9	.EQU	$09
KY_A	.EQU	$0A
KY_B	.EQU	$0B
KY_C	.EQU	$0C
KY_D	.EQU	$0D
KY_E	.EQU	$0E
KY_F	.EQU	$0F
KY_FW	.EQU	$10	; FORWARD
KY_BK	.EQU	$11	; BACKWARD
KY_CL	.EQU	$12	; CLEAR
KY_EN	.EQU	$13	; ENTER
KY_DE	.EQU	$14	; DEPOSIT
KY_EX	.EQU	$15	; EXAMINE
KY_GO	.EQU	$16	; GO
KY_BO	.EQU	$17	; BOOT
;
;__DSKY_GETKEY_____________________________________________________________________________________
;
;  WAIT FOR A DSKY KEYPRESS AND RETURN
;____________________________________________________________________________________________________
;
DSKY_GETKEY:
	LD	A,(DSKY_PRESENT)	; DOES IT EXIST?
	OR	A			; SET FLAGS
	JR	Z,DSKY_GETKEY1A		; ABORT IF NOT PRESENT
;
	CALL	DSKY_STAT		; CHECK STATUS
	JR	Z,DSKY_GETKEY		; LOOP IF NOTHING READY
	LD	A,(DSKY_KEYBUF)
	LD	B,24			; SIZE OF DECODE TABLE
	LD	C,0			; INDEX
	LD	HL,DSKY_KEYMAP		; POINT TO BEGINNING OF TABLE
DSKY_GETKEY1:
	CP	(HL)			; MATCH?
	JR	Z,DSKY_GETKEY2		; FOUND, DONE
	INC	HL
	INC	C			; BUMP INDEX
	DJNZ	DSKY_GETKEY1		; LOOP UNTIL EOT
DSKY_GETKEY1A:
	LD	A,$FF			; NOT FOUND ERR, RETURN $FF
	RET
DSKY_GETKEY2:
	LD	A,$FF			; SET KEY BUF TO $FF
	LD	(DSKY_KEYBUF),A		; DO IT
	; RETURN THE INDEX POSITION WHERE THE SCAN CODE WAS FOUND
	LD	A,C			; RETURN INDEX VALUE
	RET
;
;__DSKY_STAT_________________________________________________________________________________________
;
;  CHECK FOR KEY PRESS, SAVE RAW VALUE, RETURN STATUS
;____________________________________________________________________________________________________
;
DSKY_STAT:
	LD	A,(DSKY_PRESENT)	; DOES IT EXIST?
	OR	A			; SET FLAGS
	RET	Z			; ABORT WITH A=0 IF NOT THERE
;
	LD	A,(DSKY_KEYBUF)		; GET CURRENT BUF VAL
	CP	$FF			; $FF MEANS WE ARE WAITING FOR PREV KEY TO BE RELEASED
	JR	Z,DSKY_STAT1		; CHECK FOR PREV KEY RELEASE
	OR	A			; DO WE HAVE A SCAN CODE BUFFERED ALREADY?
	RET	NZ			; IF SO, WE ARE DONE
	JR	DSKY_STAT2		; OTHERWISE, DO KEY CHECK
	
DSKY_STAT1:
	; WAITING FOR PREVIOUS KEY RELEASE
	CALL	DSKY_KEY		; SCAN
	JR	Z,DSKY_STAT2		; IF ZERO, PREV KEY RELEASED, CONTINUE
	XOR	A			; SIGNAL NO KEY PRESSED
	RET				; AND DONE

DSKY_STAT2:
	CALL	DSKY_KEY		; SCAN
	LD	(DSKY_KEYBUF),A		; SAVE RESULT
	RET				; RETURN WITH ZF SET APPROPRIATELY
;
;__DSKY_KEY_______________________________________________________________________________________
;
;  CHECK FOR KEY PRESS W/ DEBOUNCE
;____________________________________________________________________________________________________
;
DSKY_KEY:
	; IF PPIB VALUE IS $FF, THERE IS NO DSKY, SEE DSKY_INIT
	IN	A,(PPIB)
	INC	A
	RET	Z

	CALL	DSKY_SCAN		; INITIAL KEY PRESS SCAN
	LD	E,A			; SAVE INITIAL SCAN VALUE
DSKY_KEY1:
	; MAX BOUNCE TIME FOR OMRON B3F IS 3MS
	PUSH	DE			; SAVE DE
	LD	DE,300			; ~3MS DELAY
	CALL	VDELAY			; DO IT
	CALL	DSKY_SCAN		; REPEAT SCAN
	POP	DE			; RESTORE DE
	RET	Z			; IF NOTHING PRESSED, DONE
	CP	E			; SAME?
	JR	DSKY_KEY2		; YES, READY TO RETURN
	LD	E,A			; OTHERWISE, SAVE NEW SCAN VAL
	JR	DSKY_KEY1		; AND LOOP UNTIL STABLE VALUE
DSKY_KEY2:
	OR	A			; SET FLAGS BASED ON VALUE
	RET				; AND DONE
;
;__DSKY_SCAN______________________________________________________________________________________
;
;  SCAN KEYPAD AND RETURN RAW SCAN CODE (RETURNS ZERO IF NO KEY PRESSED)
;____________________________________________________________________________________________________
;
DSKY_SCAN:
	LD	B,4			; 4 COLUMNS
	LD	C,$01			; FIRST COLUMN
	LD	E,0			; INITIAL COL ID
DSKY_SCAN1:
	LD	A,C			; COL TO A
	OR	$70			; KEEP PPISD AND 7218 INACTIVE
	OUT	(PPIC),A		; ACTIVATE COL
	IN	A,(PPIB)		; READ ROW BITS
	AND	$3F			; MASK, WE ONLY HAVE 6 ROWS, OTHERS UNDEFINED
	JR	NZ,DSKY_SCAN2		; IF NOT ZERO, GOT SOMETHING
	RLC	C			; NEXT COL
	INC	E			; BUMP COL ID
	DJNZ	DSKY_SCAN1		; LOOP THROUGH ALL COLS
	XOR	A			; NOTHING FOUND, RETURN ZERO
	JP	DSKY_RESET		; RETURN VIA RESET
DSKY_SCAN2:
	RRC	E			; MOVE COL ID
	RRC	E			; ... TO HIGH BITS 6 & 7
	OR	E			; COMBINE WITH ROW
	JP	DSKY_RESET		; RETURN VIA RESET
;
;_KEYMAP_TABLE_____________________________________________________________________________________________________________
;
DSKY_KEYMAP:
	; POS	$00  $01  $02  $03  $04  $05  $06  $07
	; KEY   [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]
	.DB	$41, $02, $42, $82, $04, $44, $84, $08
;                                                  
	; POS	$08  $09  $0A  $0B  $0C  $0D  $0E  $0F
	; KEY   [8]  [9]  [A]  [B]  [C]  [D]  [E]  [F]
	.DB	$48, $88, $10, $50, $90, $20, $60, $A0
;                                                  
	; POS	$10  $11  $12  $13  $14  $15  $16  $17
	; KEY   [FW] [BK] [CL] [EN] [DE] [EX] [GO] [BO]
	.DB	$01, $81, $C1, $C2, $C4, $C8, $D0, $E0
;
; KBD WORKING STORAGE
;
DSKY_KEYBUF	.DB	0
;
#ENDIF	; DSKY_KBD
;
;==================================================================================================
; CONVERT 32 BIT BINARY TO 8 BYTE HEX SEGMENT DISPLAY
;==================================================================================================
;
; HL: ADR OF 32 BIT BINARY
; DE: ADR OF DEST LED SEGMENT DISPLAY BUFFER (8 BYTES)
;
DSKY_BIN2SEG:
	PUSH	HL
	PUSH	DE
	LD	B,4			; 4 BYTES OF INPUT
	EX	DE,HL
DSKY_BIN2SEG1:
	LD	A,(DE)			; FIRST NIBBLE
	SRL	A
	SRL	A
	SRL	A
	SRL	A
	PUSH	HL
	LD	HL,DSKY_HEXMAP
	CALL	DSKY_ADDHLA
	LD	A,(HL)
	POP	HL
	LD	(HL),A
	INC	HL
	LD	A,(DE)			; SECOND NIBBLE
	AND	0FH
	PUSH	HL
	LD	HL,DSKY_HEXMAP
	CALL	DSKY_ADDHLA
	LD	A,(HL)
	POP	HL
	LD	(HL),A
	INC	HL
	INC	DE			; NEXT BYTE
	DJNZ	DSKY_BIN2SEG1
	POP	DE
	POP	HL
	RET
;
;==================================================================================================
; DSKY SHOW BUFFER
;   HL: ADDRESS OF BUFFER
;==================================================================================================
;
DSKY_SHOW:
	;;PUSH	AF			; SAVE 7218 CONTROL BITS
	LD	A,82H			; SETUP PPI
	OUT	(PPIX),A
	CALL	DSKY_COFF
	;;POP	AF
	LD	A,$F0			; 7218 -> (DATA COMING, NO DECODE)
	OUT	(PPIA),A
	CALL	DSKY_STROBEC		; STROBE COMMAND
	LD	B,DSKY_BUFLEN		; NUMBER OF DIGITS
	LD	C,PPIA
DSKY_HEXOUT2:
	;OUTI
	LD	A,(HL)
	XOR	$80			; FIX DOT POLARITY
	OUT	(C),A
	INC	HL
	DEC	B
	JP	Z,DSKY_STROBE		; DO FINAL STROBE AND RETURN
	CALL	DSKY_STROBE		; STROBE BYTE VALUE
	JR	DSKY_HEXOUT2
DSKY_STROBEC:	; COMMAND STROBE
	LD	A,80H | 30H
	JP	DSKY_STROBE0
DSKY_STROBE:	; DATA STROBE
	LD	A,00H | 30H		; SET WRITE STROBE
DSKY_STROBE0:
	OUT	(PPIC),A		; OUT TO PORTC
	CALL	DLY2			; DELAY
DSKY_COFF:
	LD	A,40H | 30H		; QUIESCE
	OUT	(PPIC),A		; OUT TO PORTC
;	CALL	DSKY_DELAY		; WAIT
	RET
;
;==================================================================================================
; UTILTITY FUNCTIONS
;==================================================================================================
;
DSKY_ADDHLA:
	ADD	A,L
	LD	L,A
	RET	NC
	INC	H
	RET
;
;==================================================================================================
; STORAGE
;==================================================================================================
;
; CODES FOR NUMERICS
; HIGH BIT ALWAYS CLEAR TO SUPPRESS DECIMAL POINT
; SET HIGH BIT TO SHOW DECIMAL POINT
;
DSKY_HEXMAP:
	.DB	$7B	; 0
	.DB	$30	; 1
	.DB	$6D	; 2
	.DB	$75	; 3
	.DB	$36	; 4
	.DB	$57	; 5
	.DB	$5F	; 6
	.DB	$70	; 7
	.DB	$7F	; 8
	.DB	$77	; 9
	.DB	$7E	; A
	.DB	$1F	; B
	.DB	$4B	; C
	.DB	$3D	; D
	.DB	$4F	; E
	.DB	$4E	; F
;
; SEG DISPLAY WORKING STORAGE
;
DSKY_PRESENT	.DB	0
;
DSKY_BUF	.FILL	8,0
DSKY_BUFLEN	.EQU	$ - DSKY_BUF
DSKY_HEXBUF	.FILL	4,0
DSKY_HEXBUFLEN	.EQU	$ - DSKY_HEXBUF
