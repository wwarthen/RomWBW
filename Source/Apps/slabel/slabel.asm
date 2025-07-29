;==============================================================================
; SLICE LABEL - Update Disk Labels
; Version  December-2024
;==============================================================================
;
; Author: Mark Pruden
;
; This is a SUPERSET of INVNTSLC.ASM -> Please See this program also when
; making changes, as code ( in routine prtslc: ) exists there also
;______________________________________________________________________________
;
; Usage:
;   SLABEL [unit.slice,label] [/?]
;     ex: SLABEL			Display current list of Labels
;     	  SLABEL unit.slice=label	Assign a disk Label to the Slice on Unit
;         SLABEL /?			Display version and usage
;
; Operation:
;   Print and Assign a Disk Label to a Hard Disk Slice.
;
; Technical:
;   On the third sector of "bootable" Disk Slice there is metadata used by RomWBW to know how
;   to boot the OS found on the slice. This includes a Label for the volume, which is printed
;   out by RomWBW during the boot process.
;   Note this label is not associated to any label the OS may assign to the volume.
;   See loader.asm in each of the O/S directories e.g. /src/CPM22 which describe these sectors
;
;   This ony works on slices which have existing media information in the third sector.
;   There is no capabiity to write this information on demand.
;
; known Issues:
;   - Listing the slabel for all slices can be time consuming, because of the use of the EXT_MEDIA
;     function call. This function reads the partition table (on each call) to assert (if valid)
;     the LBA location of the requested slice. Ideally we would only need to read the partition
;     table once (per device), and work out all the LBA's from this single read.
;     Note this doesnt omit the fact that the 3 rd sector of each slice wold need to be read regarless.
;     To slightly reduce some IO only slices < 64 are considered.
;   - Output formatting misaligned with storage units enumerated as greater than 9 (ie 2 digits)
;
; This code will only execute on a Z80 CPU (or derivitive)
; This code requirs the use of HBIOS
;
;______________________________________________________________________________
;
; Change Log:
;   2024-12-11 [MAP] Started - Reboot v1.0 used as the basis for this code
;   2024-12-14 [MAP] Initial 0.9 alpha with basic working functionality
;   2025-04-21 [MAP] Initial v1.0 release for distribution, fixing all issues
;   2025-07-12 [MR]  Minor tweak to partially tidy up output formatting
;______________________________________________________________________________
;
; Include Files
;
#include "../../ver.inc"		; to ensure it is the correct ver
#include "../../HBIOS/hbios.inc"
;
;===============================================================================
;
; General operational equates (should not requre adjustment)
;
stksiz		.equ	$40		; Working stack size
;
restart		.equ	$0000		; CP/M restart vector
bdos		.equ	$0005		; BDOS invocation vector
cmdbuf		.equ	$0081		; CPM command buffer
;
bf_sysreset	.equ	$F0		; restart system
bf_sysres_int	.equ	$00		; reset hbios internal
bf_sysres_warm	.equ	$01		; warm start (restart boot loader)
;
ident		.equ	$FFFE		; loc of RomWBW HBIOS ident ptr
;
sigbyte1	.equ	$A5		; 1st sig byte boot info sector (bb_sig)
sigbyte2	.equ	$5A		; 2nd sig byte boot info sector (bb_sig)
;
labelterm	.equ	'$'		; terminating charater for disk label
;
;===============================================================================
;
	.org	$0100			; standard CP/M TPA executable
;
	ld	(stksav),sp		; save stack
	ld	sp,stack		; set new stack
;
	ld	de,str_banner
	call	prtstr			; print the banner
;
	call	init			; initialize
	jr	nz,exit			; abort if init fails
;
	call	main			; do the real work
;
exit:
	call	crlf			; print terminating crlf
	ld	sp,(stksav)		; restore stack to prior state
	jp	restart			; return to CP/M via restart
;
;===============================================================================
; Initialisation
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
;===============================================================================
; Main Execution
;
main:
	call	initdiskio		; initi DiskIO routines (bank ID)
;
	ld	de,cmdbuf		; start of command input buffer
	call	skipws			; skip whitespace on cmd line
;
	ld	a,(de)			; get first non-ws char
	or	a			; test for terminator, no parms
	jr	z,prtslc		; if so, print details, and return
;
	call	isnum			; do we have a number?
	jp	z,setlabel		; if so, then we are setting Label.
;
	jp	usage			; otherwise print usage and return
	ret				; and exit
