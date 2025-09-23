;===============================================================================
; MODE - Display and/or modify device configuration
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   MODE /?
;   MODE COM<n>: [<baud>[,<parity>[,<databits>[,<stopbits>]]]] [/P]
;
;   <baud> is numerical baudrate
;   <parity> is (N)one, (O)dd, (E)ven, (M)ark, or (S)pace
;   <databits> is number of data bits, typically 7 or 8
;   <stopbits> is number of stop bits, typically 1 or 2
;   /P prompts user prior to setting new configuration
;
; Examples:
;   MODE /?			(display command usage)
;   MODE			(display configuration of all serial ports)
;   MODE COM0:			(display configuration of serial unit 0)
;   MODE COM1: 9600,N,8,1	(set serial unit 1 configuration)
;
; Notes:
;   - Parameters not provided will remain unchanged
;   - Device must support specified configuration
;_______________________________________________________________________________
;
; Change Log:
;   2017-08-16 [WBW] Initial release
;   2017-08-28 [WBW] Handle UNACPM
;   2018-07-24 [WBW] Fixed bug in getnum23 routine (credit Phil Summers)
;_______________________________________________________________________________
;
; ToDo:
;  1) Implement flow control settings
;_______________________________________________________________________________
;
#include "../../ver.inc"
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
ident	.equ	$FFFC		; loc of RomWBW HBIOS ident ptr
;
bf_cioinit	.equ	$04	; HBIOS: CIOINIT function
bf_cioquery	.equ	$05	; HBIOS: CIOQUERY function
bf_ciodevice	.equ	$06	; HBIOS: CIODEVICE function
bf_sysget	.equ	$F8	; HBIOS: SYSGET function
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
	; get the target device
	call 	getdev		; parse device/id from command line
	jr	nz,exit		; abort on error
;
	; process the configuration request
	call 	process		; parse device/id from command line
	jr	nz,exit		; abort on error
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
	; locate start of cbios (function jump table)
	ld	hl,(restart+1)	; load address of CP/M restart vector
	ld	de,-3		; adjustment for start of table
	add	hl,de		; HL now has start of table
	ld	(bioloc),hl	; save it
;
	; check for UNA (UBIOS)
	ld	a,($FFFD)	; fixed location of UNA API vector
	cp	$C3		; jp instruction?
	jr	nz,initwbw	; if not, not UNA
	ld	hl,($FFFE)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$FD		; first byte of UNA push ix instruction
	jr	nz,initwbw	; if not, not UNA
	inc	hl		; point to next byte
	ld	a,(hl)		; get next byte
	cp	$E5		; second byte of UNA push ix instruction
	jr	nz,initwbw	; if not, not UNA
;
	; UNA initialization
	ld	hl,unamod	; point to UNA mode flag
	ld	(hl),$FF	; set UNA mode flag
	ld	a,$FF		; assume max units for UNA
	ld	(comcnt),a	; ... and save it
	jr	initx		; UNA init done
;
initwbw:
	; get location of config data and verify integrity
	ld	hl,(ident)	; HL := adr or RomWBW HBIOS ident
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
;
	; RomWBW initialization
	ld	b,bf_sysget	; BIOS SYSGET function
	ld	c,$00		; CIOCNT subfunction
	rst	08		; E := serial device unit count
	ld	a,e		; count to A
	ld	(comcnt),a	; save it
;
initx
	; initialization complete
	xor	a		; signal success
	ret			; return
;
; Get target device specification (e.g., "COM1:") and save
; as devicetype/id.
;
getdev:
	; skip to start of first parm
	ld	ix,$81		; point to start of parm area (past len byte)
	call	nonblank	; skip to next non-blank char
	jp	z,prtcomall	; no parms, show all active ports
;
getdev1:
	; process options (if any)
	cp	'/'		; option prefix?
	jr	nz,getdev2	; not an option, continue
	call	option		; process option
	ret	nz		; some options mean we are done (e.g., "/?")
	inc	ix		; skip option character
	call 	nonblank	; skip whitespace
	jr	getdev1		; continue option checking
