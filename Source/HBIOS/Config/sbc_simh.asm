;
;==================================================================================================
;   SBC SIMH EMULATOR CONFIGURATION
;==================================================================================================
;
#include "cfg_sbc.asm"
;
DSRTCENABLE	.SET	FALSE		; DS-1302 CLOCK DRIVER
SIMRTCENABLE	.SET	TRUE		; SIMH CLOCK DRIVER
;
HDSKENABLE	.SET	TRUE		; TRUE FOR SIMH HDSK SUPPORT
