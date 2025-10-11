; ------------------------------------------------------------------------------
; msx-ldr.asm
; MSX RomWBW loader, requires 512KB or more RAM mapper
; ------------------------------------------------------------------------------

; The loader assumes following entry conditions:
; + RAM mapper slot is selected on all 4 pages
; + Segments 0 to 3 are in use for the DOS TPA
; + The last 2 segments may be in use for MSX-DOS 2 code + data

ROMWBW_SEG	.equ	4			; RomWBW boot segment

RDSLT		.equ	$000c			; read value of address in other slot
CALSLT		.equ	$001c			; inter-slot call routine
CHGCPU		.equ	$0180			; changes CPU mode
P2_SEG  	.equ	$f2c9	          	; current segment page 2 (MSX-DOS 2)
CSRSW		.equ	$fca9			; cursor on/off flag
MNROM		.equ	$fcc1			; main system rom slot
H_TIMI		.equ	$fd9f			; timer interrupt hook (vdp vsync)
 
; ------------------------------------------------------------------------------
		
		.ORG	$100

		; copy loader to page 3 and run it there
		ld	hl,LSTART
		ld	de,$c000
		ld	bc,LSIZE
		ldir
		jp	$c000

LSTART:
		
; ------------------------------------------------------------------------------

		.ORG	$c000

		; open ROM image file (fcb)
		ld	de,romfile
		ld	c,$0f			; FOPEN
		call	5
		or	a			; error opening file?
		jp	nz,error_open		; nz=yes
		
		; get filesize, determine number of ram segments to load
		ld	a,(romfile+$12)		; rom image size / 64k bytes
		rlca				; number of banks
		rlca				; number of segments
		ld	(nsegs),a
		
		; determine ram mapper size
		call	MapperSize
		or	a
		jp	z,error_noram
		
		; mapper segments > nsegs + 5?
		ld	a,(nsegs)
		add	a,5
		sub	b
		jp	nc,error_ramsize
		
		ld	de,t_message
		ld	c,$09			; STROUT
		call	5
		
		; init fcb file read: set recordsize and disk transfer address 
		ld	hl,$0400		; use 1K blocks
		ld	(romfile+$0e),hl
		ld	de,$8000
		ld	c,$1a			; SETDTA
		call	5

		; cursor off
		xor	a
		ld	(CSRSW),a		
		
		; preload RomWBW rom into RAM Mapper segments
		ld	a,(nsegs)
		ld	b,a			; number of segment to load
		ld	a,4			; starting segment
		
load_bank:	push	af
		push	bc
		ld	e,$0d			; set cursor to beginning of line
		ld	c,$02			; CONOUT
		call	5
		pop	bc			; reload segment number

		push	bc
		ld	a,b
		call	dspNumA
		pop	bc
		pop	af			; reload segment number
		
		out	($fe),a			; select ram segment in page 2
		ld	(P2_SEG),a		; update system variable segment 2 (MSX-DOS 2)
		inc	a
		
		; read rom bank data from file
		push	af
		push	bc
		ld	hl,16			; read 16K data
		ld	de,romfile
		ld	c,$27			; RDBLK
		call	5
		or	a			; error reading file?
		jp	nz,error_read		; nz=yes
		pop	bc
		pop	af
	
		; next rom bank
		djnz	load_bank
		
		; it's not necessary to close the file
		
		; call H.TIMI 256 times to motor off floppy drives
		di
		xor	a
mtcount:	call	H_TIMI			; H.TIMI handler saves register AF
		dec	a
		jr	nz,mtcount

		; set CPU to Z80 mode / turbo off
		ld	hl,CHGCPU
		ld	a,(MNROM)
		call	RDSLT			; routine to change CPU mode exists in BIOS?
		cp	$c3			; z=yes
		ld	a,$80			; Z80 mode + switch Turbo LED indicator
		ld	ix,CHGCPU		; change CPU routine
		ld	iy,(MNROM-1)		; in main rom
		call	z,CALSLT

		; select RomWBW bootloader bank and start RomWBW
		di
		ld	a,ROMWBW_SEG
		out	($fc),a
		inc	a
		out	($fd),a
		jp	$0
		
