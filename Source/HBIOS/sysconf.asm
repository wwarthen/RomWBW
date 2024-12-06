;
;=======================================================================
; HBIOS System Configuration via NVRAM
; ALLOWS CONFIG OF NVR TO SET OPTIONS FOR HBIOS CONFIGURATION
;=======================================================================
;
; Simple utility that sets NVR Attributes that affect HBIOS
; and RomWBW Operation. Write to RTC NVRAM to store config
; is reliant on HBIOS
;
; NOTE: This program is built as both a CP/M COM and Rom WBW Applicaton
;
; ROM APPLICATION THAT IS AUTOMATICALLY INCLUDED IN THE ROMWBW ROM.
; IT IS INVOKED FROM THE BOOT LOADER USING THE 'W' OPTION. (See RomLDR)
;
;	Author:  Mark Pruden
;
; BASED ON USEROM.ASM
; THANKS AND CREDIT TO MARTIN R. FOR PROVIDING THIS APPLICATION!
; Also Based on The Tasty Basic Configuration
; Utilitity function were also copied from RomLdr, Assign.
;
#include "../ver.inc"
#include "hbios.inc"
;
;=======================================================================
;
#ifdef CPM
#define PLATFORM "CP/M"
NVR_LOC		.equ	0100h
#endif
;
#ifdef ROMWBW
;
#define PLATFORM "ROMWBW"
#include "layout.inc"
#endif
;
;=======================================================================
;
cmdmax		.EQU	$20		; Max cmd input length
stksiz		.EQU	$40		; Working stack size
restart		.EQU	$0000		; CP/M restart vector
bdos		.EQU	$0005		; BDOS invocation vector
ident		.EQU	$FFFE		; loc of RomWBW HBIOS ident ptr
;
ETX		.EQU	3		; CTRL-C
BEL		.EQU	7		; ASCII bell
BS		.EQU	8		; ASCII backspace
LF		.EQU	10
CR		.EQU	13
DEL		.EQU	127		; ASCII del/rubout
;
;=======================================================================
;
		.ORG	NVR_LOC
;
#ifdef ROMWBW
	; PLACE STACK AT THE TOP OF AVAILABLE RAM (JUST BELOW THE HBIOS PROXY).
	LD	SP,HBX_LOC
#endif
#ifdef CPM
	; setup stack (save old value)
	ld	(stksav),sp		; save stack
	ld	sp,stack		; set new stack
	; initialization
	call	init			; initialize
	jr	nz,exit			; abort if init fails
#endif
;
	call	main			; do the real work
;
exit:
	; clean up and return to command processor
	; call	crlf			; formatting
;
#ifdef ROMWBW
	LD	B,BF_SYSRESET		; SYSTEM RESTART
	LD	C,BF_SYSRES_WARM	; WARM START
	RST	08			; CALL HBIOS (DOES NOT RETURN)
#endif
#ifdef CPM
;
	ld	sp,(stksav)		; restore stack
	jp	restart			; return to CP/M via restart
;
;=======================================================================
; CPM Specific Init
;=======================================================================
;
init:
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
	jp	err_una		; UNA not supported
;
initwbw:
	; get location of config data and verify integrity
	ld	hl,(ident)	; HL := adr or RomWBW HBIOS ident
	ld	a,(hl)		; get first byte of RomWBW marker
	cp	'W'		; match?
	jp	nz,err_inv	; abort with invalid config block
	inc	hl		; next byte (marker byte 2)
	ld	a,(hl)		; load it
	cp	~'W'		; match?
	jp	nz,err_inv	; abort with invalid config block
	inc	hl		; next byte (major/minor version)
	ld	a,(hl)		; load it
	cp	rmj << 4 | rmn	; match?
	jp	nz,err_ver	; abort with invalid os version
;
initz:
	; initialization complete
	xor	a		; signal success
	ret			; return
;
err_una:
	ld	de,str_err_una
	jp	err_ret
err_inv:
	ld	de,str_err_inv
	jp	err_ret
err_ver:
	ld	de,str_err_ver
	jp	err_ret
;
str_err_una		.db	"  ERROR: UNA not supported by application",0
str_err_inv		.db	"  ERROR: Invalid BIOS (signature missing)",0
str_err_ver		.db	"  ERROR: Unexpected HBIOS version",0
;
#endif
;
;=======================================================================
; Main Program and Loop
;
; TODO Potentially turn this into CP/M command line driven app.
; TODO Ie it just processes a single command (if provided) by CPM.
;=======================================================================
;
main:
	call	prtcrlf
	ld	de,str_banner		; banner
	call	prtstr
