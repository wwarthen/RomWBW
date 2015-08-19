;
;==================================================================================================
;   HBIOS FILLER
;==================================================================================================
;
; CREATES A CORRECTLY SIZED FILLER TO FILL SPACE BETWEEN END OF HBIOS
; IMAGE AND END OF BANK ($8000)
;
#INCLUDE "hbios.exp"
;
	.FILL	$8000 - HB_END,$FF
	.END
