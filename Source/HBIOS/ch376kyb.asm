;
;==================================================================================================
; CH376 NATIVE USB KEYBOARD DRIVER
;==================================================================================================
;
; This driver is designed to work within the TMS video driver for a CRT solution.

#DEFINE DEFM	.DB
#DEFINE DEFB	.DB
#DEFINE DEFW	.DW

#IF (!CHNATIVEEZ80)
#IF (SYSTIM == TM_NONE)
	.ECHO	"*** ERROR: MKY REQUIRES SYSTEM TIMER -- NONE CONFIGURED!!!\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF
#ENDIF

#include "./ch376-native/keyboard.s"

#IF (CHNATIVEEZ80)
CHUKB_INIT	.EQU	_keyboard_init

#ELSE
; COUNT FOR INTERRUPT HANDLER TO TRIGGER KEYBOARD SCANNER (EG: SCAN KEYBOARD ONLY EVERY 2ND INTERRUPT (2/60))
SCAN_INT_PERIOD:	.EQU	2

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
	CALL	_keyboard_init
	OR	A
	RET	Z

	; INSTALL INTERRUPT HANDLER
	LD	HL, (VEC_TICK+1)
	LD	(VEC_CHUKB_TICK+1), HL

	LD	HL, CHUKB_TICK
	LD	(VEC_TICK+1), HL

	RET

CHUKB_TICK:
	LD      A, SCAN_INT_PERIOD	; SCAN THE KEYBOARD EVERY 'SCAN_INT_PERIOD' INTERRUPTS.
UKY_SCNCNT	.EQU	$ - 1
	DEC     A
	LD      (UKY_SCNCNT), A
	JP	NZ, HB_TICK

	LD      A, SCAN_INT_PERIOD
	LD      (UKY_SCNCNT), A

	; we gonna need a bigger stack

	LD	(UKY_INT_SP),SP		; SAVE ORIGINAL STACK FRAME
	LD	SP,UKY_INTSTK		; USE DEDICATED INT STACK FRAME IN HI MEM

	CALL	_usb_kyb_tick

	LD	SP, $FFFF		; RESTORE ORIGINAL STACK FRAME
UKY_INT_SP	.EQU	$ - 2
;


VEC_CHUKB_TICK:
	JP	HB_TICK

#ENDIF

; ### Function 0x4C -- Keyboard Status (VDAKST)
;
; Inputs:
;   None
;
; Outputs:
;   A: Status / Codes Pending
;   B: Number of buffered usb reports
;   A': USB Report Modifier Key State (valid if B > 0)
;   B', C', D', E', H', L': USB Report's 6 key codes (valid only if B > 0)
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
; USB Keyboard Extension:
; Returns the current USB HID keyboard report data.
; Register B contains the number of buffered reports available:
;   B = 0: No reports available
;   B > 0: At least one report available (will be consumed after reading)
; When a report is available (B > 0):
;   A': Contains modifier key states
;   B',C',D',E',H',L': Contains up to 6 concurrent key codes
; See USB HID Usage Tables specification for key codes

UKY_STAT	.EQU	_usb_kyb_report

; ### Function 0x4D -- Video Keyboard Flush (VDAKFL)
;
; Inputs:
;   None
;
; Outputs:
;   A: standard HBIOS result code
;
; Purged and all contents discarded. The Status (A) is a standard HBIOS result code.
;
UKY_FLUSH	.EQU	_usb_kyb_flush

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
; If no key data is available, this function will wait indefinitely for a key press. The Status (A) is a
; standard HBIOS result code.
;
; The Scancode (C) value is the raw scan code from the keyboard for the key press. Scan codes are standard
; usb scan codes
;
; The Keystate (D) is a bitmap representing the value of all modifier keys and shift states as they
; existed at the time of the keystroke. The bitmap is defined as:
;
; Bit Key state Indication
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
; function keys and arrows, are returned as reserved codes.
;
UKY_READ:
	CALL	_usb_kyb_buf_get_next
	LD	A, H
	OR	A
	JR	NZ, UKY_READ
	LD	C, L
	XOR	A
	RET
