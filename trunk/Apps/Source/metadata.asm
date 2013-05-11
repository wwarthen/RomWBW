; metadata.asm 7/30/2012 dwg - set c=0 for BIOS WRITE calls per Wayne
; metadata.asm 2/17/2012 dwg - review for release 1.5.1.0
; metadata.asm 2/11/2012 dwg - review for release 1.5
; metadata.asm 2/ 4/2012 dwg - metadata library implementation

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
	maclib	cpmbios
	maclib	cpmbdos
	maclib	memory		; has x$memset
	maclib	applvers	; has A$RMJ, A$RMN, A$RUP, A$RTP
	maclib	printers
	maclib	stdlib		; SUCCESS and FAILURE

; metadata.lib 1/31/2012 dwg - macros to manipulate drive metadata
;
; update$meta       buffer	|	x$u$meta hl -> buffer
;   init$meta	    buffer	|	x$i$meta hl -> buffer
;    get$meta drive,buffer	| 	x$g$meta hl -> buffer, c = drivenum
;    put$meta drive,buffer	| 	x$p$meta hl -> buffer, c = drivenum
;   prot$meta drive		| 	x$pr$meta c = drivenum
; unprot$meta drive		|	x$un$meta c = drivenum
;
;-------------------------------------------

;meta$debug	equ	TRUE
meta$debug	equ	FALSE

meta$sig5a	equ	0
meta$siga5	equ	1
meta$prot	equ	128-8-1-16-7
meta$updates	equ	128-8-1-16-6
meta$rmj	equ	128-8-1-16-4
meta$rmn	equ	128-8-1-16-3
meta$rup	equ	128-8-1-16-2
meta$rtp	equ	128-8-1-16-1
meta$label	equ	128-8-1-16
meta$term	equ	128-8-1
meta$info$loc	equ	128-8
meta$cpm$loc	equ	128-6
meta$dat$end	equ	128-4
meta$cpm$ent	equ	128-2
meta$label$len	equ	meta$term-meta$label

;-----------------------------
crlf	db	CR,LF,'$'
;-----------------------------

	page

	public	x$u$meta
x$u$meta:
	shld	x$u$bufptr

;	lhld	x$u$bufptr
	lxi	d,meta$prot
	dad	d
	mov	a,m
	cpi	TRUE		; is metadata write protected
	jz	x$u$proterr	; if so go around update code

	; increment the update count
	lhld	x$u$bufptr
	lxi	d,meta$updates
	dad	d
	mov	e,m	; pick up LO byte into E
	inx	h
	mov	d,m	; pick up HO byte into D
	inx	d	; increment DE
	mov	m,d
	dcx	h
	mov	m,e

	; update last written version quad
	lhld	x$u$bufptr
	lxi	d,meta$rmj
	dad	d
	mvi	a,A$RMJ
	mov	m,a
	inx	h
	mvi	a,A$RMN
	mov	m,a
	inx	h
	mvi	a,A$RUP
	mov	m,a
	inx	h
	mvi	a,A$RTP
	mov	m,a

	lhld	x$u$bufptr
	lxi	d,meta$term
	dad	d
	mov	a,m
	cpi	'$'
	jz	x$u$end

	lhld	x$u$bufptr
	lxi	d,meta$label
	dad	d
	mvi	a,' '
	mvi	c,16
	call	x$memset

	lhld	x$u$bufptr
	lxi	d,meta$term
	dad	d
	mvi	a,'$'
	mov	m,a

x$u$end:
	mvi	a,SUCCESS
	ret

x$u$proterr:
	mvi	a,FAILURE
	ret

x$u$bufptr ds 2


;-----------------------------

	page
	
	public	x$i$meta