;
	CALL	PRT_STATUS		; PRINT STATUS
	RET	NZ			; status failed complely, SO EXIT
	ld	de,MSG_MENU		; Print the Main Menu
	CALL	prtstr
;
mainloop:
	ld	DE,MSG_PROMPT
	CALL	prtstr			; Print a prompt >
	CALL	rdln			; READ INPUT
;
	; accept and pare input
	ld	de,cmdbuf		; point to start of buf
	call	skipws			; skip whitespace
	JR	z,mainloop		; if empty line, just loop back
	call	upcase
;
	; MENU OPTIONS (documented)
	cp	'H'
	JR	Z,helpandloop		; get help
	cp	'P'
	JR	Z,statusandloop		; print status
	cp	'Q'
	ret	Z			; finished
	cp	'R'
	JR	Z,resetandloop		; reset NVRAM
	cp	'S'
	JR	Z,setvalueandloop	; todo set Value
;
	; COMMON ALTERNATES (undocumented)
	cp	'L'
	JR	Z,statusandloop		; print status
	cp	'X'
	ret	Z			; finished
	cp	'Z'
	ret	Z			; finished
	cp	'?'
	JR	Z,helpandloop		; get help
	cp	'/'
	JR	Z,helpandloop		; get help
;
	; Main Loop
	JR	mainloop		; Noting Valid was entered
;
;=======================================================================
; General Functional Routines Called By Menu Options
;=======================================================================
;
; Print Help Menu
;
helpandloop:				; HELP MENU
	CALL	findskipws		; skip over WS to first char
	JR	z,printmainhelp		; if empty line, print main help
	call	upcase
;
	; the folloiwng is just testing a single charater
	cp	'A'			; Auto Boot help menu
	JP	Z,HELP_AB
	cp	'B'			; Boot Options help menu
	JP	Z,HELP_BO
;
printmainhelp:
	ld	de,MSG_MENU		; nothing found Print the Main Menu
printhelp:
	CALL	prtstr			; print the selected help message
	JR	mainloop
;
; -----------
; RESET NVRAM
;
resetandloop:				; RESET NVRAM
	LD	BC,BC_SYSSET_SWITCH
	LD	D,$FF			; RESET SWITCH
	RST	08			; Reset NV RAM
	JR	statusandloop		; now reprint the status
;
; -------------
; Set NV Ram Value
;
setvalueandloop:
	CALL	findskipws		; skip over WS to first char
	JR	z,setvalueerror		; if empty line, print ?
	call	upcase
;
	; the folloiwng is just testing a single charater
	cp	'A'			; Auto Boot help menu
	JP	Z,SET_AB
	cp	'B'			; Boot Options help menu
	JP	Z,SET_BO
;
setvalueerror:
	ld	de,MSG_QUESTION		; nothing found Print the Main Menu
	CALL	prtstr			; print the selected help message
	JR	mainloop
;
setvaluesave:
	LD	BC,BC_SYSSET_SWITCH	; SET THE VALUE
	RST	08			; HL is savd
	; JR	statusandloop		; finish display status (FALL THROUGH)
;
; ------------
; Print Status
;
statusandloop:
	CALL	PRT_STATUS		; print status
	JR	mainloop
;
; Call with Return to print status
;
PRT_STATUS:
	LD	de,MSG_STAT		; print status open mesg
	CALL	prtstr
	LD	BC,BC_SYSGET_SWITCH
	LD	D,$FF			; check for existence of switches
	RST	08
	JR	NZ,STAT_NOTFOUND	; error means switchs are not enabled
;
; print invdividual stats, on all per switch
;
	CALL	STAT_BO
	CALL	STAT_AB
;
; end individual stats
;
	CALL	prtcrlf
	XOR	A			; success
	RET
;
; Error status handling
;
STAT_NOTFOUND:
	CP	0			; if status is ZERO then this is fatal
	JR	Z,STAT_NOTFOUND1
	LD	de,MSG_NOTF
	CALL	prtstr
	XOR	A			; success
	RET
STAT_NOTFOUND1:
	LD	de,MSG_NONVR		; print failure status
	CALL	prtstr
	OR	$FF			; failure
	RET
