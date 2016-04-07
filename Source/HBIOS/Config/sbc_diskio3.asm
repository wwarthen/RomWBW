;
;==================================================================================================
;   SBC DISKIO V3 CONFIGURATION
;==================================================================================================
;
FDENABLE	.SET	TRUE		; ENABLE FLOPPY SUPPORT
FDMODE		.SET	FDMODE_DIO3	; USE DISKIO V3 MODE
;                                         
PPIDEENABLE	.SET	TRUE		; ENABLE PPIDE SUPPORT
PPIDEMODE	.SET	PPIDEMODE_DIO3	; PPIDEMODE_SBC, PPPIDEMODE_DIO3, PPIDEMODE_MFP, PPIDEMODE_N8
