;
;==================================================================================================
;   HBIOS ENVIRONMENT CONFIG VALUE EXPORT TOOL
;==================================================================================================
;
; Do we need a private stack???
;
#include "std.asm"
;
; Macro to make it simple to print a config value
;
#define	prtval(tag,val) \
#defcont \	call	PREFIX
#defcont \	call	PRTSTRD
#defcont \	.text	tag
#defcont \	call	PRTEQ
#defcont \	ld	hl,val
#defcont \	call	PRTDEC
#defcont \	call	EOL
;
; Program starts here
;
	.org	$100			; Normal CP/M start address
;
; Print all desired config values...
;
	prtval("ROMSIZE$", ROMSIZE)
	prtval("CPUFAM$", CPUFAM)
;
	ret
;
; Output correct prefix for command/shell
;
PREFIX:
#ifdef CMD
	call	PRTSTRD
	.text	"set $"
#endif
	ret
;
; Output an equal sign
;
PRTEQ:
	ld	a,'='
	call	COUT
	ret
;
; Output end-of-line.  Handles differences between
; DOS/Windows and Unix.
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