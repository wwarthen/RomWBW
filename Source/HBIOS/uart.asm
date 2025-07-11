;
;==================================================================================================
; UART DRIVER (SERIAL PORT)
;==================================================================================================
;
;  SETUP PARAMETER WORD:
;  +-------+---+-------------------+ +---+---+-----------+---+-------+
;  |       |RTS| ENCODED BAUD RATE | |DTR|XON|  PARITY   |STP| 8/7/6 |
;  +-------+---+---+---------------+ ----+---+-----------+---+-------+
;    F   E   D   C   B   A   9   8     7   6   5   4   3   2   1   0
;       -- MSB (D REGISTER) --           -- LSB (E REGISTER) --
;
;  UART CONFIGURATION REGISTERS:
;  +-------+---+-------------------+ +---+---+-----------+---+-------+
;  | 0   0 |AFE|LP  OT2 OT1 RTS DTR| |DLB|BRK|STK EPS PEN|STB|  WLS  |
;  +-------+---+-------------------+ +---+---+-----------+---+-------+
;    F   E   D   C   B   A   9   8     7   6   5   4   3   2   1   0
;              -- MCR --                        -- LCR --
;
;  STANDARD UART BASE I/O ADDRESSES:
;    - ECB SBC Z80	$68
;    - ECB CASSETTE	$80
;    - ECB 4UART	$C0,$C8,$D0,$D8
;    - ECB MFPIC	$18
;    - ZETA		$68
;    - DUODYNE Z80	$58
;    - DUODYNE SELFHOST	$A8
;    - DUODYNE MULTI IO	$70,$78
;    - NHYODYNE Z80	$68
;    - NHYODYNE DUART	$80,$88
;    - RCBUS EPSER	$A0,$A8
;    - RCBUS SERIAL	$80,$88,$A0,$A8,$C0,$C8,$E0,$E8
;    - EPITX		$A0,$A8
;    - NABU		$48
;    - HEATH		$C0,$C8,$D0
;
UART_DEBUG		.EQU	FALSE
;
UART_BUFSZ		.EQU	32	; RECEIVE RING BUFFER SIZE
;
UART_NONE		.EQU	0	; UNKNOWN OR NOT PRESENT
UART_8250		.EQU	1
UART_16450		.EQU	2
UART_16550		.EQU	3
UART_16550A		.EQU	4
UART_16550C		.EQU	5
UART_16650		.EQU	6
UART_16750		.EQU	7
UART_16850		.EQU	8
;
UART_RBR		.EQU	0	; DLAB=0: RCVR BUFFER REG (READ)
UART_THR		.EQU	0	; DLAB=0: XMIT HOLDING REG (WRITE)
UART_IER		.EQU	1	; DLAB=0: INT ENABLE REG (READ)
UART_IIR		.EQU	2	; INT IDENT REGISTER (READ)
UART_FCR		.EQU	2	; FIFO CONTROL REG (WRITE)
UART_LCR		.EQU	3	; LINE CONTROL REG (READ/WRITE)
UART_MCR		.EQU	4	; MODEM CONTROL REG (READ/WRITE)
UART_LSR		.EQU	5	; LINE STATUS REG (READ)
UART_MSR		.EQU	6	; MODEM STATUS REG (READ)
UART_SCR		.EQU	7	; SCRATCH REGISTER (READ/WRITE)
UART_DLL		.EQU	0	; DLAB=1: DIVISOR LATCH (LS) (READ/WRITE)
UART_DLM		.EQU	1	; DLAB=1: DIVISOR LATCH (MS) (READ/WRITE)
UART_EFR		.EQU	2	; LCR=$BF: ENHANCED FEATURE REG (READ/WRITE)
;
; THESE BITS ARE SET IN THE UART TYPE BYTE TO FURTHER
; IDENTIFY THE FEATURES OF THE CHIP
;
UART_INTACT		.EQU	7	; INT RCV ACTIVE BIT
UART_FIFOACT		.EQU	6	; FIFO ACTIVE BIT
UART_AFCACT		.EQU	5	; AUTO FLOW CONTROL ACTIVE BIT
UART_CTSBAD		.EQU	4	; CTS STALL DETECTED
;
#IF (UARTINTS)
;
  #IF ((INTMODE == 2) | (INTMODE == 3))
;
UART0_IVT	.EQU	IVT(INT_UART0)
UART1_IVT	.EQU	IVT(INT_UART1)
;
  #ENDIF
;
#ENDIF
;
#DEFINE	UART_INP(RID)	CALL UART_INP_IMP \ .DB RID
#DEFINE	UART_OUTP(RID)	CALL UART_OUTP_IMP \ .DB RID
;
;
;
UART_PREINIT:
#IF (UART4UART)
;
; INIT UART4 BOARD CONFIG REGISTER (NO HARM IF IT IS NOT THERE)
;
	LD	A,$80			; SELECT 7.3728MHZ OSC & LOCK CONFIG REGISTER
	OUT	(UART4UARTBASE+$0F),A	; DO IT
#ENDIF
;
; SETUP THE DISPATCH TABLE ENTRIES
;
	LD	B,UARTCNT		; LOOP CONTROL
	LD	C,0			; PHYSICAL UNIT INDEX
	XOR	A			; ZERO TO ACCUM
	LD	(UART_DEV),A		; CURRENT DEVICE NUMBER
UART_PREINIT0:	
	PUSH	BC			; SAVE LOOP CONTROL
	LD	A,C			; PHYSICAL UNIT TO A
	RLCA				; MULTIPLY BY CFG TABLE ENTRY SIZE (8 BYTES)
	RLCA				; ...
	RLCA				; ... TO GET OFFSET INTO CFG TABLE
	LD	HL,UART_CFG		; POINT TO START OF CFG TABLE
	CALL	ADDHLA			; HL := ENTRY ADDRESS
	PUSH	HL			; SAVE IT
	PUSH	HL			; COPY CFG DATA PTR
	POP	IY			; ... TO IY
	CALL	UART_INITUNIT		; HAND OFF TO GENERIC INIT CODE
	POP	DE			; GET ENTRY ADDRESS BACK, BUT PUT IN DE
	POP	BC			; RESTORE LOOP CONTROL
;
	LD	A,(IY+1)		; GET THE UART TYPE DETECTED
	OR	A			; SET FLAGS
	JR	Z,UART_PREINIT2		; SKIP IT IF NOTHING FOUND
;	
	PUSH	BC			; SAVE LOOP CONTROL
	LD	BC,UART_FNTBL		; BC := FUNCTION TABLE ADDRESS
	CALL	NZ,CIO_ADDENT		; ADD ENTRY IF UART FOUND, BC:DE
	POP	BC			; RESTORE LOOP CONTROL
