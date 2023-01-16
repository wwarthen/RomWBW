;
;=======================================================================
;   p-System BIOS for RomWBW HBIOS
;=======================================================================
;
; 3:46 PM 1/13/2023 - WBW - Initial release
; 5:29 PM 1/15/2023 - WBW - Implemeted extended BIOS functions
; 10:34 AM 1/16/2023 - WBW - Moved slices into partition
;
; TODO:
;
; NOTES:
; - The partition type ID used is the same as the CP/M partition
;   type ID.  Might make sense to create a new partition ID which
;   could allow p-System to co-exist with CP/M on a disk image.  This
;   would require changes to the RomWBW boot loader as well.
;
; - MBR is borrowed from RomWBW CP/M layout, so the partition size
;   is 64 8MB slices.  p-System only uses 6 slices.  Might be better
;   to create a custom MBR with an appropriate size for p-System
;   partition.
;
; - The sysinit routine does a lot of work that just sets up a few
;   variables for later use.  This work could be moved into the
;   p-System loader to reduce the size of this BIOS.  Since the BIOS
;   is only 768 bytes at this point, I have not bothered with it.
;  

#include "../ver.inc"

#include "psys.inc"

#include "psys_ior.inc"

#include "../HBIOS/hbios.inc"

;-----------------------------------------------------------------------
; Local constants
;-----------------------------------------------------------------------

; We need to read and buffer a single sector (MBR) at initialization.
; It looks like the area just above the loader is the safest place.

dskbuf	.equ	loader_loc + loader_size



;-----------------------------------------------------------------------
; BIOS Jump Table
;-----------------------------------------------------------------------

	.org	bios_loc

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

	; Extended BIOS vectors
	jp	prninit		; 15: Printer initialize
	jp	prnstat		; 16: Printer status
	jp	prnread		; 17: Printer read
	jp	prnwrit		; 18: Printer write
	jp	reminit		; 19: Remote initialize
	jp	remstat		; 20: Remote status
	jp	remread		; 21: Remote read
	jp	remwrit		; 22: Remote write
	jp	usrinit		; 23: User devices initialize
	jp	usrstat		; 24: User devices status
	jp	usrread		; 25: User devices read
	jp	usrwrit		; 26: User devices write
	jp	clkread		; 27: System clock read

;-----------------------------------------------------------------------
; Simple BIOS routines
;-----------------------------------------------------------------------


sysinit:	; 0: Initialize machine
	; Get critical HBIOS bank ids for use later
	ld	b,BF_SYSGET		; HBIOS SysGet function
	ld	c,BF_SYSGET_BNKINFO	; BankInfo sub-function
	rst	08			; do it, D=BIOS, E=USER
	ld	(hb_bnks),de		; save bank info
	
	; Get boot disk to use for all subsequent disk I/O
	ld	b,BF_SYSGET		; HBIOS SysGet function
	ld	c,BF_SYSGET_BOOTINFO	; BootInfo sub-function
	rst	08			; do it, boot disk device unit in 
	ld	a,d			; boot unit id returned in D
	ld	(hb_dev),a		; save for disk I/O

	; Get the count of serial (CIO) HBIOS devices in system
	ld	b,BF_SYSGET		; HBIOS SysGet function
	ld	c,BF_SYSGET_CIOCNT	; CIO Count sub-function
	rst	08			; do it, count in E
	push	de			; save it

	; Get current HBIOS console unit and assign to pSys console
	ld	b,BF_SYSPEEK		; HBIOS Peek Function
	ld	a,(hb_bios)		; HBIOS bank id
	ld	d,a			; ... goes in D
	ld	hl,$112			; offset $112 is current console device
	rst	08			; call HBIOS, value returned in E
	ld	a,e			; move to A
	ld	hl,hb_con		; use HL to point to hb_con
	ld	(hl),a			; save as console device

	; Assign additional HBIOS serial devices as pSys remote and printer
	pop	bc			; recover CIO count, now in C
	ld	a,0			; assume remote on HB unit 0
	cp	(hl)			; conflict?
	jr	nz,sysinit1		; if no conflict, continue
	inc	a			; else increment to next unit
