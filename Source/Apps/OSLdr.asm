;===============================================================================
; OSLdr - Load a new OS image from filesystem on running system.
;         Optionally, load a new HBIOS image at the same time.
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   OSLDR /F <osimg> [<biosimg>]
;     /F (force) overrides all compatibility checking
;   ex. OSLDR CPM.SYS
;       OSLDR CPM.SYS HBIOS.BIO
;
;   <osimg> is an os image file such as cpm.sys or zsys.sys
;   <biosimg> is an optional bios image such as hbios.bio
;_______________________________________________________________________________
;
; Operation:
;   This application reads an OS image (and optionally HBIOS image)
;   into TPA memory from the filesystem.  It then copies the images to
;   their appropriate locations and restarts the system.
;   Note that the application itself is relocated to upper memory
;   after starting so that it can manipulate the lower memory bank.
;
;   The application uses the following memory layout:
;
;   Loc          Size   Usage
;   -----        -----  -----------------------------
;   $0400-$3FFF  $3C00  OS Image (max of 15K possible)
;   $4000-$BFFF  $8000  HBIOS Image (32K fixed size)
;   $C000-$CFFF  $1000  Application (after relocation)
;
; Notes:
;  1) Drive assignments are not retained.  Drive assignments are
;     reset during the OS boot.
;  2) The OS boot drive is not explicitly set by this app.  If a new
;     HBIOS image is not loaded, the boot drive passed to the OS will
;     be the same as it was at the last boot.  If a new HBIOS image
;     is being loaded, the boot drive will be the default imbedded in
;     the HBIOS image.
;  3) It is not possible to load a new UNA BIOS.  However, when the
;     app is run under UNA, it can load a new OS image and optionally
;     load an HBIOS image.
;_______________________________________________________________________________
;
; Change Log:
;_______________________________________________________________________________
;
; ToDo:
;_______________________________________________________________________________
;
; Known Issues:
;  1) App will fail badly if OS image exceeds 15K
;  2) No attempt is made to match the BIOS image version against
;     the running BIOS version.  This is intended behavior and is
;     to allow a different BIOS version to be tested.  A failure
;     could occur if the BIOS image does not conform to the
;     expected structure (size, meta data location, entry point
;     location, etc.)
;  3) Hardware platform has been removed from the bootloader, so the
;     platform check has been removed for OS loading.  This is fine
;     unless you attempt to switch between UNA and RomWBW.
;_______________________________________________________________________________
;
;===============================================================================
; Definitions
;===============================================================================
;
stksiz	.equ	$40		; we are a stack pig
;
restart	.equ	$0000		; CP/M restart vector
bdos	.equ	$0005		; BDOS invocation vector
;
; Memory layout (see Operation description above)
;
osimg	.equ	$0400		; OS image load location (max 15K)
hbimg	.equ	$4000		; HBIOS image load location (32K fixed)
runloc	.equ	$C000		; running location (after relocation)
;
; Below are offsets in OS image of specific data fields
; The first 1.5K of the OS image is a header
;
hdrsiz	.equ	$600		; Len of OS image header (3 sectors)
ossig	.equ	osimg + $580	; Signature ($A55A)
osplt	.equ	osimg + $582	; Platform ID
osver	.equ	osimg + $5E3	; Version (4 bytes, maj, min, up, pat)
osloc	.equ	osimg + $5FA	; Intended address to load OS image
osend	.equ	osimg + $5FC	; Ending load address of OS image
osent	.equ	osimg + $5FE	; Entry point for OS image
osbin	.equ	osimg + hdrsiz	; Start of actual OS binary (after header)
;
; HBIOS internal info (adjust if HBIOS changes)
;
bfgbnk	.equ	$F3		; HBIOS Get Bank function
bfver	.equ	$F1		; HBIOS Get Version function
sigptr	.equ	hbimg + 3	; HBIOS signature pointer
hbmrk	.equ	hbimg + $100	; HBIOS marker
hbver	.equ	hbimg + $102	; HBIOS version
hbplt	.equ	hbimg + $104	; HBIOS platform
bidusr	.equ	hbimg + $10B	; User bank id
bidbios	.equ	hbimg + $10C	; BIOS bank id
pxyimg	.equ	hbimg + $200	; Proxy image offset within HBIOS image
pxyloc	.equ	$FE00		; Proxy run location
pxysiz	.equ	$0200		; Proxy size
srcbnk	.equ	$FFE4		; Address of bank copy source bank id
dstbnk	.equ	$FFE7		; Address of bank copy destination bank id
curbnk	.equ	$FFE0		; Address of current bank id in hbios proxy
hbxbnk	.equ	$FFF3		; Bank select function entry address
hbxcpy	.equ	$FFF6		; Bank copy function entry address
;
;===============================================================================
; Code Section
;===============================================================================
;
	.org	$100		; startup org

	; relocate ourselves to upper memory
	ld	hl,$0000	; from startup location
	ld	de,runloc	; to running location
	ld	bc,$0800	; assume we are no more that 2048 bytes
	ldir			; copy ourselves
	jp	phase2		; jump to new location

	.org	$ + runloc	; adjust for phase 2 location
