;==============================================================================
; REBOOT - Allows the user to Cold or Warm Boot the RomWBW System
; Version 1.0 12-October-2024
;==============================================================================
;
; Author: MartinR (October 2024)
;    Based **very heavily** on code by Wayne Warthen (wwarthen@gmail.com)
;______________________________________________________________________________
;
; Usage:
;   REBOOT [/C] [/W] [/?]
;     ex: REBOOT	Display version and usage
;         REBOOT /?	Display version and usage
;         REBOOT /C	Cold boot RomWBW system
;	  REBOOT /W	Warm boot RomWBW system
;
; Operation:
;   Cold or warm boots a RomWBW system depending on the user option selected.
;
; This code will only execute on a Z80 CPU (or derivitive)
;
; This source code assembles with TASM V3.2 under Windows-11 using the
; following command line:
;	tasm -80 -g3 -l REBOOT.ASM REBOOT.COM
;	ie: Z80 CPU; output format 'binary' named .COM (rather than .OBJ)
;	and includes a symbol table as part of the listing file.
;______________________________________________________________________________
;
; Change Log:
;   2024-09-11 [WBW] Release of RomWBW CPU Speed Selector v1.0 used as the basis
;   2024-10-12 [MR ] Initial release of version 1.0
;______________________________________________________________________________
;
; Include Files
;
#include "../../ver.inc"		; Used for building RomWBW
#include "../../HBIOS/hbios.inc"

;#include "ver.inc"			; Used for testing purposes....
;#include "hbios.inc"			; ....during code development
;
;===============================================================================
;
; General operational equates (should not requre adjustment)
;
stksiz		.equ	$40		; Working stack size
;
restart		.equ	$0000		; CP/M restart vector
bdos		.equ	$0005		; BDOS invocation vector
;
bf_sysreset	.equ	$F0		; restart system
bf_sysres_int	.equ	$00		; reset hbios internal
bf_sysres_warm	.equ	$01		; warm start (restart boot loader)
bf_sysres_cold	.equ	$02		; cold start
;
ident		.equ	$FFFC		; loc of RomWBW HBIOS ident ptr
;
;===============================================================================
;
	.org	$0100			; standard CP/M TPA executable
;
	; setup stack (save old value)
	ld	(stksav),sp		; save stack
	ld	sp,stack		; set new stack
;
	call	crlf
	ld	de,str_banner		; banner
	call	prtstr
;
	; initialization
	call	init			; initialize
	jr	nz,exit			; abort if init fails
;
	call	main			; do the real work
;
exit:
	; clean up and return to command processor
	call	crlf			; formatting
	ld	sp,(stksav)		; restore stack
	jp	restart			; return to CP/M via restart
;
;
;===============================================================================
; Main Program
;===============================================================================
;
; Initialization
;
init:
	; check for UNA (UBIOS)
	ld	a,($FFFD)	; fixed location of UNA API vector
	cp	$C3		; jp instruction?
	jr	nz,initwbw	; if not, not UNA
	ld	hl,($FFFE)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$FD		; first byte of UNA push ix instruction
	jr	nz,initwbw	; if not, not UNA
	inc	hl		; point to next byte
	ld	a,(hl)		; get next byte
	cp	$E5		; second byte of UNA push ix instruction
	jr	nz,initwbw	; if not, not UNA
	jp	err_una		; UNA not supported
;
initwbw:
	; get location of config data and verify integrity
	ld	hl,(ident)	; HL := adr or RomWBW HBIOS ident
	ld	a,(hl)		; get first byte of RomWBW marker
	cp	'W'		; match?
	jp	nz,err_inv	; abort with invalid config block
	inc	hl		; next byte (marker byte 2)
	ld	a,(hl)		; load it
	cp	~'W'		; match?
	jp	nz,err_inv	; abort with invalid config block
	inc	hl		; next byte (major/minor version)
	ld	a,(hl)		; load it
	cp	rmj << 4 | rmn	; match?
	jp	nz,err_ver	; abort with invalid os version
;
initz:
	; initialization complete
	xor	a		; signal success
	ret			; return
;
;
;
main:
	; skip to start of first command line parameter
	ld	ix,$0081	; point to start of parm area (past length byte)
	call	nonblank	; skip to next non-blank char
	cp	'/'		; option prefix?
	jr	nz,usage	; display help info & exit if nothing to do