;
UART_PREINIT2:	
	INC	C			; NEXT PHYSICAL UNIT
	DJNZ	UART_PREINIT0		; LOOP UNTIL DONE
;
#IF ((UARTINTS) & (INTMODE > 0))
	; *** FIXME *** WE SHOULD CHECK TO SEE IF ANY UNITS ARE ACTUALLY
	; USING INT RCV.  IF NOT, WE SHOULD NOT HOOK IM1!!!
;
	; SETUP INT VECTORS AS APPROPRIATE
	LD	A,(UART_DEV)		; GET DEVICE COUNT
	OR	A			; SET FLAGS
	JR	Z,UART_PREINIT3		; IF ZERO, NO UART DEVICES, ABORT
;
  #IF (INTMODE == 1)
	; ADD IM1 INT CALL LIST ENTRY
	LD	HL,UART_INT		; GET INT VECTOR
	CALL	HB_ADDIM1		; ADD TO IM1 CALL LIST
  #ENDIF
;
  #IF ((INTMODE == 2) | (INTMODE == 3))
	; SETUP IM2/3 VECTORS
    #IF (UARTCNT >= 1)
	LD	HL,UART_INT0
	LD	(UART0_IVT),HL		; IVT INDEX
    #ENDIF
;
    #IF (UARTCNT >= 2)
	LD	HL,UART_INT1
	LD	(UART1_IVT),HL		; IVT INDEX
    #ENDIF
;
  #ENDIF
;
#ENDIF
;
UART_PREINIT3:
	XOR	A			; SIGNAL SUCCESS
	RET				; AND RETURN
;
; UART INITIALIZATION ROUTINE
;
UART_INITUNIT:
	; DETECT THE UART TYPE
	CALL	UART_DETECT		; DETERMINE UART TYPE
	LD	(IY+1),A		; AND SAVE IN CONFIG TABLE
	OR	A			; SET FLAGS
	RET	Z			; ABORT IF NOTHING THERE
;
	; UPDATE WORKING UART DEVICE NUM
	LD	HL,UART_DEV		; POINT TO CURRENT UART DEVICE NUM
	LD	A,(HL)			; PUT IN ACCUM
	INC	(HL)			; INCREMENT IT (FOR NEXT LOOP)
	LD	(IY),A			; UDPATE UNIT NUM
;
	; CHECK FOR CTS STALL (CTS SHOULD BE ASSERTED HERE)
	BIT	5,(IY+5)		; IS RTS REQUESTED?
	JR	Z,UART_INITUNIT1	; IF NOT, SKIP CTS CHECK
	UART_INP(UART_MSR)		; LOAD MODEM STATUS REG
	BIT	4,A			; CTS
	JR	NZ,UART_INITUNIT1	; IF CTS HIGH (GOOD), SKIP AHEAD
;
	; CTS LOOKS BORKED, SHUT OFF RTS/CTS FLOW CONTROL
	RES	5,(IY+5)		; CLEAR RTS BIT OF CONFIG MSB
	SET	UART_CTSBAD,(IY+1)	; RECORD BAD CTS
;	
UART_INITUNIT1:
	; SET DEFAULT CONFIG
	LD	DE,-1			; LEAVE CONFIG ALONE
	JP	UART_INITDEV		; IMPLEMENT IT AND RETURN
;
;
;
UART_INIT:
	LD	B,UARTCNT		; COUNT OF POSSIBLE UART UNITS
	LD	C,0			; INDEX INTO UART CONFIG TABLE
UART_INIT1:
	PUSH	BC			; SAVE LOOP CONTROL
	
	LD	A,C			; PHYSICAL UNIT TO A
	RLCA				; MULTIPLY BY CFG TABLE ENTRY SIZE (8 BYTES)
	RLCA				; ...
	RLCA				; ... TO GET OFFSET INTO CFG TABLE
	LD	HL,UART_CFG		; POINT TO START OF CFG TABLE
	CALL	ADDHLA			; HL := ENTRY ADDRESS
	PUSH	HL			; COPY CFG DATA PTR
	POP	IY			; ... TO IY
	
	LD	A,(IY+1)		; GET UART TYPE
	OR	A			; SET FLAGS
	JR	Z,UART_INIT2		; SKIP IF ZERO (NOT DETECTED)
	CALL	UART_PRTCFG		; PRINT IF NOT ZERO
;
UART_INIT2:
	POP	BC			; RESTORE LOOP CONTROL
	INC	C			; NEXT UNIT
	DJNZ	UART_INIT1		; LOOP TILL DONE
;
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
; RECEIVE INTERRUPT HANDLER
;
#IF ((UARTINTS) & (INTMODE > 0))
;
; IM1 ENTRY POINT
;
; POLL ALL DEVICES THAT MIGHT ENABLE INTERRUPT DRIVEN
; RECEIVE.  HANDLE FIRST INTERRUPT ENCOUNTERED (IF ANY).
; MOST BOARDS REQUIRE UARTS THAT WILL HAVE AFC.  THE
; ONLY BOARDS THAT MAY NOT ARE THE SBC AND THE CAS.
;
; THIS COULD BE IMPROVED BY DYNAMICALLY SETTING UP THE
; POLLING CHAIN WHEN DEVICES ARE INITIALIZED SUCH THAT
; ONLY DEVICES ACTUALLY USING INTS ARE POLLED HERE.
;
  #IF (INTMODE == 1)

UART_INT:
;
    #IF (UARTCNT >= 1)
	LD	IY,UART0_CFG
	CALL	UART_INTRCV
	RET	NZ
    #ENDIF
;
    #IF (UARTCNT >= 2)
	LD	IY,UART1_CFG
	CALL	UART_INTRCV
	RET	NZ
    #ENDIF
;
  #ENDIF
;
  #IF ((INTMODE == 2) | (INTMODE == 3))
;
    #IF (UARTCNT >= 1)
UART_INT0:
	LD	IY,UART0_CFG
	JR	UART_INTRCV
    #ENDIF
;
    #IF (UARTCNT >= 2)
UART_INT1:
	LD	IY,UART1_CFG
	JR	UART_INTRCV
    #ENDIF
;
  #ENDIF
;
	XOR	A			; CLEAR ACCUM (INT NOT HANDLED)
	RET				; DONE
;
; IM2 ENTRY POINTS
;

