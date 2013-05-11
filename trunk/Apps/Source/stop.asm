; stop.asm 7/19/2012 dwg - for 2.0.0.0 B22
; stop.asm 2/11/2012 dwg - review for release 1.5.1.0
; stop.asm 2/11/2012 dwg - review for release 1.5
; stop.asm 1/28/2012 dwg - update for 1.4.1.0
; stop.asm 1/22/2012 dwg - review for release 1.4
; stop.asm 1/20.2012 dwg - stop submit file activity

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
	maclib	banner
	maclib	cpmbdos
	maclib	cpmappl
	maclib	applvers
	maclib	printers
	maclib	version
	maclib	z80
	maclib	identity

	cseg

	do$start

	jmp	around$bandata
argv	dw	prog,dat,prod,orig,ser,myname,0
prog	db	'STOP.COM    $'
	date
	serial
	product
	originator
	oriname
uuid	db	'4A7BABA3-D6F3-4AAC-9C02-4F92CD52F91E$'
around$bandata:

	sbanner	argv

	mvi	c,FDELETE
	lxi	d,del$fcb
	call	BDOS

	printmsg 'Submit file halted'

	do$end

	dseg

	newfcb	del$fcb,1,'$$$     SUB'

crlf	db	CR,LF
term	db	'$'

	end	start