;
;===============================================================================
; Print Usage /? Information
;
usage:
	ld	de,str_usage	; display the cmd options for this utility
	call	prtstr
	;
	ret			; exit back out to CP/M CCP
;
;===============================================================================
; Print list of all slices
;
prtslc:
	ld	de,PRTSLC_HDR		; Header for list of Slices
	call	prtstr			; Print It
	;
	ld	bc,BC_SYSGET_DIOCNT	; FUNC: SYSTEM INFO GET DISK DRIVES
	rst	08			; E := UNIT COUNT
	;
	ld	b,e			; MOVE Disk CNT TO B FOR LOOP COUNT
	ld	c,0			; C WILL BE UNIT INDEX
prtslc1:
	ld	a,b			; loop counter
	or	a			; set flags
	ret	z			; IF no more drives, finished
	;
	ld	a,c			; unit index
	ld	(currunit),a		; store the unit number
	;
	push	bc			; save loop vars
	call	prtslc2			; for each disk Unit, print its details
	pop	bc			; restore loop variables
	;
	inc	c			; bump the unit number
	djnz	prtslc1			; main disk loop
	;
	ret				; loop has finished
;
;-------------------------------------------------------------------------------
; Print list of All Slices for a given Unit
;
prtslc2:
	; get the media infor
	ld	b,BF_DIOMEDIA		; get media information
	ld	e,1			; with media discovery
	rst	08			; do media discovery
	ret	nz			; an error
	;
	ld	a,MID_HD		; hard disk
	cp	e			; is it  hard disk
	ret	nz			; if not noting to do
	;
	; setup the loop
	ld	b,64			; arbitrary (?) number of slices to check.
					; NOTE: could be higher, but each slice check has disk IO
	ld	c,0			; starting at slice 0
;
prtslc2a:
	ld	a,c			; slice number
	ld	(currslice),a		; save slice number
	;
	push	bc			; save loop counter
	call	prtslc3			; print detals of the slice
	pop	bc			; restore loop counter
	ret	nz			; if error don't continue
	;
	inc	c			; next slice number
	djnz	prtslc2a		; loop if more slices
	;
	ret				; return from Slice Loop
;
;-------------------------------------------------------------------------------
; Print details of a Slice for a given Unit/Slice
;
prtslc3:
	; get the details of the device / slice
	ld	a,(currunit)
	ld	d,a			; unit
	ld	a,(currslice)
	ld	e,a			; slice
	ld	b,BF_EXTSLICE		; EXT function to check compute slice offset
	rst	08			; noting this call checks partition table.
	ret	NZ			; an error, for lots of reasons, e.g. Slice not valid
	;
	call	thirdsector		; point to the third sector of partition
	;
	call	diskread		; do the sector read
	ret	nz			; read error. exit the slice loop
	;
	; Check signature
	ld	bc,(bb_sig)		; get signature read
	ld	a,sigbyte1		; expected value of first byte
	cp	b			; compare
	jr	nz,prtslc5		; ignore missing signature and loop
	ld	a,sigbyte2		; expected value of second byte
	cp	c			; compare
	jr	nz,prtslc5		; ignore missing signature and loop
	;
        ; Print slice label string at HL, '$' terminated, 16 chars max
	ld	a,(currunit)
	call	prtdecb			; print unit number as decimal
	call 	pdot			; print a DOT
	ld	a, (currslice)		; fetch the current slice numeric
	call	prtdecb
;
;-------------------------------------------------------------------------------
; Added by MartinR, July 2025, to help neaten the output formatting.
; Note - this is not a complete fix and will still result in misaligned output
; where the unit number exceeds 9 (ie - uses 2 digits).
	cp	10			; is it less than 10?
	ld	a,' '
	jr	nc,jr01			; If not, then we don't need an extra space printed
	call	cout			; print the extra space	necessary
jr01:	call	cout			; print a space
	call	cout			; print a space
;-------------------------------------------------------------------------------
;
	ld	hl,bb_label		; point to label
	call	pvol			; print it
	call	crlf
	;
prtslc5:
	xor	a
	ret
;
;-------------------------------------------------------------------------------
; Print volume label string at HL, '$' terminated, 16 chars max
;
pvol:
	ld	b,16			; init max char downcounter
pvol1:
	ld	a,(hl)			; get next character
	cp	labelterm		; set flags based on terminator $
	inc	hl			; bump pointer regardless
	ret	z			; done if null
	call	cout			; display character
	djnz	pvol1			; loop till done
	ret				; hit max of 16 chars
