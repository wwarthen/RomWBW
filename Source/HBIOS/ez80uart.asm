;
;==================================================================================================
; eZ80 UART DRIVER (SERIAL PORT)
;==================================================================================================
;
;
; Supported Line Characteristics are encoded as follows in the DE register pair:
;
; | **Bits** | **Characteristic**                     |
; |---------:|----------------------------------------|
; | 15-14    | Reserved (set to 0)                    |
; | 13       | RTS (Not implemented)                  |
; | 12-8     | Baud Rate* (see below)                 |
; | 7        | DTR (Not implemented)                  |
; | 6        | XON/XOFF Flow Control (not implemented)|
; | 5        | Stick Parity (not implemented)         |
; | 4        | Even Parity (set for true)             |
; | 3        | Parity Enable (set for true)           |
; | 2        | Stop Bits (0-> 1 BIT, 1-> 2 BITS)      |
; | 1-0      | Data Bits (5-8 encoded as 0-3)         |
;
; * The 5-bit Baud Rate value (V) is encoded as V = 75 * 2^X * 3^Y. The
; bits are defined as YXXXX.
;
; STICK & EVEN & PARITY -> MARK PARITY -> NOT SUPPORTED
; STICK & !EVEN & PARITY -> SPACE PARITY -> NOT SUPPORTED
; THEREFORE, MARK PARITY WILL BE INTERPRETED AS EVEN PARITY
; AND SPACE PARITY WILL BE INTERPRETED AS ODD PARITY

UART0_LSR	.EQU	$C5
UART0_THR	.EQU	$C0
UART0_RBR	.EQU	$C0

LSR_THRE	.EQU	$20
LSR_DR		.EQU	$01

EZUART_PREINIT:
	LD	BC, EZUART_FNTBL
	LD	DE, EZUART_CFG		
	CALL	CIO_ADDENT
	LD	(EZUART_ID), A

	XOR	A
	RET

EZUART_INIT:
	CALL	NEWLINE			; FORMATTING
	CALL	PRTSTRD
	.TEXT	"EZ80 UART: UART0$"

	XOR	A
	RET
;
; ### Function 0x00 -- Character Input (CIOIN)
;
; Read and return a Character (E).  If no character(s) are available in the
; input buffer, this function will wait indefinitely.  The returned Status
; (A) is a standard HBIOS result code.
;
; Outputs:
;  E: Character
;  A: Status (0-OK, else error)
;
EZUART_IN:
	EZ80_UART_IN()			; CHAR RETURNED IN E
	RET
;
; ### Function 0x01 -- Character Output (CIOOUT)
;
; Send the Character (E).  If there is no space available in the unit's output
; buffer, the function will wait indefinitely.  The returned Status (A) is a
; standard HBIOS result code.
;
; Inputs:
;  E: Character
;
; Outputs:
;  A: Status (0-OK, else error)
;
EZUART_OUT:
	EZ80_UART_OUT()
	RET
;
; ### Function 0x02 -- Character Input Status (CIOIST)
;
; Return the count of Characters Pending (A) in the input buffer.
;
; The value returned in register A is used as both a Status (A) code and
; the return value. Negative values (bit 7 set) indicate a standard HBIOS
; result (error) code.  Otherwise, the return value represents the number
; of characters in the input buffer.
;
; Outputs:
;  A: Status / Characters Pending
;
EZUART_IST:
	EZ80_UART_IN_STAT()
	RET
;
; ### Function 0x03 -- Character Output Status (CIOOST)
;
; Return the status of the output FIFO.  0 means the output FIFO is full and
; no more characters can be sent. 1 means the output FIFO is not full and at
; least one character can be sent.  Negative values (bit 7 set) indicate a
; standard HBIOS result (error) code.
;
; Outputs
;   A: Status (0 -> Full, 1 -> OK to send, < 0 -> HBIOS error code)
;
EZUART_OST:
	EZ80_UART_OUT_STAT()
	RET

BAUD_RATE	.EQU	115200
;
; ### Function 0x04 -- Character I/O Initialization (CIOINIT)
;
; Apply the requested line Characteristics in (DE). The definition of the
; line characteristics value is described above.  If DE contains -1 (0xFFFF),
; then the input and output buffers will be flushed and reset.
; The Status (A) is a standard HBIOS result code.
;
; Inputs:
;   DE: Line Characteristics
;
; Outputs:
;   A: Status (0-OK, else error)
;
EZUART_INITDEV:
	LD	A, D
	CP	E
	JR	NZ, NOT_RESET
	CP	$FF
	JR	NZ, NOT_RESET

	EZ80_UART_RESET()
	RET