phase2:
	; setup stack (save old value)
	ld	(stksav),sp	; save stack
	ld	sp,stack	; set new stack
	
	; processing...
	call	main		; do the real work
	call	crlf		; formatting

	; return (we only get here if an error occurs)
	jp	0		; return to CP/M via reset
;
; Main routine
;
main:
	call	init		; initialize
	ret	nz		; abort on failure

	call	parse		; parse command tail
	ret	nz		; abort on failure

;	call	confirm		; confirm pending action
;	ret	nz		; abort on failure

	call	crlf2		; formatting

	; Read OS image into TPA
	call	rdos		; do the os read
	ret	nz		; abort on failure
	
	; If specified, read BIOS image
	ld	a,(newbio)	; get BIOS load flag
	or	a		; set flags
	call	nz,rdbio	; do the bios read
	ret	nz		; abort on failure
	
	call	crlf		; formatting
	
	; If force flag set, bypass image validitity checking
	ld	a,(force)	; load the flag
	or	a		; set flags
	jr	nz,main1	; if set, bypass checks

	; Check BIOS Image is acceptable
	ld	a,(newbio)	; get BIOS load flag
	or	a		; set flags
	call	nz,chkbios	; check the bios image
	ret	nz		; abort on failure

	; Check OS Image is acceptable for requested operation
	call	chkos		; check the os image
	ret	nz		; abort on failure

main1:
	; Load OS image into upper memory OS location
	call	ldos		; load OS
	ret	nz		; abort on failure

	; If specified, load BIOS image to BIOS bank
	ld	a,(newbio)	; get BIOS load flag
	or	a		; set flags
	jr	z,main3		; if not set, skip BIOS load and init
	call	ldbio		; load BIOS
	ret	nz		; abort on failure

	; Initialize BIOS
	call	initbio		; initialize BIOS

main3:
	; Launch...
	ld	hl,(osent)	; OS entry point
	jp	(hl)		; jump to OS BOOT vector
;
; Initialization
;
init:
	call	crlf
	ld	de,msgban	; point to banner
	call	prtstr		; display it

	; locate cbios function table address
	ld	hl,(restart+1)	; load address of CP/M restart vector
	ld	de,-3		; adjustment for start of table
	add	hl,de		; HL now has start of table
	ld	(cbftbl),hl	; save it

	; save current drive no
	ld	c,$19		; bdos func: get current drive
	call	bdos		; invoke BDOS function
	inc	a		; 1-based index for fcb
	ld	(defdrv),a	; save it

	; check for UNA (UBIOS)
	ld	de,msghb	; assume HBIOS (point to HBIOS mode string)
	ld	a,($fffd)	; fixed location of UNA API vector
	cp	$c3		; jp instruction?
	jr	nz,init1	; if not, not UNA
	ld	hl,($fffe)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$fd		; first byte of UNA push ix instruction
	jr	nz,init1	; if not, not UNA
	inc	hl		; point to next byte
	ld	a,(hl)		; get next byte
	cp	$e5		; second byte of UNA push ix instruction
	jr	nz,init1	; if not, not UNA
	ld	hl,unamod	; point to UNA mode flag
	ld	(hl),$ff	; set UNA mode
	ld	a,6		; UNA platform ID
	ld	(bioplt),a	; save it
	ld	de,msgub	; point to UBIOS string

