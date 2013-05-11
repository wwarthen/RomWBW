; findfile.asm 7/21/2012 dwg - added keystroke scan terminate
; findfile.asm 7/19/2012 dwg - for 2.0.0.0 B22
; findfile.asm 2/20.2012 dwg - add RESET$DISK before exit for ZDOS
; findfile.asm 2/17/2012 dwg - review for release 1.5.1.0
; findfile.asm 2/11/2012 dwg - make ident compliant
; findfile.asm 1/30/2012 dwg - use new do$start and do$end macros
; findfile.asm 1/22/2012 dwg - find a file on any slice

; Copyright (C) 2011-2012 Douglas Goodall Licensed under GPL Ver 3.
;
; This file is part of NuBiosDWG and is free software: you can
; redistribute it and/or modify it under the terms of the GNU
; General Public License as published by the Free Software Foundation,
; either version 3 of the License, or (at your option) any later version.
; This file is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; You should have received a copy of the GNU General Public License
; along with it.  If not, see <http://www.gnu.org/licenses/>.

	maclib	portab
	maclib	globals
	maclib	stdlib
	maclib	cpmbios
	maclib	cpmbdos
	maclib	bioshdr
	maclib	printers
	maclib	banner
	maclib	terminal
	maclib	applvers
	maclib	version
;	maclib	ffhaslu
;	maclib	ffnumlu
;	maclib	ffsetlu
;	maclib	ffgetlu
;	maclib	z80
;	maclib	memory
;	maclib	cpmappl
;	maclib	identity

; identity.lib 2/19/2012 dwg - add ify macro
; identity.lib 2/17/2012 dwg - Program Identity Declarations

	extrn	x$ident

ident	macro	file1fcb
	lxi	h,file1fcb
	call	x$ident
	endm

ify	macro	progname,bool
	local	done
	local	file
	local	fini
	ident	file
	jmp	fini
	newfcb	file,0,progname
fini:	mvi	a,bool
	cpi	TRUE
	jnz	done
	conout	CR
	conout	LF
done:	
	endm


identx	macro	file1fcb
	local	openok
	local	identend

	local	ldrive,lcolon,lname,ldot,lext,lterm

	mvi	c,FOPEN
	lxi	d,file1fcb
	call	BDOS
	cpi	255
	jnz	openok

	memcpy	lname,file1fcb+1,8
	mvi	a,','
	sta	ldot
	memcpy	lext,file1fcb+9,3
	mvi	a,'$'
	sta	lterm
	print	lname
	printf	' -- File Not Found'
	jmp	identend
openok:

	mvi	c,SETDMA
	lxi	d,buffer
	call	BDOS

	mvi	c,READSEQ
	lxi	d,file1fcb
	call	BDOS

	mvi	c,FCLOSE
	lxi	d,file1fcb
	call	BDOS

	lxi	d,d$prog
	mvi	c,9
	call	BDOS

	conout	','
	conout	' '
	lda	p$rmj
	mov	l,a
	mvi	h,0
	call	pr$d$word
	conout	'.'
	lda	p$rmn
	mov	l,a
	call	pr$d$word
	conout	'.'
	lda	p$rup
	mov	l,a
	call	pr$d$word
	conout	'.'
	lda	p$rtp
	mov	l,a
	call	pr$d$word
	conout	','
	conout	' '

	lda	p$mon
	mov	l,a
	call	pr$d$word
	conout	'/'
	lda	p$day
	mov	l,a
	call	pr$d$word
	conout	'/'
	lhld	p$year
	call	pr$d$word
	conout	','
	conout	' '

	lxi	d,d$prod
	mvi	c,9
	call	BDOS
	conout	','
	conout	' '

	lxi	d,d$orig
	mvi	c,9
	call	BDOS
	conout	','
	conout	' '

	lxi	d,d$ser
	mvi	c,9
	call	BDOS
	conout	','
	conout 	' '

	lxi	d,d$name
	mvi	c,9
	call	BDOS
	jmp	identend

ldrive	ds	1
lcolon	ds	1
lname	ds	8
ldot	ds	1
lext	ds	3
lterm	ds	1

