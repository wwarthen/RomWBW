* SYSTEM SEGMENT:  SYSTEM.ENV
* AUTHOR:  RICHARD CONN

; PROGRAM:  SYSENV.ASM
; AUTHOR:  Richard Conn
; Version:  1.0
; Date:  22 Feb 84
; Previous Versions:  None

;
;	SYSENV is the definition for my ZCPR3 environment, and it is loaded
; as my ZCPR3 Environment Descriptor by Z3LDR.  SYSENV is named to SYS.ENV
; after assembly to permit this.
;

;
;  Environment Definitions
;
	MACLIB	Z3BASE
	MACLIB	SYSENV

;
;  Include Environment Descriptor
;
	org	100H		; origin
	jmp	0		; leading JMP

	SYSENV

	end
