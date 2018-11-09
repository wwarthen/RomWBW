;
;==================================================================================================
; DSKY KEYBOARD ROUTINES
;==================================================================================================
;
PPIA		.EQU 	PPIBASE + 0	; PORT A
PPIB		.EQU 	PPIBASE + 1	; PORT B
PPIC		.EQU 	PPIBASE + 2	; PORT C
PPIX	 	.EQU 	PPIBASE + 3	; PPI CONTROL PORT

;
;    _____C0______C1______C2______C3__
;B5 |	$20 D	$60 E	$A0 F	$E0 BO
;B4 |	$10 A	$50 B	$90 C	$D0 GO
;B3 |	$08 7	$48 8	$88 9	$C8 EX
;B2 |	$04 4	$44 5	$84 6	$C4 DE
;B1 |	$02 1	$42 2	$82 3	$C2 EN
;B0 |	$01 FW	$41 0	$81 BK	$C1 CL
;
KY_0	.EQU	000H
KY_1	.EQU	001H
KY_2	.EQU	002H
KY_3	.EQU	003H
KY_4	.EQU	004H
KY_5	.EQU	005H
KY_6	.EQU	006H
KY_7	.EQU	007H
KY_8	.EQU	008H
KY_9	.EQU	009H
KY_A	.EQU	00AH
KY_B	.EQU	00BH
KY_C	.EQU	00CH
KY_D	.EQU	00DH
KY_E	.EQU	00EH
KY_F	.EQU	00FH
KY_FW	.EQU	010H	; FORWARD
KY_BK	.EQU	011H	; BACKWARD
KY_CL	.EQU	012H	; CLEAR
KY_EN	.EQU	013H	; ENTER
KY_DE	.EQU	014H	; DEPOSIT
KY_EX	.EQU	015H	; EXAMINE
KY_GO	.EQU	016H	; GO
KY_BO	.EQU	017H	; BOOT
;
;__DSKY_INIT_________________________________________________________________________________________
;
;  CHECK FOR KEY PRESS, SAVE RAW VALUE, RETURN STATUS
;____________________________________________________________________________________________________
;
DSKY_INIT:
	LD	A,82H
	OUT 	(PPIX),A
	LD	A,30H			;disable /CS on PPISD card(s)
	OUT	(PPIC),A
	XOR	A
	LD	(KY_BUF),A
	RET

#IFDEF DSKY_KBD
;
;__KY_STAT___________________________________________________________________________________________
;
;  CHECK FOR KEY PRESS, SAVE RAW VALUE, RETURN STATUS
;____________________________________________________________________________________________________
;
KY_STAT:
	; IF WE ALREADY HAVE A KEY, RETURN WITH NZ
	LD	A,(KY_BUF)
	OR	A
	RET	NZ
	; SCAN FOR A KEYPRESS, A=0 NO DATA OR A=RAW BYTE
	CALL	KY_SCAN			; SCAN KB ONCE
	OR	A			; SET FLAGS
	RET	Z			; NOTHING FOUND, GET OUT
	LD	(KY_BUF),A		; SAVE RAW KEYCODE
	RET				; RETURN
;
;__KY_GET____________________________________________________________________________________________
;
;  GET A SINGLE KEY (WAIT FOR ONE IF NECESSARY)
;____________________________________________________________________________________________________
;
KY_GET:
	; SEE IF WE ALREADY HAVE A KEY SAVED, GO TO DECODE IF SO
	LD	A,(KY_BUF)
	OR	A
	JR	NZ,KY_DECODE
	; NO KEY SAVED, WAIT FOR ONE
KY_STATLOOP:
	CALL	KY_STAT
	OR	A
	JR	Z,KY_STATLOOP
	; DECODE THE RAW VALUE
KY_DECODE:
	LD	D,00H
	LD	HL,KY_KEYMAP		; POINT TO BEGINNING OF TABLE
KY_GET_LOOP:
	CP	(HL)			; MATCH?
	JR	Z,KY_GET_DONE		; FOUND, DONE
	INC	HL
	INC	D			; D + 1
	JR	NZ,KY_GET_LOOP		; NOT FOUND, LOOP UNTIL EOT
KY_GET_DONE:
	; CLEAR OUT KEY_BUF
	XOR	A
	LD	(KY_BUF),A
	; RETURN THE INDEX POSITION WHERE THE RAW VALUE WAS FOUND
	LD	A,D
	RET
;
;__KY_SCAN____________________________________________________________________________________________
;
;  SCAN KEYBOARD MATRIX FOR AN INPUT
;____________________________________________________________________________________________________
;
KY_SCAN:
	LD	C,0000H
	LD	A,41H | 30H		;  SCAN COL ONE
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
	CALL	DLY2			;  DEBOUNCE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KY_SCAN_FOUND	;  YES, EXIT

	LD	C,0040H
	LD	A,42H | 30H		;  SCAN COL TWO
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES
	CALL	DLY2			;  DEBOUNCE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KY_SCAN_FOUND	;  YES, EXIT

	LD	C,0080H
	LD	A,44H | 30H		;  SCAN COL THREE
	OUT	(PPIC),A		;  SEND TO COLUMN LINES
	CALL	DLY2		;  DEBOUNCE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KY_SCAN_FOUND	;  YES, EXIT

	LD	C,00C0H			;
	LD	A,48H | 30H		;  SCAN COL FOUR
	OUT	(PPIC),A		;  SEND TO COLUMN LINES
	CALL	DLY2			;  DEBOUNCE
	IN	A,(PPIB)		;  GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			;  ANYTHING PRESSED?
	JR	NZ,KY_SCAN_FOUND	;  YES, EXIT

	LD	A,040H | 30H		;  TURN OFF ALL COLUMNS
	OUT	(PPIC),A		;  SEND TO COLUMN LINES
	LD	A,00H			;  RETURN NULL
	RET				;  EXIT

