;
;==================================================================================================
;   SBC SIMH EMULATOR CONFIGURATION
;==================================================================================================
;
#include "cfg_sbc.asm"
;
INTMODE		.SET	1		; INT MODE 1
HTIMENABLE	.SET	TRUE		; SIMH TIMER
;
DSRTCENABLE	.SET	FALSE		; DS-1302 CLOCK DRIVER
SIMRTCENABLE	.SET	TRUE		; SIMH CLOCK DRIVER
;
HDSKENABLE	.SET	TRUE		; TRUE FOR SIMH HDSK SUPPORT
