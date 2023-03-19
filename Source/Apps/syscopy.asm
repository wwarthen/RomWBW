;===============================================================================
; SysCopy - Copy System Image to/from reserved tracks of disk for RomWBW
;           adaptation of CP/M 2.2 & CP/M 3
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   SYSCOPY <dest>[=<src>]
;
;   <dest> and <src> may be a drive or a file reference
;   If <src> is not specified, the system image will 
;   be read from the current drive
;_______________________________________________________________________________
;
; Change Log:
;   2016-04-24 [WBW] Updated to preserve MBR partition table
;   2020-02-17 [WBW] Updated for CP/M 3
;   2020-05-16 [WBW] Fixed SPT for CP/M 3
;_______________________________________________________________________________
;
; ToDo:
;   1) Add option to wait/prompt for disk change
;   2) Allow <src> and <dest> to be memory
;_______________________________________________________________________________
;
;===============================================================================
; Definitions
;===============================================================================
;
false	.equ	0		; define true
true	.equ	~false		; define false
;
stksiz	.equ	$40		; we are a stack pig
;
restart	.equ	$0000		; CP/M restart vector
bdos	.equ	$0005		; BDOS invocation vector
;
imgbuf	.equ	$900		; load point for system image (from original SYSGEN)
mbrbuf	.equ	imgbuf+$4000	; load point for MBR storage
;
;===============================================================================
; Code Section
;===============================================================================
;
	.org	$100
	; setup stack (save old value)
	ld	(stksav),sp	; save stack
	ld	sp,stack	; set new stack
	; processing...
	call	main		; do the real work
	call	crlf		; formatting
	; return
	jp	0		; return to CP/M via reset
	;
	;ld	sp,(stksav)	; restore stack
	;ret			; return to CP/M w/o reset
;
; Main routine
;
main:
	call	init		; initialize
	ret	nz		; abort on failure

	call	parse		; parse command tail
	ret	nz		; abort on failure

	call	confirm		; confirm pending action
	ret	nz		; abort on failure

	call	crlf		; formatting

	ld	de,msgrd
	call	prtstr		; display "reading" message
	call	rdimg		; do the image read
	ret	nz		; abort on failure

	ld	de,msgwrt
	call	prtstr		; display "writing" message
	call	wrtimg		; do the image write
	ret	nz		; abort on failure

	ld	de,msgdon	; completion message
	call	prtstr		; display it
	
	ret
;
; Initialization
;
init:
	; add check for RomWBW?
	;
	; get OS version
	ld	c,12		; BDOS get os version
	call	bdos		; do it, L=version
	cp	$30		; Test for v3.0
	jr	c,init1		; if <, pre v3.0
	ld	a,true		; OS v3.0 or above
	ld	(v3os),a	; save it
	jr	init2
init1:
	ld	a,false		; OS < v3.0
	ld	(v3os),a	; save it
init2:
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
	; print version banner
	call	crlf		; formatting
	ld	de,msgban1	; point to version message part 1
	call	prtstr		; print it
	ld	a,(v3os)	; get OS version flag
	or	a		; set flags
	ld	de,msgv2	; point to V2 mode message
	call	z,prtstr	; if V2, say so
	ld	de,msgv3	; point to V3 mode message
	call	nz,prtstr	; if V3, say so
	call	crlf		; formatting
	ld	de,msgban2	; point to version message part 2
	call	prtstr		; print it
	call	crlf		; formatting
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
	ld	de,destfcb	; point to destination fcb
	call	convert		; convert destination spec
	jp	nz,erramb	; Error, ambiguous file specification
	call	nonblank	; skip blanks
	or	a		; end of command tail (null)?
	jr	z,parse2	; setup default source fcb
	cp	'='		; std delimiter
	jr	z,parse1	; valid delimiter, continue
	cp	'_'		; alt delimiter
	jr	z,parse1	; valid delimiter, continue
	jp	errdlm		; invalid delimiter
parse1:
	inc	hl		; skip delimiter
	call	nonblank	; skip blanks
parse2:
	ld	de,srcfcb	; point to source fcb
	call	convert		; convert spec to fcb
	jp	nz,erramb	; Error, ambiguous file specification
	; return success
	xor	a		; signal success
	ret			; done parsing
