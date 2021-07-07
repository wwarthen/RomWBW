; N8VEM	 PPI IDE test program for checkout of IDE drive connected to the 8255 PPI
;
; Written by Max Scane	July 2009
; Based on work by Paul Stoffregen  (www.pjrc.com)
;
; Note: due to a known anomaly in the 8255, some signals ( all active low signals) on the IDE bus require an inverter (74LS04 or 74LS14)
; between the 8255 and the IDE drive.
; This is due to the 8255 returning all signals to 0 (low) when a mode change is performed (for read and write to IDE data bus).
;
; This test program will allow you to check out an attached IDE drive using the basic commands:
;
; u - Spin up the drive
; d - Spin down the drive
; s - Read and print out drive status
; i - Execute drive ID command and print result correctly
; r - Read the current LBA into the sector buffer and print status
; w - Write the sector buffer to the current LBA and print status
; l - Change the current LBA
; h - Dump the current sector buffer in hexdump format
; f - format drive for CP/M use (fill with 0xE5)
; e - Display drive error information
; x - Return to CP/M
; n - read and hexdump next LBA
; ? - Display command menu help
; p - set PPI port
;
;
;
;
; - Updated December 2014 MS - changed IO routines to support different PPI ports.
; - Updated July 2021 Andrew Lynch - Minor cosmetic updates

;********************* HARDWARE IO ADR ************************************

DEFBASE:	.EQU	60H		; PPI base I/O address default

;
; Offsets to the various PPI registers

IDELSB:		.EQU	0		; LSB
IDEMSB:		.EQU	1		; MSB
IDECTL:		.EQU	2		; Control Signals
PIOCONT:	.EQU	3		; CONTROL BYTE PIO 82C55

; PPI control bytes for read and write to IDE drive

rd_ide_8255:	.EQU	10010010b	; ide_8255_ctl out, ide_8255_lsb/msb input
wr_ide_8255:	.EQU	10000000b	; all three ports output

;IDE control lines for use with ide_8255_ctl.  Change these 8
;constants to reflect where each signal of the 8255 each of the
;IDE control signals is connected.  All the control signals must
;be on the same port, but these 8 lines let you connect them to
;whichever pins on that port.

ide_a0_line:	.EQU	01H		; direct from 8255 to IDE interface
ide_a1_line:	.EQU	02H		; direct from 8255 to IDE interface
ide_a2_line:	.EQU	04H		; direct from 8255 to IDE interface
ide_cs0_line:	.EQU	08H		; inverter between 8255 and IDE interface
ide_cs1_line:	.EQU	10H		; inverter between 8255 and IDE interface
ide_wr_line:	.EQU	20H		; inverter between 8255 and IDE interface
ide_rd_line:	.EQU	40H		; inverter between 8255 and IDE interface
ide_rst_line:	.EQU	80H		; inverter between 8255 and IDE interface


;------------------------------------------------------------------
; More symbolic constants... these should not be changed, unless of
; course the IDE drive interface changes, perhaps when drives get
; to 128G and the PC industry will do yet another kludge.

;some symbolic constants for the ide registers, which makes the
;code more readable than always specifying the address pins

ide_data:	.EQU	ide_cs0_line
ide_err:	.EQU	ide_cs0_line + ide_a0_line
ide_sec_cnt:	.EQU	ide_cs0_line + ide_a1_line
ide_sector:	.EQU	ide_cs0_line + ide_a1_line + ide_a0_line
ide_cyl_lsb:	.EQU	ide_cs0_line + ide_a2_line
ide_cyl_msb:	.EQU	ide_cs0_line + ide_a2_line + ide_a0_line
ide_head:	.EQU	ide_cs0_line + ide_a2_line + ide_a1_line
ide_command:	.EQU	ide_cs0_line + ide_a2_line + ide_a1_line + ide_a0_line
ide_status:	.EQU	ide_cs0_line + ide_a2_line + ide_a1_line + ide_a0_line
ide_control:	.EQU	ide_cs1_line + ide_a2_line + ide_a1_line
ide_astatus:	.EQU	ide_cs1_line + ide_a2_line + ide_a1_line + ide_a0_line

