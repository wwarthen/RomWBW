;===============================================================================
; ASSIGN - Display and/or modify drive letter assignments
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   ASSIGN D:[=[{D:|<device>[<unitnum>]:[<slicenum>]}]][,...]
;     ex: ASSIGN		(display all active drive assignments)
;         ASSIGN /?		(display version and usage)
;         ASSIGN /L		(display all possible devices)
;         ASSIGN C:=D:		(swaps C: and D:)
;         ASSIGN C:=FD0:	(assign C: to floppy unit 0)
;         ASSIGN C:=IDE0:1	(assign C: to IDE unit0, slice 1)
;         ASSIGN C:=		(unassign C:)
;_______________________________________________________________________________
;
; Change Log:
;   2016-03-21 [WBW] Updated for HBIOS 2.8
;   2016-04-08 [WBW] Determine key memory addresses dynamically
;   2019-08-07 [WBW] Fixed DPB selection error
;   2019-11-17 [WBW] Added preliminary CP/M 3 support
;   2019-12-24 [WBW] Fixed location of BIOS save area
;   2020-04-29 [WBW] Updated for larger DPH (16 -> 20 bytes)
;   2020-05-06 [WBW] Add patch level to version compare
;   2020-05-10 [WBW] Set media change flag in XDPH for CP/M 3
;   2020-05-12 [WBW] Back out media change flag
;   2021-12-06 [WBW] Fix inverted ROM/RAM DPB mapping in buffer alloc
;   2022-02-28 [WBW] Use HBIOS to swap banks under CP/M 3
;                    Use CPM3 BDOS direct BIOS call to get DRVTBL adr
;_______________________________________________________________________________
;
; ToDo:
;  1) Do something to prevent assigning slices when device does not support them
;  2) ASSIGN C: causes drive map to be reinstalled unnecessarily
;_______________________________________________________________________________
;
;===============================================================================
; Definitions
;===============================================================================
;
stksiz	.equ	$40		; Working stack size
;
restart	.equ	$0000		; CP/M restart vector
bdos	.equ	$0005		; BDOS invocation vector
bnksel	.equ	$FFF3		; HBIOS bank select vector
;
stamp	.equ	$40		; loc of RomWBW CBIOS zero page stamp
;
#include "../ver.inc"
;
;===============================================================================
; Code Section
;===============================================================================
;
	.org	$100
;
	; relocate to high memory
	ld	hl,image
	ld	de,$8000
	ld	bc,modsize
	ldir
	jp	start
;
image	.equ	$
;
	.org	$8000
;
start:
;
	; setup stack (save old value)
	ld	(stksav),sp	; save stack
	ld	sp,stack	; set new stack
;
	; initialization
	call	init		; initialize
	jr	nz,exit		; abort if init fails
;
	; do the real work 
	call	process		; parse and process command line
	jr	nz,exit		; done if error or no action
;
	; perform table integrity check
	call	valid
	jr	nz,exit
;
	; install the new drive map if changes were made
	ld	a,(modcnt)	; get the mod count
	or	a		; set flags
	call	nz,install	; install new drive map
;
exit:	; clean up and return to command processor
	call	crlf		; formatting
	ld	sp,(stksav)	; restore stack
	jp	restart		; return to CP/M via restart
	ret			; return to CP/M w/o restart
;
; Initialization
;
init:
;
	; locate start of cbios (function jump table)
	ld	hl,(restart+1)	; load address of CP/M restart vector
	ld	de,-3		; adjustment for start of table
	add	hl,de		; HL now has start of table
	ld	(bioloc),hl	; save it
;
	; get CP/M version and save it
	ld	c,$0C		; function number
	call	bdos		; do it, HL := version
	ld	(cpmver),hl	; save it
	;push	hl		; *debug*
	;pop	bc		; *debug*
	;call	prthexword	; *debug*
	;ld	a,l		; low byte
	;cp	$30		; CP/M 3.0?
;
	; get location of config data and verify integrity
	ld	hl,stamp	; HL := adr or RomWBW zero page stamp
	ld	a,(hl)		; get first byte of RomWBW marker
	cp	'W'		; match?
	jp	nz,errinv	; abort with invalid config block
	inc	hl		; next byte (marker byte 2)
	ld	a,(hl)		; load it
	cp	~'W'		; match?
	jp	nz,errinv	; abort with invalid config block
	inc	hl		; next byte (major/minor version)
	ld	a,(hl)		; load it
	cp	RMJ << 4 | RMN	; match?
	jp	nz,errver	; abort with invalid os version
	inc	hl		; next byte (update/patch)
	ld	a,(hl)		; load it
	and	$F0		; eliminate patch num
	cp	RUP << 4	; match?
	jp	nz,errver	; abort with invalid os version
	inc	hl		; bump past version info
;
	; dereference HL to point to CBIOS extension data
	ld	a,(hl)		; dereference HL
	inc	hl		;   ... to point to
	ld	h,(hl)		;   ... ROMWBW config data block
	ld	l,a		;   ... in CBIOS
;
	; skip device map address
	inc	hl		; bump two bytes
	inc	hl		; ... past device map address entry
;
	; get location of drive map
	ld	e,(hl)		; dereference HL
	inc	hl		; ... into DE to get
	ld	d,(hl)		; ... drive map pointer
	inc	hl		; skip past drive map pointer
	ld	(maploc),de	; and save it
;
	; get location of dpbmap
	ld	e,(hl)		; dereference HL
	inc	hl		; ... into DE to get
	ld	d,(hl)		; ... DPB map pointer
	ld	(dpbloc),de	; and save it	
;
	; test for CP/M 3 and branch if so
	ld	a,(cpmver)	; low byte of cpm version
	cp	$30		; CP/M 3.0?
	jp	nc,initcpm3	; handle CP/M 3.0 or greater
;
	; make a local working copy of the drive map
	ld	hl,(maploc)	; copy from CBIOS drive map
	ld	de,mapwrk	; copy to working drive map
	dec	hl		; point to entry count
	ld	a,(hl)		; get entry count
	inc	hl		; restore hl pointer to drive map start
	add	a,a		; multiple a by
	add	a,a		; ... size of entries (4 bytes each)
	ld	c,a		; set BC := 0A
	ld 	b,0		; ... so BC is length to copy
	ldir			; do the copy
;
	; determine end of CBIOS (assume HBIOS for now)
	ld	hl,($FFFE)	; get proxy start address
	ld	(bioend),hl	; save as CBIOS end address
;
	; check for UNA (UBIOS)
	ld	a,($FFFD)	; fixed location of UNA API vector
	cp	$C3		; jp instruction?
	jr	nz,initx	; if not, not UNA
	ld	hl,($FFFE)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$FD		; first byte of UNA push ix instruction
	jr	nz,initx	; if not, not UNA
	inc	hl		; point to next byte
	ld	a,(hl)		; get next byte
	cp	$E5		; second byte of UNA push ix instruction
	jr	nz,initx	; if not, not UNA
	ld	hl,unamod	; point to UNA mode flag
	ld	(hl),$FF	; set UNA mode flag
	ld	c,$F1		; UNA func: Get HMA
	rst	08		; call UNA, HL := UNA proxy start address
	ld	(bioend),hl	; save as CBIOS end address
;
initx:
	; compute size of CBIOS
	ld	hl,(bioend)	; HL := end address
	ld	de,(bioloc)	; DE := starting address
	xor	a		; clear carry
	sbc	hl,de		; subtract to get size in HL
	ld	(biosiz),hl	; and save it
;
	; establish heap limit
	ld	hl,(bioend)	; HL := end of CBIOS address
	ld	de,-$40		; allow 40 bytes for CBIOS stack
	add	hl,de		; adjust
	ld	(heaplim),hl	; save it