init1:
	call	prtstr		; print BIOS name

	; if HBIOS active, get version number
	ld	a,(unamod)	; get UNA mode flag
	or	a		; set flags
	jr	nz,init2	; skip if UNA BIOS active
	ld	b,bfver		; HBIOS func: get version
	rst	08		; do it
	ld	a,l		; platform to A
	ld	(bioplt),a	; save platform
	ld	h,e		; switch bytes
	ld	l,d		; ... to save as maj/min, up/pat
	ld	(biover),hl	; save version
	ld	b,bfgbnk	; HBIOS func: get current bank
	rst	08		; do it
	ld	a,c		; move to A
	ld	(tpabnk),a	; save it

init2:
	; return success
	xor	a
	ret
;
; Parse command tail
;
parse:
	ld	hl,$81		; point to start of command tail (after length byte)
	call	nonblank	; locate start of parms
	jp	z,erruse	; no parms
	call	options		; process options
	ret	nz		; abort if error
	ld	de,osfcb	; point to os image fcb
	call	convert		; convert destination spec
	jp	nz,erramb	; Error, ambiguous file specification
	call	nonblank	; skip blanks
	or	a		; end of command tail (null)?
	jr	z,parse1	; if end, skip bios image fcb
	ld	de,biofcb	; point to bios image fcb
	call	convert		; convert spec to fcb
	jp	nz,erramb	; Error, ambiguous file specification
	or	$FF		; flag = true
	ld	(newbio),a	; set newbio flag to true
;
parse1:
	; return success
	xor	a		; signal success
	ret			; done parsing
;
options:
	; process options
	cp	'/'		; option introducer?
	jr	nz,options2	; if not '/' exit with success
	inc	hl		; bump past option introducer
	ld	a,(hl)		; get the next character
	cp	'F'		; compare to 'F'
	jr	z,optf		; handle if so
	jp	erruse		; bail out if unexpected option

options1:
	; post-processing after option
	inc	hl		; move past option
	call	nonblank	; skip blanks
	jr	options		; loop

options2:
	; success exit
	xor	a		; signal success
	ret

optf:
	; set force flag
	or	$FF		; load true
	ld	(force),a	; set flag
	jr	options1	; done
;
; Confirm pending action with user
;
confirm:
;	; prompt
;	call	crlf
;	ld	de,sconf1
;	call	prtstr
;	ld	hl,biofcb
;	call	prtfcb
;	ld	de,sconf2
;	call	prtstr
;	ld	hl,osfcb
;	call	prtfcb
;	ld	de,sconf3
;	call	prtstr
;;
;	; get input
;	ld	c,$0A		; get console buffer
;	ld	de,osimg	; into buf
;	ld	a,1		; max of 1 character
;	ld	(de),a		; set up buffer
;	call	bdos		; invoke BDOS
;	ld	a,(osimg+1)	; get num chars entered
;	dec	a		; check that we got exactly one char
;	jr	nz,confirm	; bad input, re-prompt
;	ld	a,(osimg+2)	; get the character
;	and	$DF		; force upper case
;	cp	'Y'		; compare to Y
	xor	a		; *temp*
	ret			; return with Z set appropriately
;
; Read OS image file into memory
;
rdos:
	ld	de,msgros	; point to "Reading OS" message
	call	prtstr		; display it

	; open the file
	ld	c,$0F		; bdos open file
	ld	de,osfcb	; bios image fcb
	ld	(rwfcb),de	; save it
	call	bdos		; invoke bdos function
	cp	$FF		; $FF is error
	jp	z,errfil	; handle error condition
	; read the header
	ld	a,$14		; setup for bdos read sequential
	ld	(rwfun),a	; save bdos function
	ld	a,12		; start with 1536 byte header (12 records)
	ld	(reccnt),a	; init record counter
	ld	hl,osimg	; start of buffer
	ld	(bufptr),hl	; init buffer pointer
	call	rwfil		; read the header
	ret	nz		; abort on error (no need to close file)
	; check header and get image size
	call	chkhdr		; verifies marker, hl = image size
	ret	nz		; abort on error (no need to close file)
	ld	b,7		; right shift 7 bits to get 128 byte record count
