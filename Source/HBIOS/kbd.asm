;__________________________________________________________________________________________________
;
;	8242 BASED PS/2 KEYBOARD DRIVER FOR SBC
;
;	ORIGINAL CODE BY DR JAMES MOXHAM
;	ROMWBW ADAPTATION BY WAYNE WARTHEN
;__________________________________________________________________________________________________
;
; TODO:
;   CONSIDER DETECTING ERRORS IN STATUS BYTE (PERR, TO)
;__________________________________________________________________________________________________
; DATA CONSTANTS
;__________________________________________________________________________________________________
;
; DRIVER DATA OFFSETS (FROM IY)
;
KBD_ST		.EQU	0	; BYTE, STATUS PORT NUM (R)
KBD_CMD		.EQU	KBD_ST	; BYTE, CMD PORT NUM (W)
KBD_DAT		.EQU	1	; BYTE, DATA PORT NUM (R/W)
;
; TIMING CONSTANTS
;
KBD_WAITTO	.EQU	0	; 0 IS MAX WAIT (256)
;
; STATUS BITS (FOR KBD_STATUS)
;
KBD_EXT		.EQU	01H	; BIT 0, EXTENDED SCANCODE ACTIVE
KBD_BREAK	.EQU	02H	; BIT 1, THIS IS A KEY UP (BREAK) EVENT
KBD_KEYRDY	.EQU	80H	; BIT 7, INDICATES A DECODED KEYCODE IS READY
;
; STATE BITS (FOR KBD_STATE, KBD_LSTATE, KBD_RSTATE)
;
KBD_SHIFT	.EQU	01H	; BIT 0, SHIFT ACTIVE (PRESSED)
KBD_CTRL	.EQU	02H	; BIT 1, CONTROL ACTIVE (PRESSED)
KBD_ALT		.EQU	04H	; BIT 2, ALT ACTIVE (PRESSED)
KBD_WIN		.EQU	08H	; BIT 3, WIN ACTIVE (PRESSED)
KBD_SCRLCK	.EQU	10H	; BIT 4, CAPS LOCK ACTIVE (TOGGLED ON)
KBD_NUMLCK	.EQU	20H	; BIT 5, NUM LOCK ACTIVE (TOGGLED ON)
KBD_CAPSLCK	.EQU	40H	; BIT 6, SCROLL LOCK ACTIVE (TOGGLED ON)
KBD_NUMPAD	.EQU	80H	; BIT 7, NUM PAD KEY (KEY PRESSED IS ON NUM PAD)
;
KBD_DEFRPT	.EQU	$40		; DEFAULT REPEAT RATE (.5 SEC DELAY, 30CPS)
KBD_DEFSTATE	.EQU	KBD_NUMLCK	; DEFAULT STATE (NUM LOCK ON)
;
;__________________________________________________________________________________________________
; DATA
;__________________________________________________________________________________________________
;
KBD_SCANCODE	.DB	0	; RAW SCANCODE
KBD_KEYCODE	.DB	0	; RESULTANT KEYCODE AFTER DECODING
KBD_STATE	.DB	0	; STATE BITS (SEE ABOVE)
KBD_LSTATE	.DB	0	; STATE BITS FOR "LEFT" KEYS
KBD_RSTATE	.DB	0	; STATE BITS FOR "RIGHT" KEYS
KBD_STATUS	.DB	0	; CURRENT STATUS BITS (SEE ABOVE)
KBD_REPEAT	.DB	0	; CURRENT REPEAT RATE
KBD_IDLE	.DB	0	; IDLE COUNT
;
;__________________________________________________________________________________________________
; KEYBOARD INITIALIZATION
;__________________________________________________________________________________________________
;
KBD_INIT:
	CALL	NEWLINE			; FORMATTING
	PRTS("KBD: IO=0x$")
	LD	A,(IY+KBD_DAT)
	CALL	PRTHEXBYTE
;
	LD	A,KBD_DEFRPT		; GET DEFAULT REPEAT RATE
	LD	(KBD_REPEAT),A		; SAVE IT
	LD	A,KBD_DEFSTATE		; GET DEFAULT STATE
	LD	(KBD_STATE),A		; SAVE IT

	LD	A,$AA			; CONTROLLER SELF TEST
	CALL	KBD_PUTCMD		; SEND IT
	CALL	KBD_GETDATA		; CONTROLLER SHOULD RESPOND WITH $55 (ACK)

	CP	$55			; IS IT THERE?
	JR	Z,KBD_INIT1		; IF SO, CONTINUE
	PRTS(" NOT PRESENT$")		; DIAGNOSE PROBLEM
	RET				; BAIL OUT

KBD_INIT1:
	LD	A,$60			; SET COMMAND REGISTER
	CALL	KBD_PUTCMD		; SEND IT
