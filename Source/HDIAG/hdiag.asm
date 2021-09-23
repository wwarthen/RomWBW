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
;   assuming that it will be loaded at 100h by the CP/M (or compatible)
;   OS.
;
	.module	MAIN
;
#include "hdiag.inc"
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
	jp	_start		; rst $00: jump to boot code
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
_start:
;
; Discover CPU Type and Memory Manager
;
; Some of this code is derived from UNA by John Coffman
;
; CPU and memory manager constants are defined in hdiag.inc.
;
	di			; no interrupts allowed
;
	ld	a,$80
	out	($0D),a
;
	; Use D for memory manager, and E for CPU Type
	ld	de,0		; assume unknown for both
;
; Start with CPU type detection
;
	; Check for Z80
	inc	e		; not sure how to do it, just assume it
;
	; Test for Z180 using mlt
	ex	de,hl		; save DE to HL for test
	ld	de,$0506	; 5 x 6
	mlt	de		; de = 30 if Z180
	ld	a,e		; check if multiply happened
	ex	de,hl		; restore DE now
	cp	30
	jr	nz,_tryZ280	; if != 30, not a Z180, try Z280
	inc	e		; Z80180 or better
;
#ifdef APPBOOT
;
	; Reset Z180 internal register base to zero no matter where
	; it might have previously been mapped.
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
	jr	z,_z180res	; if zero, pre-S, HD61480 or equiv
	inc	e		; Z8S180 rev K (SL1960) or better
;
	; Test for newer S-class (rev N)
	; On older S-class, asci time constant reg does not exist
	; and will always read back as $FF
	out0	(z180_astc1l),d	; d = 0 at this point
	in0	a,(z180_astc1l)	; asci time constant reg
	inc	a		; FF -> 0
	jr	z,_z180res	; if zero, rev-K
	inc	e		; otherwise Z8S180 rev N w/ asci brg
	jr	_z180res	; go to Z180 reset
;
_tryZ280:
	; Test for Z280 per Zilog doc
	ld	a,$40		; initialize the operand
	.db	$cb,$37		; this instruction will set the s flag
				; on the Z80 cpu and clear the s flag
				; on the Z280 mpu.
	jp	m,_z80res	; if not Z280, we are Z80
	ld	l,hd_cpu_z280	; we are Z280
	jr	_z280res	; handle Z280 initialization
;
_z80res:
	ld	a,$01
	out	(0),a
	; Reset Z80 here (is there anything?)
	jr	_cpu1
;
_z180res:
;
	; Reset z180 registers here
	; Set CPU speed to oscillator x 1
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
	jr	_cpu1
;
_z280res:
	; Reset Z280 registers here
	; Make sure memmgr is reset to defaults!
	jr	_cpu1
;
; At this point, we should have the cpu type in the L register.
; Now determine the memory manager.  In general, we just attempt to
; enable the different memory managers and keep testing to see if
; a RAM bank has appeared in the common area.
;
_cpu1:
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
	; There is no way to disable the common (himem) RAM bank
	; under the SBC memory manager.  Here, we just see if there
	; is RAM in himem and, if so, assume the SBC memory manager.
	; If not, we continue on to test the other possible memory
	; managers.
	inc	d			; assume SBC memory manager
	ld	ix,$FFFF		; point to himem
	ld	a,$A5			; an unlikely bit pattern
	ld	(ix),a			; write the value
	cp	(ix+0)			; check value written
	jr	z,_cpu2		; SBC memory manager, we are done!
;
	ld	a,$04
	out	($0D),a
;
	; Now test for Zeta 2 memory manager
	; Start by initializing and enabling the page registers
	inc	d			; assume Zeta 2 memory manager
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
	jr	z,_cpu2		; Zeta 2 memory manager, we are done!
;
	ld	a,$06
	out	($0D),a
;
	; If neither SBC nor Zeta 2, then we assume the memory
	; manager is the native memory manager onboard the CPU
	ld	a,e		; get cpu type
	cp	hd_cpu_z280	; Z280?
	jr	z,_z280init	; handle it
	or	a		; Z80?
	jr	nz,_z180init	; if no, go handle Z180
;
	; If we get here, we are stuck.  We believe we are a Z80
	; but both of the Z80 memory manager tests failed.
_halt:
	ld	a,$07
	out	($0D),a
;
	ld	hl,_str_halt
	call	prtstr
	halt			; give up
;
_z180init:
	; Initialize Z180 memory manager
	; Put first RAM page into himem (commmon)
	ld	a,$80
	out0	(z180_cbr),a
;
	ld	d,hd_mm_z180
	jr	_cpu2

_N8init:
	; Initialize N8 memory manager
	ld	d,hd_mm_n8
	jr	_cpu2
	
_z280init:
	; Initialize Z280 memory manager
	ld	d,hd_mm_z280
	jr	_cpu2
;
_cpu2:
	ld	a,$08
	out	($0D),a
;
	ex	de,hl			; cpu/memmgr values to HL
	ld	sp,hl			; and stash SP reg