;
; HANDLE INT FOR A SPECIFIC CHANNEL
; BASED ON UNIT CFG POINTED TO BY IY
;
UART_INTRCV:
	; ARE INTERRUPTS IN USE ON THIS DEVICE?
	LD	A,(IY+1)		; GET UART TYPE
	AND	%10000000		; ISOLATE INT RCV BIT
	RET	Z			; INTS NOT SUPPORTED
	; CHECK TO SEE IF SOMETHING IS ACTUALLY THERE
	LD	C,(IY+3)		; STATUS PORT TO C
	IN	A,(C)			; GET LSR
	AND	$01			; ISOLATE RECEIVE READY BIT
	RET	Z			; NOTHING AVAILABLE ON CURRENT CHANNEL
;
UART_INTRCV1:
	; RECEIVE CHARACTER INTO BUFFER
	LD	C,(IY+2)		; DATA PORT TO C
	IN	A,(C)			; READ PORT
	LD	B,A			; SAVE BYTE READ
	LD	L,(IY+6)		; SET HL TO
	LD	H,(IY+7)		; ... START OF BUFFER STRUCT
	LD	A,(HL)			; GET COUNT
	CP	UART_BUFSZ		; COMPARE TO BUFFER SIZE
	JR	Z,UART_INTRCV4		; BAIL OUT IF BUFFER FULL, RCV BYTE DISCARDED
	INC	A			; INCREMENT THE COUNT
	LD	(HL),A			; AND SAVE IT


	; *** FIXME *** THE FOLLOWING SHOULD ONLY BE DONE IF RTS FLOW CONTROL IS ON!!!
	; SOMETHING LIKE THIS MAY WORK...
	;BIT	5,(IY+5)
	;JR	Z,UART_INTRCV2
	
	
	CP	UART_BUFSZ / 2		; BUFFER GETTING FULL?
	JR	NZ,UART_INTRCV2		; IF NOT, BYPASS CLEARING RTS
	LD	C,(IY+3)		; LSR PORT TO C
	DEC	C			; POINT TO MCR PORT
	IN	A,(C)			; GET MCR VALUE
	AND	~%00000011		; CLEAR RTS & DTR
	OUT	(C),A			; AND SAVE IT
;	
UART_INTRCV2:
	INC	HL			; HL NOW HAS ADR OF HEAD PTR
	PUSH	HL			; SAVE ADR OF HEAD PTR
	LD	A,(HL)			; DEREFERENCE HL
	INC	HL
	LD	H,(HL)
	LD	L,A			; HL IS NOW ACTUAL HEAD PTR
	LD	(HL),B			; SAVE CHARACTER RECEIVED IN BUFFER AT HEAD
	INC	HL			; BUMP HEAD POINTER
	POP	DE			; RECOVER ADR OF HEAD PTR
	LD	A,L			; GET LOW BYTE OF HEAD PTR
	SUB	UART_BUFSZ+4		; SUBTRACT SIZE OF BUFFER AND POINTER
	CP	E			; IF EQUAL TO START, HEAD PTR IS PAST BUF END
	JR	NZ,UART_INTRCV3		; IF NOT, BYPASS
	LD	H,D			; SET HL TO
	LD	L,E			; ... HEAD PTR ADR
	INC	HL			; BUMP PAST HEAD PTR
	INC	HL
	INC	HL
	INC	HL			; ... SO HL NOW HAS ADR OF ACTUAL BUFFER START
UART_INTRCV3:
	EX	DE,HL			; DE := HEAD PTR VAL, HL := ADR OF HEAD PTR
	LD	(HL),E			; SAVE UPDATED HEAD PTR
	INC	HL
	LD	(HL),D
	; CHECK FOR MORE PENDING...
	LD	C,(IY+3)		; STATUS PORT TO C
	IN	A,(C)			; GET LSR
	AND	$01			; ISOLATE RECEIVE READY BIT
	JR	NZ,UART_INTRCV1		; IF SET, DO SOME MORE
UART_INTRCV4:
	OR	$FF			; NZ SET TO INDICATE INT HANDLED
	RET
;
#ENDIF
;
; DRIVER FUNCTION TABLE
;
UART_FNTBL:
	.DW	UART_IN
	.DW	UART_OUT
	.DW	UART_IST
	.DW	UART_OST
	.DW	UART_INITDEV
	.DW	UART_QUERY
	.DW	UART_DEVICE
#IF (($ - UART_FNTBL) != (CIO_FNCNT * 2))
	.ECHO	"*** INVALID UART FUNCTION TABLE ***\n"
#ENDIF
;
;
;
UART_IN:
	CALL	UART_IST		; RECEIVED CHAR READY?
	JR	Z,UART_IN		; LOOP IF NOT
#IF ((UARTINTS) & (INTMODE > 0))
	BIT	UART_INTACT,(IY+1)	; INT RCV BIT
	JR	Z,UART_IN1		; NORMAL INPUT IF NOT SET
	JR	UART_INTIN		; INT RCV INPUT
#ENDIF
;
UART_IN1:
	LD	C,(IY+2)		; C := BASE UART PORT (WHICH IS ALSO RBR REG)
	IN	E,(C)			; CHAR READ TO E
	XOR	A			; SIGNAL SUCCESS
	RET				; AND DONE
;
#IF ((UARTINTS) & (INTMODE > 0))
;
UART_INTIN:
	HB_DI				; AVOID COLLISION WITH INT HANDLER
	LD	L,(IY+6)		; SET HL TO
	LD	H,(IY+7)		; ... START OF BUFFER STRUCT
	LD	A,(HL)			; GET COUNT
	DEC	A			; DECREMENT COUNT
	LD	(HL),A			; SAVE UPDATED COUNT
	
	
	; *** FIXME *** THE FOLLOWING SHOULD ONLY BE DONE IF RTS FLOW CONTROL IS ON!!!
	; SOMETHING LIKE THIS MAY WORK...
	;BIT	5,(IY+5)
	;JR	Z,UART_INTIN1

	
	CP	UART_BUFSZ / 4		; BUFFER LOW THRESHOLD
	JR	NZ,UART_INTIN1		; IF NOT, BYPASS SETTING RTS
	LD	C,(IY+3)		; LSR PORT TO C
	DEC	C			; POINT TO MCR PORT
	IN	A,(C)			; GET MCR VALUE
	OR	%00000011		; SET RTS & DTR
	OUT	(C),A			; AND SAVE IT