;
; ======================================================================
; Specific Switches Below
; ======================================================================
;
; BOOT OPTIONS
;   Byte 1: (L)
;     Bit 7-0 DISK BOOT SLice Number to Boot -> default = 0
;     Bit 7-0 ROM BOOT (alpha character) Application to boot -> default = 0 translates to "H"
;   Byte 2: (H)
;     Bit 7 - DISK/ROM - Disk or Rom Boot -> Default=ROM (AUTO_CMD is Numeric/Alpha)
;     Bit 6-0 - DISK BOOT Disk Unit to Boot (0-127) -> default = 0
;
; PRINT CURRENT SWITCH VALUE
;
STAT_BO:
	LD	BC,BC_SYSGET_SWITCH
	LD	D,NVSW_BOOTOPTS
	RST	08			; Should return auto Boot in HL
	RET	NZ			; return if error
	LD	de,MSG_BO
	CALL	prtstr
	LD	A,H			; Byte 2
	AND	BOPTS_ROM		; DISK/ROM
	JR	NZ,STAT_BO_ROM		; is it ROM
STAT_BO_DISK:
	LD	de,MSG_DISK		; disk
	CALL	prtstr
	LD	A,H			; Byte 2
	AND	BOPTS_UNIT		; Unit
	CALL	prtdecb
	LD	de,MSG_DISK2		; Slice
	CALL	prtstr
	LD	A,L			; SLICE
	CALL	prtdecb
	LD	de,MSG_DISK3		; close bracket
	CALL	prtstr
	RET
STAT_BO_ROM:
	LD	de,MSG_ROM		; ROM
	CALL	prtstr
	LD	A,L			; ROM APP
	call	prtchr
	LD	de,MSG_ROM2		; close bracket
	CALL	prtstr
	RET
;
; SET SWITCH VALUE
;
SET_BO:
	CALL	findskipws		; skip over WS to first char
	JR	z,SET_BO_ERR		; if empty line, print main help
	call	upcase
	cp	'R'			; ROM
	JR	Z,SET_BO_ROM
	cp	'D'			; DISK
	JR	Z,SET_BO_DISK
	JR	SET_BO_ERR
SET_BO_ROM:
	CALL	findskipcomma
	CALL	skipws
	JR	z,SET_BO_ERR		; if empty line, print main help
	LD	L,A			; LOW BYTE ; next CHAR is the ROM App Name
	LD	A,BOPTS_ROM
	LD	H,A			; HIGH BYTE, has constant. ABOOT_ROM = $80
	JR	SET_BO_SAVE		; SAVE
SET_BO_DISK:
	CALL	findskipcomma
	CALL	skipws
	JR	z,SET_BO_ERR		; if empty line, print main help
	CALL	getnum			; next CHAR is the DISK UNIT
	JR	C,SET_BO_ERR		; overflow
	BIT	7,A			; is > 127
	JR	NZ, SET_BO_ERR
	LD	H,A			; HIGH BYTE, has disk unit < $80
	CALL	findskipcomma
	CALL	skipws
	JR	z,SET_BO_ERR		; if empty line, print main help
	CALL	getnum			; next CHAR is the SLICE
	JR	C,SET_BO_ERR		; overflow
	LD	L,A			; LOW BYTE, has the slice number
	;JR	SET_BO_SAVE		; SAVE - Fall Through
SET_BO_SAVE:
	LD	D,NVSW_BOOTOPTS		; BOOT OPTIONS
	JP	setvaluesave		; SAVE THE VALUE
SET_BO_ERR:
	JP	setvalueerror		; ERROR. Added this so can use JR above
;
; PRINT HELP TEST FOR SWITCH
;
HELP_BO:
	ld	de,MSG_BO_H
	JP	printhelp
;
MSG_BO		.DB	CR,LF, "  [BO] / Boot Options: ",0
MSG_DISK	.DB	"Disk (Unit = ",0
MSG_DISK2	.DB	", Slice = ",0
MSG_DISK3	.DB	")",0
MSG_ROM		.DB	"ROM (App = \"",0
MSG_ROM2	.DB	"\")",0
;
MSG_BO_H	.DB	"\r\nBoot Options - Disk or Rom App (BO):\r\n"
		.DB	"  BO [R|D],[{romapp}|{unit},{slice}]\r\n"
		.DB	"    e.g. S BO D,2,14 ; Disk Boot, unit 2, slice 14\r\n"
		.DB	"         S BO R,M    ; Rom Application 'M'onitor\r\n"
		.DB	"  Note: Disk: Unit (0-127); Slice (0-255)\r\n",0