;
; Transition to upper memory (omit page zero)
;
	ld	hl,$0000+$100
	ld	de,$8000+$100
	ld	bc,$8000-$100
	ldir
	jp	_start2
;
	.org	$ + $8000
;
; 
;=======================================================================
; Post-relocation Startup
;=======================================================================
;
_start2:
;
	ld	a,$09
	out	($0D),a
;
; Copy FF page image to real location.  Use a decrementing copy
; just in case page image is within $100 bytes of $FF00.  Very
; unlikely, but just to be safe.
;
	ld	hl,_ffimg+$FF		; Start at end of image
	ld	de,$FFFF		; To top of RAM
	ld	bc,$100			; Copy 1 page
	lddr				; Execute
;
; Recover cpu/memmgr codes stashed in SP and
; save them in FF page
;
	ld	(_cpu),sp
;
; Now we establish a real stack (finally!)
;
	ld	sp,$FF00		; Stack just below FF page
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
;
; This should be table driven!!!
;
	; Z280 UART
	ld	ix,ser_z2u
	call	jpix
	jr	z,_start3
	; ASCI
	ld	ix,ser_asci
	call	jpix
	jr	z,_start3
	; UART
	ld	ix,ser_uart
	call	jpix
	jr	z,_start3
	; ACIA
	ld	ix,ser_acia
	call	jpix
	jr	z,_start3
	; SIO
	ld	ix,ser_sio
	call	jpix
	jr	z,_start3
;
	; Ugh, nothing worked
	ld	a,$0C
	out	($0D),a
	halt
;
;
;
_start3:
;
	ld	a,$0D
	out	($0D),a
;
; Copy selected console serial driver vector table into place
;
	push	ix
	pop	hl
	ld	de,_jptbl
	ld	bc,5*3
	ldir
;
;
;
	; Setup memory manager
;
	; Map RAM page 0 to lower 32K
;
	; Setup zero page in lower 32K
;
;
;
_restart:
;
	ld	hl,_str_banner
	call	prtstr
;
	; Print CPU model
	ld	de,_str_cputag
	ld	hl,_str_cpu
	ld	a,(hd_cpu)
	call	prtstrtbl
;
	; Print memory manager
	ld	de,_str_mmtag
	ld	hl,_str_mm
	ld	a,(hd_mmgr)
	call	prtstrtbl
;
	call	cin
	jp	_restart
;
;
;
	jp	_halt
;
;=======================================================================
; Helper functions
;=======================================================================
;
#include "util.asm"
;
;=======================================================================
; Console I/O modules
;=======================================================================
;
; Include all serial drivers
;
	.module UART
ser_uart	.equ	$
#include "uart.asm"
;
	.module ASCI
ser_asci	.equ	$
#include "asci.asm"
;
	.module ACIA
ser_acia	.equ	$
#include "acia.asm"
;
	.module SIO
ser_sio		.equ	$
#include "sio.asm"
;
	.module Z2U
ser_z2u		.equ	$
#include "z2u.asm"
;
	.module MAIN
;
;=======================================================================
; Internal variables and literals
;=======================================================================
;
_str_banner	.db	"\r\n\r\nHDIAG v0.90",0
_str_cputag	.db	"\r\nCPU Model: ",0
_str_mmtag	.db	"\r\nMemory Manager: ",0
_str_halt	.db	"\r\n\r\n*** System HALTed ***",0
;
_str_cpu:
	.dw	_str_unknown
	.dw	_str_cpuz80
	.dw	_str_cpuz180
	.dw	_str_cpuz180K
	.dw	_str_cpuz180N
	.dw	_str_cpuz280
;
_str_unknown	.db	"Unknown",0
_str_cpuz80	.db	"Z80",0
_str_cpuz180	.db	"Z80180",0
_str_cpuz180K	.db	"Z8S180-K",0
_str_cpuz180N	.db	"Z8S180-N",0
_str_cpuz280	.db	"Z80280",0
;
_str_mm:
	.dw	_str_unknown
	.dw	_str_mmsbc
	.dw	_str_mmz2
	.dw	_str_mmz180
	.dw	_str_mmn8
	.dw	_str_mmz280
;
_str_mmsbc	.db	"SBC/MBC",0
_str_mmz2	.db	"Zeta2/RC2014",0
_str_mmz180	.db	"Z180 Native",0
_str_mmn8	.db	"Z180 Native (N8)",0
_str_mmz280	.db	"Z280 Native",0
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
; The console function addresses are set dynamically based on the
; console driver that is installed at boot.
;
_ffimg	.equ	$
;
	.org	$FF00			; Set code org
;
_jptbl:
cinit	jp	0			; Console port initialization
cin	jp	0			; Console read byte
cout	jp	0			; Console write byte
cist	jp	0			; Console input status
cost	jp	0			; Console output status
;
	.fill	$FF80-$
_cpu	.db	0			; CPU type
_mmgr	.db	0			; Memory manager type
;
	.fill	$10000-$
	.end


