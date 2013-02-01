;  modified 4/22/2011 for the N8VEM Home Computer Z180 -- John Coffman
;
;--------------------------------------------------------------------------
;  cpm22.s - CP/M-80 v2.2 for a Z80
;
;  Copyright (C) 2000, Michael Hope
;
;  This library is free software; you can redistribute it and/or modify it
;  under the terms of the GNU General Public License as published by the
;  Free Software Foundation; either version 2.1, or (at your option) any
;  later version.
;
;  This library is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License 
;  along with this library; see the file COPYING. If not, write to the
;  Free Software Foundation, 51 Franklin Street, Fifth Floor, Boston,
;   MA 02110-1301, USA.
;
;  As a special exception, if you link this library with other files,
;  some of which are compiled with SDCC, to produce an executable,
;  this library does not by itself cause the resulting executable to
;  be covered by the GNU General Public License. This exception does
;  not however invalidate any other reasons why the executable file
;   might be covered by the GNU General Public License.
;--------------------------------------------------------------------------

;;;        .module crt0
       	.globl	_main

	.area	_HEADER (ABS)
	;; Reset vector
	.org 	0
	jp	init

	.org	0x08
	ret
	.org	0x10
	ret
	.org	0x18
	ret
	.org	0x20
	ret
	.org	0x28
	ret
	.org	0x30
	ret
	.org	0x38
	ret
        .org    0x66    ; NMI interrupt
        retn

;;	.org	0x100
;;init:
;;	;; Stack at the top of memory.
;;	ld	sp,#0xffff
;;
;;        ;; Initialise global variables
;;        call    gsinit
;;	call	_main
;;	jp	_exit



;;	title	'Bdos Interface, Bdos, Version 2.2 Feb, 1980'
;;
;;	.Z80
;;	aseg

	org	100h

	maclib	MEMCFG.LIB	; define configuration parameters

;;	.phase	bdosph
;;bios	equ	biosph

;*****************************************************************
;*****************************************************************
;**                                                             **
;**   B a s i c    D i s k   O p e r a t i n g   S y s t e m    **
;**            I n t e r f a c e   M o d u l e                  **
;**                                                             **
;*****************************************************************
;*****************************************************************

;	Copyright (c) 1978, 1979, 1980
;	Digital Research
;	Box 579, Pacific Grove
;	California


;      20 january 1980

ssize	equ	24		;24 level stack

;	low memory locations

;;reboot	equ	0000h		;reboot system
reboot	=	0x0000

;;ioloc	equ	0003h		;i/o byte location
ioloc	=	0x0003

;;bdosa	equ	0006h		;address field of jp BDOS
bdosa	=	0x0006

;	bios access constants

bootf	defl	bios+3*0	;cold boot function

wbootf	defl	bios+3*1	;warm boot function

constf	defl	bios+3*2	;console status function

coninf	defl	bios+3*3	;console input function

conoutf	defl	bios+3*4	;console output function

listf	defl	bios+3*5	;list output function

punchf	defl	bios+3*6	;punch output function

readerf	defl	bios+3*7	;reader input function

homef	defl	bios+3*8	;disk home function

seldskf	defl	bios+3*9	;select disk function

settrkf	defl	bios+3*10	;set track function

setsecf	defl	bios+3*11	;set sector function

setdmaf	defl	bios+3*12	;set dma function

readf	defl	bios+3*13	;read disk function

writef	defl	bios+3*14	;write disk function

liststf	defl	bios+3*15	;list status function

sectran	defl	bios+3*16	;sector translate


;	equates for non graphic characters

;;ctlc	.equ	03h		;control c
ctlc	=	0x03

;;ctle	equ	05h		;physical eol
ctle	=	0x05

;;ctlh	equ	08h		;backspace
ctlh	=	0x08

;;ctlp	equ	10h		;prnt toggle
ctlp	=	0x10

;;ctlr	equ	12h		;repeat line
ctlr	=	0x12

;;ctls	equ	13h		;stop/start screen
ctls	=	0x13

;;ctlu	equ	15h		;line delete
ctlu	=	0x15

;;ctlx	equ	18h		;=ctl-u
ctlx	=	0x18

;;ctlz	equ	1ah		;end of file
ctlz	=	0x1a

;;rubout	equ	7fh		;char delete
rubout	=	0x7f

;;tab	equ	09h		;tab char
tab	=	0x09

;;cr	equ	0dh		;carriage return
cr	= 	0x0d

;;lf	equ	0ah		;line feed
lf	=	0x0a

;;ctl	equ	5eh		;up arrow
ctl	equ	0x5e

	.db	0,0,0,0,0,0

;	enter here from the user's program with function number in c,
;	and information address in d,e
	jp	bdose		;past parameter block

;	************************************************
;	*** relative locations 0009 - 000e           ***
;	************************************************
pererr:	.dw	persub		;permanent error subroutine
selerr:	.dw	selsub		;select error subroutine
roderr:	.dw	rodsub		;ro disk error subroutine
roferr:	.dw	rofsub		;ro file error subroutine


bdose:	ex	de,hl		;arrive here from user programs
	ld	(info),hl
	ex	de,hl		;info=DE, DE=info
	ld	a,e
	ld	(linfo),a	;linfo = low(info) - don't equ
	ld	hl,0
	ld	(aret),hl	;return value defaults to 0000
				;save user's stack pointer, set to local stack
	add	hl,sp
	ld	(entsp),hl	;entsp = stackptr
	ld	sp,lstack	;local stack setup
	xor	a
	ld	(fcbdsk),a
	ld	(resel),a	;fcbdsk,resel=false
	ld	hl,goback	;return here after all functions
	push	hl		;jmp goback equivalent to ret
	ld	a,c
	cp	nfuncs
	ret	nc		;skip if invalid #
	ld	c,e		;possible output character to C
	ld	hl,functab
	ld	e,a
	ld	d,0		;DE=func, HL=.ciotab
	add	hl,de
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;DE=functab(func)
	ld	hl,(info)	;info in DE for later xchg
	ex	de,hl
	jp	(hl)		;dispatched

;	dispatch table for functions
functab:
	.dw	wbootf, func1, func2, func3
	.dw	punchf, listf, func6, func7
	.dw	func8, func9, func10,func11

;;diskf	equ	($-functab)/2	;disk funcs
diskf	=	($-functab)/2	;disk funcs

	.dw	func12,func13,func14,func15
	.dw	func16,func17,func18,func19
	.dw	func20,func21,func22,func23
	.dw	func24,func25,func26,func27
	.dw	func28,func29,func30,func31
	.dw	func32,func33,func34,func35
	.dw	func36,func37,func38,func39
	.dw	func40

;;nfuncs	equ	($-functab)/2
nfuncs	=	($-functab)/2

;	error subroutines
persub:	ld	hl,permsg	;report permanent error
	call	errflg		;to report the error
	cp	ctlc
	jp	z,reboot	;reboot if response is ctlc
	ret			;and ignore the error

selsub:	ld	hl,selmsg	;report select error
	jp	wait$err	;wait console before boot

rodsub:	ld	hl,rodmsg	;report write to read/only disk
	jp	wait$err	;wait console

rofsub:				;report read/only file
	ld	hl,rofmsg	;drop through to wait for console

wait$err:			;wait for response before boot
	call	errflg
	jp	reboot

;	error messages

;;dskmsg:	db	'Bdos Err On '
dskmsg	.ascii	' : $'

;;dskerr:	db	' : $'		;filled in by errflg
dskerr	.ascii	' : $'

;;permsg:	db	'Bad Sector$'
permsg:	.ascii	'Bad Sector$'

;;selmsg:	db	'Select$'
selmsg:	.ascii	'Select$'

;;rofmsg:	db	'File '
rofmsg:	.asccii	'File '

;;rodmsg:	db	'R/O$'
rodmsg:	.ascii	'R/O$'


errflg:	push	hl		;report error to console, message address in HL
	call	crlf		;stack mssg address, new line
	ld	a,(curdsk)
	add	a,'A'
	ld	(dskerr),a	;current disk name
	ld	bc,dskmsg
	call	print		;the error message
	pop	bc
	call	print		;error mssage tail
;	jp	conin		;to get the input character
				;(drop through to conin)
;	ret


;	console handlers
conin:	ld	hl,kbchar	;read console character to A
	ld	a,(hl)
	ld	(hl),0
	or	a
	ret	nz
				;no previous keyboard character ready
	jp	coninf		;get character externally
;	ret
conech:	call	conin		;read character with echo
	call	echoc
	ret	c		;echo character?
				;character must be echoed before return
	push	af
	ld	c,a
	call	tabout
	pop	af
	ret			;with character in A

echoc:				;echo character if graphic
	cp	cr		;cr, lf, tab, or backspace
	ret	z		;carriage return?
	cp	lf
	ret	z		;line feed?
	cp	tab
	ret	z		;tab?
	cp	ctlh
	ret	z		;backspace?
	cp	' '
	ret			;carry set if not graphic

conbrk:				;check for character ready
	ld	a,(kbchar)
	or	a
	jp	nz,conb1	;skip if active kbchar
				;no active kbchar, check external break
	call	constf
	and	1
	ret	z		;return if no char ready
				;character ready, read it
	call	coninf		;to A
	cp	ctls
	jp	nz,conb0	;check stop screen function
				;found ctls, read next character
	call	coninf		;to A
	cp	ctlc
	jp	z,reboot	;ctlc implies re-boot
				;not a reboot, act as if nothing has happened
	xor	a
	ret			;with zero in accumulator
conb0:
				;character in accum, save it
	ld	(kbchar),a
conb1:
				;return with true set in accumulator
	ld	a,1
	ret

conout:				;compute character position/write console char from C
				;compcol = true if computing column position
	ld	a,(compcol)
	or	a
	jp	nz,compout
				;write the character, then compute the column
				;write console character from C
	push	bc
	call	conbrk		;check for screen stop function
	pop	bc
	push	bc		;recall/save character
	call	conoutf		;externally, to console
	pop	bc
	push	bc		;recall/save character
				;may be copying to the list device
	ld	a,(listcp)
	or	a
	call	nz,listf	;to printer, if so
	pop	bc		;recall the character
compout:
	ld	a,c		;recall the character
				;and compute column position
	ld	hl,column	;A = char, HL = .column
	cp	rubout
	ret	z		;no column change if nulls
	inc	(hl)		;column = column + 1
	cp	' '
	ret	nc		;return if graphic
				;not graphic, reset column position
	dec	(hl)		;column = column - 1
	ld	a,(hl)
	or	a
	ret	z		;return if at zero
				;not at zero, may be backspace or end line
	ld	a,c		;character back to A
	cp	ctlh
	jp	nz,notbacksp
				;backspace character
	dec	(hl)		;column = column - 1
	ret