;	LD	A,$60			; XLAT ENABLED, MOUSE DISABLED, NO INTS
	LD	A,$20			; XLAT DISABLED, MOUSE DISABLED, NO INTS
	CALL	KBD_PUTDATA		; SEND IT
	
	CALL	KBD_GETDATA		; GOBBLE UP $AA FROM POWER UP, AS NEEDED
	
;	LD	A,$AE			; COMMAND = ENABLE KEYBOARD
;	CALL	KBD_PUTCMD		; SEND IT
;	LD	A,$A7			; COMMAND = DISABLE MOUSE
;	CALL	KBD_PUTCMD		; SEND IT
	
	CALL 	KBD_RESET		; RESET THE KEYBOARD
	CALL	KBD_SETLEDS		; UPDATE LEDS BASED ON CURRENT TOGGLE STATE BITS
	CALL	KBD_SETRPT		; UPDATE REPEAT RATE BASED ON CURRENT SETTING
	
	XOR	A			; SIGNAL SUCCESS
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD STATUS
;__________________________________________________________________________________________________
;
KBD_STAT:
	CALL	KBD_DECODE		; CHECK THE KEYBOARD
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
KBD_READ:
	CALL	KBD_STAT		; KEY READY?
	JR	Z,KBD_READ		; NOT READY, KEEP TRYING
;
	LD	A,(KBD_STATE)		; GET STATE
	AND	$01			; ISOLATE EXTENDED SCANCODE BIT
	RRCA				; ROTATE IT TO HIGH ORDER BIT
	LD	E,A			; SAVE IT IN E FOR NOW
	LD	A,(KBD_SCANCODE)	; GET SCANCODE
	OR	E			; COMBINE WITH EXTENDED BIT
	LD	C,A			; STORE IT IN C FOR RETURN
	LD	A,(KBD_KEYCODE)		; GET KEYCODE
	LD	E,A			; SAVE IT IN E
	LD	A,(KBD_STATE)		; GET STATE FLAGS
	LD	D,A			; SAVE THEM IN D
	XOR	A			; SIGNAL SUCCESS
	LD	(KBD_STATUS),A		; CLEAR STATUS TO INDICATE BYTE RECEIVED
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD FLUSH
;__________________________________________________________________________________________________
;
KBD_FLUSH:
	XOR	A			; A = 0
	LD	(KBD_STATUS),A		; CLEAR STATUS
	RET
;
;__________________________________________________________________________________________________
; HARDWARE INTERFACE
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
KBD_IST:
;
; KEYBOARD INPUT STATUS
;   A=0, Z SET FOR NOTHING PENDING, OTHERWISE DATA PENDING
;
	LD	C,(IY+KBD_ST)		; STATUS PORT
	IN	A,(C)			; GET STATUS
	AND	$01			; ISOLATE INPUT PENDING BIT
	RET
;
;__________________________________________________________________________________________________
KBD_OST:
;
; KEYBOARD OUTPUT STATUS
;   A=0, Z SET FOR NOT READY, OTHERWISE READY TO WRITE
;
	LD	C,(IY+KBD_ST)		; STATUS PORT
	IN	A,(C)			; GET STATUS
	AND	$02			; ISOLATE OUTPUT EMPTY BIT
	XOR	$02			; FLIP IT FOR APPROPRIATE RETURN VALUES
	RET
;
;__________________________________________________________________________________________________
KBD_PUTCMD:
;
; PUT A CMD BYTE FROM A TO THE KEYBOARD INTERFACE WITH TIMEOUT
;
	LD	E,A			; SAVE INCOMING VALUE IN E
	LD	B,KBD_WAITTO		; SETUP TO LOOP
KBD_PUTCMD0:
	CALL	KBD_OST			; GET OUTPUT REGISTER STATUS
	JR	NZ,KBD_PUTCMD1		; EMPTY, GO TO WRITE
	CALL	DELAY			; WAIT A BIT
	DJNZ	KBD_PUTCMD0		; LOOP UNTIL COUNTER EXHAUSTED
	RET
KBD_PUTCMD1:
	LD	A,E			; RECOVER VALUE TO WRITE
#IF (KBDTRACE >= 2)
	CALL	PC_SPACE
	CALL	PC_GT
	CALL	PC_GT
	CALL	PRTHEXBYTE
#ENDIF
	LD	C,(IY+KBD_CMD)		; COMMAND PORT
	OUT	(C),A			; WRITE IT
	XOR	A			; SIGNAL SUCCESS
	RET
;
;__________________________________________________________________________________________________
KBD_PUTDATA:
;
; PUT A DATA BYTE FROM A TO THE KEYBOARD INTERFACE WITH TIMEOUT
;
	LD	E,A			; SAVE INCOMING VALUE IN E
	LD	B,KBD_WAITTO		; SETUP TO LOOP
