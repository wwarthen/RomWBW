;===============================================================================
; PORTSWP - Sweep Ports
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   PORTSWP
;
; Operation:
;   Reads all ports (multiple ways) and displays values read
;_______________________________________________________________________________
;
; Change Log:
;   2023-02-14 [WBW] Initial release
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
	call	crlf
	ld	a,($FFE0)	; get current hbios bank id
	ld	(orgbnk),a	; and save it
	ld	a,0		; start with port 0
	ld	(curport),a	; save it for use below
	; Test for z180 using mlt
	ld	de,$0506	; 5 x 6
	mlt	de		; de = 30 if z180
	ld	a,e		; result to A
	cp	30		; check if multiply happened
	jr	nz,loop		; if invalid, then Z80
	or	$FF		; flag value for Z180
	ld	(is180),a	; save it
;
loop:
	call	crlf
	ld	a,(curport)
	call	prthex
	ld	a,':'
	call	prtchr
;
	di			; interrupts off
;
	ld	hl,vallist	; init value list pointer
	call	portread	; read the port
	call	portread	; do it again
;
	; restore possibly corrupted bank registers
	ld	a,(orgbnk)	; get proper bank id
	call	$FFF3		; restore it
;
	ei			; interrupts safe now
;
	ld	hl,vallist	; re-init value list pointer
	ld	b,4		; print 4 values
prtloop:
	ld	a,' '
	call	prtchr
	ld	a,(hl)
	call	prthex
	inc	hl
	djnz	prtloop
;
	; update port and loop as needed
	ld	a,(curport)	; get current port
	inc	a		; move to next
	ld	(curport),a	; save it
	jr	z,done		; done on wraparound
	jr	loop		; loop until done
;
done:
;
	call	crlf2
	ld	de,msgdone	; message to print
	call	prtstr		; do it
;
	ret			; all done
;
;
;
portread:
	ld	a,(is180)
	or	a
	jr	nz,portread_z180
;
portread_z80:	; user traditional "IN"
	; read port using IN <portnum>
	ld	a,(curport)	; get current port
	ld	(port),a	; modify IN instruction
	in	a,($FF)		; read the port
port	.equ	$-1
	ld	(hl),a		; save it
	inc	hl		; bump value list pointer
;
	; read port using IN (C)
	ld	a,(curport)	; get current port
	ld	b,0		; in case 16 bits decoded
	ld	c,a		; move to reg C
	in	a,(c)		; read the port
	ld	(hl),a		; save it
	inc	hl		; bump value list pointer
	ret
;
portread_z180:	; use "IN0"
	; read port using IN <portnum>
	ld	a,(curport)	; get current port
	ld	(port1),a	; modify IN instruction
	in0	a,($FF)		; read the port
port1	.equ	$-1
	ld	(hl),a		; save it
	inc	hl		; bump value list pointer
;
	; read port using IN (C)
	ld	a,(curport)	; get current port
	ld	b,0		; in case 16 bits decoded
	ld	c,a		; move to reg C
	in	a,(c)		; read the port
	ld	(hl),a		; save it
	inc	hl		; bump value list pointer
	ret
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
; Short delay functions.  No clock speed compensation, so they
; will run longer on slower systems.  The number indicates the
; number of call/ret invocations.  a single call/ret is
; 27 t-states on a z80, 25 t-states on a z180
;
;			; Z80	Z180
;			; ----	----
dly64:	call	dly32	; 1728	1600
dly32:	call	dly16	; 864	800
dly16:	call	dly8	; 432	400
dly8:	call	dly4	; 216	200
dly4:	call	dly2	; 108	100
dly2:	call	dly1	; 54	50
dly1:	ret		; 27	25

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
is180	.db	0		; non-zero for z180
orgbnk	.db	0		; original bank id
curport	.db	0		; current port being processed
vallist .fill	8,0		; port values read
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Messages
;
msgban	.db	"PORTSWP v1.0, 14-Feb-2023",13,10
	.db	"Copyright (C) 2023, Wayne Warthen, GNU GPL v3",0
msguse	.db	"Usage: PORTSWP",13,10
msgprm	.db	"Parameter error (PORTSWP /? for usage)",0
msgbio	.db	"Incompatible BIOS or version, "
	.db	"HBIOS v", '0' + rmj, ".", '0' + rmn, " required",0
str_sep	.db	": ",0
;
;msgcur	.db	"Initial Bank ID = 0x",0
;msg80	.db	"Hello from bank 0x80!",0
;msgxcal	.db	"Inter-bank procedure call test...",0
msgdone	.db	"End of Port Sweep",0
;
;
;
size	.equ	$ - runloc
;
	.end