notbacksp:			;not a backspace character, eol?
	cp	lf
	ret	nz		;return if not
				;end of line, column = 0
	ld	(hl),0		;column = 0
	ret

ctlout:				;send C character with possible preceding up-arrow
	ld	a,c
	call	echoc		;cy if not graphic (or special case)
	jp	nc,tabout	;skip if graphic, tab, cr, lf, or ctlh
				;send preceding up arrow
	push	af
	ld	c,ctl
	call	conout		;up arrow
	pop	af
	or	40h		;becomes graphic letter
	ld	c,a		;ready to print
				;(drop through to tabout)

tabout:				;expand tabs to console
	ld	a,c
	cp	tab
	jp	nz,conout	;direct to conout if not
				;tab encountered, move to next tab position
tab0:	ld	c,' '
	call	conout		;another blank
	ld	a,(column)
	and	111b		;column mod 8 = 0 ?
	jp	nz,tab0		;back for another if not
	ret

backup:				;back-up one screen position
	call	pctlh
	ld	c,' '
	call	conoutf
;	(drop through to pctlh)
pctlh:				;send ctlh to console without affecting column count
	ld	c,ctlh
	jp	conoutf
;	ret
crlfp:				;print #, cr, lf for ctlx, ctlu, ctlr functions
				;then move to strtcol (starting column)
	ld	c,'#'
	call	conout
	call	crlf		;column = 0, move to position strtcol
crlfp0:	ld	a,(column)
	ld	hl,strtcol
	cp	(hl)
	ret	nc		;stop when column reaches strtcol
	ld	c,' '
	call	conout		;print blank
	jp	crlfp0

crlf:	ld	c,cr		;carriage return line feed sequence
	call	conout
	ld	c,lf
	jp	conout
;	ret
print:	ld	a,(bc)		;print message until M(BC) = '$'
	cp	'$'
	ret	z		;stop on $
				;more to print
	inc	bc
	push	bc
	ld	c,a		;char to C
	call	tabout		;another character printed
	pop	bc
	jp	print

read:				;read to info address (max length, current length, buffer)
	ld	a,(column)
	ld	(strtcol),a	;save start for ctl-x, ctl-h
	ld	hl,(info)
	ld	c,(hl)
	inc	hl
	push	hl
	ld	b,0
				;B = current buffer length,
				;C = maximum buffer length,
				;HL= next to fill - 1
readnx:				;read next character, BC, HL active
	push	bc
	push	hl		;blen, cmax, HL saved
readn0:	call	conin		;next char in A
	and	7fh		;mask parity bit
	pop	hl
	pop	bc		;reactivate counters
	cp	cr
	jp	z,readen	;end of line?
	cp	lf
	jp	z,readen	;also end of line
	cp	ctlh
	jp	nz,noth		;backspace?
				;do we have any characters to back over?
	ld	a,b
	or	a
	jp	z,readnx
				;characters remain in buffer, backup one
	dec	b		;remove one character
	ld	a,(column)
	ld	(compcol),a	;col > 0
				;compcol > 0 marks repeat as length compute
	jp	linelen		;uses same code as repeat

noth:				;not a backspace
	cp	rubout
	jp	nz,notrub	;rubout char?
				;rubout encountered, rubout if possible
	ld	a,b
	or	a
	jp	z,readnx	;skip if len=0
				;buffer has characters, resend last char
	ld	a,(hl)
	dec	b
	dec	hl		;A = last char
				;blen=blen-1, next to fill - 1 decremented
	jp	rdech1		;act like this is an echo

notrub:				;not a rubout character, check end line
	cp	ctle
	jp	nz,note		;physical end line?
				;yes, save active counters and force eol
	push	bc
	push	hl
	call	crlf
	xor	a
	ld	(strtcol),a	;start position = 00
	jp	readn0		;for another character

note:				;not end of line, list toggle?
	cp	ctlp
	jp	nz,notp		;skip if not ctlp
				;list toggle - change parity
	push	hl		;save next to fill - 1
	ld	hl,listcp	;HL=.listcp flag
	ld	a,1
	sub	(hl)		;True-listcp
	ld	(hl),a		;listcp = not listcp
	pop	hl
	jp	readnx		;for another char

notp:				;not a ctlp, line delete?
	cp	ctlx
	jp	nz,notx
	pop	hl		;discard start position
				;loop while column > strtcol
backx:	ld	a,(strtcol)
	ld	hl,column
	cp	(hl)
	jp	nc,read		;start again
	dec	(hl)		;column = column - 1
	call	backup		;one position
	jp	backx

notx:				;not a control x, control u?
				;not control-X, control-U?
	cp	ctlu
	jp	nz,notu		;skip if not
				;delete line (ctlu)
	call	crlfp		;physical eol
	pop	hl		;discard starting position
	jp	read		;to start all over

notu:				;not line delete, repeat line?
	cp	ctlr
	jp	nz,notr
linelen:			;repeat line, or compute line len (ctlh)
				;if compcol > 0
	push	bc
	call	crlfp		;save line length
	pop	bc
	pop	hl
	push	hl
	push	bc
				;bcur, cmax active, beginning buff at HL
rep0:	ld	a,b
	or	a
	jp	z,rep1		;count len to 00
	inc	hl
	ld	c,(hl)		;next to print
	dec	b
	push	bc
	push	hl		;count length down
	call	ctlout		;character echoed
	pop	hl
	pop	bc		;recall remaining count
	jp	rep0		;for the next character

rep1:				;end of repeat, recall lengths
				;original BC still remains pushed
	push	hl		;save next to fill
	ld	a,(compcol)
	or	a		;>0 if computing length
	jp	z,readn0	;for another char if so
				;column position computed for ctlh
	ld	hl,column
	sub	(hl)		;diff > 0
	ld	(compcol),a	;count down below
				;move back compcol-column spaces
backsp:				;move back one more space
	call	backup		;one space
	ld	hl,compcol
	dec	(hl)
	jp	nz,backsp
	jp	readn0		;for next character

notr:				;not a ctlr, place into buffer
rdecho:	inc	hl
	ld	(hl),a		;character filled to mem
	inc	b		;blen = blen + 1
rdech1:				;look for a random control character
	push	bc
	push	hl		;active values saved
	ld	c,a		;ready to print
	call	ctlout		;may be up-arrow C
	pop	hl
	pop	bc
	ld	a,(hl)		;recall char
	cp	ctlc		;set flags for reboot test
	ld	a,b		;move length to A
	jp	nz,notc		;skip if not a control c
	cp	1		;control C, must be length 1
	jp	z,reboot	;reboot if blen = 1
				;length not one, so skip reboot
notc:				;not reboot, are we at end of buffer?
	cp	c
	jp	c,readnx	;go for another if not
readen:				;end of read operation, store blen
	pop	hl
	ld	(hl),b		;M(current len) = B
	ld	c,cr
	jp	conout		;return carriage
;	ret
func1:				;return console character with echo
	call	conech
	jp	sta$ret

func2	equ	tabout
				;write console character with tab expansion

func3:				;return reader character
	call	readerf
	jp	sta$ret

;func4:	equated to punchf
				;write punch character

;func5:	equated to listf
				;write list character
				;write to list device

func6:				;direct console i/o - read if 0ffh
	ld	a,c
	inc	a
	jp	z,dirinp	;0ffh => 00h, means input mode
	inc	a
	jp	z,constf	;0feH in C for status
				;direct output function
	jp	conoutf

dirinp:	call	constf		;status check
	or	a
	jp	z,retmon	;skip, return 00 if not ready
				;character is ready, get it
	call	coninf		;to A
	jp	sta$ret

func7:				;return io byte
	ld	a,(ioloc)
	jp	sta$ret

func8:				;set i/o byte
	ld	hl,ioloc
	ld	(hl),c
	ret			;jmp goback

func9:				;write line until $ encountered
	ex	de,hl		;was lhld info
	ld	c,l
	ld	b,h		;BC=string address
	jp	print		;out to console

func10	equ	read
				;read a buffered console line

func11:				;check console status
	call	conbrk
				;(drop through to sta$ret)
sta$ret:			;store the A register to aret
	ld	(aret),a
func$ret:
	ret			;jmp goback (pop stack for non cp/m functions)

setlret1:			;set lret = 1
	ld	a,1
	jp	sta$ret



;	data areas

compcol:
	.db	0		;true if computing column position

strtcol:
	.db	0		;starting column position after read

column:	.db	0		;column position
listcp:	.db	0		;listing toggle
kbchar:	.db	0		;initial key char = 00
entsp:	.ds	2		;entry stack pointer
	.ds	ssize*2		;stack size

lstack:

;	end of Basic I/O System

;*****************************************************************
;*****************************************************************

;	common values shared between bdosi and bdos
usrcode:
	.db	0		;current user number
curdsk:	.db	0		;current disk number
info:	.ds	2		;information address
aret:	.ds	2		;address value to return
lret	.equ	aret		;low(aret)

;*****************************************************************
;*****************************************************************
;**                                                             **
;**   B a s i c    D i s k   O p e r a t i n g   S y s t e m    **
;**                                                             **
;*****************************************************************
;*****************************************************************

;;dvers	equ	22h		;version 2.2
dvers	=	0x22

;	module addresses

;	literal constants

;;true	equ	0ffh		;constant true
true	=	0xff

;;false	equ	000h		;constant false
false	=	0x00

;;enddir	equ	0ffffh		;end of directory
enddir	=	0xffff

;;byte	equ	1		;number of bytes for "byte" type
byte	=	1

;;word	equ	2		;number of bytes for "word" type
word	=	2

;	fixed addresses in low memory

;;tfcb	equ	005ch		;default fcb location
tfcb	=	0x5c

;;tbuff	equ	0080h		;default buffer location
tbuff	=	0x80

;	fixed addresses referenced in bios module are
;	pererr (0009), selerr (000c), roderr (000f)

;	error message handlers

;per$error:			;report permanent error to user
;	ld	hl,pererr
;	jp	goerr

;rod$error:			;report read/only disk error
;	ld	hl,roderr
;	jp	goerr

;rof$error:			;report read/only file error
;	ld	hl,roferr
;	jp	goerr

sel$error:			;report select error
	ld	hl,selerr


goerr:				;HL = .errorhandler, call subroutine
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;address of routine in DE
	ex	de,hl
	jp	(hl)		;to subroutine



;	local subroutines for bios interface

move:				;move data length of length C from source DE to
				;destination given by HL
	inc	c		;in case it is zero
move0:	dec	c
	ret	z		;more to move
	ld	a,(de)
	ld	(hl),a		;one byte moved
	inc	de
	inc	hl		;to next byte
	jp	move0