;
UART_INTIN1:
	INC	HL
	INC	HL
	INC	HL			; HL NOW HAS ADR OF TAIL PTR
	PUSH	HL			; SAVE ADR OF TAIL PTR
	LD	A,(HL)			; DEREFERENCE HL
	INC	HL
	LD	H,(HL)
	LD	L,A			; HL IS NOW ACTUAL TAIL PTR
	LD	C,(HL)			; C := CHAR TO BE RETURNED
	INC	HL			; BUMP TAIL PTR
	POP	DE			; RECOVER ADR OF TAIL PTR
	LD	A,L			; GET LOW BYTE OF TAIL PTR
	SUB	UART_BUFSZ+2		; SUBTRACT SIZE OF BUFFER AND POINTER
	CP	E			; IF EQUAL TO START, TAIL PTR IS PAST BUF END
	JR	NZ,UART_INTIN2		; IF NOT, BYPASS
	LD	H,D			; SET HL TO
	LD	L,E			; ... TAIL PTR ADR
	INC	HL			; BUMP PAST TAIL PTR
	INC	HL			; ... SO HL NOW HAS ADR OF ACTUAL BUFFER START
UART_INTIN2:
	EX	DE,HL			; DE := TAIL PTR VAL, HL := ADR OF TAIL PTR
	LD	(HL),E			; SAVE UPDATED TAIL PTR
	INC	HL
	LD	(HL),D
	LD	E,C			; MOVE CHAR TO RETURN TO E
	HB_EI				; INTERRUPTS OK AGAIN
	XOR	A			; SIGNAL SUCCESS
	RET				; AND DONE
;
#ENDIF
;
;
;
UART_OUT:
	CALL	UART_OST		; READY FOR CHAR?
	JR	Z,UART_OUT		; LOOP IF NOT
	LD	C,(IY+2)		; C := BASE UART PORT (WHICH IS ALSO THR REG)
	OUT	(C),E			; SEND CHAR FROM E
	XOR	A			; SIGNAL SUCCESS
	RET
;
;
;
UART_IST:
#IF ((UARTINTS) & (INTMODE > 0))
	BIT	UART_INTACT,(IY+1)	; INT RCV BIT
	JR	Z,UART_IST1		; NORMAL INPUT IF NOT SET
	JR	UART_INTIST		; ELSE INT RCV
#ENDIF
;
UART_IST1:
	LD	C,(IY+3)		; C := LINE STATUS REG (LSR)
	IN	A,(C)			; GET STATUS
	AND	$01			; ISOLATE BIT 0 (RECEIVE DATA READY)
	JP	Z,CIO_IDLE		; NOT READY, RETURN VIA IDLE PROCESSING
	XOR	A			; ZERO ACCUM
	INC	A			; ACCUM := 1 TO SIGNAL 1 CHAR WAITING
	RET				; DONE
;
#IF ((UARTINTS) & (INTMODE > 0))
;
UART_INTIST:
	LD	L,(IY+6)		; GET ADDRESS
	LD	H,(IY+7)		; ... OF RECEIVE BUFFER
	LD	A,(HL)			; BUFFER UTILIZATION COUNT
	OR	A			; SET FLAGS
	JP	Z,CIO_IDLE		; NOT READY, RETURN VIA IDLE PROCESSING
	RET
;
#ENDIF
;
;
;
UART_OST:
	LD	C,(IY+3)		; C := LINE STATUS REG (LSR)
	IN	A,(C)			; GET STATUS
	AND	$20			; ISOLATE BIT 5 ()
	JP	Z,CIO_IDLE		; NOT READY, RETURN VIA IDLE PROCESSING
	XOR	A			; ZERO ACCUM
	INC	A			; ACCUM := 1 TO SIGNAL 1 BUFFER POSITION
	RET				; DONE
;
;
;
UART_INITDEV:
	; INITDEV CAN BE CALLED PRIOR TO INTERRUPTS BEING ENABLED.  WE
	; NEED TO LEAVE INTERRUPTS ALONE IN THIS SCENARIO
	LD	A,(INTSENAB)		; INTS ENABLED?
	OR	A			; TEST VALUE
	JR	Z,UART_INITDEV0		; BYPASS DI/EI IF NOT ENABLED
;
	; INTERRUPTS DISABLED DURING INIT
	HB_DI				; DISABLE INTS
	CALL	UART_INITDEV0		; DO THE WORK
	HB_EI				; INTS BACK ON
	RET				; DONE
;
UART_INITDEV0:
	; TEST FOR -1 WHICH MEANS USE CURRENT CONFIG (JUST REINIT)
	LD	A,D			; TEST DE FOR
	AND	E			; ... VALUE OF -1
	INC	A			; ... SO Z SET IF -1
	JR	NZ,UART_INITDEV1	; IF DE == -1, REINIT CURRENT CONFIG
;
	; LOAD EXISTING CONFIG TO REINIT
	LD	E,(IY+4)		; LOW BYTE
	LD	D,(IY+5)		; HIGH BYTE
;
UART_INITDEV1:
	; DETERMINE DIVISOR
	PUSH	DE			; SAVE CONFIG
	CALL	UART_COMPDIV		; COMPUTE DIVISOR TO BC
	POP	DE			; RESTORE CONFIG
	RET	NZ			; ABORT IF COMPDIV FAILS!
;
	; GOT A DIVISOR, COMMIT NEW CONFIG
	LD	(IY+4),E		; SAVE LOW WORD
	LD	(IY+5),D		; SAVE HI WORD
;
	; START OF ACTUAL UART CONFIGURATION
	LD	A,80H			; DLAB IS BIT 7 OF LCR
	UART_OUTP(UART_LCR)		; DLAB ON
	LD	A,B
	UART_OUTP(UART_DLM)		; SET DIVISOR (MS)
	LD	A,C
	UART_OUTP(UART_DLL)		; SET DIVISOR (LS)
;
	; FOR 750+, WE ENABLE THE 64-BYTE FIFO
	; DLAB MUST STILL BE ON FOR ACCESS TO BIT 5
	; WE DO *NOT* ENABLE ANY OTHER FCR BITS HERE
	; BECAUSE IT WILL SCREW UP THE 2552!!!
	LD	A,%00100000
	UART_OUTP(UART_FCR)		; DO IT
;
	XOR	A			; DLAB OFF NOW
	UART_OUTP(UART_LCR)		; DO IT
;
	XOR	A			; IER VALUE FOR NO INTS
;
#IF ((UARTINTS) & (INTMODE > 0))
;
	BIT	UART_INTACT,(IY+1)	; CHECK INT RCV BIT
	JR	Z,UART_INITDEV1A	; SKIP IF NOT SET
	INC	A			; DATA RCVD INT BIT OF IER
;
UART_INITDEV1A:
;
#ENDIF
;
	UART_OUTP(UART_IER)		; SETUP IER REGISTER