;
; Confirm pending action with user
;
confirm:
	; prompt
	call	crlf
	ld	de,sconf1
	call	prtstr
	ld	hl,srcfcb
	call	prtfcb
	ld	de,sconf2
	call	prtstr
	ld	hl,destfcb
	call	prtfcb
	ld	de,sconf3
	call	prtstr
;
	; get input (imgbuf is used for temp storage)
	ld	c,$0A		; get console buffer
	ld	de,imgbuf		; into buf
	ld	a,1		; max of 1 character
	ld	(de),a		; set up buffer
	call	bdos		; invoke BDOS
	ld	a,(imgbuf+1)	; get num chars entered
	dec	a		; check that we got exactly one char
	jr	nz,confirm	; bad input, re-prompt
	ld	a,(imgbuf+2)	; get the character
	and	$DF		; force upper case
	cp	'Y'		; compare to Y
	ret			; return with Z set appropriately
;
; Read system image
;
rdimg:
	ld	hl,srcfcb	; point to source fcb
	call	chkfcb		; check if for drive/file spec
	bit	1,a		; is there a file spec?
	jp	nz,rdfil	; yes, read using file i/o
	jp	rddsk		; no, read using raw disk i/o
;
; Write system image
;
wrtimg:
	ld	hl,destfcb	; point to destination fcb
	call	chkfcb		; check it for drive/file spec
	bit	1,a		; is there a file spec?
	jp	nz,wrfil	; yes, write using file i/o
	jp	wrdsk		; no, write using raw disk i/o

;
; Read system image from file system
;
rdfil:
	; open the file
	ld	c,$0F		; bdos open file
	ld	de,srcfcb	; source fcb
	ld	(rwfcb),de	; save it
	call	bdos		; invoke bdos function
	cp	$FF		; $FF is error
	jp	z,errfil	; handle error condition
	; read the header
	ld	a,$14		; setup for bdos read sequential
	ld	(rwfun),a	; save bdos function
	ld	a,12		; start with 1536 byte header (12 records)
	ld	(reccnt),a	; init record counter
	ld	hl,imgbuf	; start of buffer
	ld	(bufptr),hl	; init buffer pointer
	call	rwfil		; read the header
	ret	nz		; abort on error (no need to close file)
	; check header and get image size
	call	chkhdr		; verifies marker & ver, hl = image size
	ret	nz		; abort on error (no need to close file)
	ld	b,7		; right shift 7 bits to get 128 byte record count
rdfil1:	srl	h		; shift right msb
	rr	l		; shift lsb w/ carry from msb
	djnz	rdfil1		; loop till done
	ld	a,l		; record count to a
	ld	(reccnt),a	; set remaining records to read
	add	a,12		; add the header back
	ld	(imgsiz),a	; and save the total image size (in records)
	call	rwfil		; do it
	ret	nz		; abort on error
	; return via close file
	jp	closefile	; close file
;
; Write system image to file system
;
wrfil:
	; check for pre-existing target file
	ld	c,$11		; bdos find first
	ld	de,destfcb	; destination fcb
	call	bdos
	cp	$FF		; check for error
	jr	z,wrfil1	; not there, skip delete
	; delete target file if it exists
	ld	c,$13		; bdos delete
	ld	de,destfcb	; destination fcb
	call	bdos
	cp	$FF		; check return code
	jp	z,errdel	; handle error
wrfil1:	; create target file
	ld	c,$16		; bdos create file
	ld	de,destfcb	; destination fcb
	ld	(rwfcb),de	; save it
	call	bdos
	cp	$FF		; check return code
	jp	z,errfil	; handle error
	; write the image
	ld	a,$15		; setup for bdos write sequential
	ld	(rwfun),a	; save bdos function
	ld	a,(imgsiz)	; number of records to write
	ld	(reccnt),a	; init record counter
	ld	hl,imgbuf	; start of buffer
	ld	(bufptr),hl	; init buffer pointer
	call	rwfil		; do it
	ret	nz		; abort on error
	; return via close file
	jp	closefile	; close file
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
; Read image directly from disk system tracks using CBIOS
;
rddsk:
	; force return to go through disk reset
	ld	hl,resdsk	; load address of reset disk routine
	push	hl		; and put it on the stack
	; set drive for subsequent reads
	ld	a,(srcfcb)	; get the drive
	dec	a		; adjust for zero indexing
	call	setdsk		; setup disk
	ret	nz		; abort on error
	; set function to read
	ld	a,13		; CBIOS func 13: Read
	ld	(actfnc),a	; save it
	; read the header
	ld	a,12		; start with 1536 byte header (12 records)
	ld	(reccnt),a	; initialize record counter
	call	rwdsk		; read the header
	ret	nz		; abort on error
	; check header and get image size
	call	chkhdr		; check integrity, HL = image size on return
	ret	nz		; abort on error
	; convert image size to count of 128-byte records
	ld	b,7		; right shift 7 bits to get 128 byte record count