selectdisk:			;select the disk drive given by curdsk, and fill
				;the base addresses curtrka - alloca, then fill
				;the values of the disk parameter block
	ld	a,(curdsk)
	ld	c,a		;current disk# to c
				;lsb of e = 0 if not yet logged - in
	call	seldskf		;HL filled by call
				;HL = 0000 if error, otherwise disk headers
	ld	a,h
	or	l
	ret	z		;return with 0000 in HL and z flag
				;disk header block address in hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl		;DE=.tran
	ld	(cdrmaxa),hl
	inc	hl
	inc	hl		;.cdrmax
	ld	(curtrka),hl
	inc	hl
	inc	hl		;HL=.currec
	ld	(curreca),hl
	inc	hl
	inc	hl		;HL=.buffa
				;DE still contains .tran
	ex	de,hl
	ld	(tranv),hl	;.tran vector
	ld	hl,buffa	;DE= source for move, HL=dest
	ld	c,addlist
	call	move		;addlist filled
				;now fill the disk parameter block
	ld	hl,(dpbaddr)
	ex	de,hl		;DE is source
	ld	hl,sectpt	;HL is destination
	ld	c,dpblist
	call	move		;data filled
				;now set single/double map mode
	ld	hl,(maxall)	;largest allocation number
	ld	a,h		;00 indicates < 255
	ld	hl,single
	ld	(hl),true	;assume a=00
	or	a
	jp	z,retselect
				;high order of maxall not zero, use double dm
	ld	(hl),false
retselect:
	ld	a,true
	or	a
	ret			;select disk function ok

home:				;move to home position, then offset to start of dir
	call	homef		;move to track 00, sector 00 reference
				;lxi h,offset ;mov c,m ;inx h ;mov b,m ;call settrkf
				;first directory position selected
	xor	a		;constant zero to accumulator
	ld	hl,(curtrka)
	ld	(hl),a
	inc	hl
	ld	(hl),a		;curtrk=0000
	ld	hl,(curreca)
	ld	(hl),a
	inc	hl
	ld	(hl),a		;currec=0000
				;curtrk, currec both set to 0000
	ret

rdbuff:				;read buffer and check condition
	call	readf		;current drive, track, sector, dma
	jp	diocomp		;check for i/o errors

wrbuff:				;write buffer and check condition
				;write type (wrtype) is in register C
				;wrtype = 0 => normal write operation
				;wrtype = 1 => directory write operation
				;wrtype = 2 => start of new block
	call	writef		;current drive, track, sector, dma
diocomp:			;check for disk errors
	or	a
	ret	z
	ld	hl,pererr
	jp	goerr

seek$dir:			;seek the record containing the current dir entry
	ld	hl,(dcnt)	;directory counter to HL
	ld	c,dskshf
	call	hlrotr		;value to HL
	ld	(arecord),hl
	ld	(drec),hl	;ready for seek
;	jp	seek
;	ret


seek:				;seek the track given by arecord (actual record)
				;local equates for registers
				;load the registers from memory
	ld	hl,arecord
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	ld	hl,(curreca)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	hl,(curtrka)
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
				;loop while arecord < currec
seek0:	ld	a,c
	sub	e
	ld	a,b
	sbc	a,d
	jp	nc,seek1	;skip if arecord >= currec
				;currec = currec - sectpt
	push	hl
	ld	hl,(sectpt)
	ld	a,e
	sub	l
	ld	e,a
	ld	a,d
	sbc	a,h
	ld	d,a
	pop	hl
				;curtrk = curtrk - 1
	dec	hl
	jp	seek0		;for another try

seek1:				;look while arecord >= (t:=currec + sectpt)
	push	hl
	ld	hl,(sectpt)
	add	hl,de		;HL = currec+sectpt
	jp	c,seek2		;can be > FFFFH
	ld	a,c
	sub	l
	ld	a,b
	sbc	a,h
	jp	c,seek2		;skip if t > arecord
				;currec = t
	ex	de,hl
				;curtrk = curtrk + 1
	pop	hl
	inc	hl
	jp	seek1		;for another try

seek2:	pop	hl
				;arrive here with updated values in each register
	push	bc
	push	de
	push	hl		;to stack for later
				;stack contains (lowest) BC=arecord, DE=currec, HL=curtrk
	ex	de,hl
	ld	hl,(offset)
	add	hl,de		;HL = curtrk+offset
	ld	b,h
	ld	c,l
	call	settrkf		;track set up
				;note that BC - curtrk is difference to move in bios
	pop	de		;recall curtrk
	ld	hl,(curtrka)
	ld	(hl),e
	inc	hl
	ld	(hl),d		;curtrk updated
				;now compute sector as arecord-currec
	pop	de		;recall currec
	ld	hl,(curreca)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	pop	bc		;BC=arecord, DE=currec
	ld	a,c
	sub	e
	ld	c,a
	ld	a,b
	sbc	a,d
	ld	b,a
	ld	hl,(tranv)
	ex	de,hl		;BC=sector#, DE=.tran
	call	sectran		;HL = tran(sector)
	ld	c,l
	ld	b,h		;BC = tran(sector)
	jp	setsecf		;sector selected
;	ret

;	file control block (fcb) constants
empty	equ	0e5h		;empty directory entry
lstrec	equ	127		;last record# in extent
recsiz	equ	128		;record size
fcblen	equ	32		;file control block size
dirrec	equ	recsiz/fcblen	;directory elts / record
dskshf	equ	2		;log2(dirrec)
dskmsk	equ	dirrec-1
fcbshf	equ	5		;log2(fcblen)

extnum	equ	12		;extent number field
maxext	equ	31		;largest extent number
ubytes	equ	13		;unfilled bytes field
modnum	equ	14		;data module number
maxmod	equ	15		;largest module number
fwfmsk	equ	80h		;file write flag is high order modnum
namlen	equ	15		;name length
reccnt	equ	15		;record count field
dskmap	equ	16		;disk map field
lstfcb	equ	fcblen-1
nxtrec	equ	fcblen
ranrec	equ	nxtrec+1	;random record field (2 bytes)

;	reserved file indicators
rofile	equ	9		;high order of first type char
invis	equ	10		;invisible file in dir command
;	equ	11		;reserved

;	utility functions for file access

dm$position:			;compute disk map position for vrecord to HL
	ld	hl,blkshf
	ld	c,(hl)		;shift count to C
	ld	a,(vrecord)	;current virtual record to A
dmpos0:	or	a
	rra
	dec	c
	jp	nz,dmpos0
				;A = shr(vrecord,blkshf) = vrecord/2**(sect/block)
	ld	b,a		;save it for later addition
	ld	a,8
	sub	(hl)		;8-blkshf to accumulator
	ld	c,a		;extent shift count in register c
	ld	a,(extval)	;extent value ani extmsk
dmpos1:
				;blkshf = 3,4,5,6,7, C=5,4,3,2,1
				;shift is 4,3,2,1,0
	dec	c
	jp	z,dmpos2
	or	a
	rla
	jp	dmpos1

dmpos2:				;arrive here with A = shl(ext and extmsk,7-blkshf)
	add	a,b		;add the previous shr(vrecord,blkshf) value
				;A is one of the following values, depending upon alloc
				;bks blkshf
				;1k   3     v/8 + extval * 16
				;2k   4     v/16+ extval * 8
				;4k   5     v/32+ extval * 4
				;8k   6     v/64+ extval * 2
				;16k  7     v/128+extval * 1
	ret			;with dm$position in A

getdm:				;return disk map value from position given by BC
	ld	hl,(info)	;base address of file control block
	ld	de,dskmap
	add	hl,de		;HL =.diskmap
	add	hl,bc		;index by a single byte value
	ld	a,(single)	;single byte/map entry?
	or	a
	jp	z,getdmd	;get disk map single byte
	ld	l,(hl)
	ld	h,0
	ret			;with HL=00bb
getdmd:
	add	hl,bc		;HL=.fcb(dm+i*2)
				;double precision value returned
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	ret

index:				;compute disk block number from current fcb
	call	dm$position	;0...15 in register A
	ld	c,a
	ld	b,0
	call	getdm		;value to HL
	ld	(arecord),hl
	ret

allocated:			;called following index to see if block allocated
	ld	hl,(arecord)
	ld	a,l
	or	h
	ret

atran:				;compute actual record address, assuming index called
	ld	a,(blkshf)	;shift count to reg A
	ld	hl,(arecord)
atran0:	add	hl,hl
	dec	a
	jp	nz,atran0	;shl(arecord,blkshf)
	ld	(arecord1),hl	;save shifted block #
	ld	a,(blkmsk)
	ld	c,a		;mask value to C
	ld	a,(vrecord)
	and	c		;masked value in A
	or	l
	ld	l,a		;to HL
	ld	(arecord),hl	;arecord=HL or (vrecord and blkmsk)
	ret

getexta:			;get current extent field address to A
	ld	hl,(info)
	ld	de,extnum
	add	hl,de		;HL=.fcb(extnum)
	ret

getfcba:			;compute reccnt and nxtrec addresses for get/setfcb
	ld	hl,(info)
	ld	de,reccnt
	add	hl,de
	ex	de,hl		;DE=.fcb(reccnt)
	ld	hl,nxtrec-reccnt
	add	hl,de		;HL=.fcb(nxtrec)
	ret

getfcb:				;set variables from currently addressed fcb
	call	getfcba		;addresses in DE, HL
	ld	a,(hl)
	ld	(vrecord),a	;vrecord=fcb(nxtrec)
	ex	de,hl
	ld	a,(hl)
	ld	(rcount),a	;rcount=fcb(reccnt)
	call	getexta		;HL=.fcb(extnum)
	ld	a,(extmsk)	;extent mask to a
	and	(hl)		;fcb(extnum) and extmsk
	ld	(extval),a
	ret

setfcb:				;place values back into current fcb
	call	getfcba		;addresses to DE, HL
	ld	a,(seqio)
	cp	02
	jp	nz,setfcb1
	xor	a		;check ranfill
setfcb1:
	ld	c,a		;=1 if sequential i/o
	ld	a,(vrecord)
	add	a,c
	ld	(hl),a		;fcb(nxtrec)=vrecord+seqio
	ex	de,hl
	ld	a,(rcount)
	ld	(hl),a		;fcb(reccnt)=rcount
	ret

hlrotr:				;hl rotate right by amount C
	inc	c		;in case zero
hlrotr0:
	dec	c
	ret	z		;return when zero
	ld	a,h
	or	a
	rra
	ld	h,a		;high byte
	ld	a,l
	rra
	ld	l,a		;low byte
	jp	hlrotr0

compute$cs:			;compute checksum for current directory buffer
	ld	c,recsiz	;size of directory buffer
	ld	hl,(buffa)	;current directory buffer
	xor	a		;clear checksum value
