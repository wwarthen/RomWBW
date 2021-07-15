;
;==================================================================================================
; DSKY NEXT GEN ROUTINES
;==================================================================================================
;
; A DSKYNG CAN SHARE A PPI BUS WITH EITHER A PPIDE OR PPISD.
;
; LED SEGMENTS (BIT VALUES)
;
;	+--01--+
;	20    02
;	+--40--+
;	10    04
;	+--08--+  80
;
; KEY CODE MAP (KEY CODES) CSCCCRRR
;                          ||||||||
;                          |||||+++-- ROW
;                          ||+++----- COL
;                          |+-------- SHIFT
;                          +--------- CONTROL
;
;	00	08	10	18	23
;	01	09	11	19	22
;	02	0A	12	1A	21
;	03	0B	13	1B	20
;	04	0C	14	1C	SHIFT
;	05	0D	15	1D	CTRL
;
; LED BIT MAP (BIT VALUES)
;
;	$08	$09	$0A	$0B	$0C	$0D	$0E	$0F
;	---	---	---	---	---	---	---	---
;	01	01	01	01	01
;	02	02	02	02	02
;	04      04      04      04	04
;	08      08      08      08	08
;	10      10      10      10	10
;	20      20      20      20	20	L1	L2 	BUZZ
;
PPIA		.EQU 	DSKYPPIBASE + 0	; PORT A
PPIB		.EQU 	DSKYPPIBASE + 1	; PORT B
PPIC		.EQU 	DSKYPPIBASE + 2	; PORT C
PPIX	 	.EQU 	DSKYPPIBASE + 3	; PPI CONTROL PORT
;
DSKY_PPIX_RD:	.EQU	%10010010	; PPIX VALUE FOR READS
DSKY_PPIX_WR:	.EQU	%10000010	; PPIX VALUE FOR WRITES
;
; PIO CHANNEL C:
;
;	7	6	5	4	3	2	1	0
;	RES	0	0	CS	CS	/RD	/WR	A0
;
; SETTING BITS 3 & 4 WILL ASSERT /CS ON 3279
; CLEAR BITS 1 OR 2 TO ASSERT READ/WRITE
;
DSKY_PPI_IDLE:	.EQU	%00000110
;
DSKY_CMD_CLR:	.EQU	%11011111	; CLEAR (ALL OFF)
DSKY_CMD_CLRX:	.EQU	%11010011	; CLEAR (ALL ON)
DSKY_CMD_WDSP:	.EQU	%10010000	; WRITE DISPLAY RAM
DSKY_CMD_RDSP:	.EQU	%01110000	; READ DISPLAY RAM
DSKY_CMD_CLK:	.EQU	%00100000	; SET CLK PRESCALE
DSKY_CMD_FIFO:	.EQU	%01000000	; READ FIFO
;
DSKY_PRESCL:	.EQU	DSKYOSC/100000	; PRESCALER
;
;__DSKY_INIT_________________________________________________________________________________________
;
;  CONFIGURE PARALLEL PORT AND INITIALIZE 8279
;____________________________________________________________________________________________________
;
;
; HARDWARE RESET 8279 BY PULSING RESET LINE
;
DSKY_INIT:
;
	; SETUP PPI
	CALL	DSKY_PPIRD
	; INIT 8279 VALUES TO IDLE STATE
	LD	A,DSKY_PPI_IDLE
	OUT	(PPIC),A
	; PULSE RESET SIGNAL ON 8279
	SET	7,A
	OUT	(PPIC),A
	RES	7,A
	OUT	(PPIC),A
	; DONE
;
DSKY_REINIT:
	CALL	DSKY_PPIIDLE
	; SET CLOCK SCALER TO 20
	LD	A,DSKY_CMD_CLK | DSKY_PRESCL
	CALL	DSKY_CMD
	; FALL THRU
