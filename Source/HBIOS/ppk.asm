;__________________________________________________________________________________________________
;
;	PARALLEL PORT KEYBOARD DRIVER FOR SBC
;       SUPPORT KEYBOARD/MOUSE ON VDU AND N8
;
;	ORIGINAL CODE BY DR JAMES MOXHAM
;	ROMWBW ADAPTATION BY WAYNE WARTHEN
;__________________________________________________________________________________________________
;
; TODO:
;__________________________________________________________________________________________________
; DATA CONSTANTS
;__________________________________________________________________________________________________
;
; DRIVER DATA OFFSETS (FROM IY)
;
PPK_PPIA	.EQU	0	; PPI PORT A
PPK_PPIB	.EQU	1	; PPI PORT B
PPK_PPIC	.EQU	2	; PPI PORT C
PPK_PPIX	.EQU	3	; PPI CONTROL PORT
;
; DRIVER CONSTANTS
;
PPK_DAT		.EQU	01111000B	; PPIX MASK TO MANAGE DATA LINE (C:4)
PPK_CLK		.EQU	01111010B	; PPIX MASK TO MANAGE CLOCK LINE (C:5)
;
PPK_WAITRDY	.EQU	6		; TUNE!!! LOOP COUNT TO ENSURE DEVICE READY
;
; STATUS BITS (FOR PPK_STATUS)
;
PPK_EXT		.EQU	01H	; BIT 0, EXTENDED SCANCODE ACTIVE
PPK_BREAK	.EQU	02H	; BIT 1, THIS IS A KEY UP (BREAK) EVENT
PPK_KEYRDY	.EQU	80H	; BIT 7, INDICATES A DECODED KEYCODE IS READY
;
; STATE BITS (FOR PPK_STATE, PPK_LSTATE, PPK_RSTATE)
;
PPK_SHIFT	.EQU	01H	; BIT 0, SHIFT ACTIVE (PRESSED)
PPK_CTRL	.EQU	02H	; BIT 1, CONTROL ACTIVE (PRESSED)
PPK_ALT		.EQU	04H	; BIT 2, ALT ACTIVE (PRESSED)
PPK_WIN		.EQU	08H	; BIT 3, WIN ACTIVE (PRESSED)
PPK_SCRLCK	.EQU	10H	; BIT 4, CAPS LOCK ACTIVE (TOGGLED ON)
PPK_NUMLCK	.EQU	20H	; BIT 5, NUM LOCK ACTIVE (TOGGLED ON)
PPK_CAPSLCK	.EQU	40H	; BIT 6, SCROLL LOCK ACTIVE (TOGGLED ON)
PPK_NUMPAD	.EQU	80H	; BIT 7, NUM PAD KEY (KEY PRESSED IS ON NUM PAD)
;
PPK_DEFRPT	.EQU	$40		; DEFAULT REPEAT RATE (.5 SEC DELAY, 30CPS)
PPK_DEFSTATE	.EQU	PPK_NUMLCK	; DEFAULT STATE (NUM LOCK ON)
;
;__________________________________________________________________________________________________
; DATA
;__________________________________________________________________________________________________
;
PPK_SCANCODE	.DB	0	; RAW SCANCODE
PPK_KEYCODE	.DB	0	; RESULTANT KEYCODE AFTER DECODING
PPK_STATE	.DB	0	; STATE BITS (SEE ABOVE)
PPK_LSTATE	.DB	0	; STATE BITS FOR "LEFT" KEYS
PPK_RSTATE	.DB	0	; STATE BITS FOR "RIGHT" KEYS
PPK_STATUS	.DB	0	; CURRENT STATUS BITS (SEE ABOVE)
PPK_REPEAT	.DB	0	; CURRENT REPEAT RATE
PPK_IDLE	.DB	0	; IDLE COUNT
PPK_WAITTO	.DW	0	; TIMEOUT WAIT LOOP COUNT (COMPUTED IN INIT)
;
	.ECHO	"PPK: ENABLED\n"
;
;__________________________________________________________________________________________________
; KEYBOARD INITIALIZATION
;__________________________________________________________________________________________________
;
PPK_INIT:
	CALL	NEWLINE			; FORMATTING
	PRTS("PPK: IO=0x$")
	LD	A,(IY+PPK_PPIA)
	CALL	PRTHEXBYTE
;
	; PRECOMPUTE TIMEOUT LOOP COUNT (CPU KHZ / 16)
	LD	HL,(CB_CPUKHZ)		; GET CPU SPEED IN KHZ
	LD	B,4			; SHIFT 4 TIMES TO DIVIDE BY 16
PPK_INIT1:
	SRL	H			; RIGHT SHIFT
	RR	L			; ... TO DIVIDE
	DJNZ	PPK_INIT1		; LOOP UNTIL DONE DIVIDING
	LD	(PPK_WAITTO),HL		; SAVE RESULT FOR USE LATER
;
	CALL 	PPK_INITPORT		; SETS PORT C SO CAN INPUT AND OUTPUT

	LD	A,PPK_DEFRPT		; GET DEFAULT REPEAT RATE
	LD	(PPK_REPEAT),A		; SAVE IT
	LD	A,PPK_DEFSTATE		; GET DEFAULT STATE
	LD	(PPK_STATE),A		; SAVE IT

	CALL 	PPK_RESET		; RESET THE KEYBOARD
	CALL	PPK_SETLEDS		; UPDATE LEDS BASED ON CURRENT TOGGLE STATE BITS
	CALL	PPK_SETRPT		; UPDATE REPEAT RATE BASED ON CURRENT SETTING
	
	XOR	A			; SIGNAL SUCCESS
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD STATUS
;__________________________________________________________________________________________________
;
; CHECKING THE KEYBOARD REQUIRES "WAITING" FOR A KEY TO BE SENT AND USING A TIMEOUT
; TO DETECT THAT NO KEY IS READY.  MANY APPS CALL STATUS REPEATEDLY.  IN ORDER TO AVOID
; SLOWING THEM DOWN, WE IGNORE 255/256 OF THE CALLS.
;
PPK_STAT:
	LD	A,(PPK_IDLE)		; GET IDLE COUNT
	DEC	A			; DECREMENT IT
	LD	(PPK_IDLE),A		; SAVE IT
	JR	Z,PPK_STAT1		; IF ZERO, DO REAL CHECK
	XOR	A			; SIGNAL NOTHING READY
	JP	CIO_IDLE		; RETURN VIA IDLE PROCESSING