rddsk1:	srl	h		; shift right msb
	rr	l		; shift lsb w/ carry from msb
	djnz	rddsk1		; loop till done
	; set the number of records pending to read
	ld	a,l		; record count to a
	ld	(reccnt),a	; set remaining records to read
	; save the total image size (including header) for later
	add	a,12		; add the header records back
	ld	(imgsiz),a	; and save the total image size (in records)
	; read the remaining system image records
	call	rwdsk		; finish up
	ret	nz		; abort on error
	; perform BDOS disk reset (critical since we mucked with CBIOS)
	ld	c,$0D		; BDOS reset disk
	call	bdos		; do it
	; return
	xor	a		; signal success
	ret			; done
;
; Write image directly to disk system tracks using CBIOS
;
wrdsk:
	; force return to go through disk reset
	ld	hl,resdsk	; load address of reset disk routine
	push	hl		; and put it on the stack
	; setup to read existing MBR
	ld	a,(destfcb)	; get the drive
	dec	a		; adjust for zero indexing
	call	setdsk		; setup disk
	ret	nz		; abort on error
	ld	hl,mbrbuf	; override to read
	ld	(bufptr),hl	; ... into MBR buffer
	ld	a,4		; 4 records = 1 512 byte sector
	ld	(reccnt),a	; initialize record counter
	; set function to read
	ld	a,13		; CBIOS func 13: Read
	ld	(actfnc),a	; save it
	; read the existing MBR into memory
	call	rwdsk		; read the sector
	ret	nz		; abort on error
	; test for valid partition table ($55, $AA at offset $1FE)
	ld	hl,(mbrbuf+$1FE); HL := signature
	ld	a,$55		; load expected value of first byte
	cp	l		; check for proper value
	jr	nz,wrdsk1	; mismatch, ignore old partition table
	ld	a,$AA		; load expected value of second byte
	cp	h		; check for proper value
	jr	nz,wrdsk1	; mismatch, ignore old partition table
	; valid MBR, copy existing partition table over to new image
	ld	hl,mbrbuf+$1BE	; copy from MBR offset of existing MBR
	ld	de,imgbuf+$1BE	; copy to MBR offset of new image
	ld	bc,$40		; size of MBR
	ldir			; do it
wrdsk1:	; setup to write the image from memory to disk
	ld	a,(destfcb)	; get the drive
	dec	a		; adjust for zero indexing
	call	setdsk		; setup disk
	ret	nz		; abort on error
	; set function to write
	ld	a,14		; CBIOS func 14: Write
	ld	(actfnc),a	; save it
	; setup the record count to write
	ld	a,(imgsiz)	; get previously recorded image size
	ld	(reccnt),a	; save it as pending record count
	; write the image
	call	rwdsk		; write the image
	ret	nz		; abort on error
	; return
	xor	a		; signal success
	ret			; done
;
; Perform BDOS disk reset
; Required after making direct CBIOS disk calls
;
resdsk:
	; perform BDOS disk reset 
	push	af		; preserve status
	ld	c,$0D		; BDOS reset disk
	call	bdos		; do it
	pop	af		; restore status
	ret
;
; Setup for CBIOS disk access
;
setdsk:
	; select disk
	ld	(actdsk),a	; save active disk no
	ld	c,a		; move to c
	ld	e,0		; treat as first select
	call	cbios		; invoke cbios with...
	;.db	$1B		; SELDSK entry offset
	.db	9		; SELDSK entry offset
	; check return (sets HL to DPH address)
	ld	a,h
	or	l
	jp	z,errsel	; HL == 0 is select error
	; set HL to DPB address
	ld	de,10		; DPB address is 10 bytes into DPH
	add	hl,de		; HL := address of DPB pointer
	ld	a,(hl)		; dereference...
	inc	hl
	ld	h,(hl)
	ld	l,a		; HL := address of DPB
	; extract sectors per track from first word of DPB
	ld	c,(hl)
	inc	hl
	ld	b,(hl)		; BC := sectors per track
	; handle CP/M 3 physical sector size
	ld	a,(v3os)	; CP/M 3 or greater?
	or	a		; set flags
	jr	z,setdsk1	; if not, continue
	; adjust SPT for CP/M 3 physical sector size
	srl	b		; divide SPT by 4
	rr	c
	srl	b
	rr	c
