;===============================================================================
; ASSIGN - Display and/or modify drive letter assignments
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   ASSIGN [D:={D:|<device><unit>[:<slice>]}]
;     ex: ASSIGN		(display all active drive assignments)
;         ASSIGN /?		(display version and usage)
;         ASSIGN /L		(display all possible devices)
;         ASSIGN C:=D:		(swaps C: and D:)
;         ASSIGN C:=FD0:	(assign C: to floppy unit 0)
;         ASSIGN C:=IDE0:1	(assign C: to IDE unit0, slice 1)
;_______________________________________________________________________________
;
; Change Log:
;_______________________________________________________________________________
;
; ToDo:
;  1) Do something to prevent assigning to non-existent devices
;  2) Do something to prevent assigning slices when device does not support them
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
;
stamp	.equ	$40		; loc of RomWBW CBIOS zero page stamp
;
rmj	.equ	2		; CBIOS version - major
rmn	.equ	6		; CBIOS version - minor
;
;===============================================================================
; Code Section
;===============================================================================
;
	.org	$100
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
;
	; perform table integrity check
	call	valid
;
exit:	; clean up and return to command processor
;
	ld	sp,(stksav)	; restore stack
	jp	restart		; return to CP/M via restart
	ret			; return to CP/M w/o restart
;
; Initialization
;
init:
;
	; locate cbios function table address
	ld	hl,(restart+1)	; load address of CP/M restart vector
	ld	de,-3		; adjustment for start of table
	add	hl,de		; HL now has start of table
	ld	(cbftbl),hl	; save it
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
	cp	rmj << 4 | rmn	; match?
	jp	nz,errver	; abort with invalid os version
	inc	hl		; bump past
	inc	hl		; ... version info
;
	; dereference HL to point to CBIOS extension data
	ld	a,(hl)		; dereference HL
	inc	hl		;   ... to point to
	ld	h,(hl)		;   ... ROMWBW config data block
	ld	l,a		;   ... in CBIOS
;
	; get location of drive map
	inc	hl		; bump two bytes
	inc	hl		; ... to drive map address
	ld	a,(hl)		; dereference HL
	inc	hl		;   ... to point to
	ld	h,(hl)		;   ... drivemap data
	ld	l,a		;   ... in CBIOS
	ld	(maploc),hl	; and save it
;
	; check for UNA (UBIOS)
	ld	a,($fffd)	; fixed location of UNA API vector
	cp	$c3		; jp instruction?
	jr	nz,initx	; if not, not UNA
	ld	hl,($fffe)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$fd		; first byte of UNA push ix instruction
	jr	nz,initx	; if not, not UNA
	inc	hl		; next byte
	ld	a,(hl)		; get next byte
	cp	$e5		; second byte of UNA push ix instruction
	jr	nz,initx	; if not, not UNA
	ld	hl,unamod	; point to UNA mode flag
	ld	(hl),$ff	; set UNA mode
;
initx:
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
	jr	z,option	; yes, handle option
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
	or	a		; set flags
	jp	nz,errprm	; handle unexpected delimiter
	ld	a,(dstdrv)	; dest drive back to A
	jp	showone		; no more parms, dump specific drive assignment
;
process1:	; handle other side of '='
;
	inc	hl		; skip '='
	call	nonblank	; skip blanks as needed
	jp	z,errprm	; nothing after '=', parm error
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
	ld	a,(hl)		; get the current cmd string char
	or	a		; set flags
	ret	z		; if null, we are done
	inc	hl		; otherwise, skip comma
	call	nonblank	; and possible blanks after comma
	ret	z		; get out if nothing more
	jr	process0	; we have more work, loop
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
	ld	de,msgban1	; point to version message part 1
	call	prtstr		; print it
	ld	a,(unamod)	; get UNA flag
	or	a		; set flags
	ld	de,msghb	; point to HBIOS mode message
	call	z,prtstr	; if not UNA, say so
	ld	de,msgub	; point to UBIOS mode message
	call	nz,prtstr	; if UNA, say so
	ld	de,msgban2	; point to version message part 2
	call	prtstr		; print it
	call	crlf		; blank line
	ld	de,msguse	; point to usage message
	call	prtstr		; print it
	ret			; and return