;IDE Command Constants.	 These should never change.
ide_cmd_recal:		.EQU	10H
ide_cmd_read:		.EQU	20H
ide_cmd_write:		.EQU	30H
ide_cmd_init:		.EQU	91H
ide_cmd_id:		.EQU	0ECH
ide_cmd_spindown:	.EQU	0E0H
ide_cmd_spinup:		.EQU	0E1H

CR:		.EQU	0Dh
LF:		.EQU	0Ah
BELL:		.EQU	07H


	.org	100H

start:

; save stack pointer so that we can return to calling program

	ld	(savsp),sp
	ld	sp,stack

	call	set_ppi_rd		; setup PPI chip to known state

	ld	hl,lba1			; zero LBA variables
	call	clrlba

	ld	hl,lba2
	call	clrlba

	ld	hl,lba3
	call	clrlba


	call	print
	.db	"PPI IDE test program v0.6b",CR,LF,0

	call	prport
	call	prstatus
	call	prlba

	call	ide_init
	call	prstatus

	call	crlf

menu:
	call	print			; display prompt
	.db	"Enter command (u,d,s,i,r,w,l,h,f,e,n,p,?,x) > ",0

	call	cin			; get command from console in reg A
	push	af
	call	crlf
	pop	af

mnu1:
	cp	'd'			; spin down command
	jr	nz,mnu2
	call	spindown
	jr	menu
mnu2:
	cp	'u'			; spinup command
	jr	nz,mnu3
	call	spinup
	jr	menu

mnu3:
	cp	's'			; print IDE status reg contents
	jr	nz,mnu4
	call	prstatus
	jr	menu

mnu4:
	cp	'i'
	jr	nz,mnu5			; drive ID command
	call	drive_id
	jr	menu

mnu5:
	cp	'r'
	jr	nz,mnu6			; read command
	call	prlba			; print out the current LBA
	call	read_sector		; read current LBA
	call	prstatus
	jr	menu

mnu6:
	cp	'w'
	jr	nz,mnu7			; write command
	call	prlba			; print out the current LBA
	call	write_sector		; write current LBA
	call	prstatus
	jr	menu

mnu7:
	cp	'l'
	jr	nz,mnu8			; LBA command
	call	prlba			; print out the current LBA
mnu7a:
	call	print
	.db	"Enter new LBA: ",0

	ld	de,lba1			; get LBA in lba1
	call	getlba
	jp	nc,menu			; valid, finished

	call	print
	.db	"Invalid LBA",CR,LF,0

	jr	mnu7a			; try again


mnu8:
	cp	'h'
	jr	nz,mnu9			; hexdump command
	call	hexdump			; hexdump the current sector buffer
	jp	menu

mnu9:
	cp	'f'
	jr	nz,mnua			; drive format
	call	format
	jp	menu

mnua:
	cp	'e'
	jr	nz,mnub			; get error register
	call	get_err
	push	af
	call	print
	.db	"Error register is: ",0

	pop	af
	call	prhex
	call	crlf


	ld	a,ide_head
	call	ide_read
	ld	a,c
	call	prhex

	ld	a,ide_cyl_msb
	call	ide_read
	ld	a,c
	call	prhex

	ld	a,ide_cyl_lsb
	call	ide_read
	ld	a,c
	call	prhex


	ld	a,ide_sector
	call	ide_read
	ld	a,c
	call	prhex

	call	crlf

	ld	a,ide_sec_cnt
	call	ide_read
	ld	a,c
	call	prhex
	call	crlf

	jp	menu


mnub:
	cp	'n'
	jr	nz,mnuc
	ld	hl,lba1
	call	inclba
	call	prlba
	call	read_sector
	call	hexdump
	jp	menu

mnuc:
	cp	'p'
	jr	nz,mnux
	call	prport
mnuca:
	call	print
	.db	"Enter new PPI base port: ",0

	ld	a,(ppibase)
	call	gethexbyte
	jr	c,mnucb
	ld	(ppibase),a		; save it
	call	prport
	jp	menu