KBD_PUTDATA0:
	CALL	KBD_OST			; GET OUTPUT REGISTER STATUS
	JR	NZ,KBD_PUTDATA1		; EMPTY, GO TO WRITE
	CALL	DELAY			; WAIT A BIT
	DJNZ	KBD_PUTDATA0		; LOOP UNTIL COUNTER EXHAUSTED
	RET
KBD_PUTDATA1:
	LD	A,E			; RECOVER VALUE TO WRITE
#IF (KBDTRACE >= 2)
	CALL	PC_SPACE
	CALL	PC_GT
	CALL	PRTHEXBYTE
#ENDIF
	LD	C,(IY+KBD_DAT)		; DATA PORT
	OUT	(C),A			; WRITE IT
	XOR	A			; SIGNAL SUCCESS
	RET
;
;__________________________________________________________________________________________________
KBD_GETDATA:
;
; GET A RAW DATA BYTE FROM KEYBOARD INTERFACE INTO A WITH TIMEOUT
;
	LD	B,KBD_WAITTO		; SETUP TO LOOP
KBD_GETDATA0:
	CALL	KBD_IST			; GET INPUT REGISTER STATUS
	JR	NZ,KBD_GETDATA1		; BYTE PENDING, GO GET IT
	CALL	DELAY			; WAIT A BIT
	DJNZ	KBD_GETDATA0		; LOOP UNTIL COUNTER EXHAUSTED
	XOR	A			; NO DATA, RETURN ZERO
	RET
KBD_GETDATA1:
	LD	C,(IY+KBD_DAT)		; DATA PORT
	IN	A,(C)			; GET THE DATA VALUE
#IF (KBDTRACE >= 2)
	PUSH	AF
	CALL	PC_SPACE
	CALL	PC_LT
	CALL	PRTHEXBYTE
	POP	AF
#ENDIF
	OR	A			; SET FLAGS
	RET
;
;__________________________________________________________________________________________________
KBD_GETDATAX:
;
; GET A RAW DATA BYTE FROM KEYBOARD INTERFACE INTO A WITH NOTIMEOUT
;
	CALL	KBD_IST			; GET INPUT REGISTER STATUS
	RET	Z			; NOTHING THERE, DONE
	JR	KBD_GETDATA1		; GO GET IT
;
;__________________________________________________________________________________________________
; RESET KEYBOARD
;__________________________________________________________________________________________________
;
KBD_RESET:
	LD	A,$FF		; RESET COMMAND
	CALL	KBD_PUTDATA	; SEND IT
	CALL	KBD_GETDATA	; GET THE ACK
	LD	B,0		; SETUP LOOP COUNTER
KBD_RESET0:
	PUSH	BC		; PRESERVE COUNTER
	CALL	KBD_GETDATA	; TRY TO GET THE RESPONSE
	POP	BC		; RECOVER COUNTER
	JR	NZ,KBD_RESET1	; GOT A BYTE?  IF SO, GET OUT OF LOOP
	DJNZ	KBD_RESET0	; LOOP TILL COUNTER EXHAUSTED
KBD_RESET1:
	LD	A,B
	XOR	A		; SIGNAL SUCCESS (RESPONSE IS IGNORED...)
	RET			; DONE
;
;__________________________________________________________________________________________________
; UPDATE KEYBOARD LEDS BASED ON CURRENT TOGGLE FLAGS
;__________________________________________________________________________________________________
;
KBD_SETLEDS:
	LD	A,$ED		; SET/RESET LED'S COMMAND
	CALL	KBD_PUTDATA	; SEND THE COMMAND
	CALL	KBD_GETDATA	; READ THE RESPONSE
	CP	$FA		; MAKE SURE WE GET ACK
	RET	NZ		; ABORT IF NO ACK
	LD	A,(KBD_STATE)	; LOAD THE STATE BYTE
	RRCA			; ROTATE TOGGLE KEY BITS AS NEEDED
	RRCA
	RRCA
	RRCA
	AND	$07		; CLEAR THE IRRELEVANT BITS
	CALL	KBD_PUTDATA	; SEND THE LED DATA
	CALL	KBD_GETDATA	; READ THE ACK
	JP	KBD_DECNEW	; RESTART DECODER FOR A NEW KEY
	RET			; DONE
