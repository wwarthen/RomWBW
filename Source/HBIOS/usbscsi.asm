;
;==================================================================================================
; CH376 NATIVE MASS STORAGE DRIVER
;==================================================================================================
;
#IF (!USBENABLE)
	.ECHO	"*** ERROR: USB_SCSI REQUIRES USBENABLE!!!\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE HEADER
;--------------------------------------------------------------------------------------------------
;
ORG_USB_SCSI	.EQU	$
;
	.DW	SIZ_USB_SCSI		; MODULE SIZE
	.DW	USB_SCSI_INITPHASE	; ADR OF INIT PHASE HANDLER
;
USB_SCSI_INITPHASE:
	; INIT PHASE HANDLER, A=PHASE
	;CP	HB_PHASE_PREINIT	; PREINIT PHASE?
	;JP	Z,USB_SCSI_PREINIT	; DO PREINIT
	CP	HB_PHASE_INIT		; INIT PHASE?
	JP	Z,USB_SCSI_INIT		; DO INIT
	RET				; DONE

#include "./ch376-native/scsi-drv.s"

	; find and mount all Mass Storage USB devices
USB_SCSI_INIT	.EQU	_chscsi_init

; DRIVER FUNCTION TABLE
;
_ch_scsi_fntbl
CH_SCSI_FNTBL:
	.DW	CH_SCSI_STATUS
	.DW	CH_SCSI_RESET
	.DW	CH_SCSI_SEEK
	.DW	CH_SCSI_READ
	.DW	CH_SCSI_WRITE
	.DW	CH_SCSI_VERIFY
	.DW	CH_SCSI_FORMAT
	.DW	CH_SCSI_DEVICE
	.DW	CH_SCSI_MEDIA
	.DW	CH_SCSI_DEFMED
	.DW	CH_SCSI_CAP
	.DW	CH_SCSI_GEOM
#IF (($ - CH_SCSI_FNTBL) != (DIO_FNCNT * 2))
	.ECHO	"*** INVALID CH_SCSI_FNTBL FUNCTION TABLE ***\n"
#ENDIF

CH_SCSI_STATUS	.EQU	USB_STATUS	; SEE USB.ASM

CH_SCSI_RESET	.EQU	USB_RESET	; SEE USB.ASM

; ### Function 0x12 -- Disk Seek (DIOSEEK)
;
; Inputs:
;   IY: device config pointer
;   DEHL: Sector Address
;
; Outputs:
;   A: Status
;
; This function will set the desired sector to be used for the next I/O
; operation. The returned Status (A) is a standard HBIOS result code.
;
; The double-word Sector Address (DEHL) can represent either a Logical
; Block Address (LBA) or a Cylinder/Head/Sector (CHS).  Bit 7 of D is
; set (1) for LBA mode and cleared (0) for CHS mode.
;
; For LBA mode operation, the high bit is set and the rest of the
; double-word is then treated as the logical sector address.
;
; For CHS mode operation, the Sector Address (DEHL) registers are
; interpreted as: D=Head, E=Sector, and HL=Track.  All values (including
; sector) are 0 relative.
;
CH_SCSI_SEEK:
	BIT	7,D			; CHECK FOR LBA FLAG
	CALL	Z,HB_CHS2LBA		; CLEAR MEANS CHS, CONVERT TO LBA
	RES	7,D			; CLEAR FLAG REGARDLESS (DOES NO HARM IF ALREADY LBA)
	CALL	USB_SETADR		; RECORD IN CFG_DSKADR (SEE USB.ASM)

	; call usb_scsi_seek(usb_device, lba)
	PUSH	IY			; SAVE CONFIG ENTRY PTR
	LD	C,(IY+USB_CFG_DEV)	; usb_device
	LD	B,0			; ...
	PUSH	DE
	PUSH	HL
	PUSH	BC
	CALL	_usb_scsi_seek
	POP	BC
	POP	HL
	POP	DE
	POP	IY			; RESTORE CONFIG ENTRY PTR

	XOR	A
	RET
;
; ### Function 0x13 -- Disk Read (DIOREAD)
;
; Inputs
;  IY: device config pointer
;  D: Buffer Bank ID
;  E: Sector Count
;  HL: Buffer Address
;
; Outputs
;  A: Status
;  E: Sectors Read
;
; Read Sector Count (E) sectors into the buffer located in Buffer Bank ID (D) 
; at Buffer Address (HL) starting at the Current Sector.  The returned 
; Status (A) is a standard HBIOS result code.
;
CH_SCSI_READ:
	CALL	HB_DSKREAD		; HOOK HBIOS DISK READ SUPERVISOR