identend:
	endm

idata	macro
	jmp	around$bandata
argv	dw	prog,dat,prod,orig,ser,myname,0
prog	db	'IDENT.COM   $'
	date
	serial
	product
	originator
	oriname
uuid	db	'777A67C2-4A92-42D4-80FE-C96FD6483BD2$'
	db	'buffer-->'
	public	buffer,p$start,p$hexrf,p$sig
	public	p$rmj,p$rmn,p$rup,p$rtp
	public	p$mon,p$day,p$year
buffer	ds	1
p$start	ds	2
p$hexrf	ds	16
p$sig	ds	2
p$rmj	ds	1
p$rmn	ds	1
p$rup	ds	1
p$rtp	ds	1
p$mon	ds	1
p$day	ds	1
p$year	ds	2
p$argv	ds	2
p$e5	ds	1
p$pr$st	ds	2
p$code1	ds	3		; begin: lxi h,0
p$code2	ds	1		;   dad sp
p$code3	ds	3		;   shld pre$stk
p$code4	ds	3		;    lxi sp,stack$top
p$code5	ds	1		;    nop
p$code6	ds	3		;    jmp around$bandata
p$prog	ds	2		;   dw prog
p$dat	ds	2		;   dw dat
p$prod	ds	2		;   dw prod
p$orig	ds	2		;   dw orig
p$ser	ds	2		;   dw ser
p$nam	ds	2		;   dw nam
p$term	ds	2		;   dw 0
d$prog	ds	8+1+3+1		;   db '12345678.123$'
d$date	ds	2+1+2+1+4+1	;   db ' 2/11/2012$'
d$ser	ds	6+1		;   db '654321$'
d$prod	ds	5+1		;   db 'CPM80$'
d$orig	ds	3+1		;   db 'DWG$'
d$name	ds	1+7+1+1+1+1+7+1	;   db ' Douglas W. Goodall$'
d$uuid	ds	37		; unique user identification
d$term2	ds	1		; can be set to zero or dollar sign
p$len	equ	$-buffer
p$rsvd	ds	128-p$len
	db	'<--buffer'
crlf	db	CR,LF,'$'
around$bandata:

	endm

; eof - identity.lib



; cpmappl.lib 2/10/2012 dwg - begin 1.6 development
; cpmappl.lib 2/04/2012 dwg - fix typo mov becomes mvi
; cpmappl.lib 2/ 2/2012 dwg - initial version
 
;
; Copyright (C) 2011-2012 Douglas Goodall Licensed under GPL Ver 3.
;
; This file is part of NuBiosDWG and is free software: you can
; redistribute it and/or modify it under the terms of the GNU
; General Public License as published by the Free Software Foundation,
; either version 3 of the License, or (at your option) any later version.
; This file is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; You should have received a copy of the GNU General Public License
; along with it.  If not, see <http://www.gnu.org/licenses/>.
;

do$start	macro

start:	jmp	begin

	public	hexref
hexref	db	'0123456789ABCDEF'

	public	id$sig,id$rmj,id$rmn,id$rup,id$rtp,id$mon,id$day,id$yr
id$sig	db	'ID'
id$rmj	db	A$RMJ
id$rmn	db	A$RMN
id$rup	db	A$RUP
id$rtp	db	A$RTP
id$mon	db	A$MONTH
id$day	db	A$DAY
id$yr	dw	A$YEAR
id$argv	dw	argv
	db	0e5h


	public	pre$stk
pre$stk	ds	2

	public	begin
begin:	lxi	h,0
	dad	sp
	shld	pre$stk
	lxi	sp,stack$top
	nop
	endm


;---------------------------------


do$end	macro
	lhld	pre$stk
	sphl

	mvi	c,13
	call	BDOS

	ret
	ds	stack$size
stack$top:

	endm

movfcb	macro	destn,source
	lxi d,destn
	lxi h,source
	lxi b,LENFCB
	ldir
	endm

copyfcb	macro	fcbname,source
	local	around
	jmp	around
fcbname	ds	32
around:
	endm


