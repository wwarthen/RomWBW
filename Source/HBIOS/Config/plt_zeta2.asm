;
;==================================================================================================
;   ROMWBW 2.X CONFIGURATION DEFAULTS FOR ZETA V2
;==================================================================================================
;
; BUILD CONFIGURATION OPTIONS
;
#INCLUDE "Config/plt_zeta.asm"		; USE ZETA CONFIG TO START
;
INTTYPE		.SET	IT_CTC		; INTERRUPT HANDLING TYPE (IT_NONE, IT_SIMH, IT_Z180, IT_CTC, ...)
;
FDMODE		.SET	FDMODE_ZETA2	; FDMODE_DIO, FDMODE_ZETA, FDMODE_DIDE, FDMODE_N8, FDMODE_DIO3
