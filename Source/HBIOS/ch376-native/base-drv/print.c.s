;
; Generated from source-doc/base-drv/./print.c.asm -- not to be modify directly
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
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	
#IF 0
	
; .area _INITIALIZED removed by z88dk
	
	
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
;source-doc/base-drv/./print.c:3: void print_device_mounted(const char *const description, const uint8_t count) {
; ---------------------------------
; Function print_device_mounted
; ---------------------------------
_print_device_mounted:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./print.c:4: print_string("\r\n  $");
	ld	hl,print_str_0
	call	_print_string
;source-doc/base-drv/./print.c:5: print_uint16(count);
	ld	e,(ix+6)
	ld	d,0x00
	ex	de, hl
	call	_print_uint16
;source-doc/base-drv/./print.c:6: print_string(description);
	ld	l,(ix+4)
	ld	h,(ix+5)
	call	_print_string
;source-doc/base-drv/./print.c:7: if (count > 1)
	ld	a,0x01
	sub	(ix+6)
	jr	NC,l_print_device_mounted_00103
;source-doc/base-drv/./print.c:8: print_string("S$");
	ld	hl,print_str_1
	call	_print_string
l_print_device_mounted_00103:
;source-doc/base-drv/./print.c:9: }
	pop	ix
	ret
print_str_0:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "  $"
	DEFB 0x00
print_str_1:
	DEFM "S$"
	DEFB 0x00
