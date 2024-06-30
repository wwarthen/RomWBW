;===============================================================================
; TIMER - Display system timer value
; Version 1.21 30-June-2024
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;	Updated: MartinR (June 2024)
;_______________________________________________________________________________
;
; Usage:
;   TIMER [/C] [/?]
;     ex: TIMER		(display current timer value)
;         TIMER /?	(display version and usage)
;         TIMER /C	(display timer value continuously)
;
; Operation:
;   Reads and displays system timer value.
;
; This code will only execute on a Z80 CPU (or derivitive)
;
; This source code assembles with TASM V3.2 under Windows-11 using the
; following command line:
;	tasm -80 -g3 -l TIMER.ASM TIMER.COM
;	ie: Z80 CPU; output format 'binary' named .COM (rather than .OBJ)
;	and includes a symbol table as part of the listing file.
;_______________________________________________________________________________
;
; Change Log:
;   2018-01-14 [WBW] Initial release
;   2018-01-17 [WBW] Add HBIOS check
;   2019-11-08 [WBW] Add seconds support
;   2024-06-30 [MR ] Display values in decimal rather than hexadecimal
;_______________________________________________________________________________
;
; Includes binary-to-decimal subroutine by Alwin Henseler
; Located at: https://www.msx.org/forum/development/msx-development/32-bit-long-ascii
;_______________________________________________________________________________
;
; ToDo:
;	Display the elapsed time in HH:MM:SS
;_______________________________________________________________________________
;
#include "../ver.inc"		; Used for building RomWBW
;#include "ver.inc"		; Used for testing purposes during code development
;
;===============================================================================
; Definitions
;===============================================================================
;
stksiz		.equ	$80	; Working stack size (was $40)
;		                
restart		.equ	$0000	; CP/M restart vector
bdos		.equ	$0005	; BDOS invocation vector
;		                
ident		.equ	$FFFE	; loc of RomWBW HBIOS ident ptr
;
bf_sysver	.equ	$F1	; BIOS: VER function
bf_sysget	.equ	$F8	; HBIOS: SYSGET function
bf_sysset	.equ	$F9	; HBIOS: SYSSET function
bf_sysgettimer	.equ	$D0	; TIMER subfunction
bf_syssettimer	.equ	$D0	; TIMER subfunction
bf_sysgetsecs	.equ	$D1	; SECONDS subfunction
bf_syssetsecs	.equ	$D1	; SECONDS subfunction
;
; ASCII Control Characters
;
lf		.equ 	$0A	; Line Feed
cr		.equ 	$0D	; Carriage Return
;
;===============================================================================
; Code Section
;===============================================================================
;
	.org	$100
;
	; setup stack (save old value)
	ld	(stksav),sp	; save stack
	ld	sp,stack	; set new stack
;
	; initialization
	call	init		; initialize
	jr	nz,exit		; abort if init fails
;
	; process
	call 	process		; do main processing
	jr	nz,exit		; abort on error
;
exit:	; clean up and return to command processor
	call	crlf		; formatting
	ld	sp,(stksav)	; restore stack
	;jp	restart		; return to CP/M via restart
	ret			; return to CP/M w/o restart
;
; Initialization
;
init:
	call	crlf			; formatting
	ld	de,msgban		; point to version message part 1
	call	prtstr			; print it
;	
	call	idbio			; identify active BIOS
	cp	1			; check for HBIOS
	jp	nz,errbio		; handle BIOS error
;	
	ld	a,rmj << 4 | rmn	; expected HBIOS ver
	cp	d			; compare with result above
	jp	nz,errbio		; handle BIOS error
;
initx
	; initialization complete
	xor	a		; signal success
	ret			; return
;
; Process
;
process:
	; look for start of parms
	ld	hl,$81		; point to start of parm area (past len byte)
;
process00:
	call	nonblank	; skip to next non-blank char
	jp	z,process0	; no more parms, go to display