mnucb:
	call	print
	.db	"Invalid PPI base port value",CR,LF,0
	jr	mnuca

mnux:
	cp	'x'			; exit command
	jp	nz,mnuhlp
	ld	sp,(savsp)
	ret


mnuhlp:
	call	print
	.db	"Commands available:",CR,LF,LF
	.db	"u - Spin Up drive",CR,LF
	.db	"d - Spin Down drive",CR,LF
	.db	"s - Print drive Status",CR,LF
	.db	"i - Query drive using ID command",CR,LF
	.db	"r - Read a sector addressed by the lba variable",CR,LF
	.db	"w - Write a sector adresses by the lba variable",CR,LF
	.db	"l - Change the current LBA variable",CR,LF
	.db	"h - Hexdump the current buffer",CR,LF
	.db	"f - Format the drive for CP/M use (fill with 0xE5)",CR,LF
	.db	"e - Display drive Error information",CR,LF
	.db	"p - Change base IO port",CR,LF
	.db	"? - Display command menu help",CR,LF
	.db	"x - eXit from this utility",CR,LF,LF,0
	jp	menu


format:
	call	print
	.db	"Warning - this command will write data to the drive",CR,LF,LF
	.db	"All existing data will be over written",CR,LF,LF
	.db	"Is that what you want to do ? ",0

	call	cin			; get answer
	cp	'y'
	jr	z,fmt1			; if yes then continue
	call	print
	.db	" Command aborted",CR,LF,0
	ret

fmt1:
	ld	a,0E5h
	call	fillbuf			; setup sector buffer
fmt2:

	call	print
	.db	CR,LF,"Enter starting LBA: ",0

	ld	de,lba2			; starting LBA
	call	getlba
	jr	nc,fmt3

	call	print
	.db	"Invalid LBA",CR,LF,0
	jr	fmt2			; try again

fmt3:

	call	crlf

fmt4:
	call	print
	.db	"Enter ending LBA: ",0

	ld	de,lba3			; ending LBA
	call	getlba
	jr		nc,fmt5

	call	print
	.db	"Invalid LBA",CR,LF,0

	jr	fmt4			; try again

fmt5:
	call	crlf

	call	print			; say what is going to happen
	.db	"Format will start at LBA ",0

	ld	a,(lba2+3)
	call	prhex
	ld	a,(lba2+2)
	call	prhex
	ld	a,(lba2+1)
	call	prhex
	ld	a,(lba2)
	call	prhex

	call	print
	.db	" and finish at LBA ",0
	ld	a,(lba3+3)
	call	prhex
	ld	a,(lba3+2)
	call	prhex
	ld	a,(lba3+1)
	call	prhex
	ld	a,(lba3)
	call	prhex

	call	crlf
	call	print
	.db	"Type y to continue or any other key to abort ",0

	call	cin
	cp	'y'
	jp	nz,fmtx
	call	crlf

	; add the actual format code here
	; get starting LBA
	; get ending LBA
	; fill buffer with E5

	ld	hl,lba2
	ld	de,lba1
	call	cpylba			; copy start LBA to LBA
	call	inclba


fmt6:
	push	hl
	call	print			; display progress
	.db	"Writing LBN: ",0
	ld	a,(lba1+3)
	call	prhex
	ld	a,(lba1+2)
	call	prhex
	ld	a,(lba1+1)
	call	prhex
	ld	a,(lba1)
	call	prhex
	ld	a,CR
	call	cout
	pop	hl

;	do some stuff to format here
	call	write_sector

; need to check status after each call and check for errors
;
	ld	hl,lba1			; LBA for disk operation
	call	inclba

	ld	hl,lba1
	ld	de,lba3
	call	cplba

	jp	nz,fmt6

	call	crlf

fmtx:
	call	print			; finished
	.db	"Format complete",CR,LF,0
	ret


getlba:					; get an LBA value from the console and validate it
	push	de			; save LBA variable
	ld	c,0ah			; bdos read console buffer
	ld	de,conbuf
	call	5			; get edited string

	call	crlf

	; ok we now have an ascii string representing the LBA.	now we have to validate it

	pop	de
	ld	hl,conbuf
	inc	hl
	ld	b,(hl)			; get character count