; memory.lib 2/17/2012 dwg - review for release 1.5.1.0
; memory.lib 2/11/2012 dwg - review for release 1.5
; memory.lib 2/04/2012 dwg - adjust for new macros
; memory.lib 1/13/2012 dwg - POSIX memcpy and memset

	extrn	x$memcpy
	extrn	x$memset

memcpy	macro	dst,src,siz
	lxi	d,dst		; load 1st positional parameter into reg
	lxi	h,src		; load 2nd positional parameter into reg
	lxi	b,siz		; load 3rd positional parameter into reg
	call	x$memcpy	; call actual routine in see memory.asm
	endm

memset	macro	dst,data,siz
	lxi	h,dst		; load 1st positional parameter into reg
	mvi	a,data		; load 2nd positional parameter into reg
	lxi	b,siz		; load 3rd positional parameter into reg
	call	x$memset	; call actual routine in see memory.asm
	endm

; eof - memory.lib


;	@CHK MACRO USED FOR CHECKING 8 BIT DISPLACMENTS
;
@CHK	MACRO	?DD	;; USED FOR CHECKING RANGE OF 8-BIT DISP.S
	IF (?DD GT 7FH) AND (?DD LT 0FF80H)
 'DISPLACEMENT RANGE ERROR - Z80 LIB'
	ENDIF
	ENDM
LDX	MACRO	?R,?D	
	@CHK	?D
	DB	0DDH,?R*8+46H,?D
	ENDM
LDY	MACRO	?R,?D	
	@CHK	?D
	DB	0FDH,?R*8+46H,?D
	ENDM
STX	MACRO	?R,?D	
	@CHK	?D
	DB	0DDH,70H+?R,?D
	ENDM
STY	MACRO	?R,?D	
	@CHK	?D
	DB	0FDH,70H+?R,?D
	ENDM
MVIX	MACRO	?N,?D	
	@CHK	?D
	DB	0DDH,36H,?D,?N
	ENDM
MVIY	MACRO	?N,?D	
	@CHK	?D
	DB	0FDH,36H,?D,?N
	ENDM
LDAI	MACRO		
	DB	0EDH,57H
	ENDM
LDAR	MACRO		
	DB	0EDH,5FH
	ENDM
STAI	MACRO		
	DB	0EDH,47H
	ENDM
STAR	MACRO		
	DB	0EDH,4FH
	ENDM

LXIX	MACRO	?NNNN	
	DB	0DDH,21H
	DW	?NNNN
	ENDM
LXIY	MACRO	?NNNN	
	DB	0FDH,21H
	DW	?NNNN
	ENDM
LDED	MACRO	?NNNN	
	DB	0EDH,5BH
	DW	?NNNN
	ENDM
LBCD	MACRO	?NNNN	
	DB	0EDH,4BH
	DW	?NNNN
	ENDM
LSPD	MACRO	?NNNN	
	DB	0EDH,07BH
	DW	?NNNN
	ENDM
LIXD	MACRO	?NNNN	
	DB	0DDH,2AH
	DW	?NNNN
	ENDM
LIYD	MACRO	?NNNN	
	DB	0FDH,2AH
	DW	?NNNN
	ENDM
SBCD	MACRO	?NNNN	
	DB	0EDH,43H
	DW	?NNNN
	ENDM
SDED	MACRO	?NNNN	
	DB	0EDH,53H
	DW	?NNNN
	ENDM
SSPD	MACRO	?NNNN	
	DB	0EDH,73H
	DW	?NNNN
	ENDM
SIXD	MACRO	?NNNN	
	DB	0DDH,22H
	DW	?NNNN
	ENDM
SIYD	MACRO	?NNNN	
	DB	0FDH,22H
	DW	?NNNN
	ENDM
SPIX	MACRO		
	DB	0DDH,0F9H
	ENDM
SPIY	MACRO		
	DB	0FDH,0F9H
	ENDM
PUSHIX	MACRO		
	DB	0DDH,0E5H
	ENDM
PUSHIY	MACRO		
	DB	0FDH,0E5H
	ENDM
POPIX	MACRO		
	DB	0DDH,0E1H
	ENDM
