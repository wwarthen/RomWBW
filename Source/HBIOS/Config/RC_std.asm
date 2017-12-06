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
SIOENABLE	.SET	TRUE		; TRUE TO AUTO-DETECT ZILOG SIO/2 
SIOMODE		.SET	SIOMODE_RC	; TYPE OF SIO/2 TO DETECT: SIOMODE_RC, SIOMODE_SMB
ACIAENABLE	.SET	TRUE		; TRUE TO AUTO-DETECT MOTOROLA 6850 ACIA
;
IDEENABLE	.SET	TRUE		; TRUE FOR IDE DEVICE SUPPORT (CF MODULE)
PPIDEENABLE	.SET	FALSE		; TRUE FOR PPIDE DEVICE SUPPORT (PPIDE MODULE)