glba1:
	inc	hl			; HL = address of buffer
	ld	a,(hl)			; get next character

	call	ishex
	ret	c			; return with carry set if any char is invalid

	; ok we are here when we have a valid character (0-9,A-F,a-f) need to convert to binary
	; character is still in A

	cp	3AH			; test for 0-9
	jp	m,glba4
	cp	47H			; test for A-F
	jp	m,glba3
	cp	67H			; test for a-f
	jp	m,glba2

glba2:
	sub	20H			; character is a-f
glba3:
	sub	07h			; character is A-F
glba4:
	sub	030H			; character is 0-9

	ld	(hl),a			; save back in buffer as binary
	djnz	glba1			; continue checking the buffer

; need to pack bytes into the destination LBA which is in de and points to the LSB

glba5:

;  - need to change the endian-ness
	push	de
	ex	de,hl			; clear LBA ready
;	push	de			; address of LBA
;	pop	hl			; address of input buffer
	ld	a,0			; zero existing LBA variable
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a

	ex	de,hl			; de now positioned at end of LBA
	pop	de			; restore LBA
	; de still contains dest address
	; now pack and store LBA

	ld	hl,conbuf+1		; get character count
	ld	b,(hl)
	inc	hl			; point to first character in buffer

glba6:
	push	de			; save starting address for next subsequent rotations
	ld	a,(hl)			; get next char from buffer
	inc	hl			; next character
	ex	de,hl			; switch to LBA
	rld				; shift nibble into LBA
	inc	hl
	rld
	inc	hl
	rld
	inc	hl
	rld
	ex	de,hl			; back to console buffer
	pop	de			; restore address of LBA
	djnz	glba6			; process next character

	scf
	ccf				; exit with carry clear = success
	ret


gethexbyte:
	push	af			; save incoming value
	ld	c,0ah			; bdos read console buffer
	ld	de,conbuf
	call	5			; get edited string
	call	crlf
	pop	de			; restore incoming to d

	; ok we should now have a string with a hex number
	ld	hl,conbuf
	inc	hl
	ld	a,(hl)			; get character count
	inc	hl
	cp	3
	jr	c,ghb0			; ok if <= 2 chars
	scf				; signal error
	ret				; and return

ghb0:
	or	a			; set flags
	jr	nz,ghb1			; got chars, go ahead
	ld	a,d			; restore incoming value
	or	a			; signal success
	ret				; and done

ghb1:
	ld	b,a			; count to b
	ld	c,0			; initial value

ghb2:
	ld	a,(hl)			; get next char
	inc	hl
	call	ishex
	ret	c			; abort on non-hex char

	; ok we are here when we have a valid character (0-9,A-F,a-f) need to convert to binary
	; character is still in A

	cp	3AH			; test for 0-9
	jp	m,ghb2c
	cp	47H			; test for A-F
	jp	m,ghb2b
	cp	67H			; test for a-f
	jp	m,ghb2a
ghb2a:	sub	20H			; character is a-f
ghb2b:	sub	07H			; character is A-F
ghb2c:	sub	30H			; character is 0-9

	rlc	c			; multiply cur value by 16
	rlc	c
	rlc	c
	rlc	c
	add	a,c			; add to accum
	ld	c,a			; put back in c

	djnz	ghb2			; loop thru all chars

	ld	a,c			; into a for return
	or	a			; signal success
	ret				; done

ishex:
	cp	30h			; check if less than character 0
	jp	m,nothex
	cp	3Ah			; check for > 9
	jp	m,ishx1			; ok, character is 1-9

	cp	41h			; check for character less than A
	jp	m,nothex
	cp	47H			; check for characters > F
	jp	m,ishx1

	cp	61H			; check for characters < a
	jp	m,nothex

	cp	67H			; check for character > f
	jp	m,ishx1
nothex:
	scf				; set carry to indicate fail
	ret

ishx1:
	scf
	ccf
	ret