rdos1:	srl	h		; shift right msb
	rr	l		; shift lsb w/ carry from msb
	djnz	rdos1		; loop till done
	ld	a,l		; record count to a
	ld	(reccnt),a	; set remaining records to read
	add	a,12		; add the header back
	ld	(imgsiz),a	; and save the total image size (in records)
	call	rwfil		; do it
	ret	nz		; abort on error
	; return via close file
	jp	closefile	; close file
;
;
;
rdbio:
	ld	de,msgrbio	; point to "Reading BIOS" message
	call	prtstr		; display it

	; open the file
	ld	c,$0F		; bdos open file
	ld	de,biofcb	; bios image fcb
	ld	(rwfcb),de	; save it
	call	bdos		; invoke bdos function
	cp	$FF		; $FF is error
	jp	z,errfil	; handle error condition
	; read 32K HBIOS image
	ld	a,$14		; setup for bdos read sequential
	ld	(rwfun),a	; save bdos function
	ld	a,0		; 0 means 256 records (32K)
	ld	(reccnt),a	; init record counter
	ld	hl,hbimg	; start of buffer
	ld	(bufptr),hl	; init buffer pointer
	call	rwfil		; read the header
	ret	nz		; abort on error (no need to close file)
	; return via close file
	jp	closefile	; close file
;
; Examine the BIOS image loaded.  Confirm existence of expected
; BIOS identification marker in first page (fail if not there).
; Display the BIOS identification information.  Confirm it is HBIOS
; and fail if not.  Save the HBIOS version number.
;
chkbios:
	; locate ROM signature in image
	ld	hl,sigptr	; point to ROM signature adr
	ld	a,(hl)		; dereference
	inc	hl		; ... to point
	ld	h,(hl)		; ... to location
	ld	l,a		; ... of signature block
	ld	de,hbimg	; offset by start
	add	hl,de		; ... of BIOS image

	; check signature
	ld	a,$76		; first byte value
	cp	(hl)		; compare
	jp	nz,errsig	; if not equal, signature error
	inc	hl		; bump to next byte
	ld	a,$B5		; second byte value
	cp	(hl)		; compare
	jp	nz,errsig	; if not equal, signature error
	inc	hl		; bump to next byte

	;; display short name
	;inc	hl		; bump past structure version number
	;inc	hl		; bump past rom size
	;ld	e,(hl)		; load rom name
	;inc	hl		; ... pointer
	;ld	d,(hl)		; ... into DE
	;ld	hl,hbimg	; offset by start
	;add	hl,de		; ... of BIOS image
	;ex	de,hl		; get pointer to DE
	;call	crlf		; formatting
	;call	prtstr		; and display it

	; check BIOS variant, only HBIOS supported
	ld	hl,hbmrk	; get the HBIOS marker
	ld	a,'W'		; first byte should be 'W'
	cp	(hl)		; compare
	jp	nz,errbio	; if not equal, fail
	inc	hl		; next byte
	ld	a,~'W'		; ... should be ~'W'
	cp	(hl)		; compare
	jp	nz,errbio	; if not equal, fail
	
	; if UNA is running, skip platform/ver stuff
	ld	a,(unamod)	; get UNA mode flag
	or	a		; set flags
	jr	nz,chkbios1	; skip if UNA

	; get and check platform (must match)
	ld	hl,hbplt	; point to BIOS platform id
	ld	a,(bioplt)	; get current running platform id
	cp	(hl)		; match?
	jp	nz,errplt	; if not, platform error

	; get HBIOS image version
	ld	hl,(hbver)	; get version byte from image
	ld	(biover),hl	; save it for later

chkbios1:
	xor	a
	ret
;
; Examine the OS image loaded.  Confirm existence of expected
; OS identification marker (fail if not there).  Check the version
; number in the OS image header.  Fail if OS image version does
; not match BIOS version.
;
chkos:
	; check for signature
	; Already verified in chkhdr

	;; compare platform id
	;ld	a,(bioplt)	; get current HBIOS platform ID
	;ld	hl,osplt	; point to OS image platform ID
	;cp	(hl)		; compare
	;jp	nz,errplt	; if not equal platform error
	
	; bypass version check if UNA running
	ld	a,(unamod)	; get UNA mode flag
	or	a		; set flags
	jr	nz,chkos1	; if UNA, bypass

	; compare version
	ld	a,(osver)	; get first OS version byte (major)
	rlca			; move low nibble
	rlca			; ...
	rlca			; ...
	rlca			; ... to high nibble
	ld	b,a		; save in b
	ld	a,(osver + 1)	; get second OS version byte (minor)
	or	b		; combine with major nibble
	ld	hl,biover	; point to HBIOS version
	cp	(hl)		; compare
	jp	nz,errver	; if not equal, fail