;
getdev2:
	; parse device mnemonic (e.g., "COM1") into tmpstr
	call	getalpha	; extract alpha portion (e.g., "COM")
	call	getnum		; extract numeric portion
	jp	c,errunt	; handle overflow as invalid unit
	ld	(unit),a	; save as unit number
;
	; skip terminating ':' in device spec
	ld	a,(ix)		; get current char
	cp	':'		; colon?
	jr	nz,getdev3	; done if no colon
	inc	ix		; otherwise, skip the colon
;
getdev3:
	call	nonblank	; gobble any remaining whitespace
	xor	a		; indicate success
	ret			; and return
;
; Process device
;
process:
	; match and branch according to device mnemonic
	ld	hl,tmpstr	; point to start of extracted string
	ld	de,strcom	; point to "COM" string
	call	strcmp		; and compare
	jp	z,comset	; handle COM port configuration
	jp	errdev		; abort if bad device name
;
; Display or change serial port configuration
;
comset:
	; check for valid unit number
	ld	hl,comcnt	; point to com device unit count
	ld	a,(unit)	; get com device unit count
	cp	(hl)		; compare to count (still in E)
	jr	c,comset1	; unit < count, continue
	jp	errunt		; handle unit number error
;
comset1:
	call	ldcom		; load config for port
;
	ld	a,(comatr)	; get attributes
	bit	7,a		; terminal?
	jp	nz,prtcom	; terminal not configurable
;
	ld	a,(ix)		; get current char
	cp	0		; nothing more?
	jp	z,prtcom	; no config parms, print current device config
;
	; parse and update baudrate
	ld	a,(ix)		; get current byte
	cp	'0'		; check for
	jr	c,comset1a	; ... valid digit
	cp	'9'+1		; ... else jump ahead
	jr	nc,comset1a	; ... to handle empty
;
	call	getnum32	; get baud rate into DE:HL
	jp	c,errcfg	; Handle overflow error
	ld	c,75		; Constant for baud rate encode
	call	encode		; encode into C:4-0
	jp	nz,errcfg	; Error if encode fails
	ld	a,(comcfg+1)	; Get high byte of config
	and	%11100000	; strip out old baud rate bits
	or	c		; insert new baud rate bits
	ld	(comcfg+1),a	; save it
;
comset1a:
	; parse and update parity
	call	nonblank	; skip blanks
	jp	z,comset9	; end of parms
	cp	','		; comma, as expected?
	jp	nz,comset8	; check for trailing options
	inc	ix		; skip comma
	call	nonblank	; skip possible blanks
	call	ucase
	; lookup parity value
	ld	c,0
	cp	'N'
	jr	z,comset2
	ld	c,1
	cp	'O'
	jr	z,comset2
	ld	c,3
	cp	'E'
	jr	z,comset2
	ld	c,5
	cp	'M'
	jr	z,comset2
	ld	c,7
	cp	'S'
	jr	z,comset2
	jr	comset3		; unexpected parity char, possibly empty
;
comset2:
	; update parity value
	ld	a,c		; new parity value to A
	rlca			; rotate to bits 5-3
	rlca			;
	rlca			;
	ld	c,a		; and back to C
	ld	a,(comcfg)	; parity is in comcfg:5-3
	and	%11000111	; strip old value
	or	c		; apply new value
	ld	(comcfg),a	; and save it
	inc	ix		; bump past parity char
;
comset3:
	; parse & update data bits
	call	nonblank	; skip blanks
	jr	z,comset9	; end of parms
	cp	','		; comma, as expected?
	jr	nz,comset8	; check for trailing options
	inc	ix		; skip comma
	call	nonblank	; skip possible blanks
	sub	'5'		; normalize value
	cp	4		; value should now be 0-3
	jr	nc,comset4	; unexpected, possibly empty
	ld	c,a		; move new value to C
	ld	a,(comcfg)	; data bits is in comcfg:1-0
	and	%11111100	; strip old value
	or	c		; apply new value
	ld	(comcfg),a	; and save it
	inc	ix		; bump past data bits char