POPIY	MACRO		
	DB	0FDH,0E1H
	ENDM
EXAF	MACRO		
	DB	08H
	ENDM
EXX	MACRO		
	DB	0D9H
	ENDM
XTIX	MACRO		
	DB	0DDH,0E3H
	ENDM
XTIY	MACRO		
	DB	0FDH,0E3H
	ENDM

LDI	MACRO		
	DB	0EDH,0A0H
	ENDM
LDIR	MACRO		
	DB	0EDH,0B0H
	ENDM
LDD	MACRO		
	DB	0EDH,0A8H
	ENDM
LDDR	MACRO		
	DB	0EDH,0B8H
	ENDM
CCI	MACRO		
	DB	0EDH,0A1H
	ENDM
CCIR	MACRO		
	DB	0EDH,0B1H
	ENDM
CCD	MACRO		
	DB	0EDH,0A9H
	ENDM
CCDR	MACRO		
	DB	0EDH,0B9H
	ENDM

ADDX	MACRO	?D	
	@CHK	?D
	DB	0DDH,86H,?D
	ENDM
ADDY	MACRO	?D	
	@CHK	?D
	DB	0FDH,86H,?D
	ENDM
ADCX	MACRO	?D	
	@CHK	?D
	DB	0DDH,8EH,?D
	ENDM
ADCY	MACRO	?D	
	@CHK	?D
	DB	0FDH,8EH,?D
	ENDM
SUBX	MACRO	?D	
	@CHK	?D
	DB	0DDH,96H,?D
	ENDM
SUBY	MACRO	?D	
	@CHK	?D
	DB	0FDH,96H,?D
	ENDM
SBCX	MACRO	?D	
	@CHK	?D
	DB	0DDH,9EH,?D
	ENDM
SBCY	MACRO	?D	
	@CHK	?D
	DB	0FDH,9EH,?D
	ENDM
ANDX	MACRO	?D	
	@CHK	?D
	DB	0DDH,0A6H,?D
	ENDM
ANDY	MACRO	?D	
	@CHK	?D
	DB	0FDH,0A6H,?D
	ENDM
XORX	MACRO	?D	
	@CHK	?D
	DB	0DDH,0AEH,?D
	ENDM
XORY	MACRO	?D	
	@CHK	?D
	DB	0FDH,0AEH,?D
	ENDM
ORX	MACRO	?D	
	@CHK	?D
	DB	0DDH,0B6H,?D
	ENDM
ORY	MACRO	?D	
	@CHK	?D
	DB	0FDH,0B6H,?D
	ENDM
CMPX	MACRO	?D	
	@CHK	?D
	DB	0DDH,0BEH,?D
	ENDM
CMPY	MACRO	?D	
	@CHK	?D
	DB	0FDH,0BEH,?D
	ENDM
INRX	MACRO	?D	
	@CHK	?D
	DB	0DDH,34H,?D
	ENDM
INRY	MACRO	?D	
	@CHK	?D
	DB	0FDH,34H,?D
	ENDM
DCRX	MACRO	?D	
	@CHK	?D
	DB	0DDH,035H,?D
	ENDM
DCRY	MACRO	?D	
	@CHK	?D
	DB	0FDH,35H,?D
	ENDM

NEG	MACRO		
	DB	0EDH,44H
	ENDM
IM0	MACRO		
	DB	0EDH,46H
	ENDM
IM1	MACRO		
	DB	0EDH,56H
	ENDM
IM2	MACRO		
	DB	0EDH,5EH
	ENDM


BC	EQU	0
DE	EQU	2
HL	EQU	4
IX	EQU	4	
IY	EQU	4	
DADC	MACRO	?R	
	DB	0EDH,?R*8+4AH
	ENDM
DSBC	MACRO	?R	
	DB	0EDH,?R*8+42H
	ENDM
DADX	MACRO	?R	
	DB	0DDH,?R*8+09H
	ENDM
DADY	MACRO	?R	
	DB	0FDH,?R*8+09H
	ENDM
INXIX	MACRO		
	DB	0DDH,23H
	ENDM