;
#if 0
	ld	a,' '
	call	crlf
	ld	bc,(bioloc)
	call	prthexword
	call	prtchr
	ld	bc,(bioend)
	call	prthexword
	call	prtchr
	ld	bc,(maploc)
	call	prthexword
	call	prtchr
	ld	bc,(heaplim)
	call	prthexword
	
#endif
;
 	; return success
	xor	a		; signal success
	ret			; return
;
; CP/M 3 initialization
;
initcpm3:
	ld	a,22		; XBIOS DRVTBL function
	call	xbios		; Invoke XBIOS
	ld	(drvtbl),hl	; save DRVTBL address
;
; The CP/M 3 drvtbl is in common memory, but the XDPHs are not.
; So, here we temporarily swap the bank to the CP/M 3 system
; bank.  We cannot use the CP/M Direct BIOS call because it
; explicitly blocks use of SELMEM, so we are forced to use
; HBIOS call.  The CP/M 3 system bank is always the HBIOS
; user bank.
;
	; switch to sysbnk
	ld	a,($FFE0)	; get current bank
	push	af		; save it
	ld	bc,$F8F2	; HBIOS Get Bank Info
	rst	08		; call HBIOS, E=User Bank
	ld	a,e		; HBIOS User Bank
	call	bnksel		; HBIOS BNKSEL
;
	; copy CP/M 3 drvtbl to drvmap working copy
	ld	hl,(drvtbl)	; get drive table in HL
	ld	de,mapwrk	; DE := working drive map
	ld	b,16
initc2:
	push	hl		; save drvtbl entry adr
	ld	a,(hl)		; deref HL to get DPH adr
	inc	hl		; ...
	ld	h,(hl)		; ...
	ld	l,a		; ...
	ld	a,l		; check for
	or	h		; ... zero
	jr	nz,initc3	; if not zero, copy entry
	inc	de		; ... else bump past unit field
	jr	initc4		; ... and continue without copying
initc3:
	dec	hl		; back up to
	dec	hl		; ... unit
	ld	a,(hl)		; get unit from drvtbl
	ld	(de),a		; save unit to drvmap
	inc	hl		; bump to slice
	inc	de		; bump to slice
	ld	a,(hl)		; get slice from drvtbl
	ld	(de),a		; save slice to drvmap
initc4:	
	inc	de		; bump past slice
	inc	de		; skip
	inc	de		; ... dph
	pop	hl		; back to drvtbl entry
	inc	hl		; bump to
	inc	hl		; ... next drvtbl entry
	djnz	initc2
;
	; switch back to tpabnk
	pop	af		; recover prev bank
	call	bnksel		; HBIOS BNKSEL
;
 	; return success
	xor	a		; signal success
	ret			; return
;
; Process command line
;
process:
;
	; look for start of parms
	ld	hl,$81		; point to start of parm area (past len byte)
	call	nonblank	; skip to next non-blank char
	jp	z,showall	; no parms, show all active assignments
;
	; check for special option, introduced by a "/"
	cp	'/'		; start of usage request?
	jp	z,option	; yes, handle option
;
process0:
;
	sub	'A'		; make it binary
	ld	(dstdrv),a	; save it as destination drive
	inc	hl		; next char
	ld	a,(hl)		; get it
	cp	':'		; is it ':' as expected?
	jp	nz,errprm	; error if not
	inc	hl		; skip ':'
	call	nonblank	; skip possible blanks
	cp	'='		; proper delimiter?
	jr	z,process1	; yes, continue

	ld	de,drvshow	; show the drive
	ld	a,(dstdrv)	; load the drive
	jr	process4	; do it
;
process1:	; handle other side of '='
;
	inc	hl		; skip '='
	call	nonblank	; skip blanks as needed
	ld	de,drvdel	; assume a drive delete
	jp	z,process4	; continue to processing
	cp	','		; comma?
	jp	z,process4	; continue to processing
	call	getalpha	; gobble all alpha characters
	dec	b		; decrement num chars parsed
	jr	nz,process2	; more than 1 char, handle as device name
;
	; handle as drive swap
	cp	':'		; check for mandatory trailing colon
	jp	nz,errprm	; handle unexpected character
	inc	hl		; skip ':'
	ld	a,(tmpstr)	; get the drive letter
	sub	'A'		; make it binary
	ld	(srcdrv),a	; assume it is a src drv and save it
	ld	de,drvswap	; put routine to call in DE
	jr	process4	; and continue
;
process2:	; handle a device/slice assignment
;
	call	getnum		; get number from buffer
	jp	c,errnum	; abort on overflow
	cp	16		; compare to max
	jp	nc,errnum	; abort if too high
	ld	(unit),a	; save it as unit num
	ld	a,(hl)		; get terminating char
	cp	':'		; check for mandatory colon
	jp	nz,errprm	; handle unexpected character
	inc	hl		; skip past colon
	call	getnum		; get number from buffer
	jp	c,errnum	; abort on overflow
	ld	(slice),a	; save it as slice num
	ld	de,drvmap	; put routine to call in DE
	jr	process4	; and continue
;
process4:	; check for terminating null or comma
;
	call	nonblank	; skip possible blanks
	jr	z,process5	; null terminator OK
	cp	','		; check for comma
	jr	z,process5	; also OK
	jp	errprm		; otherwise parm error
;
process5:	; do the processing
;
	ex	de,hl		; move routine to call to HL
	push	de		; save command string pointer
	call	jphl		; do the work
	pop	hl		; recover command string pointer
	ret	nz		; abort on error
	ld	a,(hl)		; get the current cmd string char
	or	a		; set flags
	ret	z		; if null, we are done
	inc	hl		; otherwise, skip comma
	call	nonblank	; and possible blanks after comma
	ret	z		; get out if nothing more
	jp	process0	; we have more work, loop
;
; Handle special options
;
option:
;
	inc	hl		; next char
	ld	a,(hl)		; get it
	cp	'?'		; is it a '?' as expected?
	jp	z,usage		; yes, display usage
	cp	'L'		; is it a 'L', display device list?
	jp	z,devlist	; yes, display device list
	jp	errprm		; anything else is an error
;
usage:
;
	call	crlf		; formatting
	ld	de,msgban1	; point to version message part 1
	call	prtstr		; print it
	ld	de,msg22	; assume CP/M 2.2
	ld	a,(cpmver)	; low byte of ver
	cp	$30		; CP/M 3.0?
	jp	c,usage1	; if not, jump ahead
	ld	de,msg3		; CP/M 3
usage1:
	call	prtstr
	ld	de,msbban2	; next portion of banner
	call	prtstr
	ld	a,(unamod)	; get UNA flag
	or	a		; set flags
	ld	de,msghb	; point to HBIOS mode message
	call	z,prtstr	; if not UNA, say so
	ld	de,msgub	; point to UBIOS mode message
	call	nz,prtstr	; if UNA, say so
	call	crlf		; formatting
	ld	de,msgban3	; point to version message part 2
	call	prtstr		; print it
	call	crlf2		; blank line
	ld	de,msguse	; point to usage message
	call	prtstr		; print it
	or	$FF		; signal no action performed
	ret			; and return
;
devlist:
;
	ld	a,(unamod)	; get UNA mode flag
	or	a		; set flags
	jr	nz,devlstu	; do UNA mode dev list
;
	ld	b,$F8		; hbios func: sysget
	ld	c,$10		; sysget subfunc: diocnt
	rst	08		; call hbios, E := device count 
	ld	b,e		; use device count for loop count
	ld	c,0		; use C for device index
devlist1:
	call	crlf		; formatting
	ld	de,indent	; indent
	call	prtstr		; ... to look nice
	push	bc		; preserve loop control
	ld	a,c		; device to A
	call	prtdev		; print device mnemonic
	ld	a,':'		; colon for device/unit format
	call	prtchr		; print it
	pop	bc		; restore loop control
	inc	c		; next device index
	djnz	devlist1	; loop as needed
	or	$FF		; signal no action taken
	ret			; done