;
comset4:
	; parse & update stop bits
	call	nonblank	; skip blanks
	jr	z,comset9	; end of parms
	cp	','		; comma, as expected?
	jr	nz,comset8	; check for trailing options
	inc	ix		; skip comma
	call	nonblank	; skip possible blanks
	sub	'1'		; normalize value
	cp	2		; value should now be 0-1
	jr	nc,comset8	; unexpected, possibly empty
	rlca			; rotate to bit 2
	rlca
	ld	c,a		; move new value to C
	ld	a,(comcfg)	; stop bit is in comcfg:2
	and	%11111011	; strip old value
	or	c		; apply new value
	ld	(comcfg),a	; and save it
	inc	ix		; bump past stop bits char
;
comset8:
	; trailing options
	call	nonblank	; skip blanks
	jr	z,comset9	; end of parms
	cp	'/'		; option introducer?
	jp	nz,errprm	; parameter error
	inc	ix		; bump part '/'
	ld	a,(ix)		; get character
	call	ucase		; make upper case
	cp	'P'		; only valid option
	jp	nz,errprm	; parameter error
	ld	a,$FF		; set prompt value on
	ld	(pflag),a	; save it
	inc	ix		; bump past character
	jr	comset8		; process more parms
;
comset9:
	; display new config
	ld	de,(comcfg)	; get new config
	call	prtcom		; print it
	ld	a,(pflag)	; get prompt flag
	or	a		; set flags
	jr	z,comset9b	; bypass if not requested
	call	crlf2		; spacing
	ld	de,indent	; indent
	call	prtstr		; do it
	ld	de,msgpmt	; point to prmopt message
	call	prtstr		; print it
;
	ld	b,64
comset9a:
	xor	a
	call	prtchr
	djnz	comset9a
;
comset9b:
	; check for UNA
	ld	a,(unamod)	; get UNA flag
	or	a		; set flags
	jr	nz,comsetu	; go to UNA variant
;
	; implement new config
	ld	de,(comcfg)	; get new config value to DE
	ld	b,bf_cioinit	; BIOS serial init
	ld	a,(unit)	; get serial device unit
	ld	c,a		; ... into C
	rst	08		; call HBIOS
	jp	nz,errcfg	; handle error
	jr	comsetx		; common exit
;
comsetu:
	; implement new config under UNA
	ld	de,(comcfg)	; get new config value to DE
	ld	c,$10		; UNA INIT function
	ld	a,(unit)	; get serial device unit
	ld	b,a		; ... into B
	rst	08		; call HBIOS
	jp	nz,errcfg	; handle error
	jr	comsetx		; common exit
;
comsetx:
	ld	a,(pflag)	; get prompt flag
	or	a		; set flags
	jr	z,comsetx2	; bypass if not requested
comsetx1:
	ld	c,$01		; console read
	call	bdos		; do it
	cp	$0D		; CR?
	jr	nz,comsetx1	; loop as needed
;
comsetx2:
	xor	a
	ret
;
; Print configuration of all serial ports
;
prtcomall:
	ld	a,(comcnt)	; get com device unit count
	ld	b,a		; init B as loop counter
	ld	c,0		; init C as unit index
;
prtcomall1:
	push	bc		; save loop control
;
	; get port info
	ld	a,c		; put unit number
	ld	(unit),a	; ... into unit
	call	ldcom		; get config
	jr	z,prtcomall2	; no error, continue
	pop	bc		; unwind stack
	ret			; and return with NZ
;
prtcomall2:
	; print config for port
	call	prtcom		; print line for this port
;
	; loop as needed
	pop	bc		; restore loop control
	inc	c		; next unit index
	djnz	prtcomall1	; loop till done
;
	or	$FF		; indicate nothing more to do
	ret			; finished
;
; Print configuration of serial port
;
prtcom:
	; print leader (e.g., "COM0: ")
	call	crlf
	ld	de,indent
	call	prtstr
	ld	de,strcom
	call	prtstr
	ld	a,(unit)
	call	prtdecb
	ld	a,':'
	call	prtchr
	ld	a,' '
	call	prtchr
;
	ld	a,(comatr)	; get attribute byte
	bit	7,a		; 0=RS232, 1=terminal
	jr	z,prtcom1	; handle serial port configuration
