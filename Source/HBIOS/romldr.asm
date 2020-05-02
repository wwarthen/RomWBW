;
;=======================================================================
; RomWBW Loader
;=======================================================================
;
; The loader code is invoked immediately after HBIOS completes system
; initialization. it is responsible for loading a runnable image
; (operating system, etc.) into memory and transferring control to that
; image.  The image may come from ROM (romboot), RAM (appboot/imgboot)
; or from disk (disk boot).
;
; In the case of a ROM boot, the selected executable image is copied
; from ROM into the default RAM and then control is passed to the
; starting address in RAM.  In the case of an appboot or imgboot
; startup (see hbios.asm) the source of the image may be RAM.
;
; In the case of a disk boot, sector 2 (the third sector) of the disk
; device will be read -- this is the boot info sector and is expected
; to have the format defined at bl_infosec below.  the last three words
; of data in this sector determine the final destination starting and
; ending address for the disk load operation as well as the entry point
; to transfer control to.  The actual image to be loaded *must* be on
; the disk in the sectors immediately following the boot info sector.
; This means the image to be loaded must begin in sector 3 (the fourth
; sector) and occupy sectors contiguously after that.
;
; The code below relocates itself at startup to the start of common RAM
; at $8000.  This means that the code, data, and stack will all stay
; within $8000-$8FFF.  Since all code images like to be loaded either
; high or low (never in the middle), the $8000-$8FFF location tends to
; avoid the problem where the code is overlaid during the loading of
; the desired executable image.
;
#INCLUDE "std.asm"	; standard RomWBW constants
;
#ifndef BOOT_DEFAULT
#define BOOT_DEFAULT "H"
#endif
;
bel	.equ	7	; ASCII bell
bs	.equ	8	; ASCII backspace
lf	.equ	10	; ASCII linefeed
cr	.equ	13	; ASCII carriage return
;
cmdbuf	.equ	$80	; cmd buf is in second half of page zero
cmdmax	.equ	60	; max cmd len (arbitrary), must be < bufsiz
bufsiz	.equ	$80	; size of cmd buf
;
int_im1	.equ	$FF00	; IM1 vector target for RomWBW HBIOS proxy
;
bid_cur	.equ	-1	; used below to indicate current bank
;
	.org	0	; we expect to be loaded at $0000
;
;=======================================================================
; Normal page zero setup, ret/reti/retn as appropriate
;=======================================================================
;
	jp	$100			; rst 0: jump to boot code
	.fill	($08 - $)
#if (BIOS == BIOS_WBW)
	jp	HB_INVOKE		; rst 8: invoke HBIOS function
#else
	jp	$FFFD			; rst 8: invoke UBIOS function
#endif
	.fill	($10 - $)
	ret				; rst 10
	.fill	($18 - $)
	ret				; rst 18
	.fill	($20 - $)
	ret				; rst 20
	.fill	($28 - $)
	ret				; rst 28
	.fill	($30 - $)
	ret				; rst 30
	.fill	($38 - $)
#if (BIOS == BIOS_WBW)
  #if (INTMODE == 1)
	jp	int_im1			; go to handler in hi mem
  #else
	ret				; return w/ ints left disabled
  #endif
#else
	ret				; return w/ ints disabled
#endif
	.fill	($66 - $)
	retn				; nmi
;
	.fill	($100 - $)		; pad remainder of page zero
;
;=======================================================================
; Startup and loader initialization
;=======================================================================
;
; Note: at startup, we should not assume which bank we are operating in.
;
	; Relocate to start of common ram at $8000
	ld	hl,0
	ld	de,$8000
	ld	bc,LDR_SIZ
	ldir
;
	jp	start
;
	.ORG	$8000 + $
;
start:
	ld	sp,bl_stack		; setup private stack
	call	DELAY_INIT		; init delay functions
;
; Disable interrupts if IM1 is active because we are switching to page
; zero in user bank and it has not been prepared with IM1 vector yet.
;
#if (INTMODE == 1)
	di
#endif
;
; Switch to user RAM bank
;
#if (BIOS == BIOS_WBW)
	ld	b,BF_SYSSETBNK		; HBIOS func: set bank
	ld	c,BID_USR		; select user bank
	rst	08			; do it
	ld	a,c			; previous bank to A
	ld	(bid_ldr),a		; save previous bank for later
	cp	BID_IMG0		; starting from ROM?
#endif
;
#if (BIOS == BIOS_UNA)
	ld	bc,$01FB		; UNA func: set bank
	ld	de,BID_USR		; select user bank
	rst	08			; do it
	ld	(bid_ldr),de		; ... for later
	ld	a,d			; starting from ROM?
	or	e			; ... bank == 0?
#endif
;
	; For app mode startup, use alternate table
	ld	hl,ra_tbl		; assume ROM startup
	jr	z,start1		; if so, ra_tbl OK, skip ahead
	ld	hl,ra_tbl_app		; not ROM boot, get app tbl loc
start1:
	ld	(ra_tbl_loc),hl		; and overlay pointer
;
; Copy original page zero into user page zero
;
	ld	hl,$8000		; page zero was copied here
	ld	de,0			; put it in user page zero
	ld	bc,$100			; full page
	ldir				; do it
;
; Page zero in user bank is ready for interrupts now.
;
#if (INTMODE == 1)
	ei
#endif
;
;=======================================================================
; Loader prompt
;=======================================================================
;
	call	nl2			; formatting
	ld	hl,str_banner		; display boot banner
	call	pstr			; do it
	call	clrbuf			; zero fill the cmd buffer
;

#ifdef BOOT_DEFAULT_FORCE
	or	$FF			; auto cmd active value
	ld	(acmd_act),a		; set flag
	jp	autocmd
#else
#if (BOOT_TIMEOUT > 0)
	; Initialize auto command timeout downcounter
	or	$FF			; auto cmd active value
	ld	(acmd_act),a		; set flag
	ld	bc,BOOT_TIMEOUT * 100	; hundredths of seconds
	ld	(acmd_to),bc		; save auto cmd timeout
#endif
#endif
;
prompt:
	ld	hl,reprompt		; adr of prompt restart routine
	push	hl			; put it on stack
	call	nl2			; formatting
	ld	hl,str_prompt		; display boot prompt
	call	pstr			; do it
	call	clrbuf			; zero fill the cmd buffer