;
	; check for option, introduced by a "/"
	cp	'/'		; start of options?
	jp	nz,usage	; yes, handle option
	call	option		; do option processing
	ret	nz		; done if non-zero return
	jr	process00	; continue looking for options
;
process0:
;
	; Test of API function to set seconds value
	;ld	b,bf_sysset	; HBIOS SYSGET function
	;ld	c,bf_syssetsecs	; SECONDS subfunction
	;ld	de,0		; set seconds value
	;ld	hl,1000		; ... to 1000
	;rst	08		; call HBIOS, DE:HL := seconds value
;
	; get and print seconds value
	call	crlf2		; formatting
;
process1:
	ld	b,bf_sysget		; HBIOS SYSGET function
	ld	c,bf_sysgettimer	; TIMER subfunction
	rst	08			; call HBIOS, DE:HL := timer value
	
	ld	a,(first)
	or	a
	ld	a,0
	ld	(first),a
	jr	nz,process1a
	
	; test for new value
	ld	a,(last)	; last LSB value to A
	cp	l		; compare to current LSB
	jr	z,process2	; if equal, bypass display

;*******************************************************************************
	
; Code added/amended to print values in decimal
; MartinR June2024	

process1a:
	; save and print new value
	ld	a,l			; new LSB value to A
	ld	(last),a		; save as last value
	call	prtcr			; back to start of line
	
	call	b2d32			; Convert DE:HL into ASCII; Start of ASCII buffer returned in HL
	ex	de,hl
	call	prtstr			; Display the value
	
	ld	de,strtick		; "Ticks" message 
	call	prtstr			; Display it

	; get and print seconds value
	ld	b,bf_sysget		; HBIOS SYSGET function
	ld	c,bf_sysgetsecs		; SECONDS subfunction
	rst	08			; Call HBIOS; DE:HL := seconds value; C := fractional part
	push	bc			; Preserve the fractional part on the stack

	call	b2d32			; Convert DE:HL into ASCII; Start of ASCII buffer returned in HL
	ex	de,hl
	call	prtstr			; Display the value

	ld	a,'.'			; Fraction separator, ie decimal point
	call	prtchr			; Print it

	pop	bc			; Retrieve fractional part into A
	ld	a,c
	sla	a			; Double the 50Hz 'ticks' value to give 1/100s of a second

	call	b2d8			; Convert into ASCII - up to 3 digits
	ex	de,hl			; Start of ASCII buffer returned in HL
	call	prtstr			; Display fractional part of the value
	
	ld	de,strsec		; "Seconds" message
	call	prtstr			; Display it

;*******************************************************************************
		
process2:
	ld	a,(cont)	; continuous display?
	or	a		; test for true/false
	jr	z,process3	; if false, get out
;
	ld	c,6		; BDOS: direct console I/O
	ld	e,$FF		; input char
	call	bdos		; call BDOS, A := char
	or	a		; test for zero
	jr	z,process1	; loop until char pressed
;
process3:
	xor	a		; signal success
	ret
;
; Handle special options
;
option:
;
	inc	hl		; next char
	ld	a,(hl)		; get it
	or	a		; zero terminator?
	ret	z		; done if so
	cp	' '		; blank?
	ret	z		; done if so
	cp	'?'		; is it a '?'?
	jp	z,usage		; yes, display usage
	cp	'C'		; is it a 'C', continuous?
	jp	z,setcont	; yes, set continuous display
	jp	errprm		; anything else is an error
;
usage:
;
	jp	erruse		; display usage and get out
;
setcont:
;
	or	$FF		; set A to true
	ld	(cont),a	; and set continuous flag
	jr	option		; check for more option letters