fillbuf:
					; fill sector buffer with character specified in A
	ld		hl,buffer
	ld		b,0
fb1:
	ld		(hl),a		; store character in buffer
	inc		hl
	ld		(hl),a
	inc		hl
	djnz	fb1
	ret


hexdump:

	call	print			; print heading
	.db	"Current sector buffer contents:",CR,LF,LF,0

	ld	b,32			;  line counter
	ld	hl,buffer		; address of buffer to dump
hxd1:

	push	bc			; save loop counter
	push	hl			; save address pointer

	push	hl
	ld	a,h
	call	prhex			; print hi byte of address
	pop	hl

	push	hl
	ld	a,l
	call	prhex			; print lo byte of address
	ld	a,' '
	call	cout
	pop	hl


	ld	b,16			; how many characters do we display
hxd2:
	push	bc

	ld	a,(hl)			; get byte from buffer
	inc	hl
	push	hl

	call	prhex			; display it in hex
	ld	a,' '
	call	cout

	pop	hl
	pop	bc
	djnz	hxd2

	pop	hl

	ld	b,16			; how many characters do we display
hxd3:
	push	bc

	ld	a,(hl)			; get byte from buffer
	inc	hl
	push	hl

	call	prascii			; display it in ASCII

	pop	hl
	pop	bc
	djnz	hxd3

	push	hl
	call	crlf

	pop	hl
	pop	bc

	ld	a,b				; check for screen pause
	cp	16
	jp	nz,hxd4

	push	hl
	push	bc
	call	cin				; wait for a character
	pop	bc
	pop	hl

hxd4:
	djnz	hxd1			; continue if not at end of buffer

	call	crlf
	call	crlf
	ret

prascii:

	cp	20H
	jp	m,pra1			; anything less than 20H is non-printable
	cp	7fH			; anything greater than 7E is non-printable
	jp	m,pra2
pra1:
	ld	a,'.'
pra2:
	call	cout
	ret
;
;
;
; -------------------------------------------------------------------------
;
; LBA manipulation routines;
;
cpylba:
					; copy LBA to LBA
					; source = HL,	Destination = DE
	ld	bc,04H
	ldir
	ret

; -------------------------------------------------------------------------

inclba:
	ld	a,(hl)			; first byte
	add	a,1
	ld	(hl),a
	ret	nc

	inc	hl			;second byte
	ld	a,(hl)
	add	a,1
	ld	(hl),a
	ret	nc

	inc	hl			; third byte
	ld	a,(hl)
	add	a,1
	ld	(hl),a
	ret	nc

	inc	hl			; fourth byte (MSB)
	ld	a,(hl)
	add	a,1
	ld	(hl),a

	ret

; -------------------------------------------------------------------------

cplba:					; compare LBA
					; addresses by HL and DE

	ld	a,(hl)			; start at LSB
	inc	hl
	ex	de,hl
	cp	(hl)
	ret	nz
	inc	hl
	ex	de,hl

	ld	a,(hl)
	inc	hl
	ex	de,hl
	cp	(hl)
	ret	nz
	inc	hl
	ex	de,hl

	ld	a,(hl)
	inc	hl
	ex	de,hl
	cp	(hl)
	ret	nz
	inc	hl
	ex	de,hl

	ld	a,(hl)
	inc	hl
	ex	de,hl
	cp	(hl)
	ret

	ret	nz
	inc	hl
	ex	de,hl

	ret

; -------------------------------------------------------------------------

prlba:

	call	print
	.db	"Current LBA = ",0
	ld	a,(lba1+3)
	call	prhex
	ld	a,(lba1+2)
	call	prhex
	ld	a,(lba1+1)
	call	prhex
	ld	a,(lba1)
	call	prhex
	call	crlf
	call	crlf
	ret

; -------------------------------------------------------------------------

prport:
	call	print
	.db	"Current PPI base port: 0x",0
	ld	a,(ppibase)
	call	prhex
	call	crlf
	ret


clrlba:
	ld	a,0
	ld	b,4