x$i$meta:
	shld	x$i$bufptr

	lhld	x$i$bufptr
	lxi	d,meta$sig5a
	dad	d
	mvi	a,05ah
	mov	m,a
	inx	h
	mvi	a,0a5h
	mov	m,a

	lhld	x$i$bufptr
	lxi	d,meta$prot
	dad	d
	mvi	a,FALSE
	mov	m,a

	lhld	x$i$bufptr
	lxi	d,meta$updates
	dad	d
	mvi	a,0
	mov	m,a
	inx	h
	mov	m,a

	lhld	x$i$bufptr
	lxi	d,meta$label
	dad	d		; hl -> dest
	mvi	a,' '
	mvi	c,meta$label$len
	call	x$memset

	lhld	x$i$bufptr
	lxi	d,meta$term
	dad	d
	mvi	a,'$'
	mov	m,a

	lhld	x$i$bufptr
	lxi	d,meta$updates
	dad	d
	mvi	a,0
	mov	m,a
	inx	h
	mov	m,a

	lhld	x$i$bufptr
	call	x$u$meta

	ret

x$i$bufptr	ds	2

;-------------------------------------------

	page

	public	x$g$meta
x$g$meta;

	shld	x$g$bufptr	; entry hl has bufptr
	mov	a,c		; entry c  has drivenum
	sta	x$g$drivenum

;	lda	x$g$drivenum
	mov	c,a
	call	BISELDSK

	lxi	b,0
	call	BISETTRK

	lxi	b,11
	call	BISETSEC

	lhld	x$g$bufptr
	push	h
	pop	b
	call	BISETDMA

	call	BIREAD

	lhld	x$g$bufptr
	lxi	d,meta$siga5
	dad	d
	mov	a,m
	cpi	0a5h
	jnz	x$g$needs$init
	
	lhld	x$g$bufptr
	lxi	d,meta$sig5a
	dad	d
	mov	a,m
	cpi	05ah
	jnz	x$g$needs$init

	jmp	x$g$fini

x$g$needs$init:

	lhld	x$g$bufptr
	call	x$i$meta

	mvi	c,0		; default to 0 per Wayne
	call	BIWRITE

x$g$fini:	
	mvi	c,13
	call	BDOS
	ret

x$g$bufptr	ds	2
x$g$drivenum	ds	1

;-----------------------------------

	page

	public	x$p$meta
x$p$meta:
	shld	x$p$bufptr
	mov	a,c
	sta	x$p$drivenum

	IF meta$debug eq TRUE
	conout	'x'
	conout	'$'
	conout	'p'
	conout	'$'
	printf	'meta called, drive='
	lda	x$p$drivenum
	mov	l,a
	mvi	h,0
	call	pr$d$word
	printf	', buffer='
	lhld	x$p$bufptr
	call	pr$h$word
	print	crlf
	ENDIF

	; increment the update count
	lhld	x$p$bufptr	; hl -> buffer
	lxi	d,meta$updates	; de = offset to updates word
	dad	d		; hl -> updates word
	mov	e,m		; e = LO byte of updates
	inx	h		; hl -> HO byte
	mov	d,m		; d = HO byte of updates
	inx	d		; increment DE (updates)
	mov	m,d		; put back HO byte
	dcx	h		; back up ptr
	mov	m,e		; put back LO byte

	; update last written version quad
	lhld	x$p$bufptr
	lxi	d,meta$rmj
	dad	d
	mvi	a,A$RMJ
	mov	m,a
	inx	h
	mvi	a,A$RMN
	mov	m,a
	inx	h
	mov	a,A$RUP
	mov	m,a
	inx	h
	mvi	a,A$RTP
	mov	m,a

	lhld	x$p$bufptr
	lxi	d,meta$prot
	dad	d
	mov	a,m
	cpi	TRUE		; if metadata is write protected
	jz	x$p$fini	; jump around update code
	lda	x$p$drivenum
	mov	c,a	
	call	BISELDSK
	lxi	b,0
	call	BISETTRK
	lxi	b,11
	call	BISETSEC
	lhld	x$p$bufptr
	push	h
	pop	b
	call	BISETDMA

	mvi	c,0		; default to 0 per Wayne
	call	BIWRITE

	IF meta$debug eq TRUE
	printf	'return from BIWRITE is '
	mov	l,a
	mvi	h,0
	call	pr$h$word
	print	crlf
	ENDIF