;
#if (DSKYENABLE)
	call	DSKY_RESET		; clear DSKY
	ld	hl,msg_sel		; boot select msg
	call	DSKY_SHOWSEG		; show on DSKY
#endif
;
wtkey:
	; wait for a key or timeout
	call	cst			; check for keyboard key
	jr	nz,concmd		; if pending, do console command
;
#if (DSKYENABLE)
	call	DSKY_STAT		; check DSKY for keypress
	or	a			; set flags
	jp	nz,dskycmd		; if pending, do DSKY command
#endif
;
#if (BOOT_TIMEOUT > 0)
	; check for timeout and handle auto boot here
	ld	a,(acmd_act)		; get auto cmd active flag
	or	a			; set flags
	jr	z,wtkey			; if not active, just loop
	ld	bc,(acmd_to)		; load timeout value
	ld	a,b			; test for
	or	c			; ... zero
	jr	z,autocmd		; if so, handle it
	dec	bc			; decrement
	ld	(acmd_to),bc		; resave it
	ld	de,625			; 16us * 625 = 10ms
	call	VDELAY			; 10ms delay
#endif
;
	jr	wtkey			; loop
;
reprompt:
	xor	a			; zero accum
	ld	(acmd_act),a		; set auto cmd inactive
	jr	prompt			; back to loader prompt
;
clrbuf:
	ld	hl,cmdbuf
	ld	b,bufsiz
	xor	a
clrbuf1:
	ld	(hl),a
	djnz	clrbuf1
	ret
;
;=======================================================================
; Process a command line from buffer
;=======================================================================
;
concmd:
	call	clrled			; clear LEDs
;
	; Get a command line from console and handle it
	call	rdln			; get a line from the user
	ld	de,cmdbuf		; point to buffer
	call	skipws			; skip whitespace
	or	a			; set flags to check for null
	jr	nz,runcmd		; got a cmd, process it
	; if no cmd entered, fall thru to process default cmd
;
autocmd:
	; Copy autocmd string to buffer and process it
#ifndef BOOT_DEFAULT_FORCE
	ld	hl,acmd			; auto cmd string
	call	pstr			; display it
#endif
	ld	hl,acmd			; auto cmd string
	ld	de,cmdbuf		; cmd buffer adr
	ld	bc,acmd_len		; auto cmd length
	ldir				; copy to command line buffer
;
runcmd:
	; Process command line
;
	ld	de,cmdbuf		; point to start of buf
	call	skipws			; skip whitespace
	or	a			; check for null terminator
	ret	z			; if empty line, just bail out
	ld	a,(de)			; get character
	call	upcase			; make upper case
;
	; Attempt built-in commands
	cp	'H'			; H = display help
	jp	z,help			; if so, do it
	cp	'?'			; '?' alias for help
	jp	z,help			; if so, do it
	cp	'L'			; L = List ROM applications
	jp	z,applst		; if so, do it
	cp	'D'			; D = device inventory
	jp	z,devlst		; if so, do it
	cp	'R'			; R = reboot system
	jp	z,reboot		; if so, do it
#if (BIOS == BIOS_WBW)
	cp	'I'			; C = set console interface
	jp	z,setcon		; if so, do it
#endif
;
	; Attempt ROM application launch
	ld	ix,(ra_tbl_loc)		; point to start of ROM app tbl
	ld	c,a			; save command in C
runcmd1:
	ld	a,(ix+ra_conkey)	; get match char
	and	~$80			; clear "hidden entry" bit
	cp	c			; compare
	jp	z,romload		; if match, load it
	ld	de,ra_entsiz		; table entry size
	add	ix,de			; bump IX to next entry
	ld	a,(ix)			; check for end
	or	(ix+1)			; ... of table
	jr	nz,runcmd1		; loop till done
;
	; Attempt disk boot
	ld	de,cmdbuf		; start of buffer
	call	skipws			; skip whitespace
	call	isnum			; do we have a number?
	jp	nz,err_invcmd		; invalid format if empty
	call	getnum			; parse a number
	jp	c,err_invcmd		; handle overflow error
	ld	(bootunit),a		; save boot unit
	xor	a			; zero accum
	ld	(bootslice),a		; save default slice
	call	skipws			; skip possible whitespace
	ld	a,(de)			; get separator char
	or	a			; test for terminator
	jp	z,diskboot		; if so, boot the disk unit
	cp	'.'			; otherwise, is '.'?
	jr	z,runcmd2		; yes, handle slice spec
	cp	':'			; or ':'?
	jr	z,runcmd2		; alt sep for slice spec
	jp	err_invcmd		; if not, format error
runcmd2:
	inc	de			; bump past separator
	call	skipws			; skip possible whitespace
	call	isnum			; do we have a number?
	jp	nz,err_invcmd		; if not, format error
	call	getnum			; get number
	jp	c,err_invcmd		; handle overflow error
	ld	(bootslice),a		; save boot slice
	jp	diskboot		; boot the disk unit/slice
;
;=======================================================================
; Process a DSKY command from key in A
;=======================================================================
;
#if (DSKYENABLE)
;
dskycmd:
	call	clrled			; clear LEDs
;
	call	DSKY_GETKEY		; get DSKY key
	cp	$FF			; check for error
	ret	z			; abort if so
;
	; Attempt built-in commands
	cp	KY_BO			; reboot system
	jp	z,reboot		; if so, do it
;
	; Attempt ROM application launch
	ld	ix,(ra_tbl_loc)		; point to start of ROM app tbl
	ld	c,a			; save DSKY key in C
dskycmd1:
	ld	a,(ix+ra_dskykey)	; get match char
	cp	c			; compare
	jp	z,romload		; if match, load it
	ld	de,ra_entsiz		; table entry size
	add	ix,de			; bump IX to next entry
	ld	a,(ix)			; check for end
	or	(ix+1)			; ... of table
	jr	nz,dskycmd1		; loop till done
;
	; Attempt disk boot
	ld	a,c			; copy key to A
	cp	KY_F + 1		; over max?
	ret	nc			; abort if so
	ld	(bootunit),a		; set as boot unit
	xor	a			; zero A
	ld	(bootslice),a		; boot slice always zero here
	jp	diskboot		; go do it
;
#endif
;
;=======================================================================
; Special command processing
;=======================================================================
;
; Display Help
;
help:
	ld	hl,str_help		; point to help string
	call	pstr			; display it
	ret