;
	PUSH	IY			; SAVE CONFIG ENTRY PTR
	PUSH	HL			; SAVE BUFFER ADR
	LD	C,(IY+USB_CFG_DEV)	; usb_device
	LD	B,0			; ...
	PUSH	HL			; ARG: BUFFER
	PUSH	BC			; ARG: usb_device
	CALL	_usb_scsi_read		; CALL INTERNAL SCSI READ
	POP	BC			; DISCARD ARGS
	POP	BC			; ...
	LD	A,L			; usb_error RESULT
	POP	HL			; RESTORE BUFFER ADR
	POP	IY			; RESTORE CONFIG ENTRY PTR
	JP	USB_IODONE		; FINISH UP (SEE USB.ASM)
;
; ### Function 0x14 -- Disk Write (DIOWRITE)
;
; Inputs
; IY: device config pointer
; D: Buffer Bank ID
; E: Sector Count
; HL: Buffer Address
;
; Outputs
; A: Status
; E: Sectors Written
;
; Write Sector Count (E) sectors from the buffer located in Buffer Bank ID (D)
; at Buffer Address (HL) starting at the Current Sector.  The returned 
; Status (A) is a standard HBIOS result code.
;
CH_SCSI_WRITE:
	CALL	HB_DSKWRITE		; HOOK HBIOS DISK WRITE SUPERVISOR
;
	PUSH	IY			; SAVE CONFIG ENTRY PTR
	PUSH	HL			; SAVE BUFFER ADR
	LD	C,(IY+USB_CFG_DEV)	; usb_device
	LD	B,0			; ...
	PUSH	HL			; ARG: BUFFER
	PUSH	BC			; ARG: usb_device
	CALL	_usb_scsi_write		; CALL INTERNAL SCSI WRITE
	POP	BC			; DISCARD ARGS
	POP	BC			; ...
	LD	A,L			; usb_error RESULT
	POP	HL			; RESTORE BUFFER ADR
	POP	IY			; RESTORE CONFIG ENTRY PTR
	JP	USB_IODONE		; FINISH UP (SEE USB.ASM)

CH_SCSI_VERIFY:
CH_SCSI_FORMAT:
	LD	A, $FF
	OR	A
	RET
;
; ### Function 0x17 -- Disk Device (DIODEVICE)
;
; Inputs
;   IY: device config pointer
;
; Outputs
;   A: Status
;   C: Device Attributes
;   D: Device Type (DIODEV_USB)
;   E: Device Number (1)
;   H: Device Unit Mode (0)
;   L: Device I/O Base Address
;
; Reports device information.  The Status (A) is a standard
; HBIOS result code.
;
; The Device Attribute (C):
;
; | **Bits** | **Definition**                                   |
; |---------:|--------------------------------------------------|
; | 7        | Floppy                                           |
; | 6        | Removable                                        |
; | 5        | High Capacity (>8 MB)                            |
;
; Low Capacity Devices??
;
; | **Bits** | **Definition**                                   |
; |---------:|--------------------------------------------------|
; | 4-3      | Form Factor: 0=8", 1=5.25", 2=3.5", 3=Other      |
; | 2        | Sides: 0=SS, 1=DS                                |
; | 1-0      | Density: 0=SD, 1=DD, 2=HD, 3=ED                  |
;
; High Capacity Devices
;
; | **Bits** | **Definition**                                   |
; |---------:|--------------------------------------------------|
; | 4        | LBA Capable                                      |
; | 3-0      | Media Type: 0=Hard Disk, 1=CF, 2=SD, 3=USB,      |
; |          |   4=ROM, 5=RAM, 6=RAMF, 7=FLASH, 8=CD-ROM,       |
; |          |   9=Cartridge, 10=usb-scsi, 11=usb-ufi           |
;
CH_SCSI_DEVICE:
	LD	C, %00111010
	LD	D, DIODEV_USB
	LD	E,(IY+CFG_DEVNUM)	; DRIVER UNIT NUMBER
	LD	HL, 0
	XOR	A
	RET
