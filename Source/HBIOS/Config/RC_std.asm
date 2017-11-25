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
SIOENABLE	.SET	TRUE		; TRUE FOR ZILOG SIO/2 
SIOMODE		.SET	SIOMODE_RC	; SIOMODE_RC, SIOMODE_SMB
ACIAENABLE	.SET	TRUE		; TRUE FOR MOTOROLA 6850 ACIA SUPPORT

;
IDEENABLE	.SET	TRUE		; TRUE FOR IDE DEVICE SUPPORT