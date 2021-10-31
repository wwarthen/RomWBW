
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

CIODEV_CONSOLE			.equ 0d0h
BF_CIOIN			.equ 00h 			; character input
BF_CIOOUT			.equ 01h			; character output
BF_CIOIST			.equ 02h 			; character input status
BF_SYSRESET			.equ 0f0h			; restart system
BF_SYSRES_WARM			.equ 01h			; warm start

;*************************************************************
;
; THE FOLLOWING NEED MUST BE SYNCED WITH STD.ASM SO ROMLDR
; KNOWS WHERE THIS EXECUTES AT
;
;*************************************************************
;
#ifndef PLATFORM
TBC_LOC				.equ $0a00
#endif
TBC_SIZ				.equ $0a00
TBC_END				.equ TBC_LOC + TBC_SIZ
;
;*************************************************************

USRPTR_OFFSET			.equ 09feh
INTERNAL_OFFSET			.equ 0c00h
TEXTEND_OFFSET			.equ 07dffh
STACK_OFFSET			.equ 07fffh

bye:
				call endchk			; ** Reboot **
				ld b,BF_SYSRESET		; system restart
				ld c,BF_SYSRES_WARM		; warm start
				jp 0fff0h			; does not return!
putchar:
				push af
				push bc
				push de
				push hl
								; output character to console via hbios
				ld e,a				; output char to e
				ld c,CIODEV_CONSOLE		; console unit to c
				ld b,BF_CIOOUT			; hbios func: output char
				rst 08h				; hbios outputs character

				pop hl
				pop de
				pop bc
				pop af
				ret
haschar:
				push bc
				push de
				push hl
								; get console input status via hbios
				ld c,CIODEV_CONSOLE		; console unit to c
				ld b,BF_CIOIST			; hbios func: input status
				rst 08h				; hbios returns status in a

				pop hl
				pop de
				pop bc
				ret

getchar:
				push bc
				push de
				push hl
								; input character from console via hbios
				ld c,CIODEV_CONSOLE		; console unit to c
				ld b,BF_CIOIN			; hbios func: input char
				rst 08h				; hbios reads charactdr
				ld a,e				; move character to a for return
								; restore registers (af is output)
				pop hl
				pop de
				pop bc
				ret
