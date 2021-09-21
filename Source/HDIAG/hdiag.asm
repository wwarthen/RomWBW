;
;
;=======================================================================
; HDIAG Diagmostic ROM
;=======================================================================
;
; HDIAG is a framework for a diagnotic environment intended to be
; suitable for all systems supported by RomWBW.  RomWBW expects hardware
; to be fully functional making it difficult to use it to initially
; check out a system.  HDIAG is explicitly constructed to be as simple
; as possible.
;
; There is only a single variant of HDIAG that is built.  HDIAG is
; designed to detect the environment it is operating under at startup
; and dynamically adapt to it.
;
; HDIAG can be assembled to boot in one of 2 modes (rom or application)
; as described below.  When compiled, you must define exactly one of the
; following macros:
;
; - ROMBOOT: Boot from a rom bank
;
;   When ROMBOOT is defined, the file is assembled to be imbedded at the
;   start of a rom assuming that the cpu will start execution at address
;   0.
;
; - APPBOOT: Boot as a CP/M style application file
;
;   When APPBOOT is defined, the file is assembled as a CP/M application
;   assuming that it will be loaded at 100h by the cp/m (or compatible)
;   OS.
;
#include "z180.inc"
; 
;=======================================================================
; Page Zero Definition
;=======================================================================
;
; Generic page zero setup.  Only applies to ROMBOOT startup mode.
;
#ifdef ROMBOOT 
;
	.org	$0000
;
	jp	hd_start		; rst $00: jump to boot code
	.fill	($08-$)
	ret				; rst $08
	.fill	($10-$)
	ret				; rst $10
	.fill	($18-$)
	ret				; rst $18
	.fill	($20-$)
	ret				; rst $20
	.fill	($28-$)
	ret				; rst $28
	.fill	($30-$)
	ret				; rst $30
	.fill	($38-$)
	reti				; h/w int return
	.fill	($66-$)
	retn				; h/w nmi return
	.fill	($100-$)		; pad remainder of page zero
;
#else
	.org	$0100
;
#endif
; 
;=======================================================================
; Startup
;=======================================================================
;
; Before transitioning to RAM, we need to determine the memory
; manager to use because some platforms will not have any RAM mapped
; to the upper 32K of CPU address space until the memory manager
; is initialized.
;
hd_start:
;
; Discover CPU Type and Memory Manager
;
; Some of this code is derived from UNA by John Coffman
;
; CPU Type:
;	0: Z80
;	1: Z80180 - ORIGINAL Z180 (EQUIVALENT TO HD64180)
;	2: Z8S180 - ORIGINAL S-CLASS, REV. K, AKA SL1960, NO ASCI BRG
;	3: Z8S180 - REVISED S-CLASS, REV. N, W/ ASCI BRG
;	4: Z8280
;
; Memory Manager:
;	0: SBC/MBC/Zeta 1
;	1: Zeta 2/RC2014
;	2: Z180
;	3: N8?
;	4: Z280
;
;
	di			; no interrupts allowed
;
	ld	a,$80
	out	($0D),a
;
	; Use H for memory manager, and L for CPU Type
	ld	hl,0		; assume Z80 and SBC
;
	; Test for Z180 using mlt
	ld	de,$0506	; 5 x 6
	mlt	de		; de = 30 if Z180
	ld	a,e		; check if multiply happened
	cp	30
	jr	nz,hd_tryZ280	; if != 30, not a Z180, try Z280
	inc	l		; Z80180 or better
;
#ifdef APPBOOT
;
	; Reset Z180 internal register base to zero
	xor	a
	out0	($7F),a
	out0	($BF),a
	out0	($FF),a
;	
#endif
;
	; Test for older S-class (rev K)
	in0	a,(z180_ccr)	; supposedly only on s-class
	inc	a		; FF -> 0
	jr	z,hd_z180res	; if zero, pre-S, HD61480 or equiv
	inc	l		; Z8S180 rev K (SL1960) or better
;
	; Test for newer S-class (rev N)
	; On older S-class, asci time constant reg does not exist
	; and will always read back as $FF
	out0	(z180_astc1l),d	; d = 0 at this point
	in0	a,(z180_astc1l)	; asci time constant reg
	inc	a		; FF -> 0
	jr	z,hd_z180res	; if zero, rev-K
	inc	l		; otherwise Z8S180 rev N w/ asci brg
	jr	hd_z180res	; go to Z180 reset
;
hd_tryZ280:
	; Test for Z280 per Zilog doc
	ld	a,$40		; initialize the operand
	.db	$cb,$37		; this instruction will set the s flag
				; on the Z80 cpu and clear the s flag
				; on the Z280 mpu.
	jp	m,hd_z80res	; if not Z280, we are Z80
	ld	l,4		; we are Z280
	jr	hd_z280res	; handle Z280 initialization
;
hd_z80res:
	ld	a,$01
	out	(0),a
	; Reset Z80 here (is there anything?)
	jr	hd_cpu1
