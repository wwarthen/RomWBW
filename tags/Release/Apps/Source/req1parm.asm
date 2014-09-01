; req1parm.asm 7/19/2012 dwg - for 2.0.0.0 B22
; req1parm.asm 2/11/2012 dwg - review for release 1.5.1.0
; req1parm.asm 2/11/2012 dwg - review for release 1.5
; req1parm.asm 2/05/2012 dwg - update for macro usage
; req1parm.asm 1/28/2012 dwg - update for 1.4.1.0
; req1parm.asm 1/22/2012 dwg - require one parameter or stop submit

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
	maclib	cpmappl
	maclib	applvers
	maclib	printers
	maclib	banner
	maclib	identity

	cseg

	do$start

	jmp	around$bandata
argv	dw	prog,dat,prod,orig,ser,myname,0
prog	db	'REQ1PARM.COM$'
	date
	serial
	product
	originator
	oriname
uuid	db	'B9772224-F47A-4309-BECA-9D7AB1B7EDE7$'
around$bandata:

	sbanner	argv

	lda	80h
	cpi 	0
	jnz	fini

	printmsg 'Sorry, submit file requires a parameter'

	mvi	c,FDELETE
	lxi	d,del$fcb
	call	BDOS

fini:
	do$end

	dseg

	newfcb	del$fcb,1,'$$$     SUB'

crlf	db	CR,LF
term	db	'$'

	end	start
