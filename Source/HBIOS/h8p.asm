;
;==================================================================================================
; HEATH H8 FRONT PANEL (DISPLAY AND KEYBOARD) ROUTINES
;==================================================================================================
;
; LED SEGMENTS (BIT VALUES)
;
;	+--02--+
;	40    04
;	+--01--+
;	20    08
;	+--10--+  80
;
;__H8P_PREINIT_______________________________________________________________________________________
;
;  CONFIGURE AND RESET PANEL
;____________________________________________________________________________________________________
;
; HARDWARE RESET PRIOR TO ROMWBW CONSOLE INITIALIZATION
;
H8P_PREINIT:
	LD	A,(DSKY_DISPACT)	; DSKY DISPATCHER ALREADY SET?
	OR	A			; SET FLAGS
	RET	NZ			; IF ALREADY ACTIVE, ABORT
;
	; REGISTER DRIVER WITH HBIOS
	LD	BC,H8P_DISPATCH
	CALL	DSKY_SETDISP
;
	RET
;
;__H8P_INIT__________________________________________________________________________________________
;
;  DISPLAY DSKY INFO ON ROMWBW CONSOLE
;____________________________________________________________________________________________________
;
H8P_INIT:
	CALL	NEWLINE			; FORMATTING
	PRTS("H8P:$")			; DRIVER TAG
;
	RET				; DONE
;
; DSKY DEVICE FUNCTION DISPATCH ENTRY
;   A: RESULT (OUT), 0=OK, Z=OK, NZ=ERR
;   B: FUNCTION (IN)
;
H8P_DISPATCH:
	LD	A,B			; GET REQUESTED FUNCTION
	AND	$0F			; ISOLATE SUB-FUNCTION
	JP	Z,H8P_RESET		; RESET DSKY HARDWARE
	DEC	A	
	JP	Z,H8P_STAT		; GET KEYPAD STATUS
	DEC	A	
	JP	Z,H8P_GETKEY		; READ A KEY FROM THE KEYPAD
	DEC	A	
	JP	Z,H8P_SHOWHEX		; DISPLAY A 32-BIT BINARY VALUE IN HEX
	DEC	A	
	JP	Z,H8P_SHOWSEG		; DISPLAY SEGMENTS
	DEC	A	
	JP	Z,H8P_KEYLEDS		; SET KEYPAD LEDS
	DEC	A	
	JP	Z,H8P_STATLED		; SET STATUS LED
	DEC	A	
	JP	Z,H8P_BEEP		; BEEP DSKY SPEAKER
	DEC	A
	JP	Z,H8P_DEVICE		; DEVICE INFO
	SYSCHKERR(ERR_NOFUNC)
	RET
;
; RESET DSKY -- CLEAR DISPLAY AND KEYPAD FIFO
;
H8P_RESET:
	XOR	A			; SIGNAL SUCCESS
	RET
;
;  CHECK FOR KEY PRESS, SAVE RAW VALUE, RETURN STATUS
;
H8P_STAT:
	XOR	A			; ZERO KEYS PENDING (FOR NOW)
	RET
;
;  WAIT FOR A DSKY KEYPRESS AND RETURN
;
H8P_GETKEY:
	; PUT KEY VALUE IN REGISTER E
	XOR	A			; SIGNAL SUCCESS	
	RET
;
; DISPLAY HEX VALUE FROM DE:HL
;
H8P_SHOWHEX:
	LD	BC,DSKY_HEXBUF		; POINT TO HEX BUFFER
	CALL	ST32			; STORE 32-BIT BINARY THERE
	LD	HL,DSKY_HEXBUF		; FROM: BINARY VALUE (HL)
	LD	DE,DSKY_BUF		; TO: SEGMENT BUFFER (DE)
	CALL	DSKY_BIN2SEG		; CONVERT
	LD	HL,DSKY_BUF		; POINT TO SEGMENT BUFFER
	; AND FALL THRU TO DISPLAY IT
;
; DISPLAY BYTE VALUES POINTED TO BY DE.  THE INCOMING BYTES ARE IN
; THE STANDARD ROMWBW SEGMENT ENCODING AND MUST BE TRANSLATED TO THE
; HEATH ENCODING (SEE ICM.ASM FOR EXAMPLE):
;
;
;	From:		To:
;	+--01--+	+--02--+
;	20    02	40    04
;	+--40--+	+--01--+
;	10    04	20    08
;	+--08--+  80	+--10--+  80
;
H8P_SHOWSEG:
	XOR	A			; SIGNAL SUCCESS
	RET
;
; UPDATE KEY LEDS (H8 HAS NONE)
;
H8P_KEYLEDS:
	XOR	A			; SIGNAL SUCCESS
	RET
;
; SET STATUS LEDS BASED ON BITS IN E
;
H8P_STATLED:
	XOR	A			; SIGNAL SUCCESS
	RET
;
; BEEP THE SPEAKER ON THE H8P
;
H8P_BEEP:
	POP	BC
	XOR	A			; SIGNAL SUCCESS
	RET
;
; DEVICE INFORMATION
;
H8P_DEVICE:
	LD	D,DSKYDEV_H8P		; D := DEVICE TYPE
	LD	E,0			; E := PHYSICAL DEVICE NUMBER
	LD	H,0			; H := MODE
	LD	L,0			; L := BASE I/O ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET
;
;_KEYMAP_TABLE_____________________________________________________________________________________________________________
;
H8P_KEYMAP:	; *** NEEDS TO BE UPDATED ***
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

	; POS	$18  $19  $1A  $1B
	; KEY   [F4] [F3] [F2] [F1]
	.DB	$23, $22, $21, $20