;
PPK_STAT1:
	CALL	PPK_DECODE		; CHECK THE KEYBOARD
	JP	Z,CIO_IDLE		; RET VIA IDLE PROCESSING IF NO KEY
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD READ
;
;   RETURNS ASCII VALUE IN E.  SEE END OF FILE FOR VALUES RETURNED FOR SPECIAL KEYS
;   LIKE PGUP, ARROWS, FUNCTION KEYS, ETC.
;__________________________________________________________________________________________________
;
PPK_READ:
	CALL	PPK_STAT		; KEY READY?
	JR	Z,PPK_READ		; NOT READY, KEEP TRYING
;
	LD	A,(PPK_STATE)		; GET STATE
	AND	$01			; ISOLATE EXTENDED SCANCODE BIT
	RRCA				; ROTATE IT TO HIGH ORDER BIT
	LD	E,A			; SAVE IT IN E FOR NOW
	LD	A,(PPK_SCANCODE)	; GET SCANCODE
	OR	E			; COMBINE WITH EXTENDED BIT
	LD	C,A			; STORE IT IN C FOR RETURN
	LD	A,(PPK_KEYCODE)		; GET KEYCODE
	LD	E,A			; SAVE IT IN E
	LD	A,(PPK_STATE)		; GET STATE FLAGS
	LD	D,A			; SAVE THEM IN D
	XOR	A			; SIGNAL SUCCESS
	LD	(PPK_STATUS),A		; CLEAR STATUS TO INDICATE BYTE RECEIVED
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD FLUSH
;__________________________________________________________________________________________________
;
PPK_FLUSH:
	XOR	A			; A = 0
	LD	(PPK_STATUS),A		; CLEAR STATUS
	RET
;
;__________________________________________________________________________________________________
; HARDWARE INTERFACE
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
PPK_GETDATA:
;
; GET RAW BYTE FROM KEYBOARD INTERFACE INTO A
; IF TIMEOUT, RETURN WITH A=0 AND Z SET
;
	CALL	PPK_CLKHI		; ALLOW KEYBOARD TO XMIT
	CALL	PPK_WTCLKLO		; WAIT FOR CLOCK LINE TO GO LOW
	JP	NZ,PPK_GETDATA1		; IF IT WENT LOW, READ THE BYTE
	CALL	PPK_CLKLO		; SUPPRESS KEYBOARD XMIT
	XOR	A			; SIGNAL TIMEOUT
	RET
	
PPK_GETDATA1:
	CALL 	PPK_WTCLKHI		; WAIT FOR END OF START BIT
	LD 	B,8			; SAMPLE 8 TIMES
	LD 	E,0			; START WITH E=0

PPK_GETDATA2:
	CALL 	PPK_WTCLKLO		; WAIT TILL CLOCK GOES LOW
	LD	C,(IY+PPK_PPIB)		; C := PPI PORT B
	IN 	A,(C)			; SAMPLE THE DATA LINE
	RRA				; MOVE THE DATA BIT INTO THE CARRY REGISTER
	LD 	A,E			; GET THE BYTE WE ARE BUILDING IN E
	RRA				; MOVE THE CARRY BIT INTO BIT 7 AND SHIFT RIGHT
	LD 	E,A			; STORE IT BACK  AFTER 8 CYCLES 1ST BIT READ WILL BE IN B0
	CALL 	PPK_WTCLKHI		; WAIT TILL GOES HIGH
	DJNZ 	PPK_GETDATA2		; DO THIS 8 TIMES
	CALL 	PPK_WTCLKLO		; GET THE PARITY BIT
	CALL 	PPK_WTCLKHI
	CALL 	PPK_WTCLKLO		; GET THE STOP BIT
	CALL 	PPK_WTCLKHI
	CALL	PPK_CLKLO		; SUPPRESS KEYBOARD XMIT
	LD 	A,E			; RETURN WITH RAW SCANCODE BYTE IN A

#IF (PPKTRACE >= 2)
	CALL	PC_SPACE
	CALL	PC_LT
	CALL	PRTHEXBYTE
#ENDIF

	OR	A
	RET
;
;__________________________________________________________________________________________________
PPK_GETDATAX:
;
; GET A RAW DATA BYTE FROM KEYBOARD INTERFACE INTO A WITH NOTIMEOUT
; IN THE CASE OF PPK, THERE IS NO QUICK WAY TO CHECK FOR A KEY WAITING,
; SO WE JUST CHAIN TO GETDATA
;
	JR	PPK_GETDATA		; CHAIN TO GETDATA
;
;__________________________________________________________________________________________________
PPK_PUTDATA:
;
; PUT A RAW BYTE FROM A TO THE KEYBOARD INTERFACE
;
	LD	E,A			; STASH INCOMING BYTE VALUE IN E
	
#IF (PPKTRACE >= 2)
	CALL	PC_SPACE
	CALL	PC_GT
	CALL	PRTHEXBYTE
#ENDIF

	; START WITH DATA HI AND CLOCK LOW
	CALL	PPK_DATHI
	CALL 	PPK_CLKLO		; NEED CLOCK LOW TO GET DEVICE ATTENTION

	; WAIT 100US(?) TO MAKE SURE DEVICE IS READY TO RECEIVE
	LD	B,PPK_WAITRDY		; DELAY 6 * 16US = 96US 
PPK_PUTDATA0:
	CALL	DELAY			; INVOKE 16US DELAY
	DJNZ	PPK_PUTDATA0		; LOOP

	; SEND START BIT
	CALL 	PPK_DATLO		; SET DATA LOW - REQUEST TO SEND/START BIT
	CALL 	PPK_CLKHI		; RELEASE THE CLOCK LINE
	CALL 	PPK_WTCLKLO		; DEVICE HAS RECEIVED THE START BIT

	; SEND DATA BITS
	LD	B,8			; 8 DATA BITS
PPK_PUTDATA1:
	RRC	E			; ROTATE LOW BIT OF E TO CARRY (NEXT BIT TO SEND)
	LD	A,PPK_DAT >> 1		; INIT A WITH DATA MASK SHIFTED RIGHT BY ONE BIT
	RLA				; SHIFT CARRY INTO LOW BIT OF A
	LD	C,(IY+PPK_PPIX)		; C := PPI CONTROL PORT
	OUT	(C),A			; SET/RESET DATA LINE FOR NEXT BIT VALUE
	CALL 	PPK_WTCLKHI		; WAIT FOR CLOCK TO TRANSTION HI
	CALL 	PPK_WTCLKLO		; THEN LO, BIT HAS NOW BEEN RECEIVED BY DEVICE
	DJNZ	PPK_PUTDATA1		; LOOP TO SEND 8 DATA BITS

	; SEND PARITY BIT
	XOR	A			; CLEAR A
	OR	E			; OR WITH SENT VALUE, SETS PARITY FLAG!
	LD	A,PPK_DAT		; PREPARE A WITH DATA MASK
	JP	PO,PPK_PUTDATA2		; PARITY IS ALREADY ODD, LEAVE A ALONE
	INC	A			; SET PARITY BIT BY INCREMENTING A