;
DSKY_RESET:
	; RESET DSKY
	LD	A,DSKY_CMD_CLR
	CALL	DSKY_CMD
	RET
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
KY_F4	.EQU	$18	; F4
KY_F3	.EQU	$19	; F3
KY_F2	.EQU	$20	; F2
KY_F1	.EQU	$21	; F1
;
;__DSKY_STAT_________________________________________________________________________________________
;
;  CHECK FOR KEY PRESS, SAVE RAW VALUE, RETURN STATUS
;____________________________________________________________________________________________________
;
DSKY_STAT:
	CALL	DSKY_ST
	AND	$0F			; ISOLATE THE CUR FIFO LEN
	RET
;
;__DSKY_GETKEY_____________________________________________________________________________________
;
;  WAIT FOR A DSKY KEYPRESS AND RETURN
;____________________________________________________________________________________________________
;
DSKY_GETKEY:
	CALL	DSKY_STAT
	JR	Z,DSKY_GETKEY		; LOOP IF NOTHING THERE
	LD	A,DSKY_CMD_FIFO
	CALL	DSKY_CMD
	CALL	DSKY_DIN
	XOR	%11000000		; FLIP POLARITY OF SHIFT/CTL BITS
	PUSH	AF			; SAVE VALUE
	AND	$3F			; STRIP SHIFT/CTL BITS FOR LOOKUP
	LD	B,28			; SIZE OF DECODE TABLE
	LD	C,0			; INDEX
	LD	HL,DSKY_KEYMAP		; POINT TO BEGINNING OF TABLE
DSKY_GETKEY1:
	CP	(HL)			; MATCH?
	JR	Z,DSKY_GETKEY2		; FOUND, DONE
	INC	HL
	INC	C			; BUMP INDEX
	DJNZ	DSKY_GETKEY1		; LOOP UNTIL EOT
	POP	AF			; FIX STACK
	LD	A,$FF			; NOT FOUND ERR, RETURN $FF
	RET
DSKY_GETKEY2:
	; RETURN THE INDEX POSITION WHERE THE SCAN CODE WAS FOUND
	; THE ORIGINAL SHIFT/CTRL BITS ARE RESTORED
	POP	AF			; RESTORE RAW VALUE
	AND	%11000000		; ISOLATE SHIFT/CTRL BITS
	OR	C			; COMBINE WITH INDEX VALUE
	RET
;
;_KEYMAP_TABLE_____________________________________________________________________________________________________________
;
DSKY_KEYMAP:
	; POS	$00  $01  $02  $03  $04  $05  $06  $07
	; KEY   [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]
	.DB	$0D, $04, $0C, $14, $03, $0B, $13, $02
;
	; POS	$08  $09  $0A  $0B  $0C  $0D  $0E  $0F
	; KEY   [8]  [9]  [A]  [B]  [C]  [D]  [E]  [F]
	.DB	$0A, $12, $01, $09, $11, $00, $08, $10
;
	; POS	$10  $11  $12  $13  $14  $15  $16  $17
	; KEY   [FW] [BK] [CL] [EN] [DE] [EX] [GO] [BO]
	.DB	$05, $15, $1D, $1C, $1B, $1A, $19, $18

	; POS	$18  $19  $20  $21
	; KEY   [F4] [F3] [F2] [F1]
	.DB	$23, $22, $21, $20

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
	PUSH	HL
	LD	HL,HEXMAP
	CALL	DSKY_ADDHLA
	LD	A,(HL)
	POP	HL
	LD	(HL),A
	INC	HL
	LD	A,(DE)			; SECOND NIBBLE
	AND	0FH
	PUSH	HL
	LD	HL,HEXMAP
	CALL	DSKY_ADDHLA
	LD	A,(HL)
	POP	HL
	LD	(HL),A
	INC	HL
	INC	DE			; NEXT BYTE
	DJNZ	DSKY_HEXOUT1
	LD	HL,DSKY_BUF
	JR	DSKY_SHOW
;
;==================================================================================================
; DSKY SHOW BUFFER
;   HL: ADDRESS OF BUFFER
;   ENTER @ SHOWHEX FOR HEX DECODING
;   ENTER @ SHOWSEG FOR SEGMENT DECODING
;==================================================================================================
;
DSKY_SHOWHEX:
	JR	DSKY_SHOW
