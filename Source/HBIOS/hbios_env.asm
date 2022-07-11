;
;==================================================================================================
;   HBIOS ENVIRONMENT EXPORT
;==================================================================================================
;
; Do we need a private stack???
; Use a macro do dump each variable?
;
#include "std.asm"
;
	.org	$100			; Normal CP/M start address
;
	; Dump ROMSIZE
	call	PRTSTRD
#ifdef CMD
	.text	"set ROMSize=$"
#endif
#ifdef BASH
	.text	"ROMSIZE=$"
#endif
	ld	hl,ROMSIZE
	call	PRTDEC
	call	EOL
;
	ret				; Return
;
; Output end-of-line.  Handles differences between
; Windows CMD file and Bash.
;
EOL:
#ifdef CMD
	ld	a,13
	call	COUT
#endif
	ld	a,10
	call	COUT
	ret

;
; Print a single character from register A.
; This routine is required by the utility routines included below.
;
COUT:
	push	af
	push	bc
	push	de
	push	hl
	ld	e,a
	ld	c,2
	call	$0005
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
; Include the utility routines
;
#include "util.asm"
;
	.end