;
;=============================================================================
; HWMON.ASM - BARE METAL HARDWARE MONITOR
;=============================================================================
;
; THIS IS JUST A STUB FOR NOW.
;
#INCLUDE "std.asm"
;
; MONITOR WILL BE LOADED AT HWMON_LOC
;
	.ORG	HWMON_LOC
	;;;.ORG	0
;
	LD	HL,STR_NOTIMPL		; POINT TO STRING
	CALL	PSTR			; AND SEND TO CONSOLE
;
	; NOT IMPLEMENTED, WARM BOOT TO RETURN TO BOOT LOADER
	LD	B,BF_SYSRESET		; SYSTEM RESTART
	LD	C,BF_SYSRES_WARM	; WARM START
	CALL	$FFF0			; CALL HBIOS
;
;=======================================================================
; UTILITY FUNCTIONS
;=======================================================================
;
; PRINT STRING AT HL ON CONSOLE, NULL TERMINATED, HL INCREMENTED
;
PSTR:
	PUSH	AF			; SAVE AF
PSTR1:
	LD	A,(HL)			; GET NEXT CHARACTER
	INC	HL			; BUMP POINTER REGARDLESS
	OR	A			; SET FLAGS
	JR	Z,PSTR2			; DONE IF NULL
	CALL	COUT			; DISPLAY CHARACTER
	JR	PSTR1			; LOOP TILL DONE
PSTR2:
	POP	AF			; RESTORE AF
	RET				; RETURN
;
; OUTPUT CHARACTER FROM A
;
COUT:	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	B,BF_CIOOUT
	LD	C,CIO_CONSOLE
	LD	E,A
	;RST	08
	CALL	$FFF0
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
;=======================================================================
; STORAGE
;=======================================================================
;
STR_NOTIMPL	.DB	13,10,13,10,"*** Not Implemented ***",13,10,0
;
; IT IS CRITICAL THAT THE FINAL BINARY BE EXACTLY HWMON_SIZ BYTES.
; THIS GENERATES FILLER AS NEEDED.  IT WILL ALSO FORCE AN ASSEMBLY
; ERROR IF THE SIZE EXCEEDS THE SPACE ALLOCATED.
;
SLACK	.EQU	(HWMON_END - $)
;;;SLACK	.EQU	(HWMON_SIZ - $)
;
#IF (SLACK < 0)
	.ECHO	"*** HWMON IS TOO BIG!!!\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF
;
	.FILL	SLACK,$00
	.ECHO	"Hardware Monitor space remaining: "
	.ECHO	SLACK
	.ECHO	" bytes.\n"
;
	.END