;
;__________________________________________________________________________________________________
; UPDATE KEYBOARD REPEAT RATE BASED ON CURRENT SETTING
;__________________________________________________________________________________________________
;
KBD_SETRPT:
	LD	A,$F3		; COMMAND = SET TYPEMATIC RATE/DELAY
	CALL	KBD_PUTDATA	; SEND IT
	CALL	KBD_GETDATA	; GET THE ACK
	CP	$FA		; MAKE SURE WE GET ACK
	RET	NZ		; ABORT IF NO ACK
	LD	A,(KBD_REPEAT)	; LOAD THE CURRENT RATE/DELAY BYTE
	CALL	KBD_PUTDATA	; SEND IT
	CALL	KBD_GETDATA	; GET THE ACK
	RET
;
;__________________________________________________________________________________________________
; DECODING ENGINE
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
KBD_DECODE:
;
;  RUN THE DECODING ENGINE UNTIL EITHER: 1) NO MORE SCANCODES ARE AVAILABLE
;  FROM THE KEYBOARD, OR 2) A DECODED KEY VALUE IS AVAILABLE
;
;  RETURNS A=0 AND Z SET IF NO KEYCODE READY, OTHERWISE A DECODED KEY VALUE IS AVAILABLE.
;  THE DECODED KEY VALUE AND KEY STATE IS STORED IN KBD_KEYCODE AND KBD_STATE.
;
;  KBD_STATUS IS NOT CLEARED AT START. IT IS THE CALLER'S RESPONSIBILITY
;  TO CLEAR KBD_STATUS WHEN IT HAS RETRIEVED A PENDING VALUE.  IF DECODE IS CALLED
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
KBD_DEC0:	; CHECK KEYCODE BUFFER
	LD	A,(KBD_STATUS)		; GET CURRENT STATUS
	AND	KBD_KEYRDY		; ISOLATE KEY READY FLAG
	RET	NZ			; ABORT IF KEY IS ALREADY PENDING

KBD_DEC1:	; PROCESS NEXT SCANCODE
	CALL	KBD_GETDATAX		; GET THE SCANCODE
	RET	Z			; NO KEY READY, RETURN WITH A=0, Z SET
	LD	(KBD_SCANCODE),A	; SAVE SCANCODE

KBD_DEC2:	; DETECT AND HANDLE SPECIAL KEYCODES
	LD	A,(KBD_SCANCODE)	; GET THE CURRENT SCANCODE
	CP	$AA			; KEYBOARD INSERTION?
	JR	NZ,KBD_DEC3		; NOPE, BYPASS
	CALL	LDELAY			; WAIT A BIT
	CALL	KBD_RESET		; RESET KEYBOARD
	CALL	KBD_SETLEDS		; SET LEDS
	CALL	KBD_SETRPT		; SET REPEAT RATE
	JP	KBD_DECNEW		; RESTART THE ENGINE

KBD_DEC3:	; DETECT AND HANDLE SCANCODE PREFIXES
	LD	A,(KBD_SCANCODE)	; GET THE CURRENT SCANCODE

KBD_DEC3A:	; HANDLE SCANCODE PREFIX $E0 (EXTENDED SCANCODE FOLLOWS)
	CP	$E0			; EXTENDED KEY PREFIX $E0?
	JR	NZ,KBD_DEC3B		; NOPE MOVE ON
	LD	A,(KBD_STATUS)		; GET STATUS
	OR	KBD_EXT			; SET EXTENDED BIT
	LD	(KBD_STATUS),A		; SAVE STATUS
	JR	KBD_DEC1		; LOOP TO DO NEXT SCANCODE

KBD_DEC3B:	; HANDLE SCANCODE PREFIX $E1 (PAUSE KEY)
	CP	$E1			; EXTENDED KEY PREFIX $E1
	JR	NZ,KBD_DEC4		; NOPE MOVE ON
	LD	A,$EE			; MAP TO KEYCODE $EE
	LD	(KBD_KEYCODE),A		; SAVE IT
		; SWALLOW NEXT 7 SCANCODES
	LD	B,7			; LOOP 5 TIMES
KBD_DEC3B1:
	PUSH	BC
	CALL	KBD_GETDATA		; RETRIEVE NEXT SCANCODE
	POP	BC
	DJNZ	KBD_DEC3B1		; LOOP AS NEEDED
	JP	KBD_DEC6		; RESUME AFTER MAPPING

KBD_DEC4:	; DETECT AND FLAG BREAK EVENT
	CP	$F0			; BREAK (KEY UP) PREFIX?
	JR	NZ,KBD_DEC5		; NOPE MOVE ON
	LD	A,(KBD_STATUS)		; GET STATUS
	OR	KBD_BREAK		; SET BREAK BIT
	LD	(KBD_STATUS),A		; SAVE STATUS
	JR	KBD_DEC1		; LOOP TO DO NEXT SCANCODE

