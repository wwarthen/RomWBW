;
;==================================================================================================
; CH376 NATIVE USB KEYBOARD DRIVER
;==================================================================================================
;
; This driver is designed to work within the TMS video driver for a CRT solution.


#IF (!CHNATIVEENABLE)
	.ECHO	"*** TMSMODE: TMSMODE_MSXUKY REQUIRES CHNATIVEENABLE***\n"
	!!!!! *** TMSMODE: TMSMODE_MSXUKY REQUIRES CHNATIVEENABLE***
_usb_kyb_status:
_usb_kyb_flush:
#ENDIF


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
UKY_STAT:	.EQU	_usb_kyb_status

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
;   E: Keycode
;
; Read the next key data from the keyboard. If a buffer is used, return the next key code in the buffer.
; If no key data is available, this function will wait indefinitely for a key press. The Status (A) is a
; standard HBIOS result code.
;
; The Keycode (E) is generally returned as appropriate ASCII values, if possible. Special keys, like
; function keys and arrows, are returned as reserved codes.
;
UKY_READ:
	CALL	_usb_kyb_read
	LD	A, H
	OR	A
	JR	NZ, UKY_READ
	LD	E, L
	XOR	A
	RET