;
hd_z180res:
;
	; Reset z180 registers here
	; Set CPU speed to oscillator X 1
	xor	a
	out0	(z180_cmr),a
	ld	a,$80
	out0	(z180_ccr),a
	; Set default wait states
	ld	a,$%00000100	; mem wait=0, i/o wait=+1
	out0	(z180_dcntl),a	
;
#ifdef ROMBOOT
	; Setup Z180 MMU
	; Keep ROM page zero in lower 32K!!!
	ld	a,$80		; Common Base @ 32K, Bank Base @ 0K
	out0	(z180_cbar),a
	xor	a		; Physical address zero
	out0	(z180_cbr),a	; ... for Common Base
	out0	(z180_bbr),a	; ... and Bank Base
#else
	xor	a		; Physical address zero
	out0	(z180_cbr),a	; ... for Common Base
#endif
;	
	jr	hd_cpu1
;
hd_z280res:
	; Reset Z280 registers here
	; Make sure memmgr is reset to defaults!
	jr	hd_cpu1
;
hd_cpu1:
	ld	a,$02
	out	($0D),a
;
	; Reset Zeta 2 memory manager (in case it exists)
#ifdef ROMBOOT
	xor	a			; disable value
	out	($7C),a			; write it
	xor	a			; 16K ROM page 0
	out	($78),a
	inc	a			; 16K ROM page 1
	out	($79),a
#endif
	ld	a,2			; 16K ROM page 2
	out	($7A),a
	inc	a			; 16K ROM page 3
	out	($7B),a
;
	; Reset N8 supplemental memory manager
	; *** Need to implement this ***
;
	ld	a,$03
	out	($0D),a
;
	; If SBC memmgr, RAM is already in himem, otherwise ROM
	ld	ix,$FFFF		; point to himem
	ld	a,$A5			; an unlikely bit pattern
	ld	(ix),a			; write the value
	cp	(ix+0)			; check value written
	jr	z,hd_cpu2		; SBC memory manager, we are done!
;
	ld	a,$04
	out	($0D),a
;
	; Now test for Zeta 2 memory manager
	; Start by initializing and enabling the page registers
	inc	h			; assume Zeta 2 memory manager
#ifdef ROMBOOT
	xor	a			; ROM page 0
	out	($78),a
	inc	a			; ROM page 1
	out	($79),a
#endif
	ld	a,$20			; first RAM page
	out	($7A),a
	inc	a			; second RAM page
	out	($7B),a
	ld	a,1			; enable paging
	out	($7C),a
;
	ld	a,$05
	out	($0D),a
;
	; Test himem RAM again
	ld	ix,$FFFF		; point to himem
	ld	a,$A5			; an unlikely bit pattern
	ld	(ix),a			; write the value
	cp	(ix+0)			; check value written
	jr	z,hd_cpu2		; Zeta 2 memory manager, we are done!
;
	ld	a,$06
	out	($0D),a
;
	; If neither SBC nor Zeta 2, then we assume the memory
	; manager is the native memory manager onboard the CPU
	ld	a,l		; get cpu type
	cp	4		; Z280?
	jr	z,hd_z280init	; handle it
	or	a		; Z80?
	jr	nz,hd_z180init	; if no, do handle Z180
;
	; If we get here, we are stuck.  We believe we are a Z80
	; but both of the Z80 memory manager tests failed.
hd_halt:


	ld	a,$07
	out	($0D),a


	ld	hl,str_halt
	call	prtstr
	halt			; give up
;
hd_z180init:
	; Initialize Z180 memory manager
	; Put first RAM page into himem (commmon)
	ld	a,$80
	out0	(z180_cbr),a
;
	ld	h,2
	jr	hd_cpu2

hd_N8init:
	; Initialize N8 memory manager
	ld	h,3
	jr	hd_cpu2
	
hd_z280init:
	; Initialize Z280 memory manager
	ld	h,4
	jr	hd_cpu2
;
hd_cpu2:
	ld	a,$08
	out	($0D),a
;
	ld	($8000),hl		; stash cpu/memmgr at $8000
;
; Transition to upper memory (omit page zero)
;
	ld	hl,$0000+$100
	ld	de,$8000+$100
	ld	bc,$8000-$100
	ldir
	jp	hd_start2
;
	.org	$ + $8000
;
; 
;=======================================================================
; Post-relocation Startup
;=======================================================================
;
hd_start2:
;
	ld	a,$09
	out	($0D),a
;
	ld	sp,$FF00		; Stack just below FF page
;
; Copy FF page image to real location.  Use a decrementing copy
; just in case page image is within $100 bytes of $FF00.  Very
; unlikely, but just to be safe.
;
	ld	hl,ffpgimg+$FF		; Start at end of image
	ld	de,$FFFF		; To top of RAM
	ld	bc,$100			; Copy 1 page
	lddr				; Execute
;
; Recover cpu/memmgr codes stashed at $8000 and
; save them in FFpg
;
	ld	hl,($8000)
	ld	(hd_cpu),hl
;
; Probe and initialize serial port console driver.  We just go
; through the options stopping at the first one that works.  The
; order of polling below is intended to find the most reasonable
; console port.
;
;
	ld	a,$0A
	out	($0D),a