;
	; process any options
	inc	ix		; fetch next character and process
	ld	a,(ix)
	call	upcase		; ensure it's an upper case character
	cp	'C'		; if it's a 'C' then
	jr	z,cboot		; do a cold boot.
	cp	'W'		; if it's a 'W' then
	jr	z,wboot		; do a warm boot.
	cp	'?'		; if it's a '?' then
	jr	z,usage		; display usage info and exit.
	jr	err_parm	; or not a recognised option, so report and exit.
;
; Handle Usage Information
;
usage:
	call	crlf2		; display the options for this utility
	ld	de,str_usage
	call	prtstr
	or	$FF
	ret			; exit back out to CP/M CCP
;
; Handle Warm Boot
;
wboot:
	ld	de,str_warmboot		; message
	call	prtstr			; display it
	ld	b,bf_sysreset		; system restart
	ld	c,bf_sysres_warm	; warm start
	call	$fff0			; call hbios
;
; Handle Cold Boot
;
cboot:
	ld	de,str_coldboot		; message
	call	prtstr			; display it
	ld	b,bf_sysreset		; system restart
	ld	c,bf_sysres_cold	; cold start
	call	$fff0			; call hbios
;
;===============================================================================
; Error Handlers
;===============================================================================
;
err_una:
	ld	de,str_err_una
	jr	err_ret
err_inv:
	ld	de,str_err_inv
	jr	err_ret
err_ver:
	ld	de,str_err_ver
	jr	err_ret
err_parm:
	ld	de,str_err_parm
	jr	err_ret

;
err_ret:
	call	crlf2
	call	prtstr
	or	$FF			; signal error
	ret
;
;===============================================================================
; Utility Routines
;===============================================================================
;
; Print character in A without destroying any registers
;
prtchr:
	push	af
	push	bc		; save registers
	push	de
	push	hl
	ld	e,a		; character to print in E
	ld	c,$02		; BDOS function to output a character
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	pop	af
	ret
;
; Start a new line
;
crlf2:
	call	crlf		; two of them
crlf:
	push	af		; preserve AF
	ld	a,13		; <CR>
	call	prtchr		; print it
	ld	a,10		; <LF>
	call	prtchr		; print it
	pop	af		; restore AF
	ret
;
; Print a zero terminated string at (de) without destroying any registers
;
prtstr:
	push	af
	push	de
;
prtstr1:
	ld	a,(de)		; get next char
	or	a
	jr	z,prtstr2
	call	prtchr
	inc	de
	jr	prtstr1
;
prtstr2:
	pop	de		; restore registers
	pop	af
	ret
;
; Get the next non-blank character from (ix)
;
nonblank:
	ld	a,(ix)		; load next character
	or	a		; string ends with a null
	ret	z		; if null, return pointing to null
	cp	' '		; check for blank
	ret	nz		; return if not blank
	inc	ix		; if blank, increment character pointer
	jr	nonblank	; and loop
;
; Convert character in A to uppercase
;
upcase:
	cp	'a'		; if below 'a'
	ret	c		; ... do nothing and return
	cp	'z' + 1		; if above 'z'
	ret	nc		; ... do nothing and return
	res	5,a		; clear bit 5 to make lower case -> upper case
	ret			; and return
;
;===============================================================================
; Constants
;===============================================================================
;
str_banner	.db	"RomWBW Reboot Utility, Version 1.0, 12-Oct-2024\r\n"
		.db	"   Wayne Warthen (wwarthen@gmail.com) & MartinR",0
;
str_warmboot	.db	"\r\n\r\nWarm booting...\r\n",0
str_coldboot	.db	"\r\n\r\nCold booting...\r\n",0
;
str_err_una	.db	"  ERROR: UNA not supported by application",0
str_err_inv	.db	"  ERROR: Invalid BIOS (signature missing)",0
str_err_ver	.db	"  ERROR: Unexpected HBIOS version",0
str_err_parm	.db	"  ERROR: Parameter error (REBOOT /? for usage)",0
;
str_usage	.db	"  Usage: REBOOT /? - Display this help info.\r\n"
		.db	"         REBOOT /W - Warm boot system\r\n"
		.db	"         REBOOT /C - Cold boot system\r\n"
		.db	"         Options are case insensitive.\r\n",0
;
;===============================================================================
; Working data
;===============================================================================
;
stksav		.dw	0		; stack pointer saved at start
		.fill	stksiz,0	; stack
stack		.equ	$		; stack top
;
;===============================================================================
;
	.end