;
DSKY_SHOWSEG:
	JR	DSKY_SHOW
;
DSKY_SHOW:
;	PUSH	HL
;	CALL	DSKY_RESET
;	POP	HL
	LD	C,0			; STARTING DISPLAY POSITION
	LD	B,DSKY_BUFLEN		; NUMBER OF CHARS
	JP	DSKY_PUTSTR
;
;
;
;
; COMMAND IN A
; TRASHES BC
;
DSKY_CMD:
	LD	B,$01
	JR	DSKY_DOUT2
;
; DATA VALUE IN A
; TRASHES BC
;
DSKY_DOUT:
	LD	B,$00
;
DSKY_DOUT2:
;
	; SAVE INCOMING DATA BYTE
	PUSH	AF
;
	; SET PPI LINE CONFIG TO WRITE MODE
	CALL	DSKY_PPIWR
;
	; SETUP
	LD	C,PPIC
;
	; SET ADDRESS FIRST
	LD	A,DSKY_PPI_IDLE
	OR	B
	OUT	(C),A
;
	; ASSERT 8279 /CS
	SET	3,A
	SET	4,A
	OUT	(C),A
;
	; PPIC WORKING VALUE TO REG B NOW
	LD	B,A
;
	; ASSERT DATA BYTE VALUE
	POP	AF
	OUT	(PPIA),A
;
	; PULSE /WR
	RES	1,B
	OUT	(C),B
	NOP			; MAY NOT BE NEEDED
	SET	1,B
	OUT	(C),B
;
	; DEASSERT /CS
	RES	3,B
	RES	4,B
	OUT	(C),B
;
	; CLEAR ADDRESS BIT
	RES	0,B
	OUT	(C),B
;
	; DONE
	CALL	DSKY_PPIIDLE
	RET
;
; STATUS VALUE IN A
; TRASHES BC
;
DSKY_ST:
	LD	B,$01
	JR	DSKY_DIN2
;
; DATA VALUE RETURNED IN A
; TRASHES BC
;
DSKY_DIN:
	LD	B,$00
;
DSKY_DIN2:
	; SET PPI LINE CONFIG TO WRITE MODE
	CALL	DSKY_PPIRD
;
	; SETUP
	LD	C,PPIC
;
	; SET ADDRESS FIRST
	LD	A,DSKY_PPI_IDLE
	OR	B
	OUT	(C),A
;
	; ASSERT 8279 /CS
	SET	3,A
	SET	4,A
	OUT	(C),A
;
	; PPIC WORKING VALUE TO REG B NOW
	LD	B,A
;
	; ASSERT /RD
	RES	2,B
	OUT	(C),B
;
	; GET VALUE
	IN	A,(PPIA)
;
	; DEASSERT /RD
	SET	2,B
	OUT	(C),B
;
	; DEASSERT /CS
	RES	3,B
	RES	4,B
	OUT	(C),B
;
	; CLEAR ADDRESS BIT
	RES	0,B
	OUT	(C),B
;
	; DONE
	CALL	DSKY_PPIIDLE
	RET
;
; BLANK THE DISPLAY (WITHOUT USING CLEAR)
;
DSKY_BLANK:
	LD	A,DSKY_CMD_WDSP
	CALL	DSKY_CMD
	LD	B,16
DSKY_BLANK1:
	PUSH	BC
	LD	A,$FF
	CALL	DSKY_DOUT
	POP	BC
	DJNZ	DSKY_BLANK1
	RET
;
; WRITE A RAW BYTE VALUE TO DSKY DISPLAY RAM
; AT LOCATION IN REGISTER C, VALUE IN A.
;
DSKY_PUTBYTE:
	PUSH	BC
	PUSH	AF
	LD	A,C
	ADD	A,DSKY_CMD_WDSP
	CALL	DSKY_CMD
	POP	AF
	XOR	$FF
	CALL	DSKY_DOUT
	POP	BC
	RET