sysinit1:
	cp	c			; check for over max serial count
	jr	nc,sysinit3		; if exceeded, we are done
	ld	(hb_rem),a		; assign remote device
	inc	a			; bump to next dev for printer
	cp	(hl)			; conflict?
	jr	nz,sysinit2		; if no conflict, continue
	inc	a			; else increment to next unit
sysinit2:
	cp	c			; check for over max serial count
	jr	nc,sysinit3		; if exceeded, we are done
	ld	(hb_prn),a		; assign printer device
sysinit3:

	; Announce BIOS
	ld	hl,str_banner		; load version banner
	call	prtstr			; and display it
	;call	conread			; wait for user

	; The p-System slices live within a disk partition.  So, now we
	; read the MBR, look for our partition ID, extract the
	; corresponding LBA offset and save it for subsequent disk I/O.

	; Read MBR.  The MBR lives in the first sector of the hard
	; disk.  At this point paroff, curdisk, curtrak, and cursect
	; are all zero.  So, we just set the disk buffer and make a
	; disk I/O call which results in reading the first (MBR)
	; sector.
	ld	bc,dskbuf		; load disk buf adr
	ld	(curbufr),bc		; save it
	call	dskread			; read first sector of phy disk
	jp	nz,parterr		; abort on error

	; Check signature
	ld	hl,(dskbuf+$1FE)	; get signature
	ld	a,l			; first byte
	cp	$55			; should be $55
	jp	nz,parterr		; if not, no part table
	ld	a,h			; second byte
	cp	$AA			; should be $AA
	jp	nz,parterr		; if not, no part table

	; Search part table for entry (type 0x2E)
	ld	b,4			; four entries in part table
	ld	hl,dskbuf+$1BE+4	; offset of first part type
sysinit4:
	ld	a,(hl)			; get part type
	cp	$2E			; CP/M partition?
	jr	z,sysinit5		; cool, grab the LBA offset
	ld	de,16			; part table entry size
	add	hl,de			; bump to next part type
	djnz	sysinit4		; loop thru table
	jp	parterr			; too bad, no CP/M partition
sysinit5:
	; Capture the starting LBA of the partition we found
	ld	de,4			; LBA is 4 bytes after part type
	add	hl,de			; point to it
	ld	de,paroff		; loc to store lba offset
	ld	bc,4			; 4 bytes (32 bits)
	ldir				; copy it

sysinit6:
	
	; Vector sysinit is being called twice during startup.  Once
	; from the bootstrap and then from the interpreter.  So, we
	; remap the vector here to avoid doing the above stuff
	; multiple times.
	ld	hl,sysinitz		; re-vector to sysinitz
	ld	(bios_loc+1),hl		; update the jump table

sysinitz:
	ret				; done
	xor	a			; signal success

syshalt:	; 1: Exit UCSD Pascal
	; The syshalt vector does not seem be to invoked when
	; selecting the Halt option from the p-System menu.
	; I have no idea why.
	ld	b,BF_SYSRESET		; HBIOS reset function
	ld	c,BF_SYSRES_WARM	; warm reset is fine
	rst	08			; do it
	
	; We should never get here.
	di				; interrupts off
	halt				; ... and die
	

coninit:	; 2: Console initialize
	ld	a,(hb_con)		; initialize console unit
	jp	serinit			; do it

constat:	; 3: Console status
	ld	a,(hb_con)		; status of console unit
	jp	serstat			; do it
	
conread:	; 4: Console input	
	ld	a,(hb_con)		; read from console unit
	jp	serread			; do it
	
