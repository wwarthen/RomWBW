;
;==================================================================================================
;   RC2014 STANDARD CONFIGURATION
;==================================================================================================
;
#include "cfg_rc.asm"
;
CPUOSC		.SET	7372800		; CPU OSC FREQ
DEFSERCFG	.SET	SER_115200_8N1	; DEFAULT SERIAL LINE CONFIG (SHOULD MATCH ABOVE)
;
SIOENABLE	.SET	TRUE		; TRUE FOR ZILOG SIO/2 SUPPORT
;
IDEENABLE	.SET	TRUE		; TRUE FOR IDE DEVICE SUPPORT