;
devlstu:
	; UNA mode device list
	ld	b,0		; use unit 0 to get count
	ld	c,$48		; una func: get disk type
	ld	l,0		; preset unit count to zero
	rst	08		; call una, b is assumed to be untouched!!!
	ld	a,l		; unit count to a
	or	a		; set flags
	ret	z		; no units, return
	ld	b,l		; unit count to b
	ld	c,0		; init unit index
devlstu1:
	call	crlf		; formatting
	ld	de,indent	; indent
	call	prtstr		; ... to look nice
	push	bc		; save loop control vars
	ld	a,c		; put unit num in A
	push	af		; save it
	call	prtdevu		; print the device name
	pop	af		; restore unit num
	call	prtdecb		; print unit num
	ld	a,':'		; colon delimiter
	call	prtchr		; print it
	pop	bc		; restore loop control
	inc	c		; next drive
	djnz	devlstu1	; loop as needed
	ret			; return
;
; Install the new drive map into CBIOS
;
install:
	ld	a,(cpmver)	; low byte of CP/M version
	cp	$30		; CP/M 3.0?
	jp	nc,instcpm3	; handle CP/M 3.0 or greater
;
	; capture CBIOS snapshot and stack frame for error recovery
	ld	hl,(bioloc)	; start of CBIOS
	ld	de,$1000	; save it here
	ld	bc,(biosiz)	; size of CBIOS
	ldir			; save it
	ld	(xstksav),sp	; save stack frame
	; clear CBIOS buffer area
	ld	hl,(maploc)	; start fill at drive map
	ld	a,(bioend + 1)	; msb of CBIOS end address to A
install1:
	ld	e,0		; fill with null
	ld	(hl),e		; fill next byte
	inc	hl		; point to next byte
	cp	h		; is H == msb of CBIOS end address?
	jr	nz,install1	; if not, loop
;
	; determine the drive map entry count
	ld	hl,mapwrk
	ld	c,0
	ld	b,16
install2:
	ld	a,$FF
	cp	(hl)
	jr	z,install3
	ld	e,c		; remember high water mark
install3:
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	inc	c
	djnz	install2
	inc	e		; convert from max value to count
;
	; record entry count in CBIOS
	ld	hl,(maploc)	; start of map
	dec	hl		; backup to entry count
	ld	(hl),e		; record count
;
	; copy map
	ld	a,e		; A := entry count
	add	a,a		; multiply by size
	add	a,a		; ... of entry (4 bytes)
	ld	c,a		; put in C for count
	ld	b,0		; msb of count is always zero
	ld	hl,mapwrk	; source of copy is work map
	ld	de,(maploc)	; target is CBIOS map loc
	ldir			; do it
;
	; set start of memory allocation heap
	ld	(heaptop),de	; DE has next byte available
;
	; allocate directory buffer
	ld	hl,128		; size of directory buffer
	call	alloc		; allocate the space
	jp	c,instovf	; handle overflow error
	ld	(dirbuf),hl	; ... and save in dirbuf
;
dph_init:
;
; iterate through drive map to build dph entries dynamically
;
	; setup for dph build loop
	ld	hl,(maploc)	; point to drive map
	dec	hl		; backup to entry count
	ld	b,(hl)		; loop drvcnt times
	ld	c,0		; drive index
	inc	hl		; bump to start of drive map
;
dph_init1:
	; no DPH if drive not assigned
	ld	a,(hl)
	cp	$FF
	jr	nz,dph_init2
	ld	de,0		; not assigned, use DPH pointer of zero
	jr	dph_init3
;
dph_init2:
	ld	a,(hl)		; unit to A
	push	bc		; save loop control
	push	hl		; save drive map pointer
	;ld	hl,16		; size of a DPH structure
	ld	hl,20		; size of a DPH structure
	call	alloc		; allocate space for dph
	jp	c,instovf	; handle overflow error
	push	hl		; save DPH location
	push	hl		; move DPH location
	pop	de		; ... to DE
	call	makdph		; make the DPH, unit in A from above
	pop	de		; restore DPH pointer to DE
	pop	hl		; restore drive map pointer to HL
	pop	bc		; restore loop control
;
dph_init3:
	inc	hl		; bump to slice loc
	inc	hl		; bump to DPH pointer lsb
	ld	(hl),e		; save lsb
	inc	hl		; bump to DPH pointer msb
	ld	(hl),d		; save msb
	inc	hl		; bump to start of next drive map entry
	inc	c		; next drive index
	djnz	dph_init1	; loop as needed
;
	; display free memory
	call	crlf2
	ld	de,indent
	call	prtstr
	ld	hl,(heaplim)	; subtract high water
	ld	de,(heaptop)	; ... from top of cbios
	or	a		; ... with cf clear
	sbc	hl,de		; ... so hl gets bytes free
	call	prtdecw		; print it
	ld	de,msgmem	; add description
	call	prtstr		; and print it
;
	call	drvrst		; perform BDOS drive reset
;	
	xor	a		; signal success
	ret			; done
;
makdph:
;
; make a dph at address in de for dev/unit in a
;
	push	de		; save incoming dph address
;
	ld	c,a		; save incoming dev/unit
	ld	a,(unamod)	; get UNA mode flag
	or	a		; set flags
	ld	a,c		; restore incoming dev/unit
	jr	nz,makdphuna	; do UNA mode
	jr	makdphwbw	; do WBW mode
;
makdphuna:	; determine appropriate dpb (WBW mode)
	ld	b,a		; unit num to b
	ld	c,$48		; una func: get disk type
	rst	08		; call una
	ld	a,d		; move disk type to a
;
	; derive dpb address based on disk type
	cp	$40		; ram/rom drive?
	jr	z,makdphuna1	; handle ram/rom drive if so
;	cp	$??		; floppy drive?
;	jr	z,xxxxx		; handle floppy
	ld	e,4		; assume hard disk
	jr	makdph0		; continue
;
makdphuna1:	; handle ram/rom
	ld	c,$45		; una func: get disk info
	ld	de,$9000	; 512 byte buffer *** fix!!! ***
	rst	08		; call una
	bit	7,b		; test ram drive bit
	ld	e,1		; assume rom
	jr	z,makdph0	; not set, rom drive, continue
	ld	e,2		; otherwise, must be ram drive
	jr	makdph0		; continue
;
makdphwbw:	; determine appropriate dpb (WBW mode, unit number in A)
;
	ld	c,a		; unit number to C
	ld	b,$17		; HBIOS: Report Device Info
	rst	08		; call HBIOS, return w/ device type in D, physical unit in E
	ld	a,d		; device type to A
	cp	$00		; ram/rom?
	jr	nz,makdph00	; if not, skip ahead to other types
	ld	a,e		; physical unit number to A
	ld	e,1		; assume rom
	cp	$01		; rom?
	jr	z,makdph0	; yes, jump ahead
	ld	e,2		; otherwise ram
	jr	makdph0		; jump ahead
makdph00:	
	ld	e,6		; assume floppy
	cp	$10		; floppy?
	jr	z,makdph0	; yes, jump ahead
	ld	e,3		; assume ram floppy
	cp	$20		; ram floppy?
	jr	z,makdph0	; yes, jump ahead
	ld	e,4		; everything else is assumed to be hard disk
	jr	makdph0		; yes, jump ahead
;
makdph0:
	ld	hl,(dpbloc)	; point to start of dpb table in CBIOS
	ld	a,e		; get index of target DPB to A
	add	a,a		; each entry is two bytes
	call	addhl		; add offset for desired DPB address
	ld	e,(hl)		; dereference HL
	inc	hl		; into DE, so DE
	ld	d,(hl)		; has address of target DPB
;
makdph1:
;
	; build the dph
	pop	hl		; hl := start of dph
	ld	a,8		; size of dph reserved area
	call	addhl		; leave it alone (zero filled)
