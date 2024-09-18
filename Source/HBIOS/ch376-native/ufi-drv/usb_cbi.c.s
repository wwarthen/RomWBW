;
; Generated from source-doc/ufi-drv/./usb_cbi.c.asm -- not to be modify directly
;
; 
;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.4.0 #14648 (Linux)
;--------------------------------------------------------
; Processed by Z88DK
;--------------------------------------------------------
	

;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
;--------------------------------------------------------
; Externals used
;--------------------------------------------------------
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
_CH376_DATA_PORT	.EQU	0xff88
_CH376_COMMAND_PORT	.EQU	0xff89
_USB_MODULE_LEDS	.EQU	0xff8a
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	
#IF 0
	
; .area _INITIALIZED removed by z88dk
	
_cbi2_adsc:
	DEFS 8
	
#ENDIF
	
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
;--------------------------------------------------------
; Home
;--------------------------------------------------------
;--------------------------------------------------------
; code
;--------------------------------------------------------
;source-doc/ufi-drv/./usb_cbi.c:9: usb_error usb_execute_cbi(device_config *const storage_device,
; ---------------------------------
; Function usb_execute_cbi
; ---------------------------------
_usb_execute_cbi:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/./usb_cbi.c:18: const uint8_t interface_number = storage_device->interface_number;
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	l, c
	ld	h, b
	inc	hl
	inc	hl
	ld	e, (hl)
;source-doc/ufi-drv/./usb_cbi.c:21: adsc           = cbi2_adsc;
	push	de
	push	bc
	ex	de, hl
	ld	hl,4
	add	hl, sp
	ex	de, hl
	ld	hl,_cbi2_adsc
	ld	bc,0x0008
	ldir
	pop	bc
	pop	de
;source-doc/ufi-drv/./usb_cbi.c:22: adsc.bIndex[0] = interface_number;
	ld	(ix-4),e
;source-doc/ufi-drv/./usb_cbi.c:24: result = usbdev_control_transfer(storage_device, &adsc, (uint8_t *const)cmd);
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	ld	hl,2
	add	hl, sp
	push	hl
	push	bc
	call	_usbdev_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/ufi-drv/./usb_cbi.c:26: if (result == USB_ERR_STALL) {
	cp	0x02
	jr	NZ,l_usb_execute_cbi_00104
;source-doc/ufi-drv/./usb_cbi.c:27: if (sense_codes != NULL)
	ld	a,(ix+14)
	or	(ix+13)
	jr	Z,l_usb_execute_cbi_00102
;source-doc/ufi-drv/./usb_cbi.c:28: usbdev_dat_in_trnsfer(storage_device, sense_codes, 2, ENDPOINT_INTERRUPT_IN);
	ld	a,0x02
	push	af
	inc	sp
	ld	hl,0x0002
	push	hl
	ld	l,(ix+13)
	ld	h,(ix+14)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usbdev_dat_in_trnsfer
	pop	af
	pop	af
	pop	af
	inc	sp
l_usb_execute_cbi_00102:
;source-doc/ufi-drv/./usb_cbi.c:30: return USB_ERR_STALL;
	ld	l,0x02
	jp	l_usb_execute_cbi_00118
l_usb_execute_cbi_00104:
;source-doc/ufi-drv/./usb_cbi.c:33: if (result != USB_ERR_OK) {
	or	a
	jr	Z,l_usb_execute_cbi_00106
;source-doc/ufi-drv/./usb_cbi.c:35: return result;
	ld	l, a
	jr	l_usb_execute_cbi_00118
l_usb_execute_cbi_00106:
;source-doc/ufi-drv/./usb_cbi.c:38: if (send) {
	bit	0,(ix+8)
	jr	Z,l_usb_execute_cbi_00112
;source-doc/ufi-drv/./usb_cbi.c:39: result = usbdev_blk_out_trnsfer(storage_device, buffer, buffer_size);
	ld	l,(ix+9)
	ld	h,(ix+10)
	push	hl
	ld	l,(ix+11)
	ld	h,(ix+12)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usbdev_blk_out_trnsfer
	pop	af
	pop	af
	pop	af
;source-doc/ufi-drv/./usb_cbi.c:41: if (result != USB_ERR_OK) {
	ld	a, l
	or	a
	jr	Z,l_usb_execute_cbi_00113
;source-doc/ufi-drv/./usb_cbi.c:43: return result;
	jr	l_usb_execute_cbi_00118
l_usb_execute_cbi_00112:
;source-doc/ufi-drv/./usb_cbi.c:46: result = usbdev_dat_in_trnsfer(storage_device, buffer, buffer_size, ENDPOINT_BULK_IN);
	ld	a,0x01
	push	af
	inc	sp
	ld	l,(ix+9)
	ld	h,(ix+10)
	push	hl
	ld	l,(ix+11)
	ld	h,(ix+12)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usbdev_dat_in_trnsfer
	pop	af
	pop	af
	pop	af
	inc	sp
;source-doc/ufi-drv/./usb_cbi.c:48: if (result != USB_ERR_OK) {
	ld	a, l
	or	a
;source-doc/ufi-drv/./usb_cbi.c:50: return result;
	jr	NZ,l_usb_execute_cbi_00118
l_usb_execute_cbi_00113:
;source-doc/ufi-drv/./usb_cbi.c:54: if (sense_codes != NULL) {
	ld	a,(ix+14)
	or	(ix+13)
	jr	Z,l_usb_execute_cbi_00117
;source-doc/ufi-drv/./usb_cbi.c:55: result = usbdev_dat_in_trnsfer(storage_device, sense_codes, 2, ENDPOINT_INTERRUPT_IN);
	ld	a,0x02
	push	af
	inc	sp
	ld	hl,0x0002
	push	hl
	ld	l,(ix+13)
	ld	h,(ix+14)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usbdev_dat_in_trnsfer
	pop	af
	pop	af
	pop	af
	inc	sp
;source-doc/ufi-drv/./usb_cbi.c:57: if (result != USB_ERR_OK) {
	ld	a, l
	or	a
;source-doc/ufi-drv/./usb_cbi.c:59: return result;
	jr	NZ,l_usb_execute_cbi_00118
l_usb_execute_cbi_00117:
;source-doc/ufi-drv/./usb_cbi.c:63: return USB_ERR_OK;
	ld	l,0x00
l_usb_execute_cbi_00118:
;source-doc/ufi-drv/./usb_cbi.c:64: }
	ld	sp, ix
	pop	ix
	ret
_cbi2_adsc:
	DEFB +0x21
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0xff
	DEFB +0x00
	DEFW +0x000c