;
	; this is a terminal, just say so
	ld	de,strterm	; point to string
	call	prtstr		; print it
	ret			; and return
;
prtcom1:
	ld	de,(comcfg)	; load config to DE
;
	; print baud rate
	push	de		; save it
	ld	a,d		; baud rate is in D
	and	$1F		; ... bits 4-0
	ld	l,a		; move to L
	ld	h,0		; setup H for decode routine
	ld	de,75		; set DE to baud rate decode constant
	call	decode		; decode baud rate, DE:HL := baud rate
	ld	bc,bcdtmp	; point to temp bcd buffer
	call	bin2bcd		; convert baud to BCD
	call	prtbcd		; and print in decimal
	pop	de		; restore line characteristics
;
	; print parity
	ld	a,','		; A := comma
	call	prtchr		; ... print it
	ld	a,e		; E has parity config
	rrca			; isolate bits 5-3
	rrca			; ...
	rrca			; ...
	and	$07		; ...
	ld	hl,parmap	; HL := start of parity char table
	call	addhl		; index into table
	ld	a,(hl)		; get resulting parity char
	call	prtchr		; and print
;
	; print data bits
	ld	a,','		; A := comma
	call	prtchr		; ... print it
	ld	a,e		; E has data bits config
	and	$03		; isloate bits 1-0
	add	A,'5'		; convert to printable char
	call	prtchr		; and print it
;
	; print stop bits
	ld	a,','		; A := comma
	call	prtchr		; ... print it
	ld	a,e		; E has stop bits config
	rrca			; isolate bit 2
	rrca			; ...
	and	$01		; ...
	add	A,'1'		; convert to printable char
	call	prtchr		; and print it
;
	ret
;
; Load serial device info for specific unit
;
ldcom:
	ld	a,(unamod)	; get UNA flag
	or	a		; set flags
	jr	nz,ldcomu	; go to UNA variant
;
	; get device type info
	ld	a,(unit)	; get unit
	ld	b,bf_ciodevice	; BIOS device call
	ld	c,a		; ... and put in C
	rst	08		; call HBIOS, C := attributes
	ret	nz		; return on error
	ld	a,c		; attributes to A
	ld	(comatr),a	; save it
;
	; get serial port config
	ld	b,bf_cioquery	; BIOS serial device query
	ld	a,(unit)	; get device unit num
	ld	c,a		; ... and put in C
	rst	08		; call H/UBIOS, DE := line characteristics
	ret	nz		; abort on error
	ld	(comcfg),de	; save config
;
	xor	a		; success
	ret
;
ldcomu:	; UNA variant
	xor	a		; assume attribtues zero
	ld	(comatr),a	; save it
	; get device info
	ld	a,(unit)	; get unit
	ld	b,a		; put unit in B
	ld	c,$18		; UNA Get line/driver info func
	rst	08		; call H/UBIOS, DE := line characteristics
	ld	a,c		
	or	a
	jr	z,ldcomu1
	cp	$43		; $43 is OK for now (tell John about this)
	jr	z,ldcomu1
	ret			; return w/ NZ indicating error
;
ldcomu1:
	ld	(comcfg),de	; save config
;
	xor	a		; success
	ret
	
;
; Handle special options
;
option:
;
	inc	ix		; next char
	ld	a,(ix)		; get it
	cp	'?'		; is it a '?' as expected?
	jp	z,usage		; yes, display usage
;	cp	'L'		; is it a 'L', display device list?
;	jp	z,devlist	; yes, display device list
	jp	errprm		; anything else is an error
;
; Display usage
;
usage:
;
	call	crlf		; formatting
	ld	de,msgban1	; point to version message part 1
	call	prtstr		; print it
	ld	a,(unamod)	; get UNA flag
	or	a		; set flags
	ld	de,msghb	; point to HBIOS mode message
	call	z,prtstr	; if not UNA, say so
	ld	de,msgub	; point to UBIOS mode message
	call	nz,prtstr	; if UNA, say so
	call	crlf		; formatting
	ld	de,msgban2	; point to version message part 2
	call	prtstr		; print it
	call	crlf2		; blank line
	ld	de,msguse	; point to usage message
	call	prtstr		; print it
	or	$FF		; signal no action performed
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
; print the hex dword value in de:hl
;
prthex32:
	push	bc
	push	de
	pop	bc
	call	prthexword
	push	hl
	pop	bc
	call	prthexword
	pop	bc
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
	ld	a,(ix)		; load next character
	or	a		; string ends with a null
	ret	z		; if null, return pointing to null
	cp	' '		; check for blank
	ret	nz		; return if not blank
	inc	ix		; if blank, increment character pointer
	jr	nonblank	; and loop