;
	; SETUP FCR, BIT 5 IS KEPT ON EVEN THOUGH IT IS PROBABLY
	; IRRELEVANT BECAUSE IT ONLY APPLIES TO 750 AND DLAB IS
	; NOW OFF, BUT DOESN'T HURT.
	; BITS 7-6 DEFINE THE FIFO RECEIVE INTERRUPT THRESHOLD. WE
	; USE A VALUE 0F %01 FOR THESE BITS WHICH REDUCES THE
	; FREQUENCY OF INTERRUPTS DURING HEAVY RECEIVE OPERATIONS.
	LD	A,%01100111		; FIFO ENABLE & RESET
	UART_OUTP(UART_FCR)		; DO IT
;
	; SETUP LCR FROM SECOND CONFIG BYTE
	LD	A,(IY+4)		; GET CONFIG BYTE
	AND	~$C0			; ISOLATE PARITY, STOP/DATA BITS
	UART_OUTP(UART_LCR)		; SAVE IT
;
	; SETUP MCR FROM FIRST CONFIG BYTE
	LD	A,(IY+5)		; GET CONFIG BYTE
	AND	~$1F			; REMOVE ENCODED BAUD RATE BITS
	OR	$03			; FORCE RTS & DTR
;
	; SOME NEWER UARTS USE MCR:3 TO ACTIVATE THE INTERRUPT LINE.
	; ALTHOUGH OTHER UARTS USE MCR:3 TO CONTROL A GPIO LINE CALLED
	; OUT2, NO ROMWBW HARDWARE USES THIS GPIO LINE.  SO, HERE, WE
	; JUST SET MCR:3 TO ACTIVATE THE INTERRUPT LINE.  NOTE THAT
	; EVEN IF WE ARE NOT USING INTERRUPTS FOR THIS UART, THE
	; INTERRUPT LINE MUST STILL BE ACTIVATED SO THAT IT WILL
	; PRESENT A DEASSERTED CONDITION TO THE CPU.  OTHERWISE, THE
	; INTERRUPT LINE MAY BE LEFT FLOATING WHICH IS DEFINITELY BAD.
	OR	$08			; ACTIVATE INT LINE
;
	; THE MCR REGISTER AFE BIT WILL NORMALLY BE SET/RESET BY THE
	; VALUE OF THE CONFIG BYTE.  HOWEVER, IF THE CHIP IS NOT AFC CAPABLE
	; WE ARE PROBABLY USING INT RCV FOR FLOW CONTROL.  ALTHOUGH THE
	; CHIP PROBABLY IGNORES THE AFE BIT, WE FORCE CLEAR IT ANYWAY. IT WOULD
	; BE BAD IF AFC AND INT RCV ARE ACTIVE AT THE SAME TIME.
	BIT	UART_AFCACT,(IY+1)	; IS AFC SUPPOSED TO BE ON?
	JR	NZ,UART_INITDEV1B	; IF SO, AFE BIT IS OK BASED ON CONFIG BYTE
	RES	5,A			; ELSE FORCE IT OFF
;
UART_INITDEV1B:
	UART_OUTP(UART_MCR)		; SAVE MCR VALUE
;
	; TEST FOR EFR CAPABLE CHIPS
	LD	A,(IY+1)		; GET UART TYPE
	AND	$0F			; ISOLATE LOW NIBBLE
	CP	UART_16650		; 16650?
	JR	Z,UART_INITDEV2		; USE EFR REGISTER
	CP	UART_16850		; 16850?
	JR	Z,UART_INITDEV2		; USE EFR REGISTER
	JR	UART_INITDEV4		; NO EFR, SKIP AHEAD
;
UART_INITDEV2:
	; WE HAVE AN EFR CAPABLE CHIP, SET EFR REGISTER
	; NOTE THAT AN EFR CAPABLE CHIP IMPLIES IT IS CAPABLE OF AFC!
	UART_INP(UART_LCR)		; GET CURRENT LCR VALUE
	PUSH	AF			; SAVE IT
	LD	A,$BF			; VALUE TO ACCESS EFR
	UART_OUTP(UART_LCR)		; SET VALUE IN LCR
	LD	A,(IY+5)		; GET CONFIG BYTE
	BIT	5,A			; AFC REQUESTED?
	LD	A,$C0			; ASSUME AFC ON
	JR	NZ,UART_INITDEV3	; YES, IMPLEMENT IT
	XOR	A			; NO AFC REQEUST, EFR := 0
;
UART_INITDEV3:
	UART_OUTP(UART_EFR)		; SAVE IT
	POP	AF			; RECOVER ORIGINAL LCR VALUE
	UART_OUTP(UART_LCR)		; AND PUT IT BACK
;
UART_INITDEV4:
;
#IF ((UARTINTS) & (INTMODE > 0))
;
	LD	A,(IY+7)		; MSB OF BUFFER
	OR	A			; SET FLAGS
	JR	Z,UART_INITDEV5		; BYPASS IF NO BUFFER
	; RESET THE RECEIVE BUFFER
	LD	E,(IY+6)
	LD	D,(IY+7)		; DE := _CNT
	XOR	A			; A := 0
	LD	(DE),A			; _CNT = 0
	INC	DE			; DE := ADR OF _HD
	PUSH	DE			; SAVE IT
	INC	DE
	INC	DE
	INC	DE
	INC	DE			; DE := ADR OF _BUF
	POP	HL			; HL := ADR OF _HD
	LD	(HL),E
	INC	HL
	LD	(HL),D			; _HD := _BUF
	INC	HL
	LD	(HL),E
	INC	HL
	LD	(HL),D			; _TL := _BUF
;
UART_INITDEV5:
;
#ENDIF
;
;
#IF (UART_DEBUG)
	PRTS(" [$")
	
	; DEBUG: DUMP UART TYPE
	LD	A,(IY+1)
	CALL	PRTHEXBYTE

	; DEBUG: DUMP IIR
	UART_INP(UART_IIR)
	CALL	PC_SPACE
	CALL	PRTHEXBYTE

	; DEBUG: DUMP LCR
	UART_INP(UART_LCR)
	CALL	PC_SPACE
	CALL	PRTHEXBYTE

	; DEBUG: DUMP MCR
	UART_INP(UART_MCR)
	CALL	PC_SPACE
	CALL	PRTHEXBYTE

	; DEBUG: DUMP EFR
	UART_INP(UART_LCR)
	PUSH	AF
	LD	A,$BF
	UART_OUTP(UART_LCR)
	UART_INP(UART_EFR)
	LD	H,A
	EX	(SP),HL
	LD	A,H
	UART_OUTP(UART_LCR)
	POP	AF
	CALL	PC_SPACE
	CALL	PRTHEXBYTE
	
	PRTC(']')
