;
;==================================================================================================
; CH376 NATIVE MASS STORAGE DRIVER
;==================================================================================================
;

#include "./ch376-native/ufi-drv.s"
_ufi_seek	.EQU	_usb_scsi_seek

	; find and mount all floppy USB drives
CHUFI_INIT	.EQU	_chufi_init

; DRIVER FUNCTION TABLE
;
_ch_ufi_fntbl
CH_UFI_FNTBL:
	.DW	CH_UFI_STATUS
	.DW	CH_UFI_RESET
	.DW	CH_UFI_SEEK
	.DW	CH_UFI_READ
	.DW	CH_UFI_WRITE
	.DW	CH_UFI_VERIFY
	.DW	CH_UFI_FORMAT
	.DW	CH_UFI_DEVICE
	.DW	CH_UFI_MEDIA
	.DW	CH_UFI_DEFMED
	.DW	CH_UFI_CAP
	.DW	CH_UFI_GEOM
#IF (($ - CH_UFI_FNTBL) != (DIO_FNCNT * 2))
	.ECHO	"*** INVALID CH_UFI_FNTBL FUNCTION TABLE ***\n"
#ENDIF

CH_UFI_STATUS:
	XOR	A
	RET

CH_UFI_RESET:
	XOR	A
	RET
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
;if
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
CH_UFI_SEEK:
	EXX
	LD	D, 0
	LD	E, (IY+1)		; usb_device
	PUSH	DE
	POP	IY
	EXX

	BIT	7,D			; CHECK FOR LBA FLAG
	CALL	Z,CH_UFI_CHS2LBA	; CLEAR MEANS CHS, CONVERT TO LBA
	RES	7,D			; CLEAR FLAG REGARDLESS (DOES NO HARM IF ALREADY LBA)

	PUSH	DE
	PUSH	HL
	PUSH	IY
	CALL	_ufi_seek
	POP	IY
	POP	HL
	POP	DE

	XOR	A
	RET
;
; Helper function to convert CHS address in DE:HL to LBA.
; Currently assumes 1.44MB floppy media
; LBA = (TRACK * #HDS * #SPT) + (HEAD * #SPT)  + SECTOR
; For 1.44MB FLOPPY, #HDS = 2, #SPT = 18
; LBA = (TRACK * 36) + (HEAD * 18) + SECTOR
; Algorithm uses B=#HDS*SPT, C=#SPT.  For now, hard coded B=36, C=18
; for 1.44MB media.  In future, BC could be passed in to accommodate
; different media geometry.
;
CH_UFI_CHS2LBA:
	LD	B,2 * 18		; #HDS * #SPT (SECTORS PER CYLINDER)
	LD	C,18			; #SPT

	; TRACK * #HDS * #SPT
	PUSH	DE			; SAVE DE
	LD	E,B			; SECTORS PER CYLINDER
	LD	H,L			; LSB OF TRACK TO H, H IS NEVER USED BY FLOPPY CHS
	CALL	MULT8			; HL = H * E; TRACK LBA
	POP	DE			; RECOVER DE
	PUSH	HL			; SAVE TRACK LBA
	
	; HEAD * #SPT
	PUSH	DE			; SAVE DE
	LD	E,C			; SECTORS PER TRACK
	LD	H,D			; HEADS
	CALL	MULT8			; HL = H * E; HEAD LBA
	POP	DE			; RECOVER DE

	; COMPUTE LBA (HL) = SECTOR (E) + HEAD LBA (HL) + TRACK LBA (TOS)
	LD	A,E			; SECTOR
	CALL	ADDHLA			; SECTOR * HEAD LBA
	POP	DE			; RECOVER TRACK LBA
	ADD	HL,DE			; ADD IN TRACK LBA

	; FINISH UP
	LD	DE,0			; DE IS ALWAYS ZERO
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
CH_UFI_READ:
	EXX
	LD	D, 0
	LD	E, (IY+1)		; usb_device
	PUSH	DE
	POP	IY
	EXX

	CALL	HB_DSKREAD		; HOOK HBIOS DISK READ SUPERVISOR

	PUSH	HL
	PUSH	IY
	CALL	_usb_ufi_read
	LD	L, 0
	LD	A, L
	POP	IY
	POP	HL
	LD	BC, 512
	ADD	HL, BC
	OR	A
	RET
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
CH_UFI_WRITE:
	EXX
	LD	D, 0
	LD	E, (IY+1)		; usb_device
	PUSH	DE
	POP	IY
	EXX

	CALL	HB_DSKWRITE		; HOOK HBIOS DISK WRITE SUPERVISOR

	; call scsi_write(IY, HL);
	; HL = HL + 512
	PUSH	HL
	PUSH	IY
	CALL	_usb_ufi_write
	LD	A, L
	POP	IY
	POP	HL
	LD	BC, 512
	ADD	HL, BC
	OR	A
	RET

CH_UFI_VERIFY:
CH_UFI_FORMAT:
	LD	HL, 0
	LD	DE, 0
	LD	BC, 0
	LD	A, $FF
	OR	A
	RET

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
CH_UFI_DEVICE:
	LD	C, %11010110
	LD	D, DIODEV_USB
	LD	E, (IY+0)			; drive_index
	DEC	E
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
CH_UFI_MEDIA:
	LD	E, MID_FD144	;todo verify device still active?
	XOR	A
	RET

CH_UFI_DEFMED:
	LD	HL, 0
	LD	DE, 0
	LD	BC, 0
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
CH_UFI_CAP:
	EXX
	LD	D, 0
	LD	E, (IY+1)		; usb_device
	PUSH	DE
	POP	IY
	EXX

	PUSH	IY
	CALL	_usb_ufi_get_cap
	POP	IY
	LD	BC, 512
	XOR	A
	RET

CH_UFI_GEOM:
	LD	HL, 0
	LD	DE, 0
	LD	BC, 0
	LD	A, $FF
	OR	A
	RET
