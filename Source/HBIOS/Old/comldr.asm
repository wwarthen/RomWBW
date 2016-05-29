;
;==================================================================================================
;   APPLICATION LOADER (COM FILE)
;
; CREATES A STANDARD CP/M COM APPLICATION FILE TO LOAD ROMWBW
; FROM A COMMAND PROMPT.
;==================================================================================================
;
#define MODE LM_COM
;
#INCLUDE "std.asm"
#INCLUDE "hbios.exp"
;
	.ORG	$100
	JP	START
;
#INCLUDE "loader.asm"
;
	.END