computecs0:
	add	a,(hl)
	inc	hl
	dec	c		;cs=cs+buff(recsiz-C)
	jp	nz,computecs0
	ret			;with checksum in A

hlrotl:				;rotate the mask in HL by amount in C
	inc	c		;may be zero
hlrotl0:
	dec	c
	ret	z		;return if zero
	add	hl,hl
	jp	hlrotl0

set$cdisk:			;set a "1" value in curdsk position of BC
	push	bc		;save input parameter
	ld	a,(curdsk)
	ld	c,a		;ready parameter for shift
	ld	hl,1		;number to shift
	call	hlrotl		;HL = mask to integrate
	pop	bc		;original mask
	ld	a,c
	or	l
	ld	l,a
	ld	a,b
	or	h
	ld	h,a		;HL = mask or rol(1,curdsk)
	ret

nowrite:			;return true if dir checksum difference occurred
	ld	hl,(rodsk)
	ld	a,(curdsk)
	ld	c,a
	call	hlrotr
	ld	a,l
	and	1b
	ret			;non zero if nowrite

set$ro:				;set current disk to read only
	ld	hl,rodsk
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	call	set$cdisk	;sets bit to 1
	ld	(rodsk),hl
				;high water mark in directory goes to max
	ld	hl,(dirmax)
	inc	hl
	ex	de,hl		;DE = directory max
	ld	hl,(cdrmaxa)	;HL = .cdrmax
	ld	(hl),e
	inc	hl
	ld	(hl),d		;cdrmax = dirmax
	ret

check$rodir:			;check current directory element for read/only status
	call	getdptra	;address of element

check$rofile:			;check current buff(dptr) or fcb(0) for r/o status
	ld	de,rofile
	add	hl,de		;offset to ro bit
	ld	a,(hl)
	rla
	ret	nc		;return if not set
	ld	hl,roferr
	jp	goerr
;	jp	rof$error 	;exit to read only disk message


check$write:			;check for write protected disk
	call	nowrite
	ret	z		;ok to write if not rodsk
	ld	hl,roderr
	jp	goerr
;	jp	rod$error	;read only disk error

getdptra:			;compute the address of a directory element at
				;positon dptr in the buffer
	ld	hl,(buffa)
	ld	a,(dptr)
addh:				;HL = HL + A
	add	a,l
	ld	l,a
	ret	nc
				;overflow to H
	inc	h
	ret