;
;===============================================================================
; Set Label Information onto disk
;
setlabel:
	call	getnum			; parse a number
	jp	c,err_parm		; handle overflow error
	ld	(currunit),a		; save boot unit
	xor	a			; zero accum
	ld	(currslice),a		; save default slice
	call	skipws			; skip possible whitespace
	ld	a,(de)			; get separator char
	or	a			; test for terminator
	jp	z,err_parm		; if so, incomplete
	cp	'='			; otherwise, is ','?
	jr	z,setlabel4		; if so, skip the Slice parm
	cp	'.'			; otherwise, is '.'?
	jp	NZ,err_parm		; if not, format error
;
	inc	de			; bump past separator
	call	skipws			; skip possible whitespace
	call	isnum			; do we have a number?
	jp	nz,err_parm		; if not, format error
	call	getnum			; get number
	jp	c,err_parm		; handle overflow error
	ld	(currslice),a		; save boot slice
setlabel3:
	call	skipws			; skip possible whitespace
	ld	a,(de)			; get separator char
	or	a			; test for terminator
	jp	z,err_parm		; if so, then an error
	cp	'='			; otherwise, is ','?
	jp	nz,err_parm		; if not, format error
setlabel4:
	inc	de			; bump past separator
	call	skipws			; skip possible whitespace
	ld	(newlabel),de		; address of disk label after '='
	;
	ld	a,(currunit)		; passing boot unit
	ld	d,a
	ld	a,(currslice)		; and slice
	ld	e,a
	ld	b,BF_EXTSLICE		; HBIOS func: SLICE CALC - extended
	rst	08			; info for the Device, and Slice
;
	; Check errors from the Function
	cp	ERR_NOUNIT		; compare to no unit error
	jp	z,err_nodisk		; handle no disk err
	cp	ERR_NOMEDIA		; no media in the device
	jp	z,err_nomedia		; handle the error
	cp	ERR_RANGE		; slice is invalid
	jp	z,err_badslice		; bad slice, handle err
	or	a			; any other error
	jp	nz,err_diskio		; handle as general IO error
	;
	call	thirdsector		; point to the third sector of partition
	;
	call	diskread		; read the sector
	jp	nz,err_diskio		; abort on error
	;
	; Check signature
	ld	de,(bb_sig)		; get signature read
	ld	a,sigbyte1		; expected value of first byte
	cp	d			; compare
	jp	nz,err_sig		; handle error
	ld	a,sigbyte2		; expected value of second byte
	cp	e			; compare
	jp	nz,err_sig		; handle error
	;
	ld	b,16			; loop down counter (max size of label)
	ld	de,(newlabel)		; reading from cmd line
	ld	hl,bb_label		; writing to disk label in sector buffer
updatelabel:
	ld	a,(de)			; read input
	or	a			; look for string terminator
	jr	z,updatelabel2		; if terminator then complete
	ld 	(hl),a			; store char in sector buff
	inc	de			; update pointers
	inc	hl
	djnz	updatelabel		; loop for next character
updatelabel2:
	ld	a,labelterm
	ld	(hl),a			; store the final terminator $ char
writelabel:
	; write the sector
	ld	hl,(lba)		; lba, low word, same as read sector
	ld	de,(lba+2)		; lba, high word
	call	diskwrite		; write the sector back to disk
	jp	nz,err_diskio		; abort on error
	;
	; print the outcome.
	ld	de,PRTSLC_HDR		; Header for list of Slices
	call	prtstr			; Print header
	call	prtslc3			; print updated label for unit/slice
	;
	ret
;
;-------------------------------------------------------------------------------
; advance the DE HL LBA sector by 2, ie third sector
;
thirdsector:
	ld	bc,2			; sector offset
	add	hl,bc			; add to LBA value low word
	jr	nc,sectornum		; check for carry
	inc	de			; if so, bump high word
sectornum:
	ld	(lba),hl		; update lba, low word
	ld	(lba+2),de		; update lba, high word
	ret
;
;===============================================================================
; Error Handlers
;
err_una:
	ld	de,str_err_una
	jr	err_ret
err_inv:
	ld	de,str_err_inv
	jr	err_ret
err_ver:
	ld	de,str_err_ver
	jr	err_ret
err_parm:
	ld	de,str_err_parm
	jr	err_ret