;
;=======================================================================
;
; AUTO BOOT CONFIG
;   Byte 0: (L)
;     Bit 7-6 - Reserved
;     Bit 5 - AUTO BOOT Auto boot, default=false (i.e. BOOT_TIMEOUT != -1)
;     Bit 4 - Reserved
;     Bit 3-0 - BOOT_TIMEOUT in seconds (0-15) 0=immediate -> default=3
;
; PRINT CURRENT SWITCH VALUE
;
STAT_AB:
	LD	BC,BC_SYSGET_SWITCH
	LD	D,NVSW_AUTOBOOT
	RST	08			; Should return auto Boot in HL
	RET	NZ			; return if error
	LD	de,MSG_AUTOB
	CALL	prtstr
	LD	A,L			; Byte 1
	LD	de,MSG_DISABLED
	AND	ABOOT_AUTO		; enabled
	JR	Z, STAT_AB1		; disabled
	LD	de,MSG_ENABLED		; enabled
	CALL	prtstr
	LD	A,L			; Byte 1
	AND	ABOOT_TIMEOUT		; timeout
	CALL	prtdecb			; print timeout
	LD	de,MSG_ENABLED2		; and closing bracket
STAT_AB1:
	CALL	prtstr
	RET
;
; SET SWITCH VALUE
;
SET_AB:
	CALL	findskipws		; skip over WS to first char
	JR	z,SET_AB_ERR		; if empty line, print main help
	call	upcase
	cp	'E'			; Enabled
	JR	Z,SET_AB_ENAB
	cp	'D'			; Disabled
	JR	Z,SET_AB_DISAB
	JR	SET_AB_ERR
SET_AB_ENAB:
	CALL	findskipcomma
	CALL	skipws
	JR	z,SET_AB_ERR		; if empty line, print main help
	CALL	getnum			; next NUMBER is the timout
	JR	C,SET_AB_ERR		; overflow
	AND	$F0			; mask just the upper bits
	JR	NZ,SET_AB_ERR		; if any upper bit set > 15 then Error
	LD	A,C			; NOTE getnum also returns Value in C
	OR	ABOOT_AUTO		; set the enabled bit for auto boot
	LD	L,A			; LOW BYTE, has the timeout from getNum
	JR	SET_AB_SAVE		; SAVE
SET_AB_DISAB:
	LD	L,0
	;JR	SET_AB_SAVE		; SAVE - Fall Through
SET_AB_SAVE:
	LD	D,NVSW_AUTOBOOT		; AUTO BOOT CONFIG
	JP	setvaluesave		; SAVE THE VALUE
SET_AB_ERR:
	JP	setvalueerror		; ERROR. Added this so can use JR above
;
; PRINT HELP TEST FOR SWITCH
;
HELP_AB:
	ld	de,MSG_AB_H
	JP	printhelp
;
MSG_AUTOB:	.DB	CR,LF,"  [AB] / Auto Boot: ",0
MSG_ENABLED:	.DB	"Enabled (Timeout = ",0
MSG_ENABLED2:	.DB	")",0
MSG_DISABLED:	.DB	"Disabled",0
;
MSG_AB_H	.DB	"\r\nAutomatic Boot (AB):\r\n"
		.DB	"  AB <D|E>[,{timeout}]\r\n"
		.DB	"    e.g. S AB E,3 ; enabled (show menu) with 3 second timout before boot\r\n"
		.DB	"         S AB E,0 ; enabled with immediate effect, bypass menu\r\n"
		.DB	"         S AB D   ; disabled, just display menu\r\n",0
;
;=======================================================================
; Error Handlers
;=======================================================================
;
err_unknown:
	ld	de,str_err_unknown
	jr	err_ret
;
err_ret:
	call	prtcrlf2
	call	prtstr
	or	$FF			; signal error
	ret
;
;=======================================================================
; GENERAL CONSTANTS
;=======================================================================
;
str_banner	.db	"\r\n"
		.db	"RomWBW System Config Utility, Version 1.0 Nov-2024\r\n",0