NOT_RESET:
	PUSH	DE			; SAVE LINE CHARACTERISTICS
	LD	A, D
	AND	$1F			; ISOLATE ENCODED BAUD RATE
	LD	L, A			; PUT IN L
	LD	H, 0			; H IS ALWAYS ZERO
	LD	DE, 75			; BAUD RATE DECODE CONSTANT
	CALL	DECODE			; DE:HL := BAUD RATE

	EZ80_CPY_EHL_TO_UHL		; HL{23:0} <- E:HL{15:0}

	POP	DE			; RESTORE REQUESTED LINE CHARACTERISTICS
	LD	A, E
	AND	3			; MASK FOR DATA BITS
	RLCA
	RLCA
	RLCA				; SHIFT TO BITS 4:3
	LD	D, A			; SAVE INTO D

	BIT	2, E			; STOP BITS (1 OR 2)
	JR	Z, ISKIP1
	SET	2, D			; APPLY TO D
ISKIP1:

	BIT	3, E			; PARITY ENABLE
	JR	Z, ISKIP2
	SET	1, D			; APPLY TO D
ISKIP2:

	BIT	4, E			; EVEN PARITY
	JR	Z, ISKIP3
	SET	0, D			; APPLY TO D
ISKIP3:

	; D NOW CONTAINS THE LINE CONTROL BITS AS PER EZ80 FUNCTION

	EZ80_UART_CONFIG()
	RET

#DEFINE	TRANSLATE(nnn,rrr) \
#defcont \		LDBCMM.LIL(nnn)
#defcont \		SBCHLBC.LIL
#defcont \		JR	NC, $+7
#defcont \		LD	D, rrr
#defcont \		JP	uart_query_end
;
; ### Function 0x05 -- Character I/O Query (CIOQUERY)
;
; Returns the current Line Characteristics (DE). The definition of the line
; characteristics value is described above. The returned status (A) is a
; standard HBIOS result code.
;
; As the eZ80 UART driver supports more than the defined HBIOS baud rates, the
; returned baud rate may be an approximation of the actual baud rate.
;
; Outputs:
;  DE: Line Characteristics
;  A: Status (0-OK, else error)
;
EZUART_QUERY:
	EZ80_UART_QUERY()
					; HL{23:0} := BAUD RATE
					; D = LINE CONTROL BITS
	PUSH	DE			; SAVE D

	OR	A
	; HL24 bit has the baud rate, we need to convert to the 5 bit representation?
	TRANSLATE(112, 			00000b)	; BAUDRATE=75 (BETWEEN 0 AND 112)
	TRANSLATE(187-112, 		00001b)	; BAUDRATE=150 (BETWEEN 113 AND 187)
	TRANSLATE(262-187, 		10000b)	; BAUDRATE=225 (BETWEEN 188 AND 262)
	TRANSLATE(375-262, 		00010b)	; BAUDRATE=300 (BETWEEN 263 AND 375)
	TRANSLATE(525-375, 		10001b)	; BAUDRATE=450 (BETWEEN 376 AND 525)
	TRANSLATE(750-525, 		00011b)	; BAUDRATE=600 (BETWEEN 526 AND 750)
	TRANSLATE(1050-750, 		10010b)	; BAUDRATE=900 (BETWEEN 751 AND 1050)
	TRANSLATE(1500-1050, 		00100b)	; BAUDRATE=1200 (BETWEEN 1051 AND 1500)
	TRANSLATE(2100-1500, 		10011b)	; BAUDRATE=1800 (BETWEEN 1501 AND 2100)
	TRANSLATE(3000-2100, 		00101b)	; BAUDRATE=2400 (BETWEEN 2101 AND 3000)
	TRANSLATE(4200-3000, 		10100b)	; BAUDRATE=3600 (BETWEEN 3001 AND 4200)
	TRANSLATE(6000-4200, 		00110b)	; BAUDRATE=4800 (BETWEEN 4201 AND 6000)
	TRANSLATE(8400-6000, 		10101b)	; BAUDRATE=7200 (BETWEEN 6001 AND 8400)
	TRANSLATE(12000-8400, 		00111b)	; BAUDRATE=9600 (BETWEEN 8401 AND 12000)
	TRANSLATE(16800-12000, 		10110b)	; BAUDRATE=14400 (BETWEEN 12001 AND 16800)
	TRANSLATE(24000-16800, 		01000b)	; BAUDRATE=19200 (BETWEEN 16801 AND 24000)
	TRANSLATE(33600-24000, 		10111b)	; BAUDRATE=28800 (BETWEEN 24001 AND 33600)
	TRANSLATE(48000-33600, 		01001b)	; BAUDRATE=38400 (BETWEEN 33601 AND 48000)
	TRANSLATE(67200-48000, 		11000b)	; BAUDRATE=57600 (BETWEEN 48001 AND 67200)
	TRANSLATE(96000-67200, 		01010b)	; BAUDRATE=76800 (BETWEEN 67201 AND 96000)
	TRANSLATE(134400-96000, 	11001b)	; BAUDRATE=115200 (BETWEEN 96001 AND 134400)
	TRANSLATE(192000-134400, 	01011b)	; BAUDRATE=153600 (BETWEEN 134401 AND 192000)
	TRANSLATE(268800-192000, 	11010b)	; BAUDRATE=230400 (BETWEEN 192001 AND 268800)
	TRANSLATE(384000-268800, 	01100b)	; BAUDRATE=307200 (BETWEEN 268801 AND 384000)
	TRANSLATE(537600-384000, 	11011b)	; BAUDRATE=460800 (BETWEEN 384001 AND 537600)
	TRANSLATE(768000-537600, 	01101b)	; BAUDRATE=614400 (BETWEEN 537601 AND 768000)
	TRANSLATE(1075200-768000,	11100b)	; BAUDRATE=921600 (BETWEEN 768001 AND 1075200)
	TRANSLATE(1536000-1075200,	01110b)	; BAUDRATE=1228800 (BETWEEN 1075201 AND 1536000)
	TRANSLATE(2150400-1536000,	11101b)	; BAUDRATE=1843200 (BETWEEN 1536001 AND 2150400)
	TRANSLATE(3072000-2150400,	01111b)	; BAUDRATE=2457600 (BETWEEN 2150401 AND 3072000)
	TRANSLATE(5529600-3072000,	11110b)	; BAUDRATE=3686400 (BETWEEN 3072001 AND 5529600)

	LD	D, 11111b			; BAUDRATE=7372800 (>=5529601)