PPK_PUTDATA2:
	LD	C,(IY+PPK_PPIX)		; C := PPI CONTROL PORT
	OUT	(C),A			; SET THE DATA LINE
	CALL 	PPK_WTCLKHI		; WAIT FOR CLOCK TO TRANSITION HI
	CALL 	PPK_WTCLKLO		; THEN LO, BIT HAS NOW BEEN RECEIVED BY DEVICE
	
	; SEND STOP BIT, NO NEED TO WATCH CLOCK, JUST WAIT FOR START OF DEVICE ACK
	CALL	PPK_DATHI		; STOP BIT IS 1 (HI)
	
	; HANDLE DEVICE ACK
	CALL	PPK_WTDATLO		; WAIT FOR DEVICE TO START ACK
	CALL	PPK_WTCLKLO		; WAIT FOR CLOCK TO TRANSITION LO
	CALL	PPK_WTCLKHI		; THEN HI
	CALL	PPK_WTDATHI		; FINALLY WAIT FOR DEVICE TO RELEASE DATA LINE
	
	; ASSERT CLOCK TO INHIBIT DEVICE FROM SENDING US ANYTHING UNTIL WE ARE READY
	CALL	PPK_CLKLO		; SET CLOCK LOW
	
	RET
;
;__________________________________________________________________________________________________
PPK_INITPORT:
;
; INITIALIZE PPI
;	
	LD 	A,10000010B		; A=OUT B=IN, C HIGH=OUT, CLOW=OUT
	LD	C,(IY+PPK_PPIX)		; C := PPI CONTROL PORT
	OUT	(C),A			; SET PPI CONTROL PORT
	XOR	A			; A=0
	LD	C,(IY+PPK_PPIA)		; C := PPI PORT A
	OUT	(C),A			; PPI PORT A TO ZERO (REQUIRED FOR PAR PRINTER)
	CALL 	PPK_DATHI		; KBD DATA LINE HI (IDLE)
	CALL 	PPK_CLKHI		; KBD CLOCK LINE HI (IDLE)
	RET
;
;__________________________________________________________________________________________________
;
; BIT TESTING (PORT B)
;
;   B:0 = KBD DATA LINE (INPUT)
;   B:1 = KBD CLOCK LINE (INPUT)
;
;   TEST PPI PORT B BIT(S) DESIGNATED BY BITMASK IN D AFTER XOR WITH E
;   WAIT FOR ANY OF THE DESIGNATED BITS TO BE SET, THEN RETURN
;   IF TIMEOUT, RETURN WITH A=0 AND Z SET
;   HL IS DESTROYED, A IS OVERWRITTEN WITH RETURN VALUE
;
PPK_WTCLKLO:	; WAIT FOR CLOCK LINE TO BE LOW
	PUSH	DE
	LD	DE,0202H	; TEST BIT 1 AFTER INVERTING
	JR	PPK_WAIT
;
PPK_WTCLKHI:	; WAIT FOR CLOCK LINE TO BE HIGH
	PUSH	DE
	LD	DE,0200H	; TEST BIT 1
	JR	PPK_WAIT
;
PPK_WTDATLO:	; WAIT FOR DATA LINE TO BE LOW
	PUSH	DE
	LD	DE,0101H	; TEST BIT 0 AFTER INVERTING
	JR	PPK_WAIT
;
PPK_WTDATHI:	; WAIT FOR DATA LINE TO BE HIGH
	PUSH	DE
	LD	DE,0100H	; TEST BIT 0
	JR	PPK_WAIT
;
PPK_WAIT:	; COMPLETE THE WAIT PROCESSING
	LD	HL,(PPK_WAITTO)
PPK_WAIT1:
	LD	C,(IY+PPK_PPIB)	; C := PPI PORT B
	IN 	A,(C)		; GET BYTE FROM PORT B
	XOR	E
	AND	D
	JR 	NZ,PPK_WAIT2	; EXIT IF ANY BIT IS SET
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,PPK_WAIT1
PPK_WAIT2:
	POP	DE
	RET
;
;__________________________________________________________________________________________________
;
; BIT MANAGEMENT (PORT C)
;
;   C:4 = KBD DATA LINE (LATCHED OUTPUT)
;   C:5 = KBD CLOCK LINE (LATCHED OUTPUT)
;
;   A IS DESTROYED (OVERWRITTEN WITH PORT OUTPUT VALUE)
;
PPK_DATHI:
	LD	A,PPK_DAT + 1
	JR	PPK_SETBIT
PPK_DATLO:
	LD	A,PPK_DAT
	JR	PPK_SETBIT
PPK_CLKHI:
	LD	A,PPK_CLK + 1
	JR	PPK_SETBIT
PPK_CLKLO:
	LD	A,PPK_CLK
	JR	PPK_SETBIT
PPK_SETBIT:
	LD	C,(IY+PPK_PPIX)	; C := PPI CONTROL PORT
	OUT	(C),A
	RET
;
;__________________________________________________________________________________________________
; RESET KEYBOARD
;__________________________________________________________________________________________________
;
PPK_RESET:
	LD	A,$FF		; RESET COMMAND
	CALL	PPK_PUTDATA	; SEND IT
	CALL	PPK_GETDATA	; GET THE ACK
	LD	B,0		; SETUP LOOP COUNTER
PPK_RESET0:
	PUSH	BC		; PRESERVE COUNTER
	CALL	DELAY		; DELAY 25MS
	CALL	PPK_GETDATA	; TRY TO GET THE RESPONSE
	POP	BC		; RECOVER COUNTER
	JR	NZ,PPK_RESET1	; GOT A BYTE?  IF SO, GET OUT OF LOOP
	DJNZ	PPK_RESET0	; LOOP TILL COUNTER EXHAUSTED
PPK_RESET1:
	LD	A,B
	XOR	A		; SIGNAL SUCCESS (RESPONSE IS IGNORED...)
	RET			; DONE