;
; Get alpha chars and save in tmpstr
; Length of string returned in A
;
getalpha:
;
	ld	hl,tmpstr	; location to save chars
	ld	b,8		; length counter (tmpstr max chars)
	ld	c,0		; init character counter
;
getalpha1:
	ld	a,(ix)		; get active char
	call	ucase		; lower case -> uppper case, if needed
	cp	'A'		; check for start of alpha range
	jr	c,getalpha2	; not alpha, get out
	cp	'Z' + 1		; check for end of alpha range
	jr	nc,getalpha2	; not alpha, get out
	; handle alpha char
	ld	(hl),a		; save it
	inc	c		; bump char count
	inc	hl		; inc string pointer
	inc	ix		; increment buffer ptr
	djnz	getalpha1	; if space, loop for more chars
;
getalpha2:	; non-alpha, clean up and return
	ld	(hl),0		; terminate string
	ld	a,c		; string length to A
	or	a		; set flags
	ret			; and return
;
; Get numeric chars and convert to number returned in A
; Carry flag set on overflow
;
getnum:
	ld	c,0		; C is working register
getnum1:
	ld	a,(ix)		; get the active char
	cp	'0'		; compare to ascii '0'
	jr	c,getnum2	; abort if below
	cp	'9' + 1		; compare to ascii '9'
	jr	nc,getnum2	; abort if above
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
	ld	a,(ix)		; get new digit
	sub	'0'		; make binary
	add	a,c		; add in working value
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
;
	inc	ix		; bump to next char
	jr	getnum1		; loop
;
getnum2:	; return result
	ld	a,c		; return result in A
	or	a		; with flags set, CF is cleared
	ret
;
; Get numeric chars and convert to 32-bit number returned in DE:HL
; Carry flag set on overflow
;
getnum32:
	ld	de,0		; Initialize DE:HL
	ld	hl,0		; ... to zero
getnum32a:
	ld	a,(ix)		; get the active char
	cp	'0'		; compare to ascii '0'
	jr	c,getnum32c	; abort if below
	cp	'9' + 1		; compare to ascii '9'
	jr	nc,getnum32c	; abort if above
;
	; valid digit, multiply DE:HL by 10
	; X * 10 = (((x * 2 * 2) + x)) * 2
	push	de
	push	hl
;	
	call	getnum32e	; DE:HL *= 2
	jr	c,getnum32d	; if overflow, ret w/ CF & stack pop
;	
	call	getnum32e	; DE:HL *= 2
	jr	c,getnum32d	; if overflow, ret w/ CF & stack pop
;
	pop	bc		; DE:HL += X
	add	hl,bc
	ex	de,hl
	pop	bc
	adc	hl,bc
	ex	de,hl
	ret	c		; if overflow, ret w/ CF
;	
	call	getnum32e	; DE:HL *= 2
	ret	c		; if overflow, ret w/ CF
;
	; now add in new digit
	ld	a,(ix)		; get the active char
	sub	'0'		; make it binary
	add	a,l		; add to L, CF updated
	ld	l,a		; back to L
	jr	nc,getnum32b	; if no carry, done
	inc	h		; otherwise, bump H
	jr	nz,getnum32b	; if no overflow, done
	inc	e		; otherwise, bump E
	jr	nz,getnum32b	; if no overflow, done
	inc	d		; otherwise, bump D
	jr	nz,getnum32b	; if no overflow, done
	scf			; set carry flag to indicate overflow
	ret			; and return
;
getnum32b:
	inc	ix		; bump to next char
	jr	getnum32a	; loop
;
getnum32c:
	; successful completion
	xor	a		; clear flags
	ret			; and return