;
; List ROM apps
;
applst:
	ld	hl,str_applst
	call	pstr
	call	nl
	ld	ix,(ra_tbl_loc)
applst1:
	; check for end of table
	ld	a,(ix)
	or	(ix+1)
	ret	z
;
	ld	a,(ix+ra_conkey)
	bit	7,a
	jr	nz,applst2
	push	af
	call	nl
	ld	a,' '
	call	cout
	call	cout
	pop	af
	call	cout
	ld	a,':'
	call	cout
	ld	a,' '
	call	cout
	ld	l,(ix+ra_name)
	ld	h,(ix+ra_name+1)
	call	pstr
;
applst2:
	ld	bc,ra_entsiz
	add	ix,bc
	jr	applst1

	ret
;
; Device list
;
devlst:
	ld	hl,str_devlst		; device list header string
	call	pstr			; display it
	jp	prtall			; do it
;
; Set console interface unit
;
#if (BIOS == BIOS_WBW)
;
setcon:
	; On entry DE is expected to be pointing to start
	; of command
	call	findws			; skip command
	call	skipws			; and skip it
	call	isnum			; do we have a number?
	jp	nz,err_invcmd		; if not, invalid
	call	getnum			; parse number into A
	jp	c,err_nocon		; handle overflow error
;
	; Check against max char unit
	push	af			; save requested unit
	ld	b,BF_SYSGET		; HBIOS func: SYS GET
	ld	c,BF_SYSGET_CIOCNT	; HBIOS subfunc: CIO unit count
	rst	08			; E := unit count
	pop	af			; restore requested unit
	cp	e			; compare
	jp	nc,err_nocon		; handle invalid unit
;
	; Notify user, we're outta here....
	push	af			; save new console unit
	ld	hl,str_newcon		; new console msg
	call	pstr			; print string on cur console
	pop	af			; restore new console unit
	call	PRTDECB			; print unit num
;
	; Set console unit
	ld	b,BF_SYSPOKE		; HBIOS func: POKE
	ld	d,BID_BIOS		; BIOS bank
	ld	e,a			; Char unit value
	ld	hl,HCB_LOC + HCB_CONDEV	; Con unit num in HCB
	rst	08			; do it
;
	; Display loader prompt on new console
	call	nl2			; formatting
	ld	hl,str_banner		; display boot banner
	call	pstr			; do it
;
	ret				; done
;
#endif
;
; Restart system
;
reboot:
	ld	hl,str_reboot		; point to message
	call	pstr			; print it
	call	LDELAY			; wait for message to display
;
#if (BIOS == BIOS_WBW)
;
#if (DSKYENABLE)
	ld	hl,msg_boot		; point to boot message
	call	DSKY_SHOWSEG		; display message
#endif
;
	; switch to rom bank 0 and jump to address 0
	ld	a,BID_BOOT		; boot bank
	ld	hl,0			; address zero
	call	HB_BNKCALL		; does not return
#endif
;
#if (BIOS == BIOS_UNA)
	; switch to rom bank 0 and jump to address 0
	ld	bc,$01FB		; UNA func = set bank
	ld	de,0			; ROM bank 0
	rst	08			; do it
	jp	0			; jump to restart address
#endif
;
;=======================================================================
; Load and run a ROM application, IX=ROM app table entry
;=======================================================================
;
romload:
;
	; Notify user
	ld	hl,str_load
	call	pstr
	ld	l,(ix+ra_name)
	ld	h,(ix+ra_name+1)
	call	pstr
;
#if (DSKYENABLE)
	ld	hl,msg_load		; point to load message
	call	DSKY_SHOWSEG		; display message
#endif
;
#if (BIOS == BIOS_WBW)
;
	; Copy image to it's running location
	ld	a,(ix+ra_bnk)		; get image source bank id
	cp	bid_cur			; special value?
	jr	nz,romload1		; if not, continue
	ld	a,(bid_ldr)		; else substitute
romload1:
	push	af			; save source bank
	ld	e,a			; source bank to E
	ld	d,BID_USR		; dest is user bank
	ld	l,(ix+ra_siz)		; HL := image size
	ld	h,(ix+ra_siz+1)		; ...
	ld	b,BF_SYSSETCPY		; HBIOS func: setup bank copy
	rst	08			; do it
	ld	a,'.'			; dot character
	call	cout			; show progress
	ld	e,(ix+ra_dest)		; DE := run dest adr
	ld	d,(ix+ra_dest+1)	; ...
	ld	l,(ix+ra_src)		; HL := image source adr
	ld	h,(ix+ra_src+1)		; ...
	ld	b,BF_SYSBNKCPY		; HBIOS func: bank copy
	rst	08			; do it
	ld	a,'.'			; dot character
	call	cout			; show progress
;
	; Record boot information
	pop	af			; recover source bank
	ld	l,a			; L := source bank
	ld	de,$0100		; boot volume/slice
	ld	b,BF_SYSSET		; HBIOS func: system set
	ld	c,BF_SYSSET_BOOTINFO	; BBIOS subfunc: boot info
	rst	08			; do it
	ld	a,'.'			; dot character
	call	cout			; show progress
;
#endif
;
#if (BIOS == BIOS_UNA)
;
; Note: UNA has no interbank memory copy, so we can only load
; images from the current bank.	 We switch to the original bank
; use a simple ldir to relocate the image, then switch back to the
; user bank to launch.	This will only work if the images are in
; the lower 32K and the relocation adr is in the upper 32K.
;
	; Switch to original bank
	ld	bc,$01FB		; UNA func: set bank
	ld	de,(bid_ldr)		; select user bank
	rst	08			; do it
	ld	a,'.'			; dot character
	call	cout			; show progress
;
	; Copy image to running location
	ld	l,(ix+ra_src)		; HL := image source adr
	ld	h,(ix+ra_src+1)		; ...
	ld	e,(ix+ra_dest)		; DE := run dest adr
	ld	d,(ix+ra_dest+1)	; ...
	ld	c,(ix+ra_siz)		; BC := image size
	ld	b,(ix+ra_siz+1)		; ...
	ldir				; copy image
	ld	a,'.'			; dot character
	call	cout			; show progress
;
	; Switch back to user bank
	ld	bc,$01FB		; UNA func: set bank
	ld	de,(bid_ldr)		; select user bank
	rst	08			; do it
	ld	a,'.'			; dot character
	call	cout			; show progress
