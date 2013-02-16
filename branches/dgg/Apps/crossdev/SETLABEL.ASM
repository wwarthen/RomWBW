; setlabel.asm 2/22/2012 dwg - use new labelib macro library for labels
; label.asm    2/11/2012 dwg - make ident compliant
; label.asm    2/11/2012 dwg - begin 1.6 enhancements
; label.asm    2/04/2012 dwg - use new macros for benefits
; label.asm    1/20/2012 dwg - label a drive or slice

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
	maclib	stdlib		; SUCCESS & FAILURE
	maclib	cpmbios
	maclib	cpmbdos
	maclib	bioshdr
	maclib	applvers
	maclib	cpmappl
	maclib	banner
	maclib	identity
	maclib	labelib
	maclib	version

	cseg

	do$start	; begin application housekeeping

	jmp	around$bandata
argv	dw	prog,dat,prod,orig,ser,myname,0
prog	db	'SETLABEL.COM$'
	date
	serial
	product
	originator
	oriname
uuid	db	'A3EEDB99-2CC0-483E-8176-A67118936E32$'
around$bandata:

	sbanner	argv

;	version	warn$msg,error$msg

	mvi	c,RETCURR
	call	BDOS
	sta	drive$num

	mov	c,a
	get$off
	mov	a,h
	ora	l
	jnz	off$ok
	printf	'Sorry, you can only label drives with reserved tracks'
	jmp	main$exit
off$ok:

	lda	drive$num	; using the default drive number
	mov	c,a		; (presented in the C register)
	call	x$label		; call the actual code in labelib.asm

main$exit:
	do$end			; finish up application housekeeping


	dseg

drive$num ds 1

; here are the two strings required for the version call
warn$msg  db 'The version number of this program '
	  db 'is not exactly the same as the BIOS',CR,LF,'$'
error$msg db 'Sorry, requires RomWBW or NuBios v2.0'

crlf	db	CR,LF,'$'

	end	start