;	
	ld	bc,(dirbuf)	; address of dirbuf
	ld	(hl),c		; plug dirbuf
	inc	hl		; ... into dph
	ld	(hl),b		; ... and bump
	inc	hl		; ... to next dph entry
;
	ld	(hl),e		; plug dpb address
	inc	hl		; ... into dph
	ld	(hl),d		; ... and bump
	inc	hl		; ... to next entry
	dec	de		; point
	dec	de		; ... to start
	dec	de		; ... of
	dec	de		; ... dpb
	dec	de		; ... prefix data (cks & als buf sizes)
	call	makdph2		; handle cks buf, then fall thru for als buf
	ret	nz		; bail out on error
;
makdph2:
	; DE = address of CKS or ALS buf to allocate
	; HL = address of field in DPH to get allocated address
	push	hl		; save DPH field ptr
	pop	bc		; into BC
;
	; HL := alloc size, DE bumped
	ex	de,hl
	ld	e,(hl)		; get size to allocate 
	inc	hl		; ...
	ld	d,(hl)		; ... into HL
	inc	hl		; and bump DE
	ex	de,hl
;
	; check for size of zero, special case
	ld	a,h		; check to see
	or	l		; ... if hl is zero
	jr	z,makdph3	; if so, jump ahead using hl as address
;
	; allocate memory
	call	alloc		; do the allocation
	jp	c,instovf	; bail out on overflow
	
makdph3:
	; swap hl and bc
	push	bc		; bc -> (sp)
	ex	(sp),hl		; (sp) -> hl, hl -> (sp)
	pop	bc		; (sp) -> bc
;
	; save allocated address
	ld	(hl),c		; save cks/als buf
	inc	hl		; ... address in
	ld	(hl),b		; ... dph and bump
	inc	hl		; ... to next dph entry	
	xor	a		; signal success
	ret
;
;
;
instcpm3:
	; swicth to sysbnk
	ld	a,($FFE0)	; get current bank
	push	af		; save it
	ld	bc,$F8F2	; HBIOS Get Bank Info
	rst	08		; call HBIOS, E=User Bank
	ld	a,e		; HBIOS User Bank
	call	$FFF3		; HBIOS BNKSEL
;
	; copy drvmap working copy to CP/M 3 drvtbl
	ld	hl,(drvtbl)	; get drvtbl address
	ld	a,(hl)		; deref HL to get DPH0 adr
	inc	hl		; ...
	ld	h,(hl)		; ...
	ld	l,a		; ...
	ld	(dphadr),hl	; save starting dphadr
	
	
	ld	hl,(drvtbl)	; get drive table in HL
	ld	de,mapwrk	; DE := working drive map
	ld	b,16
instc1:
	ld	a,(de)		; get unit field of mapwrk
	inc	a		; test for $FF
	jr	nz,instc2	; if used, do copy
	xor	a		; zero accum
	ld	(hl),a		; zero lsb of drvtbl entry adr
	inc	hl		; move to msb
	ld	(hl),a		; zero msb of drvtbl entry adr
	inc	hl		; bump to start of next drvtbl entry
	inc	de		; bump to next mapwrk entry
	inc	de		; ...
	inc	de		; ...
	inc	de		; ...
	jr	instc3		; resume loop without copy
;
instc2:	
	push	hl		; save drvtbl entry adr
	push	de		; save mapwrk entry adr
	ld	de,(dphadr)	; get cur dph adr
	ld	(hl),e		; save dph adr to drvtbl
	inc	hl		; ...
	ld	(hl),d		; ...
	ex	de,hl		; dph adr to HL
	pop	de		; restore mapwrk entry adr
	dec	hl		; backup to unit
	dec	hl		; ...
	ld	a,(de)		; get unit from mapwrk
	ld	(hl),a		; put unit into DPH field
	inc	de		; bump to slice field of mapwrk
	inc	hl		; bump to slice field of DPH field
	ld	a,(de)		; get slice from mapwrk
	ld	(hl),a		; put slice into DPH field
;	ld	a,11		; media byte is 11 bytes ahead
;	call	addhl		; bump HL to media byte adr
;	or	$FF		; use $FF to signify media change
;	ld	(hl),a		; set media flag byte
	inc	de		; bump to next mapwrk entry
	inc	de		; ...
	inc	de		; ...
	pop	hl		; back to drvtbl entry
	inc	hl		; bump to
	inc	hl		; ... next drvtbl entry
instc3:
	push	hl		; save drvtbl entry adr
	push	de		; save mapwrk entry adr
	ld	hl,(dphadr)	; get cur dph address
	ld	de,$27		; size of xdph
	add	hl,de		; bump to next dph
	ld	(dphadr),hl	; save it
	pop	de		; recover mapwrk entry adr
	pop	hl		; recover drvtbl entry adr
	djnz	instc1
;
	; switch back to tpabnk
	pop	af		; recover prev bank
	call	$FFF3		; HBIOS BNKSEL
;
	; set SCB drive door open flag
	ld	a,$54		; SCB drive door opened flag
	ld	(scboff),a	; set offset parm
	or	$FF		; SCB operation, $FF = set
	ld	(scbop),a	; set operation parm
	ld	(scbval),a	; set value parm to $FF
	ld	c,$31		; get/set system control block
	ld	de,scbpb	; scb parameter block adr
	call	bdos
;
	call	drvrst		; perform BDOS drive reset
;
	xor	a		; signal success
	ret
;
; Handle overflow error in installation
;
instovf:
	; restore stack frame and CBIOS image
	ld	sp,(xstksav)	; restore stack frame
	ld	hl,$1000	; start of CBIOS image buffer
	ld	de,(bioloc)	; start of CBIOS
	ld	bc,(biosiz)	; size of CBIOS
	ldir			; restore it
	jp	errovf
;
; Allocate HL bytes from heap
; Return pointer to allocated memory in HL
; On overflow error, C set
;
alloc:
	push	de		; save de so we can use it for work reg
	ld	de,(heaptop)	; get current heap top
	push	de		; and save for return value
	add	hl,de		; add requested space, hl := new heap top
	jr	c,allocx	; test for cpu memory space overflow
	ld	de,(heaplim)	; load de with heap limit
	ex	de,hl		; de=new heaptop, hl=heaplim
	sbc	hl,de		; heaplim - heaptop
	jr	c,allocx	; c set on overflow error
	; allocation succeeded, commit new heaptop              
	ld	(heaptop),de	; save new heaptop
allocx:                         
	pop	hl		; return value to hl
	pop	de		; recover de
	ret
;
; Scan drive map table for integrity
; Currently just checks for multiple drive 
;   letters referencing a single file system
;
valid:
	ld	hl,mapwrk	; point to working drive map table
	ld	b,16 - 1	; loop one less times than num entries
;
	; check that drive A: is assigned
	ld	a,$FF		; value that indicates unassigned
	cp	(hl)		; compare to A: value
	jp	z,errnoa	; handle failure
;
valid1:		; outer loop
;	call	crlf
	push	hl		; save pointer
	push	bc		; save loop control
	call	valid2		; do the inner loop
	pop	bc		; restore loop control
	pop	hl		; restore pointer
	jp	z,errint	; validation error
	ld	a,4		; 4 bytes per entry
	call	addhl		; bump to next entry
	djnz	valid1		; loop until done
	xor	a		; signal OK
	ret			; done
;
valid2:		; setup for inner loop
	push	hl		; save HL
	ld	a,4		; 4 bytes per entry
	call	addhl		; point to entry following
	pop	de		; de points to comparison entry
;
valid3:		; inner loop
	; bypass unassigned drives (only need to test 1)
	ld	a,(hl)		; get first drive unit in A
	cp	$FF		; unassigned?
	jr	z,valid4	; yes, skip
