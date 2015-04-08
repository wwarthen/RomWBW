;  PROGRAM:  SYSNDR.ASM
;  AUTHOR:  RICHARD CONN
;  VERSION:  1.0
;  DATE:  24 FEB 84

;
;	SYSNDR.ASM sets up a memory-based named directory file suitable
; for loading by Z3LDR.  It does this by including SYSNDR.LIB.
;
	MACLIB	SYSNDR

	org	100h

	SYSNDR		; Invoke macro

	end