chkos1:
	xor	a		; signal success
	ret
;
; Load OS image into correct destination
;
ldos:
	; compute the image size (does not include size of header)
	ld	hl,(osend)	; get CPM_END
	ld	de,(osloc)	; get CPM_LOC
	or	a		; clear CF
	sbc	hl,de		; image size := CPM_END - CPM_LOC
	push	hl		; move image size
	pop	bc		; ... to BC
	ld	hl,osbin	; copy from buf, skip header
	ld	de,(osloc)	; OS location
	ldir			; do the copy
	xor	a
	ret
;
; Load BIOS into correct destination
;
ldbio:
;
	; copy the proxy to upper memory
	ld	hl,pxyimg	; location of proxy image
	ld	de,pxyloc	; target location of proxy
	ld	bc,pxysiz	; size of proxy
	ldir			; copy it
	ld	a,(tpabnk)	; get active tpa bank id
	ld	(curbnk),a	; fixup the proxy
;
	; copy image to bios bank
	ld	a,(curbnk)	; load from current bank
	ld	(srcbnk),a	; set source bank
	ld	a,(bidbios)	; copy to bios bank
	ld	(dstbnk),a	; set destination bank
	ld	hl,hbimg	; set source address
	ld	de,0		; set destination address
	ld	bc,$8000	; set length
	ld	a,(curbnk)	; return to current bank
	call	hbxcpy		; to the inter-bank copy
;
	xor	a		; signal success
	ret
;
;
;
initbio:
;
	; initialize HBIOS
	ld	a,(bidbios)	; get bios bank
	call	hbxbnk		; ... and activate it
	call	$0000		; call bios init entry point
	ld	a,(tpabnk)	; get active tpa bank id
	call	hbxbnk		; ... and activate it
;
	xor	a
	ret
;
; Common routine to handle read/write for file system
;
rwfil:
	ld	c,$1A		; BDOS set dma
	ld	de,(bufptr)	; current buffer pointer
	push	de		; save pointer
	call	bdos		; do it
	pop	de		; recover pointer
	ld	hl,128		; record length
	add	hl,de		; increment buffer pointer
	ld	(bufptr),hl	; save it
	ld	a,(rwfun)	; get the active function
	ld	c,a		; set it
	ld	de,(rwfcb)	; active fcb
	call	bdos		; do it
	or	a		; check return code
	jp	nz,errdos	; BDOS err
;	call	prtdot		; mark progress
	ld	hl,reccnt	; point to record count
	dec	(hl)		; decrement record count
	jr	nz,rwfil	; loop till done
	xor	a		; signal success
	ret			; done
;
; Close file
;
closefile:
	ld	c,$10		; BDOS close file
	ld	de,(rwfcb)	; active fcb
	call	bdos		; do it
	cp	$FF		; $FF is error
	jp	z,errclo	; if error, handle it
	xor	a		; signal success
	ret			; done
;
jphl:	jp	(hl)		; indirect jump
;
; Verify system image header in osimg by checking the expected signature.
; Compute and return image size (based on header values) in HL.  Size
; does not include header.  NZ set if signature error.
;
chkhdr:
	; check signature
	ld	hl,(ossig)	; get signature
	ld	de,$A55A	; signature value
	or	a		; clear CF
	sbc	hl,de		; compare
	jp	nz,errsig	; invalid signature
	; compute the image size (does not include size of header)
	ld	hl,(osend)	; get CPM_END
	ld	de,(osloc)	; get CPM_LOC
	or	a		; clear CF
	sbc	hl,de		; image size := CPM_END - CPM_LOC
	xor	a		; signal success
	ret			; done