;
	; Record boot information
	ld	de,(bid_ldr)		; original bank
	ld	l,$01			; encoded boot slice/unit
	ld	bc,$01FC		; UNA func: set bootstrap hist
	rst	08			; call una
;
#endif
;
#if (DSKYENABLE)
	ld	hl,msg_go		; point to go message
	call	DSKY_SHOWSEG		; display message
#endif
;
	ld	l,(ix+ra_ent)		; HL := app entry address
	ld	h,(ix+ra_ent+1)		; ...
	jp	(hl)			; go
;
;=======================================================================
; Boot disk unit/slice
;=======================================================================
;
diskboot:
;
	; Notify user
	ld	hl,str_boot1
	call	pstr
	ld	a,(bootunit)
	call	PRTDECB
	ld	hl,str_boot2
	call	pstr
	ld	a,(bootslice)
	call	PRTDECB
;
#if (DSKYENABLE)
	ld	hl,msg_load		; point to load message
	call	DSKY_SHOWSEG		; display message
#endif
;
#if (BIOS == BIOS_WBW)
;
	; Check that drive actually exists
	ld	c,a			; put in C for func call
	ld	b,BF_SYSGET		; HBIOS func: sys get
	ld	c,BF_SYSGET_DIOCNT	; HBIOS sub-func: disk count
	rst	08			; do it, E=disk count
	ld	a,(bootunit)		; get boot disk unit
	cp	e			; compare to count
	jp	nc,err_nodisk		; handle no disk err
;
	; If non-zero slice requested, confirm device can handle it
	ld	a,(bootslice)		; get slice
	or	a			; set flags
	jr	z,diskboot1		; slice 0, skip slice check
	ld	a,(bootunit)		; get disk unit
	ld	c,a			; put in C for func call
	ld	b,BF_DIODEVICE		; HBIOS func: device info
	rst	08			; do it
	ld	a,d			; device type to A
	cp	DIODEV_IDE		; IDE is max slice device type
	jp	c,err_noslice		; no such slice, handle err
;
diskboot1:
	; Sense media
	ld	a,(bootunit)		; get boot disk unit
	ld	c,a			; put in C for func call
	ld	b,BF_DIOMEDIA		; HBIOS func: media
	ld	e,1			; enable media check/discovery
	rst	08			; do it
	jp	nz,err_diskio		; handle error
	call	pdot			; show progress
;
	; Seek to boot info sector, third sector
	ld	a,(bootslice)		; get boot slice
	ld	e,a			; move to E for mult
	ld	h,65			; 65 tracks per slice
	call	MULT8			; hl := h * e
	ld	de,$0002		; head 0, sector 2
	ld	b,BF_DIOSEEK		; HBIOS func: seek
	ld	a,(bootunit)		; get boot disk unit
	ld	c,a			; put in C
	rst	08			; do it
	jp	nz,err_diskio		; handle error
	call	pdot			; show progress
;
	; Read sector into local buffer
	ld	b,BF_DIOREAD		; HBIOS func: disk read
	ld	a,(bootunit)		; get boot disk unit
	ld	c,a			; put in C for func call
	ld	hl,bl_infosec		; read into info sec buffer
	ld	d,BID_USR		; user bank
	ld	e,1			; transfer one sector
	rst	08			; do it
	jp	nz,err_diskio		; handle error
	call	pdot			; show progress
;
#endif
;
#if (BIOS == BIOS_UNA)
;
	; Check that drive actually exists
	ld	a,(bootunit)		; get disk unit to boot
	ld	b,a			; put in B for func call
	ld	c,$48			; UNA func: get disk type
	rst	08			; call UNA, B preserved
	jp	nz,err_nodisk		; handle error if no such disk
;
	; If non-zero slice requested, confirm device can handle it
	ld	a,(bootslice)		; get slice
	or	a			; set flags
	jr	z,diskboot1		; slice 0, skip slice check
	ld	a,d			; disk type to A
	cp	$41			; IDE?
	jr	z,diskboot1		; if so, OK
	cp	$42			; PPIDE?
	jr	z,diskboot1		; if so, OK
	cp	$43			; SD?
	jr	z,diskboot1		; if so, OK
	cp	$44			; DSD?
	jr	z,diskboot1		; if so, OK
	jp	err_noslice		; no such slice, handle err
;
diskboot1:
	; Add slice offset
	ld	a,(bootslice)		; get boot slice, A is loop cnt
	ld	hl,0			; DE:HL is LBA
	ld	de,0			; ... initialize to zero
	ld	bc,16640		; sectors per slice
diskboot2:
	or	a			; set flags to check loop ctr
	jr	z,diskboot4		; done if counter exhausted
	add	hl,bc			; add one slice to low word
	jr	nc,diskboot3		; check for carry
	inc	de			; if so, bump high word
diskboot3:
	dec	a			; dec loop downcounter
	jr	diskboot2		; and loop
;
diskboot4:
	ld	(loadlba),hl		; save lba, low word
	ld	(loadlba+2),de		; save lba, high word
;
	; Seek to boot info sector, third sector
	ld	bc,2			; sector offset
	add	hl,bc			; add to LBA value low word
	jr	nc,diskboot5		; check for carry
	inc	de			; if so, bump high word
diskboot5:
	ld	a,(bootunit)		; get disk unit to boot
	ld	b,a			; put in B for func call
	ld	c,$41			; UNA func: set lba
	rst	08			; set lba
	jp	nz,err_api		; handle error
	call	pdot			; show progress
;
	; Read sector into local buffer
	ld	c,$42			; UNA func: read sectors
	ld	de,bl_infosec		; dest of cpm image
	ld	l,1			; sectors to read
	rst	08			; do read
	jp	nz,err_diskio		; handle error
;
#endif
;
	; Check signature
	ld	de,(bb_sig)		; get signature read
	ld	a,$A5			; expected value of first byte
	cp	d			; compare
	jp	nz,err_sig		; handle error
	ld	a,$5A			; expected value of second byte
	cp	e			; compare
	jp	nz,err_sig		; handle error