INXIY	MACRO		
	DB	0FDH,23H
	ENDM
DCXIX	MACRO		
	DB	0DDH,2BH
	ENDM
DCXIY	MACRO		
	DB	0FDH,2BH
	ENDM

BIT	MACRO	?N,?R	
	DB	0CBH,?N*8+?R+40H
	ENDM
SETB	MACRO	?N,?R
	DB	0CBH,?N*8+?R+0C0H
	ENDM
RES	MACRO	?N,?R
	DB	0CBH,?N*8+?R+80H
	ENDM

BITX	MACRO	?N,?D	
	@CHK	?D
	DB	0DDH,0CBH,?D,?N*8+46H
	ENDM
BITY	MACRO	?N,?D	
	@CHK	?D
	DB	0FDH,0CBH,?D,?N*8+46H
	ENDM
SETX	MACRO	?N,?D	
	@CHK	?D
	DB	0DDH,0CBH,?D,?N*8+0C6H
	ENDM
SETY	MACRO	?N,?D	
	@CHK	?D
	DB	0FDH,0CBH,?D,?N*8+0C6H
	ENDM
RESX	MACRO	?N,?D	
	@CHK	?D
	DB	0DDH,0CBH,?D,?N*8+86H
	ENDM
RESY	MACRO	?N,?D	
	@CHK	?D
	DB	0FDH,0CBH,?D,?N*8+86H
	ENDM

JR	MACRO	?N
	DB	18H,?N-$-1
	ENDM
JRC	MACRO	?N
	DB	38H,?N-$-1
	ENDM
JRNC	MACRO	?N
	DB	30H,?N-$-1
	ENDM
JRZ	MACRO	?N
	DB	28H,?N-$-1
	ENDM
JRNZ	MACRO	?N
	DB	20H,?N-$-1
	ENDM
DJNZ	MACRO	?N
	DB	10H,?N-$-1
	ENDM

PCIX	MACRO		
	DB	0DDH,0E9H
	ENDM
PCIY	MACRO		
	DB	0FDH,0E9H
	ENDM

RETI	MACRO		
	DB	0EDH,4DH
	ENDM
RETN	MACRO		
	DB	0EDH,45H
	ENDM

INP	MACRO	?R	
	DB	0EDH,?R*8+40H
	ENDM
OUTP	MACRO	?R	
	DB	0EDH,?R*8+41H
	ENDM
INI	MACRO		
	DB	0EDH,0A2H
	ENDM
INIR	MACRO		
	DB	0EDH,0B2H
	ENDM
IND	MACRO		
	DB	0EDH,0AAH
	ENDM
INDR	MACRO		
	DB	0EDH,0BAH
	ENDM
OUTI	MACRO		
	DB	0EDH,0A3H
	ENDM
OUTIR	MACRO		
	DB	0EDH,0B3H
	ENDM
OUTD	MACRO		
	DB	0EDH,0ABH
	ENDM
OUTDR	MACRO		
	DB	0EDH,0BBH
	ENDM


RLCR	MACRO	?R	
	DB	0CBH, 00H + ?R
	ENDM
RLCX	MACRO	?D	
	@CHK	?D
	DB	0DDH, 0CBH, ?D, 06H
	ENDM
RLCY	MACRO	?D	
	@CHK	?D
	DB	0FDH, 0CBH, ?D, 06H
	ENDM
RALR	MACRO	?R	
	DB	0CBH, 10H+?R
	ENDM
RALX	MACRO	?D	
	@CHK	?D
	DB	0DDH, 0CBH, ?D, 16H
	ENDM
RALY	MACRO	?D	
	@CHK	?D
	DB	0FDH, 0CBH, ?D, 16H
	ENDM
RRCR	MACRO	?R	
	DB	0CBH, 08H + ?R
	ENDM
RRCX	MACRO	?D	
	@CHK	?D
	DB	0DDH, 0CBH, ?D, 0EH
	ENDM
RRCY	MACRO	?D	
	@CHK	?D
	DB	0FDH, 0CBH, ?D, 0EH
	ENDM
RARR	MACRO	?R	
	DB	0CBH, 18H + ?R
	ENDM