;
	; Z280 UART
	ld	ix,z2u_jptbl
	call	jpix
	jr	z,hd_start3
	; ASCI
	ld	ix,asci_jptbl
	call	jpix
	jr	z,hd_start3
	; UART
	ld	ix,uart_jptbl
	call	jpix
	jr	z,hd_start3
	; ACIA
	ld	ix,acia_jptbl
	call	jpix
	jr	z,hd_start3
	; SIO
	ld	ix,sio_jptbl
	call	jpix
	jr	z,hd_start3
;
	; Ugh, nothing worked
	ld	a,$0C
	out	($0D),a
	halt
;
;
;
hd_start3:
;
	ld	a,$0D
	out	($0D),a
;
; Copy selected console serial driver vector table into place
;
	push	ix
	pop	hl
	ld	de,hd_serjptbl
	ld	bc,5*3
	ldir
;
;
;
	; Map a RAM page to lower 32K
;
	; Setup zero page in lower 32K
;
;
;
hd_start4:
;
	ld	hl,str_banner
	call	prtstr
;
	ld	hl,str_cputag
	call	prtstr
	ld	a,($8000)		; cpu type
	;call	prthex8
	rlca
	ld	hl,str_cpu
	call	addhla
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	call	prtstr
;
;
	ld	hl,str_mmtag
	call	prtstr
	ld	a,($8001)		; memory manager
	;call	prthex8
	rlca
	ld	hl,str_mm
	call	addhla
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	call	prtstr
;
	call	cin
	jp	hd_start4
;
;
;
	jp	hd_halt
;
;=======================================================================
; Helper functions
;=======================================================================
;
;
;=======================================================================
; Include various utility code modules
;=======================================================================
;
#include "util.asm"
;
;=======================================================================
; Console I/O
;=======================================================================
;
; Internal serial driver routing jump table.  The console serial
; port is detected at startup and the following table is populated
; dynamically at that time.
;
hd_serjptbl:
	jp	0			; Console port initialization
	jp	0			; Console read byte
	jp	0			; Console write byte
	jp	0			; Console input status
	jp	0			; Console output status
;
; Wrapper functions for console I/O handles routing abstraction and
; ensures that no registers are modified other than AF for input
; functions.
;
hd_cinit:
	push	af
	push	bc
	push	de
	push	hl
	call	hd_serjptbl + 0
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
hd_cin:
	push	bc
	push	de
	push	hl
	call	hd_serjptbl + 3
	pop	hl
	pop	de
	pop	bc
	ret
;
hd_cout:
	push	af
	push	bc
	push	de
	push	hl
	call	hd_serjptbl + 6
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
hd_cist:
	push	bc
	push	de
	push	hl
	call	hd_serjptbl + 9
	pop	hl
	pop	de
	pop	bc
	ret
;
hd_cost:
	push	af
	push	bc
	push	de
	push	hl
	call	hd_serjptbl + 12
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
; Include all serial drivers
;
#include "uart.asm"
#include "asci.asm"
#include "acia.asm"
#include "sio.asm"
#include "z2u.asm"
;
;=======================================================================
; Working literals and internal variables
;=======================================================================
;
str_banner	.db	"\r\n\r\nHDIAG v0.90",0
str_cputag	.db	"\r\nCPU Model: ",0
str_mmtag	.db	"\r\nMemory Manager: ",0
str_halt	.db	"\r\n\r\n*** System HALTed ***",0
;
str_cpu:
	.dw	str_cpuz80
	.dw	str_cpuz180
	.dw	str_cpuz180K
	.dw	str_cpuz180N
	.dw	str_cpuz280
;
str_cpuz80	.db	"Z80",0
str_cpuz180	.db	"Z80180",0
str_cpuz180K	.db	"Z8S180-K",0
str_cpuz180N	.db	"Z8S180-N",0
str_cpuz280	.db	"Z80280",0
;
str_mm:
	.dw	str_mmsbc
	.dw	str_mmz2
	.dw	str_mmz180
	.dw	str_mmn8
	.dw	str_mmz280
;
str_mmsbc	.db	"SBC/MBC",0
str_mmz2	.db	"Zeta2/RC2014",0
str_mmz180	.db	"Z180 Native",0
str_mmn8	.db	"Z180 Native (N8)",0
str_mmz280	.db	"Z280 Native",0
;
;=======================================================================
; Top page of CPU RAM, global variables and function jump table
;=======================================================================
;
; This area is defined here, but copied to the top page of RAM at
; initialization!
;
; The top page (256 bytes) of CPU address space is used to maintain
; a jump table of functions available to all diagnostic modules.
; It also contains some global variables at fixed locations for use
; by diagnostic modules.
;
ffpgimg	.equ	$
	.org	$FF00			; Set code org
;
hd_jptbl:
cinit	jp	hd_cinit		; Console port initialization
cin	jp	hd_cin			; Console read byte
cout	jp	hd_cout			; Console write byte
cist	jp	hd_cist			; Console input status
cost	jp	hd_cost			; Console output status
;
	.fill	$FF80-$
hd_cpu	.db	0			; CPU type
hd_mmgr	.db	0			; Memory manager type
	.end


