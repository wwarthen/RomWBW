;
;==================================================================================================
;   RF DISK DRIVER - DATA
;==================================================================================================
;
; RAM FLOPPY 00
;
		.DB	DIODEV_RF + 0
RFDPH0		.DW 	0000,0000
		.DW 	0000,0000
		.DW 	DIRBF,DPB_RF
		.DW 	RFCSV0,RFALV0
;
; RAM FLOPPY 01
;
		.DB	DIODEV_RF + 1
RFDPH1		.DW 	0000,0000
		.DW 	0000,0000
		.DW 	DIRBF,DPB_RF
		.DW 	RFCSV1,RFALV1
;
RFCKS		.EQU	0		; CKS: 0 FOR NON-REMOVABLE MEDIA
RFALS		.EQU	256		; ALS: BLKS / 8 = 2048 / 8 = 256 (ROUNDED UP)
;
; BUFFERS
;
RFCSV0:		.FILL	RFCKS		; NO DIRECTORY CHECKSUM, NON-REMOVABLE DRIVE
RFALV0:		.FILL	RFALS		; MAX OF 2048 DATA BLOCKS
RFCSV1:		.FILL	RFCKS		; NO DIRECTORY CHECKSUM, NON-REMOVABLE DRIVE
RFALV1:		.FILL	RFALS		; MAX OF 2048 DATA BLOCKS
