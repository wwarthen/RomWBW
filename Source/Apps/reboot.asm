;===============================================================================
;
; REBOOT - Execute HBIOS reset to restart to boot loader.
;
;===============================================================================
;
BID_BOOT	.EQU	$00
HB_BNKCALL	.EQU	$FFF9

			.org	$100
		
			LD		A,BID_BOOT		; BOOT BANK
			LD		HL,0			; ADDRESS ZERO
			CALL	HB_BNKCALL		; DOES NOT RETURN	
			HALT
			
			.end
			