KBD_DEC5:	; MAP SCANCODE TO KEYCODE
	LD	A,(KBD_STATUS)		; GET STATUS
	AND	KBD_EXT			; EXTENDED BIT SET?
	JR	Z,KBD_DEC5C		; NOPE, MOVE ON

		; PERFORM EXTENDED KEY MAPPING
	LD	A,(KBD_SCANCODE)	; GET SCANCODE
	LD	E,A			; STASH IT IN E
	LD	HL,KBD_MAPEXT		; POINT TO START OF EXT MAP TABLE
KBD_DEC5A:
	LD	A,(HL)			; GET FIRST BYTE OF PAIR
	CP	$00			; END OF TABLE?
	JP	Z,KBD_DECNEW		; UNKNOWN OR BOGUS, START OVER
	INC	HL			; INC HL FOR FUTURE
	CP	E			; DOES MATCH BYTE EQUAL SCANCODE?
	JR	Z,KBD_DEC5B		; YES! JUMP OUT
	INC	HL			; BUMP TO START OF NEXT PAIR
	JR	KBD_DEC5A		; LOOP TO CHECK NEXT TABLE ENTRY
KBD_DEC5B:
	LD	A,(HL)			; GET THE KEYCODE VIA MAPPING TABLE
	LD	(KBD_KEYCODE),A		; SAVE IT
	JR	KBD_DEC6

KBD_DEC5C:	; PERFORM REGULAR KEY (NOT EXTENDED) KEY MAPPING
	LD	A,(KBD_SCANCODE)	; GET THE SCANCODE
	CP	KBD_MAPSIZ		; COMPARE TO SIZE OF TABLE
	JR	NC,KBD_DEC6		; PAST END, SKIP OVER LOOKUP

		; SETUP POINTER TO MAPPING TABLE BASED ON SHIFTED OR UNSHIFTED STATE
	LD	A,(KBD_STATE)		; GET STATE
	AND	KBD_SHIFT		; SHIFT ACTIVE?
	LD	HL,KBD_MAPSTD		; LOAD ADDRESS OF NON-SHIFTED MAPPING TABLE
	JR	Z,KBD_DEC5D		; NON-SHIFTED, MOVE ON
	LD	HL,KBD_MAPSHIFT		; LOAD ADDRESS OF SHIFTED MAPPING TABLE
KBD_DEC5D:
	LD	A,(KBD_SCANCODE)	; GET THE SCANCODE
	LD	E,A			; SCANCODE TO E FOR TABLE OFFSET
	LD	D,0			; D -> 0
	ADD	HL,DE			; COMMIT THE TABLE OFFSET TO HL
	LD	A,(HL)			; GET THE KEYCODE VIA MAPPING TABLE
	LD	(KBD_KEYCODE),A		; SAVE IT

KBD_DEC6:	; HANDLE MODIFIER KEYS
	LD	A,(KBD_KEYCODE)		; MAKE SURE WE HAVE KEYCODE
	CP	$B8			; END OF MODIFIER KEYS
	JR	NC,KBD_DEC7		; BYPASS MODIFIER KEY CHECKING
	CP	$B0			; START OF MODIFIER KEYS
	JR	C,KBD_DEC7		; BYPASS MODIFIER KEY CHECKING
	
	LD	B,4			; LOOP COUNTER TO LOOP THRU 4 MODIFIER BITS
	LD	E,$80			; SETUP E TO ROATE THROUGH MODIFIER STATE BITS
	SUB	$B0 - 1			; SETUP A TO DECREMENT THROUGH MODIFIER VALUES
	
KBD_DEC6A:
	RLC	E			; SHIFT TO NEXT MODIFIER STATE BIT
	DEC	A			; L-MODIFIER?
	JR	Z,KBD_DEC6B		; YES, HANDLE L-MODIFIER MAKE/BREAK
	DEC	A			; R-MODIFIER?
	JR	Z,KBD_DEC6C		; YES, HANDLE R-MODIFIER MAKE/BREAK
	DJNZ	KBD_DEC6A		; LOOP THRU 4 MODIFIER BITS
	JR	KBD_DEC7		; FAILSAFE, SHOULD NEVER GET HERE!

KBD_DEC6B:	; LEFT STATE KEY MAKE/BREAK (STATE BIT TO SET/CLEAR IN E)
	LD	HL,KBD_LSTATE		; POINT TO LEFT STATE BYTE
	JR	KBD_DEC6D		; CONTINUE

KBD_DEC6C:	; RIGHT STATE KEY MAKE/BREAK (STATE BIT TO SET/CLEAR IN E)
	LD	HL,KBD_RSTATE		; POINT TO RIGHT STATE BYTE
	JR	KBD_DEC6D		; CONTINUE
	
KBD_DEC6D:	; BRANCH BASED ON WHETHER THIS IS A MAKE OR BREAK EVENT
	LD	A,(KBD_STATUS)		; GET STATUS FLAGS
	AND	KBD_BREAK		; BREAK EVENT?
	JR	Z,KBD_DEC6E		; NO, HANDLE A MODIFIER KEY MAKE EVENT
	JR	KBD_DEC6F		; YES, HANDLE A MODIFIER BREAK EVENT

