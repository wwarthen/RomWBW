;===============================================================================
; BANKTEST - Test RomWBW bank management API
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   BANKTEST
;
; Operation:
;   Steps through a series of banking API tests
;_______________________________________________________________________________
;
; Change Log:
;   2023-01-22 [WBW] Initial release
;_______________________________________________________________________________
;
; ToDo:
;_______________________________________________________________________________
;
;===============================================================================
; Definitions
;===============================================================================
;
runloc	.equ	$C000		; Running location (upper memory required)
stksiz	.equ	$40		; Working stack size
;
rmj	.equ	3		; intended HBIOS version - major
rmn	.equ	1		; intended HBIOS version - minor
;
restart	.equ	$0000		; CP/M restart vector
;
#include "../../../HBIOS/hbios.inc"
;
;===============================================================================
; Code Section
;===============================================================================
;
	.org	$100
;
	; relocate worker code to upper memory
	ld	hl,begin	; start of working code image
	ld	de,runloc	; running location
	ld	bc,size		; size of working code image
	ldir			; copy to upper RAM
	jp	runloc		; and go
;
; Start of working code
;
begin	.equ	$		; image loaded here
;
	.org	runloc		; now generate running location adresses
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
	call	crlf2		; formatting
	ld	de,msgban	; point to version message part 1
	call	prtstr		; print it
;
	call	idbio		; identify active BIOS
	cp	1		; check for HBIOS
	jp	nz,errbio	; handle BIOS error
;
	ld	a,rmj << 4 | rmn	; expected HBIOS ver
	cp	d		; compare with result above
	jp	nz,errbio	; handle BIOS error
;
initx
	; initialization complete
	xor	a		; signal success
	ret			; return
;
; Process
;
process:
;
; Start by testing a bank switch and dumping some memory
; from the new bank.
;
	di
;
	; Get and display current RAM bank
	ld	b,BF_SYSGETBNK	; HBIOS GetBank function
	rst	08		; do it via RST vector, C=bank id
	ld	a,c		; put bank id in A
	push	af		; save bank id returned
	call	crlf2
	ld	de,msgcur	; load message
	call	prtstr		; print it
	pop	af		; restore bank id
	call	prthex		; print the bank id
;
	; Switch to first RAM bank
	ld	b,BF_SYSSETBNK	; HBIOS SetBank function
	ld	c,$80		; first RAM bank
	rst	08		; do it via RST vector
	ld	a,c		; original bank id to accum
	ld	(orgbnk),a	; save it
;
; NOTE: Once the page zero of the default bank is swapped out, we
; cannot use RST 08 for HBIOS function calls because the vector is
; no longer in context.  Instead, we rely on the alternate call
; address entry point.
;
	; Do an HBIOS function call while bank switched
	call	crlf2
	ld	de,msg80	; message to print
	call	prtstr		; do it
;
	; Dump chunk of memory from bank
	call	crlf
	ld	de,0		; from 0x0000
	call	dump_buffer
;
	; Switch back to original bank
	ld	b,BF_SYSSETBNK	; HBIOS SetBank function
	ld	a,(orgbnk)	; get original bank back
	ld	c,a		; to C for function call
	call	HB_INVOKE	; do it via call
;
	ei
;
; Now poke a small procedure into an alternate bank and do an
; inter-bank call to execute it.
;
	; Copy test procedure to a foreign bank
	ld	b,BF_SYSSETCPY	; HBIOS SysSetCopy function
	ld	a,(orgbnk)	; our current bank is source
	ld	e,a		; put in D
	ld	d,xproc_bnk	; target bank is 0x80
	ld	hl,xproc_len	; length to copy
	rst	08		; do it
;
	ld	b,BF_SYSBNKCPY	; HBIOS SysBnkCopy function
	ld	de,xproc_loc	; destination address
	ld	hl,xproc	; source address
	rst	08		; do it