clr32b1:
	ld	(hl),a
	inc	hl
	djnz	clr32b1
	ret


; -------------------------------------------------------------------------

prstatus:
	call	print
	.db	"status = ",0

	ld	a,ide_status		; read IDE status register
	call	ide_read
	ld	a,c			; returned value
	call	prhex

	call	crlf
	ret




print:
	pop	hl			; get address of text
	ld	a,(hl)			; get next character
	inc	hl
	push	hl
	cp	0
	ret	z			; end of text found
	call	cout			; output character
	jp	print

; -------------------------------------------------------------------------

prhex:					; print hexadecimal digit in A
	push	af
	srl	a			; move high nibble to low
	srl	a
	srl	a
	srl	a
	call	hexnib			; convert to ASCII Hex
	call	cout			; send character to output device
	pop	af
	call	hexnib
	call	cout			; send character to output device
	ret



hexnib:
	and		0fh		; strip high order nibble
	add		a,30H		; add ASCII ofset
	cp		3ah		; correction necessary?
	ret		m
	add		a,7		; correction for A to F
	ret

; -------------------------------------------------------------------------

cout:
	ld	e,a
	ld	c,02h			; Console output byte call
	call	5
	ret

; -------------------------------------------------------------------------

cin:
	ld	c,01h			; BDOS console function
	call	5
	ret

; -------------------------------------------------------------------------

crlf:
	ld	a,CR
	call	cout
	ld	a,LF
	call	cout
	ret

;------------------------------------------------------------------
; Routines that talk with the IDE drive, these should be called by
; the main program.


	; read a sector, specified by the 4 bytes in "lba",
	; Return, acc is zero on success, non-zero for an error