KBD_DEC6E:	; HANDLE STATE KEY MAKE EVENT
	LD	A,E			; GET THE BIT TO SET
	OR	(HL)			; OR IN THE CURRENT BITS
	LD	(HL),A			; SAVE THE RESULT
	JR	KBD_DEC6G		; CONTINUE

KBD_DEC6F:	; HANDLE STATE KEY BREAK EVENT
	LD	A,E			; GET THE BIT TO CLEAR
	XOR	$FF			; FLIP ALL BITS TO SETUP FOR A CLEAR OPERATION
	AND	(HL)			; AND IN THE FLIPPED BITS TO CLEAR DESIRED BIT
	LD	(HL),A			; SAVE THE RESULT
	JR	KBD_DEC6G		; CONTINUE
	
KBD_DEC6G:	; COALESCE L/R STATE FLAGS
	LD	A,(KBD_STATE)		; GET EXISTING STATE BITS
	AND	$F0			; GET RID OF OLD MODIFIER BITS
	LD	DE,(KBD_LSTATE)		; LOAD BOTH L/R STATE BYTES IN D/E
	OR	E			; MERGE IN LEFT STATE BITS
	OR	D			; MERGE IN RIGHT STATE BITS
	LD	(KBD_STATE),A		; SAVE IT
	JP	KBD_DECNEW		; DONE WITH CURRENT KEYSTROKE

KBD_DEC7:	; COMPLETE PROCESSING OF EXTENDED AND KEY BREAK EVENTS
	LD	A,(KBD_STATUS)		; GET CURRENT STATUS FLAGS
	AND	KBD_BREAK		; IS THIS A KEY BREAK EVENT?
	JP	NZ,KBD_DECNEW		; PROCESS NEXT KEY

KBD_DEC8:	; HANDLE TOGGLE KEYS
	LD	A,(KBD_KEYCODE)		; GET THE CURRENT KEYCODE INTO A
	LD	E,KBD_CAPSLCK		; SETUP E WITH CAPS LOCK STATE BIT
	CP	$BC			; IS THIS THE CAPS LOCK KEY?
	JR	Z,KBD_DEC8A		; YES, GO TO BIT SET ROUTINE
	LD	E,KBD_NUMLCK		; SETUP E WITH NUM LOCK STATE BIT
	CP	$BD			; IS THIS THE NUM LOCK KEY?
	JR	Z,KBD_DEC8A		; YES, GO TO BIT SET ROUTINE
	LD	E,KBD_SCRLCK		; SETUP E WITH SCROLL LOCK STATE BIT
	CP	$BE			; IS THIS THE SCROLL LOCK KEY?
	JR	Z,KBD_DEC8A		; YES, GO TO BIT SET ROUTINE
	JR	KBD_DEC9		; NOT A TOGGLE KEY, CONTINUE
	
KBD_DEC8A:	; RECORD THE TOGGLE
	LD	A,(KBD_STATE)		; GET THE CURRENT STATE FLAGS
	XOR	E			; SET THE TOGGLE KEY BIT FROM ABOVE
	LD	(KBD_STATE),A		; SAVE IT
	CALL	KBD_SETLEDS		; UPDATE LED LIGHTS ON KBD
	JP	KBD_DECNEW		; RESTART DECODER FOR A NEW KEY

KBD_DEC9:	; ADJUST KEYCODE FOR CONTROL MODIFIER
	LD	A,(KBD_STATE)		; GET THE CURRENT STATE BITS
	AND	KBD_CTRL		; CHECK THE CONTROL BIT
	JR	Z,KBD_DEC10		; CONTROL KEY NOT PRESSED, MOVE ON
	LD	A,(KBD_KEYCODE)		; GET CURRENT KEYCODE IN A
	CP	'a'			; COMPARE TO LOWERCASE A
	JR	C,KBD_DEC9A		; BELOW IT, BYPASS
	CP	'z' + 1			; COMPARE TO LOWERCASE Z
	JR	NC,KBD_DEC9A		; ABOVE IT, BYPASS
	RES	5,A			; KEYCODE IN LOWERCASE A-Z RANGE CLEAR BIT 5 TO MAKE IT UPPERCASE
KBD_DEC9A:
	CP	'@'			; COMPARE TO @
	JR	C,KBD_DEC10		; BELOW IT, BYPASS
	CP	'_' + 1			; COMPARE TO _
	JR	NC,KBD_DEC10		; ABOVE IT, BYPASS
	RES	6,A			; CONVERT TO CONTROL VALUE BY CLEARING BIT 6
	LD	(KBD_KEYCODE),A		; UPDATE KEYCODE TO CONTROL VALUE

