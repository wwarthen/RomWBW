;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; infolist.inc 6/ 7/2012 dwg - removed DSK_MAP pointer   ;
; infolist.inc 5/16/2012 dwg - BIOS information pointers ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The putpose of this table is to provide pointers that can
; be used by utility programs to access BIOS internals for
; debugging and informative purposes. Any time the format 
; changes, the first word should be incremented to the Apps
; can determine the lineage of a specific BIOS. This table 
; was created in support of the 2.0.0.0 banked BIOS. 

INFOLIST:
	.DW	2		; INFOLIST version 2 6/7/2012
	.DW	STR_BANNER
	.DW	STR_BUILD
	.DW	STR_TIMESTAMP
	.DW	DPB_MAP
	.DW	DPH_MAP
	.DW	CIO_MAP

;;;;;;;;;;;;;;;;;;;;;;
; eof - infolist.inc ;
;;;;;;;;;;;;;;;;;;;;;;