;
; Identify active BIOS.  RomWBW HBIOS=1, UNA UBIOS=2, else 0
;
idbio:
;
	; Check for UNA (UBIOS)
	ld	a,($FFFD)	; fixed location of UNA API vector
	cp	$C3		; jp instruction?
	jr	nz,idbio1	; if not, not UNA
	ld	hl,($FFFE)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$FD		; first byte of UNA push ix instruction
	jr	nz,idbio1	; if not, not UNA
	inc	hl		; point to next byte
	ld	a,(hl)		; get next byte
	cp	$E5		; second byte of UNA push ix instruction
	jr	nz,idbio1	; if not, not UNA, check others
;
	ld	bc,$04FA	; UNA: get BIOS date and version
	rst	08		; DE := ver, HL := date
;
	ld	a,2		; UNA BIOS id = 2
	ret			; and done
;
idbio1:
	; Check for RomWBW (HBIOS)
	ld	hl,($FFFE)	; HL := HBIOS ident location
	ld	a,'W'		; First byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
	inc	hl		; Next byte of ident
	ld	a,~'W'		; Second byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
;
	ld	b,bf_sysver	; HBIOS: VER function
	ld	c,0		; required reserved value
	rst	08		; DE := version, L := platform id
;	
	ld	a,1		; HBIOS BIOS id = 1
	ret			; and done
;
idbio2:
	; No idea what this is
	xor	a		; Setup return value of 0
	ret			; and done
;
; Print character in A without destroying any registers
;
prtchr:
	push	bc		; save registers
	push	de
	push	hl
	ld	e,a		; character to print in E
	ld	c,$02		; BDOS function to output a character
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	ret
;
prtdot:
;
	; shortcut to print a dot preserving all regs
	push	af		; save af
	ld	a,'.'		; load dot char
	call	prtchr		; print it
	pop	af		; restore af
	ret			; done
;
prtcr:
;
	; shortcut to print carriage return preserving all regs
	push	af		; save af
	ld	a,cr		; load CR value
	call	prtchr		; print it
	pop	af		; restore af
	ret			; done
;
; Print a zero terminated string at (DE) without destroying any registers
;
prtstr:
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
	ret	
;
; Print the value in A in hex without destroying any registers
;
prthex:
	push	af		; save AF
	push	de		; save DE
	call	hexascii	; convert value in A to hex chars in DE
	ld	a,d		; get the high order hex char
	call	prtchr		; print it
	ld	a,e		; get the low order hex char
	call	prtchr		; print it
	pop	de		; restore DE
	pop	af		; restore AF
	ret			; done
;
; print the hex word value in bc
;
prthexword:
	push	af
	ld	a,b
	call	prthex
	ld	a,c
	call	prthex 
	pop	af
	ret
;
; print the hex dword value in de:hl
;
prthex32:
	push	bc
	push	de
	pop	bc
	call	prthexword
	push	hl
	pop	bc
	call	prthexword
	pop	bc
	ret
;
; Convert binary value in A to ascii hex characters in DE
;
hexascii:
	ld	d,a		; save A in D
	call	hexconv		; convert low nibble of A to hex
	ld	e,a		; save it in E
	ld	a,d		; get original value back
	rlca			; rotate high order nibble to low bits
	rlca
	rlca
	rlca
	call	hexconv		; convert nibble
	ld	d,a		; save it in D
	ret			; done
;
; Convert low nibble of A to ascii hex
;
hexconv:
	and	$0F	     	; low nibble only
	add	a,$90
	daa	
	adc	a,$40
	daa	
	ret
;
; Print value of A or HL in decimal with leading zero suppression
; Use prtdecb for A or prtdecw for HL
;
prtdecb:
	push	hl
	ld	h,0
	ld	l,a
	call	prtdecw		; print it
	pop	hl
	ret
;
prtdecw:
	push	af
	push	bc
	push	de
	push	hl
	call	prtdec0
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
prtdec0:
	ld	e,'0'
	ld	bc,-10000
	call	prtdec1
	ld	bc,-1000
	call	prtdec1
	ld	bc,-100
	call	prtdec1
	ld	c,-10
	call	prtdec1
	ld	e,0
	ld	c,-1