;
MSG_MENU	.DB	"\r\n"
		.DB	"Commands:\r\n"
		.DB	"  (P)rint - Display Current settings\r\n"
		.DB	"  (S)et {SW} {val}[,{val}[,{val}]]- Set a switch value(s)\r\n"
		.DB	"  (R)eset - Init NVRAM to Defaults\r\n"
		.DB	"  (H)elp [{SW}] - This help menu, or help on a switch\r\n"
		.DB	"  (Q)uit - Quit\r\n"
		.DB	0
MSG_PROMPT:	.DB	"\r\n"
		.DB	"$", 0
MSG_STAT:	.DB	"\r\nCurrent Configuration: ",0
MSG_NOTF:	.DB	"Config Not Found.\r\n",0
MSG_NONVR:	.DB	"NVRAM Not Found. Exiting.\r\n",0
MSG_QUESTION	.DB	"\r\n?\r\n",0
;
;MSG_PAK:	.DB	"\r\nPress Any Key ...",0
;
str_err_unknown	.db	"\r\nUnknown Error\r\n",0
;
;=======================================================================
; Utility Routines
;=======================================================================
;
; Print a dot character without destroying any registers
;
prtdot:
	; shortcut to print a dot preserving all regs
	push	af		; save af
	ld	a,'.'		; load dot char
	call	prtchr		; print it
	pop	af		; restore af
	ret			; done
;
; Print Cr LF
;
prtcrlf2:
	call	prtcrlf		; two of them
prtcrlf:
	; shortcut to print a dot preserving all regs
	push	af		; save af
	ld	a,13
	call	prtchr		; print it
	ld	a,10
	call	prtchr		; print it
	pop	af		; restore af
	ret			; done
;
; Print a zero terminated string at (de) without destroying any registers
;
prtstr:
	push	af
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
	pop	af
	ret
;
; Print a hex value prefix "0x"
;
prthexpre:
	push	af
	ld	a,'0'
	call	prtchr
	ld	a,'x'
	call	prtchr
	pop	af
	ret
;
; Print the value in A in hex without destroying any registers
;
;prthex:
;	call	prthexpre
;prthex1:
;	push	af		; save AF
;	push	de		; save DE
;	call	hexascii	; convert value in A to hex chars in DE
;	ld	a,d		; get the high order hex char
;	call	prtchr		; print it
;	ld	a,e		; get the low order hex char
;	call	prtchr		; print it
;	pop	de		; restore DE
;	pop	af		; restore AF
;	ret			; done
;
; print the hex word value in hl
;
;prthexword:
;	call	prthexpre
;prthexword1:
;	push	af
;	ld	a,h
;	call	prthex1
;	ld	a,l
;	call	prthex1
;	pop	af
;	ret
;
; print the hex dword value in de:hl
;
;prthex32:
;	call	prthexpre
;	push	bc
;	push	de
;	pop	bc
;	call	prthexword1
;	push	hl
;	pop	bc
;	call	prthexword1
;	pop	bc
;	ret
;
; Convert binary value in A to ascii hex characters in DE
;
;hexascii:
;	ld	d,a		; save A in D
;	call	hexconv		; convert low nibble of A to hex
;	ld	e,a		; save it in E
;	ld	a,d		; get original value back
;	rlca			; rotate high order nibble to low bits
;	rlca
;	rlca
;	rlca
;	call	hexconv		; convert nibble
;	ld	d,a		; save it in D
;	ret			; done
;
; Convert low nibble of A to ascii hex
;
;hexconv:
;	and	$0F	     	; low nibble only
;	add	a,$90
;	daa
;	adc	a,$40
;	daa
;	ret
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
; Print value of HL as thousandths, ie. 0.000
;
;prtd3m:
;	push	bc
;	push	de
;	push	hl
;	ld	e,'0'
;	ld	bc,-10000
;	call	prtd3m1
;	ld	e,0
;	ld	bc,-1000
;	call	prtd3m1
;	call	prtdot
;	ld	bc,-100
;	call	prtd3m1
;	ld	c,-10
;	call	prtd3m1
;	ld	c,-1
;	call	prtd3m1
;	pop	hl
;	pop	de
;	pop	bc
;	ret
;prtd3m1:
;	ld	a,'0' - 1
;prtd3m2:
;	inc	a
;	add	hl,bc
;	jr	c,prtd3m2
;	sbc	hl,bc
;	cp	e
;	jr	z,prtd3m3
;	ld	e,0
;	call	prtchr
;prtd3m3:
;	ret
;
; -------------------------------------------------------
;
; Get the next non-blank character from (HL).
;
;nonblank:
;	ld	a,(ix)		; load next character
;	or	a		; string ends with a null
;	ret	z		; if null, return pointing to null
;	cp	' '		; check for blank
;	ret	nz		; return if not blank
;	inc	ix		; if blank, increment character pointer
;	jr	nonblank	; and loop
;
; Get alpha chars and save in tmpstr
; Length of string returned in A
;
;getalpha:
;
;	ld	hl,tmpstr	; location to save chars
;	ld	b,8		; length counter (tmpstr max chars)
;	ld	c,0		; init character counter
;
;getalpha1:
;	ld	a,(ix)		; get active char
;	call	upcase		; lower case -> uppper case, if needed
;	cp	'A'		; check for start of alpha range
;	jr	c,getalpha2	; not alpha, get out
;	cp	'Z' + 1		; check for end of alpha range
;	jr	nc,getalpha2	; not alpha, get out
;	; handle alpha char
;	ld	(hl),a		; save it
;	inc	c		; bump char count
;	inc	hl		; inc string pointer
;	inc	ix		; increment buffer ptr
;	djnz	getalpha1	; if space, loop for more chars
;
;getalpha2:	; non-alpha, clean up and return
;	ld	(hl),0		; terminate string
;	ld	a,c		; string length to A
;	or	a		; set flags
;	ret			; and return
;
;tmpstr	.fill	9,0		; temp string (8 chars, 0 term)
;
; Determine if byte in A is a numeric '0'-'9'
; Return with CF clear if it is numeric
;
isnum:
	cp	'0'
	jr	c,isnum1	; too low
	cp	'9' + 1
	jr	nc,isnum1	; too high
	or	a		; clear CF
	ret