#ENDIF
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
;
;
UART_QUERY:
	LD	E,(IY+4)		; FIRST CONFIG BYTE TO E
	LD	D,(IY+5)		; SECOND CONFIG BYTE TO D
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
;
;
UART_DEVICE:
	LD	D,CIODEV_UART		; D := DEVICE TYPE
	LD	E,(IY)			; E := PHYSICAL UNIT
	LD	C,$00			; C := DEVICE TYPE, 0x00 IS RS-232
	LD	H,(IY+1)		; H := UART TYPE BYTE
	LD	L,(IY+2)		; L := BASE I/O ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET
;
; UART DETECTION ROUTINE
;
UART_DETECT:
	CALL	UART_CHIP		; DETECT CHIP VARIANT
	;LD	A,UART_16550A		; *DEBUG*
	OR	A
	RET	Z			; DONE IF NO CHIP
	LD	C,A			; PUT CHIP VARIANT IN C
;
#IF ((UARTINTS) & (INTMODE > 0))
;
	; CHECK TO SEE IF INT RCV WANTED ON THIS DEVICE
	PUSH	AF			; SAVE CHIP ID
	CP	UART_16550C		; 16550C OR LATER?
	JR	NC,UART_DETECT1		; NO INTS, USE AFC INSTEAD
	LD	A,(IY+7)		; MSB OF RING BUFFER
	OR	A			; SET FLAGS
	JR	Z,UART_DETECT1		; NO BUFFER, NO INTS ALLOWED
	SET	UART_INTACT,C		; SET INT RCV BIT
;
UART_DETECT1:
	POP	AF			; RESTORE CHIP ID
;
#ENDIF
;
	CP	UART_16550		; 16550 OR GREATER?
	JR	C,UART_DETECT2		; NO MORE FEATURES
	SET	UART_FIFOACT,C		; RECORD FIFO FEATURE
	CP	UART_16550C		; 16550C OR GREATER?
	JR	C,UART_DETECT2		; NO MORE FEATURES
	SET	UART_AFCACT,C		; RECORD AFC FEATURE
;
UART_DETECT2:
	LD	A,C			; RETURN RESULT IN A
	RET
;
; DETERMINE THE UART CHIP VARIANT AND RETURN IN A
;
UART_CHIP:
;
	; SEE IF UART IS THERE BY CHECKING DLAB FUNCTIONALITY
	XOR	A			; ZERO ACCUM
	UART_OUTP(UART_IER)		; IER := 0
	LD	A,$80			; DLAB BIT ON
	UART_OUTP(UART_LCR)		; OUTPUT TO LCR (DLAB REGS NOW ACTIVE)
	LD	A,$5A			; LOAD TEST VALUE
	UART_OUTP(UART_DLM)		; OUTPUT TO DLM
	UART_INP(UART_DLM)		; READ IT BACK
	CP	$5A			; CHECK FOR TEST VALUE
	JP	NZ,UART_CHIP_NONE	; NOPE, UNKNOWN UART OR NOT PRESENT
	XOR	A			; DLAB BIT OFF
	UART_OUTP(UART_LCR)		; OUTPUT TO LCR (DLAB REGS NOW INACTIVE)
	UART_INP(UART_IER)		; READ IER
	CP	$5A			; CHECK FOR TEST VALUE
	JP	Z,UART_CHIP_NONE	; IF STILL $5A, UNKNOWN OR NOT PRESENT
;
	; TEST FOR FUNCTIONAL SCRATCH REG, IF NOT, WE HAVE AN 8250
	LD	A,$5A			; LOAD TEST VALUE
	UART_OUTP(UART_SCR)		; PUT IT IN SCRATCH REGISTER
	UART_INP(UART_SCR)		; READ IT BACK
	CP	$5A			; CHECK IT
	JR	NZ,UART_CHIP_8250	; STUPID 8250
;
	; TEST FOR EFR REGISTER WHICH IMPLIES 16650/850
	LD	A,$BF			; VALUE TO ENABLE EFR
	UART_OUTP(UART_LCR)		; WRITE IT TO LCR
	UART_INP(UART_SCR)		; READ SCRATCH REGISTER
	CP	$5A			; SPR STILL THERE?
	JR	NZ,UART_CHIP1		; NOPE, HIDDEN, MUST BE 16650/850
;
	; RESET LCR TO DEFAULT (DLAB OFF)
	;LD	A,$80			; DLAB BIT ON
	XOR	A			; DLAB BIT OFF
	UART_OUTP(UART_LCR)		; RESET LCR
;
	; TEST FCR TO ISOLATE 16450/550/550A
	LD	A,$E7			; TEST VALUE
	UART_OUTP(UART_FCR)		; PUT IT IN FCR
	UART_INP(UART_IIR)		; READ BACK FROM IIR
	BIT	6,A			; BIT 6 IS FIFO ENABLE, LO BIT
	JR	Z,UART_CHIP_16450	; IF NOT SET, MUST BE 16450
	BIT	7,A			; BIT 7 IS FIFO ENABLE, HI BIT
	JR	Z,UART_CHIP_16550	; IF NOT SET, MUST BE 16550
	BIT	5,A			; BIT 5 IS 64 BYTE FIFO
	JR	Z,UART_CHIP2		; IF NOT SET, MUST BE 16550A/C
	JR	UART_CHIP_16750	; ONLY THING LEFT IS 16750
;
UART_CHIP1:	; PICK BETWEEN 16650/850
	; RESET LCR TO DEFAULT (DLAB OFF)
	XOR	A			; DLAB BIT OFF
	UART_OUTP(UART_LCR)		; RESET LCR
	; NOT SURE HOW TO DIFFERENTIATE 16650 FROM 16850 YET
	JR	UART_CHIP_16650	; ASSUME 16650
;
UART_CHIP2:	; PICK BETWEEN 16550A/C
	; SET AFC BIT IN FCR
	LD	A,$20			; SET AFC BIT, MCR:5
	UART_OUTP(UART_MCR)		; WRITE NEW FCR VALUE
;
	; READ IT BACK, IF SET, WE HAVE 16550C
	UART_INP(UART_MCR)		; READ BACK MCR
	BIT	5,A			; CHECK AFC BIT
	JR	Z,UART_CHIP_16550A	; NOT SET, SO 16550A
	JR	UART_CHIP_16550C	; IS SET, SO 16550C
;
UART_CHIP_NONE:
	LD	A,UART_NONE		; NO UART DETECTED AT THIS PORT
	RET
;
UART_CHIP_8250:
	LD	A,UART_8250
	RET
;
UART_CHIP_16450:
	LD	A,UART_16450
	RET
;
UART_CHIP_16550:
	LD	A,UART_16550
	RET
;
UART_CHIP_16550A:
	LD	A,UART_16550A
	RET
;
UART_CHIP_16550C:
	LD	A,UART_16550C
	RET
;
UART_CHIP_16650:
	LD	A,UART_16650
	RET
