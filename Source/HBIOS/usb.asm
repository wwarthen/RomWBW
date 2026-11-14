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
	LD	A, L
	JP	PRTHEXBYTE

; HBIOS DISK DEVICE CONFIG ENTRY, SEE hbios_storage_device_t,
; IN ch376-native/source-doc/base-drv/hbios-driver-storage.h.
; BYTES 0-15 ARE STANDARD (SEE STD.ASM, CFG_...)
; AND ARE FILLED IN BELOW.  KEEP IN SYNC WITH C STRUCTURE!!!
;
USB_CFG_DRVIDX	.EQU	16		; DRIVE INDEX (1-BASED) (BYTE)
USB_CFG_DEV	.EQU	17		; USB DEVICE INDEX (BYTE)
;
; REGISTER A DIO DEVICE IN THE HBIOS DISK UNIT TABLE
; HL = DRIVER FUNCTION TABLE, DE = CONFIG ENTRY
; DYNAMICALLY FILLS IN THE STANDARD CONFIG HEADER BEFORE REGISTERING.
;
_dio_add_entry:
	PUSH	IY			; PRESERVE FOR C
	PUSH	DE			; CONFIG ENTRY
	POP	IY			; ... TO IY
	LD	(IY+CFG_DISPTBL+0),L	; DRIVER FUNCTION
	LD	(IY+CFG_DISPTBL+1),H	; ... TABLE ADDRESS
	LD	(IY+CFG_DRVTYPE),'D'	; DRIVER TYPE
	LD	A,(IY+USB_CFG_DRVIDX)	; DRIVE INDEX (1-BASED)
	DEC	A			; ... TO 0-BASED
	LD	(IY+CFG_DEVNUM),A	; DRIVER UNIT NUMBER
	LD	(IY+CFG_STATUS),ERR_NONE		; ASSUME INIT WORKED
	LD	(IY+CFG_TAG+0),USB_STR_TAG & $FF	; DRIVER TAG STRING PTR
	LD	(IY+CFG_TAG+1),USB_STR_TAG >> 8		; ...
	LD	B,H			; BC := FUNC TABLE ADR
	LD	C,L			; ...
	CALL	DIO_ADDENT		; ADD ENTRY TO HBIOS DISK DEV TABLE
	LD	(IY+CFG_UNIT),A		; RECORD HBIOS UNIT NUMBER ASSIGNED
	POP	IY			; RESTORE IY
	RET
;
; SOME COMMON ROUTINES TO SUPPORT THE USB STORAGE SUB-DRIVERS (USBSCSI.ASM, USBUFI.ASM)
; IY *MUST* POINT TO CONFIG AT ENTRY!
;
; RETURN DEVICE STATUS
;
USB_STATUS:
	LD	A,(IY+CFG_STATUS)	; GET STATUS OF SELECTED DEVICE
	OR	A			; SET FLAGS
	RET				; AND RETURN
;
; RESET DEVICE.  THERE IS NO C ENTRY POINT TO REINITIALIZE A DEVICE, SO
; JUST CLEAR THE STATUS SO THE NEXT I/O IS ATTEMPTED AGAIN.
;
USB_RESET:
	XOR	A			; STATUS := OK
	LD	(IY+CFG_STATUS),A	; SAVE IT
	RET				; DONE, A=0, ZF SET
;
; RECORD THE LBA IN DE:HL AS THE CURRENT DISK ADDRESS (CFG_DSKADR) WITH
; THE LBA FLAG SET.  THIS IS JUST FOR THE HBIOS DISK SUPERVISOR TO USE
; WHEN UPDATING DSKY/LED DISPLAYS AND ERROR MESSAEGES.  THE DRIVER KEEPS
; IT'S OWN COPY.
;
USB_SETADR:
	LD	(IY+CFG_DSKADR+0),L	; SAVE NEW LBA
	LD	(IY+CFG_DSKADR+1),H	; ...
	LD	(IY+CFG_DSKADR+2),E	; ...
	LD	A,D			; ...
	OR	$80			; ... WITH LBA FLAG
	LD	(IY+CFG_DSKADR+3),A	; ...
	RET
;
; IMPLEMENT STANDARD HBIOS SECTOR I/O COMPLETION.  A HAS THE INTERNAL
; DRIVER RESULT (0=OK) AND HL THE BUFFER ADDRESS USED.  ON SUCCESS,
; BUMP THE LBA AND BUFFER.  ON ERROR, RECORD AND RETURN GENERIC HBIOS
; ERR_IO.  WE DON'T CURRENTLY MAP DRIVER ERRORS TO HBIOS ERRORS.
;
USB_IODONE:
	OR	A			; C RESULT OK?
	JR	NZ,USB_IODONE1		; IF NOT, HANDLE ERROR
	PUSH	HL			; SAVE BUFFER ADR
	CALL	HB_DSKINCLBA		; INCREMENT LBA
	POP	HL			; RESTORE BUFFER ADR
	LD	BC,512			; BUMP BUFFER
	ADD	HL,BC			; ... BY 512 BYTES
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
USB_IODONE1:
	LD	A,ERR_IO		; IO ERROR
	LD	(IY+CFG_STATUS),A	; RECORD IT
	OR	A			; SET FLAGS
	RET				; AND RETURN
;
USB_STR_TAG	.TEXT	"USB$"

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
