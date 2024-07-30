;
; Generated from source-doc/base-drv/./print.c.asm -- not to be modify directly
;
; 
;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.3.0 #14210 (Linux)
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
;source-doc/base-drv/./print.c:4: print_string("\r\n  $");
	ld	hl,print_str_0
	call	_print_string
;source-doc/base-drv/./print.c:5: print_uint16(count);
	ld	iy,4
	add	iy, sp
	ld	l,(iy+0)
	ld	h,0x00
	call	_print_uint16
;source-doc/base-drv/./print.c:6: print_string(description);
	ld	hl,2
	add	hl, sp
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	call	_print_string
;source-doc/base-drv/./print.c:7: if (count > 1)
	ld	a,0x01
	ld	iy,4
	add	iy, sp
	sub	(iy+0)
	ret	NC
;source-doc/base-drv/./print.c:8: print_string("S$");
	ld	hl,print_str_1
;source-doc/base-drv/./print.c:9: }
	jp	_print_string
print_str_0:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "  $"
	DEFB 0x00
print_str_1:
	DEFM "S$"
	DEFB 0x00