;
;__________________________________________________________________________________________________
; UPDATE KEYBOARD LEDS BASED ON CURRENT TOGGLE FLAGS
;__________________________________________________________________________________________________
;
PPK_SETLEDS:
	LD	A,$ED		; SET/RESET LED'S COMMAND
	CALL	PPK_PUTDATA	; SEND THE COMMAND
	CALL	PPK_GETDATA	; READ THE RESPONSE
	CP	$FA		; MAKE SURE WE GET ACK
	RET	NZ		; ABORT IF NO ACK
	LD	A,(PPK_STATE)	; LOAD THE STATE BYTE
	RRCA			; ROTATE TOGGLE KEY BITS AS NEEDED
	RRCA
	RRCA
	RRCA
	AND	$07		; CLEAR THE IRRELEVANT BITS
	CALL	PPK_PUTDATA	; SEND THE LED DATA
	CALL	PPK_GETDATA	; READ THE ACK
	JP	PPK_DECNEW	; RESTART DECODER FOR A NEW KEY
	RET			; DONE
;
;__________________________________________________________________________________________________
; UPDATE KEYBOARD REPEAT RATE BASED ON CURRENT SETTING
;__________________________________________________________________________________________________
;
PPK_SETRPT:
	LD	A,$F3		; COMMAND = SET TYPEMATIC RATE/DELAY
	CALL	PPK_PUTDATA	; SEND IT
	CALL	PPK_GETDATA	; GET THE ACK
	CP	$FA		; MAKE SURE WE GET ACK
	RET	NZ		; ABORT IF NO ACK
	LD	A,(PPK_REPEAT)	; LOAD THE CURRENT RATE/DELAY BYTE
	CALL	PPK_PUTDATA	; SEND IT
	CALL	PPK_GETDATA	; GET THE ACK
	RET
;
;__________________________________________________________________________________________________
; DECODING ENGINE
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
PPK_DECODE:
;
;  RUN THE DECODING ENGINE UNTIL EITHER: 1) NO MORE SCANCODES ARE AVAILABLE
;  FROM THE KEYBOARD, OR 2) A DECODED KEY VALUE IS AVAILABLE
;
;  RETURNS A=0 AND Z SET IF NO KEYCODE READY, OTHERWISE A DECODED KEY VALUE IS AVAILABLE.
;  THE DECODED KEY VALUE AND KEY STATE IS STORED IN PPK_KEYCODE AND PPK_STATE.
;
;  PPK_STATUS IS NOT CLEARED AT START. IT IS THE CALLER'S RESPONSIBILITY
;  TO CLEAR PPK_STATUS WHEN IT HAS RETRIEVED A PENDING VALUE.  IF DECODE IS CALLED
;  WITH A KEYCODE STILL PENDING, IT WILL JUST RETURN WITHOUT DOING ANYTHING.
;
; Step 0: Check keycode buffer
;   if status[keyrdy]
;     return
; 
; Step 1: Get scancode
;   if no scancode ready
;     return
;   read scancode
;
; Step 2: Detect and handle special keycodes
;   if scancode == $AA
;     *** handle hot insert somehow ***
; 
; Step 3: Detect and handle scancode prefixes
;   if scancode == $E0
;     set status[extended]
;     goto Step 1
; 
;   if scancode == $E1
;     *** handle pause key somehow ***
; 
; Step 4: Detect and flag break event
;   *** scancode set #1 variation ***
;     set status[break] = high bit of scancode
;     clear high order bit
;     continue to Step 5
;   *** scancode set #2 variation ***
;     if scancode == $F0
;       set status[break]
;       goto Step 1
; 
; Step 5: Map scancode to keycode 
;   if status[extended]
;     apply extended-map[scancode] -> keycode
;   else if state[shifted]
;     apply shifted-map[scancode] -> keycode
;   else
;     apply normal-map[scancode] -> keycode
; 
; Step 6: Handle modifier keys
;   if keycode is modifier (shift, ctrl, alt, win)
;     set (l/r)state[<modifier>] = not status[break]
;     clear modifier bits in state
;     set state = (lstate OR rstate OR state)
;     goto New Key
; 
; Step 7: Complete procesing of key break events
;   if status[break]
;     goto New Key
; 
; Step 8: Handle toggle keys
;   if keycode is toggle (capslock, numlock, scrolllock)
;     invert (XOR) state[<toggle>]
;     update keyboard LED's
;     goto New Key
; 
; Step 9: Adjust keycode for control modifier
;   if state[ctrl]
;     if keycode is 'a'-'z'
;       subtract 20 (clear bit 5) from keycode
;     if keycode is '@'-'_'
;       subtract 40 (clear bit 6) from keycode
; 
; Step 10: Adjust keycode for caps lock
;   if state[capslock]
;     if keycode is 'a'-'z' OR 'A'-'Z'
;       toggle (XOR) bit 5 of keycode
; 
; Step 11: Handle num pad keys
;   clear state[numpad]
;   if keycode is numpad
;     set state[numpad]
;     if state[numlock]
;       toggle (XOR) bit 4 of keycode
;     apply numpad-map[keycode] -> keycode
; 
; Step 12: Detect unknown/invalid keycodes
;   if keycode == $FF
;     goto New Key
; 
; Step 13: Done
;   set status[keyrdy]
;   return
;
; New Key:
;   clear status
;   goto Step 1
;
PPK_DEC0:	; CHECK KEYCODE BUFFER
	LD	A,(PPK_STATUS)		; GET CURRENT STATUS
	AND	PPK_KEYRDY		; ISOLATE KEY READY FLAG
	RET	NZ			; ABORT IF KEY IS ALREADY PENDING

PPK_DEC1:	; PROCESS NEXT SCANCODE
	CALL	PPK_GETDATAX		; GET THE SCANCODE
	RET	Z			; NO KEY READY, RETURN WITH A=0, Z SET
	LD	(PPK_SCANCODE),A	; SAVE SCANCODE

PPK_DEC2:	; DETECT AND HANDLE SPECIAL KEYCODES
	LD	A,(PPK_SCANCODE)	; GET THE CURRENT SCANCODE
	CP	$AA			; KEYBOARD INSERTION?
	JR	NZ,PPK_DEC3		; NOPE, BYPASS
	CALL	LDELAY			; WAIT A BIT
	CALL	PPK_RESET		; RESET KEYBOARD
	CALL	PPK_SETLEDS		; SET LEDS
	CALL	PPK_SETRPT		; SET REPEAT RATE
	JP	PPK_DECNEW		; RESTART THE ENGINE