conwrit:	; 5: Console output	
	ld	a,c	
	cp	27			; escape?
	ld	a,(hb_con)		; write to console unit
	jp	nz,serwrit		; if not, handle normally
	call	serwrit			; else, send escape
	ld	c,'['			; ... followed by '[' for ANSI
	ld	a,(hb_con)		; write to console unit
	jp	serwrit			; do it
	
setdisk:	; 6: Set disk number	
	ld	a,c			; disk number to A
	ld	(curdisk),a		; save for later

	; Each p-System disk lives in a slice.  Additionally,
	; the start of the slices is determined by the hard
	; disk partition table.  To avoid computing the p-System
	; disk offset on every I/O call, below we pre-compute
	; the physical HBIOS disk LBA offset for the slice of the
	; p-System disk being selected here.
	ld	hl,(paroff)		; initialize DE:HL
	ld	de,(paroff+2)		; ... to start of partition
	or	a			; use A as loop ctr, check for zero
	jr	z,setdisk2		; if 0, no slice offset needed
setdisk1:	
	ld	bc,(sps)		; get low word of sps
	add	hl,bc			; add low words
	ex	de,hl			; swap high word into HL
	ld	bc,(sps+2)		; get high word of sps
	adc	hl,bc			; add high words (w/ carry)
	ex	de,hl			; swap back to get DE:HL
	dec	a			; dec loop ctr
	jr	nz,setdisk1		; rinse and repeat
setdisk2:	
	ld	(curoff),hl		; save low word
	ld	(curoff+2),de		; save high word
	
	xor	a			; signal success
	ret				; done
	
settrak:	; 7: Set track number	
	ld	a,c			; track number to A
	ld	(curtrak),a		; save for later
	xor	a			; signal success
	ret				; done
	
setsect:	; 8: Set sector number	
	ld	a,c			; sector number to A
	dec	a			; from 1 indexed to 0 indexed
	ld	(cursect),a		; save for later
	xor	a			; signal success
	ret	
	
setbufr:	; 9: Set buffer address	
	ld	(curbufr),bc		; save buf adr for later
	xor	a			; signal success
	ret				; done

dskread:	; 10: Read sector from disk
	call	chkdisk
	ret	nz

	call	seek
	ret	nz

	ld	b,BF_DIOREAD		; HBIOS disk read function
	ld	a,(hb_dev)		; HBIOS disk unit
	ld	c,a			; ... goes in C
	ld	a,(HB_CURBNK)		; get current memory bank
	ld	d,a			; use as target bank for transfer
	ld	e,1			; read 1 sector
	ld	hl,(curbufr)		; disk read buffer adr
	rst	08			; do it
	ret	z			; return if good read
	ld	a,ior_badblk		; else i/o error
	ret				; done
		
dskwrit:	; 11: Write sector to disk	
	call	chkdisk	
	ret	nz	
	
	call	seek	
	ret	nz
	
	ld	b,BF_DIOWRITE		; HBIOS disk read function
	ld	a,(hb_dev)		; HBIOS disk unit
	ld	c,a			; ... goes in C
	ld	a,(HB_CURBNK)		; get current memory bank
	ld	d,a			; use as target bank for transfer
	ld	e,1			; read 1 sector
	ld	hl,(curbufr)		; disk read buffer adr
	rst	08			; do it
	ret	z			; return if good read
	ld	a,ior_badblk		; else i/o error
	ret				; done
	
dskinit:	; 12: Reset disk	
	call	chkdisk	
	ret	nz	
	
	xor	a			; signal success
	ret				; done
	
dskstrt:	; 13: Activate disk	
	xor	a			; signal success
	ret				; done
	
dskstop:	; 14: De-activate disk	
	xor	a			; signal success
	ret				; done

;-----------------------------------------------------------------------
; Extended BIOS routines
;-----------------------------------------------------------------------

prninit:	; 15: Printer initialize
	ld	a,(hb_prn)		; initialize printer unit
	jp	serinit			; do it

