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

; extern uint8_t usb_ufi_read(const uint16_t dev_index, uint8_t *const buffer)
_usb_ufi_read:
	LD	IY, 0
	ADD	IY, SP

	LD	C, (IY+2)
	LD	E, (IY+4)
	LD	D, (IY+5)
	EZ80_EXTN_DE_TO_MB_DE
	EZ80_EX_USB_UFI_READ
	LD	L, A
	RET

;extern usb_error usb_ufi_write(const uint16_t dev_index, uint8_t *const buffer);
_usb_ufi_write:
	LD	IY, 0
	ADD	IY, SP

	LD	C, (IY+2)
	LD	E, (IY+4)
	LD	D, (IY+5)
	EZ80_EXTN_DE_TO_MB_DE
	EZ80_EX_USB_UFI_WRITE
	LD	L, A
	RET

; extern uint32_t  usb_ufi_get_cap(const uint16_t dev_index)
_usb_ufi_get_cap:
	LD	IY, 0
	ADD	IY, SP

	LD	C, (IY+2)
	EZ80_EXTN_DE_TO_MB_DE
	EZ80_EX_USB_UFI_GET_CAP		; 

	LD	D, E			; convert E:uHL to DE:HL
	EZ80_CPY_UHL_TO_EHL
	RET

; extern void usb_kyb_init(const uint8_t dev_index) __sdcccall(1);
_usb_kyb_init:
	LD	C, A
	EZ80_EX_USB_KYB_INIT
	RET

; extern uint8_t  usb_kyb_flush() __sdcccall(1);
_usb_kyb_flush:
	EZ80_EX_USB_KYB_FLUSH
	RET

; extern uint8_t  usb_kyb_status() __sdcccall(1);
_usb_kyb_status:
	EZ80_EX_USB_KYB_STATUS
	RET

; extern uint16_t usb_kyb_read();
;  H = 0/1 set if char, L=>code 
_usb_kyb_read:
	EZ80_EX_USB_KYB_READ
	LD	H, A
	RET


;usb_device_type usb_get_device_type(const uint16_t dev_index)
_usb_get_device_type:
	LD	IY, 0
	ADD	IY, SP

	LD	C, (IY+2)
	EZ80_EX_USB_GET_DEV_TYPE
	LD	L, A
	RET