setdsk1:
	ld	(actspt),bc	; save it
	; ensure there are system tracks (verify that offset field in DPB is not zero)
	ld	de,12		; offset field is 12 bytes into DPB
	add	hl,de		; point to offset field in DPB
	ld	a,(hl)		; load first byte in A
	inc	hl		; point to second byte
	or	(hl)		; or with first byte
	jp	z,errsys	; if zero, abort (no system tracks)
	; initialize for I/O
	ld	hl,0
	ld	(acttrk),hl	; active track := 0
	ld	(actsec),hl	; active sector := 0
	ld	hl,imgbuf	; assume r/w to image buffer
	ld	(bufptr),hl	; reset buffer pointer
;
	xor	a		; signal success
	ret			; done
;
; Read or write (reccnt) sectors to/from disk via CBIOS
;
rwdsk:
	ld	hl,128		; assume rec len for < CP/M 3
	ld	(reclen),hl	; and save it
	ld	a,(v3os)	; CP/M 3 or greater?
	or	a		; set flags
	jr	z,rwdsk0	; if not, continue
	; adjust reccnt, logical (128) to physical (512)
	ld	a,(reccnt)	; get pending rec cnt
	add	a,3		; round up
	srl	a		; shift to
	srl	a		; ... divide by 4
	ld	(reccnt),a	; and resave it
	ld	hl,512		; use physical rec len
	ld	(reclen),hl	; and save it
rwdsk0:
	; setup to read/write a sector
	ld	bc,(acttrk)	; get active track
	call	cbios		; invoke cbios with...
	;.db	$1E		; SETTRK entry offset
	.db	10		; SETTRK entry offset
	ld	bc,(actsec)	; get active sector
	call	cbios		; invoke cbios with...
	;.db	$21		; SETSEC entry offset
	.db	11		; SETSEC entry offset
	ld	bc,(bufptr)	; get active buffer pointer
	call	cbios		; invoke cbios with...
	;.db	$24		; SETDMA entry offset
	.db	12		; SETDMA entry offset
	; read/write sector
	ld	a,(reccnt)	; get the pending record count
	dec	a		; last record?
	ld	c,2		; allow cached writes by default
	jr	nz,rwdsk1	; not last record, continue
	ld	c,1		; last record, no caching please
rwdsk1:	
	ld	a,(actfnc)
	call	cbiosfn
	or	a		; set flags on return code
	jp	nz,errio	; if not zero, error abort
	; adjust buffer pointer
	ld	hl,(bufptr)	; get buffer pointer
	ld	de,(reclen)	; get rec len
	add	hl,de		; adjust buffer ptr for next record
	ld	(bufptr),hl	; save it
	; next sector
	ld	hl,(actsec)	; current sector
	inc	hl		; increment sector
	ld	(actsec),hl	; save it
	; check for end of track
	ld	de,(actspt)	; get current sectors per track
	or	a		; clear CF
	sbc	hl,de		; current track == sectors per track?
	jr	nz,rwdsk2	; no, skip track change
	; next track
	ld	hl,0
	ld	(actsec),hl	; current sector := 0
	ld	hl,acttrk	; point to track variable
	inc	(hl)		; increment track
	; check pending record count and loop or return
rwdsk2:	ld	hl,reccnt
	dec	(hl)		; decrement pending record count
	ret	z		; if zero, done, return with Z set
	jr	rwdsk0		; otherwise, loop