prnstat:	; 16: Printer status
	ld	a,(hb_prn)		; status of printer unit
	jp	serstat			; do it

prnread:	; 17: Printer read
	ld	a,(hb_prn)		; read from printer unit
	jp	serread			; do it

prnwrit:	; 18: Printer write
	ld	a,(hb_prn)		; write to printer unit
	jp	serwrit			; do it

reminit:	; 19: Remote initialize
	ld	a,(hb_rem)		; initialize remote unit
	jp	serinit			; do it

remstat:	; 20: Remote status
	ld	a,(hb_rem)		; status of remote unit
	jp	serstat			; do it

remread:	; 21: Remote read
	ld	a,(hb_rem)		; read from remote unit
	jp	serread			; do it

remwrit:	; 22: Remote write
	ld	a,(hb_rem)		; write to remote unit
	jp	serwrit			; do it

usrinit:	; 23: User devices initialize
	ld	a,9			; offline status
	ret

usrstat:	; 24: User devices status
	pop	hl			; return address
	pop	de			; discard input/output toggle
	pop	de			; discard ptr to status rec
	pop	de			; discard device number
	ld	a,9			; offline status
	jp	(hl)			; return

usrread:	; 25: User devices read
usrwrit:	; 26: User devices write
	pop	hl			; return address
	pop	de			; extra parameter 2
	pop	de			; extra parameter 1
	pop	de			; pointer to buffer
	pop	de			; device number
	pop	de			; extra parameter 5
	ld	a,9			; offline status
	jp	(hl)			; return

clkread:	; 27: System clock read
	ld	b,BF_SYSGET		; HBIOS SysGet function
	ld	c,BF_SYSGET_TIMER	; Timer sub-function
	rst	08			; do it, ticks ret in DE:HL
	ex	de,hl			; swap for pSys
	xor	a			; signal success
	ret				; done



;-----------------------------------------------------------------------
; Support routines
;-----------------------------------------------------------------------

serinit:
	; Initialize HBIOS serial port identified in reg A
	cp	$FF			; do we have desired port?
	jr	z,nodev			; handle it if so
	xor	a			; signal success
	ret				; done
	
serstat:
	; Check status of HBIOS serial port identified in reg A
	cp	$FF			; do we have desired port?
	jr	z,nodev			; handle it if so
	ld	b,BF_CIOIST		; serial port status function
	ld	c,a			; HBIOS serial port
	rst	08			; call HBIOS
	ld	c,0			; assume no chars pendin
	jr	z,serstat1		; if zero, no chars waiting
	ld	c,$FF			; signal char(s) pending
serstat1:	
	xor	a			; signal success
	ret				; done

serread:
	; Read one byte from HBIOS serial port identified in reg A
	cp	$FF			; do we have desired port?
	jr	z,nodev			; handle it if so
	ld	b,BF_CIOIN		; serial port read function
	ld	c,a			; HBIOS serial port
	rst	08			; call HBIOS
	ld	c,e			; char to C
	xor	a			; signal success
	ret				; done

serwrit:
	; Write one byte to HBIOS serial port identified in reg A
	cp	$FF			; do we have desired port?
	jr	z,nodev			; handle it if so
	ld	e,c			; char to write to E
	ld	b,BF_CIOOUT		; serial port write function
	ld	c,a			; HBIOS serial port
	rst	08			; call HBIOS
	xor	a			; signal success
	ret				; done
	
nodev:	
	ld	a,9			; signal volume offline
	ret				; and done

chkdisk:
	; Validate that curdisk is <= max supported
	ld	a,(curdisk)		; get current disk
	cp	disks			; compare to disk count
	jr	nc,chkdisk1		; if too high, go to err
	xor	a			; signal success
	ret				; done
chkdisk1:	
	ld	a,ior_novol		; signal not online
	or	a			; set flags
	ret				; done