;
; ### Function 0x18 -- Disk Media (DIOMEDIA)
;
; Inputs
;  IY: device config pointer
;  E: Flags
;
; Outputs
;  A: Status
;  E: Media ID
;
; Report the Media ID (E) for the for media. If bit 0 of Flags (E) is set,
; then media discovery or verification  will be performed.  The Status
; (A) is a standard HBIOS result code. If there is no media in device,
; function will return an error status.
;
CH_SCSI_MEDIA:
	; THERE IS NO MECHANISM TO REDISCOVER MEDIA.  IF DISCOVERY IS
	; REQUESTED (BIT 0 OF E) AND THE UNIT IS IN AN ERROR STATE,
	; JUST RESET IT (CLEARS THE STATUS) AND SIGNAL A MEDIA CHANGE.
	LD	D,0			; ASSUME NO MEDIA CHANGE
	BIT	0,E			; MEDIA DISCOVERY REQUESTED?
	JR	Z,CH_SCSI_MEDIA_Z	; IF NOT, REPORT CURRENT INFO
	LD	A,(IY+CFG_STATUS)	; GET CURRENT STATUS
	OR	A			; SET FLAGS
	JR	Z,CH_SCSI_MEDIA_Z	; IF OK, REPORT CURRENT INFO
	CALL	USB_RESET		; RESET UNIT (SEE USB.ASM)
	LD	D,1			; SIGNAL MEDIA CHANGE
;
CH_SCSI_MEDIA_Z:
	LD	A,(IY+CFG_STATUS)	; GET CURRENT STATUS
	OR	A			; SET FLAGS
	LD	E,MID_HD		; ASSUME WE ARE OK
	RET	Z			; RETURN IF GOOD
	LD	E,MID_NONE		; ELSE SIGNAL NO MEDIA
	RET				; AND RETURN ERROR

CH_SCSI_DEFMED:
	LD	A, $FF
	OR	A
	RET
;
; ### Function 0x1A -- Disk Capacity (DIOCAPACITY)
;
; Inputs
; IY: device config pointer
;
; Outputs
; A: Status
; DEHL: Sector Count
; BC: Block Size
;
;
; Report the current media capacity information.
;
;
CH_SCSI_CAP:
	EXX
	LD	D, 0
	LD	E, (IY+USB_CFG_DEV)	; usb_device
	PUSH	DE
	POP	IY
	EXX

	PUSH	IX
	LD	IX, -8		; reserve 8 bytes for 
	ADD	IX, SP		; scsi_read_capacity_result
	LD	SP, IX

	PUSH	IX
	PUSH	IY
	CALL	_usb_scsi_read_capacity
	POP	IY
	POP	IX

	LD	D, (IX)		; response.number_of_blocks[0]
	LD	E, (IX+1)	; response.number_of_blocks[1]
	LD	H, (IX+2)	; response.number_of_blocks[2]
	LD	L, (IX+3)	; response.number_of_blocks[3]
	LD	B, (IX+6)	; response.block_size[2]
	LD	C, (IX+7)	; response.block_size[3]

	LD	IX, 8
	ADD	IX, SP
	LD	SP, IX
	POP	IX

	XOR	A		; todo determine a drive status
	RET
;
; ### Function 0x1B -- Disk Geometry (DIOGEOMETRY)
;
; Inputs
; IY: device config pointer
;
; Outputs
; A: Status
; D: Heads
; E: Sectors
; HL: Cylinder Count
; BC: Block Size
;
; Report the simulated geometry for the media. The Status (A) is a
; standard HBIOS result code.  If the media is unknown, an error will be returned.
;
; ** Does not appear to be used??
;
CH_SCSI_GEOM:
	; FOR LBA, WE SIMULATE CHS ACCESS USING 16 HEADS AND 16 SECTORS
	; RETURN HS:CC -> DE:HL, SET HIGH BIT OF D TO INDICATE LBA CAPABLE
	CALL	CH_SCSI_CAP		; GET TOTAL BLOCKS IN DE:HL, BLOCK SIZE TO BC
	LD	L,H			; DIVIDE BY 256 FOR # TRACKS
	LD	H,E			; ... HIGH BYTE DISCARDED, RESULT IN HL
	LD	D,16 | $80		; HEADS / CYL = 16, SET LBA CAPABILITY BIT
	LD	E,16			; SECTORS / TRACK = 16
	RET				; DONE, A STILL HAS CHUSB_CAP STATUS
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE TRAILER
;--------------------------------------------------------------------------------------------------
;
END_USB_SCSI	.EQU	$
SIZ_USB_SCSI	.EQU	END_USB_SCSI - ORG_USB_SCSI
;	
	MEMECHO	"USB_SCSI occupies "
	MEMECHO	SIZ_USB_SCSI
	MEMECHO	" bytes.\n"
