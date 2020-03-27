;===============================================================================
; FORMAT - DISK FORMAT UTILITY FOR ROMWBW ADAPTATION OF CP/M 2.2
;===============================================================================
;
;	AUTHOR:  WAYNE WARTHEN (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   FORMAT D:
;     ex: FORMAT		(display version and usage)
;         FORMAT /?		(display version and usage)
;         FORMAT C:		(format drive C:)
;_______________________________________________________________________________
;
; Change Log:
;_______________________________________________________________________________
;
; ToDo:
;  1) Actually implement this
;_______________________________________________________________________________
;
;===============================================================================
; Definitions
;===============================================================================
;
stksiz	.equ	$40		; Working stack size
;
restart	.equ	$0000		; CP/M restart vector
bdos	.equ	$0005		; BDOS invocation vector
;;
;stamp	.equ	$40		; loc of RomWBW CBIOS zero page stamp
;
rmj	.equ	3		; CBIOS version - major
rmn	.equ	0		; CBIOS version - minor
;
;===============================================================================
; Code Section
;===============================================================================
;
;
	.org	$100
;
	; setup stack (save old value)
	ld	(stksav),sp	; save stack
	ld	sp,stack	; set new stack
;
	; initialization
	call	init		; initialize
	jr	nz,exit		; abort if init fails
;
	; do the real work 
	call	process		; parse and process command line
	jr	nz,exit		; done if error or no action
;
exit:	; clean up and return to command processor
	call	crlf		; formatting
	ld	sp,(stksav)	; restore stack
	jp	restart		; return to CP/M via restart
	ret			; return to CP/M w/o restart
;
; Initialization
;
init:
;
	; locate start of cbios (function jump table)
	ld	hl,(restart+1)	; load address of CP/M restart vector
	ld	de,-3		; adjustment for start of table
	add	hl,de		; HL now has start of table
	ld	(bioloc),hl	; save it
;
	; check for UNA (UBIOS)
	ld	a,($FFFD)	; fixed location of UNA API vector
	cp	$C3		; jp instruction?
	jr	nz,initx	; if not, not UNA
	ld	hl,($FFFE)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$FD		; first byte of UNA push ix instruction
	jr	nz,initx	; if not, not UNA
	inc	hl		; point to next byte
	ld	a,(hl)		; get next byte
	cp	$E5		; second byte of UNA push ix instruction
	jr	nz,initx	; if not, not UNA
	ld	hl,unamod	; point to UNA mode flag
	ld	(hl),$FF	; set UNA mode flag
;
initx:
;
	xor	a
	ret
;
; Process command line
;
process:
	jr	usage
;
	xor	a
	ret
;
usage:
;
	call	crlf		; formatting
	ld	de,msgban1	; point to version message part 1
	call	prtstr		; print it
	ld	a,(unamod)	; get UNA flag
	or	a		; set flags
	ld	de,msghb	; point to HBIOS mode message
	call	z,prtstr	; if not UNA, say so
	ld	de,msgub	; point to UBIOS mode message
	call	nz,prtstr	; if UNA, say so
	call	crlf		; formatting
	ld	de,msgban2	; point to version message part 2
	call	prtstr		; print it
	call	crlf2		; blank line
	ld	de,msguse	; point to usage message
	call	prtstr		; print it
	xor	a		; signal success
	ret			; and return
;
; Print character in A without destroying any registers
;
prtchr:
	push	bc		; save registers
	push	de
	push	hl
	ld	e,a		; character to print in E
	ld	c,$02		; BDOS function to output a character
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	ret
;
; Print a zero terminated string at (HL) without destroying any registers
;
prtstr:
	push	de
;
prtstr1:
	ld	a,(de)		; get next char
	or	a
	jr	z,prtstr2
	call	prtchr
	inc	de
	jr	prtstr1
;
prtstr2:
	pop	de		; restore registers
	ret	
;
; Start a new line
;
crlf2:
	call	crlf		; two of them
crlf:
	push	af		; preserve AF
	ld	a,13		; <CR>
	call	prtchr		; print it
	ld	a,10		; <LF>
	call	prtchr		; print it
	pop	af		; restore AF
	ret
;
; Invoke CBIOS function
; The CBIOS function offset must be stored in the byte
; following the call instruction.  ex:
;	call	cbios
;	.db	$0C		; offset of CONOUT CBIOS function
;
cbios:
	ex	(sp),hl
	ld	a,(hl)		; get the function offset
	inc	hl		; point past value following call instruction
	ex	(sp),hl		; put address back at top of stack and recover HL
	ld	hl,(bioloc)	; address of CBIOS function table to HL
	call	addhl		; determine specific function address
	jp	(hl)		; invoke CBIOS
;
; Add the value in A to HL (HL := HL + A)
;
addhl:
	add	a,l		; A := A + L
	ld	l,a		; Put result back in L
	ret	nc		; if no carry, we are done
	inc	h		; if carry, increment H
	ret			; and return
;
; Jump indirect to address in HL
;
jphl:
	jp	(hl)
;
;===============================================================================
; Storage Section
;===============================================================================
;
bioloc	.dw	0		; CBIOS starting address
;
unamod	.db	0		; $FF indicates UNA UBIOS active
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
msgban1	.db	"FORMAT v0.1a for RomWBW CP/M 2.2, 02-Sep-2017",0
msghb	.db	" (HBIOS Mode)",0
msgub	.db	" (UBIOS Mode)",0
msgban2	.db	"Copyright (C) 2017, Wayne Warthen, GNU GPL v3",0
msguse	.db	"FORMAT command is not yet implemented!",13,10,13,10
	.db	"Use FDU command to physically format floppy diskettes",13,10
	.db	"Use CLRDIR command to (re)initialize directories",13,10
	.db	"Use SYSCOPY command to make disks bootable",13,10
	.db	"Use FDISK80 command to partition mass storage media",0
;
	.end
