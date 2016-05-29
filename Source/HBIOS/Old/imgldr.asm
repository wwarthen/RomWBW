;
;==================================================================================================
;   IMAGE LOADER
;
; CREATES A BINARY IMAGE THAT WILL LAUNCH ROMWBW ASSUMING IMAGE
; HAS BEEN PRE-LOADED INTO THE USER BANK.  INTENDED FOR USE WITH
; UNA FATFS.
;==================================================================================================
;
#define MODE LM_IMG
;
#INCLUDE "std.asm"
#INCLUDE "hbios.exp"
;
	.ORG	0
;
;==================================================================================================
; NORMAL PAGE ZERO SETUP, RET/RETI/RETN AS APPROPRIATE
;==================================================================================================
;
	.FILL	(000H - $),0FFH		; RST 0
	JP	START			; JUMP TO BOOT CODE
	.DW	ROM_SIG
	.FILL	(008H - $),0FFH		; RST 8
	RET
	.FILL	(010H - $),0FFH		; RST 10
	RET
	.FILL	(018H - $),0FFH		; RST 18
	RET
	.FILL	(020H - $),0FFH		; RST 20
	RET
	.FILL	(028H - $),0FFH		; RST 28
	RET
	.FILL	(030H - $),0FFH		; RST 30
	RET
	.FILL	(038H - $),0FFH		; INT
	RETI
	.FILL	(066H - $),0FFH		; NMI
	RETN
;
	.FILL	(070H - $),0FFH		; SIG STARTS AT $80
;
ROM_SIG:
	.DB	$76, $B5		; 2 SIGNATURE BYTES
	.DB	1			; STRUCTURE VERSION NUMBER
	.DB	7			; ROM SIZE (IN MULTIPLES OF 4KB, MINUS ONE)
	.DW	NAME			; POINTER TO HUMAN-READABLE ROM NAME
	.DW	AUTH			; POINTER TO AUTHOR INITIALS
	.DW	DESC			; POINTER TO LONGER DESCRIPTION OF ROM
	.DB	0, 0, 0, 0, 0, 0	; RESERVED FOR FUTURE USE; MUST BE ZERO
;
NAME	.DB	"ROMWBW v", BIOSVER, ", ", TIMESTAMP, 0
AUTH	.DB	"WBW",0
DESC	.DB	"ROMWBW v", BIOSVER, ", Copyright 2015, Wayne Warthen, GNU GPL v3", 0
;
	.FILL	($100 - $),$FF		; PAD REMAINDER OF PAGE ZERO
;
#INCLUDE "loader.asm"
;
	.END