read_sector:
	call	ide_wait_not_busy	;make sure drive is ready
	call	wr_lba			;tell it which sector we want

	ld	a, ide_command
	ld	c, ide_cmd_read
	call	ide_write		; ask the drive to read it

	call	ide_wait_drq		;wait until it's got the data

	bit	0,a
	jp	nz, get_err
	ld	hl, buffer
	call	read_data		;grab the data
	ld	a,0
	ret


	; when an error occurs, we get acc.0 set from a call to ide_drq
	; or ide_wait_not_busy (which read the drive's status register).  If
	; that error bit is set, we should jump here to read the drive's
	; explanation of the error, to be returned to the user.	 If for
	; some reason the error code is zero (shouldn't happen), we'll
	; return 255, so that the main program can always depend on a
	; return of zero to indicate success.
get_err:
	ld	a,ide_err
	call	ide_read
	ld	a,c
	jp	z,gerr2
	ret
gerr2:
	ld	a, 255
	ret


	;write a sector, specified by the 4 bytes in "lba",
	;whatever is in the buffer gets written to the drive!
	;Return, acc is zero on success, non-zero for an error
write_sector:
	call	ide_wait_not_busy	; make sure drive is ready
	call	wr_lba				; tell it which sector we want
	ld	a, ide_command
	ld	c, ide_cmd_write

	call	ide_write		;tell drive to write a sector
	call	ide_wait_drq		;wait unit it wants the data
	bit	0,a			; check for error returned
	jp	nz,get_err

	ld	hl, buffer
	call	write_data		;give the data to the drive
	call	ide_wait_not_busy	;wait until the write is complete

	bit	0,a
	jp	nz,get_err

	ld	a,0
	ret


	; do the identify drive command, and return with the buffer
	; filled with info about the drive
drive_id:
	call	ide_wait_not_busy
	ld	a,ide_head
	ld	c,10100000b
	call	ide_write		;select the master device
	call	ide_wait_ready
	ld	a,ide_command
	ld	c,0ech
	call	ide_write		;issue the command
	call	ide_wait_drq
	ld	hl, buffer
	call	read_data
	ret


	; tell the drive to spin up
spinup:
	ld	c,ide_cmd_spinup
	ld	a,ide_command
	call	ide_write
	call	ide_wait_not_busy
	ret

	; tell the drive to spin down
spindown:
	call	ide_wait_not_busy
	ld	c,ide_cmd_spindown
	ld	a,ide_command
	call	ide_write
	call	ide_wait_not_busy
	ret

	; initialize the IDE drive
ide_init:
	ld	a, ide_head
	ld	b, 0
	ld	c, 10100000b		; select the master device
	call	ide_write
init1:
	ld	a, ide_status
	call	ide_read
	ld	a, c

	; should probably check for a timeout here
	bit	6,a			; wait for RDY bit to be set
	jp	z,init1
	bit	7,a
	jp	nz,init1		; wait for BSY bit to be clear

	ret



; IDE Status Register:
;  bit 7: Busy	1=busy, 0=not busy
;  bit 6: Ready		1=ready for command, 0=not ready yet
;  bit 5: DF		1=fault occured inside drive
;  bit 4: DSC	1=seek complete
;  bit 3: DRQ	1=data request ready, 0=not ready to xfer yet
;  bit 2: CORR	1=correctable error occured
;  bit 1: IDX	vendor specific
;  bit 0: ERR	1=error occured





;------------------------------------------------------------------
; Not quite as low, low level I/O.  These routines talk to the drive,
; using the low level I/O.  Normally a main program should not call
; directly to these.


	;Read a block of 512 bytes (one sector) from the drive
	;and store it in memory @ HL
read_data:
	ld	b, 0
rdblk2:
	push	bc
	push	hl
	ld	a, ide_data
	call	ide_read
	pop	hl
	ld	a, c
	ld	(hl), a
	inc	hl
	ld	a, b
	ld	(hl), a
	inc	hl
	pop	bc
	djnz	rdblk2
	ret


	; Write a block of 512 bytes (at HL) to the drive
write_data:
	ld	b,0
wrblk2:
	push	bc
	ld	a,(hl)
	ld	c, a			; LSB
	inc	hl
	ld	a,(hl)
	ld	b, a			; MSB
	inc	hl
	push	hl

	ld	a, ide_data
	call	ide_write
	pop	hl
	pop	bc
	djnz	wrblk2
	ret



	; write the logical block address to the drive's registers
wr_lba:
	ld	a,(lba1+3)		; MSB
	and	0fh
	or	0e0h
	ld	c,a
	ld	a,ide_head
	call	ide_write

	ld	a,(lba1+2)
	ld	c,a
	ld	a,ide_cyl_msb
	call	ide_write

	ld	a,(lba1+1)
	ld	c,a
	ld	a,ide_cyl_lsb
	call	ide_write

	ld	a,(lba1+0)		; LSB
	ld	c,a
	ld	a,ide_sector
	call	ide_write

	ld	c,1
	ld	a,ide_sec_cnt
	call	ide_write


	ret


ide_wait_not_busy:
	ld	a,ide_status		;wait for RDY bit to be set
	call	ide_read
	bit	7,c
	jp	nz,ide_wait_not_busy
	; should probably check for a timeout here

	ret


ide_wait_ready:
	ld	a,ide_status		; wait for RDY bit to be set
	call	ide_read
	bit	6,c			; test for XXX
	jp	z,ide_wait_ready
	bit	7,c
	jp	nz,ide_wait_ready

	;should probably check for a timeout here
	ret



	; Wait for the drive to be ready to transfer data.
	; Returns the drive's status in Acc
ide_wait_drq:
	ld	a,ide_status			;wait for DRQ bit to be set
	call	ide_read
	bit	7,c
	jp	nz,ide_wait_drq			; check for busy
	bit	3,c					; wait for DRQ
	jp	z,ide_wait_drq

	; should probably check for a timeout here

	ret



;-----------------------------------------------------------------------------
; Low Level I/O to the drive.  These are the routines that talk
; directly to the drive, via the 8255 chip.  Normally a main
; program would not call to these.

	; Do a read bus cycle to the drive, using the 8255.
	; input acc = IDE register address
	; output C = lower byte read from IDE drive
	; output B = upper byte read from IDE drive




ide_read:
	push	af			; save register value
	push	bc
	call	set_ppi_rd		; setup for a read cycle
	pop	bc

	pop	af			; restore register value
	call	wrppictl		; write to control sigs

	or	ide_rd_line		; assert RD pin
	call	wrppictl		; write to control sigs

	push	af			; save register value
	call	rdppilsb		; read LSB register into A
	ld	c,a			; save in reg C

	call	rdppimsb		; read MSB register into A
	ld	b,a			; save in reg C


	pop	af			; restore register value
	xor	ide_rd_line		; de-assert RD signal
	call	wrppictl		; write to control sigs

	ld	a,0
	call	wrppictl		; write to control sigs
	ret



	; Do a write bus cycle to the drive, via the 8255
	; input acc = IDE register address
	; input register C = LSB to write
	; input register B = MSB to write
	;

ide_write:
	push	af			; save IDE register value

	push	bc
	call	set_ppi_wr		; setup for a write cycle
	pop	bc

	ld	a,c			; get value to be written
	call	wrppilsb

	ld	a,b			; get value to be written
	call	wrppimsb

	pop	af			; get saved IDE register
	call	wrppictl		; write to control sigs

	or	ide_wr_line		; assert write pin
	call	wrppictl		; write to control sigs

	xor	ide_wr_line		; de assert WR pin
	call	wrppictl		; write to control sigs

	ld	a,0
	call	wrppictl		; write to control sigs
	ret


;-------------------------------------------------------------------------------------------

ide_hard_reset:
	call	set_ppi_rd
	ld	a,ide_rst_line
	call	wrppictl		; write to control register
	ld	bc,0
rstdly:
	djnz	rstdly
	ld	a,0
	call	wrppictl		; write to control registers
	ret

;-----------------------------------------------------------------------------------
; PPI setup routine to configure the appropriate PPI mode
;
;------------------------------------------------------------------------------------

set_ppi_rd:
	ld	a,(ppibase)
	add	a,PIOCONT		; select Control register
	ld	c,a
	ld	a,rd_ide_8255		; configure 8255 chip, read mode
	out	(c),a
	ret

set_ppi_wr:
	ld	a,(ppibase)
	add	a,PIOCONT		; select Control register
	ld	c,a
	ld	a,wr_ide_8255		; configure 8255 chip, write mode
	out	(c),a
	ret

;------------------------------------------------------------------------------------

rdppilsb:				; read LSB
					; returns data in A
	push	bc
	ld	a,(ppibase)
	add	a,IDELSB		; select Control register
	ld	c,a
	in	a,(c)
	pop	bc
	ret


wrppilsb:				; write LSB
					; data to be written in A
	push	bc
	push	af
	ld	a,(ppibase)
	add	a,IDELSB		; select Control register
	ld	c,a
	pop	af
	out	(c),a
	pop	bc
	ret

;--------------------------------------------------------------------------

rdppimsb:				; read MSB
					; returns data in A
	push	bc
	ld	a,(ppibase)
	add	a,IDEMSB		; select MSB Register
	ld	c,a
	in	a,(c)
	pop	bc
	ret


wrppimsb:				; write LSB
					; data to be written in A
	push	bc
	push	af
	ld	a,(ppibase)
	add	a,IDEMSB		; select MSB Register
	ld	c,a
	pop	af
	out	(c),a
	pop	bc
	ret

;--------------------------------------------------------------------------

wrppictl:				; write to control signals
					; data to be written in A
	push	bc
	push	af
	ld	a,(ppibase)
	add	a,IDECTL		; select CTL Register
	ld	c,a
	pop	af
	out	(c),a
	pop	bc
	ret

;--------------------------------------------------------------------------
; Storage area follows

savsp:		.dw	0		; saved stack pointer
lba1:		.dw	0,0		; LBA used for read/write operations
lba2:		.dw	0,0		; Start LBA for format
lba3:		.dw	0,0		; End LBA for format
ppibase:	.db	DEFBASE		; base address of PPI chip

		.fill	0C00H - $

buffer:		.fill	512		; sector buffer for IDE transfers
conbuf:		.db	8		; maximum chars
		.db	0		; count
		.fill	8		; size of buffer

		.fill	100
stack:

	.end

