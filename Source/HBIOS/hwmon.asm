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
;
; IT IS CRITICAL THAT THE FINAL BINARY BE EXACTLY HWMON_SIZ BYTES.
; THIS GENERATES FILLER AS NEEDED.  IT WILL ALSO FORCE AN ASSEMBLY
; ERROR IF THE SIZE EXCEEDS THE SPACE ALLOCATED.
;
SLACK	.EQU	(HWMON_END - $)
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
