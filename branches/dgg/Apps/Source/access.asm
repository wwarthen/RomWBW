; access.asm 7/19/2012 dwg - for 2.0.0.0 B22
; access.com 2/17/2012 dwg - review for release 1.5.1.0
; access.asm 2/11/2012 dwg - make ident compliant
; access.com 2/07/2012 dwg - review for release 1.5
; access.com 2/05/2012 dwg - adjust for new macros
; access.asm 1/30/2012 dwg - use new do$start and do$end macros
; access.asm 1/28/2012 dwg - assure file exists from within submit file

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

;----------------------------------------------------------------------
	maclib	portab
	maclib	globals
	maclib	cpmbdos
	maclib	printers
	maclib	banner
	maclib	applvers
	maclib	z80
	maclib	memory
	maclib	version
	maclib	cpmappl
	maclib	banner
;-----------------------

	do$start

	jmp	around$bandata
argv	dw	prog,dat,prod,orig,ser,myname,0
prog	db	'ACCESS.COM  $'
	date
	serial
	product
	originator
	oriname
uuid	db	'08D4953E-B6F4-4673-990C-7E17A0A299BD$'
around$bandata:

	sbanner	argv

	lda 	80h	; pick up the command tail length provided by CCP
	cpi 	0	; were there any parameters given?
	jnz	no$usage	; If not, go around
	printf	'usage - access <filename>'
	jmp do$exit
no$usage:

	memcpy	work$fcb,PRIFCB,32	; Save initial default FCB from CCP

	printf	'Checking: '

	mvi	a,'$'			; place a terminating dollar sign
	sta	PRIFCB+9		; at the end of the filname field
	print PRIFCB+1			; and print the filename portion

	conout	'.'			; print the seperating dot

	memcpy	PRIFCB,work$fcb,16	; get a fresh copy of the initial FCB
	mvi	a,'$'			; place a terminating dollar sign
	sta	PRIFCB+12		; at the end of the filetype field
	print	PRIFCB+9		; and print the filetype
	print	crlf			; followed by a CR and LF

	memcpy	PRIFCB,work$fcb,32	; restore the initial FCB

	mvi	c,FOPEN			; Try to open the given filename
	lxi	d,PRIFCB		; using the primary default FCB
	call	BDOS			; with a BDOS call
	cpi 	255			; Test for Open Failure (255)
	jnz	done			; jump if file existed

	mvi	c,FDELETE		; Delete the A:$$$.SUB file
	lxi	d,del$fcb		; using an alternative FCB
	call	BDOS

	printf	'Submit file terminated due to missing file$'

	jmp 	do$exit			; Go to the one true exit point

done:
	printf	'File found, Submit may proceed'
do$exit:
	do$end

	newfcb	del$fcb,1,'$$$     SUB'

work$fcb ds	36	; A place to save a copy of the default FCB on entry

crlf	db	CR,LF		; a dollar sign terminated CR and LF
term	db	'$'		; a general purpose terminating character

	end	start

; eof - access.asm