KBD_DEC10:	; ADJUST KEYCODE FOR CAPS LOCK
	LD	A,(KBD_STATE)		; LOAD THE STATE FLAGS
	AND	KBD_CAPSLCK		; CHECK CAPS LOCK
	JR	Z,KBD_DEC11		; CAPS LOCK NOT ACTIVE, MOVE ON
	LD	A,(KBD_KEYCODE)		; GET THE CURRENT KEYCODE VALUE
	CP	'a'			; COMPARE TO LOWERCASE A
	JR	C,KBD_DEC10A		; BELOW IT, BYPASS
	CP	'z' + 1			; COMPARE TO LOWERCASE Z
	JR	NC,KBD_DEC10A		; ABOVE IT, BYPASS
	JR	KBD_DEC10B		; IN RANGE LOWERCASE A-Z, GO TO CASE SWAPPING LOGIC
KBD_DEC10A:
	CP	'A'			; COMPARE TO UPPERCASE A
	JR	C,KBD_DEC11		; BELOW IT, BYPASS
	CP	'Z' + 1			; COMPARE TO UPPERCASE Z
	JR	NC,KBD_DEC11		; ABOVE IT, BYPASS
	JR	KBD_DEC10B		; IN RANGE UPPERCASE A-Z, GO TO CASE SWAPPING LOGIC
KBD_DEC10B:
	LD	A,(KBD_KEYCODE)		; GET THE CURRENT KEYCODE
	XOR	$20			; FLIP BIT 5 TO SWAP UPPER/LOWER CASE
	LD	(KBD_KEYCODE),A		; SAVE IT

KBD_DEC11:	; HANDLE NUM PAD KEYS
	LD	A,(KBD_STATE)		; GET THE CURRENT STATE FLAGS
	AND	~KBD_NUMPAD		; ASSUME NOT A NUMPAD KEY, CLEAR THE NUMPAD BIT
	LD	(KBD_STATE),A		; SAVE IT
	
	LD	A,(KBD_KEYCODE)		; GET THE CURRENT KEYCODE
	AND	11100000B		; ISOLATE TOP 3 BITS
	CP	11000000B		; IS IN NUMPAD RANGE?
	JR	NZ,KBD_DEC12		; NOPE, GET OUT
	
	LD	A,(KBD_STATE)		; LOAD THE CURRENT STATE FLAGS
	OR	KBD_NUMPAD		; TURN ON THE NUMPAD BIT
	LD	(KBD_STATE),A		; SAVE IT

	AND	KBD_NUMLCK		; IS NUM LOCK BIT SET?
	JR	Z,KBD_DEC11A		; NO, SKIP NUMLOCK PROCESSING
	LD	A,(KBD_KEYCODE)		; GET THE KEYCODE
	XOR	$10			; FLIP VALUES FOR NUMLOCK
	LD	(KBD_KEYCODE),A		; SAVE IT

KBD_DEC11A:	; APPLY NUMPAD MAPPING
	LD	A,(KBD_KEYCODE)		; GET THE CURRENT KEYCODE
	LD	HL,KBD_MAPNUMPAD	; LOAD THE START OF THE MAPPING TABLE
	SUB	$C0			; KEYCODES START AT $C0
	LD	E,A			; INDEX TO E
	LD	D,0			; D IS ZERO
	ADD	HL,DE			; POINT TO RESULT OF MAPPING
	LD	A,(HL)			; GET IT IN A
	LD	(KBD_KEYCODE),A		; SAVE IT

KBD_DEC12:	; DETECT UNKNOWN/INVALID KEYCODES
	LD	A,(KBD_KEYCODE)		; GET THE FINAL KEYCODE
	CP	$FF			; IS IT $FF (UNKNOWN/INVALID)
	JP	Z,KBD_DECNEW		; IF SO, JUST RESTART THE ENGINE

KBD_DEC13:	; DONE - RECORD RESULTS
	LD	A,(KBD_STATUS)		; GET CURRENT STATUS
	OR	KBD_KEYRDY		; SET KEY READY BIT
	LD	(KBD_STATUS),A		; SAVE IT
	XOR	A			; A=0
	INC	A			; SIGNAL SUCCESS WITH A=1
	RET
	
KBD_DECNEW:	; START NEW KEYPRESS (CLEAR ALL STATUS BITS)
	XOR	A			; A = 0
	LD	(KBD_STATUS),A		; CLEAR STATUS
	JP	KBD_DEC1		; RESTART THE ENGINE