;
	; compare unit/slice values
	ld	a,(de)		; first byte to A
	cp	(hl)		; compare
	jr	nz,valid4	; if not equal, continue loop
	inc	de		; bump DE to next byte
	inc	hl		; bump HL to next byte
	ld	a,(de)		; first byte to A
	cp	(hl)		; compare
	ret	z		; both bytes equal, return signalling problem
	dec	de		; point DE back to first byte of comparison entry
	dec	hl		; point HL back
;
valid4:		; no match, loop
	inc	hl
	inc	hl		; bump HL
	inc	hl		; ... to
	inc	hl		; ... next entry
	or	$FF		; no match
	djnz	valid3		; loop as appropriate
	ret
;
; Show a specific drive assignment
;
drvshow:
	ld	a,(dstdrv)	; get the drive num
	call	chkdrv		; valid drive letter?
	ret	nz		; abort if not
	call	showone		; show it
	xor	a		; signal success
	ret			; done
;
; Delete (unassign) drive
;
drvdel:
	ld	a,(dstdrv)	; get the dest drive (to be unassigned)
	call	chkdrv		; valid drive letter?
	ret	nz		; abort if not
	; point to correct entry in drive map
	ld	hl,mapwrk	; point to working drive map
	ld	a,(dstdrv)	; get drive letter to remove
	rlca			; calc table offset
	rlca			; ... as drive num * 4
	call	addhl		; get final table offset
	; wipe out the drive letter
	ld	a,$FF		; dev/unit := $FF (unassigned)
	ld	(hl),a		; do it
	xor	a		; zero accum
	inc	hl		; slice := 0
	ld	(hl),a		; do it
	inc	hl		; DPH pointer lsb := 0
	ld	(hl),a		; do it
	inc	hl		; DPH pointer msb := 0
	ld	(hl),a		; do it
	; done
	ld	a,(dstdrv)	; get the destination
	call	showone		; show it
	ld	hl,modcnt	; point to mod count
	inc	(hl)		; increment it
	xor	a		; signal success
	ret
;
; Swap the source and destination drive letters
;
drvswap:
	ld	a,(dstdrv)	; get the destination drive
	call	chkdrv		; valid drive?
	ret	nz		; abort if not
	ld	a,(srcdrv)	; get the source drive
	call	chkdrv		; valid drive?
	ret	nz		; abort if not
	ld	hl,(drives)	; load source/dest in DE
	ld	a,h		; put source drive num in a
	cp	l		; compare to the dest drive num
	jp	z,errswp	; Invalid swap request, src == dest
;
	; Get pointer to source drive table entry
	ld	hl,mapwrk
	ld	a,(srcdrv)
	rlca
	rlca
	call	addhl
	ld	(srcptr),hl
;
	; Get pointer to destination drive table entry
	ld	hl,mapwrk
	ld	a,(dstdrv)
	rlca
	rlca
	call	addhl
	ld	(dstptr),hl
;	
	; 1) dest -> temp
	ld	hl,(dstptr)
	ld	de,tmpent
	ld	bc,4
	ldir
;
	; 2) source -> dest
	ld	hl,(srcptr)
	ld	de,(dstptr)
	ld	bc,4
	ldir
;
	; 3) temp -> source
	ld	hl,tmpent
	ld	de,(srcptr)
	ld	bc,4
	ldir
;
	; print the results
	ld	a,(dstdrv)	; get the destination
	call	showone		; show it
	ld	a,(srcdrv)	; get the source drive
	call	showone		; show it
;
	ld	hl,modcnt	; point to mod count
	inc	(hl)		; increment it
	xor	a		; signal success
	ret			; exit
;
; Assign drive to specified unit/slice
;
drvmap:
	; check for UNA mode
	ld	a,(unamod)	; get UNA mode flag
	or	a		; set flags
	jr	nz,drvmapu	; do UNA mode drvmap
;
		; determine device code by scanning for string
	ld	b,16		; device table always has 16 entries
	ld	c,0		; c is used to track table entry num
	ld	de,tmpstr	; de points to specified device name
	ld	hl,devtbl	; hl points to first entry of devtbl
;
drvmap1:	; loop through device table looking for a match
	push	hl		; save device table entry pointer
	ld	a,(hl)		; dereference HL
	inc	hl		;   ... to point to
	ld	h,(hl)		;   ... string
	ld	l,a		;   ... in device table
	push	de		; save string pointer
	push	bc		; save loop control stuff
	call	strcmp		; compare strings
	pop	bc		; restore loop control stuff
	pop	de		; restore de
	pop	hl		; restore table entry pointer
	jr	z,drvmap2	; match, continue
	inc	hl		; bump to next
	inc	hl		; device table pointer
	inc	c		; keep track of table entry num
	djnz	drvmap1		; and loop
	jp	errdev
;
drvmap2:	
	; convert index to device type id
	ld	a,c		; index to accum
	rlca			; move it to upper nibble
	rlca			; ...
	rlca			; ...
	rlca			; ...
	ld	(device),a	; save as device id
;
	; loop thru hbios units looking for device type/unit match
	ld	b,$F8		; hbios func: sysget
	ld	c,$10		; sysget subfunc: diocnt
	rst	08		; call hbios, E := device count 
	ld	b,e		; use device count for loop count
	ld	c,0		; use C for device index
drvmap3:
	push	bc		; preserve loop control
	ld	b,$17		; hbios func: diodevice
	rst	08		; call hbios, D := device, E := unit
	pop	bc		; restore loop control
	ld	a,(device)
	cp	d
	jr	nz,drvmap4
	ld	a,(unit)
	cp	e
	jr	z,drvmap5	; match, continue, C = BIOS unit
drvmap4:
	; continue looping
	inc	c
	djnz	drvmap3
	jp	errdev		; invalid device specified
;
drvmap5:
	; check for valid unit (supported by BIOS)
	push	bc		; save unit
	ld	a,c		; unit to A
	call	chkdev		; check validity
	pop	bc		; restore unit
	ret	nz		; bail out on error
	
	; resolve the CBIOS DPH table entry
	ld	a,(dstdrv)	; dest drv num to A
	call	chkdrv		; valid drive?
	ret	nz		; abort if invalid
	ld	hl,mapwrk	; point to start of drive map
	rlca			; multiply by
	rlca			; ... entry size of 4
	call	addhl		; adjust HL to point to entry
	ld	(dstptr),hl	; save it
;
	; shove updated unit/slice into the entry
	ld	(hl),c		; save unit byte
	inc	hl		; bump to next byte
	ld	a,(slice)
	ld	(hl),a		; save slice
;
	; finish up
	ld	a,(dstdrv)	; get the destination drive
	call	showone		; show it's new value
	ld	hl,modcnt	; point to mod count
	inc	(hl)		; increment it
	xor	a		; signal success
	ret			; exit
;
; UNA mode drive mapping
;
drvmapu:
;
	; verify the device nmeumonic
	ld	a,(unit)	; get unit specified
	ld	b,a		; put in b
	ld	d,0		; preset type to 0
	ld	c,$48		; una func: get disk type
	rst	08		; call una, b is assumed to be untouched!!!
	ld	a,d		; resultant device type to a
	cp	$40		; RAM/ROM
	jr	z,drvmapu0	; special case for RAM/ROM
	ld	de,udevide	; assume IDE
	cp	$41		; IDE?
	jr	z,drvmapu1	; do compare
	ld	de,udevppide	; assume PPIDE
	cp	$42		; PPIDE?
	jr	z,drvmapu1	; do compare
	ld	de,udevsd	; assume SD
	cp	$43		; SD?
	jr	z,drvmapu1	; do compare
	ld	de,udevdsd	; assume DSD
	cp	$44		; DSD?
	jr	z,drvmapu1	; do compare
	jp	errdev		; error, invalid device name
;
drvmapu0:
	; handle RAM/ROM
	ld	a,(unit)	; get unit specified
	ld	b,a		; unit num to B
	ld	c,$45		; UNA func: get disk info
	ld	de,$9000	; 512 byte buffer *** FIX!!! ***
	rst	08		; call UNA
	bit	7,b		; test RAM drive bit
	ld	de,udevrom	; assume ROM
	jr	z,drvmapu1	; do compare
	ld	de,udevram	; assume RAM
	jr	drvmapu1	; do compare
	jp	errdev		; error, invalid device name
