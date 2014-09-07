;----------------------------------------------------------------------------
;       PREFIX.ASM
;
;       PUT AT THE HEAD OF BOOT.BIN TO XFER TO A FLOPPY DISK
;
;----------------------------------------------------------------------------

; 5/11/2012 dwg - changed offset to BIOS booting fixup location
; 3/ 2/2012 dwg - fixed BOOT_INFO_LOC (moved when jump added for bnksel)
; 2/15/2012 dwg - added origin data written by formatter
; 2/ 5/2012 dwg - added version quad, updates counter, and write protect boolean to metadata
; 1/ 9/2012 wbw - added signature
; 1/ 5/2012 dwg - added version of build generating system image
; 1/ 5/2012 dwg - added drive label to metadata for 1.4

#INCLUDE "std.asm"

BYT		.EQU	1	; used to describe METADATA_SIZE below
WRD		.EQU	2

SECTOR_SIZE	.EQU	512
BLOCK_SIZE	.EQU	128
PREFIX_SIZE	.EQU	(3 * SECTOR_SIZE)	; 3 SECTORS
METADATA_SIZE	.EQU	BYT+WRD+(4*BYT)+16+BYT+WRD+WRD+WRD+WRD	; (as defined below)

BOOT_INFO_LOC	.EQU	CPM_ENT + 04BH
; PTR TO LOCATION TO RECORD BOOT INFO IN MEMORY IMAGE
; FIXUP REQUIRED WHEN BIOS HEADER CHANGES

		.ORG	0000H
		JP	CPM_ENT
;
		.FILL	((PREFIX_SIZE - BLOCK_SIZE) - $),00H
PR_SIG		.DW	0A55AH				; SIGNATURE GOES HERE

PR_PLATFORM	.DB	0	
PR_DEVICE	.DB	0
PR_FORMATTER	.DB	0,0,0,0,0,0,0,0
PR_DRIVE	.DB	0
PR_LOG_UNIT	.DW	0

;
		.FILL	((PREFIX_SIZE - METADATA_SIZE) - $),00H
		.DB	0		; write protect boolean
		.DW	0		; starting update number
		.DB	RMJ,RMN,RUP,RTP
		.DB	"Unlabeled Drive ","$"
		.DW	BOOT_INFO_LOC	; PTR TO LOCATION TO STORE DISKBOOT & BOOTDRIVE (SEE CNFGDATA)
		.DW	CPM_LOC		; CCP START
		.DW	CPM_END		; END OF CBIOS
		.DW	CPM_ENT		; COLD BOOT LOCATION

		.END