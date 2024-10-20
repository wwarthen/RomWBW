;
;==================================================================================================
; CH376 NATIVE USB KEYBOARD DRIVER
;==================================================================================================
;

#DEFINE DEFM	.DB
#DEFINE DEFB	.DB
#DEFINE DEFW	.DW

#IF (SYSTIM == TM_NONE)
	.ECHO	"*** ERROR: MKY REQUIRES SYSTEM TIMER -- NONE CONFIGURED!!!\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF

#include "./ch376-native/keyboard.s"

; COUNT FOR INTERRUPT HANDLER TO TRIGGER KEYBOARD SCANNER (EG: SCAN KEYBOARD ONLY EVERY 3RD INTERRUPT (3/60))
SCAN_INT_PERIOD:	.EQU	3

; VDP-INTERUPT COUNTER THAT COUNTS FROM SCAN_INT_PERIOD TO 0, WHEN IT REACHES ZERO, THE
; KEYBOARD MATRIX IS SCANNED, AND THE COUNTERS IS RESET AT SCAN_INT_PERIOD
UKY_SCNCNT:		.DB	SCAN_INT_PERIOD

	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
UKY_INTSTK:	; 128 bytes for keyboard interrupt stack - need ~52 bytes???

CHUKB_INIT:
	; INSTALL INTERRUPT HANDLER
	LD	HL, (VEC_TICK+1)
	LD	(VEC_CHUKB_TICK+1), HL

	LD	HL, CHUKB_TICK
	LD	(VEC_TICK+1), HL

	JP	_keyboard_init

CHUKB_TICK:
	LD      A, (UKY_SCNCNT)			; SCAN THE KEYBOARD EVERY 'SCAN_INT_PERIOD' INTERRUPTS.
	DEC     A
	LD      (UKY_SCNCNT), A
	JR	NZ, VEC_CHUKB_TICK

	LD      A, SCAN_INT_PERIOD
	LD      (UKY_SCNCNT), A

	; we gonna need a bigger stack

	EZ80_UTIL_DEBUG

	LD	(UKY_INT_SP),SP		; SAVE ORIGINAL STACK FRAME
	LD	SP,UKY_INTSTK		; USE DEDICATED INT STACK FRAME IN HI MEM

	CALL	_keyboard_tick

	LD	SP, $FFFF		; RESTORE ORIGINAL STACK FRAME
UKY_INT_SP	.EQU	$ - 2
;


VEC_CHUKB_TICK:
	JP	HB_TICK


; ### Function 0x4C -- Keyboard Status (VDAKST)
;
; Inputs:
;   None
;
; Outputs:
;   A: Status / Codes Pending
;
; Return a count of the number of key Codes Pending (A) in the keyboard buffer. 
; If it is not possible to determine the actual number in the buffer, it is 
; acceptable to return 1 to indicate there are key codes available to read and 
; 0 if there are none available.
; The value returned in register A is used as both a Status (A) code and the 
; return value. Negative values (bit 7 set) indicate a standard HBIOS result 
; (error) code. Otherwise, the return value represents the number of key codes 
; pending.
;
UKY_STAT:
	JP	_keyboard_buf_size

; ### Function 0x4D -- Video Keyboard Flush (VDAKFL)
;
; Inputs:
;   C: Video Unit
;
; Outputs:
;   A: standard HBIOS result code
;
; Purged and all contents discarded. The Status (A) is a standard HBIOS result code.
;
UKY_FLUSH:
	CALL	_keyboard_buf_flush
	XOR	A
	RET
;
; ### Function 0x4E -- Video Keyboard Read (VDAKRD)
;
; Inputs:
;   None
;
; Outputs:
;   A: Status
;   C: Scancode
;   D: Keystate
;   E: Keycode
;
; Read the next key data from the keyboard. If a buffer is used, return the next key code in the buffer.
; If no key data is available, this function will wait indefinitely for a keypress. The Status (A) is a 
; standard HBIOS result code.
;
; The Scancode (C) value is the raw scancode from the keyboard for the keypress. Scancodes are from 
; the PS/2 scancode set 2 standard.
;
; The Keystate (D) is a bitmap representing the value of all modifier keys and shift states as they 
; existed at the time of the keystroke. The bitmap is defined as:
;
; Bit Keystate Indication
; 7   Key pressed was from the num pad
; 6   Caps Lock was active
; 5   Num Lock was active
; 4   Scroll Lock was active
; 3   Windows key was held down
; 2   Alt key was held down
; 1   Control key was held down
; 0   Shift key was held down
;
; The Keycode (E) is generally returned as appropriate ASCII values, if possible. Special keys, like 
; function keys and arrows, are returned as reserved codes as described at the start of this section.
;
UKY_READ:
	HB_DI
	CALL	_keyboard_buf_get_next
	HB_EI
	LD	A, H
	OR	A
	JR	NZ, UKY_READ
	LD	C, 0
	LD	D, 0
	; LD	E, 'A'
	XOR	A
	RET
