; delegate usb function to firmware of ez80 module

; extern uint16_t usb_init(uint8_t state) __z88dk_fastcall;
_usb_init:
	EZ80_EX_USB_INIT
	RET

; usb_error usb_scsi_seek(const uint16_t dev_index, const uint32_t lba)
_usb_scsi_seek:
	; iy+2 : dev_index
	; iy+4:5:6:7 : lba
	LD	IY, 0
	ADD	IY, SP
	EZ80_EXTN_IY_TO_MB_IY

	LD	C, (IY+2)
	LD_DE_IY_P_.L(4)	; LD.L	DE, (IY+4)
	LD	L, (IY+7)
	EZ80_EX_USB_STORAGE_SEEK
	LD	L, A
	RET

; usb_error usb_scsi_init(const uint16_t dev_index)
_usb_scsi_init:
	LD	IY, 0
	ADD	IY, SP

	LD	C, (IY+2)
	EZ80_EX_USB_SCSI_INIT
	LD	L, A
	RET

; usb_error usb_scsi_read(const uint16_t dev_index, uint8_t *const buffer);
_usb_scsi_read:
	LD	IY, 0
	ADD	IY, SP

	LD	C, (IY+2)
	LD	E, (IY+4)
	LD	D, (IY+5)
	EZ80_EXTN_DE_TO_MB_DE
	EZ80_EX_USB_SCSI_READ
	LD	L, A
	RET

; usb_error usb_scsi_write(const uint16_t dev_index, uint8_t *const buffer)
_usb_scsi_write:
	LD	IY, 0
	ADD	IY, SP

	LD	C, (IY+2)
	LD	E, (IY+4)
	LD	D, (IY+5)
	EZ80_EXTN_DE_TO_MB_DE
	EZ80_EX_USB_SCSI_WRITE
	LD	L, A
	RET

; usb_error usb_scsi_read_capacity(const uint16_t dev_index, scsi_read_capacity_result *cap_result)
_usb_scsi_read_capacity:
	LD	IY, 0
	ADD	IY, SP

	LD	C, (IY+2)
	LD	E, (IY+4)
	LD	D, (IY+5)
	EZ80_EXTN_DE_TO_MB_DE
	EZ80_EX_USB_SCSI_READ_CAP
	LD	L, A
	RET

_usb_ufi_read:
_usb_ufi_write:
_usb_ufi_get_cap:

_usb_kyb_flush:
_usb_kyb_report:
_usb_kyb_buf_get_next:
_usb_kyb_init:
	RET

;usb_device_type usb_get_device_type(const uint16_t dev_index)
_usb_get_device_type:
	LD	IY, 0
	ADD	IY, SP

	LD	C, (IY+2)
	EZ80_EX_USB_GET_DEV_TYPE
	LD	L, A
	RET