;
jphl:	jp	(hl)		; indirect jump
;
; Verify system image header in buf by checking the expected signature.
; Compute and return image size (based on header values) in HL.
; NZ set if signature error.
;
chkhdr:
	; check signature
	ld	hl,(imgbuf+$580)	; get signature
	ld	de,$A55A	; signature value
	or	a		; clear CF
	sbc	hl,de		; compare
	jp	nz,errsig	; invalid signature
	; compute the image size (does not include size of header)
	ld	hl,(imgbuf+$5FC)	; get CPM_END
	ld	de,(imgbuf+$5FA)	; get CPM_LOC
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
; Print dot
;
prtdot:
	push	af
	ld	a,'.'
	call	prtchr
	pop	af
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
; Print $ terminated string at (DE) without destroying any registers
;
prtstr:
	push	bc		; save registers
	push	de
	push	hl
	ld	c,$09		; BDOS function to output a '$' terminated string
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
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
; Start a new line
;
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
	ld	a,(hl)		; get the function number
	inc	hl		; point past value following call instruction
	ex	(sp),hl		; put address back at top of stack and recover HL
	
cbiosfn:
	; enter here if function already in reg A
	ld	(bpb_fn),a	; save function
;	
	ld	a,(v3os)	; CP/M 3 or greater?
	or	a		; set flags
	jr	nz,cbios2	; if >= V3, handle it
;
	; CBIOS call for CP/M < v3
	ld	a,(bpb_fn)	; get pending function number
	ld	l,a		; function number to L
	add	a,l		; ... and multiply by 3 for
	add	a,l		; ... jump table offset
	ld	hl,(cbftbl)	; address of CBIOS function table to HL
	call	addhl		; determine specific function address
	jp	(hl)		; invoke CBIOS
;
cbios2:
	; CBIOS call for CP/M v3 or greater
	ld	(bpb_bc),bc
	ld	(bpb_de),de
	ld	(bpb_hl),hl
	
	ld	c,50		; direct bios call function number
	ld	de,bpb		; BIOS parameter block
	jp	bdos		; return via BDOS call
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
errdel:	; file delete error
	ld	de,msgdel
	jr	err
errsig:	; invalid system image signature error
	ld	de,msgsig
	jr	err
errsel:	; CBIOS drive select error
	ld	de,msgsel
	jr	err
errsys:	; no system tracks on drive error
	ld	de,msgsys
	jr	err
errio:	; I/O error
	ld	de,msgio
	jr	err
err:	; print error string and return error signal
	call	crlf		; print newline
	call	prtstr		; print error string
	or	$FF		; signal error
	ret			; done
errdos:	; handle BDOS errors
	push	af		; save return code
	call	crlf		; newline
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
destfcb	.fill	36,0		; destination FCB
srcfcb	.fill	36,0		; source FCB
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
actdsk	.db	0		; active disk no
acttrk	.dw	0		; active track
actsec	.dw	0		; active sector
actspt	.dw	0		; active sectors per track
actfnc	.db	0		; active cbios i/o function (read or write)
v3os	.db	0		; true ($FF) if OS v3.0 or greater
reclen	.dw	0		; active record length
;
bpb:				; BIOS parameter block for CP/M 3 BIOS calls
bpb_fn	.db	0		; function
bpb_a	.db	0		; reg A
bpb_bc	.dw	0		; reg BC
bpb_de	.dw	0		; reg DE
bpb_hl	.dw	0		; reg HL
;
; Messages
;
msgban1	.db	"SYSCOPY v2.1 for RomWBW CP/M, 15-May-2020$"
msgv2	.db	" (CP/M 2 Mode)$"
msgv3	.db	" (CP/M 3 Mode)$"
msgban2	.db	"Copyright 2020, Wayne Warthen, GNU GPL v3$"

msguse	.db	"Usage: SYSCOPY <dest>[=<source>]$"
msgamb	.db	"Ambiguous file specification not allowed$"
msgdlm	.db	"Invalid delimiter$"
msgfil	.db	"File not found$"
msgclo	.db	"File close error$"
msgdel	.db	"Error deleting target file$"
msgsig	.db	"Invalid system image (bad signature)$"
msgdos	.db	"DOS error, return code=0x$"
msgsel	.db	"Disk select error$"
msgsys	.db	"Non-system disk error$"
msgio	.db	"Disk I/O error$"
msgrd	.db	"Reading image... $"
msgwrt	.db	"Writing image... $"
msgdon	.db	"Done$"
sconf1	.db	"Transfer system image from $"
sconf2	.db	" to $"
sconf3	.db	" (Y/N)? $"
;
	.end
