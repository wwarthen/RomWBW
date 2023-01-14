;
;-----------------------------------------------------------------------
;   p-System BIOS for RomWBW HBIOS
;
;-----------------------------------------------------------------------
;
; 3:46 PM 1/13/2023 - WBW - Initial release
;
; TODO:
;
; - Assign the HBIOS console device to the p-System console instead
;   of just using a hard-coded reference to Serial Unit 0.
;
; - Implement Extended BIOS.
;

#include "../ver.inc"
;
#include "psys.inc"
;
#include "../HBIOS/hbios.inc"
;
; IORESULT values
;
ior_ok		.equ	0		; No error
ior_badblk	.equ	1		; Bad block, CRC error (parity)
ior_baddev	.equ	2		; Bad device number
ior_badio	.equ	3		; Illegal I/O request
ior_timout	.equ	4		; Data-com timeout
ior_offlin	.equ	5		; Volume is no longer on-line
ior_nofile	.equ	6		; File is no longer in directory
ior_filnamerr	.equ	7		; Illegal file name
ior_full	.equ	8		; No room; insufficient space on disk
ior_novol	.equ	9		; No such volume on-line
ior_notfnd	.equ	10		; No such file name in directory
ior_dupfil	.equ	11		; Duplicate file
ior_notclos	.equ	12		; Not closed: attempt to open an open file
ior_notopen	.equ	13		; Not open: attempt to access a closed file
ior_badfmt	.equ	14		; Bad format: error reading real or integer
ior_bufovr	.equ	15		; Ring buffer overflow
ior_diskwp	.equ	16		; Write attempt to protected disk
ior_blknumerr	.equ	17		; Illegal block number
ior_bufadrerr	.equ	18		; Illegal buffer address
ior_badsiz	.equ	19		; Bad text file size
;
;
;
	.org	bios_loc
;
	; Simple BIOS vectors
	jp	sysinit		; 0: Initialize machine
	jp	syshalt		; 1: Exit UCSD Pascal
	jp	coninit		; 2: Console initialize
	jp	constat		; 3: Console status
	jp	conread		; 4: Console input
	jp	conwrit		; 5: Console output
	jp	setdisk		; 6: Set disk number
	jp	settrak		; 7: Set track number
	jp	setsect		; 8: Set sector number
	jp	setbufr		; 9: Set buffer address
	jp	dskread		; 10: Read sector from disk
	jp	dskwrit		; 11: Write sector to disk
	jp	dskinit		; 12: Reset disk
	jp	dskstrt		; 13: Activate disk
	jp	dskstop		; 14: De-activate disk
;
	; Extended BIOS vectors
	jp	panic		; 15: Extended BIOS vector
	jp	panic		; 16: Extended BIOS vector
	jp	panic		; 17: Extended BIOS vector
	jp	panic		; 18: Extended BIOS vector
	jp	panic		; 19: Extended BIOS vector
	jp	panic		; 20: Extended BIOS vector
	jp	panic		; 21: Extended BIOS vector
	jp	panic		; 22: Extended BIOS vector
	jp	panic		; 23: Extended BIOS vector
	jp	panic		; 24: Extended BIOS vector
	jp	panic		; 25: Extended BIOS vector
	jp	panic		; 26: Extended BIOS vector
	jp	panic		; 27: Extended BIOS vector
;
;
;
sysinit:
	;ld	a,0
	;jp	panic
	
	ld	hl,str_banner
	call	prtstr
	call	conread
	
	ld	b,BF_SYSGET		; HBIOS SysGet function
	ld	c,BF_SYSGET_BOOTINFO	; BootInfo sub-function
	rst	08			; do it, boot disk device unit in 
	ld	a,d			; boot unit id returned in D
	ld	(hb_dev),a		; save for disk I/O
	
	; sysinit is being called twice during startup.  Once from
	; the bootstrap and then from the interpreter.  So, we
	; remap the vector here to avoid doing the above stuff
	; multiple times.
	ld	hl,sysinit1		; re-vector to sysinit1
	ld	(bios_loc+1),hl		; update the jump table

sysinit1:
	xor	a		; signal success
	ret			; done

syshalt:
	;ld	a,1
	;jp	panic

	; The syshalt vector does not seem be to invoked when
	; selecting the Halt option from the p-System menu.
	; I have no idea why.
	ld	b,BF_SYSRESET	; HBIOS reset function
	ld	c,BF_SYSRES_WARM	; warm reset is fine
	rst	08		; do it
	
	; we should never get here
	di			; interrupts off
	halt			; ... and die
	

coninit:
	;ld	a,2
	;jp	panic

	xor	a		; signal success
	ret			; done

constat:
	;ld	a,3
	;jp	panic

	ld	b,BF_CIOIST	; serial port status function
	ld	c,0		; port 0
	rst	08		; call HBIOS
	ld	c,0		; assume no chars pendin
	jr	z,constat1	; if zero, no chars waiting
	ld	c,$FF		; signal char(s) pending
constat1:
	xor	a		; signal success
	ret			; done

conread:
	;ld	a,4
	;jp	panic

	ld	b,BF_CIOIN	; serial port read function
	ld	c,0		; port 0
	rst	08		; call HBIOS
	ld	c,e		; char to C
	xor	a		; signal success
	ret			; done

conwrit:
	;ld	a,5
	;jp	panic
	
	ld	a,c
	cp	27		; escape?
	jr	nz,conwrit1	; if not, handle normally
	call	conwrit1	; else, send escape
	ld	c,'['		; ... followed by '[' for ANSI
