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


CHUKB_INIT	.EQU	_keyboard_init

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
	XOR A
	RET

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
	RET
