;
;==================================================================================================
;   N8 STANDARD CONFIGURATION
;==================================================================================================
;
#include "cfg_n8.asm"
;
Z180_CLKDIV	.SET	1		; 0=OSC/2, 1=OSC, 2=OSC*2
Z180_MEMWAIT	.SET	1		; MEMORY WAIT STATES (0-3)
Z180_IOWAIT	.SET	3		; ADD (0-3) I/O WAIT STATES ABOVE 1 W/S BUILT-IN
;
SDMODE		.SET	SDMODE_CSIO	; FOR N8 PROTOTYPE (DATECODE 2511), USE SDMODE_N8
;
CRTACT		.SET	FALSE		; TRUE TO ACTIVATE CRT AT STARTUP (BOOT ON CRT)