isnum1:
	or	a		; clear CF
	ccf			; set CF
	ret
;
; Get numeric chars at DE and convert to number returned in A
; Carry flag set on overflow
;
getnum:
	ld	c,0		; C is working register
getnum1:
	ld	a,(de)		; get the active char
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
	ld	a,(de)		; get new digit
	sub	'0'		; make binary
	add	a,c		; add in working value
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
;
	inc	de		; bump to next char
	jr	getnum1		; loop
;
getnum2:	; return result
	ld	a,c		; return result in A
	or	a		; with flags set, CF is cleared
	ret
;
; Find (AND SKIP) whitespace at buffer adr in DE, returns with first
; NON whitespace character in A.
;
findskipws:
	ld	a,(de)		; get next char
	or	a		; check for eol
	ret	z		; done if so
	cp	' '		; blank?
	JR	z,skipws	; nope, done
	inc	de		; bump buffer pointer
	jr	findskipws	; and loop
;
; Skip whitespace at buffer adr in DE, returns with first
; non-whitespace character in A.
;
skipws:
	ld	a,(de)		; get next char
	or	a		; check for eol
	ret	z		; done if so
	cp	' '		; blank?
	ret	nz		; nope, done
	inc	de		; bump buffer pointer
	jr	skipws		; and loop
;
; Find (AND SKIP) "," at buffer adr in DE, returns with first
; NON "," character in A.
;
findskipcomma:
	ld	a,(de)		; get next char
	or	a		; check for eol
	ret	z		; done if so
	cp	','		; blank?
	JR	z,skipcomma	; nope, done
	inc	de		; bump buffer pointer
	jr	findskipcomma	; and loop
;
; Skip "," at buffer adr in DE, returns with first
; non-comma character in A.
;
skipcomma:
	ld	a,(de)		; get next char
	or	a		; check for eol
	ret	z		; done if so
	cp	','		; blank?
	ret	nz		; nope, done
	inc	de		; bump buffer pointer
	jr	skipcomma	; and loop
;
; Uppercase character in A
;
upcase:
	cp	'a'			; below 'a'?
	ret	c			; if so, nothing to do
	cp	'z'+1			; above 'z'?
	ret	nc			; if so, nothing to do
	and	~$20			; convert character to lower
	ret				; done
;
; -----------------------------
; Add hl,a
;   A register is destroyed!
;
;addhla:
;	add	a,l
;	ld	l,a
;	ret	nc
;	inc	h
;	ret
;
;=======================================================================
; Read a string on the console
; (Code originally from RomLDR)
;
; Uses address $0080 in page zero for buffer
; Input is zero terminated
;
rdln:
	ld	de,cmdbuf		; init buffer address ptr