;
devlist:
;
	ld	a,(unamod)	; get UNA mode flag
	or	a		; set flags
	jr	nz,devlstu	; do UNA mode dev list
;
	call	crlf
	ld	c,0
devlist1:
	ld	de,indent	; indent
	call	prtstr		; ... to look nice
	ld	a,c
	call	prtdev
	ld	a,':'
	call	prtchr
	call	crlf
	inc	c
	ld	a,c
	cp	devcnt
	jr	nz,devlist1
	ret
;
devlstu:
	; UNA mode device list
	ld	b,0		; use unit 0 to get count
	ld	c,$48		; una func: get disk type
	ld	l,0		; preset unit count to zero
	call	$fffd		; call una, b is assumed to be untouched!!!
	ld	a,l		; unit count to a
	or	a		; set flags
	ret	z		; no units, return
	ld	b,l		; unit count to b
	ld	c,0		; init unit index
devlstu1:
	push	bc		; save loop control vars
	ld	de,indent	; indent
	call	prtstr		; ... to look nice
	ld	a,c		; put unit num in A
	push	af		; save it
	call	prtdevu		; print the device name
	pop	af		; restore unit num
	call	prtdecb		; print unit num
	ld	a,':'		; colon delimiter
	call	prtchr		; print it
	call	crlf		; formatting
	pop	bc		; restore loop control
	inc	c		; next drive
	djnz	devlstu1	; loop as needed
	ret			; return
;
; Scan drive map table for integrity
; Currently just checks for multiple drive 
;   letters referencing a single file system
;
valid:
	ld	hl,(maploc)	; get the map table location
	dec	hl		; point to table entry count
	ld	b,(hl)		; B := table entries
	dec	b		; loop one less times than num entries
	inc	hl		; point back to table start
;
valid1:		; outer loop
	push	hl		; save pointer
	push	bc		; save loop control
	call	valid2		; do the inner loop
	pop	bc		; restore loop control
	pop	hl		; restore pointer
	jp	z,errint	; validation error
	ld	a,4		; 4 bytes per entry
	call	addhl		; bump to next entry
	djnz	valid1		; loop until done
	ret			; done
;
valid2:		; setup for inner loop
	push	hl		; save HL
	ld	a,4		; 4 bytes per entry
	call	addhl		; point to entry following
	pop	de		; de points to comparison entry
;
valid3:		; inner loop
	ld	c,(hl)		; first byte to C
	ld	a,(de)		; second byte to A
	cp	c		; compare
	inc	hl		; bump HL to next byte
	jr	nz,valid4	; if not equal, continue loop
	inc	de		; bump DE to next byte
	ld	c,(hl)		; first byte to C
	ld	a,(de)		; second byte to A
	cp	c		; compare
	ret	z		; both bytes equal, return signaling problem
	dec	de		; point DE back to first byte of comparison entry
;
valid4:		; no match, loop
	inc	hl		; bump HL
	inc	hl		; ... to
	inc	hl		; ... next entry
	djnz	valid3		; loop as appropriate
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
	ld	hl,(maploc)
	ld	a,(srcdrv)
	rlca
	rlca
	call	addhl
	ld	(srcptr),hl
;
	; Get pointer to destination drive table entry
	ld	hl,(maploc)
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
	jp	drvrst		; exit via a full drive reset
;
; Assign drive to specified device/unit/slice
;
drvmap:		; determine device code by scanning for string
	ld	b,16		; device table always has 16 entries
	ld	c,0		; c is used to track table entry num
	ld	de,tmpstr	; de points to specified device name
	ld	hl,devtbl	; hl points to first entry of dvtbl
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
drvmap2:	; verify the unit is eligible for assignment (hard disk unit only!)
	ld	a,c		; get the specified device number
	call	chktyp		; check it
	jp	nz,errtyp	; abort with bad unit error
