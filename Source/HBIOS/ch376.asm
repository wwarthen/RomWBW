;
;==================================================================================================
; CH376 NATIVE USB DRIVER
;==================================================================================================
;

#DEFINE DEFM	.DB
#DEFINE DEFB	.DB
#DEFINE DEFW	.DW

_print_string	.EQU	PRTSTR

_print_hex:
	ld	a, l
	JP	PRTHEXBYTE

_delay:
	push	af
	call	DELAY
	call	DELAY
	call	DELAY
	call	DELAY
	call	DELAY
	call	DELAY
	call	DELAY
	call	DELAY
	pop	af
	ret

_delay_20ms:
	LD	DE, 1250
	JP	VDELAY
;
; DELAY approx 60ms
_delay_short:
	LD	DE, 3750
	JP	VDELAY
;
; DELAY approx 1/2 second
_delay_medium	.EQU	LDELAY

_dio_add_entry:
	LD	B, H
	LD	C, L
	JP	DIO_ADDENT		; ADD ENTRY TO GLOBAL DISK DEV TABLE

#include "./ch376-native/base-drv.asm"
#include "./ch376-native/print.asm"
#include "./ch376-native/cruntime.asm"
#include "./ch376-native/base-drv.s"

CHNATIVE_INIT	.EQU	_chnative_init
CHNATIVE_INITF	.EQU	_chnative_init_force