PPK_DEC3:	; DETECT AND HANDLE SCANCODE PREFIXES
	LD	A,(PPK_SCANCODE)	; GET THE CURRENT SCANCODE

PPK_DEC3A:	; HANDLE SCANCODE PREFIX $E0 (EXTENDED SCANCODE FOLLOWS)
	CP	$E0			; EXTENDED KEY PREFIX $E0?
	JR	NZ,PPK_DEC3B		; NOPE MOVE ON
	LD	A,(PPK_STATUS)		; GET STATUS
	OR	PPK_EXT			; SET EXTENDED BIT
	LD	(PPK_STATUS),A		; SAVE STATUS
	JR	PPK_DEC1		; LOOP TO DO NEXT SCANCODE

PPK_DEC3B:	; HANDLE SCANCODE PREFIX $E1 (PAUSE KEY)
	CP	$E1			; EXTENDED KEY PREFIX $E1
	JR	NZ,PPK_DEC4		; NOPE MOVE ON
	LD	A,$EE			; MAP TO KEYCODE $EE
	LD	(PPK_KEYCODE),A		; SAVE IT
		; SWALLOW NEXT 7 SCANCODES
	LD	B,7			; LOOP 5 TIMES
PPK_DEC3B1:
	PUSH	BC
	CALL	PPK_GETDATA		; RETRIEVE NEXT SCANCODE
	POP	BC
	DJNZ	PPK_DEC3B1		; LOOP AS NEEDED
	JP	PPK_DEC6		; RESUME AFTER MAPPING

PPK_DEC4:	; DETECT AND FLAG BREAK EVENT
	CP	$F0			; BREAK (KEY UP) PREFIX?
	JR	NZ,PPK_DEC5		; NOPE MOVE ON
	LD	A,(PPK_STATUS)		; GET STATUS
	OR	PPK_BREAK		; SET BREAK BIT
	LD	(PPK_STATUS),A		; SAVE STATUS
	JR	PPK_DEC1		; LOOP TO DO NEXT SCANCODE

PPK_DEC5:	; MAP SCANCODE TO KEYCODE
	LD	A,(PPK_STATUS)		; GET STATUS
	AND	PPK_EXT			; EXTENDED BIT SET?
	JR	Z,PPK_DEC5C		; NOPE, MOVE ON

		; PERFORM EXTENDED KEY MAPPING
	LD	A,(PPK_SCANCODE)	; GET SCANCODE
	LD	E,A			; STASH IT IN E
	LD	HL,PPK_MAPEXT		; POINT TO START OF EXT MAP TABLE
PPK_DEC5A:
	LD	A,(HL)			; GET FIRST BYTE OF PAIR
	CP	$00			; END OF TABLE?
	JP	Z,PPK_DECNEW		; UNKNOWN OR BOGUS, START OVER
	INC	HL			; INC HL FOR FUTURE
	CP	E			; DOES MATCH BYTE EQUAL SCANCODE?
	JR	Z,PPK_DEC5B		; YES! JUMP OUT
	INC	HL			; BUMP TO START OF NEXT PAIR
	JR	PPK_DEC5A		; LOOP TO CHECK NEXT TABLE ENTRY
PPK_DEC5B:
	LD	A,(HL)			; GET THE KEYCODE VIA MAPPING TABLE
	LD	(PPK_KEYCODE),A		; SAVE IT
	JR	PPK_DEC6

PPK_DEC5C:	; PERFORM REGULAR KEY (NOT EXTENDED) KEY MAPPING
	LD	A,(PPK_SCANCODE)	; GET THE SCANCODE
	CP	PPK_MAPSIZ		; COMPARE TO SIZE OF TABLE
	JR	NC,PPK_DEC6		; PAST END, SKIP OVER LOOKUP

		; SETUP POINTER TO MAPPING TABLE BASED ON SHIFTED OR UNSHIFTED STATE
	LD	A,(PPK_STATE)		; GET STATE
	AND	PPK_SHIFT		; SHIFT ACTIVE?
	LD	HL,PPK_MAPSTD		; LOAD ADDRESS OF NON-SHIFTED MAPPING TABLE
	JR	Z,PPK_DEC5D		; NON-SHIFTED, MOVE ON
	LD	HL,PPK_MAPSHIFT		; LOAD ADDRESS OF SHIFTED MAPPING TABLE
PPK_DEC5D:
	LD	A,(PPK_SCANCODE)	; GET THE SCANCODE
	LD	E,A			; SCANCODE TO E FOR TABLE OFFSET
	LD	D,0			; D -> 0
	ADD	HL,DE			; COMMIT THE TABLE OFFSET TO HL
	LD	A,(HL)			; GET THE KEYCODE VIA MAPPING TABLE
	LD	(PPK_KEYCODE),A		; SAVE IT

PPK_DEC6:	; HANDLE MODIFIER KEYS
	LD	A,(PPK_KEYCODE)		; MAKE SURE WE HAVE KEYCODE
	CP	$B8			; END OF MODIFIER KEYS
	JR	NC,PPK_DEC7		; BYPASS MODIFIER KEY CHECKING
	CP	$B0			; START OF MODIFIER KEYS
	JR	C,PPK_DEC7		; BYPASS MODIFIER KEY CHECKING
	
	LD	B,4			; LOOP COUNTER TO LOOP THRU 4 MODIFIER BITS
	LD	E,$80			; SETUP E TO ROATE THROUGH MODIFIER STATE BITS
	SUB	$B0 - 1			; SETUP A TO DECREMENT THROUGH MODIFIER VALUES
	
PPK_DEC6A:
	RLC	E			; SHIFT TO NEXT MODIFIER STATE BIT
	DEC	A			; L-MODIFIER?
	JR	Z,PPK_DEC6B		; YES, HANDLE L-MODIFIER MAKE/BREAK
	DEC	A			; R-MODIFIER?
	JR	Z,PPK_DEC6C		; YES, HANDLE R-MODIFIER MAKE/BREAK
	DJNZ	PPK_DEC6A		; LOOP THRU 4 MODIFIER BITS
	JR	PPK_DEC7		; FAILSAFE, SHOULD NEVER GET HERE!

PPK_DEC6B:	; LEFT STATE KEY MAKE/BREAK (STATE BIT TO SET/CLEAR IN E)
	LD	HL,PPK_LSTATE		; POINT TO LEFT STATE BYTE
	JR	PPK_DEC6D		; CONTINUE

