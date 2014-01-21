	title	'Ident - Display Program Identification'

; ident.asm 2/21/2012 dwg - review for release 2.0.0.0
; ident.asm 2/19.2012 dwg - review for release 1.5.1.0
; ident.asm 2/19/2012 dwg - remove test* & analyse & ws-shim
; ident.asm 2/18/2012 dwg - drives,map and slice become map
; ident.asm 2/14/2012 dwg - superfmt becomes multifmt
; ident.asm 2/13/2012 dwg - add disk
; ident.asm 2/12/2012 dwg - add cleardir and superfmt
; ident.asm 2/11/2012 dwg - Display the Ident of a program file

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
	maclib	cpmbdos
	maclib	cpmappl
	maclib	applvers
	maclib	banner
	maclib	printers
	maclib	dumpmac
	maclib	memory
	maclib	identity

	do$start

	idata

	sbanner	argv

	ify	'ACCESS  COM',TRUE
;	ify	'ASSIGN  COM',TRUE
;	ify	'CPMNAME COM',TRUE
;	ify	'ERASE   COM',TRUE
	ify	'FINDFILECOM',TRUE
;	ify	'HEADER  COM',TRUE
	ify	'IDENT   COM',TRUE
	ify	'SETLABELCOM',TRUE
;	ify	'MAP     COM',TRUE
;	ify	'METAVIEWCOM',TRUE
;	ify	'MULTIFMTCOM',TRUE
	ify	'NOACCESSCOM',TRUE
;	ify	'PAUSE   COM',TRUE
;	ify	'REM     COM',TRUE
;	ify	'REQ1PARMCOM',TRUE
;	ify	'STOP    COM',TRUE
;	ify	'TERMTYPECOM',TRUE
;	ify	'WRITESYSCOM',FALSE

	do$end

	end