;
; Convert a filename at (HL) into an FCB at (DE).
; Includes wildcard expansion.
; On return, A=0 if unambiguous name specified, and 
; (HL) points to character following filename spec
;
convert:
	push	de		; put fcb address on stack
	ex	de,hl
	ld	a,(de)		; get first character.
	or	a
	jp	z,convrt1
	sbc	a,'A'-1		; might be a drive name, convert to binary.
	ld	b,a		; and save.
	inc	de		; check next character for a ':'.
	ld	a,(de)
	cp	':'
	jp	z,convrt2
	dec	de		; nope, move pointer back to the start of the line.
convrt1:
	ld	a,(defdrv)
	ld	(hl),a
	jp	convrt3
convrt2:
	ld	a,b
	ld	(hl),b
	inc	de
	; Convert the base file name.
convrt3:ld	b,08h
convrt4:ld	a,(de)
	call	delim
	jp	z,convrt8
	inc	hl
	cp	'*'		; note that an '*' will fill the remaining
	jp	nz,convrt5	; field with '?'
	ld	(hl),'?'
	jp	convrt6
convrt5:ld	(hl),a
	inc	de
convrt6:dec	b
	jp	nz,convrt4
convrt7:ld	a,(de)
	call	delim		; get next delimiter
	jp	z,getext
	inc	de
	jp	convrt7
convrt8:inc	hl		; blank fill the file name
	ld	(hl),' '
	dec	b
	jp	nz,convrt8
getext:	ld	b,03h
	cp	'.'
	jp	nz,getext5
	inc	de
getext1:ld	a,(de)
	call	delim
	jp	z,getext5
	inc	hl
	cp	'*'
	jp	nz,getext2
	ld	(hl),'?'
	jp	getext3
getext2:ld	(hl),a
	inc	de
getext3:dec	b
	jp	nz,getext1
getext4:ld	a,(de)
	call	delim
	jp	z,getext6
	inc	de
	jp	getext4
getext5:inc	hl
	ld	(hl),' '
	dec	b
	jp	nz,getext5
getext6:ld	b,3
getext7:inc	hl
	ld	(hl),0
	dec	b
	jp	nz,getext7
	pop	hl		; HL := start of FCB
	push	de		; save input line pointer
	; Check to see if this is an ambiguous file name specification.
	; Set the A register to non-zero if it is.
	ld	bc,11		; set name length.
getext8:inc	hl
	ld	a,(hl)
	cp	'?'		; any question marks?
	jp	nz,getext9
	inc	b		; count them.
getext9:dec	c
	jp	nz,getext8
	ld	a,b
	or	a
	pop	hl		; return with updated input pointer
	ret
;
; Print formatted FCB at (HL)
;
prtfcb:
	push	hl		; save HL
	call	chkfcb		; set flags indicating nature of FCB
	pop	hl		; restore HL
	ret	z		; nothing to print
	push	af		; save FCB flags
	ld	a,(hl)		; get first byte of FCB (drive)
	inc	hl		; point to next char
	or	a		; is drive specified (non-zero)?
	jr	z,prtfcb1	; if zero, do not print drive letter
	add	a,'@'		; adjust drive number to alpha
	call	prtchr		; print it
	ld	a,':'
	call	prtchr		; print drive separator
prtfcb1:
	pop	af		; restore FCB flags
	bit	1,a		; bit 1 set if filename specified
	ret	z		; return if no filename
	ld	b,8		; base is 8 characters
	call	prtfcb2		; print them
	ld	a,'.'
	call	prtchr		; print file extension separator
	ld	b,3		; extension is 3 characters
prtfcb2:
	ld	a,(hl)		; load the next character
	inc	hl		; point to next character
	cp	' '		; check for blank
	call	nz,prtchr	; print char if it is not a blank
	djnz	prtfcb2		; loop till done
	ret			; return
;
; Check FCB to see if a drive and/or filename is specified.
; Set bit 0 for drive and bit 1 for filename in A
;
chkfcb:
	ld	c,0		; use C for flags, start with none
	ld	a,(hl)		; get drive
	or	a		; anything there?
	jr	z,chkfcb1	; skip if nothing there
	set	0,c		; set bit zero to indicate a drive spec
chkfcb1:
	ld	b,11		; set up to check 11 bytes (base & ext)
