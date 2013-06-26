;
;==================================================================================================
;   HDSK DISK DRIVER - DATA
;==================================================================================================
;
; MEMORY DISK 00: ROM DISK
;
ROMBLKS	.EQU	((ROMSIZE - 64) / 2)
;
		.DB	DIODEV_MD + 0
MDDPH0 	 	.DW 	0000,0000
	 	.DW 	0000,0000
	 	.DW 	DIRBF,DPB_ROM
	 	.DW 	MDCSV0,MDALV0
;
CKS_ROM	.EQU	0			; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_ROM	.EQU	((ROMBLKS + 7) / 8)	; ALS: BLKS / 8 (ROUNDED UP)
;
; MEMORY DISK 01: RAM DISK
;
RAMBLKS	.EQU	((RAMSIZE - 96) / 2)
;
		.DB	DIODEV_MD + 1
MDDPH1	 	.DW 	0000,0000
	 	.DW 	0000,0000
	 	.DW 	DIRBF,DPB_RAM
	 	.DW 	MDCSV1,MDALV1
;
CKS_RAM	.EQU	0			; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_RAM	.EQU	((RAMBLKS + 7) / 8)	; ALS: BLKS / 8 (ROUNDED UP)
;
MDCSV0:		.FILL	0		; NO DIRECTORY CHECKSUM, NON-REMOVABLE DRIVE
MDALV0:		.FILL	ALS_ROM,00H	; MAX OF 512 DATA BLOCKS
MDCSV1:		.FILL	0		; NO DIRECTORY CHECKSUM, NON-REMOVABLE DRIVE
MDALV1:		.FILL	ALS_RAM,00H	; MAX OF 256 DATA BLOCKS
