;
; p-System Loader
;
loader_size	.equ	$200
loader_loc	.equ	$100
loader_end	.equ	loader_loc + loader_size
;
; p-System BIOS
;
bios_size	.equ	$300
bios_loc	.equ	$FE00 - bios_size
bios_end	.equ	bios_loc + bios_size
;
; p-System Bootstrap
;
#ifdef TESTBIOS
boot_size	.equ	$400
boot_loc	.equ	$8000
boot_end	.equ	boot_loc + boot_size
#else
boot_size	.equ	$800
boot_loc	.equ	$8200
boot_end	.equ	boot_loc + boot_size
#endif
;
; Disk geometry
;
seclen		.equ	512	; bytes per sector
sectors		.equ	16	; sectors per track
tracks		.equ	192	; tracks per disk
disks		.equ	6	; number of pSystem disk devices