;
drvmapu1:
	ld	hl,tmpstr	; point HL to specified device name
	call	strcmp		; compare
	jp	nz,errdev	; no match, invalid device name
;
	; check for valid unit (supported by BIOS)
	ld	a,(unit)	; get specified unit
	call	chkdevu		; check validity
	jp	nz,errdev	; invalid device specified
;
	; resolve the CBIOS DPH table entry
	ld	a,(dstdrv)	; dest drv num to A
	call	chkdrv		; valid drive?
	ret	nz		; abort if invalid
	ld	hl,mapwrk	; point to start of drive map
	rlca			; multiply by
	rlca			; ... entry size of 4
	call	addhl		; adjust HL to point to entry
	ld	(dstptr),hl	; save it
;
	; shove updated unit/slice into the entry
	ld	a,(unit)	; get specified unit
	ld	(hl),a		; save it
	inc	hl		; next byte is slice
	ld	a,(slice)	; get specified slice
	ld	(hl),a		; save it
;
	; finish up
	ld	a,(dstdrv)	; get the destination drive
	call	showone		; show it's new value
	ld	hl,modcnt	; point to mod count
	inc	(hl)		; increment it
	xor	a		; signal success
	ret
;
; Display all active drive letter assignments
;
showall:
	ld	b,16		; 16 drives possible
	ld	c,0		; map index (drive letter)
;
	ld	a,b		; load count
	or	$FF		; signal no action
	ret	z		; bail out if zero
;
showall1:	; loop
	ld	a,c		;
	push	bc		; save loop control
	call	showass
	pop	bc		; restore loop control
	inc	c
	djnz	showall1
	or	$FF
	ret
;
; Display drive letter assignment IF it is assigned
; Drive num in A
;
showass:
;
	; setup HL to point to desired entry in table
	ld	c,a		; save incoming drive in C
	ld	hl,mapwrk	; HL = address of drive map
	rlca
	rlca
	call	addhl		; HL = address of drive map table entry
	ld	a,(hl)		; get unit value
	cp	$FF		; compare to unassigned value
	ld	a,c		; recover original drive num
	ret	z		; bail out if unassigned drive
	; fall thru to display drive
;
; Display drive letter assignment for the drive num in A
;
showone:
;
	push	af		; save the incoming drive num
;
	call	crlf		; formatting
;
	ld	de,indent	; indent
	call	prtstr		; ... to look nice
;
	; setup HL to point to desired entry in table
	pop	af
	push	af
	ld	hl,mapwrk	; HL = address of drive map
	rlca
	rlca
	call	addhl		; HL = address of drive map table entry
	pop	af
;
	; render the drive letter based on table index
	add	a,'A'		; convert to alpha
	call	prtchr		; print it
	ld	a,':'		; conventional color after drive letter
	call	prtchr		; print it
	ld	a,'='		; use '=' to represent assignment
	call 	prtchr		; print it
;
	; render the map entry
	ld	a,(hl)		; load unit
	cp	$FF		; empty?
	ret	z		; yes, bypass
	push	hl		; preserve HL
	call	prtdev		; print device mnemonic
	ld	a,':'		; colon for device/unit format
	call	prtchr		; print it
	pop	hl		; recover HL
	inc	hl		; point to slice num
	ld	a,(hl)		; load slice num
	call	prtdecb		; print it
;
	ret
;
; Force BDOS to reset (logout) all drives
;
drvrst:
	ld	c,$0D		; BDOS Reset Disk function
	call	bdos		; do it
;
	ld	c,$25		; BDOS Reset Multiple Drives
	ld	de,$FFFF	; all drives
	call	bdos		; do it
;
	xor	a		; signal success
	ret
;
; Print device mnemonic based on device number in A
;
prtdev:
	ld	e,a		; stash incoming device num in E
	ld	a,(unamod)	; get UNA mode flag
	or	a		; set flags
	ld	a,e		; put device num back
	jr	nz,prtdevu	; print device in UNA mode
	ld	b,$17		; hbios func: diodevice
	ld	c,a		; unit to C
	rst	08		; call hbios, D := device, E := unit
	push	de		; save results
	ld	a,d		; device to A
	rrca			; isolate high nibble (device)
	rrca			;   ...
	rrca			;   ...
	rrca			;   ... into low nibble
	and	$0F		; mask out undesired bits
	push	hl		; save HL
	add	a,a		; multiple A by two for word table
	ld	hl,devtbl	; point to start of device name table
	call	addhl		; add A to hl to point to table entry
	ld	a,(hl)		; dereference hl to loc of device name string
	inc	hl		;   ...
	ld	d,(hl)		;   ...
	ld	e,a		;   ...
	call	prtstr		; print the device nmemonic
	pop	hl		; restore HL
	pop	de		; get device/unit data back
	ld	a,e		; device id to a
	call	prtdecb		; print it
	ret			; done
;
prtdevu:
	push	bc
	push	de
	push	hl
;	
	; UNA mode version of print device
	ld	b,a		; B := unit num
	push	bc		; save for later
	ld	c,$48		; UNA func: get disk type
	rst	08		; call UNA
	ld	a,d		; disk type to A
	pop	bc		; get unit num back in C
;
	; pick string based on disk type
	cp	$40		; RAM/ROM?
	jr	z,prtdevu1	; if so, handle it
	cp	$41		; IDE?
	ld	de,udevide	; load string
	jr	z,prtdevu2	; if IDE, print and return
	cp	$42		; PPIDE?
	ld	de,udevppide	; load string
	jr	z,prtdevu2	; if PPIDE, print and return
	cp	$43		; SD?
	ld	de,udevsd	; load string
	jr	z,prtdevu2	; if SD, print and return
	cp	$44		; DSD?
	ld	de,udevdsd	; load string
	jr	z,prtdevu2	; if DSD, print and return
	ld	de,udevunk	; load string for unknown
	jr	prtdevu2	; and print it
;
prtdevu1:
	; handle RAM/ROM
	push	bc		; save unit num
	ld	c,$45		; UNA func: get disk info
	ld	de,$9000	; 512 byte buffer *** FIX!!! ***
	rst	08		; call UNA
	bit	7,b		; test RAM drive bit
	pop	bc		; restore unit num
	ld	de,udevrom	; load string
	jr	z,prtdevu2	; print and return
	ld	de,udevram	; load string
	jr	prtdevu2	; print and return
;
prtdevu2:
	call	prtstr		; print the device nmemonic
	ld	a,b		; get the unit num back
	call	prtdecb		; append it
	pop	hl
	pop	de
	pop	bc
	ret
;
; Check that specified drive num is valid
;
chkdrv:
	cp	16		; max of 16 drive letters
	jp	nc,errdrv	; handle bad drive
	cp	a		; set Z to signal good
	ret			; and return
;
; Check that the unit value in A is valid
; according to active BIOS support.
;
;
chkdev:		; HBIOS variant
	push	af		; save incoming unit
	ld	b,$F8		; hbios func: sysget
	ld	c,$10		; sysget subfunc: diocnt
	rst	08		; call hbios, E := device count
	pop	af		; restore incoming unit
	cp	e		; compare to unit count
	jp	nc,errdev	; if too high, error
;
	; get device/unit info
	ld	b,$17		; hbios func: diodevice
	ld	c,a		; unit to C
	rst	08		; call hbios, D := device, E := unit
	ld	a,d		; device to A
;
	; check slice support
	cp	$30		; A has device/unit, in hard disk range?
	jr	c,chkdev1	; if not hard disk, check slice val
	xor	a		; otherwise, signal OK
	ret