seek:
	; We use LBA addressing for disk access.  So, we need to
	; translate the track/sector value from p-System into an
	; lba offset.  Since we are using 16 sectors per track, we
	; can cheat (avoid multiplication) by using the low 4 bits
	; for sector and the high bits for track which allows us to 
	; just "or" the values together.  We are only using word values
	; here since that will handle up to a 32MB p-System file system
	; (slice) which is more than enough.
	
	ld	a,(curtrak)		; cur track in accum
	ld	l,a			; move to low byte of HL
	ld	h,0			; zero out high byte of HL
	add	hl,hl			; * 2
	add	hl,hl			; * 4
	add	hl,hl			; * 8
	add	hl,hl			; * 16 (sectors per track)
	ld	a,(cursect)		; cur sec to accum
	or	l			; combine with low byte of HL
	ld	l,a			; back to low byte of HL
	
	; HL now has LBA offset of desired sector.  Next
	; we need to add in the offset of the current disk.
	; At this point, we need to start using dword values
	; using DE:HL to accommodate large disk drives.
	ld	de,0			; extend LBA to DE:HL
	ld	bc,(curoff)		; get low word of offset
	add	hl,bc			; add low words together
	ex	de,hl			; swap high word of LBA into HL
	ld	bc,(curoff+2)		; get high word of offset
	adc	hl,bc			; add high words together (w/ carry)
	ex	de,hl			; swap back to get DE:HL
	
	; Now we have final LBA in DE:HL.  We just set the
	; LBA flag bit and do the disk seek.
	set	7,d			; high order bit designates LBA I/O
	ld	b,BF_DIOSEEK		; HBIOS seek function
	ld	a,(hb_dev)		; HBIOS disk unit
	ld	c,a			; ... goes in C
	rst	08			; do it
	ret	z			; if no error, done
	ld	a,ior_badblk		; signal I/O error
	ret				; done

prtstr:
	; Print a null terminated string on the p-System console
	ld	a,(hl)			; get next char
	or	a			; set flags
	ret	z			; done if null
	push	hl			; save buffer pointer
	ld	c,a			; char to C
	call	conwrit			; write it out to pSys console
	pop	hl			; recover buffer pointer
	inc	hl			; increment to next char
	jr	prtstr			; loop as needed

parterr:
	ld	hl,str_parterr		; partition error string
	call	prtstr			; display it
	jp	syshalt			; back to boot loader

panic:
	; Hard stop
	di				; no interrupts
	halt				; ... and halt



;-----------------------------------------------------------------------
; Local storage
;-----------------------------------------------------------------------

hb_bnks:
hb_usr	.db	0		; HBIOS User bank id
hb_bios	.db	0		; HBIOS BIOS bank id

hb_dev	.db	0		; HBIOS device for pSys disk
hb_con	.db	$FF		; HBIOS device for pSys console unit
hb_rem	.db	$FF		; HBIOS device for pSys remote unit
hb_prn	.db	$FF		; HBIOS device for pSys printer unit

curdisk	.db	0		; Current pSys disk number
curtrak	.db	0		; Current pSys track number
cursect	.db	0		; Current pSys sector number
curbufr	.dw	0		; Current pSys disk buffer address
curoff	.dw	0,0		; Current sector offset (dword LBA)

paroff	.dw	0,0		; Partition offset (dword LBA)
sps	.dw	16384,0		; Sectors per slice (8MB / 512) = 16384

str_banner	.db	13,10,13,10,"RomWBW p-System Extended BIOS v"
		.db	BIOSVER,0
str_parterr	.db	13,10,"*** Disk partition table error!",0



#if	($ >= bios_end)
	.echo	"*** ERROR: Out of space in pSystem BIOS!!!\n"
	!!!	; force an assembly error
#endif

slack		.equ	bios_end - $
		.echo	"pSystem BIOS space remaining: "
		.echo	slack
		.echo	" bytes.\n"

	.fill	bios_end - $

	.end