;
	; Print disk boot info
	; Volume "xxxxxxx" (0xXXXX-0xXXXX, entry @ 0xXXXX)
	ld	hl,str_binfo1		; load string
	call	pstr			; print
	push	hl			; save string ptr
	ld	hl,bb_label		; point to label
	call	pvol			; print it
	pop	hl			; restore string ptr
	call	pstr			; print
	push	hl			; save string ptr
	ld	bc,(bb_cpmloc)		; get load loc
	call	PRTHEXWORD		; print it
	pop	hl			; restore string ptr
	call	pstr			; print
	push	hl			; save string ptr
	ld	bc,(bb_cpmend)		; get load end
	call	PRTHEXWORD		; print it
	pop	hl			; restore string ptr
	call	pstr			; print
	push	hl			; save string ptr
	ld	bc,(bb_cpment)		; get load end
	call	PRTHEXWORD		; print it
	pop	hl			; restore string ptr
	call	pstr			; print
;
	; Compute number of sectors to load
	ld	hl,(bb_cpmend)		; hl := end
	ld	de,(bb_cpmloc)		; de := start
	or	a			; clear carry
	sbc	hl,de			; hl := length to load
	ld	a,h			; determine 512 byte sector count
	rra				; ... by dividing msb by two
	ld	(loadcnt),a		; ... and save it
	call	pdot			; show progress
;
#if (BIOS == BIOS_WBW)
;
	; Load image into memory
	ld	b,BF_DIOREAD		; HBIOS func: read sectors
	ld	a,(bootunit)		; get boot disk unit
	ld	c,a			; put in C
	ld	hl,(bb_cpmloc)		; load address
	ld	d,BID_USR		; user bank
	ld	a,(loadcnt)		; get sectors to read
	ld	e,a			; number of sectors to load
	rst	08			; do it
	jp	nz,err_diskio		; handle errors
	call	pdot			; show progress
;
	; Record boot unit/slice
	ld	b,BF_SYSSET		; hb func: set hbios parameter
	ld	c,BF_SYSSET_BOOTINFO	; hb subfunc: set boot info
	ld	a,(bid_ldr)		; original bank is boot bank
	ld	l,a			; ... and save as boot bank
	ld	a,(bootunit)		; load boot unit
	ld	d,a			; save in D
	ld	a,(bootslice)		; load boot slice
	ld	e,a			; save in E
	rst	08
	jp	nz,err_api		; handle errors
	call	pdot			; show progress
;
#endif
;
#if (BIOS == BIOS_UNA)
;
	; Start os load at sector 3
	ld	hl,(loadlba)		; low word of saved LBA
	ld	de,(loadlba+2)		; high word of saved LBA
	ld	bc,3			; offset for sector 3
	add	hl,bc			; apply it
	jr	nc,diskboot6		; check for carry
	inc	de			; bump high word if so
diskboot6:
	ld	c,$41			; UNA func: set lba
	ld	a,(bootunit)		; get boot disk unit
	ld	b,a			; move to B
	rst	08			; set lba
	jp	nz,err_api		; handle error
;
	; Read OS image into memory
	ld	c,$42			; UNA func: read sectors
	ld	a,(bootunit)		; get boot disk unit
	ld	b,a			; move to B
	ld	de,(bb_cpmloc)		; dest of cpm image
	ld	a,(loadcnt)		; get sectors to read
	ld	l,a			; sectors to read
	rst	08			; do read
	jp	nz,err_diskio		; handle error
	call	pdot			; show progress
;
	; Record boot unit/slice
	; UNA provides only a single byte to record the boot unit
	; so we encode the unit/slice into one byte by using the
	; high nibble for unit and low nibble for slice.
	ld	de,-1			; boot rom page, -1 for n/a
	ld	a,(bootslice)		; get boot slice
	and	$0F			; 4 bits only
	rlca				; rotate to high bits
	rlca				; ...
	rlca				; ...
	rlca				; ...
	ld	l,a			; put in L
	ld	a,(bootunit)		; get boot disk unit
	and	$0F			; 4 bits only
	or	l			; combine
	ld	l,a			; back to L
	ld	bc,$01FC		; UNA func: set bootstrap hist
	rst	08			; call UNA
	jp	nz,err_api		; handle error
	call	pdot			; show progress
;
#endif
;
#if (DSKYENABLE)
	ld	hl,msg_go		; point to go message
	call	DSKY_SHOWSEG		; display message
#endif
;
	; Jump to entry vector
	ld	hl,(bb_cpment)		; get entry vector
	jp	(hl)			; and go there
;
;=======================================================================
; Utility functions
;=======================================================================
;
; Clear LEDs
;
clrled:
#if (BIOS == BIOS_WBW)
  #if (DIAGENABLE)
	xor	a		; zero accum
	out	(DIAGPORT),a	; clear diag leds
  #endif
  #if (LEDENABLE)
	or	$FF		; led is inverted
	out	(LEDPORT),a	; clear led
  #endif
#endif
	ret
;
; Print string at HL on console, null terminated
;
pstr:
	ld	a,(hl)			; get next character
	or	a			; set flags
	inc	hl			; bump pointer regardless
	ret	z			; done if null
	call	cout			; display character
	jr	pstr			; loop till done
;
; Print volume label string at HL, '$' terminated, 16 chars max
;
pvol:
	ld	b,16			; init max char downcounter
pvol1:
	ld	a,(hl)			; get next character
	cp	'$'			; set flags
	inc	hl			; bump pointer regardless
	ret	z			; done if null
	call	cout			; display character
	djnz	pvol1			; loop till done
	ret				; hit max of 16 chars
;
; Start a newline on console (cr/lf)
;
nl2:
	call	nl			; double newline
nl:
	ld	a,cr			; cr
	call	cout			; send it
	ld	a,lf			; lf
	jp	cout			; send it and return
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
; Read a string on the console
;
; Uses address $0080 in page zero for buffer
; Input is zero terminated
;
rdln:
	ld	de,cmdbuf		; init buffer address ptr
rdln_nxt:
	call	cin			; get a character
	cp	bs			; backspace?
	jr	z,rdln_bs		; handle it if so
	cp	cr			; return?
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
	call	cout			; echo character input
	ld	(de),a			; save in buffer
	inc	de			; inc buffer ptr
	jr	rdln_nxt		; loop till done
;
rdln_bs:
	ld	hl,cmdbuf			; start of buffer
	or	a			; clear carry
	sbc	hl,de			; subtract from cur buf ptr
	jr	z,rdln_bel		; at buf start, just beep
	ld	hl,str_bs		; backspace sequence
	call	pstr			; send it
	dec	de			; backup buffer pointer
	jr	rdln_nxt		; and loop