;
chkdev1:	; not a hard disk, make sure slice == 0
	ld	a,(slice)	; get specified slice
	or	a		; set flags
	jp	nz,errslc	; invalid slice error
	xor	a		; signal OK
	ret
;
chkdevu:	; UNA variant
	ld	b,a		; put in b
	ld	d,0		; preset type to 0
	ld	c,$48		; una func: get disk type
	rst	08		; call una
	ld	a,d		; resultant device type to a
	or	a		; set flags
	jp	z,errdev	; invalid if 0
;
	; check for slice support, if required
	cp	$40		; ram/rom?
	jr	z,chkdevu1	; yes, check for slice
;	cp	$??		; floppy?
;	jr	z,chkdevu1	; yes, check for slice
	xor	a		; otherwise signal success
	ret			; and return
;
chkdevu1:
	ld	a,(slice)	; get specified slice
	or	a		; set flags
	jp	nz,errslc	; invalid slice error
	xor	a		; otherwise, signal OK
	ret			; and return
;
; Print character in A without destroying any registers
;
prtchr:
	push	bc		; save registers
	push	de
	push	hl
	ld	e,a		; character to print in E
	ld	c,$02		; BDOS function to output a character
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	ret
;
prtdot:
;
	; shortcut to print a dot preserving all regs
	push	af		; save af
	ld	a,'.'		; load dot char
	call	prtchr		; print it
	pop	af		; restore af
	ret			; done
;
; Print a zero terminated string at (HL) without destroying any registers
;
prtstr:
	push	de
;
prtstr1:
	ld	a,(de)		; get next char
	or	a
	jr	z,prtstr2
	call	prtchr
	inc	de
	jr	prtstr1
;
prtstr2:
	pop	de		; restore registers
	ret	
;
; Print the value in A in hex without destroying any registers
;
prthex:
	push	af		; save AF
	push	de		; save DE
	call	hexascii	; convert value in A to hex chars in DE
	ld	a,d		; get the high order hex char
	call	prtchr		; print it
	ld	a,e		; get the low order hex char
	call	prtchr		; print it
	pop	de		; restore DE
	pop	af		; restore AF
	ret			; done
;
; print the hex word value in bc
;
prthexword:
	push	af
	ld	a,b
	call	prthex
	ld	a,c
	call	prthex 
	pop	af
	ret
;
; Convert binary value in A to ascii hex characters in DE
;
hexascii:
	ld	d,a		; save A in D
	call	hexconv		; convert low nibble of A to hex
	ld	e,a		; save it in E
	ld	a,d		; get original value back
	rlca			; rotate high order nibble to low bits
	rlca
	rlca
	rlca
	call	hexconv		; convert nibble
	ld	d,a		; save it in D
	ret			; done
;
; Convert low nibble of A to ascii hex
;
hexconv:
	and	$0F	     	; low nibble only
	add	a,$90
	daa	
	adc	a,$40
	daa	
	ret
;
; Print value of A or HL in decimal with leading zero suppression
; Use prtdecb for A or prtdecw for HL
;
prtdecb:
	push	hl
	ld	h,0
	ld	l,a
	call	prtdecw		; print it
	pop	hl
	ret
;
prtdecw:
	push	af
	push	bc
	push	de
	push	hl
	call	prtdec0
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
prtdec0:
	ld	e,'0'
	ld	bc,-10000
	call	prtdec1
	ld	bc,-1000
	call	prtdec1
	ld	bc,-100
	call	prtdec1
	ld	c,-10
	call	prtdec1
	ld	e,0
	ld	c,-1
prtdec1:
	ld	a,'0' - 1
prtdec2:
	inc	a
	add	hl,bc
	jr	c,prtdec2
	sbc	hl,bc
	cp	e
	ret	z
	ld	e,0
	call	prtchr
	ret
;
; Print a byte buffer in hex pointed to by DE
; Register A has size of buffer
;
prthexbuf:
	or	a
	ret	z		; empty buffer
;
	ld	b,a
prthexbuf1:
	ld	a,' '
	call	prtchr
	ld	a,(de)
	call	prthex
	inc	de
	djnz	prthexbuf1
	ret
;
; Start a new line
;
crlf2:
	call	crlf		; two of them
crlf:
	push	af		; preserve AF
	ld	a,13		; <CR>
	call	prtchr		; print it
	ld	a,10		; <LF>
	call	prtchr		; print it
	pop	af		; restore AF
	ret
;
; Get the next non-blank character from (HL).
;
nonblank:
	ld	a,(hl)		; load next character
	or	a		; string ends with a null
	ret	z		; if null, return pointing to null
	cp	' '		; check for blank
	ret	nz		; return if not blank
	inc	hl		; if blank, increment character pointer
	jr	nonblank	; and loop
;
; Check character at (DE) for delimiter.
;
delim:	or	a
	ret	z
	cp	' '		; blank
	ret	z
	jr	c,delim1	; handle control characters
	cp	'='		; equal
	ret	z
	cp	'_'		; underscore
	ret	z
	cp	'.'		; period
	ret	z
	cp	':'		; colon
	ret	z
	cp	$3B		; semicolon
	ret	z
	cp	'<'		; less than
	ret	z
	cp	'>'		; greater than
	ret
delim1:
	; treat control chars as delimiters
	xor	a		; set Z
	ret			; return
;
; Get alpha chars and save in tmpstr
; return with terminating char in A and flags set
; return with num chars in B
;
getalpha:
;
	ld	de,tmpstr	; location to save chars
	ld	b,0		; length counter
;
getalpha1:
	ld	a,(hl)		; get active char
	cp	'A'		; check for start of alpha range
	jr	c,getalpha2	; not alpha, get out
	cp	'Z' + 1		; check for end of alpha range
	jr	nc,getalpha2	; not alpha, get out
	; handle alpha char
	inc	hl		; increment buffer ptr
	ld	(de),a		; save it
	inc	de		; inc string pointer
	inc	b		; inc string length
	ld	a,b		; put length in A
	cp	8		; max length?
	jr	z,getalpha2	; if max, get out
	jr	getalpha1	; and loop
;
getalpha2:	; non-alpha, clean up and return
	xor	a		; clear accum
	ld	(de),a		; terminate string
	ld	a,(hl)		; recover terminating char
	or	a		; set flags
	ret			; and done
;
; Get numeric chars and convert to number returned in A
; Carry flag set on overflow
;
getnum:
	ld	c,0		; C is working register
getnum1:
	ld	a,(hl)		; get the active char
	cp	'0'		; compare to ascii '0'
	jr	c,getnum2	; abort if below
	cp	'9' + 1		; compare to ascii '9'
	jr	nc,getnum2	; abort if above\
;
	; valid digit, add new digit to C
	ld	a,c		; get working value to A
	rlca			; multiply by 10
	ret	c		; overflow, return with carry set
	rlca			; ...
	ret	c		; overflow, return with carry set
	add	a,c		; ...
	ret	c		; overflow, return with carry set
	rlca			; ...
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
	ld	a,(hl)		; get new digit
	sub	'0'		; make binary
	add	a,c		; add in working value
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
;
	inc	hl		; bump to next char
	jr	getnum1		; loop
;
getnum2:	; return result
	ld	a,c		; return result in A
	or	a		; with flags set, CF is cleared
	ret
;
; Compare null terminated strings at HL & DE
; If equal return with Z set, else NZ
;
strcmp:
;
	ld	a,(de)		; get current source char
	cp	(hl)		; compare to current dest char
	ret	nz		; compare failed, return with NZ
	or	a		; set flags
	ret	z		; end of string, match, return with Z set
	inc	de		; point to next char in source
	inc	hl		; point to next char in dest
	jr	strcmp		; loop till done
;
; Invoke CBIOS function
; The CBIOS function offset must be stored in the byte
; following the call instruction.  ex:
;	call	cbios
;	.db	$0C		; offset of CONOUT CBIOS function
;
cbios:
	ex	(sp),hl
	ld	a,(hl)		; get the function offset
	inc	hl		; point past value following call instruction
	ex	(sp),hl		; put address back at top of stack and recover HL
	ld	hl,(bioloc)	; address of CBIOS function table to HL
	call	addhl		; determine specific function address
	jp	(hl)		; invoke CBIOS