x$p$fini:
	ret

x$p$bufptr	ds	2
x$p$drivenum	ds	1

;-----------------------

	page

	public	x$pr$meta
x$pr$meta:
	mov	a,c
	sta	x$pr$drivenum

	IF meta$debug eq TRUE
	conout	'x'
	conout	'$'
	printf	'pr'
	conout	'$'
	printf	'meta called, drive='
	lda	x$pr$drivenum
	mov	l,a
	mvi	h,0
	call	pr$d$word
	print	crlf
	ENDIF

	lda	x$pr$drivenum
	mov	c,a
	call	BISELDSK
	lxi	b,0
	call	BISETTRK
	lxi	b,11
	call	BISETSEC
	lxi	b,x$pr$buffer
	call	BISETDMA
	call	BIREAD

	IF meta$debug eq TRUE
	printf	'return from BIREAD is '
	mov	l,a
	mvi	h,0
	call	pr$h$word
	print	crlf
	ENDIF

	lxi	h,x$pr$buffer
	lxi	d,meta$prot
	dad	d
	mvi	a,TRUE
	mov	m,a


	lxi	h,x$pr$buffer
	lxi	d,meta$updates
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	inx	d
	mov	m,d
	dcx	h
	mov	m,e

	lda	x$pr$drivenum
	mov	c,a
	call	BISELDSK
	lxi	b,0
	call	BISETTRK
	lxi	b,11
	call	BISETSEC
	lxi	b,x$pr$buffer
	call	BISETDMA
	
	mvi	c,0		; default to 0 per Wayne
	call	BIWRITE

	IF meta$debug eq TRUE
	printf	'return from BIWRITE is '
	mov	l,a
	mvi	h,0
	call	pr$h$word
	print	crlf
	ENDIF

	mvi	c,13
	call	BDOS

	ret


x$pr$drivenum	ds	1
x$pr$buffer	ds	128

;-----------------------

	page

	public	x$un$meta
x$un$meta:
	mov	a,c
	sta	x$un$drivenum

	IF meta$debug eq TRUE
	conout	'x'
	conout	'$'
	printf	'un'
	conout	'$'
	printf	'meta called, drive='
	lda	x$un$drivenum
	mov	l,a
	mvi	h,0
	call	pr$d$word
	print	crlf
	ENDIF

	lda	x$un$drivenum
	mov	c,a
	call	BISELDSK
	lxi	b,0
	call	BISETTRK
	lxi	b,11
	call	BISETSEC
	lxi	b,x$un$buffer
	call	BISETDMA
	call	BIREAD

	IF meta$debug eq TRUE
	printf	'return from BIREAD is '
	mov	l,a
	mvi	h,0
	call	pr$h$word
	print	crlf
	ENDIF

	lxi	h,x$un$buffer
	lxi	d,meta$prot
	dad	d
	mvi	a,FALSE
	mov	m,a


	lxi	h,x$un$buffer
	lxi	d,meta$updates
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	inx	d
	mov	m,d
	dcx	h
	mov	m,e

	lda	x$un$drivenum
	mov	c,a
	call	BISELDSK
	lxi	b,0
	call	BISETTRK
	lxi	b,11
	call	BISETSEC
	lxi	b,x$un$buffer
	call	BISETDMA
	
	mvi	c,0		; default to 0 per Wayne
	call	BIWRITE

	IF meta$debug eq TRUE
	printf	'return from BIWRITE is '
	mov	l,a
	mvi	h,0
	call	pr$h$word
	print	crlf
	ENDIF

	mvi	c,13
	call	BDOS

	ret

x$un$drivenum	ds	1
x$un$buffer	ds	128

;-----------------------

; eof - metadata.asm