;
rdln_bel:
	ld	a,bel			; Bell characters
	call	cout			; send it
	jr	rdln_nxt		; and loop
;
rdln_cr:
	xor	a			; null to A
	ld	(de),a			; store terminator
	ret				; and return
;
; Find next whitespace character at buffer adr in DE, returns with first
; whitespace character in A.
;
findws:
	ld	a,(de)			; get next char
	cp	' '			; blank?
	ret	z			; nope, done
	inc	de			; bump buffer pointer
	jr	findws			; and loop
;
; Skip whitespace at buffer adr in DE, returns with first
; non-whitespace character in A.
;
skipws:
	ld	a,(de)			; get next char
	cp	' '			; blank?
	ret	nz			; nope, done
	inc	de			; bump buffer pointer
	jr	skipws			; and loop
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
; Is character in A numberic? NZ if not
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
;=======================================================================
; Console character I/O helper routines (registers preserved)
;=======================================================================
;
#if (BIOS == BIOS_WBW)
;
; Output character from A
;
cout:
	; Save all incoming registers
	push	af
	push	bc
	push	de
	push	hl
;
	; Output character to console via HBIOS
	ld	e,a			; output char to E
	ld	c,CIO_CONSOLE		; console unit to C
	ld	b,BF_CIOOUT		; HBIOS func: output char
	rst	08			; HBIOS outputs character
;
	; Restore all registers
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
; Input character to A
;
cin:
	; Save incoming registers (AF is output)
	push	bc
	push	de
	push	hl
;
	; Input character from console via hbios
	ld	c,CIO_CONSOLE		; console unit to c
	ld	b,BF_CIOIN		; HBIOS func: input char
	rst	08			; HBIOS reads charactdr
	ld	a,e			; move character to A for return
;
	; Restore registers (AF is output)
	pop	hl
	pop	de
	pop	bc
	ret
;
; Return input status in A (0 = no char, != 0 char waiting)
;
cst:
	; Save incoming registers (AF is output)
	push	bc
	push	de
	push	hl
;
	; Get console input status via HBIOS
	ld	c,CIO_CONSOLE		; console unit to C
	ld	b,BF_CIOIST		; HBIOS func: input status
	rst	08			; HBIOS returns status in A
;
	; Restore registers (AF is output)
	pop	hl
	pop	de
	pop	bc
	ret
;
#endif
;
#if (BIOS == BIOS_UNA)
;
; Output character from A
;
cout:
	; Save all incoming registers
	push	af
	push	bc
	push	de
	push	hl
;
	; Output character to console via UBIOS
	ld	e,a
	ld	bc,$12
	rst	08
;
	; Restore all registers
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
; Input character to A
;
cin:
	; Save incoming registers (AF is output)
	push	bc
	push	de
	push	hl
;
	; Input character from console via UBIOS
	ld	bc,$11
	rst	08
	ld	a,e
;
	; Restore registers (AF is output)
	pop	hl
	pop	de
	pop	bc
	ret
;
; Return input status in A (0 = no char, != 0 char waiting)
;
cst:
	; Save incoming registers (AF is output)
	push	bc
	push	de
	push	hl
;
	; Get console input status via UBIOS
	ld	bc,$13
	rst	08
	ld	a,e
	or	a
;
	; Restore registers (AF is output)
	pop	hl
	pop	de
	pop	bc
	ret
;
#endif
;
; Generic console I/O
;
CIN	.equ	cin
COUT	.equ	cout
CST	.equ	cst
;
;=======================================================================
; Device inventory display
;=======================================================================
;
; Print list of all drives (WBW)
;
#if (BIOS == BIOS_WBW)
;
prtall:
	call	nl			; formatting
	ld	b,BF_SYSGET
	ld	c,BF_SYSGET_DIOCNT
	rst	08			; E := disk unit count
	ld	b,e			; count to B
	ld	a,b			; count to A
	or	a			; set flags
	ret	z			; bail out if zero
	ld	c,0			; init device index
;
prtall1:
	ld	hl,str_disk		; prefix string
	call	pstr			; display it
	ld	a,c			; index
	call	PRTDECB			; print it
	ld	hl,str_on		; separator string
	call	pstr
	push	bc			; save loop control
	ld	b,BF_DIODEVICE		; HBIOS func: report device info
	rst	08			; call HBIOS
	call	prtdrv			; print it
	pop	bc			; restore loop control
	inc	c			; bump index
	djnz	prtall1			; loop as needed
	ret				; done
;
; Print the device info
; On input D has device type, E has device number
; Destroy no registers other than A
;
prtdrv:
	push	de			; preserve de
	push	hl			; preserve HL
	ld	a,d			; load device/unit
	rrca				; rotate device
	rrca				; ... bits
	rrca				; ... into
	rrca				; ... lowest 4 bits
	and	$0F			; isolate device bits
	add	a,a			; multiple by two for word table
	ld	hl,devtbl		; point to start of table
	call	ADDHLA			; add A to HL for table entry
	ld	a,(hl)			; deref HL for string adr
	inc	hl			; ...
	ld	h,(hl)			; ...
	ld	l,a			; ...
	call	pstr			; print the device nmemonic
	pop	hl			; recover HL
	pop	de			; recover DE
	ld	a,e			; device number
	call	PRTDECB			; print it
	ld	a,':'			; suffix
	call	cout			; print it
	ret
;
devtbl:	; device table
	.dw	dev00, dev01, dev02, dev03
	.dw	dev04, dev05, dev06, dev07
	.dw	dev08, dev09, dev10, dev11
	.dw	dev12, dev13, dev14, dev15
;
devunk	.db	"???",0
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
#endif
;
;
;
#if (BIOS == BIOS_UNA)
;
; Print list of all drives (UNA)
;
prtall:
	call	nl			; formatting
	ld	b,0			; start with unit 0
;
prtall1:	; loop thru all units available
	ld	c,$48			; UNA func: get disk type
	ld	l,0			; preset unit count to zero
	rst	08			; call UNA, B preserved
	ld	a,l			; unit count to a
	or	a			; past end?
	ret	z			; we are done
	push	bc			; save unit
	call	prtdrv			; process the unit
	pop	bc			; restore unit
	inc	b			; next unit
	jr	prtall1			; loop