;
	; Do an inter-bank call to the test procedure
	di			; interrupts off
	ld	a,xproc_bnk	; target bank
	ld	ix,xproc_loc	; target address
	call	HB_BNKCALL	; do it and pray
	ei			; interrupts back on
;
	call	crlf2
	ld	de,msgdone	; message to print
	call	prtstr		; do it
;
	ret			; all done
;
; Test procedure to be copied into an alternate bank.  Code should
; be entirely relocatable.
;
xproc_bnk	.equ	$80	; alternate bank for test proc
xproc_loc	.equ	$1000	; run location for test proc
;
xproc:
	call	crlf2
	ld	de,msgxcal
	call	prtstr
	ret
;
xproc_end	.equ	$
xproc_len	.equ	xproc_end - xproc
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
	ld	hl,(HB_IDENT)	; HL := HBIOS ident location
	ld	a,'W'		; First byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
	inc	hl		; Next byte of ident
	ld	a,~'W'		; Second byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
;
	ld	b,BF_SYSVER	; HBIOS: VER function
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
	ld	b,BF_CIOOUT	; HBIOS function to output a character
	ld	c,CIO_CONSOLE	; write to current console unit
	call	HB_INVOKE	; invoke HBIOS via call
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
prtspace:
;
	; shortcut to print a space preserving all regs
	push	af		; save af
	ld	a,' '		; load dot char
	call	prtchr		; print it
	pop	af		; restore af
	ret			; done
;
prtcr:
;
	; shortcut to print a dot preserving all regs
	push	af		; save af
	ld	a,13		; load CR value
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
; Print a block of memory nicely formatted
;  de=buffer address
;
dump_buffer:
	call	crlf

	push	de
	pop	hl
	inc	d
	inc	d

db_blkrd:
	push	bc
	push	hl
	pop	bc
	call	prthexword		; print start location
	pop	bc
	call	prtspace		;
	ld	c,16			; set for 16 locs
	push	hl			; save starting hl
db_nxtone:
	ld	a,(hl)			; get byte
	call	prthex			; print it
	call	prtspace		;
db_updh:
	inc	hl			; point next
	dec	c			; dec. loc count
	jr	nz,db_nxtone		; if line not done
					; now print 'decoded' data to right of dump
db_pcrlf:
	call	prtspace		; space it
	ld	c,16			; set for 16 chars
	pop	hl			; get back start
db_pcrlf0:
	ld	a,(hl)			; get byte
	and	060h			; see if a 'dot'
	ld	a,(hl)			; o.k. to get
	jr	nz,db_pdot		;
db_dot:
	ld	a,2eh			; load a dot
db_pdot:
	call	prtchr			; print it
	inc	hl			;
	ld	a,d			;
	cp	h			;
	jr	nz,db_updh1		;
	ld	a,e			;
	cp	l			;
	jp	z,db_end		;
db_updh1:
; if block not dumped, do next character or line
	dec	c			; dec. char count
	jr	nz,db_pcrlf0		; do next
db_contd:
	call	crlf			;
	jp	db_blkrd		;

db_end:
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
;===============================================================================
; Storage Section
;===============================================================================
;
orgbnk	.db	0		; original bank id at startup
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Messages
;
msgban	.db	"BANKTEST v1.0, 22-Jan-2023",13,10
	.db	"Copyright (C) 2023, Wayne Warthen, GNU GPL v3",0
msguse	.db	"Usage: BANKTEST",13,10
msgprm	.db	"Parameter error (BANKTEST /? for usage)",0
msgbio	.db	"Incompatible BIOS or version, "
	.db	"HBIOS v", '0' + rmj, ".", '0' + rmn, " required",0
msgcur	.db	"Initial Bank ID = 0x",0
msg80	.db	"Hello from bank 0x80!",0
msgxcal	.db	"Inter-bank procedure call test...",0
msgdone	.db	"End of bank test",0
;
;
;
size	.equ	$ - runloc
;
	.end