uart_query_end:

	POP	BC				; B = LINE CONTROL BITS

; Convert from line control settings from:
;
;     B{0:1} = Parity    (00 -> NONE, 01 -> NONE, 10 -> ODD, 11 -> EVEN)
;     B{2}   = Stop Bits (0 -> 1, 1 -> 2)
;     B{3:4} = Data Bits (00 -> 5, 01 -> 6, 10 -> 7, 11 -> 8)
;     B{5:5} = Hardware Flow Control CTS (0 -> OFF, 1 -> ON)
;
; to
;
;     E{7}   = TODO: DTR
;     E{6}   = NOT IMPLEMENTED: XON/XOFF Flow Control
;     E{5}   = NOT SUPPORTED: Stick Parity (set for true)
;     E{4}   = Even Parity (set for true)
;     E{3}   = Parity Enable (set for true)
;     E{2}   = Stop Bits (set for true)
;     E{1:0} = Data Bits (5-8 encoded as 0-3)

	XOR	A
	OR	3 << 3		; ISOLATE DATA BITS
	AND	B		; MASK IN DATA BITS

	RRCA			; SHIFT TO BITS 1:0
	RRCA
	RRCA
	LD	H, A		; H{1:0} DATA BITS

	BIT	2, B		; STOP BITS
	JR	Z, SKIP1
	SET	2, H		; APPLY TO H

SKIP1:
	BIT	1, B		; PARITY ENABLE
	JR	Z, SKIP2
	SET	3, H		; APPLY TO H

SKIP2:
	BIT	0, B		; EVEN PARITY
	JR	Z, SKIP3
	SET	4, H		; APPLY TO H

SKIP3:
	LD	E, H
	XOR	A
	RET
;
; ### Function 0x06 -- Character I/O Device (CIODEVICE)
;
; Returns device information.  The status (A) is a standard HBIOS result
; code.
;
; Outputs
;  A: Status (0 - OK)
;  C: Device Attribute (0 - RS/232)
;  D: Device Type (CIODEV_EZ80UART)
;  E: Physical Device Number
;  H: Device Mode (0)
;  L: Device I/O Base Address - Not Supported (0)
;
EZUART_DEVICE:
	LD	D, CIODEV_EZ80UART	; D := DEVICE TYPE
	LD	E, (IY)			; E := PHYSICAL UNIT
	LD	C, 0			; C := DEVICE TYPE, 0x00 IS RS-232
	LD	HL, 0			; H := MODE, L := BASE I/O ADDRESS
	
	XOR	A			; SIGNAL SUCCESS
	RET

EZUART_CFG:
EZUART_ID:	.DB	0

	
EZUART_FNTBL:
	.DW	EZUART_IN
	.DW	EZUART_OUT
	.DW	EZUART_IST
	.DW	EZUART_OST
	.DW	EZUART_INITDEV
	.DW	EZUART_QUERY
	.DW	EZUART_DEVICE
#IF (($ - EZUART_FNTBL) != (CIO_FNCNT * 2))
	.ECHO	"*** INVALID EZUART FUNCTION TABLE ***\n"
#ENDIF