;
; print the una unit info
; on input b has unit
;
prtdrv:
	push	bc			; save unit
	push	de			; save disk type
	ld	hl,str_disk		; prefix string
	call	pstr			; display it
	ld	a,b			; index
	call	PRTDECB			; print it
	ld	a,' '			; formatting
	call	cout			; do it
	ld	a,'='			; formatting
	call	cout			; do it
	ld	a,' '			; formatting
	call	cout			; do it
	pop	de			; recover disk type
	ld	a,d			; disk type to a
	cp	$40			; ram/rom?
	jr	z,prtdrv1		; handle ram/rom
	ld	hl,devide		; assume ide
	cp	$41			; ide?
	jr	z,prtdrv2		; print it
	ld	hl,devppide		; assume ppide
	cp	$42			; ppide?
	jr	z,prtdrv2		; print it
	ld	hl,devsd		; assume sd
	cp	$43			; sd?
	jr	z,prtdrv2		; print it
	ld	hl,devdsd		; assume dsd
	cp	$44			; dsd?
	jr	z,prtdrv2		; print it
	ld	hl,devunk		; otherwise unknown
	jr	prtdrv2
;
prtdrv1:	; handle ram/rom
	ld	c,$45			; una func: get disk info
	ld	de,bl_infosec		; 512 byte buffer
	rst	08			; call una
	bit	7,b			; test ram drive bit
	ld	hl,devrom		; assume rom
	jr	z,prtdrv2		; if so, print it
	ld	hl,devram		; otherwise ram
	jr	prtdrv2			; print it
;
prtdrv2:	; print device
	pop	bc			; recover unit
	call	pstr			; print device name
	ld	a,b			; unit to a
	call	PRTDECB			; print it
	ld	a,':'			; device name suffix
	call	cout			; print it
	ret				; done
;
devram		.db	"RAM",0
devrom		.db	"ROM",0
devide		.db	"IDE",0
devppide	.db	"PPIDE",0
devsd		.db	"SD",0
devdsd		.db	"DSD",0
devunk		.db	"UNK",0
;
#endif
;
;=======================================================================
; Error handlers
;=======================================================================
;
err_invcmd:
	ld	hl,str_err_invcmd
	jr	err
err_nodisk:
	ld	hl,str_err_nodisk
	jr	err
;
err_noslice:
	ld	hl,str_err_noslice
	jr	err
;
err_nocon:
	ld	hl,str_err_nocon
	jr	err
;
err_diskio:
	ld	hl,str_err_diskio
	jr	err
;
err_sig:
	ld	hl,str_err_sig
	jr	err
;
err_api:
	ld	hl,str_err_api
	jr	err
;
err:
	push	hl
;	ld	a,(acmd_act)		; get auto cmd active flag
;	or	a			; set flags
;	call	nz,showcmd		; if auto cmd act, show cmd
;	ld	a,bel			; bel character
;	call	cout			; beep
	ld	hl,str_err_prefix
	call	pstr
	pop	hl
	jp	pstr
;
str_err_prefix	.db	bel,"\r\n\r\n*** ",0
str_err_invcmd	.db	"Invalid command",0
str_err_nodisk	.db	"Disk unit not available",0
str_err_noslice	.db	"Disk unit does not support slices",0
str_err_nocon	.db	"Invalid character unit",0
str_err_diskio	.db	"Disk I/O failure",0
str_err_sig	.db	"No system image on disk",0
str_err_api	.db	"Unexpected hardware BIOS API failure",0
;
;=======================================================================
; Includes
;=======================================================================
;
#define USEDELAY
#include "util.asm"
;
#if (DSKYENABLE)
#define	DSKY_KBD
#include "dsky.asm"
#endif
;
;=======================================================================
; Working data storage (initialized)
;=======================================================================
;
acmd		.db	BOOT_DEFAULT	; auto cmd string
		.db	0
acmd_len	.equ	$ - acmd	; len of auto cmd
acmd_act	.db	$FF		; auto cmd active
acmd_to		.dw	BOOT_TIMEOUT	; auto cmd timeout
;
;=======================================================================
; Strings
;=======================================================================
;
str_banner	.db	PLATFORM_NAME," Boot Loader",0
str_prompt	.db	"Boot [H=Help]: ",0
str_bs		.db	bs,' ',bs,0
str_reboot	.db	"\r\n\r\nRestarting System...",0
str_newcon	.db	"\r\n\r\n  Console on Unit #",0
str_applst	.db	"\r\n\r\nROM Applications:",0
str_devlst	.db	"\r\n\r\nDisk Devices:",0
str_invcmd	.db	"\r\n\r\n*** Invalid Command ***",bel,0
str_load	.db	"\r\n\r\nLoading ",0
str_disk	.db	"\r\n  Disk Unit ",0
str_on		.db	" on ",0
str_boot1	.db	"\r\n\r\nBooting Disk Unit ",0
str_boot2	.db	", Slice ",0
str_binfo1	.db	"\r\n\r\nVolume ",$22,0
str_binfo2	.db	$22," [0x",0
str_binfo3	.db	"-0x",0
str_binfo4	.db	", entry @ 0x",0
str_binfo5	.db	"]",0
;
str_help	.db	"\r\n"
		.db	"\r\n  L         - List ROM Applications"
		.db	"\r\n  D         - Disk Device Inventory"
		.db	"\r\n  R         - Reboot System"
#if (BIOS == BIOS_WBW)
		.db	"\r\n  I <u>     - Set Console Interface"
#endif
		.db	"\r\n  <u>[.<s>] - Boot Disk Unit/Slice"
		.db	0