RARX	MACRO	?D	
	@CHK	?D
	DB	0DDH, 0CBH, ?D, 1EH
	ENDM
RARY	MACRO	?D	
	@CHK	?D
	DB	0FDH, 0CBH, ?D, 1EH
	ENDM
SLAR	MACRO	?R	
	DB	0CBH, 20H + ?R
	ENDM
SLAX	MACRO	?D	
	@CHK	?D
	DB	0DDH, 0CBH, ?D, 26H
	ENDM
SLAY	MACRO	?D	
	@CHK	?D
	DB	0FDH, 0CBH, ?D, 26H
	ENDM
SRAR	MACRO	?R	
	DB	0CBH, 28H+?R
	ENDM
SRAX	MACRO	?D	
	@CHK	?D
	DB	0DDH, 0CBH, ?D, 2EH
	ENDM
SRAY	MACRO	?D	
	@CHK	?D
	DB	0FDH, 0CBH, ?D, 2EH
	ENDM
SRLR	MACRO	?R	
	DB	0CBH, 38H + ?R
	ENDM
SRLX	MACRO	?D	
	@CHK	?D
	DB	0DDH, 0CBH, ?D, 3EH
	ENDM
SRLY	MACRO	?D	
	@CHK	?D
	DB	0FDH, 0CBH, ?D, 3EH
	ENDM
RLD	MACRO		
	DB	0EDH, 6FH
	ENDM
RRD	MACRO		
	DB	0EDH, 67H
	ENDM

; ffsetlu.lib 1/24/2012 dwg - 
ffgetlu	macro	
	mvi	c,RETCURR
	call	BDOS
	mov	c,a
	call	BISELDSK
	lxi	d,16+2
	dad	d
	mov	a,m
	endm
; eof - ffsetlu


; ffsetlu.lib 2/12/2012 dwg - review for use in superfmt
; ffsetlu.lib 1/24/2012 dwg - 

; enter with desired LU in A reg
ffsetlu	macro	
	enter
	push	psw
	mvi	c,RETCURR
	call	BDOS
	mov	c,a
	call	BISELDSK	; uses c parameter (drive)
	lxi	d,16+2
	dad	d
	pop	psw
	mov	m,a		; put slice into CURRENT
	mvi	c,13
	call	BDOS
	leave
	endm

; eof - ffsetlu


; ffhaslu.lib 1/22/2012 dwg - macro to detect drive with logical unit support

ffhaslu	macro	
	local	ret$false,fini
	mvi	c,RETCURR
	call	BDOS
	mov	c,a
	call	BISELDSK
	lxi	d,16		; offset to end of DPH
	dad	d		; calc offset of 1st signature byte
	mov	a,m		; pick up first sig byte which s/b 'L'
	cpi	'L'
	jnz	ret$false	; if it wasn't, indicate to caller no LU
	inx	h		; bump ptr to 2nd signature byte
	mov	a,m		; pick up second sig byte which s/b 'U'
	cpi	'U'
	jnz	ret$false	; if it wasn't, indicate to caller no LU
	mvi	a,TRUE		; otherwise indicate presence of LU support
	jmp	fini		; finish up macro
ret$false:
	mvi	a,FALSE		; prepare negative response for caller
fini:
	endm



; ffnumlu.lib 1/22/2012 dwg - macro to get number of logical units

ffnumlu	macro	
	mvi	c,RETCURR
	call	BDOS
	mov	c,a
	call	BISELDSK
	lxi	d,16+2+2	; offset to end of DPH
	dad	d		; calc offset of 1st signature byte
	mov	a,m
	endm

; eof - ffnumlu.lib



prfilnam	macro	fcb
	local	fnbuf,fnext,prfnfini
	memcpy	fnbuf,fcb+1,8
	memcpy	fnext,fcb+9,3

	lda fnext
	ani 07fh
	sta fnext

	lda fnext+1
	ani 07fh
	sta fnext+1

	lda fnext+2
	ani 07fh
	sta fnext+2

	mvi	c,9
	lxi	d,fnbuf
	call	BDOS
	
	jmp	prfnfini

