; labelib.asm 2/22/2012 dwg - label library function implementation
; label.asm   2/11/2012 dwg - make ident compliant
; label.asm   2/11/2012 dwg - begin 1.6 enhancements
; label.asm   2/04/2012 dwg - use new macros for benefits
; label.asm   1/20/2012 dwg - label a drive or slice

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


	maclib	portab
	maclib	globals
	maclib	cpmbios
	maclib	cpmbdos
	maclib	bioshdr
	maclib	hardware
	maclib	z80
	maclib	memory
;	maclib	applvers
;	maclib	cpmappl
	maclib	printers
	maclib	metadata
;	maclib	banner
	maclib	stdlib
;	maclib	ffhaslu
;	maclib	identity



	cseg

	public	x$label
x$label:
	mov	a,c
	sta	drive$num

	get$off
	mov	a,h
	ora	l
	jnz	off$ok
	printf	'Sorry, you can only label drives with reserved tracks'
	jmp	main$exit
off$ok:

	lda	drive$num
	mov	c,a
	lxi	h,buffer
	call	x$g$meta

	lda DEFBUF ! mov c,a
	cpi 0      ! jnz x$lab2

;	; Interactive label functionality here...

prompt:
	; signature exists so label should be displayable

	print old$lbl

;	print label
	lxi	h,buffer
	lxi	d,meta$label
	dad	d
	push	h
	pop	d
	mvi	c,PRINTSTR
	call	BDOS

	print crlf
	print new$lbl

	mvi c,READ$CON$BUF
	lxi d,rcbuff
	call BDOS
	lda rclen
	cpi 0
	jnz length$ok
	jmp main$exit
length$ok:
	inr a
	sta DEFBUF
	mvi a,' '
	sta DEFBUF+1
	mov c,a
	mvi b,0
	lxi h,rcdata
	lxi d,DEFBUF+2
	ldir

	print crlf

	lda	drive$num
	mov	c,a
	; fall through to code below


;;; not$interactive:

	public	x$lab2
x$lab2:
; This routine can be used interactively or non-interactively.
; You can set up the default buffer at 80h and call x$lab2,
; or you can call x$label and it will interactively redo the label.
;
	mov	a,c
	sta	drive$num


	lxi	h,buffer
	lxi	d,meta$label
	dad	d
	mvi	a,' '
	lxi	b,meta$label$len	; max length of label
	call	x$memset

	lda DEFBUF	; pick up length of command tail
	cpi 18		; compare with max size of label
	jc lenok	; jump if size is within limits
	mvi a,17	; specify maximum size
	sta DEFBUF	; and poke into default buffer size byte

lenok:	lda DEFBUF	; pick up command tail size byte
	dcr a		; decrement

	mov c,a		; move to c reg as counter
	mvi b,0

	lxi	h,buffer
	lxi	d,meta$label
	dad	d
	xchg
	lxi 	h,DEFBUF+2	; set source index for move
	ldir

	lxi	h,buffer
	lxi	d,meta$term
	dad	d
	mvi 	a,'$' 
	mov	m,a

	lda	drive$num
	mov	c,a

	lxi	h,buffer
	call	x$u$meta
	cpi	FAILURE
	jz	write$prot$err

	lxi	h,buffer
	call	x$p$meta

	print suc$msg

	jmp main$exit

write$prot$err:
	print wr$prot$msg
	jmp main$exit

readerr: 
	print rd$err$msg
	jmp main$exit

writeerr: 
	print wr$err$msg
	jmp main$exit

dontboth: 
	print usage$msg

main$exit:
	ret

	dseg

suc$msg    db 'Label Written Successfully$'
rd$err$msg db 'Sorry, cannot read label sector$'
wr$err$msg db 'Sorry, cannot write label sector$'
wr$prot$msg db 'Sorry, metadata is write protected$'
usage$msg  db 'usage - label <label>$'
ver$msg    db 'Sorry, requires RomWBW or NuBios v1.5$'
def$label  db 'Unlabeled       ',0
init$msg   db 'Label initialized$'
old$lbl    db 'Old Label: $'
new$lbl	   db 'New Label: $'	
copr$msg   db 'Copyright (C) 2012 Douglas Goodall$'
lic$msg    db 'Program licensed under the GPL v3$'

crlf	db	CR,LF
term	db	'$'


drive$num ds 1

rcbuff	db	MAX$LABEL
rclen	db	0
rcdata	ds	MAX$LABEL

buffer	ds	128




	end	start