;
#if (DSKYENABLE)
msg_sel		.db	$ff,$9d,$9d,$8f,$ec,$80,$80,$80	; "boot?   "
msg_boot	.db	$ff,$9d,$9d,$8f,$00,$00,$00,$80	; "boot... "
msg_load	.db	$8b,$9d,$fd,$bd,$00,$00,$00,$80	; "load... "
msg_go		.db	$db,$9d,$00,$00,$00,$80,$80,$80	; "go...   "
#endif
;
;=======================================================================
; ROM Application Table
;=======================================================================
;
; Macro ra_ent:
;
;						WBW		UNA
; p1: Application name string adr		word (+0)	word (+0)
; p2: Console keyboard selection key		byte (+2)	byte (+2)
; p3: DSKY selection key			byte (+3)	byte (+3)
; p4: Application image bank			byte (+4)	word (+4)
; p5: Application image source address		word (+5)	word (+6)
; p6: Application image dest load address	word (+7)	word (+8)
; p7: Application image size			word (+9)	word (+10)
; p8: Application entry address			word (+11)	word (+12)
;
#if (BIOS == BIOS_WBW)
ra_name		.equ	0
ra_conkey	.equ	2
ra_dskykey	.equ	3
ra_bnk		.equ	4
ra_src		.equ	5
ra_dest		.equ	7
ra_siz		.equ	9
ra_ent		.equ	11
#endif
;
#if (BIOS == BIOS_UNA)
ra_name		.equ	0
ra_conkey	.equ	2
ra_dskykey	.equ	3
ra_bnk		.equ	4
ra_src		.equ	6
ra_dest		.equ	8
ra_siz		.equ	10
ra_ent		.equ	12
#endif
;
#define		ra_ent(p1,p2,p3,p4,p5,p6,p7,p8) \
#defcont	.dw	p1 \
#defcont	.db	p2 \
#if (DSKYENABLE)
#defcont	.db	p3 \
#else
#defcont	.db	$FF \
#endif
#if (BIOS == BIOS_WBW)
#defcont	.db	p4 \
#endif
#if (BIOS == BIOS_UNA)
#defcont	.dw	p4 \
#endif
#defcont	.dw	p5 \
#defcont	.dw	p6 \
#defcont	.dw	p7 \
#defcont	.dw	p8
;
; Note: The formatting of the following is critical. TASM does not pass
; macro arguments well. Ensure std.asm holds the definitions for *_LOC,
; *_SIZ *_END and any code generated which does not include std.asm is
; synced.
;
; Note: The loadable ROM images are placed in ROM banks BID_IMG0 and
; BID_IMG1.  However, RomWBW supports a mechanism to load a complete
; new system dynamically as a runnable application (see appboot and
; imgboot in hbios.asm).  In this case, the contents of BID_IMG0 will
; be pre-loaded into the currently executing ram bank thereby allowing
; those images to be dynamically loaded as well.  To support this
; concept, a pseudo-bank called bid_cur is used to specify the images
; normally found in BID_IMG0.  In romload, this special value will cause
; the associated image to be loaded from the currently executing bank
; which will be correct regardless of the load mode.  Images in other
; banks (BID_IMG1) will always be loaded directly from ROM.
;
ra_tbl:
;
;      Name	  Key	   Dsky	  Bank	    Src	   Dest	    Size     Entry
;      ---------  -------  -----  --------  -----  -------  -------  ----------
ra_ent(str_mon,	  'M',	   KY_CL, BID_IMG0, $1000, MON_LOC, MON_SIZ, MON_SERIAL)
ra_entsiz	.equ	$ - ra_tbl
ra_ent(str_cpm22, 'C',	   KY_BK, BID_IMG0, $2000, CPM_LOC, CPM_SIZ, CPM_ENT)
ra_ent(str_zsys,  'Z',	   KY_FW, BID_IMG0, $5000, CPM_LOC, CPM_SIZ, CPM_ENT)
#if (BIOS == BIOS_WBW)
ra_ent(str_fth,	  'F',	   KY_EX, BID_IMG1, $0000, FTH_LOC, FTH_SIZ, FTH_LOC)
ra_ent(str_bas,	  'B',	   KY_DE, BID_IMG1, $1700, BAS_LOC, BAS_SIZ, BAS_LOC)
ra_ent(str_tbas,  'T',	   KY_EN, BID_IMG1, $3700, TBC_LOC, TBC_SIZ, TBC_LOC)
ra_ent(str_play,  'P',	   $FF,	  BID_IMG1, $4000, GAM_LOC, GAM_SIZ, GAM_LOC)
ra_ent(str_user,  'U',	   $FF,	  BID_IMG1, $7000, USR_LOC, USR_SIZ, USR_LOC)
#endif
#if (DSKYENABLE)
ra_ent(str_dsky,  'Y'+$80, KY_GO, bid_cur,  $1000, MON_LOC, MON_SIZ, MON_DSKY)
#endif
ra_ent(str_egg,	  'E'+$80, $FF	, bid_cur,  $0E00, EGG_LOC, EGG_SIZ, EGG_LOC)
		.dw	0		; table terminator
;
ra_tbl_app:
;
;      Name	  Key	   Dsky	  Bank	    Src	   Dest	    Size     Entry
;      ---------  -------  -----  --------  -----  -------  -------  ----------
ra_ent(str_mon,	  'M',	   KY_CL, bid_cur,  $1000, MON_LOC, MON_SIZ, MON_SERIAL)
ra_ent(str_zsys,  'Z',	   KY_FW, bid_cur,  $2000, CPM_LOC, CPM_SIZ, CPM_ENT)
#if (DSKYENABLE)
ra_ent(str_dsky,  'Y'+$80, KY_GO, bid_cur,  $1000, MON_LOC, MON_SIZ, MON_DSKY)
#endif
ra_ent(str_egg,	  'E'+$80, $FF	, bid_cur,  $0E00, EGG_LOC, EGG_SIZ, EGG_LOC)
		.dw	0		; table terminator
;
str_mon		.db	"Monitor",0
str_cpm22	.db	"CP/M 2.2",0
str_zsys	.db	"Z-System",0
str_dsky	.db	"DSKY Monitor",0
str_fth		.db	"Forth",0
str_bas		.db	"BASIC",0
str_tbas	.db	"Tasty BASIC",0
str_play	.db	"Play a Game",0
str_user	.db	"User App",0
str_egg		.db	"",0
;
;=======================================================================
; Pad remainder of ROM Loader
;=======================================================================
;
slack		.equ	($8000 + LDR_SIZ - $)
		.fill	slack
;
		.echo	"LOADER space remaining: "
		.echo	slack
		.echo	" bytes.\n"
;
;=======================================================================
; Working data storage (uninitialized)
;=======================================================================
;
		.ds	64		; 32 level stack
bl_stack	.equ	$		; ... top is here
;
#if (BIOS == BIOS_WBW)
bid_ldr		.ds	1		; bank at startup
#endif
#if (BIOS == BIOS_UNA)
bid_ldr		.ds	2		; bank at startup
loadlba		.ds	4		; lba for load, dword
#endif
;
ra_tbl_loc	.ds	2		; points to active ra_tbl
bootunit	.ds	1		; boot disk unit
bootslice	.ds	1		; boot disk slice
loadcnt		.ds	1		; num disk sectors to load
;
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
	.end