KY_SCAN_FOUND:
	AND	3FH			;  CLEAR TOP TWO BITS
	OR	C			;  ADD IN ROW BITS
	LD	C,A			;  STORE VALUE

	; WAIT FOR KEY TO BE RELEASED
	LD	A,4FH | 30H		; SCAN ALL COL LINES
	OUT	(PPIC),A		; SEND TO COLUMN LINES
	CALL	DLY2			; DEBOUNCE
KY_CLEAR_LOOP:				; WAIT FOR KEY TO CLEAR
	IN	A,(PPIB)		; GET ROWS
	AND	7FH			;ignore PB7 for PPISD
	CP	00H 			; ANYTHING PRESSED?
	JR	NZ,KY_CLEAR_LOOP	; YES, LOOP UNTIL KEY RELEASED

	LD	A,040H | 30H		;  TURN OFF ALL COLUMNS
	OUT 	(PPIC),A		;  SEND TO COLUMN LINES

	LD	A,C			;  RESTORE VALUE
	RET
;
;_KEYMAP_TABLE_____________________________________________________________________________________________________________
;
KY_KEYMAP:
;               0    1    2    3    4    5    6    7
	.DB	041H,002H,042H,082H,004H,044H,084H,008H
;               8    9    A    B    C    D    E    F
	.DB	048H,088H,010H,050H,090H,020H,060H,0A0H
;               FW   BK   CL   EN   DE   EX   GO   BO
	.DB	001H,081H,0C1H,0C2H,0C4H,0C8H,0D0H,0E0H
;
#ENDIF	; DSKY_KBD
;
;==================================================================================================
; DSKY HEX DISPLAY
;==================================================================================================
;
DSKY_HEXOUT:
	LD	B,DSKY_HEXBUFLEN
	LD	HL,DSKY_BUF
	LD	DE,DSKY_HEXBUF
DSKY_HEXOUT1:
	LD	A,(DE)			; FIRST NIBBLE
	SRL	A
	SRL	A
	SRL	A
	SRL	A
	LD	(HL),A
	INC	HL
	LD	A,(DE)			; SECOND NIBBLE
	AND	0FH
	LD	(HL),A
	INC	HL
	INC	DE			; NEXT BYTE
	DJNZ	DSKY_HEXOUT1
	LD	HL,DSKY_BUF
	JR	DSKY_SHOWHEX
;
;==================================================================================================
; DSKY SHOW BUFFER
;   HL: ADDRESS OF BUFFER
;   ENTER @ SHOWHEX FOR HEX DECODING
;   ENTER @ SHOWRAW FOR DIRECT SEGMENT DECODING
;==================================================================================================
;
DSKY_SHOWHEX:
	LD	A,$D0			; 7218 -> (DATA COMING, HEXA DECODE)
	JR	DSKY_SHOW

DSKY_SHOWRAW:
	LD	A,$F0			; 7218 -> (DATA COMING, NO DECODE)
	JR	DSKY_SHOW

DSKY_SHOW:
	PUSH	AF			; SAVE 7218 CONTROL BITS
	LD	A,82H			; SETUP PPI
	OUT	(PPIX),A
	CALL	DSKY_COFF
	POP	AF
	OUT	(PPIA),A
	CALL	DSKY_STROBEC
	LD	B,DSKY_BUFLEN		; NUMBER OF DIGITS
	LD	C,PPIA
DSKY_HEXOUT2:
	OUTI
	JP	Z,DSKY_STROBE		; DO FINAL STROBE AND RETURN
	CALL	DSKY_STROBE
	JR	DSKY_HEXOUT2

DSKY_STROBEC:
	LD	A,80H | 30H
	JP	DSKY_STROBE0

DSKY_STROBE:
	LD	A,00H | 30H		; SET WRITE STROBE

DSKY_STROBE0:
	OUT	(PPIC),A		; OUT TO PORTC
	CALL	DLY2			; DELAY
DSKY_COFF
	LD	A,40H | 30H		; SET CONTROL PORT OFF
	OUT	(PPIC),A		; OUT TO PORTC
;	CALL	DSKY_DELAY		; WAIT
	RET
;
;
;
KY_BUF		.DB	0
DSKY_BUF:	.FILL	8,0
DSKY_BUFLEN	.EQU	$ - DSKY_BUF
DSKY_HEXBUF	.FILL	4,0
DSKY_HEXBUFLEN	.EQU	$ - DSKY_HEXBUF
