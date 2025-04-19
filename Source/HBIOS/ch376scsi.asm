;
;==================================================================================================
; CH376 NATIVE MASS STORAGE DRIVER
;==================================================================================================
;

#include "./ch376-native/scsi-drv.s"

	; find and mount all Mass Storage USB devices
CHSCSI_INIT	.EQU	_chscsi_init

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

CH_SCSI_STATUS:
	; LD	A, (IY)
	XOR	A
	RET

CH_SCSI_RESET:
	; LD	A, (IY)
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
	EX	DE, HL

	push	IY
	CALL	_chnative_seek
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

	; call scsi_read(IY, HL);
	; HL = HL + 512
	push	hl
	push	iy
	call	_scsi_read
	ld	a, l
	pop	iy
	pop	hl
	ld	bc, 512
	add	hl, bc
	ret
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

	; call scsi_write(IY, HL);
	; HL = HL + 512
	push	hl
	push	iy
	call	_scsi_write
	ld	a, l
	pop	iy
	pop	hl
	ld	bc, 512
	add	hl, bc
	ret

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
	LD	C, %00111010		; TODO?
	LD	D, DIODEV_USB
	LD	E, (iy+16) ;???? device_config_storage.drive_index
	LD	H, 0
	LD	L, 0
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
	LD	E, MID_HD	;todo verify device still active?
	XOR	A
	RET

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
	push	ix
	ld	ix, -8		; reserve 8 bytes for 
	add	ix, sp		; scsi_read_capacity_result
	ld	sp, ix

	push	ix
	push	iy
	call	_scsi_read_capacity
	pop	iy
	pop	ix

	ld	d, (ix)		; response.number_of_blocks[0]
	ld	e, (ix+1)	; response.number_of_blocks[1]
	ld	h, (ix+2)	; response.number_of_blocks[2]
	ld	l, (ix+3)	; response.number_of_blocks[3]
	ld	b, (ix+6)	; response.block_size[2]
	ld	c, (ix+7)	; response.block_size[3]

	ld	ix, 8
	add	ix, sp
	ld	sp, ix
	pop	ix

	xor	a		; todo determine a drive status
	ret
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