rdln_nxt:
 	call	CIN			; get a character
 	cp	BS			; backspace?
 	jr	z,rdln_bs		; handle it if so
 	cp	DEL			; del/rubout?
 	jr	z,rdln_bs		; handle as backspace
 	cp	CR			; return?
 	jr	z,rdln_cr		; handle it if so
;
 	; check for non-printing characters
 	cp	' '			; first printable is space char
 	jr	c,rdln_bel		; too low, beep and loop
 	cp	'~'+1			; last printable char
 	jr	nc,rdln_bel		; too high, beep and loop
;
 	; need to check for buffer overflow here!!!
 	ld	hl,cmdbuf+cmdmax	; max cmd length
 	or	a			; clear carry
 	sbc	hl,de			; test for max
 	jr	z,rdln_bel		; at max, beep and loop
;
 	; good to go, echo and store character
 	call	COUT			; echo character input
 	ld	(de),a			; save in buffer
 	inc	de			; inc buffer ptr
 	jr	rdln_nxt		; loop till done
;
rdln_bs:
 	ld	hl,cmdbuf		; start of buffer
 	or	a			; clear carry
 	sbc	hl,de			; subtract from cur buf ptr
 	jr	z,rdln_bel		; at buf start, just beep
 	;ld	hl,str_bs		; backspace sequence
	ld	a,BS
	call	COUT
	ld	a,' '
	call 	COUT
	ld	a,BS
	call	COUT
 	;call	prtstr			; send it
 	dec	de			; backup buffer pointer
 	jr	rdln_nxt		; and loop
;
rdln_bel:
 	ld	a,BEL			; Bell characters
 	call	COUT			; send it
 	jr	rdln_nxt		; and loop
;
rdln_cr:
 	xor	a			; null to A
 	ld	(de),a			; store terminator
 	ret
;
str_bs		.db	BS,' ',BS,0
;
;=======================================================================
; Basic Input Output (Specific to Target)
;=======================================================================
;
; Print character in A without destroying any registers
;
COUT:
prtchr:
	push	af
	push	bc		; save registers
	push	de
	push	hl
#ifdef ROMWBW
	LD	BC, BF_CIOOUT<<8 | CIO_CONSOLE
	LD	E,A
	RST	08
#endif
#ifdef CPM
	ld	e,a		; character to print in E
	ld	c,$02		; BDOS function to output a character
	call	bdos		; do it
#endif
	pop	hl		; restore registers
	pop	de
	pop	bc
	pop	af
	ret
;
; WAIT FOR A CHARACTER FROM THE CONSOLE DEVICE AND RETURN IT IN A
;
CIN:	PUSH	BC
	PUSH	DE
	PUSH	HL
#ifdef ROMWBW
	LD	BC, BF_CIOIN << 8 | CIO_CONSOLE
	RST	08
	LD	A,E
#endif
#ifdef CPM
	; todo CONVERT TO BDOS CALL
	LD	BC, BF_CIOIN << 8 | CIO_CONSOLE
	RST	08
	LD	A,E
#endif
	POP	HL
	POP	DE
	POP	BC
	RET
;
;=======================================================================
; General Working data
;=======================================================================
;
stksav		.dw	0		; stack pointer saved at start
;
cmdbuf:		.FILL	cmdmax,0	; cmd inut buffer
;
		.fill	stksiz,0	; stack
stack		.equ	$		; stack top
;
#ifdef ROMWBW
;
;=======================================================================
; IT IS CRITICAL THAT THE FINAL BINARY BE EXACTLY NVR_SIZ BYTES.
; THIS GENERATES FILLER AS NEEDED.  IT WILL ALSO FORCE AN ASSEMBLY
; ERROR IF THE SIZE EXCEEDS THE SPACE ALLOCATED.
;=======================================================================
;
SLACK	.EQU	(NVR_END - $)
;
#IF (SLACK < 0)
	.ECHO	"*** SYSCONF APP IS TOO BIG!!!\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#endif
;
	.FILL	SLACK,$00
	.ECHO	"SYSCONF space remaining: "
	.ECHO	SLACK
	.ECHO	" bytes.\n"
;
	.NOLIST
;
#endif
	.END
