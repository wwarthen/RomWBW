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

USRPTR_OFFSET			.equ 0afeh
INTERNAL_OFFSET			.equ 0c00h
TEXTEND_OFFSET			.equ 07cffh
STACK_OFFSET			.equ 07effh

BDOS				.equ 05h				; standard cp/m entry
DCONIO				.equ 06h				; direct console I/O
INPREQ				.equ 0ffh				; console input request
TERMCPM				.equ 0
OPENF				.equ 0fh				; file open
CLOSEF				.equ 10h				; file close
DELETEF				.equ 13h				; file delete
READF				.equ 14h				; read file record
WRITEF				.equ 15h				; write file record
MAKEF				.equ 16h				; make new file
SETDMA				.equ 1ah				; set DMA address
EOF				.equ 1ah				; EOF marker
DMAOFF				.equ 1ah				; set DMA address pointer
FCB				.equ 5ch				; file control block address
DMA				.equ 80h				; disk buffer address
BUFSIZE				.equ 80h				; disk buffer size

; FILE CONTROL BLOCK DEFINITIONS
FCBDN				.equ FCB+0 				; disk name
FCBFN				.equ FCB+1 				; file name
FCBFT				.equ FCB+9 				; disk file type (3 chars)
FCBRL				.equ FCB+12				; file's current reel number
FCBRC				.equ FCB+15				; file's record count (0 to 128)
FCBCR				.equ FCB+32				; current (next) record
FCBLN				.equ FCB+33				; FCB length
FTYPE				.db "TBA"				; tasty basic file type

haschar:	
				push	bc
				push	de
				ld	c,DCONIO			; direct console i/o
				ld	e,INPREQ			; input request
				call	BDOS				; any chr typed?
				pop	de				; if yes, (a)<--char
				pop	bc				; else    (a)<--00h (ignore chr)
				or	a				
				ret
;
putchar:					
				push	bc
				push	de
				push	af
				push	hl
				ld	c,DCONIO			; direct console i/o
				ld	e,a				; output char (a)
				call	BDOS
				pop	hl
				pop	af
				pop	de
				pop	bc
				ret
load:				
				ld hl,textbegin				; ** load **
				ld (textunfilled),hl			; clear program text area
				call clrvars				; and variables
				call fname				; get filename
				call fopen				; and open file for reading
				ld de,DMA
				ld c,SETDMA				; point dma to default
				call BDOS

lo1:
				ld de,FCB				; and read record
				ld c,READF
				call BDOS
				or a					; are we at EOF?
				jr nz,lo3				; yes, all done
				ld b,BUFSIZE				; no, copy from io buffer
				ld de,DMA				; to text buffer
				ld hl,(textunfilled)
lo2:
				ld a,(de)				; get char from buffer
				cp 1ah					; is it EOF?
				jr z,lo3				; yes, all done
				ld (hl),a				; copy char to text area
				inc hl					; and update pointers
				inc de
				ld (textunfilled),hl
				dec b					; end of record?			
				jr z,lo1				; yes, so try next record
				jr lo2					; no, copy next char
lo3:
				jp rstart
save:
				call fname				; ** save **
				ld de,textbegin				; check there is a program
				ld hl,(textunfilled)			; in memory
				sbc hl,de
				jr nz,sa1				; yes, try to save it
				jp qhow					; no, nothing to be done
sa1:
				call fdel				; remove any existing file
				call fmake				; open new file for writing
				ld de,textbegin				; initialise text ptr
sa2:
				push de					; save current text ptr
				ld hl,(textunfilled)
				ld (hl),EOF				; set EOF marker
				sbc hl,de				; are we done?
				jr c,sa4
				ld c,SETDMA				; point dma to text
				call BDOS
				ld de,FCB				; write record
				ld c,WRITEF
				call BDOS
				or a					; all good?
				jr z,sa3				; yes, try next
				jp qsorry				; no, something bad happened
sa3:
				pop hl					; update text ptr
				ld de,BUFSIZE
				add hl,de
				ex de,hl
				jr sa2
sa4: 
				call fclose				; and close file				jp rstart
				jp rstart
fname:
				call testc				; check filename
				.db 22h					; is first char a double quote
				.db fn4-$-1				; no, so fail
				ld hl,FCBFN				; start configuring fcb
				ld b,22h
				ld c,8					; max filename length
fn1:
				ld a,(de)
				inc de			   		; bump pointer
				cp b					; double quote?
				jr z,fn2
				ld (hl),a				; copy into fcb
				inc hl
				dec c					; check filename length
				jp z,qhow				; too long
				jr fn1
fn2:
				call endchk
				ld a,20h				; clear any remaining chars
				ld (hl),a				; in filename
				inc hl
				dec c
				jr nz,fn2
				ld b,3					; set file type
				ld hl,FTYPE
				ld de,FCBFT
fn3:
				ld a,(hl)
				ld (de),a
				inc hl
				inc de
				dec b
				jr nz,fn3
				xor a
				ld (FCBCR),a				; clear current record
				ret
fn4:
				jp qwhat
fopen:
				ld de,FCB				; open file		
				ld c,OPENF
				jr fexec
fclose:
				ld de,FCB				; close file
				ld c,CLOSEF
				jr fexec
fmake:
				ld de,FCB				; create new file
				ld c,MAKEF
fexec:
				call BDOS
				inc a					; did operation fail?
				ret nz					; no, all good
				jp qhow					; something bad happened
fdel:
				ld de,FCB				; delete file
				ld c,DELETEF
				jp BDOS					; ignore any errors			
bye:
				ld c,TERMCPM				; does not return!
				jp BDOS					