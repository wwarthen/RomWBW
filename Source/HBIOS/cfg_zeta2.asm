;
;==================================================================================================
;   ROMWBW 2.X CONFIGURATION DEFAULTS FOR ZETA V2
;==================================================================================================
;
; BUILD CONFIGURATION OPTIONS
;
#INCLUDE "cfg_zeta.asm"			; USE ZETA CONFIG TO START
;
MEMMGR		.SET	MM_Z2		; MM_NONE, MM_SBC, MM_Z2, MM_N8, MM_Z180
INTMODE		.SET	2		; 0=NONE, 1=INT MODE 1, 2=INT MODE 2
;
FDMODE		.SET	FDMODE_ZETA2	; FDMODE_DIO, FDMODE_ZETA, FDMODE_DIDE, FDMODE_N8, FDMODE_DIO3