;
UART_CHIP_16750:
	LD	A,UART_16750
	RET
;
UART_CHIP_16850:
	LD	A,UART_16850
	RET
;
; COMPUTE DIVISOR TO BC
;
UART_COMPDIV:
	; WE WANT TO DETERMINE A DIVISOR FOR THE UART CLOCK
	; THAT RESULTS IN THE DESIRED BAUD RATE.
	; BAUD RATE = UART CLK / DIVISOR, OR TO SOLVE FOR DIVISOR
	; DIVISOR = UART CLK / BAUDRATE.
	; THE UART CLOCK IS THE UART OSC PRESCALED BY 16.  ALSO, WE CAN
	; TAKE ADVANTAGE OF ENCODED BAUD RATES ALWAYS BEING A FACTOR OF 75.
	; SO, WE CAN USE (UART OSC / 16 / 75) / (BAUDRATE / 75)
;
	; FIRST WE DECODE THE BAUDRATE, BUT WE USE A CONSTANT OF 1 INSTEAD
	; OF THE NORMAL 75.  THIS PRODUCES (BAUDRATE / 75).
;
	LD	A,D			; GET CONFIG MSB
	AND	$1F			; ISOLATE ENCODED BAUD RATE
	LD	L,A			; PUT IN L
	LD	H,0			; H IS ALWAYS ZERO
	LD	DE,1			; USE 1 FOR ENCODING CONSTANT
	CALL	DECODE			; DE:HL := BAUD RATE, ERRORS IGNORED
	EX	DE,HL			; DE := (BAUDRATE / 75), DISCARD HL
	LD	HL,UARTOSC / 16 / 75	; HL := (UART OSC / 16 / 75)
	JP	DIV16			; BC := HL/DE == DIVISOR AND RETURN
;
;
;
UART_PRTCFG:
	; ANNOUNCE PORT
	CALL	NEWLINE			; FORMATTING
	PRTS("UART$")			; FORMATTING
	LD	A,(IY)			; DEVICE NUM
	CALL	PRTDECB			; PRINT DEVICE NUM
	PRTS(": IO=0x$")		; FORMATTING
	LD	A,(IY+2)		; GET BASE PORT
	CALL	PRTHEXBYTE		; PRINT BASE PORT

	; PRINT THE UART TYPE
	CALL	PC_SPACE		; FORMATTING
	LD	A,(IY+1)		; GET UART TYPE BYTE
	AND	$0F			; LOW BITS ONLY
	RLCA				; MAKE IT A WORD OFFSET
	LD	HL,UART_TYPE_MAP	; POINT HL TO TYPE MAP TABLE
	CALL	ADDHLA			; HL := ENTRY
	LD	E,(HL)			; DEREFERENCE
	INC	HL			; ...
	LD	D,(HL)			; ... TO GET STRING POINTER
	CALL	WRITESTR		; PRINT IT
;
	; ALL DONE IF NO UART WAS DETECTED
	LD	A,(IY+1)		; GET UART TYPE BYTE
	OR	A			; SET FLAGS
	RET	Z			; IF ZERO, NOT PRESENT
;
	PRTS(" MODE=$")			; FORMATTING
	LD	E,(IY+4)		; LOAD CONFIG
	LD	D,(IY+5)		; ... WORD TO DE
	CALL	PS_PRTSC0		; PRINT CONFIG
;
	; PRINT FEATURES ENABLED
	BIT	UART_INTACT,(IY+1)	; GET INT RCV BIT
	JR	Z,UART_PRTCFG1
	PRTS(" INT$")
;
UART_PRTCFG1:
	BIT	UART_FIFOACT,(IY+1)	; GET FIFO BIT
	JR	Z,UART_PRTCFG2
	PRTS(" FIFO$")
;
UART_PRTCFG2:
	BIT	UART_AFCACT,(IY+1)	; GET AFC BIT
	JR	Z,UART_PRTCFG3
	PRTS(" AFC$")
;
UART_PRTCFG3:
	BIT	UART_CTSBAD,(IY+1)	; GET BADCTS BIT
	JR	Z,UART_PRTCFG4
	PRTS(" NO_CTS!$")
;
UART_PRTCFG4:
;
	XOR	A
	RET
;
; ROUTINES TO READ/WRITE PORTS INDIRECTLY
;
; READ VALUE OF UART PORT ON TOS INTO REGISTER A
;
UART_INP_IMP:
	EX	(SP),HL		; SWAP HL AND TOS
	PUSH	BC		; PRESERVE BC
	LD	A,(IY+2)	; GET UART IO BASE PORT
	OR	(HL)		; OR IN REGISTER ID BITS
	LD	C,A		; C := PORT
	IN	A,(C)		; READ PORT INTO A
	POP	BC		; RESTORE BC
	INC	HL		; BUMP HL PAST REG ID PARM
	EX	(SP),HL		; SWAP BACK HL AND TOS
	RET
;
; WRITE VALUE IN REGISTER A TO UART PORT ON TOS
;
UART_OUTP_IMP:
	EX	(SP),HL		; SWAP HL AND TOS
	PUSH	BC		; PRESERVE BC
	LD	B,A		; PUT VALUE TO WRITE IN B
	LD	A,(IY+2)	; GET UART IO BASE PORT
	OR	(HL)		; OR IN REGISTER ID BITS
	LD	C,A		; C := PORT
	OUT	(C),B		; WRITE VALUE TO PORT
	POP	BC		; RESTORE BC
	INC	HL		; BUMP HL PAST REG ID PARM
	EX	(SP),HL		; SWAP BACK HL AND TOS
	RET
;
;
;
UART_TYPE_MAP:
			.DW	UART_STR_NONE
			.DW	UART_STR_8250
			.DW	UART_STR_16450
			.DW	UART_STR_16550
			.DW	UART_STR_16550A
			.DW	UART_STR_16550C
			.DW	UART_STR_16650
			.DW	UART_STR_16750
			.DW	UART_STR_16850

UART_STR_NONE		.DB	"<NOT PRESENT>$"
UART_STR_8250		.DB	"8250$"
UART_STR_16450		.DB	"16450$"
UART_STR_16550		.DB	"16550$"
UART_STR_16550A		.DB	"16550A$"
UART_STR_16550C		.DB	"16550C$"
UART_STR_16650		.DB	"16650$"
UART_STR_16750		.DB	"16750$"
UART_STR_16850		.DB	"16850$"
;
UART_PAR_MAP		.DB	"NONENMNS"
;
; WORKING VARIABLES
;
UART_DEV		.DB	0		; DEVICE NUM USED DURING INIT
;
; UART PORT TABLE
;
UART_CFG:
;
#IF (UARTCNT >= 1)
UART0_CFG:
	.DB	0				; DEVICE NUMBER (SET DURING INIT)	; +0
	.DB	0				; UART TYPE (SET DURING INIT)		; +1
	.DB	UART0BASE			; IO PORT BASE (RBR, THR)		; +2
	.DB	UART0BASE + UART_LSR		; LINE STATUS PORT (LSR)		; +3
	.DW	UART0CFG			; LINE CONFIGURATION			; +4
	.DW	UART0_RCVBUF			; POINTER TO RCV BUFFER STRUCT		; +6