err_nodisk:
	ld	de,str_err_nodisk
	jr	err_ret
err_nomedia:
	ld	de,str_err_nomedia
	jr	err_ret
err_badslice:
	ld	de,str_err_badslc
	jr	err_ret
err_sig:
	ld	de,str_err_sig
	jr	err_ret
err_diskio:
	ld	de,str_err_diskio
	jr	err_ret
err_ret:
	call	crlf2
	call	prtstr
	or	$FF			; signal error
	ret
;
;===============================================================================
; Utility Routines
;-------------------------------------------------------------------------------
; Print a dot on console
;
pdot:
	push	af
	ld	a,'.'
	call	cout
	pop	af
	ret
;
;-------------------------------------------------------------------------------
; Print character in A without destroying any registers
; Use CP/M BDOS function $02 - Console Output
;
prtchr:
cout:
	push	af		; save registers
	push	bc
	push	de
	push	hl
	ld	e,a		; character to print in E
	ld	c,$02		; BDOS function to output a character
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	pop	af
	ret
;
;-------------------------------------------------------------------------------
; Start a newline on console (cr/lf)
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
;-------------------------------------------------------------------------------
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
;-------------------------------------------------------------------------------
; Print value of a in decimal with leading zero suppression
;
prtdecb:
	push	hl
	push	af
	ld	l,a
	ld	h,0
	call	prtdec
	pop	af
	pop	hl
	ret
;
;-------------------------------------------------------------------------------
; Print value of HL in decimal with leading zero suppression
;
prtdec:
	push	bc
	push	de
	push	hl
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
	call	prtdec1
	pop	hl
	pop	de
	pop	bc
	ret
prtdec1:
	ld	a,'0' - 1
prtdec2:
	inc	a
	add	hl,bc
	jr	c,prtdec2
	sbc	hl,bc
	cp	e
	jr	z,prtdec3
	ld	e,0
	call	cout
prtdec3:
	ret
;
;-------------------------------------------------------------------------------
; INPUT ROUTINES
;-------------------------------------------------------------------------------
; Skip whitespace at buffer adr in DE, returns with first
; non-whitespace character in A.
;
skipws:
	ld	a,(de)			; get next char
	or	a			; check for eol
	ret	z			; done if so
	cp	' '			; blank?
	ret	nz			; nope, done
	inc	de			; bump buffer pointer
	jr	skipws			; and loop
;
;-------------------------------------------------------------------------------
; Convert character in A to uppercase
;
upcase:
	cp	'a'		; if below 'a'
	ret	c		; ... do nothing and return
	cp	'z' + 1		; if above 'z'
	ret	nc		; ... do nothing and return
	res	5,a		; clear bit 5 to make lower case -> upper case
	ret			; and return
;
;-------------------------------------------------------------------------------
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
;-------------------------------------------------------------------------------
; Is character in A numeric? NZ if not
;
isnum:
	cp	'0'		; compare to ascii '0'
	jr	c,isnum1	; abort if below
	cp	'9' + 1		; compare to ascii '9'
	jr	nc,isnum1	; abort if above
	cp	a		; set Z
	ret
isnum1:
	or	$FF		; set NZ
	ret			; and done
;
;-------------------------------------------------------------------------------
; DISK IO ROUTINES
;-------------------------------------------------------------------------------
; Init Disk IO
;
initdiskio:
	; Get current RAM bank
	ld      b,BF_SYSGETBNK  	; HBIOS GetBank function
	RST     08          		; do it via RST vector, C=bank id
	RET     NZ          		; had to replace this line below.
	ld      a,c         		; put bank id in A
	ld      (BID_USR),a  		; put bank id in Argument
	RET
;
;-------------------------------------------------------------------------------
; Read disk sector(s)
; DE:HL is LBA, B is sector count, C is disk unit
;
diskread:
;
	; Seek to requested sector in DE:HL
	ld	a,(currunit)
	ld	c,a			; from the specified unit
	set	7,d			; set LBA access flag
	ld	b,BF_DIOSEEK		; HBIOS func: seek
	rst	08			; do it
	ret	nz			; handle error
;
	; Read sector(s) into buffer
	ld	a,(currunit)
	ld	c,a			; from the specified unit
	ld	e,1			; read 1 sector
	ld	hl,(dma)		; read into info sec buffer
	ld	a,(BID_USR)		; get user bank to accum
	ld	d,a			; and move to D
	ld	b,BF_DIOREAD		; HBIOS func: disk read
	rst	08			; do it
	ret				; and done