prtdec1:
	ld	a,'0' - 1
prtdec2:
	inc	a
	add	hl,bc
	jr	c,prtdec2
	sbc	hl,bc
	cp	e
	ret	z
	ld	e,0
	call	prtchr
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
; Get the next non-blank character from (HL).
;
nonblank:
	ld	a,(hl)		; load next character
	or	a		; string ends with a null
	ret	z		; if null, return pointing to null
	cp	' '		; check for blank
	ret	nz		; return if not blank
	inc	hl		; if blank, increment character pointer
	jr	nonblank	; and loop
;
; Convert character in A to uppercase
;
ucase:
	cp	'a'		; if below 'a'
	ret	c		; ... do nothing and return
	cp	'z' + 1		; if above 'z'
	ret	nc		; ... do nothing and return
	res	5,a		; clear bit 5 to make lower case -> upper case
	ret			; and return
;
; Add the value in A to HL (HL := HL + A)
;
addhl:
	add	a,l		; A := A + L
	ld	l,a		; Put result back in L
	ret	nc		; if no carry, we are done
	inc	h		; if carry, increment H
	ret			; and return
;
; Jump indirect to address in HL
;
jphl:
	jp	(hl)
;
; Errors
;
erruse:	; command usage error (syntax)
	ld	de,msguse
	jr	err
;
errprm:	; command parameter error (syntax)
	ld	de,msgprm
	jr	err
;
errbio:	; invalid BIOS or version
	ld	de,msgbio
	jr	err
;
err:	; print error string and return error signal
	call	crlf2		; print newline
;
err1:	; without the leading crlf
	call	prtstr		; print error string
;
err2:	; without the string
;	call	crlf		; print newline
	or	$FF		; signal error
	ret			; done
;
;
;===============================================================================
; Subroutine to print decimal numbers
;===============================================================================
;
; Combined routine for conversion of different sized binary numbers into
; directly printable ASCII(Z)-string
; Input value in registers, number size and -related to that- registers to fill
; is selected by calling the correct entry:
;
;   entry        input    decimal value 0 to:
;   b2d8             A                    255  (3 digits)
;   b2d16           HL                  65535   5   "
;   b2d24         E:HL               16777215   8   "
;   b2d32        DE:HL             4294967295  10   "
;   b2d48     BC:DE:HL        281474976710655  15   "
;   b2d64  IX:BC:DE:HL   18446744073709551615  20   "
;
; The resulting string is placed into a small buffer attached to this routine,
; this buffer needs no initialization and can be modified as desired.
; The number is aligned to the right, and leading 0's are replaced with spaces.
; On exit HL points to the first digit, (B)C = number of decimals
; This way any re-alignment / postprocessing is made easy.
; Changes: AF,BC,DE,HL,IX
;
; by Alwin Henseler
; https://msx.org/forum/topic/who-who/dutch-hardware-guy-pops-back-sort
;
; Found at:
; https://www.msx.org/forum/development/msx-development/32-bit-long-ascii
;
; Tweaked to assemble using TASM 3.2 by MartinR 23June2024
;
b2d8:	ld	h,0
	ld	l,a
b2d16:	ld	e,0
b2d24:	ld	d,0
b2d32:	ld	bc,0
b2d48:	ld	ix,0		; zero all non-used bits
b2d64:	ld	(b2dinv),hl
	ld	(b2dinv+2),de
	ld	(b2dinv+4),bc
	ld	(b2dinv+6),ix	; place full 64-bit input value in buffer
	ld	hl,b2dbuf
	ld	de,b2dbuf+1
	ld	(hl),' '
b2dfilc:.equ	$-1		; address of fill-character
	ld	bc,18
	ldir			; fill 1st 19 bytes of buffer with spaces
	ld	(b2dend-1),bc	; set BCD value to "0" & place terminating 0
	ld	e,1		; no. of bytes in BCD value
	ld	hl,b2dinv+8	; (address MSB input)+1
	ld	bc,$0909
	xor	a