;
	DEVECHO	"UART: IO="
	DEVECHO	UART0BASE
  #IF ((UARTINTS) & (INTMODE > 0))
	DEVECHO	", INTERRUPTS ENABLED"
  #ENDIF
	DEVECHO	"\n"
#ENDIF
;
#IF (UARTCNT >= 2)
UART1_CFG:
	.DB	0				; DEVICE NUMBER (SET DURING INIT)
	.DB	0				; UART TYPE (SET DURING INIT)
	.DB	UART1BASE			; IO PORT BASE (RBR, THR)
	.DB	UART1BASE + UART_LSR		; LINE STATUS PORT (LSR)
	.DW	UART1CFG			; LINE CONFIGURATION
	.DW	UART1_RCVBUF			; POINTER TO RCV BUFFER STRUCT
;
	DEVECHO	"UART: IO="
	DEVECHO	UART1BASE
  #IF ((UARTINTS) & (INTMODE > 0))
	DEVECHO	", INTERRUPTS ENABLED"
  #ENDIF
	DEVECHO	"\n"
#ENDIF
;
#IF (UARTCNT >= 3)
UART2_CFG:
	.DB	0				; DEVICE NUMBER (SET DURING INIT)
	.DB	0				; UART TYPE (SET DURING INIT)
	.DB	UART2BASE			; IO PORT BASE (RBR, THR)
	.DB	UART2BASE + UART_LSR		; LINE STATUS PORT (LSR)
	.DW	UART2CFG			; LINE CONFIGURATION
	.DW	0				; POINTER TO RCV BUFFER STRUCT
;
	DEVECHO	"UART: IO="
	DEVECHO	UART2BASE
	DEVECHO	"\n"
#ENDIF
;
#IF (UARTCNT >= 4)
UART3_CFG:
	.DB	0				; DEVICE NUMBER (SET DURING INIT)
	.DB	0				; UART TYPE (SET DURING INIT)
	.DB	UART3BASE			; IO PORT BASE (RBR, THR)
	.DB	UART3BASE + UART_LSR		; LINE STATUS PORT (LSR)
	.DW	UART3CFG			; LINE CONFIGURATION
	.DW	0				; POINTER TO RCV BUFFER STRUCT
;
	DEVECHO	"UART: IO="
	DEVECHO	UART3BASE
	DEVECHO	"\n"
#ENDIF
;
#IF (UARTCNT >= 5)
UART4_CFG:
	.DB	0				; DEVICE NUMBER (SET DURING INIT)
	.DB	0				; UART TYPE (SET DURING INIT)
	.DB	UART4BASE			; IO PORT BASE (RBR, THR)
	.DB	UART4BASE + UART_LSR		; LINE STATUS PORT (LSR)
	.DW	UART4CFG			; LINE CONFIGURATION
	.DW	0				; POINTER TO RCV BUFFER STRUCT
;
	DEVECHO	"UART: IO="
	DEVECHO	UART4BASE
	DEVECHO	"\n"
#ENDIF
;
#IF (UARTCNT >= 6)
UART5_CFG:
	.DB	0				; DEVICE NUMBER (SET DURING INIT)
	.DB	0				; UART TYPE (SET DURING INIT)
	.DB	UART5BASE			; IO PORT BASE (RBR, THR)
	.DB	UART5BASE + UART_LSR		; LINE STATUS PORT (LSR)
	.DW	UART5CFG			; LINE CONFIGURATION
	.DW	0				; POINTER TO RCV BUFFER STRUCT
;
	DEVECHO	"UART: IO="
	DEVECHO	UART5BASE
	DEVECHO	"\n"
#ENDIF
;
#IF (UARTCNT >= 7)
UART6_CFG:
	.DB	0				; DEVICE NUMBER (SET DURING INIT)
	.DB	0				; UART TYPE (SET DURING INIT)
	.DB	UART6BASE			; IO PORT BASE (RBR, THR)
	.DB	UART6BASE + UART_LSR		; LINE STATUS PORT (LSR)
	.DW	UART6CFG			; LINE CONFIGURATION
	.DW	0				; POINTER TO RCV BUFFER STRUCT
;
	DEVECHO	"UART: IO="
	DEVECHO	UART6BASE
	DEVECHO	"\n"
#ENDIF
;
#IF (UARTCNT >= 8)
UART7_CFG:
	.DB	0				; DEVICE NUMBER (SET DURING INIT)
	.DB	0				; UART TYPE (SET DURING INIT)
	.DB	UART7BASE			; IO PORT BASE (RBR, THR)
	.DB	UART7BASE + UART_LSR		; LINE STATUS PORT (LSR)
	.DW	UART7CFG			; LINE CONFIGURATION
	.DW	0				; POINTER TO RCV BUFFER STRUCT
;
	DEVECHO	"UART: IO="
	DEVECHO	UART7BASE
	DEVECHO	"\n"
#ENDIF
;
#IF ((!UARTINTS) | (INTMODE == 0))
;
UART0_RCVBUF	.EQU	0
UART1_RCVBUF	.EQU	0
;
#ELSE
;
; UART SBC RECEIVE BUFFER
;
  #IF (UARTCNT >= 1)
;
UART0_RCVBUF:
UART0_CNT	.DB	0		; CHARACTERS IN RING BUFFER
UART0_HD	.DW	UART0_BUF	; BUFFER HEAD POINTER
UART0_TL	.DW	UART0_BUF	; BUFFER TAIL POINTER
UART0_BUF	.FILL	UART_BUFSZ,0	; RECEIVE RING BUFFER
;
  #ENDIF
;
; UART CASSETTE RECEIVE BUFFER
;
  #IF (UARTCNT >= 2)
;
UART1_RCVBUF:
UART1_CNT	.DB	0		; CHARACTERS IN RING BUFFER
UART1_HD	.DW	UART1_BUF	; BUFFER HEAD POINTER
UART1_TL	.DW	UART1_BUF	; BUFFER TAIL POINTER
UART1_BUF	.FILL	UART_BUFSZ,0	; RECEIVE RING BUFFER
;
  #ENDIF
;
#ENDIF