;
	; construct the requested dph table entry	
	ld	a,c		; C has device num
	rlca			; move it to upper nibble
	rlca			; ...
	rlca			; ...
	rlca			; ...
	ld	c,a		; stash it back in C
	ld	a,(unit)	; get the unit number
	or	c		; combine device and unit
	ld	c,a		; and save in C
	ld	a,(slice)	; get the slice
	ld	b,a		; and save in B
;
	; resolve the CBIOS DPH table entry
	ld	a,(dstdrv)	; dest drv num to A
	call	chkdrv		; valid drive?
	ret	nz		; abort if invalid
	ld	hl,(maploc)	; start of DPH table to HL
	rlca			; multiply by
	rlca			; ... entry size of 4
	call	addhl		; adjust HL to point to entry
	ld	(dstptr),hl	; save it
;
	; verify the drive letter being assigned is a hard disk
	ld	a,(hl)		; get the device/unit byte
	rrca			; move device nibble to low nibble
	rrca			; ...
	rrca			; ...
	rrca			; ...
	and	$0F		; and isolate device bits
	call	chktyp		; check it
	jp	nz,errtyp	; abort with bad device type error
;
	; shove updated device/unit/slice into the entry
	ld	(hl),c		; save device/unit byte
	inc	hl		; bump to next byte
	ld	(hl),b		; save slice
;
	; finish up
	ld	a,(dstdrv)	; get the destination drive
	call	showone		; show it's new value
	jp	drvrst		; exit via drive reset
;
; Display all active drive letter assignments
;
showall:
	ld	hl,(maploc)	; HL = address of drive map
	dec	hl		; point to prior byte with map entry count
	ld	b,(hl)		; put it in b for loop counter
	ld	c,0		; map index (drive letter)
;
	ld	a,b		; load count
	or	a		; set flags
	ret	z		; bail out if zero
;
showall1:	; loop
	ld	a,c		;
	call	showone
	inc	c
	djnz	showall1
	ret
;
; Display drive letter assignment for the drive num in A
;
showone:
;
	push	af		; save the incoming drive num
;
	ld	de,indent	; indent
	call	prtstr		; ... to look nice
;
	; setup HL to point to desired entry in table
	pop	af
	push	af
	ld	hl,(maploc)	; HL = address of drive map
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
	ld	a,(hl)		; load device/unit
	call	prtdev		; print device mnemonic
	ld	a,(hl)		; load device/unit again
	and	$0F		; isolate unit num
	call	prtdecb		; print it
	inc	hl		; point to slice num
	ld	a,':'		; colon to separate slice
	call	prtchr		; print it
	ld	a,(hl)		; load slice num
	call	prtdecb		; print it
;
	call	crlf
;
	ret
;
; Force BDOS to reset (logout) all drives
;
drvrst:
	ld	c,$0D		; BDOS Reset Disk function
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
	ret			; done
;
prtdevu:
	ld	e,a		; save unit num in E
	push	bc
	push	de
	push	hl
	; UNA mode version of print device
	ld	b,a		; B := unit num
	ld	c,$48		; UNA func: get disk type
	call	$FFFD		; call UNA
	ld	a,d		; disk type to A
	pop	hl
	pop	de
	pop	bc
;
	cp	$40		; RAM/ROM?
	jr	z,prtdevu1	; if so, handle it
	cp	$41		; IDE?
	ld	de,udevide	; load string
	jp	z,prtstr	; if IDE, print and return
	cp	$43		; SD?
	ld	de,udevsd	; load string
	jp	z,prtstr	; if SD, print and return
	ld	de,udevunk	; load string for unknown
	jr	prtstr		; and print it
;
prtdevu1:
	; handle RAM/ROM
	push	bc
	push	hl
	ld	b,e		; unit num to B
	ld	c,$45		; UNA func: get disk info
	ld	de,$9000	; 512 byte buffer *** FIX!!! ***
	call	$FFFD		; call UNA
	bit	7,b		; test RAM drive bit
	pop	hl
	pop	bc
	ld	de,udevrom	; load string
	jp	z,prtstr	; print and return
	ld	de,udevram	; load string
	jp	prtstr		; print and return
