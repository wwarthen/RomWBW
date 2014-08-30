;
;==================================================================================================
;   UBIOS - JUST FILLER TO REPLACE THE SPACE HBIOS WOULD NORMALLY USE
;==================================================================================================
;
	.ORG	$1000
;
; INCLUDE GENERIC STUFF
;
#INCLUDE "std.asm"
;
	.FILL	(HBX_LOC - $8000 - $),$FF
	.ORG	HBX_LOC
	.FILL	HBX_END - $,$FF
	.END