;
; Routine to call CPM3 BIOS routines via BDOS
; function 50.
;
xbios:
	ld	(biofnc),a	; set BIOS function
	ld	c,50		; direct BIOS call function
	ld	(dereg),de	; set DE parm
	ld	de,biospb	; BIOS parameter block
	jp	bdos		; invoke BDOS
;
biospb:
biofnc	.db	0		; BIOS function
areg	.db	0		; A register
bcreg	.dw	0		; BC register
dereg	.dw	0		; DE register
hlreg	.dw	0		; HL register
;
; Add the value in A to HL (HL := HL + A)
;
addhl:
	add	a,l		; A := A + L
	ld	l,a		; Put result back in L
	ret	nc		; if no carry, we are done
	inc	h		; if carry, increment H
	ret			; and return
;
; Jump indirect to address in HL
;
jphl:
	jp	(hl)
;
; Errors
;
erruse:	; command usage error (syntax)
	ld	de,msguse
	jr	err
;
errprm:	; command parameter error (syntax)
	ld	de,msgprm
	jr	err
;
errinv:	; invalid CBIOS, zp signature not found
	ld	de,msginv
	jr	err
;
errver:	; CBIOS version is not as expected
	ld	de,msgver
	jr	err
;
errdrv:	; Invalid drive letter specified
	push	af
	call	crlf
	ld	de,msgdrv1
	call	prtstr
	pop	af
	add	a,'A'
	call	prtchr
	ld	de,msgdrv2
	jr	err1
;
errswp:	; invalid drive swap request
	ld	de,msgswp
	jr	err
;
errdev:	; invalid device name
	ld	de,msgdev
	jr	err
;
errslc:	; invalid slice
	ld	de,msgslc
	jr	err
;
errtyp:	; invalid device assignment request (not a hard disk device type)
	ld	de,msgtyp
	jr	err
;
errnum:	; invalid number parsed, overflow
	ld	de,msgnum
	jr	err
;
errint:	; DPH table integrity error (multiple drives ref one filesystem)
	ld	de,msgint
	jr	err
;
errnoa:	; No A: drive assignment
	ld	de,msgnoa
	jr	err
;
errovf:	; CBIOS disk buffer overflow
	ld	de,msgovf
	jr	err
;
errdos:	; handle BDOS errors
	push	af		; save return code
	call	crlf		; newline
	ld	de,msgdos	; load
	call	prtstr		; and print error string
	pop	af		; recover return code
	call	prthex		; print error code
	jr	err2
;
err:	; print error string and return error signal
	call	crlf2		; print double newline
;
err1:	; without the leading crlf
	call	prtstr		; print error string
;
err2:	; without the string
;	call	crlf		; print newline
	or	$FF		; signal error
	ret			; done
;
;===============================================================================
; Storage Section
;===============================================================================
;
;
bioloc	.dw	0		; CBIOS starting address
bioend	.dw	0		; CBIOS ending address
biosiz	.dw	0		; CBIOS size (in bytes)
maploc	.dw	0		; location of CBIOS drive map table
dpbloc	.dw	0		; location of CBIOS DPB map table
cpmver	.dw	0		; CP/M version
drvtbl	.dw	0		; CP/M 3 drive table address
dphadr	.dw	0		; CP/M 3 working value for DPH
;
drives:
dstdrv	.db	0		; destination drive
srcdrv	.db	0		; source drive
device	.db	0		; source device
unit	.db	0		; source unit
slice	.db	0		; source slice
;
unamod	.db	0		; $FF indicates UNA UBIOS active
modcnt	.db	0		; count of drive map modifications
;
srcptr	.dw	0		; source pointer for copy
dstptr	.dw	0		; destination pointer for copy
tmpent	.fill	4,0		; space to save a table entry
tmpstr	.fill	9,0		; temporary string of up to 8 chars, zero term
;
heaptop	.dw	0		; current address of top of heap memory
heaplim	.dw	0		; heap limit address
;
dirbuf	.dw	0		; directory buffer location
;
scbpb:	; BDOS SCB get/set parm block
scboff	.db	$54		; media open door flag
scbop	.db	$FF		; set a byte
scbval	.dw	$FF		; value to set
;
mapwrk	.fill	(4 * 16),$FF	; working copy of drive map
;
devtbl:				; device table
	.dw	dev00, dev01, dev02, dev03
	.dw	dev04, dev05, dev06, dev07
	.dw	dev08, dev09, dev10, dev11
	.dw	dev12, dev13, dev14, dev15
;
devunk	.db	"?",0
dev00	.db	"MD",0
dev01	.db	"FD",0
dev02	.db	"RAMF",0
dev03	.db	"IDE",0
dev04	.db	"ATAPI",0
dev05	.db	"PPIDE",0
dev06	.db	"SD",0
dev07	.db	"PRPSD",0
dev08	.db	"PPPSD",0
dev09	.db	"HDSK",0
dev10	.equ	devunk
dev11	.equ	devunk
dev12	.equ	devunk
dev13	.equ	devunk
dev14	.equ	devunk
dev15	.equ	devunk
;
devcnt	.equ	10		; 10 devices defined
;
udevram		.db	"RAM",0
udevrom		.db	"ROM",0
udevide		.db	"IDE",0
udevppide	.db	"PPIDE",0
udevsd		.db	"SD",0
udevdsd		.db	"DSD",0
udevunk		.db	"UNK",0
;
stksav	.dw	0		; stack pointer saved at start
xstksav	.dw	0		; temp stack save for error recovery
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Messages
;
indent	.db	"   ",0
msgban1	.db	"ASSIGN v1.5 for RomWBW CP/M ",0
msg22	.db	"2.2",0
msg3	.db	"3",0
msbban2	.db	", 28-Feb-2022",0
msghb	.db	" (HBIOS Mode)",0
msgub	.db	" (UBIOS Mode)",0
msgban3	.db	"Copyright 2021, Wayne Warthen, GNU GPL v3",0
msguse	.db	"Usage: ASSIGN D:[=[{D:|<device>[<unitnum>]:[<slicenum>]}]][,...]",13,10
	.db	"  ex. ASSIGN           (display all active assignments)",13,10
	.db	"      ASSIGN /?        (display version and usage)",13,10
	.db	"      ASSIGN /L        (display all possible devices)",13,10
	.db	"      ASSIGN C:=D:     (swaps C: and D:)",13,10
	.db	"      ASSIGN C:=FD0:   (assign C: to floppy unit 0)",13,10
	.db	"      ASSIGN C:=IDE0:1 (assign C: to IDE unit0, slice 1)",13,10
	.db	"      ASSIGN C:=       (unassign C:)",0
msgprm	.db	"Parameter error (ASSIGN /? for usage)",0
msginv	.db	"Unexpected CBIOS (signature missing)",0
msgver	.db	"Unexpected CBIOS version",0
msgdrv1	.db	"Invalid drive letter (",0
msgdrv2	.db	":)",0
msgswp	.db	"Invalid drive swap request",0
msgdev	.db	"Invalid device name (ASSIGN /L for device list)",0
msgslc	.db	"Specified device does not support slices",0
msgnum	.db	"Unit or slice number invalid",0
msgovf	.db	"Disk buffer exceeded in CBIOS, aborted",0
msgtyp	.db	"Only hard drive devices can be reassigned",0
msgint	.db	"Multiple drive letters reference one filesystem, aborting!",0
msgnoa	.db	"Drive A: is unassigned, aborting!",0
msgdos	.db	"DOS error, return code=0x",0
msgmem	.db	" Disk Buffer Bytes Free",0
;
modsize	.equ	$ - start
;
	.end
