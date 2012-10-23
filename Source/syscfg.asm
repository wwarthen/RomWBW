;___SYSCFG_____________________________________________________________________________________________________________
;
; syscfg.asm 3/04/2012 2.0.0.0 dwg - added required configuration information
;
; Include standard BIOS definitions
;
#INCLUDE "std.asm"
;
	.ORG	0000H		; ALL ADDRESSES GENERATED WILL BE ZERO BASED
;
	JP	0000H		; DUMMY JP INSTRUCTION FOR COMPATIBILITY
;
; Reserved for Configuration Information
;
	.DW	cnf_loc
	.DW	tst_loc1
	.DW	var_loc1
;
; BIOS configuration data
;
cnf_loc:
#INCLUDE "cnfgdata.inc"
;
; Build information strings
;
tst_loc1	.DB	TIMESTAMP
var_loc1	.DB	VARIANT
		.DB	'$'		; provide terminator for variable length field
;
	.EXPORT	DISKBOOT,BOOTDEVICE,BOOTLU
;	
	.FILL	200H - $,$FF
;
	.END
