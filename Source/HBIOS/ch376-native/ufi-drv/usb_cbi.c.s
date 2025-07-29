;
; Generated from source-doc/ufi-drv/usb_cbi.c.asm -- not to be modify directly
;
; 
;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.0 #15248 (Linux)
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
;source-doc/ufi-drv/usb_cbi.c:10: usb_error usb_execute_cbi(device_config *const storage_device,
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
;source-doc/ufi-drv/usb_cbi.c:17: const uint8_t interface_number = storage_device->interface_number;
	ld	l,(ix+4)
	ld	h,(ix+5)
	ld	c,l
	ld	b,h
	inc	hl
	inc	hl
	ld	e, (hl)
;source-doc/ufi-drv/usb_cbi.c:20: adsc           = cbi2_adsc;
	push	de
	push	bc
	ld	hl,4
	add	hl, sp
	ex	de, hl
	ld	bc,$0008
	ld	hl,_cbi2_adsc
	ldir
	pop	bc
	pop	de
;source-doc/ufi-drv/usb_cbi.c:21: adsc.bIndex[0] = interface_number;
	ld	(ix-4),e
;source-doc/ufi-drv/usb_cbi.c:23: critical_begin();
	push	bc
	call	_critical_begin
	pop	bc
;source-doc/ufi-drv/usb_cbi.c:25: result = usbdev_control_transfer(storage_device, &adsc, (uint8_t *const)cmd);
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
;source-doc/ufi-drv/usb_cbi.c:27: if (result == USB_ERR_STALL) {
	ld	a, l
	sub	$02
	jr	NZ,l_usb_execute_cbi_00104
;source-doc/ufi-drv/usb_cbi.c:28: if (sense_codes != NULL)
	ld	a,(ix+14)
	or	(ix+13)
	jr	Z,l_usb_execute_cbi_00102
;source-doc/ufi-drv/usb_cbi.c:29: usbdev_dat_in_trnsfer(storage_device, sense_codes, 2, ENDPOINT_INTERRUPT_IN);
	ld	a,$02
	push	af
	inc	sp
	ld	hl,$0002
	push	hl
	ld	l,(ix+13)
	ld	h,(ix+14)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usbdev_dat_in_trnsfer
	ld	hl,7
	add	hl, sp
	ld	sp, hl
l_usb_execute_cbi_00102:
;source-doc/ufi-drv/usb_cbi.c:31: result = USB_ERR_STALL;
	ld	l,$02
;source-doc/ufi-drv/usb_cbi.c:32: goto done;
	jr	l_usb_execute_cbi_00116
l_usb_execute_cbi_00104:
;source-doc/ufi-drv/usb_cbi.c:35: if (result != USB_ERR_OK) {
	ld	a, l
	or	a
	jr	NZ,l_usb_execute_cbi_00116
;source-doc/ufi-drv/usb_cbi.c:40: if (send) {
	bit	0,(ix+8)
	jr	Z,l_usb_execute_cbi_00112
;source-doc/ufi-drv/usb_cbi.c:41: result = usbdev_blk_out_trnsfer(storage_device, buffer, buffer_size);
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
;source-doc/ufi-drv/usb_cbi.c:43: if (result != USB_ERR_OK) {
	ld	a, l
	or	a
	jr	Z,l_usb_execute_cbi_00113
;source-doc/ufi-drv/usb_cbi.c:45: goto done;
	jr	l_usb_execute_cbi_00116
l_usb_execute_cbi_00112:
;source-doc/ufi-drv/usb_cbi.c:48: result = usbdev_dat_in_trnsfer(storage_device, buffer, buffer_size, ENDPOINT_BULK_IN);
	ld	a,$01
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
;source-doc/ufi-drv/usb_cbi.c:50: if (result != USB_ERR_OK) {
	ld	a, l
	or	a
	jr	NZ,l_usb_execute_cbi_00116
;source-doc/ufi-drv/usb_cbi.c:52: goto done;
l_usb_execute_cbi_00113:
;source-doc/ufi-drv/usb_cbi.c:56: if (sense_codes != NULL) {
	ld	a,(ix+14)
	or	(ix+13)
	jr	Z,l_usb_execute_cbi_00116
;source-doc/ufi-drv/usb_cbi.c:57: result = usbdev_dat_in_trnsfer(storage_device, sense_codes, 2, ENDPOINT_INTERRUPT_IN);
	ld	a,$02
	push	af
	inc	sp
	ld	hl,$0002
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
;source-doc/ufi-drv/usb_cbi.c:65: done:
l_usb_execute_cbi_00116:
;source-doc/ufi-drv/usb_cbi.c:66: critical_end();
	push	hl
	call	_critical_end
	pop	hl
;source-doc/ufi-drv/usb_cbi.c:68: return result;
;source-doc/ufi-drv/usb_cbi.c:69: }
	ld	sp, ix
	pop	ix
	ret
_cbi2_adsc:
	DEFB +$21
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$ff
	DEFB +$00
	DEFW +$000c