b2dskp0:dec	b
	jr	z,b2dsiz	; all 0: continue with postprocessing
	dec	hl
	or	(hl)		; find first byte <> 0
	jr	z,b2dskp0
b2dfnd1:dec	c
	rla
	jr	nc,b2dfnd1	; determine no. of most significant 1-bit
	rra
	ld	d,a		; byte from binary input value
b2dlus2:push	hl
	push	bc
b2dlus1:ld	hl,b2dend-1	; address LSB of bcd value
	ld	b,e		; current length of BCD value in bytes
	rl	d		; highest bit from input value -> carry
b2dlus0:ld	a,(hl)
	adc	a,a
	daa
	ld	(hl),a		; double 1 BCD byte from intermediate result
	dec	hl
	djnz	b2dlus0		; and go on to double entire BCD value (+carry!)
	jr	nc,b2dnxt
	inc	e		; carry at MSB -> BCD value grew 1 byte larger
	ld	(hl),1		; initialize new MSB of BCD value
b2dnxt:	dec	c
	jr	nz,b2dlus1	; repeat for remaining bits from 1 input byte
	pop	bc		; no. of remaining bytes in input value
	ld	c,8		; reset bit-counter
	pop	hl		; pointer to byte from input value
	dec	hl
	ld	d,(hl)		; get next group of 8 bits
	djnz	b2dlus2		; and repeat until last byte from input value
b2dsiz:	ld	hl,b2dend	; address of terminating 0
	ld	c,e		; size of bcd value in bytes
	or	a
	sbc	hl,bc		; calculate address of MSB BCD
	ld	d,h
	ld	e,l
	sbc	hl,bc
	ex	de,hl		; HL=address BCD value, de=start of decimal value
	ld	b,c		; no. of bytes BCD
	sla	c		; no. of bytes decimal (possibly 1 too high)
	ld	a,'0'
	rld			; shift bits 4-7 of (HL) into bit 0-3 of A
	cp	'0'		; (HL) was > 9h?
	jr	nz,b2dexph	; if yes, start with recording high digit
	dec	c		; correct number of decimals
	inc	de		; correct start address
	jr	b2dexpl		; continue with converting low digit
b2dexp:	rld			; shift high digit (HL) into low digit of a
b2dexph:ld	(de),a		; record resulting ascii-code
	inc	de
b2dexpl:rld
	ld	(de),a
	inc	de
	inc	hl		; next BCD-byte
	djnz	b2dexp		; and go on to convert each BCD-byte into 2 ASCII
	sbc	hl,bc		; return with HL pointing to 1st decimal
	ret

b2dinv	.fill	8		; space for 64-bit input value (LSB first)
b2dbuf	.fill	20		; space for 20 decimal digits
b2dend	.db	0		; space for terminating character
;
;===============================================================================
; Storage Section
;===============================================================================
;
last	.db	0		; last LSB of timer value
cont	.db	0		; non-zero indicates continuous display
first	.db	$FF		; first pass flag (true at start)
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ $			; new stack top
;
; Messages
;
msgban	.db	"TIMER v1.21, 30-Jun-2024",cr,lf
	.db	"Copyright (C) 2019, Wayne Warthen, GNU GPL v3",cr,lf
	.db	"Updated by MartinR 2024",0
msguse	.db	"Usage: TIMER [/C] [/?]",cr,lf
	.db	"  ex. TIMER           (display current timer value)",cr,lf
	.db	"      TIMER /?        (display version and usage)",cr,lf
	.db	"      TIMER /C        (display timer value continuously)",0
msgprm	.db	"Parameter error (TIMER /? for usage)",0
msgbio	.db	"Incompatible BIOS or version, "
	.db	"HBIOS v", '0' + rmj, ".", '0' + rmn, " required",0
strtick	.db	" Ticks     ",0
strsec	.db	" Seconds  ",0
;
		.end