chkfcb2:
	inc	hl		; bump to next byte
	ld	a,(hl)		; get next
	cp	'A'		; blank means empty byte
	jr	nc,chkfcb3	; if not blank, we have a filename
	djnz	chkfcb2		; loop
	jr	chkfcb4		; nothing there
chkfcb3:
	set	1,c		; set bit 1 to indicate a file spec
chkfcb4:
	ld	a,c		; put result in a
	or	a		; set flags
	ret
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
	push	af
	ld	a,'.'
	call	prtchr
	pop	af
	ret
;
; Print a zero terminated string at (DE) without destroying any registers
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
; Start a new line (or 2)
;
crlf2:
	call	crlf		; double new line entry
crlf:
	ld	a,13		; <CR>
	call	prtchr		; print it
	ld	a,10		; <LF>
	jr	prtchr		; print it
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
	cp	$3b		; semicolon
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
	ld	hl,(cbftbl)	; address of CBIOS function table to HL
	call	addhl		; determine specific function address
	jp	(hl)		; invoke CBIOS
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
; Errors
;
erruse:	; command usage error (syntax)
	ld	de,msguse
	jr	err
erramb:	; ambiguous file spec (wild cards) is not allowed
	ld	de,msgamb
	jr	err
errdlm:	; invalid delimiter in command tail
	ld	de,msgdlm
	jr	err
errfil:	; source file not found
	ld	de,msgfil
	jr	err
errclo:	; file close error
	ld	de,msgclo
	jr	err
errsig:	; invalid system image signature error
	ld	de,msgsig
	jr	err
errbio:	; invalid BIOS image, not HBIOS
	ld	de,msgbio
	jr	err
errplt:	; platform mismatch
	ld	de,msgplt
	jr	err
errver:	; version mismatch
	ld	de,msgver
	jr	err
err:	; print error string and return error signal
	call	crlf2		; print newline
	call	prtstr		; print error string
	or	$FF		; signal error
	ret			; done
errdos:	; handle BDOS errors
	push	af		; save return code
	call	crlf2		; newline
	ld	de,msgdos	; load
	call	prtstr		; and print error string
	pop	af		; recover return code
	call	prthex		; print error code
	or	$FF		; signal error
	ret			; done
;
;===============================================================================
; Storage Section
;===============================================================================
;
defdrv	.db	0		; default drive for FCB
cbftbl	.dw	0		; address of CBIOS function table
imgsiz	.db	0		; image size (count of 128 byte records)
;
osfcb	.fill	36,0		; os image FCB
biofcb	.fill	36,0		; bios image FCB
;
unamod	.db	0		; UNA move flag (non-zero if UNA running)
newbio	.db	0		; BIOS load flag (non-zero if new BIOS load)
force	.db	0		; force operation (bypass compatibility checks)
tpabnk	.db	0		; bank id of TPA when app starts
bioplt	.db	0		; Platform ID of running HBIOS
biover	.dw	0		; version of BIOS being loaded
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
rwfun	.db	0		; active read/write function
rwfcb	.dw	0		; active read/write FCB
reccnt	.db	0		; active remaining records to read/write
bufptr	.dw	0		; active pointer into buffer
;
; Messages
;
msgban	.db	"OSLDR v1.2 for RomWBW, 20-Feb-2020",0
msghb	.db	" (HBIOS Mode)",0
msgub	.db	" (UBIOS Mode)",0
msguse	.db	"Usage: OSLDR [/F] <osimg> [<hbiosimg>]\r\n"
	.db	"  /F (force) overrides all compatibility checking",0
msgamb	.db	"Ambiguous file specification not allowed",0
msgdlm	.db	"Invalid delimiter",0
msgfil	.db	"File not found",0
msgclo	.db	"File close error",0
msgsig	.db	"Obsolete or invalid BIOS image (BIOS signature)",0
msgbio	.db	"Obsolete or invalid HBIOS image (HBIOS signature)",0
msgplt	.db	"Platform (hardware) mismatch",0
msgver	.db	"Version mismatch",0
msgdos	.db	"DOS error, return code=0x",0

msgros	.db	"Reading OS... ",0
msgrbio	.db	"Reading BIOS... ",0
msglos	.db	"Loading OS... ",0
msglbio	.db	"Loading BIOS... ",0
;
	.end