conwrit1:
	ld	e,c		; char to write to E
	ld	b,BF_CIOOUT	; serial port write function
	ld	c,0		; port 0
	rst	08		; call HBIOS
	xor	a		; signal success
	ret			; done

setdisk:
	;ld	a,6
	;jp	panic

	ld	a,c		; disk number to A
	ld	(curdisk),a	; save for later
	xor	a		; signal success
	ret			; done

settrak:
	;ld	a,7
	;jp	panic

	ld	a,c		; track number to A
	ld	(curtrak),a	; save for later
	xor	a		; signal success
	ret			; done

setsect:
	;ld	a,8
	;jp	panic
	
	ld	a,c		; sector number to A
	dec	a		; from 1 indexed to 0 indexed
	ld	(cursect),a	; save for later
	xor	a		; signal success
	ret

setbufr:
	;ld	a,9
	;jp	panic
	
	ld	(curbufr),bc	; save buf adr for later
	xor	a		; signal success
	ret			; done

dskread:
	;ld	a,10
	;jp	panic

	;ld	a,(curdisk)
	;cp	0
	;jr	nz,dskinit1
	
	call	chkdisk
	ret	nz

	call	seek
	ret	nz

	ld	b,BF_DIOREAD	; HBIOS disk read function
	ld	a,(hb_dev)	; HBIOS disk unit
	ld	c,a		; ... goes in C
	ld	a,(HB_CURBNK)	; get current memory bank
	ld	d,a		; use as target bank for transfer
	ld	e,1		; read 1 sector
	ld	hl,(curbufr)	; disk read buffer adr
	rst	08		; do it
	ret	z		; return if good read
	ld	a,ior_badblk	; else i/o error
	ret			; done
	
dskwrit:
	;ld	a,11
	;jp	panic

	call	chkdisk
	ret	nz

	call	seek
	ret	nz

	ld	b,BF_DIOWRITE	; HBIOS disk read function
	ld	a,(hb_dev)	; HBIOS disk unit
	ld	c,a		; ... goes in C
	ld	a,(HB_CURBNK)	; get current memory bank
	ld	d,a		; use as target bank for transfer
	ld	e,1		; read 1 sector
	ld	hl,(curbufr)	; disk read buffer adr
	rst	08		; do it
	ret	z		; return if good read
	ld	a,ior_badblk	; else i/o error
	ret			; done

dskinit:
	;ld	a,12
	;jp	panic
	
	call	chkdisk
	ret	nz

	xor	a		; signal success
	ret			; done

dskstrt:
	;ld	a,13
	;jp	panic

	xor	a		; signal success
	ret			; done

dskstop:
	;ld	a,14
	;jp	panic

	xor	a		; signal success
	ret			; done

chkdisk:
	; Validate that curdisk is <= max supported
	ld	a,(curdisk)	; get current disk
	cp	disks		; compare to disk count
	jr	nc,chkdisk1	; if too high, go to err
	xor	a		; signal success
	ret			; done
chkdisk1:
	ld	a,ior_novol	; signal not online
	or	a
	ret

seek:
	; A single physical HBIOS disk device will contain p-System
	; volume slices.  Each slice will be 8MB.  Start by computing
	; a track offset using the p-System disk number as an
	; index.  <Track Offset> = 8MB * <Disk Number>
	; A track contains 0x20000 bytes:
	;     512 (bytes per sec) * 16 (sec per trk) * 16 (hds per cyl)
	; So, 8MB / 0x20000 = 0x40 tracks
	ld	hl,0		; starting unit track offset
	ld	de,$0040	; per disk track offset
	ld	a,(curdisk)	; get current disk
	or	a		; set flags
	jr	z,seek2		; disk 0 needs no offset
	ld	b,a		; into B for loop counter
seek1:
	add	hl,de		; add another offset
	djnz	seek1		; and loop as needed
seek2:
	push	hl		; save total track offset
	ld	a,(curtrak)	; get current track value
	push	af		; save track value
	and	$0F		; head is low 4 bits of track
	ld	d,a		; save in D for head
	pop	af		; recover original track value
	rra			; rotate to remove head bits
	rra
	rra
	rra
	and	$0F		; mask off other bits
	ld	l,a		; save in low byte of HL
	ld	h,0		; zero out high byte of HL
	ld	a,(cursect)	; get sector
	ld	e,a		; put in E
	pop	bc
	add	hl,bc		; add track offset
	ld	b,BF_DIOSEEK	; HBIOS seek function
	ld	a,(hb_dev)	; HBIOS disk unit
	ld	c,a		; ... goes in C
	rst	08		; do it
	ret	z		; if no error, done
	ld	a,ior_badblk	; signal I/O error
	ret			; done

prtstr:
	ld	a,(hl)
	or	a
	ret	z
	push	hl
	ld	c,a
	call	conwrit
	pop	hl
	inc	hl
	jr	prtstr


panic:
	di
	halt


hb_dev	.db	3		; HBIOS disk device unit
;
curdisk	.db	0		; Current disk number
curtrak	.db	0		; Current track number
cursect	.db	0		; Current sector number
curbufr	.dw	0		; Current disk buffer address
;
str_banner	.db	13,10,"RomWBW p-System BIOS v"
		.db	BIOSVER
		.db	13,10,13,10
		.db	"Press any key...",0
;
;
;
	.fill	bios_end - $
	
;
	.end