fnbuf	db	0,0,0,0,0,0,0,0
	db	'.'
fnext	db	0,0,0,' $'
prfnfini:
	endm


	do$start


	jmp	around$bandata
argv	dw	prog,dat,prod,orig,ser,myname,0
prog	db	'FINDFILE.COM$'
	date
	serial
	product
	originator
	oriname
uuid	db	'107CDD27-2E4D-4340-A324-BEB13054E67B$'
around$bandata:


	crtinit
	crtclr
	crtlc	1,1
	sbanner	argv
;	version	wrnmsg,errmsg

	lda 80h
	cpi 0
	jnz	no$usage
	print 	crlf
	printf	'usage - findfile <filename>'
	jmp all$done
no$usage:


	memcpy	work$fcb,PRIFCB,32

	printf	'Finding: '
	memcpy PRIFCB,work$fcb,16

	mvi	a,'$'
	sta	PRIFCB+9
	print PRIFCB+1
	conout	'.'
	memcpy	PRIFCB,work$fcb,16
	mvi	a,'$'
	sta	PRIFCB+12
	print	PRIFCB+9
	print	crlf

	ffhaslu
	cpi	TRUE
	jz	do$lu
	memcpy	PRIFCB,work$fcb,32
	mvi	c,FOPEN
	lxi	d,PRIFCB
	call	BDOS
	cpi 	255
	jnz	single$true
	jmp	all$done
single$true:
	printf	'Found'
	jmp all$done

do$lu:
	ffgetlu
	sta	entry$lu
	;
	ffnumlu	
	sta	lu$cnt
	;
	mov	l,a
	mvi	h,0
	call	pr$d$word
	printf	' Logical Units Detected'
	print	crlf

	mvi	a,0
	sta	lu$num
loop:
	printf	'Scanning Logical Unit '
	lda	lu$num
	mov	l,a
	mvi	h,0
	call	pr$d$word
	conout  ' '

	; set the Logical Unit
	lda 	lu$num
	ffsetlu
	
	; test for the target file
	memcpy	PRIFCB,work$fcb,32
	mvi	c,FOPEN
	lxi	d,PRIFCB
	call	BDOS
	sta	retcode

	lda	retcode
	cpi	255
	jz	not$yet
	conout	CR
	prfilnam PRIFCB
	printf	' '
	printf	'Found on Logical Unit '
	lda	lu$num
	mov	l,a
	mvi	h,0
	call	pr$d$word
	conout	','
	conout	'('
	lda	drv$num
	mov	c,a
	call	BISELDSK
	lxi	b,0
	call	BISETTRK
	lxi	b,11
	call	BISETSEC
	lxi	b,buffer
	call	BISETDMA
	call	BIREAD

	mvi	a,'$'
	sta	buffer+128-8-1
	print	buffer+128-8-1-16
	conout	')'

	mvi	c,FCLOSE
	lxi	d,PRIFCB
	call	BDOS
	conout	LF
not$yet:
	conout	CR

	; Check for key hit interrupt scan
	mvi	c,11		; get console status
	caLL	BDOS
	cpi	0
	jz	nyok		; jump if no key hit
	jmp	abort		; gracefully exit loop
nyok:


	lda	lu$num
	inr	a
	sta	lu$num
	;
	lda	lu$cnt
	dcr	a
	sta	lu$cnt
	cpi	0
	jnz	loop

	printf	'               '

abort:	conout	cr
	printf	'Scan Completed                '

all$done:
	lda entry$lu
	ffsetlu

	mvi	c,RESET$DRIVE	; call to logout drive
	lxi	d,0ffh
	call	BDOS

	do$end


wrnmsg	db	'By the way, this program is newer than the BIOS$'

errmsg	db	'Sorry, this program requires a newer BIOS$'

crlf	db	CR,LF
term	db	'$'

drv$num	ds	1	; drive code of current drive
lu$cnt	ds	1	; number of slices on drive
lu$num	ds	1	; slice index
entry$lu ds	1
retcode	ds	1

work$fcb	ds	64
buffer		ds	80h


	end	start