;
;-------------------------------------------------------------------------------
; WRITE disk sector(s)
; DE:HL is LBA, B is sector count, C is disk unit
;
diskwrite:
;
	ld	a,(currunit)		; disk unit to read
	ld	c,a			; put in C
	ld	b,1			; one sector
;
	; Seek to requested sector in DE:HL
	push	bc			; save unit & count
	set	7,d			; set LBA access flag
	ld	b,BF_DIOSEEK		; HBIOS func: seek
	rst	08			; do it
	pop	bc			; recover unit & count
	ret	nz			; handle error
;
	; Read sector(s) into buffer
	ld	e,b			; transfer count
	ld	b,BF_DIOWRITE		; HBIOS func: disk read
	ld	hl,(dma)		; read into info sec buffer
	ld	a,(BID_USR)		; get user bank to accum
	ld	d,a			; and move to D
	rst	08			; do it
	ret				; and done
;
;===============================================================================
; Constants
;===============================================================================
;
str_banner	.db	"\r\n"
		.db	"Slice Label, v1.1, July 2025 - M.Pruden",0
;
str_err_una	.db	"  ERROR: UNA not supported by application",0
str_err_inv	.db	"  ERROR: Invalid BIOS (signature missing)",0
str_err_ver	.db	"  ERROR: Unexpected HBIOS version",0
str_err_parm	.db	"  ERROR: Parameter error (SLABEL /? for usage)",0
str_err_nodisk	.db	"  ERROR: Disk unit not available",0
str_err_nomedia	.db	"  ERROR: Media not present",0
str_err_badslc 	.db	"  ERROR: Slice specified is illegal",0
str_err_sig	.db	"  ERROR: No system image on disk",0
str_err_diskio	.db	"  ERROR: Disk I/O failure",0
;
str_usage	.db	"\r\n\r\n"
		.db	"  Usage: SLABEL - list current labels\r\n"
		.db	"         SLABEL unit[.slice]=label - Defines a label\r\n"
		.db	"         SLABEL /? - Display this help info.\r\n"
		.db	"         Options are case insensitive.\r\n",0
;
PRTSLC_HDR	.TEXT	"\r\n\r\n"
		.TEXT	"Un.Sl Label           \r\n"
		.TEXT	"----- ----------------\r\n"
		.DB	0
;
;===============================================================================
; Working data
;===============================================================================
;
currunit	.db	0		; parameters for disk unit, current unit
currslice	.db	0		; parameters for disk slice, current slice
lba		.dw	0, 0		; lba address (4 bytes), of slice
newlabel	.dw	0		; address of parameter, new label to write
;
BID_USR		.db	0		; Bank ID for user bank
dma		.dw	bl_infosec	; address for disk buffer
;
stksav		.dw	0		; stack pointer saved at start
		.fill	stksiz,0	; stack
stack		.equ	$		; stack top
;
;===============================================================================
; Disk Buffer
;===============================================================================
;
		; define origin of disk buffer above 8000 for performance.
		.org	$8000
;
; Below is copied from ROM LDR
; Boot info sector is read into area below.
; The third sector of a disk device is reserved for boot info.
;
bl_infosec	.equ	$
		.ds	(512 - 128)
bb_metabuf	.equ	$
bb_sig		.ds	2		; signature (0xA55A if set)
bb_platform	.ds	1		; formatting platform
bb_device	.ds	1		; formatting device
bb_formatter	.ds	8		; formatting program
bb_drive	.ds	1		; physical disk drive #
bb_lu		.ds	1		; logical unit (lu)
		.ds	1		; msb of lu, now deprecated
		.ds	(bb_metabuf + 128) - $ - 32
bb_protect	.ds	1		; write protect boolean
bb_updates	.ds	2		; update counter
bb_rmj		.ds	1		; rmj major version number
bb_rmn		.ds	1		; rmn minor version number
bb_rup		.ds	1		; rup update number
bb_rtp		.ds	1		; rtp patch level
bb_label	.ds	16		; 16 character drive label
bb_term		.ds	1		; label terminator ('$')
bb_biloc	.ds	2		; loc to patch boot drive info
bb_cpmloc	.ds	2		; final ram dest for cpm/cbios
bb_cpmend	.ds	2		; end address for load
bb_cpment	.ds	2		; CP/M entry point (cbios boot)
;
;===============================================================================
;
	.end
