; -----------------------------------------------------------------------------
; Copyright 2021 Dimitri Theulings
;
; This file is part of Tasty Basic.
;
; Tasty Basic is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Tasty Basic is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Tasty Basic.  If not, see <https://www.gnu.org/licenses/>.
; -----------------------------------------------------------------------------
; Tasty Basic is derived from earlier works by Li-Chen Wang, Peter Rauskolb,
; and Doug Gabbard. Refer to the source code repository for details
; <https://github.com/dimitrit/tastybasic/>.
; -----------------------------------------------------------------------------

#IFDEF CPM	
	.ORG $0C00	; ie. 3072 dec
#ELSE
	.ORG $1400	; ie. 5120 dec
#ENDIF

	LD B,0
	LD A,D
	CALL COUNT
	LD A,E
	CALL COUNT
	LD E,B
	LD D,0
	RET
COUNT:
	OR A
	RET Z
	BIT 0,A
	JR Z,NEXT
	INC B
NEXT:
	SRL A
	JR COUNT

	.END