;
#IF (KBDKBLOUT == KBD_US)
;__________________________________________________________________________________________________
;
; MAPPING TABLES US/ENGLISH
;__________________________________________________________________________________________________
KBD_MAPSTD:	; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE
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
KBD_MAPSIZ	.EQU	($ - KBD_MAPSTD)
;
KBD_MAPSHIFT:	; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE WHEN SHIFT ACTIVE
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
KBD_MAPEXT:	; PAIRS ARE [SCANCODE,KEYCODE] FOR EXTENDED SCANCODES
	.DB	$11,$B5,	$14,$B3,	$1F,$B6,	$27,$B7
	.DB	$2F,$EF,	$37,$FA,	$3F,$FB,	$4A,$CB
	.DB	$5A,$CF,	$5E,$FC,	$69,$F3,	$6B,$F8
	.DB	$6C,$F2,	$70,$F0,	$71,$F1,	$72,$F7
	.DB	$74,$F9,	$75,$F6,	$7A,$F5,	$7C,$ED
	.DB	$7D,$F4,	$7E,$FD,	$00,$00
;
KBD_MAPNUMPAD:	; KEYCODE TRANSLATION FROM NUMPAD RANGE TO STD ASCII/KEYCODES
	.DB	$F3,$F7,$F5,$F8,$FF,$F9,$F2,$F6,$F4,$F0,$F1,$2F,$2A,$2D,$2B,$0D
	.DB	$31,$32,$33,$34,$35,$36,$37,$38,$39,$30,$2E,$2F,$2A,$2D,$2B,$0D
#ENDIF
#IF (KBDKBLOUT == KBD_DE)
;__________________________________________________________________________________________________
;
; MAPPING TABLES GERMAN
;__________________________________________________________________________________________________
;
KBD_MAPSTD: ; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE             ROW

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
 
KBD_MAPSIZ  .EQU  ($ - KBD_MAPSTD)
;
KBD_MAPSHIFT:     ; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE WHEN SHIFT ACTIVE

      .DB   $FF,$E8,$FF,$E4,$E2,$E0,$E1,$EB,$FF,$E9,$E7,$E5,$E3,$09,'~',$FF        ; '°' --> '~'
      .DB   $FF,$B4,$B0,$FF,$B2,'Q','!',$FF,$FF,$FF,'Y','S','A','W',$22,$FF       
      .DB   $FF,'C','X','D','E','$',$20,$FF,$FF,' ','V','F','T','R','%',$FF        ; '§'-->$20; '§'=Paragraph not used in CP/M
      .DB   $FF,'N','B','H','G','Z','&',$FF,$FF,$FF,'M','J','U','/','(',$FF
      .DB   $FF,';','K','I','O','=',')',$FF,$FF,':','_','L','{','P','?',$FF        ; 'Ö'-->'{'
      .DB   $FF,$FF,'@',$FF,'}','`',$FF,$FF,$BC,$B1,$0D,'*',$FF,$27,$FF,$FF        ; 'Ä'-->'@' ; 'Ü'-->'}'
      .DB   $FF,'>',$FF,$FF,$FF,$FF,$08,$FF,$FF,$D0,$FF,$D3,$D6,'>',$FF,$FF
      .DB   $D9,$DA,$D1,$D4,$D5,$D7,$1B,$BD,$FA,$DE,$D2,$DD,$DC,$D8,$BE,$FF
      .DB   $FF,$FF,$FF,$E6,$EC

KBD_MAPEXT: ; PAIRS ARE [SCANCODE,KEYCODE] FOR EXTENDED SCANCODES
	.DB         $11,$B5,	$14,$B3,	$1F,$B6,	$27,$B7
	.DB         $2F,$EF,	$37,$FA,	$3F,$FB,	$4A,$CB		; All keys listed below are customized for Wordstar.
	.DB         $5A,$CF,	$5E,$FC,	$69,$06,	$6B,$13		; n.a , n.a , word right , n.a.
	.DB         $6C,$01,	$70,$16,	$71,$07,	$72,$18		; Word left , Toggle Insert/Overwrite , Del Char , Cursor down
	.DB         $74,$04,	$75,$05,	$7A,$1A,	$7C,$ED		; Cursor right , Cursor up , Page down
	.DB         $7D,$17,	$7E,$FD,	$00,$00				; Page up , n.a. , END KBD_MAPEXT (Pairs end)
;
KBD_MAPNUMPAD:    ; KEYCODE TRANSLATION FROM NUMPAD RANGE TO STD ASCII/KEYCODES

      .DB   $F3,$F7,$F5,$F8,$FF,$F9,$F2,$F6,$F4,$F0,$F1,$2F,$2A,$2D,$2B,$0D
      .DB   $31,$32,$33,$34,$35,$36,$37,$38,$39,$30,$2E,$2F,$2A,$2D,$2B,$0D
;
#ENDIF
;
;__________________________________________________________________________________________________
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