; ---------------------------------------------------------------------------
; dspNumA - routine to display a value in A in ascii characters
; ---------------------------------------------------------------------------
dspNumA:	ld	l,a
		ld	h,0
		;ld	bc,-100
		;call	num1
		ld	bc,-10
		call	num1
		ld	bc,-01
num1:		ld	a,'0'-1
num2:		inc	a
		add	hl,bc
		jr	c,num2
		sbc	hl,bc
		push	hl
		ld	e,a
		ld	c,$02			; CONOUT
		call	5
		pop	hl
		ret
		
; ---------------------------------------------------------------------------
; Determine if a RAM mapper is available and what size it is
; Output: a = number of RAM mapper segments
; ---------------------------------------------------------------------------
MapperSize:	ld	hl,$8000
		; pass 1: test write/read segment 0
		ld	a,1
		out	($fe),a			; set page 2 to segment 1
		ld	b,(hl)			; save byte 1
		ld	(hl),$aa		; write test value AA in segment 1
		xor	a
		out	($fe),a			; set page 2 to segment 0
		ld	c,(hl)			; save byte 0
		ld	(hl),$55		; write test value 55 in segment 0
		inc	a
		out	($fe),a			; set page 2 to segment 1
		ld	e,(hl)			; read test byte 1 in E
		xor	a
		out	($fe),a			; set page 2 to segment 0
		ld	(hl),c			; restore byte 0
		inc	a
		out	($fe),a			; set page 2 to segment 1
		ld	(hl),b			; restore byte 1
		ld	a,e			; AA=mapper 55=no mapper
		cp	$aa			; is mapper?
		ld	b,$00			; set RAM segments to 0
		jr	nz,_restore2		; nz=no mapper
		; pass 2: write test byte to all segments
_testpass2:	ld	a,b
		out	($fe),a
		ld	a,(hl)
		push	af			; save byte on stack
		inc	sp			; "
		ld	(hl),$aa
		inc	b
		jr	nz,_testpass2
		; pass 3: determine number of valid ram segments
_testpass3:	ld	a,b
		out	($fe),a
		ld	a,(hl)
		cp	$aa			; valid ram segment?
		jr	nz,_restore		; nz=no
		ld	a,$55
		ld	(hl),a
		cp	(hl)			; 2nd test ok?
		jr	nz,_restore		; nz=no
		inc	b
		jr	nz,_testpass3
		dec	b			; maximum segment number is 255
		; restore data saved on stack for each segment
_restore:	ld	c,$00
_restore1:	ld	a,c
		dec	a
		out	($fe),a
		dec	sp			; load byte on stack
		pop	af			; "
		ld	(hl),a
		dec	c
		jr	nz,_restore1
		; restore/set ram segment 1 in page 2
_restore2:	ld	a,$01
		out	($fe),a
		ld	a,b
		ret
		
		
; ---------------------------------------------------------
; Handle errors reading rom file
; ---------------------------------------------------------
error_open:	ld	de,t_open
		jr	error_end

error_read:	pop	bc
		pop	af
		ld	de,t_read
		jr	error_end
		
error_noram:	ld	de,t_noram
		jr	error_end
		
error_ramsize:	ld	de,t_ramsize

error_end:	ld	c,$09			; STROUT
		call	5
		jp	0			; end program
		
t_message:	.db	"Loading RomWBW for MSX...",13,10,"$"
t_open:		.db	"Error opening msx-std.rom file$"
t_noram:	.db	"Error: no RAM mapper memory detected$"
t_ramsize:	.db	"Error: not enough RAM mapper memory$"
t_read:		.db	$0a,"Error reading msx-std.rom file$"
nsegs:		.db	0			; number of segments
romfile:	.db	0,"MSX-STD ","ROM"	; fcb file
		.fill	25,0			; fcb variables

; ------------------------------------------------------------------------------

LSIZE		.EQU	$-$c000

		.END