PPK_DEC6C:	; RIGHT STATE KEY MAKE/BREAK (STATE BIT TO SET/CLEAR IN E)
	LD	HL,PPK_RSTATE		; POINT TO RIGHT STATE BYTE
	JR	PPK_DEC6D		; CONTINUE
	
PPK_DEC6D:	; BRANCH BASED ON WHETHER THIS IS A MAKE OR BREAK EVENT
	LD	A,(PPK_STATUS)		; GET STATUS FLAGS
	AND	PPK_BREAK		; BREAK EVENT?
	JR	Z,PPK_DEC6E		; NO, HANDLE A MODIFIER KEY MAKE EVENT
	JR	PPK_DEC6F		; YES, HANDLE A MODIFIER BREAK EVENT

PPK_DEC6E:	; HANDLE STATE KEY MAKE EVENT
	LD	A,E			; GET THE BIT TO SET
	OR	(HL)			; OR IN THE CURRENT BITS
	LD	(HL),A			; SAVE THE RESULT
	JR	PPK_DEC6G		; CONTINUE

PPK_DEC6F:	; HANDLE STATE KEY BREAK EVENT
	LD	A,E			; GET THE BIT TO CLEAR
	XOR	$FF			; FLIP ALL BITS TO SETUP FOR A CLEAR OPERATION
	AND	(HL)			; AND IN THE FLIPPED BITS TO CLEAR DESIRED BIT
	LD	(HL),A			; SAVE THE RESULT
	JR	PPK_DEC6G		; CONTINUE
	
PPK_DEC6G:	; COALESCE L/R STATE FLAGS
	LD	A,(PPK_STATE)		; GET EXISTING STATE BITS
	AND	$F0			; GET RID OF OLD MODIFIER BITS
	LD	DE,(PPK_LSTATE)		; LOAD BOTH L/R STATE BYTES IN D/E
	OR	E			; MERGE IN LEFT STATE BITS
	OR	D			; MERGE IN RIGHT STATE BITS
	LD	(PPK_STATE),A		; SAVE IT
	JP	PPK_DECNEW		; DONE WITH CURRENT KEYSTROKE

PPK_DEC7:	; COMPLETE PROCESSING OF EXTENDED AND KEY BREAK EVENTS
	LD	A,(PPK_STATUS)		; GET CURRENT STATUS FLAGS
	AND	PPK_BREAK		; IS THIS A KEY BREAK EVENT?
	JP	NZ,PPK_DECNEW		; PROCESS NEXT KEY

PPK_DEC8:	; HANDLE TOGGLE KEYS
	LD	A,(PPK_KEYCODE)		; GET THE CURRENT KEYCODE INTO A
	LD	E,PPK_CAPSLCK		; SETUP E WITH CAPS LOCK STATE BIT
	CP	$BC			; IS THIS THE CAPS LOCK KEY?
	JR	Z,PPK_DEC8A		; YES, GO TO BIT SET ROUTINE
	LD	E,PPK_NUMLCK		; SETUP E WITH NUM LOCK STATE BIT
	CP	$BD			; IS THIS THE NUM LOCK KEY?
	JR	Z,PPK_DEC8A		; YES, GO TO BIT SET ROUTINE
	LD	E,PPK_SCRLCK		; SETUP E WITH SCROLL LOCK STATE BIT
	CP	$BE			; IS THIS THE SCROLL LOCK KEY?
	JR	Z,PPK_DEC8A		; YES, GO TO BIT SET ROUTINE
	JR	PPK_DEC9		; NOT A TOGGLE KEY, CONTINUE
	
PPK_DEC8A:	; RECORD THE TOGGLE
	LD	A,(PPK_STATE)		; GET THE CURRENT STATE FLAGS
	XOR	E			; SET THE TOGGLE KEY BIT FROM ABOVE
	LD	(PPK_STATE),A		; SAVE IT
	CALL	PPK_SETLEDS		; UPDATE LED LIGHTS ON KBD
	JP	PPK_DECNEW		; RESTART DECODER FOR A NEW KEY

PPK_DEC9:	; ADJUST KEYCODE FOR CONTROL MODIFIER
	LD	A,(PPK_STATE)		; GET THE CURRENT STATE BITS
	AND	PPK_CTRL		; CHECK THE CONTROL BIT
	JR	Z,PPK_DEC10		; CONTROL KEY NOT PRESSED, MOVE ON
	LD	A,(PPK_KEYCODE)		; GET CURRENT KEYCODE IN A
	CP	'a'			; COMPARE TO LOWERCASE A
	JR	C,PPK_DEC9A		; BELOW IT, BYPASS
	CP	'z' + 1			; COMPARE TO LOWERCASE Z
	JR	NC,PPK_DEC9A		; ABOVE IT, BYPASS
	RES	5,A			; KEYCODE IN LOWERCASE A-Z RANGE CLEAR BIT 5 TO MAKE IT UPPERCASE
PPK_DEC9A:
	CP	'@'			; COMPARE TO @
	JR	C,PPK_DEC10		; BELOW IT, BYPASS
	CP	'_' + 1			; COMPARE TO _
	JR	NC,PPK_DEC10		; ABOVE IT, BYPASS
	RES	6,A			; CONVERT TO CONTROL VALUE BY CLEARING BIT 6
	LD	(PPK_KEYCODE),A		; UPDATE KEYCODE TO CONTROL VALUE

PPK_DEC10:	; ADJUST KEYCODE FOR CAPS LOCK
	LD	A,(PPK_STATE)		; LOAD THE STATE FLAGS
	AND	PPK_CAPSLCK		; CHECK CAPS LOCK
	JR	Z,PPK_DEC11		; CAPS LOCK NOT ACTIVE, MOVE ON
	LD	A,(PPK_KEYCODE)		; GET THE CURRENT KEYCODE VALUE
	CP	'a'			; COMPARE TO LOWERCASE A
	JR	C,PPK_DEC10A		; BELOW IT, BYPASS
	CP	'z' + 1			; COMPARE TO LOWERCASE Z
	JR	NC,PPK_DEC10A		; ABOVE IT, BYPASS
	JR	PPK_DEC10B		; IN RANGE LOWERCASE A-Z, GO TO CASE SWAPPING LOGIC
PPK_DEC10A:
	CP	'A'			; COMPARE TO UPPERCASE A
	JR	C,PPK_DEC11		; BELOW IT, BYPASS
	CP	'Z' + 1			; COMPARE TO UPPERCASE Z
	JR	NC,PPK_DEC11		; ABOVE IT, BYPASS
	JR	PPK_DEC10B		; IN RANGE UPPERCASE A-Z, GO TO CASE SWAPPING LOGIC