;
getnum32d:
	; special overflow exit with stack fixup
	pop	hl		; burn 2
	pop	hl		; ... stack entries
	ret			; and return
;
getnum32e:
	; DE:HL := DE:HL * 2
	sla	l
	rl	h
	rl	e
	rl	d
	ret
;
; Compare null terminated strings at HL & DE
; If equal return with Z set, else NZ
;
strcmp:
	ld	a,(de)		; get current source char
	cp	(hl)		; compare to current dest char
	ret	nz		; compare failed, return with NZ
	or	a		; set flags
	ret	z		; end of string, match, return with Z set
	inc	de		; point to next char in source
	inc	hl		; point to next char in dest
	jr	strcmp		; loop till done
;
; Convert character in A to uppercase
;
ucase:
	cp	'a'		; if below 'a'
	ret	c		; ... do nothing and return
	cp	'z' + 1		; if above 'z'
	ret	nc		; ... do nothing and return
	res	5,a		; clear bit 5 to make lower case -> upper case
	ret			; and return
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
; Integer divide DE:HL by C
; result in DE:HL, remainder in A
; clobbers F, B
;
div32x8:
	xor	a
	ld	b,32
div32x8a:
  	add	hl,hl
	rl	e
	rl	d
	rla
	cp	c
	jr	c,div32x8b
	sub	c
	inc	l
div32x8b:
  	djnz	div32x8a
	ret
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
errinv:	; invalid HBIOS, signature not found
	ld	de,msginv
	jr	err
;
errver:	; unsupported HBIOS version
	ld	de,msgver
	jr	err
;
errdev:	; invalid device name
	ld	de,msgdev
	jr	err
;
errnum:	; invalid number parsed, overflow
	ld	de,msgnum
	jr	err
;
errunt:	; Invalid device unit specified
	ld	de,msgunt
	jr	err
;
errcfg:	; Invalid device configuration specified
	ld	de,msgcfg
	jr	err
;
err:	; print error string and return error signal
	call	crlf2		; print newline
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
; Utility modules
;===============================================================================
;
#include "encode.asm"
#include "decode.asm"
#include "bcd.asm"
;
;===============================================================================
; Storage Section
;===============================================================================
;
;
bioloc	.dw	0		; CBIOS starting address
unit	.db	0		; source unit
;
unamod	.db	0		; $FF indicates UNA UBIOS active
;
tmpstr	.fill	9,0		; temporary string of up to 8 chars, zero term
bcdtmp	.fill	5,0		; temporary bcd number storage
;
comcnt	.db	0		; count of com ports
comatr	.db	0		; com port attributes
comcfg	.dw	0		; com port configuration
;
parmap	.db	"NONENMNS"	; parity character lookup table
;
pflag	.db	0		; $FF indicates prompt option set
;
strcom	.db	"COM",0		; serial device name string
strterm	.db	"VDU",0		; terminal device string
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Messages
;
indent	.db	"   ",0
msgban1	.db	"MODE v1.2, 24-Jul-2018",0
msghb	.db	" [HBIOS]",0
msgub	.db	" [UBIOS]",0
msgban2	.db	"Copyright (C) 2017, Wayne Warthen, GNU GPL v3",0
msguse	.db	"Usage: MODE COM<n>: [<baud>[,<parity>[,<databits>[,<stopbits>]]]] [/P]",13,10
	.db	"  ex. MODE /?                (display version and usage)",13,10
	.db	"      MODE                   (display config of all serial ports)",13,10
	.db	"      MODE COM0:             (display serial unit 0 config)",13,10
	.db	"      MODE COM1: 9600,N,8,1  (set serial unit 1 config)",0
msgprm	.db	"Parameter error (MODE /? for usage)",0
msginv	.db	"Invalid BIOS (signature missing)",0
msgver	.db	"Unexpected HBIOS version",0
msgdev	.db	"Invalid device name",0
msgnum	.db	"Unit or slice number invalid",0
msgunt	.db	"Invalid device unit number specified",0
msgcfg	.db	"Invalid device configuration specified",0
msgpmt	.db	"Prepare line then press <return>",0
;
	.end
