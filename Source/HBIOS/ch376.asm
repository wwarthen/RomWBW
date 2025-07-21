;
;==================================================================================================
; CH376 NATIVE USB DRIVER
;==================================================================================================
;

#DEFINE DEFM	.DB
#DEFINE DEFB	.DB
#DEFINE DEFW	.DW

_CH376_DAT_PORT_ADDR	.EQU	_CH376_DATA_PORT
_CH376_CMD_PORT_ADDR	.EQU	_CH376_COMMAND_PORT
_USB_MOD_LEDS_ADDR	.EQU	_USB_MODULE_LEDS

_print_string	.EQU	PRTSTR

_print_hex:
	ld	a, l
	JP	PRTHEXBYTE

_dio_add_entry:
	LD	B, H
	LD	C, L
	JP	DIO_ADDENT		; ADD ENTRY TO GLOBAL DISK DEV TABLE

#IF (CHNATIVEEZ80)

#include "./ch376-native/ez80-firmware.asm"

_ch376_driver_version:
	.DB	",F); $", 0

#ELSE

_ch376_driver_version:
	.DB	",W); $", 0

_delay:
	push	af
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

#include "./ch376-native/cruntime.asm"
#include "./ch376-native/base-drv.asm"
#ENDIF

#include "./ch376-native/print.asm"
#include "./ch376-native/base-drv.s"

CHNATIVE_INIT	.EQU	_chnative_init
CHNATIVE_INITF	.EQU	_chnative_init_force