PPK_DEC10B:
	LD	A,(PPK_KEYCODE)		; GET THE CURRENT KEYCODE
	XOR	$20			; FLIP BIT 5 TO SWAP UPPER/LOWER CASE
	LD	(PPK_KEYCODE),A		; SAVE IT

PPK_DEC11:	; HANDLE NUM PAD KEYS
	LD	A,(PPK_STATE)		; GET THE CURRENT STATE FLAGS
	AND	~PPK_NUMPAD		; ASSUME NOT A NUMPAD KEY, CLEAR THE NUMPAD BIT
	LD	(PPK_STATE),A		; SAVE IT
	
	LD	A,(PPK_KEYCODE)		; GET THE CURRENT KEYCODE
	AND	11100000B		; ISOLATE TOP 3 BITS
	CP	11000000B		; IS IN NUMPAD RANGE?
	JR	NZ,PPK_DEC12		; NOPE, GET OUT
	
	LD	A,(PPK_STATE)		; LOAD THE CURRENT STATE FLAGS
	OR	PPK_NUMPAD		; TURN ON THE NUMPAD BIT
	LD	(PPK_STATE),A		; SAVE IT

	AND	PPK_NUMLCK		; IS NUM LOCK BIT SET?
	JR	Z,PPK_DEC11A		; NO, SKIP NUMLOCK PROCESSING
	LD	A,(PPK_KEYCODE)		; GET THE KEYCODE
	XOR	$10			; FLIP VALUES FOR NUMLOCK
	LD	(PPK_KEYCODE),A		; SAVE IT

PPK_DEC11A:	; APPLY NUMPAD MAPPING
	LD	A,(PPK_KEYCODE)		; GET THE CURRENT KEYCODE
	LD	HL,PPK_MAPNUMPAD	; LOAD THE START OF THE MAPPING TABLE
	SUB	$C0			; KEYCODES START AT $C0
	LD	E,A			; INDEX TO E
	LD	D,0			; D IS ZERO
	ADD	HL,DE			; POINT TO RESULT OF MAPPING
	LD	A,(HL)			; GET IT IN A
	LD	(PPK_KEYCODE),A		; SAVE IT

PPK_DEC12:	; DETECT UNKNOWN/INVALID KEYCODES
	LD	A,(PPK_KEYCODE)		; GET THE FINAL KEYCODE
	CP	$FF			; IS IT $FF (UNKNOWN/INVALID)
	JP	Z,PPK_DECNEW		; IF SO, JUST RESTART THE ENGINE

PPK_DEC13:	; DONE - RECORD RESULTS
	LD	A,(PPK_STATUS)		; GET CURRENT STATUS
	OR	PPK_KEYRDY		; SET KEY READY BIT
	LD	(PPK_STATUS),A		; SAVE IT
	XOR	A			; A=0
	INC	A			; SIGNAL SUCCESS WITH A=1
	RET
	
PPK_DECNEW:	; START NEW KEYPRESS (CLEAR ALL STATUS BITS)
	XOR	A			; A = 0
	LD	(PPK_STATUS),A		; CLEAR STATUS
	JP	PPK_DEC1		; RESTART THE ENGINE
;
#IF (PPKKBLOUT == KBD_US)
;__________________________________________________________________________________________________
;
; MAPPING TABLES US/ENGLISH
;__________________________________________________________________________________________________
;
PPK_MAPSTD:	; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE
	.DB	$FF,$E8,$FF,$E4,$E2,$E0,$E1,$EB,$FF,$E9,$E7,$E5,$E3,$09,'`',$FF
	.DB	$FF,$B4,$B0,$FF,$B2,'q','1',$FF,$FF,$FF,'z','s','a','w','2',$FF
	.DB	$FF,'c','x','d','e','4','3',$FF,$FF,' ','v','f','t','r','5',$FF
	.DB	$FF,'n','b','h','g','y','6',$FF,$FF,$FF,'m','j','u','7','8',$FF
	.DB	$FF,',','k','i','o','0','9',$FF,$FF,'.','/','l',';','p','-',$FF
	.DB	$FF,$FF,$27,$FF,'[','=',$FF,$FF,$BC,$B1,$0D,']',$FF,'\',$FF,$FF
	.DB	$FF,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$C0,$FF,$C3,$C6,$FF,$FF,$FF
	.DB	$C9,$CA,$C1,$C4,$C5,$C7,$1B,$BD,$FA,$CE,$C2,$CD,$CC,$C8,$BE,$FF
	.DB	$FF,$FF,$FF,$E6,$EC
;
PPK_MAPSIZ	.EQU	($ - PPK_MAPSTD)
;
PPK_MAPSHIFT:	; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE WHEN SHIFT ACTIVE
	.DB	$FF,$E8,$FF,$E4,$E2,$E0,$E1,$EB,$FF,$E9,$E7,$E5,$E3,$09,'~',$FF
	.DB	$FF,$B4,$B0,$FF,$B2,'Q','!',$FF,$FF,$FF,'Z','S','A','W','@',$FF
	.DB	$FF,'C','X','D','E','$','#',$FF,$FF,' ','V','F','T','R','%',$FF
	.DB	$FF,'N','B','H','G','Y','^',$FF,$FF,$FF,'M','J','U','&','*',$FF
	.DB	$FF,'<','K','I','O',')','(',$FF,$FF,'>','?','L',':','P','_',$FF
	.DB	$FF,$FF,$22,$FF,'{','+',$FF,$FF,$BC,$B1,$0D,'}',$FF,'|',$FF,$FF
	.DB	$FF,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$D0,$FF,$D3,$D6,$FF,$FF,$FF
	.DB	$D9,$DA,$D1,$D4,$D5,$D7,$1B,$BD,$FA,$DE,$D2,$DD,$DC,$D8,$BE,$FF
	.DB	$FF,$FF,$FF,$E6,$EC
;
PPK_MAPEXT:	; PAIRS ARE [SCANCODE,KEYCODE] FOR EXTENDED SCANCODES
	.DB	$11,$B5,	$14,$B3,	$1F,$B6,	$27,$B7
	.DB	$2F,$EF,	$37,$FA,	$3F,$FB,	$4A,$CB
	.DB	$5A,$CF,	$5E,$FC,	$69,$F3,	$6B,$F8
	.DB	$6C,$F2,	$70,$F0,	$71,$F1,	$72,$F7
	.DB	$74,$F9,	$75,$F6,	$7A,$F5,	$7C,$ED
	.DB	$7D,$F4,	$7E,$FD,	$00,$00
