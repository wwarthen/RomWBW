;
;==================================================================================================
; CH376 NATIVE USB DRIVER
;==================================================================================================
;
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE HEADER
;--------------------------------------------------------------------------------------------------
;
ORG_USB	.EQU	$
;
	.DW	SIZ_USB			; MODULE SIZE
	.DW	USB_INITPHASE		; ADR OF INIT PHASE HANDLER
;
USB_INITPHASE:
	; INIT PHASE HANDLER, A=PHASE
	;CP	HB_PHASE_PREINIT	; PREINIT PHASE?
	;JP	Z,USB_PREINIT		; DO PREINIT
	CP	HB_PHASE_INIT		; INIT PHASE?
	JP	Z,USB_INIT		; DO INIT
	RET				; DONE

#DEFINE DEFM	.DB
#DEFINE DEFB	.DB
#DEFINE DEFW	.DW

CHNATIVEEZ80		.EQU	USB_EZ80

_CH376_DATA_PORT	.EQU	USB_DAT_PORT
_CH376_COMMAND_PORT	.EQU	USB_CMD_PORT
_USB_MODULE_LEDS	.EQU	USB_LED_PORT

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

#IF (USB_EZ80)

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

#IF (USB_FORCE)
USB_INIT	.EQU	_chnative_init_force
#ELSE
USB_INIT	.EQU	_chnative_init
#ENDIF

;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE TRAILER
;--------------------------------------------------------------------------------------------------
;
END_USB		.EQU	$
SIZ_USB		.EQU	END_USB - ORG_USB
;	
	MEMECHO	"USB occupies "
	MEMECHO	SIZ_USB
	MEMECHO	" bytes.\n"