;
; READ A RAW BYTE VALUE FROM DSKY DISPLAY RAM
; AT LOCATION IN REGISTER C, VALUE RETURNED IN A
;
DSKY_GETBYTE:
	PUSH	BC
	LD	A,C
	ADD	A,DSKY_CMD_RDSP
	CALL	DSKY_CMD
	CALL	DSKY_DIN
	XOR	$FF
	POP	BC
	RET
;
; WRITE A STRING OF RAW BYTE VALUES TO DSKY DISPLAY RAM
; AT LOCATION IN REGISTER C, LENGTH IN B, ADDRESS IN HL.
;
DSKY_PUTSTR:
	PUSH	BC
	LD	A,C
	ADD	A,DSKY_CMD_WDSP
	CALL	DSKY_CMD
	POP	BC
;
DSKY_PUTSTR1:
	LD	A,(HL)
	XOR	$FF
	INC	HL
	PUSH	BC
	CALL	DSKY_DOUT
	POP	BC
	DJNZ	DSKY_PUTSTR1
	RET
;
; READ A STRING OF RAW BYTE VALUES FROM DSKY DISPLAY RAM
; AT LOCATION IN REGISTER C, LENGTH IN B, ADDRESS IN HL.
;
DSKY_GETSTR:
	PUSH	BC
	LD	A,C
	ADD	A,DSKY_CMD_RDSP
	CALL	DSKY_CMD
	POP	BC
;
DSKY_GETSTR1:
	PUSH	BC
	CALL	DSKY_DIN
	POP	BC
	XOR	$FF
	LD	(HL),A
	INC	HL
	DJNZ	DSKY_GETSTR1
	RET
;
; HL IS ADR OF ENCODED STRING OF BYTES
; B IS LEN OF STRING (BYTES)
; C IS POSITION IN DISPLAY RAM TO WRITE
;
DSKY_PUTENCSTR:
	PUSH	BC
	LD	A,C
	ADD	A,DSKY_CMD_WDSP
	CALL	DSKY_CMD
	POP	BC
	EX	DE,HL
DSKY_PUTENCSTR1:
	LD	A,(DE)
	INC	DE
	LD	HL,HEXMAP
	CALL	DSKY_ADDHLA
	LD	A,(HL)
	XOR	$FF
	PUSH	BC
	CALL	DSKY_DOUT
	POP	BC
	DJNZ	DSKY_PUTENCSTR1
	RET

;
;	This function is intended to update the LEDs.  It expects 8 bytes following the call, and
;	updates the entire matrix.
;
;  EXAMPLE:
;	CALL 	DSKY_PUTLED
;	.DB 	$00,$00,$00,$00,$00,$00,$00,$00
;
;
DSKY_PUTLED:
        EX	(SP),HL
	PUSH	AF
	PUSH	BC
	LD 	C,8
DSKY_PUTLED_1:
	LD 	A,(HL)
	PUSH 	BC
	CALL	DSKY_PUTBYTE
	POP 	BC
	INC 	C
	INC	HL
	LD 	A,C
	CP	$10
	JP 	NZ,DSKY_PUTLED_1
	POP	BC
        POP	AF
	EX	(SP),HL
	RET

;
;	This function is intended to beep the speaker on the DSKY
;
;
DSKY_BEEP:
	PUSH	AF
	PUSH	BC

	LD 	C,$0F
	CALL	DSKY_GETBYTE
	or 	$20
	LD 	C,$0F
	CALL	DSKY_PUTBYTE

;;; 	timer . . .
	PUSH	HL
	ld 	hl,$8FFF
DSKY_BEEP1:
	dec 	hl
	ld 	a,H
	cp 	0
	jp 	nz,DSKY_BEEP1
	pop 	hl

	LD 	C,$0F
	CALL	DSKY_GETBYTE
	and  	$DF
	LD 	C,$0F
	CALL	DSKY_PUTBYTE

	POP	BC
        POP	AF
	RET

;
;	This function is intended to turn on DSKY L1
;
DSKY_L1ON:
	PUSH	AF
	PUSH	BC

	LD 	C,$0D
	CALL	DSKY_GETBYTE
	or 	$20
	LD 	C,$0D
	CALL	DSKY_PUTBYTE

	POP	BC
        POP	AF
	RET