;
PPK_MAPNUMPAD:	; KEYCODE TRANSLATION FROM NUMPAD RANGE TO STD ASCII/KEYCODES
	.DB	$F3,$F7,$F5,$F8,$FF,$F9,$F2,$F6,$F4,$F0,$F1,$2F,$2A,$2D,$2B,$0D
	.DB	$31,$32,$33,$34,$35,$36,$37,$38,$39,$30,$2E,$2F,$2A,$2D,$2B,$0D
#ENDIF
#IF (PPKKBLOUT == KBD_DE)
;__________________________________________________________________________________________________
;
; MAPPING TABLES GERMAN
;__________________________________________________________________________________________________
;
PPK_MAPSTD: ; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE             ROW

; Column 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F		;	Special adjustments listed below
      .DB   $FF,$E8,$FF,$E4,$E2,$E0,$E1,$EB,$FF,$E9,$E7,$E5,$E3,$09,'^',$FF     ;0	for German keyboard keys that give
      .DB   $FF,$B4,$B0,$FF,$B2,'q','1',$FF,$FF,$FF,'y','s','a','w','2',$FF     ;1	different characters than are printed
      .DB   $FF,'c','x','d','e','4','3',$FF,$FF,' ','v','f','t','r','5',$FF     ;2	on the keys.
      .DB   $FF,'n','b','h','g','z','6',$FF,$FF,$FF,'m','j','u','7','8',$FF     ;3	'german key' --> 'new occupied with'
      .DB   $FF,',','k','i','o','0','9',$FF,$FF,'.','-','l','[','p',$5C,$FF     ;4 	Assembler ERROR: '\'-->$5C ; 'ö'-->'['
      .DB   $FF,$FF,'@',$FF,']','|',$FF,$FF,$BC,$B1,$0D,'+',$FF,'#',$FF,$FF     ;5	'ä'-->'@' ; 'ü'-->']'
      .DB   $FF,'<',$FF,$FF,$FF,$FF,$08,$FF,$FF,$C0,$FF,$C3,$C6,'<',$FF,$FF     ;6
      .DB   $C9,$CA,$C1,$C4,$C5,$C7,$1B,$BD,$FA,$CE,$C2,$CD,$CC,$C8,$BE,$FF     ;7
      .DB   $FF,$FF,$FF,$E6,$EC                                                 ;8
 
PPK_MAPSIZ  .EQU  ($ - PPK_MAPSTD)
;
PPK_MAPSHIFT:     ; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE WHEN SHIFT ACTIVE

      .DB   $FF,$E8,$FF,$E4,$E2,$E0,$E1,$EB,$FF,$E9,$E7,$E5,$E3,$09,'~',$FF        ; '°' --> '~'
      .DB   $FF,$B4,$B0,$FF,$B2,'Q','!',$FF,$FF,$FF,'Y','S','A','W',$22,$FF       
      .DB   $FF,'C','X','D','E','$',$20,$FF,$FF,' ','V','F','T','R','%',$FF        ; '§'-->$20; '§'=Paragraph not used in CP/M
      .DB   $FF,'N','B','H','G','Z','&',$FF,$FF,$FF,'M','J','U','/','(',$FF
      .DB   $FF,';','K','I','O','=',')',$FF,$FF,':','_','L','{','P','?',$FF        ; 'Ö'-->'{'
      .DB   $FF,$FF,'@',$FF,'}','`',$FF,$FF,$BC,$B1,$0D,'*',$FF,$27,$FF,$FF        ; 'Ä'-->'@' ; 'Ü'-->'}'
      .DB   $FF,'>',$FF,$FF,$FF,$FF,$08,$FF,$FF,$D0,$FF,$D3,$D6,'>',$FF,$FF
      .DB   $D9,$DA,$D1,$D4,$D5,$D7,$1B,$BD,$FA,$DE,$D2,$DD,$DC,$D8,$BE,$FF
      .DB   $FF,$FF,$FF,$E6,$EC

PPK_MAPEXT: ; PAIRS ARE [SCANCODE,KEYCODE] FOR EXTENDED SCANCODES
	.DB         $11,$B5,	$14,$B3,	$1F,$B6,	$27,$B7
	.DB         $2F,$EF,	$37,$FA,	$3F,$FB,	$4A,$CB		; All keys listed below are customized for Wordstar.
	.DB         $5A,$CF,	$5E,$FC,	$69,$06,	$6B,$13		; n.a , n.a , word right , n.a.
	.DB         $6C,$01,	$70,$16,	$71,$07,	$72,$18		; Word left , Toggle Insert/Overwrite , Del Char , Cursor down
	.DB         $74,$04,	$75,$05,	$7A,$1A,	$7C,$ED		; Cursor right , Cursor up , Page down
	.DB         $7D,$17,	$7E,$FD,	$00,$00				; Page up , n.a. , END PPK_MAPEXT (Pairs end)
;
PPK_MAPNUMPAD:    ; KEYCODE TRANSLATION FROM NUMPAD RANGE TO STD ASCII/KEYCODES

      .DB   $F3,$F7,$F5,$F8,$FF,$F9,$F2,$F6,$F4,$F0,$F1,$2F,$2A,$2D,$2B,$0D
      .DB   $31,$32,$33,$34,$35,$36,$37,$38,$39,$30,$2E,$2F,$2A,$2D,$2B,$0D
;
#ENDIF
;__________________________________________________________________________________________________
;
; KEYCODE VALUES RETURNED BY THE DECODER
;__________________________________________________________________________________________________
;
; VALUES 0-127 ARE STANDARD ASCII, SPECIAL KEYS WILL HAVE THE FOLLOWING VALUES:
;
; F1		$E0
; F2		$E1
; F3		$E2
; F4		$E3
; F5		$E4
; F6		$E5
; F7		$E6
; F8		$E7
; F9		$E8
; F10		$E9
; F11		$EA
; F12		$EB
; SYSRQ		$EC
; PRTSC		$ED
; PAUSE		$EE
; APP		$EF
; INS		$F0
; DEL		$F1
; HOME		$F2
; END		$F3
; PGUP		$F4
; PGDN		$F5
; UP		$F6
; DOWN		$F7
; LEFT		$F8
; RIGHT		$F9
; POWER		$FA
; SLEEP		$FB
; WAKE		$FC
; BREAK		$FD
