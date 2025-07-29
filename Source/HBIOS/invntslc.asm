;==============================================================================
; SLICE INVENTORY - Inventory Slice
; Version  June-2025
;==============================================================================
;
; Author: Mark Pruden
;
; This is a SUBSET of SLABEL.ASM -> Please See this program also when
; making changes, as most of the code found here exists there also
;
; This is a program CALLED from RomLoader, and is specific to RomWBW
;
; See SLABEL.ASM for ALL other Notes about This program.
;------------------------------------------------------------------------------
;
; Change Log:
;   2025-06-30 [MAP] Initial v1.0 release for distribution
;   2025-07-12 [MR]  Minor tweak to partially tidy up output formatting
;______________________________________________________________________________
;
; Include Files
;
#include "./hbios.inc"
#include "./layout.inc"
;______________________________________________________________________________
;
; General operational equates (should not requre adjustment)
;
sigbyte1	.equ	$A5		; 1st sig byte boot info sector (bb_sig)
sigbyte2	.equ	$5A		; 2nd sig byte boot info sector (bb_sig)
;
labelterm	.equ	'$'		; terminating charater for disk label
;
;*****************************************************************************
;
; APPLICATION WILL WILL BE LOADED AT USR_LOC.  THEREFORE, THE CODE
; MUST "ORG" AT THIS ADDRESS.  TO CHANGE THE LOAD LOCATION OF THIS
; CODE, YOU CAN UPDATE SLC_LOC IN LAYOUT.INC
;
	.ORG	SLC_LOC
;
;*****************************************************************************
; Main Code (shared) starts here
;*****************************************************************************
;
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
prtslcfin:
	ret				; loop has finished, RETURN
;
;*****************************************************************************
; Supporting Code Stars Here
;*****************************************************************************
;
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
	ld	a,(currslice)
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
;
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
;*****************************************************************************
; SUPPORT ROUTINES
;*****************************************************************************
;
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
; NOTE THIS CODE IS SPECIFIC AS IT USES HBIOS DIRECTLY
;
prtchr:
cout:
	push	af		; save registers
	push	bc
	push	de
	push	hl
	LD	B,BF_CIOOUT
	LD	C,CIO_CONSOLE
	LD	E,A
	RST	08
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
;===============================================================================
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
;
BID_USR		.db	0		; Bank ID for user bank
dma		.dw	bl_infosec	; address for disk buffer
;
;===============================================================================
;
; IT IS CRITICAL THAT THE FINAL BINARY BE EXACTLY SLC_SIZ BYTES.
; THIS GENERATES FILLER AS NEEDED.  IT WILL ALSO FORCE AN ASSEMBLY
; ERROR IF THE SIZE EXCEEDS THE SPACE ALLOCATED.
;
SLACK	.EQU	(SLC_END - $)
;
#IF (SLACK < 0)
	.ECHO	"*** INVENTORY SLICE IS TOO BIG!!!\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF
;
	.FILL	SLACK,$00
	.ECHO	"INVNTSLC Slice Inventory space remaining: "
	.ECHO	SLACK
	.ECHO	" bytes.\n"
;
;===============================================================================
; Disk Buffer
;===============================================================================
;
		; define origin of disk buffer = 9000
		; Note this shares SAME Buffer Address as ROMLDR
		.org	$9000
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

.END