;
; Check that specified drive num is valid
;
chkdrv:
	push	hl		; preserve incoming hl
	ld	hl,(maploc)	; point to drive map
	dec	hl		; back up to point to table entry count
	cp	(hl)		; compare to incoming
	pop	hl		; restore hl now
	jp	nc,errdrv	; handle bad drive
	cp	a		; set Z to signal good
	ret			; and return
;
; Check that specified device is valid for a mapping operation
; Only hard disk devices are dynamically mappable because
;   the DPH vector allocation sizes may not change.
;
chktyp:
	cp	3		; first mappable device is 3 (IDE)
	jr	c,chkunit1	; if below 3, return error
	cp	9 + 1		; last mappable device is 9 (HDSK)
	jr	nc,chkunit1	; if above 8, return error
	xor	a		; signal valid
	ret			; and return
;
chkunit1:	; return error
	or	$ff		; signal error
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
; Start a new line
;
crlf:
	ld	a,13		; <CR>
	call	prtchr		; print it
	ld	a,10		; <LF>
	jp	prtchr		; print it
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
errdrv:	; CBIOS version is not as expected
	push	af
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
	call	crlf		; print newline
;
err1:	; without the leading crlf
	call	prtstr		; print error string
;
err2:	; without the string
	call	crlf		; print newline
	or	$FF		; signal error
	ret			; done
;
;===============================================================================
; Storage Section
;===============================================================================
;
cbftbl	.dw	0		; address of CBIOS function table
maploc	.dw	0		; location of drive map
drives:
dstdrv	.db	0		; destination drive
srcdrv	.db	0		; source drive
device	.db	0		; source device
unit	.db	0		; source unit
slice	.db	0		; source slice
;
unamod	.db	0		; $FF indicates UNA UBIOS active
;
srcptr	.dw	0		; source pointer for copy
dstptr	.dw	0		; destination pointer for copy
tmpent	.fill	4,0		; space to save a table entry
tmpstr	.fill	9,0		; temporary string of up to 8 chars, zero term
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
udevram	.db	"RAM",0
udevrom	.db	"ROM",0
udevide	.db	"IDE",0
udevsd	.db	"SD",0
udevunk	.db	"UNK",0
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Messages
;
indent	.db	"   ",0
msgban1	.db	"ASSIGN v0.9c for RomWBW CP/M 2.2, 20-Aug-2014",0
msgban2	.db	13,10,"Copyright 2014, Wayne Warthen, GNU GPL v3",13,10,0
msghb	.db	" (HBIOS Mode)",0
msgub	.db	" (UBIOS Mode)",0
msguse	.db	"Usage: ASSIGN [D:[={D:|<device><unitnum>[:<slice num>]}]]",13,10
	.db	"  ex. ASSIGN           (display all active assignments)",13,10
	.db	"      ASSIGN /?        (display version and usage)",13,10
	.db	"      ASSIGN /L        (display all possible devices)",13,10
	.db	"      ASSIGN C:=D:     (swaps C: and D:)",13,10
	.db	"      ASSIGN C:=FD0:   (assign C: to floppy unit 0)",13,10
	.db	"      ASSIGN C:=IDE0:1 (assign C: to IDE unit0, slice 1)",13,10,0
msgprm	.db	"Parameter error (ASSIGN /? for usage)",0
msginv	.db	"Unexpected CBIOS (signature missing)",0
msgver	.db	"Unexpected CBIOS version",0
msgdrv1	.db	"Invalid drive letter (",0
msgdrv2	.db	":)",0
msgswp	.db	"Invalid drive swap request",0
msgdev	.db	"Invalid device name",0
msgnum	.db	"Unit or slice number invalid",0
msgtyp	.db	"Only hard drive devices can be reassigned",0
msgint	.db	"WARNING: Multiple drive letters reference one filesystem!",0
msgdos	.db	"DOS error, return code=0x",0
;
	.end