getmodnum:			;compute the address of the module number
				;bring module number to accumulator
				;(high order bit is fwf (file write flag)
	ld	hl,(info)
	ld	de,modnum
	add	hl,de		;HL=.fcb(modnum)
	ld	a,(hl)
	ret			;A=fcb(modnum)

clrmodnum:			;clear the module number field for user open/make
	call	getmodnum
	ld	(hl),0		;fcb(modnum)=0
	ret

setfwf:	call	getmodnum	;HL=.fcb(modnum), A=fcb(modnum)
				;set fwf (file write flag) to "1"
	or	fwfmsk
	ld	(hl),a		;fcb(modnum)=fcb(modnum) or 80h
				;also returns non zero in accumulator
	ret


compcdr:			;return cy if cdrmax > dcnt
	ld	hl,(dcnt)
	ex	de,hl		;DE = directory counter
	ld	hl,(cdrmaxa)	;HL=.cdrmax
	ld	a,e
	sub	(hl)		;low(dcnt) - low(cdrmax)
	inc	hl		;HL = .cdrmax+1
	ld	a,d
	sbc	a,(hl)		;hig(dcnt) - hig(cdrmax)
				;condition dcnt - cdrmax  produces cy if cdrmax>dcnt
	ret

setcdr:				;if not (cdrmax > dcnt) then cdrmax = dcnt+1
	call	compcdr
	ret	c		;return if cdrmax > dcnt
				;otherwise, HL = .cdrmax+1, DE = dcnt
	inc	de
	ld	(hl),d
	dec	hl
	ld	(hl),e
	ret

subdh:				;compute HL = DE - HL
	ld	a,e
	sub	l
	ld	l,a
	ld	a,d
	sbc	a,h
	ld	h,a
	ret

newchecksum:
	ld	c,true		;drop through to compute new checksum
checksum:			;compute current checksum record and update the
				;directory element if C=true, or check for = if not
				;drec < chksiz?
	ld	hl,(drec)
	ex	de,hl
	ld	hl,(chksiz)
	call	subdh		;DE-HL
	ret	nc		;skip checksum if past checksum vector size
				;drec < chksiz, so continue
	push	bc		;save init flag
	call	compute$cs	;check sum value to A
	ld	hl,(checka)	;address of check sum vector
	ex	de,hl
	ld	hl,(drec)	;value of drec
	add	hl,de		;HL = .check(drec)
	pop	bc		;recall true=0ffh or false=00 to C
	inc	c		;0ffh produces zero flag
	jp	z,initial$cs
				;not initializing, compare
	cp	(hl)		;compute$cs=check(drec)?
	ret	z		;no message if ok
				;checksum error, are we beyond
				;the end of the disk?
	call	compcdr
	ret	nc		;no message if so
	call	set$ro		;read/only disk set
	ret

initial$cs:			;initializing the checksum
	ld	(hl),a
	ret


wrdir:				;write the current directory entry, set checksum
	call	newchecksum	;initialize entry
	call	setdir		;directory dma
	ld	c,1		;indicates a write directory operation
	call	wrbuff		;write the buffer
	jp	setdata		;to data dma address
;	ret
rd$dir:				;read a directory entry into the directory buffer
	call	setdir		;directory dma
	call	rdbuff		;directory record loaded
				;jmp setdata to data dma address
;	ret
setdata:			;set data dma address
	ld	hl,dmaad
	jp	setdma		;to complete the call

setdir:				;set directory dma address
	ld	hl,buffa	;jmp setdma to complete call

setdma:				;HL=.dma address to set (i.e., buffa or dmaad)
	ld	c,(hl)
	inc	hl
	ld	b,(hl)		;parameter ready
	jp	setdmaf

dir$to$user:			;copy the directory entry to the user buffer
				;after call to search or searchn by user code
	ld	hl,(buffa)
	ex	de,hl		;source is directory buffer
	ld	hl,(dmaad)	;destination is user dma address
	ld	c,recsiz	;copy entire record
	jp	move
;	ret

end$of$dir:			;return zero flag if at end of directory, non zero
				;if not at end (end of dir if dcnt = 0ffffh)
	ld	hl,dcnt
	ld	a,(hl)		;may be 0ffh
	inc	hl
	cp	(hl)		;low(dcnt) = high(dcnt)?
	ret	nz		;non zero returned if different
				;high and low the same, = 0ffh?
	inc	a		;0ffh becomes 00 if so
	ret

set$end$dir:			;set dcnt to the end of the directory
	ld	hl,enddir
	ld	(dcnt),hl
	ret

read$dir:			;read next directory entry, with C=true if initializing
	ld	hl,(dirmax)
	ex	de,hl		;in preparation for subtract
	ld	hl,(dcnt)
	inc	hl
	ld	(dcnt),hl	;dcnt=dcnt+1
				;continue while dirmax >= dcnt (dirmax-dcnt no cy)
	call	subdh		;DE-HL
	jp	nc,read$dir0
				;yes, set dcnt to end of directory
	jp	set$end$dir
;	ret

read$dir0:			;not at end of directory, seek next element
				;initialization flag is in C
	ld	a,(dcnt)
	and	dskmsk		;low(dcnt) and dskmsk
	ld	b,fcbshf	;to multiply by fcb size
read$dir1:
	add	a,a
	dec	b
	jp	nz,read$dir1
				;A = (low(dcnt) and dskmsk) shl fcbshf
	ld	(dptr),a	;ready for next dir operation
	or	a
	ret	nz		;return if not a new record
	push	bc		;save initialization flag C
	call	seek$dir	;seek proper record
	call	rd$dir		;read the directory record
	pop	bc		;recall initialization flag
	jp	checksum	;checksum the directory elt
;	ret


getallocbit:			;given allocation vector position BC, return with byte
				;containing BC shifted so that the least significant
				;bit is in the low order accumulator position.  HL is
				;the address of the byte for possible replacement in
				;memory upon return, and D contains the number of shifts
				;required to place the returned value back into position
	ld	a,c

;;	and	111b
	and	0b00000111

	inc	a
	ld	e,a
	ld	d,a
				;d and e both contain the number of bit positions to shift
	ld	a,c
	rrca
	rrca
	rrca

;	and	11111b
	and	0b00011111

	ld	c,a		;C shr 3 to C
	ld	a,b
	add	a,a
	add	a,a
	add	a,a
	add	a,a
	add	a,a		;B shl 5
	or	c
	ld	c,a		;bbbccccc to C
	ld	a,b
	rrca
	rrca
	rrca

;;	and	11111b
	and	0b00011111

	ld	b,a		;BC shr 3 to BC
	ld	hl,(alloca)	;base address of allocation vector
	add	hl,bc
	ld	a,(hl)		;byte to A, hl = .alloc(BC shr 3)
				;now move the bit to the low order position of A
rotl:	rlca
	dec	e
	jp	nz,rotl
	ret


set$alloc$bit:			;BC is the bit position of ALLOC to set or reset.  The
				;value of the bit is in register E.
	push	de
	call	getallocbit	;shifted val A, count in D

;;	and	11111110b	;mask low bit to zero (may be set)
	and	0b11111110

	or	c		;low bit of C is masked into A
;	jp	rotr 		;to rotate back into proper position
;	ret
rotr:
				;byte value from ALLOC is in register A, with shift count
				;in register C (to place bit back into position), and
				;target ALLOC position in registers HL, rotate and replace
	rrca
	dec	d
	jp	nz,rotr		;back into position
	ld	(hl),a		;back to ALLOC
	ret

scandm:				;scan the disk map addressed by dptr for non-zero
				;entries, the allocation vector entry corresponding
				;to a non-zero entry is set to the value of C (0,1)
	call	getdptra	;HL = buffa + dptr
				;HL addresses the beginning of the directory entry
	ld	de,dskmap
	add	hl,de		;hl now addresses the disk map
	push	bc		;save the 0/1 bit to set
	ld	c,fcblen-dskmap+1;size of single byte disk map + 1
scandm0:			;loop once for each disk map entry
	pop	de		;recall bit parity
	dec	c
	ret	z		;all done scanning?
				;no, get next entry for scan
	push	de		;replace bit parity
	ld	a,(single)
	or	a
	jp	z,scandm1
				;single byte scan operation
	push	bc		;save counter
	push	hl		;save map address
	ld	c,(hl)
	ld	b,0		;BC=block#
	jp	scandm2

scandm1:			;double byte scan operation
	dec	c		;count for double byte
	push	bc		;save counter
	ld	c,(hl)
	inc	hl
	ld	b,(hl)		;BC=block#
	push	hl		;save map address
scandm2:			;arrive here with BC=block#, E=0/1
	ld	a,c
	or	b		;skip if = 0000
	jp	z,scanm3
	ld	hl,(maxall)	;check invalid index
	ld	a,l
	sub	c
	ld	a,h
	sbc	a,b		;maxall - block#
	call	nc,set$alloc$bit
				;bit set to 0/1
scanm3:	pop	hl
	inc	hl		;to next bit position
	pop	bc		;recall counter
	jp	scandm0		;for another item

initialize:			;initialize the current disk
				;lret = false ;set to true if $ file exists
				;compute the length of the allocation vector - 2
	ld	hl,(maxall)
	ld	c,3		;perform maxall/8
				;number of bytes in alloc vector is (maxall/8)+1
	call	hlrotr
	inc	hl		;HL = maxall/8+1
	ld	b,h
	ld	c,l		;count down BC til zero
	ld	hl,(alloca)	;base of allocation vector
				;fill the allocation vector with zeros
initial0:
	ld	(hl),0
	inc	hl		;alloc(i)=0
	dec	bc		;count length down
	ld	a,b
	or	c
	jp	nz,initial0
				;set the reserved space for the directory
	ld	hl,(dirblk)
	ex	de,hl
	ld	hl,(alloca)	;HL=.alloc()
	ld	(hl),e
	inc	hl
	ld	(hl),d		;sets reserved directory blks
				;allocation vector initialized, home disk
	call	home
				;cdrmax = 3 (scans at least one directory record)
	ld	hl,(cdrmaxa)
	ld	(hl),3
	inc	hl
	ld	(hl),0
				;cdrmax = 0000
	call	set$end$dir	;dcnt = enddir
				;read directory entries and check for allocated storage
initial2:
	ld	c,true
	call	read$dir
	call	end$of$dir
	ret	z		;return if end of directory
				;not end of directory, valid entry?
	call	getdptra	;HL = buffa + dptr
	ld	a,empty
	cp	(hl)
	jp	z,initial2	;go get another item
				;not empty, user code the same?
	ld	a,(usrcode)
	cp	(hl)
	jp	nz,pdollar
				;same user code, check for '$' submit
	inc	hl
	ld	a,(hl)		;first character
	sub	'$'		;dollar file?
	jp	nz,pdollar
				;dollar file found, mark in lret
	dec	a
	ld	(lret),a	;lret = 255
pdollar:			;now scan the disk map for allocated blocks
	ld	c,1		;set to allocated
	call	scandm
	call	setcdr		;set cdrmax to dcnt
	jp	initial2	;for another entry

copy$dirloc:			;copy directory location to lret following
				;delete, rename, ... ops
	ld	a,(dirloc)
	jp	sta$ret
;	ret

compext:			;compare extent# in A with that in C, return nonzero
				;if they do not match
	push	bc		;save C's original value
	push	af
	ld	a,(extmsk)
	cpl
	ld	b,a
				;B has negated form of extent mask
	ld	a,c
	and	b
	ld	c,a		;low bits removed from C
	pop	af
	and	b		;low bits removed from A
	sub	c
	and	maxext		;set flags
	pop	bc		;restore original values
	ret

search:				;search for directory element of length C at info

;;	ld	a,0ffh
	ld	a,0xff

	ld	(dirloc),a	;changed if actually found
	ld	hl,searchl
	ld	(hl),c		;searchl = C
	ld	hl,(info)
	ld	(searcha),hl	;searcha = info
	call	set$end$dir	;dcnt = enddir
	call	home		;to start at the beginning
				;(drop through to searchn)

searchn:			;search for the next directory element, assuming
				;a previous call on search which sets searcha and
				;searchl
	ld	c,false
	call	read$dir	;read next dir element
	call	end$of$dir
	jp	z,search$fin	;skip to end if so
				;not end of directory, scan for match
	ld	hl,(searcha)
	ex	de,hl		;DE=beginning of user fcb
	ld	a,(de)		;first character
	cp	empty		;keep scanning if empty
	jp	z,searchnext
				;not empty, may be end of logical directory
	push	de		;save search address
	call	compcdr		;past logical end?
	pop	de		;recall address
	jp	nc,search$fin	;artificial stop
searchnext:
	call	getdptra	;HL = buffa+dptr
	ld	a,(searchl)
	ld	c,a		;length of search to c
	ld	b,0		;b counts up, c counts down
searchloop:
	ld	a,c
	or	a
	jp	z,endsearch
	ld	a,(de)
	cp	'?'
	jp	z,searchok	;? matches all
				;scan next character if not ubytes
	ld	a,b
	cp	ubytes
	jp	z,searchok
				;not the ubytes field, extent field?
	cp	extnum		;may be extent field
	ld	a,(de)		;fcb character
	jp	z,searchext	;skip to search extent
	sub	(hl)
	and	7fh		;mask-out flags/extent modulus
	jp	nz,searchn	;skip if not matched
	jp	searchok	;matched character

searchext:			;A has fcb character
				;attempt an extent # match
	push	bc		;save counters
	ld	c,(hl)		;directory character to c
	call	compext		;compare user/dir char
	pop	bc		;recall counters
	jp	nz,searchn	;skip if no match
searchok:			;current character matches
	inc	de
	inc	hl
	inc	b
	dec	c
	jp	searchloop

endsearch:			;entire name matches, return dir position
	ld	a,(dcnt)
	and	dskmsk
	ld	(lret),a
				;lret = low(dcnt) and 11b
	ld	hl,dirloc
	ld	a,(hl)
	rla
	ret	nc		;dirloc=0ffh?
				;yes, change it to 0 to mark as found
	xor	a
	ld	(hl),a		;dirloc=0
	ret

search$fin:			;end of directory, or empty name
	call	set$end$dir	;may be artifical end
	ld	a,255
	jp	sta$ret

delete:				;delete the currently addressed file
	call	check$write	;write protected?
	ld	c,extnum
	call	search		;search through file type
delete0:
				;loop while directory matches
	call	end$of$dir
	ret	z		;stop if end
				;set each non zero disk map entry to 0
				;in the allocation vector
				;may be r/o file
	call	check$rodir	;ro disk error if found
	call	getdptra	;HL=.buff(dptr)
	ld	(hl),empty
	ld	c,0
	call	scandm		;alloc elts set to 0
	call	wrdir		;write the directory
	call	searchn		;to next element
	jp	delete0		;for another record

get$block:			;given allocation vector position BC, find the zero bit
				;closest to this position by searching left and right.
				;if found, set the bit to one and return the bit position
				;in hl.  if not found (i.e., we pass 0 on the left, or
				;maxall on the right), return 0000 in hl
	ld	d,b
	ld	e,c		;copy of starting position to de
lefttst:
	ld	a,c
	or	b
	jp	z,righttst	;skip if left=0000
				;left not at position zero, bit zero?
	dec	bc
	push	de
	push	bc		;left,right pushed
	call	getallocbit
	rra
	jp	nc,retblock	;return block number if zero
				;bit is one, so try the right
	pop	bc
	pop	de		;left, right restored
righttst:
	ld	hl,(maxall)	;value of maximum allocation#
	ld	a,e
	sub	l
	ld	a,d
	sbc	a,h		;right=maxall?
	jp	nc,retblock0	;return block 0000 if so
	inc	de
	push	bc
	push	de		;left, right pushed
	ld	b,d
	ld	c,e		;ready right for call
	call	getallocbit
	rra
	jp	nc,retblock	;return block number if zero
	pop	de
	pop	bc		;restore left and right pointers
	jp	lefttst		;for another attempt
retblock:
	rla
	inc	a		;bit back into position and set to 1
				;d contains the number of shifts required to reposition
	call	rotr		;move bit back to position and store
	pop	hl
	pop	de		;HL returned value, DE discarded
	ret

retblock0:			;cannot find an available bit, return 0000
	ld	a,c
	or	b
	jp	nz,lefttst	;also at beginning
	ld	hl,0000h
	ret

copy$fcb:			;copy the entire file control block
	ld	c,0
	ld	e,fcblen	;start at 0, to fcblen-1
;	jp	copy$dir

copy$dir:			;copy fcb information starting at C for E bytes
				;into the currently addressed directory entry
	push	de		;save length for later
	ld	b,0		;double index to BC
	ld	hl,(info)	;HL = source for data
	add	hl,bc
	ex	de,hl		;DE=.fcb(C), source for copy
	call	getdptra	;HL=.buff(dptr), destination
	pop	bc		;DE=source, HL=dest, C=length
	call	move		;data moved
seek$copy:			;enter from close to seek and copy current element
	call	seek$dir	;to the directory element
	jp	wrdir		;write the directory element
;	ret
rename:				;rename the file described by the first half of
				;the currently addressed file control block. the
				;new name is contained in the last half of the
				;currently addressed file conrol block.  the file
				;name and type are changed, but the reel number
				;is ignored.  the user number is identical
	call	check$write	;may be write protected
				;search up to the extent field
	ld	c,extnum
	call	search
				;copy position 0
	ld	hl,(info)
	ld	a,(hl)		;HL=.fcb(0), A=fcb(0)
	ld	de,dskmap
	add	hl,de		;HL=.fcb(dskmap)
	ld	(hl),a		;fcb(dskmap)=fcb(0)
				;assume the same disk drive for new named file
rename0:
	call	end$of$dir
	ret	z		;stop at end of dir
				;not end of directory, rename next element
	call	check$rodir	;may be read-only file
	ld	c,dskmap
	ld	e,extnum
	call	copy$dir
				;element renamed, move to next
	call	searchn
	jp	rename0

indicators:			;set file indicators for current fcb
	ld	c,extnum
	call	search		;through file type
indic0:	call	end$of$dir
	ret	z		;stop at end of dir
				;not end of directory, continue to change
	ld	c,0
	ld	e,extnum	;copy name
	call	copy$dir
	call	searchn
	jp	indic0

open:				;search for the directory entry, copy to fcb
	ld	c,namlen
	call	search
	call	end$of$dir
	ret	z		;return with lret=255 if end
				;not end of directory, copy fcb information
open$copy:			;(referenced below to copy fcb info)
	call	getexta
	ld	a,(hl)
	push	af
	push	hl		;save extent#
	call	getdptra
	ex	de,hl		;DE = .buff(dptr)
	ld	hl,(info)	;HL=.fcb(0)
	ld	c,nxtrec	;length of move operation
	push	de		;save .buff(dptr)
	call	move		;from .buff(dptr) to .fcb(0)
				;note that entire fcb is copied, including indicators
	call	setfwf		;sets file write flag
	pop	de
	ld	hl,extnum
	add	hl,de		;HL=.buff(dptr+extnum)
	ld	c,(hl)		;C = directory extent number
	ld	hl,reccnt
	add	hl,de		;HL=.buff(dptr+reccnt)
	ld	b,(hl)		;B holds directory record count
	pop	hl
	pop	af
	ld	(hl),a		;restore extent number
				;HL = .user extent#, B = dir rec cnt, C = dir extent#
				;if user ext < dir ext then user := 128 records
				;if user ext = dir ext then user := dir records
				;if user ext > dir ext then user := 0 records
	ld	a,c
	cp	(hl)
	ld	a,b		;ready dir reccnt
	jp	z,open$rcnt	;if same, user gets dir reccnt
	ld	a,0
	jp	c,open$rcnt	;user is larger
	ld	a,128		;directory is larger
open$rcnt:			;A has record count to fill
	ld	hl,(info)
	ld	de,reccnt
	add	hl,de
	ld	(hl),a
	ret

mergezero:			;HL = .fcb1(i), DE = .fcb2(i),
				;if fcb1(i) = 0 then fcb1(i) := fcb2(i)
	ld	a,(hl)
	inc	hl
	or	(hl)
	dec	hl
	ret	nz		;return if = 0000
	ld	a,(de)
	ld	(hl),a
	inc	de
	inc	hl		;low byte copied
	ld	a,(de)
	ld	(hl),a
	dec	de
	dec	hl		;back to input form
	ret

close:				;locate the directory element and re-write it
	xor	a
	ld	(lret),a
	ld	(dcnt),a
	ld	(dcnt+1),a
	call	nowrite
	ret	nz		;skip close if r/o disk
				;check file write flag - 0 indicates written
	call	getmodnum	;fcb(modnum) in A
	and	fwfmsk
	ret	nz		;return if bit remains set
	ld	c,namlen
	call	search		;locate file
	call	end$of$dir
	ret	z		;return if not found
				;merge the disk map at info with that at buff(dptr)
	ld	bc,dskmap
	call	getdptra
	add	hl,bc
	ex	de,hl		;DE is .buff(dptr+16)
	ld	hl,(info)
	add	hl,bc		;DE=.buff(dptr+16), HL=.fcb(16)
	ld	c,fcblen-dskmap;length of single byte dm
merge0:	ld	a,(single)
	or	a
	jp	z,merged	;skip to double
				;this is a single byte map
				;if fcb(i) = 0 then fcb(i) = buff(i)
				;if buff(i) = 0 then buff(i) = fcb(i)
				;if fcb(i) <> buff(i) then error
	ld	a,(hl)
	or	a
	ld	a,(de)
	jp	nz,fcbnzero
				;fcb(i) = 0
	ld	(hl),a		;fcb(i) = buff(i)
fcbnzero:
	or	a
	jp	nz,buffnzero
				;buff(i) = 0
	ld	a,(hl)
	ld	(de),a		;buff(i)=fcb(i)
buffnzero:
	cp	(hl)
	jp	nz,mergerr	;fcb(i) = buff(i)?
	jp	dmset		;if merge ok

merged:				;this is a double byte merge operation
	call	mergezero	;buff = fcb if buff 0000
	ex	de,hl
	call	mergezero
	ex	de,hl		;fcb = buff if fcb 0000
				;they should be identical at this point
	ld	a,(de)
	cp	(hl)
	jp	nz,mergerr	;low same?
	inc	de
	inc	hl		;to high byte
	ld	a,(de)
	cp	(hl)
	jp	nz,mergerr	;high same?
				;merge operation ok for this pair
	dec	c		;extra count for double byte
dmset:	inc	de
	inc	hl		;to next byte position
	dec	c
	jp	nz,merge0	;for more
				;end of disk map merge, check record count
				;DE = .buff(dptr)+32, HL = .fcb(32)
	ld	bc,-(fcblen-extnum)
	add	hl,bc
	ex	de,hl
	add	hl,bc
				;DE = .fcb(extnum), HL = .buff(dptr+extnum)
	ld	a,(de)		;current user extent number
				;if fcb(ext) >= buff(fcb) then
				;buff(ext) := fcb(ext), buff(rec) := fcb(rec)
	cp	(hl)
	jp	c,endmerge
				;fcb extent number >= dir extent number
	ld	(hl),a		;buff(ext) = fcb(ext)
				;update directory record count field
	ld	bc,reccnt-extnum
	add	hl,bc
	ex	de,hl
	add	hl,bc
				;DE=.buff(reccnt), HL=.fcb(reccnt)
	ld	a,(hl)
	ld	(de),a		;buff(reccnt)=fcb(reccnt)
endmerge:
	ld	a,true
	ld	(fcb$copied),a	;mark as copied
	jp	seek$copy	;ok to "wrdir" here - 1.4 compat
				;		ret

mergerr:			;elements did not merge correctly
	ld	hl,lret
	dec	(hl)		;=255 non zero flag set
	ret

make:				;create a new file by creating a directory entry
				;then opening the file
	call	check$write	;may be write protected
	ld	hl,(info)
	push	hl		;save fcb address, look for e5
	ld	hl,efcb
	ld	(info),hl	;info = .empty
	ld	c,1
	call	search		;length 1 match on empty entry
	call	end$of$dir	;zero flag set if no space
	pop	hl		;recall info address
	ld	(info),hl	;in case we return here
	ret	z		;return with error condition 255 if not found
	ex	de,hl		;DE = info address
				;clear the remainder of the fcb
	ld	hl,namlen
	add	hl,de		;HL=.fcb(namlen)
	ld	c,fcblen-namlen	;number of bytes to fill
	xor	a		;clear accumulator to 00 for fill
make0:	ld	(hl),a
	inc	hl
	dec	c
	jp	nz,make0
	ld	hl,ubytes
	add	hl,de		;HL = .fcb(ubytes)
	ld	(hl),a		;fcb(ubytes) = 0
	call	setcdr		;may have extended the directory
				;now copy entry to the directory
	call	copy$fcb
				;and set the file write flag to "1"
	jp	setfwf
;	ret

open$reel:			;close the current extent, and open the next one
				;if possible.  RMF is true if in read mode
	xor	a
	ld	(fcb$copied),a	;set true if actually copied
	call	close		;close current extent
				;lret remains at enddir if we cannot open the next ext
	call	end$of$dir
	ret	z		;return if end
				;increment extent number
	ld	hl,(info)
	ld	bc,extnum
	add	hl,bc		;HL=.fcb(extnum)
	ld	a,(hl)
	inc	a
	and	maxext
	ld	(hl),a		;fcb(extnum)=++1
	jp	z,open$mod	;move to next module if zero
				;may be in the same extent group
	ld	b,a
	ld	a,(extmsk)
	and	b
				;if result is zero, then not in the same group
	ld	hl,fcb$copied	;true if the fcb was copied to directory
	and	(hl)		;produces a 00 in accumulator if not written
	jp	z,open$reel0	;go to next physical extent
				;result is non zero, so we must be in same logical ext
	jp	open$reel1	;to copy fcb information
open$mod:			;extent number overflow, go to next module
	ld	bc,modnum-extnum
	add	hl,bc		;HL=.fcb(modnum)
	inc	(hl)		;fcb(modnum)=++1
				;module number incremented, check for overflow
	ld	a,(hl)
	and	maxmod		;mask high order bits
	jp	z,open$r$err	;cannot overflow to zero
				;otherwise, ok to continue with new module
open$reel0:
	ld	c,namlen
	call	search		;next extent found?
	call	end$of$dir
	jp	nz,open$reel1
				;end of file encountered
	ld	a,(rmf)
	inc	a		;0ffh becomes 00 if read
	jp	z,open$r$err	;sets lret = 1
				;try to extend the current file
	call	make
				;cannot be end of directory
	call	end$of$dir
	jp	z,open$r$err	;with lret = 1
	jp	open$reel2

open$reel1:			;not end of file, open
	call	open$copy
open$reel2:
	call	getfcb		;set parameters
	xor	a
	jp	sta$ret		;lret = 0
;	ret 			;with lret = 0

open$r$err:			;cannot move to next extent of this file
	call	setlret1	;lret = 1
	jp	setfwf		;ensure that it will not be closed
;	ret

seqdiskread:			;sequential disk read operation
	ld	a,1
	ld	(seqio),a
				;drop through to diskread

diskread:			;(may enter from seqdiskread)
	ld	a,true
	ld	(rmf),a		;read mode flag = true (open$reel)
				;read the next record from the current fcb
	call	getfcb		;sets parameters for the read
	ld	a,(vrecord)
	ld	hl,rcount
	cp	(hl)		;vrecord-rcount
				;skip if rcount > vrecord
	jp	c,recordok
				;not enough records in the extent
				;record count must be 128 to continue
	cp	128		;vrecord = 128?
	jp	nz,diskeof	;skip if vrecord<>128
	call	open$reel	;go to next extent if so
	xor	a
	ld	(vrecord),a	;vrecord=00
				;now check for open ok
	ld	a,(lret)
	or	a
	jp	nz,diskeof	;stop at eof
recordok:			;arrive with fcb addressing a record to read
	call	index
				;error 2 if reading unwritten data
				;(returns 1 to be compatible with 1.4)
	call	allocated	;arecord=0000?
	jp	z,diskeof
				;record has been allocated, read it
	call	atran		;arecord now a disk address
	call	seek		;to proper track,sector
	call	rdbuff		;to dma address
	jp	setfcb		;replace parameter
;	ret

diskeof:
	jp	setlret1	;lret = 1
;	ret

seqdiskwrite:			;sequential disk write
	ld	a,1
	ld	(seqio),a
				;drop through to diskwrite

diskwrite:			;(may enter here from seqdiskwrite above)
	ld	a,false
	ld	(rmf),a		;read mode flag
				;write record to currently selected file
	call	check$write	;in case write protected
	ld	hl,(info)	;HL = .fcb(0)
	call	check$rofile	;may be a read-only file
	call	getfcb		;to set local parameters
	ld	a,(vrecord)
	cp	lstrec+1	;vrecord-128
				;skip if vrecord > lstrec
				;vrecord = 128, cannot open next extent
	jp	nc,setlret1	;lret=1
diskwr0:			;can write the next record, so continue
	call	index
	call	allocated
	ld	c,0		;marked as normal write operation for wrbuff
	jp	nz,diskwr1
				;not allocated
				;the argument to getblock is the starting
				;position for the disk search, and should be
				;the last allocated block for this file, or
				;the value 0 if no space has been allocated
	call	dm$position
	ld	(dminx),a	;save for later
	ld	bc,0000h	;may use block zero
	or	a
	jp	z,nopblock	;skip if no previous block
				;previous block exists at A
	ld	c,a
	dec	bc		;previous block # in BC
	call	getdm		;previous block # to HL
	ld	b,h
	ld	c,l		;BC=prev block#
nopblock:			;BC = 0000, or previous block #
	call	get$block	;block # to HL
				;arrive here with block# or zero
	ld	a,l
	or	h
	jp	nz,blockok
				;cannot find a block to allocate
	ld	a,2
	jp	sta$ret		;lret=2

blockok:			;allocated block number is in HL
	ld	(arecord),hl
	ex	de,hl		;block number to DE
	ld	hl,(info)
	ld	bc,dskmap
	add	hl,bc		;HL=.fcb(dskmap)
	ld	a,(single)
	or	a		;set flags for single byte dm
	ld	a,(dminx)	;recall dm index
	jp	z,allocwd	;skip if allocating word
				;allocating a byte value
	call	addh
	ld	(hl),e		;single byte alloc
	jp	diskwru		;to continue

allocwd:			;allocate a word value
	ld	c,a
	ld	b,0		;double(dminx)
	add	hl,bc
	add	hl,bc		;HL=.fcb(dminx*2)
	ld	(hl),e
	inc	hl
	ld	(hl),d		;double wd
diskwru:			;disk write to previously unallocated block
	ld	c,2		;marked as unallocated write
diskwr1:			;continue the write operation of no allocation error
				;C = 0 if normal write, 2 if to prev unalloc block
	ld	a,(lret)
	or	a
	ret	nz		;stop if non zero returned value
	push	bc		;save write flag
	call	atran		;arecord set
	ld	a,(seqio)
	dec	a
	dec	a
	jp	nz,diskwr11
	pop	bc
	push	bc
	ld	a,c
	dec	a
	dec	a
	jp	nz,diskwr11	;old allocation
	push	hl		;arecord in hl ret from atran
	ld	hl,(buffa)
	ld	d,a		;zero buffa & fill
fill0:	ld	(hl),a
	inc	hl
	inc	d
	jp	p,fill0
	call	setdir
	ld	hl,(arecord1)
	ld	c,2
fill1:	ld	(arecord),hl
	push	bc
	call	seek
	pop	bc
	call	wrbuff		;write fill record
	ld	hl,(arecord)	;restore last record
	ld	c,0		;change  allocate flag
	ld	a,(blkmsk)
	ld	b,a
	and	l
	cp	b
	inc	hl
	jp	nz,fill1	;cont until cluster is zeroed
	pop	hl
	ld	(arecord),hl
	call	setdata
diskwr11:
	call	seek		;to proper file position
	pop	bc
	push	bc		;restore/save write flag (C=2 if new block)
	call	wrbuff		;written to disk
	pop	bc		;C = 2 if a new block was allocated, 0 if not
				;increment record count if rcount<=vrecord
	ld	a,(vrecord)
	ld	hl,rcount
	cp	(hl)		;vrecord-rcount
	jp	c,diskwr2
				;rcount <= vrecord
	ld	(hl),a
	inc	(hl)		;rcount = vrecord+1
	ld	c,2		;mark as record count incremented
diskwr2:			;A has vrecord, C=2 if new block or new record#
	dec	c
	dec	c
	jp	nz,noupdate
	push	af		;save vrecord value
	call	getmodnum	;HL=.fcb(modnum), A=fcb(modnum)
				;reset the file write flag to mark as written fcb
	and	(not fwfmsk) and 0ffh;bit reset
	ld	(hl),a		;fcb(modnum) = fcb(modnum) and 7fh
	pop	af		;restore vrecord
noupdate:			;check for end of extent, if found attempt to open
				;next extent in preparation for next write
	cp	lstrec		;vrecord=lstrec?
	jp	nz,diskwr3	;skip if not
				;may be random access write, if so we are done
				;change next
	ld	a,(seqio)
	cp	1
	jp	nz,diskwr3	;skip next extent open op
				;update current fcb before going to next extent
	call	setfcb
	call	open$reel	;rmf=false
				;vrecord remains at lstrec causing eof if
				;no more directory space is available
	ld	hl,lret
	ld	a,(hl)
	or	a
	jp	nz,nospace
				;space available, set vrecord=255
	dec	a
	ld	(vrecord),a	;goes to 00 next time
nospace:
	ld	(hl),0		;lret = 00 for returned value
diskwr3:
	jp	setfcb		;replace parameters
;	ret

rseek:				;random access seek operation, C=0ffh if read mode
				;fcb is assumed to address an active file control block
				;(modnum has been set to 1100$0000b if previous bad seek)
	xor	a
	ld	(seqio),a	;marked as random access operation
rseek1:	push	bc		;save r/w flag
	ld	hl,(info)
	ex	de,hl		;DE will hold base of fcb
	ld	hl,ranrec
	add	hl,de		;HL=.fcb(ranrec)
	ld	a,(hl)
	and	7fh
	push	af		;record number
	ld	a,(hl)
	rla			;cy=lsb of extent#
	inc	hl
	ld	a,(hl)
	rla
	and	11111b		;A=ext#
	ld	c,a		;C holds extent number, record stacked
	ld	a,(hl)
	rra
	rra
	rra
	rra
	and	1111b		;mod#
	ld	b,a		;B holds module#, C holds ext#
	pop	af		;recall sought record #
				;check to insure that high byte of ran rec = 00
	inc	hl
	ld	l,(hl)		;l=high byte (must be 00)
	inc	l
	dec	l
	ld	l,6		;zero flag, l=6
				;produce error 6, seek past physical eod
	jp	nz,seekerr
				;otherwise, high byte = 0, A = sought record
	ld	hl,nxtrec
	add	hl,de		;HL = .fcb(nxtrec)
	ld	(hl),a		;sought rec# stored away
				;arrive here with B=mod#, C=ext#, DE=.fcb, rec stored
				;the r/w flag is still stacked.  compare fcb values
	ld	hl,extnum
	add	hl,de
	ld	a,c		;A=seek ext#
	sub	(hl)
	jp	nz,ranclose	;tests for = extents
				;extents match, check mod#
	ld	hl,modnum
	add	hl,de
	ld	a,b		;B=seek mod#
				;could be overflow at eof, producing module#
				;of 90H or 10H, so compare all but fwf
	sub	(hl)
	and	7fh
	jp	z,seekok	;same?
ranclose:
	push	bc
	push	de		;save seek mod#,ext#, .fcb
	call	close		;current extent closed
	pop	de
	pop	bc		;recall parameters and fill
	ld	l,3		;cannot close error #3
	ld	a,(lret)
	inc	a
	jp	z,badseek
	ld	hl,extnum
	add	hl,de
	ld	(hl),c		;fcb(extnum)=ext#
	ld	hl,modnum
	add	hl,de
	ld	(hl),b		;fcb(modnum)=mod#
	call	open		;is the file present?
	ld	a,(lret)
	inc	a
	jp	nz,seekok	;open successful?
				;cannot open the file, read mode?
	pop	bc		;r/w flag to c (=0ffh if read)
	push	bc		;everyone expects this item stacked
	ld	l,4		;seek to unwritten extent #4
	inc	c		;becomes 00 if read operation
	jp	z,badseek	;skip to error if read operation
				;write operation, make new extent
	call	make
	ld	l,5		;cannot create new extent #5
	ld	a,(lret)
	inc	a
	jp	z,badseek	;no dir space
				;file make operation successful
seekok:
	pop	bc		;discard r/w flag
	xor	a
	jp	sta$ret		;with zero set
badseek:			;fcb no longer contains a valid fcb, mark
				;with 1100$000b in modnum field so that it
				;appears as overflow with file write flag set
	push	hl		;save error flag
	call	getmodnum	;HL = .modnum
	ld	(hl),11000000b
	pop	hl		;and drop through
seekerr:
	pop	bc		;discard r/w flag
	ld	a,l
	ld	(lret),a	;lret=#, nonzero
				;setfwf returns non-zero accumulator for err
	jp	setfwf		;flag set, so subsequent close ok
;	ret

randiskread:			;random disk read operation
	ld	c,true		;marked as read operation
	call	rseek
	call	z,diskread	;if seek successful
	ret

randiskwrite:			;random disk write operation
	ld	c,false		;marked as write operation
	call	rseek
	call	z,diskwrite	;if seek successful
	ret

compute$rr:			;compute random record position for getfilesize/setrandom
	ex	de,hl
	add	hl,de
				;DE=.buf(dptr) or .fcb(0), HL = .f(nxtrec/reccnt)
	ld	c,(hl)
	ld	b,0		;BC = 0000 0000 ?rrr rrrr
	ld	hl,extnum
	add	hl,de
	ld	a,(hl)
	rrca
	and	80h		;A=e000 0000
	add	a,c
	ld	c,a
	ld	a,0
	adc	a,b
	ld	b,a
				;BC = 0000 000? errrr rrrr
	ld	a,(hl)
	rrca
	and	0fh
	add	a,b
	ld	b,a
				;BC = 000? eeee errrr rrrr
	ld	hl,modnum
	add	hl,de
	ld	a,(hl)		;A=XXX? mmmm
	add	a,a
	add	a,a
	add	a,a
	add	a,a		;cy=? A=mmmm 0000
	push	af
	add	a,b
	ld	b,a
				;cy=?, BC = mmmm eeee errr rrrr
	push	af		;possible second carry
	pop	hl		;cy = lsb of L
	ld	a,l		;cy = lsb of A
	pop	hl		;cy = lsb of L
	or	l		;cy/cy = lsb of A
	and	1		;A = 0000 000? possible carry-out
	ret

getfilesize:			;compute logical file size for current fcb
	ld	c,extnum
	call	search
				;zero the receiving ranrec field
	ld	hl,(info)
	ld	de,ranrec
	add	hl,de
	push	hl		;save position
	ld	(hl),d
	inc	hl
	ld	(hl),d
	inc	hl
	ld	(hl),d		;=00 00 00
getsize:
	call	end$of$dir
	jp	z,setsize
				;current fcb addressed by dptr
	call	getdptra
	ld	de,reccnt	;ready for compute size
	call	compute$rr
				;A=0000 000? BC = mmmm eeee errr rrrr
				;compare with memory, larger?
	pop	hl
	push	hl		;recall, replace .fcb(ranrec)
	ld	e,a		;save cy
	ld	a,c
	sub	(hl)
	inc	hl		;ls byte
	ld	a,b
	sbc	a,(hl)
	inc	hl		;middle byte
	ld	a,e
	sbc	a,(hl)		;carry if .fcb(ranrec) > directory
	jp	c,getnextsize	;for another try
				;fcb is less or equal, fill from directory
	ld	(hl),e
	dec	hl
	ld	(hl),b
	dec	hl
	ld	(hl),c
getnextsize:
	call	searchn
	jp	getsize

setsize:
	pop	hl		;discard .fcb(ranrec)
	ret

setrandom:			;set random record from the current file control block
	ld	hl,(info)
	ld	de,nxtrec	;ready params for computesize
	call	compute$rr	;DE=info, A=cy, BC=mmmm eeee errr rrrr
	ld	hl,ranrec
	add	hl,de		;HL = .fcb(ranrec)
	ld	(hl),c
	inc	hl
	ld	(hl),b
	inc	hl
	ld	(hl),a		;to ranrec
	ret

select:				;select disk info for subsequent input or output ops
	ld	hl,(dlog)
	ld	a,(curdsk)
	ld	c,a
	call	hlrotr
	push	hl
	ex	de,hl		;save it for test below, send to seldsk
	call	selectdisk
	pop	hl		;recall dlog vector
	call	z,sel$error	;returns true if select ok
				;is the disk logged in?
	ld	a,l
	rra
	ret	c		;return if bit is set
				;disk not logged in, set bit and initialize
	ld	hl,(dlog)
	ld	c,l
	ld	b,h		;call ready
	call	set$cdisk
	ld	(dlog),hl	;dlog=set$cdisk(dlog)
	jp	initialize
;	ret

curselect:
	ld	a,(linfo)
	ld	hl,curdsk
	cp	(hl)
	ret	z		;skip if linfo=curdsk
	ld	(hl),a		;curdsk=info
	jp	select
;	ret

reselect:			;check current fcb to see if reselection necessary
	ld	a,true
	ld	(resel),a	;mark possible reselect
	ld	hl,(info)
	ld	a,(hl)		;drive select code
	and	11111b		;non zero is auto drive select
	dec	a		;drive code normalized to 0..30, or 255
	ld	(linfo),a	;save drive code
	cp	30
	jp	nc,noselect
				;auto select function, save curdsk
	ld	a,(curdsk)
	ld	(olddsk),a	;olddsk=curdsk
	ld	a,(hl)
	ld	(fcbdsk),a	;save drive code

;;	and	11100000b
	and	0b11100000

	ld	(hl),a		;preserve hi bits
	call	curselect
noselect:			;set user code
	ld	a,(usrcode)	;0...31
	ld	hl,(info)
	or	(hl)
	ld	(hl),a
	ret

;	individual function handlers
func12:				;return version number
	ld	a,dvers
	jp	sta$ret		;lret = dvers (high = 00)
;	ret
;	jp	goback

func13:				;reset disk system - initialize to disk 0
	ld	hl,0
	ld	(rodsk),hl
	ld	(dlog),hl
	xor	a
	ld	(curdsk),a	;note that usrcode remains unchanged
	ld	hl,tbuff
	ld	(dmaad),hl	;dmaad = tbuff
	call	setdata		;to data dma address
	jp	select
;	ret
;	jp	goback

func14	equ	curselect	;select disk info
;	ret
;	jp	goback

func15:				;open file
	call	clrmodnum	;clear the module number
	call	reselect
	jp	open
;	ret
;	jp	goback

func16:				;close file
	call	reselect
	jp	close
;	ret
;	jp	goback

func17:				;search for first occurrence of a file
	ld	c,0		;length assuming '?' true
	ex	de,hl		;was lhld info
	ld	a,(hl)
	cp	'?'		;no reselect if ?
	jp	z,qselect	;skip reselect if so
				;normal search
	call	getexta
	ld	a,(hl)
	cp	'?'		;
	call	nz,clrmodnum	;module number zeroed
	call	reselect
	ld	c,namlen
qselect:
	call	search
	jp	dir$to$user	;copy directory entry to user
;	ret
;	jp	goback

func18:				;search for next occurrence of a file name
	ld	hl,(searcha)
	ld	(info),hl
	call	reselect
	call	searchn
	jp	dir$to$user	;copy directory entry to user
;	ret
;	jp	goback

func19:				;delete a file
	call	reselect
	call	delete
	jp	copy$dirloc
;	ret
;	jp	goback

func20:				;read a file
	call	reselect
	jp	seqdiskread
;	jp	goback

func21:				;write a file
	call	reselect
	jp	seqdiskwrite
;	jp	goback

func22:				;make a file
	call	clrmodnum
	call	reselect
	jp	make
;	ret
;	jp	goback

func23:				;rename a file
	call	reselect
	call	rename
	jp	copy$dirloc
;	ret
;	jp	goback

func24:				;return the login vector
	ld	hl,(dlog)
	jp	sthl$ret
;	ret
;	jp	goback

func25:				;return selected disk number
	ld	a,(curdsk)
	jp	sta$ret
;	ret
;	jp	goback

func26:				;set the subsequent dma address to info
	ex	de,hl		;was lhld info
	ld	(dmaad),hl	;dmaad = info
	jp	setdata		;to data dma address
;	ret
;	jp	goback

func27:				;return the login vector address
	ld	hl,(alloca)
	jp	sthl$ret
;	ret
;	jp	goback

func28	equ	set$ro
				;write protect current disk
;	ret
;	jp	goback

func29:				;return r/o bit vector
	ld	hl,(rodsk)
	jp	sthl$ret
;	ret
;	jp	goback

func30:				;set file indicators
	call	reselect
	call	indicators
	jp	copy$dirloc	;lret=dirloc
;	ret
;	jp	goback

func31:				;return address of disk parameter block
	ld	hl,(dpbaddr)
sthl$ret:
	ld	(aret),hl
	ret
;	jp	goback

func32:				;set user code
	ld	a,(linfo)
	cp	0ffh
	jp	nz,setusrcode
				;interrogate user code instead
	ld	a,(usrcode)
	jp	sta$ret		;lret=usrcode
;	ret
;	jp	goback

setusrcode:
	and	1fh
	ld	(usrcode),a
	ret
;	jp	goback

func33:				;random disk read operation
	call	reselect
	jp	randiskread	;to perform the disk read
;	ret
;	jp	goback

func34:				;random disk write operation
	call	reselect
	jp	randiskwrite	;to perform the disk write
;	ret
;	jp	goback

func35:				;return file size (0-65536)
	call	reselect
	jp	getfilesize
;	ret
;	jp	goback

func36	equ	setrandom	;set random record
;	ret
;	jp	goback

func37:	ld	hl,(info)
	ld	a,l
	cpl
	ld	e,a
	ld	a,h
	cpl
	ld	hl,(dlog)
	and	h
	ld	d,a
	ld	a,l
	and	e
	ld	e,a
	ld	hl,(rodsk)
	ex	de,hl
	ld	(dlog),hl
	ld	a,l
	and	e
	ld	l,a
	ld	a,h
	and	d
	ld	h,a
	ld	(rodsk),hl
	ret

goback:				;arrive here at end of processing to return to user
	ld	a,(resel)
	or	a
	jp	z,retmon
				;reselection may have taken place
	ld	hl,(info)
	ld	(hl),0		;fcb(0)=0
	ld	a,(fcbdsk)
	or	a
	jp	z,retmon
				;restore disk number
	ld	(hl),a		;fcb(0)=fcbdsk
	ld	a,(olddsk)
	ld	(linfo),a
	call	curselect

;	return from the disk monitor
retmon:	ld	hl,(entsp)
	ld	sp,hl		;user stack restored
	ld	hl,(aret)
	ld	a,l
	ld	b,h		;BA = HL = aret
	ret

func38	equ	func$ret
func39	equ	func$ret
func40:				;random disk write with zero fill of unallocated block
	call	reselect
	ld	a,2
	ld	(seqio),a
	ld	c,false
	call	rseek1
	call	z,diskwrite	;if seek successful
	ret

;	data areas

;	initialized data
efcb:	.db	empty		;0e5=available dir entry
rodsk:	.dw	0		;read only disk vector
dlog:	.dw	0		;logged-in disks
dmaad:	.dw	tbuff		;initial dma address

;	curtrka - alloca are set upon disk select
;	(data must be adjacent, do not insert variables)
;	(address of translate vector, not used)
cdrmaxa:
	.ds	word		;pointer to cur dir max value
curtrka:
	.ds	word		;current track address
curreca:
	.ds	word		;current record address
buffa:	.ds	word		;pointer to directory dma address
dpbaddr:
	.ds	word		;current disk parameter block address
checka:	.ds	word		;current checksum vector address
alloca:	.ds	word		;current allocation vector address

addlist	equ	$-buffa		;address list size

;	sectpt - offset obtained from disk parm block at dpbaddr
;	(data must be adjacent, do not insert variables)
sectpt:	.ds	word		;sectors per track
blkshf:	.ds	byte		;block shift factor
blkmsk:	.ds	byte		;block mask
extmsk:	.ds	byte		;extent mask
maxall:	.ds	word		;maximum allocation number
dirmax:	.ds	word		;largest directory number
dirblk:	.ds	word		;reserved allocation bits for directory
chksiz:	.ds	word		;size of checksum vector
offset:	.ds	word		;offset tracks at beginning

dpblist	equ	$-sectpt	;size of area

;	local variables
tranv:	ds	word		;address of translate vector
fcb$copied:
	ds	byte		;set true if copy$fcb called
rmf:	ds	byte		;read mode flag for open$reel
dirloc:	ds	byte		;directory flag in rename, etc.
seqio:	ds	byte		;1 if sequential i/o
linfo:	ds	byte		;low(info)
dminx:	ds	byte		;local for diskwrite
searchl:
	ds	byte		;search length
searcha:
	ds	word		;search address
tinfo:	ds	word		;temp for info in "make"
single:	ds	byte		;set true if single byte allocation map
resel:	ds	byte		;reselection flag
olddsk:	ds	byte		;disk on entry to bdos
fcbdsk:	ds	byte		;disk named in fcb
rcount:	ds	byte		;record count in current fcb
extval:	ds	byte		;extent number and extmsk
vrecord:
	ds	word		;current virtual record
arecord:
	ds	word		;current actual record
arecord1:
	ds	word		;current actual block# * blkmsk

;	local variables for directory access
dptr:	ds	byte		;directory pointer 0,1,2,3
dcnt:	ds	word		;directory counter 0,1,...,dirmax
drec:	ds	word		;directory record 0,1,...,dirmax/4

;bios	equ	($ and 0ff00h)+100h;next module

	end





	;; Ordering of segments for the linker.
	.area	_HOME
	.area	_CODE
        .area   _GSINIT
        .area   _GSFINAL

	.area	_DATA
	.area	_BSEG
        .area   _BSS
        .area   _HEAP

        .area   _CODE
.if 0
__clock::
	ld	a,#2
        rst     0x08
	ret
.endif

_exit::
	;; Exit - special code to the emulator
	ld	a,#0
        rst     0x08
1$:
	halt
	jr	1$

        .area   _GSINIT
gsinit::

        .area   _GSFINAL
        ret