;
;	This function is intended to turn on DSKY L2
;
DSKY_L2ON:
	PUSH	AF
	PUSH	BC

	LD 	C,$0E
	CALL	DSKY_GETBYTE
	or 	$20
	LD 	C,$0E
	CALL	DSKY_PUTBYTE

	POP	BC
        POP	AF
	RET

;
;	This function is intended to turn off DSKY L1
;
DSKY_L1OFF:
	PUSH	AF
	PUSH	BC

	LD 	C,$0D
	CALL	DSKY_GETBYTE
	and 	$DF
	LD 	C,$0D
	CALL	DSKY_PUTBYTE

	POP	BC
        POP	AF
	RET

;
;	This function is intended to turn off DSKY L2
;
DSKY_L2OFF:
	PUSH	AF
	PUSH	BC

	LD 	C,$0E
	CALL	DSKY_GETBYTE
	and 	$DF
	LD 	C,$0E
	CALL	DSKY_PUTBYTE

	POP	BC
        POP	AF
	RET



;
; SETUP PPI FOR WRITING: PUT PPI PORT A IN OUTPUT MODE
; AVOID REWRTING PPIX IF ALREADY IN OUTPUT MODE
;
DSKY_PPIWR:
	PUSH	AF
;
	; CHECK FOR WRITE MODE
	LD	A,(DSKY_PPIX_VAL)
	CP	DSKY_PPIX_WR
	JR	Z,DSKY_PPIWR1
;
	; SET PPI TO WRITE MODE
	LD	A,DSKY_PPIX_WR
	OUT	(PPIX),A
	LD	(DSKY_PPIX_VAL),A
;
	; RESTORE PORT C (MAY NOT BE NEEDED)
	LD	A,DSKY_PPI_IDLE
	OUT	(PPIC),A
;
DSKY_PPIWR1:
;
	POP	AF
	RET
;
;
;
DSKY_ADDHLA:
	ADD	A,L
	LD	L,A
	RET	NC
	INC	H
	RET
;
; SETUP PPI FOR READING: PUT PPI PORT A IN INPUT MODE
; AVOID REWRTING PPIX IF ALREADY IN INPUT MODE
;
DSKY_PPIRD:
	PUSH	AF
;
	; CHECK FOR READ MODE
	LD	A,(DSKY_PPIX_VAL)
	CP	DSKY_PPIX_RD
	JR	Z,DSKY_PPIRD1
;
	; SET PPI TO READ MODE
	LD	A,DSKY_PPIX_RD
	OUT	(PPIX),A
	LD	(DSKY_PPIX_VAL),A
;
;	; DIAGNOSTIC
;	LD	A,'R'
;	CALL	COUT
;
DSKY_PPIRD1:
	POP	AF
	RET
;
; RELEASE USE OF PPI
;
DSKY_PPIIDLE:
	JR	DSKY_PPIRD		; SAME AS READ MODE
;
; CODES FOR NUMERICS
; HIGH BIT ALWAYS CLEAR TO SUPPRESS DECIMAL POINT
; SET HIGH BIT TO SHOW DECIMAL POINT
;
HEXMAP:
DSKY_NUMS:
	.DB	$3F	; 0
	.DB	$06	; 1
	.DB	$5B	; 2
	.DB	$4F	; 3
	.DB	$66	; 4
	.DB	$6D	; 5
	.DB	$7D	; 6
	.DB	$07	; 7
	.DB	$7F	; 8
	.DB	$67	; 9
	.DB	$77	; A
	.DB	$7C	; B
	.DB	$39	; C
	.DB	$5E	; D
	.DB	$79	; E
	.DB	$71	; F
;
DSKY_PPIX_VAL:	.DB	0
;
; SEG DISPLAY WORKING STORAGE
;
DSKY_BUF	.FILL	8,0
DSKY_BUFLEN	.EQU	$ - DSKY_BUF
DSKY_HEXBUF	.FILL	4,0
DSKY_HEXBUFLEN	.EQU	$ - DSKY_HEXBUF
