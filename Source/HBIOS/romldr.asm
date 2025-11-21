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
#include "std.asm"	; standard RomWBW constants
;
; If BOOT_DEFAULT is not defined, just define it to "H" for help.
;
#ifndef BOOT_DEFAULT
  #define BOOT_DEFAULT "H"
#endif
;
; If AUTO_CMD is not defined, just define it as an empty string.
;
#ifndef AUTO_CMD
  #define AUTO_CMD ""
#endif
;
bel	.equ	7	; ASCII bell
bs	.equ	8	; ASCII backspace
lf	.equ	10	; ASCII linefeed
cr	.equ	13	; ASCII carriage return
esc	.equ	27	; ASCII escape
del	.equ	127	; ASCII del/rubout
;
cmdbuf	.equ	$80	; cmd buf is in second half of page zero
cmdmax	.equ	60	; max cmd len (arbitrary), must be < bufsiz
bufsiz	.equ	$80	; size of cmd buf
;
hbx_int		.equ	$FF60	; IM1 vector target for RomWBW HBIOS proxy
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
	call	hbx_int			; handle im1 interrupts
	.db	$10 << 2		; use special vector #16
  #else
	ret				; return w/ ints left disabled
  #endif
#else
	ret				; return w/ ints disabled
#endif
;
#if (BIOS == BIOS_WBW)
	.fill	($40 - $),$FF
	; After initial bootup, it is conventional for a jp 0 to
	; cause a warm start of the system.  If there is no OS running
	; then this bit of code will suffice.  After bootup, the
	; jp instruction at $0 is modified to point here.
	pop	hl			; save PC in case needed for ...
	ld	bc,$F003		; HBIOS user reset function
	call	HB_INVOKE		; do it
	ld	bc,$F001		; HBIOS warm start function
	call	HB_INVOKE		; do it
#endif
;
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
	ld	a,e			; save startup mode
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
	ld	(startmode),a		; save startup mode
	call	delay_init		; init delay functions
;
; Disable interrupts if IM1 is active because we are switching to page
; zero in user bank and it has not been prepared with IM1 vector yet.
;
#if (INTMODE == 1)
	di
#endif
;
; Switch to user RAM bank and establish boot mode
;
#if (BIOS == BIOS_WBW)
	; Get the boot mode
	ld	b,BF_SYSPEEK		; HBIOS func: PEEK
	ld	d,BID_BIOS		; BIOS bank
	ld	hl,HCB_LOC + HCB_BOOTMODE	; boot mode byte
	rst	08
	ld	a,e			; put in A
	ld	(bootmode),a		; save it
;
	ld	b,BF_SYSSETBNK		; HBIOS func: set bank
	ld	c,BID_USR		; select user bank
	rst	08			; do it
	ld	a,c			; previous bank to A
	ld	(bid_ldr),a		; save previous bank for later
#endif
;
#if (BIOS == BIOS_UNA)
	ld	bc,$01FB		; UNA func: set bank
	ld	de,BID_USR		; select user bank
	rst	08			; do it
	ld	(bid_ldr),de		; save previous bank for later
;
	ld	a,BM_ROMBOOT		; assume ROM boot
	bit	7,d			; starting from ROM?
	jr	z,start1		; if so, skip ahead
	ld	a,BM_APPBOOT		; else this is APP boot
start1:
	ld	(bootmode),a		; save it
#endif
;
	; For app mode startup, use alternate table
	ld	hl,ra_tbl		; assume ROM application table
	ld	a,(bootmode)		; get boot mode
	cp	BM_ROMBOOT		; ROM boot?
	jr	z,start2		; if so, ra_tbl OK, skip ahead
	ld	hl,ra_tbl_app		; switch to RAM application table
start2:
	ld	(ra_tbl_loc),hl		; and overlay pointer
;
; Copy original page zero into user page zero
;
	ld	hl,$8000		; page zero was copied here
	ld	de,0			; put it in user page zero
	ld	bc,$100			; full page
	ldir				; do it
	ld	hl,$0040		; adr of user reset code
	ld	(1),hl			; save at $0000
;
; Page zero in user bank is ready for interrupts now.
;
#if (INTMODE == 1)
	ei
#endif
;
#if (BIOS == BIOS_WBW)
	; Get the current console unit
	ld	b,BF_SYSPEEK		; HBIOS func: PEEK
	ld	d,BID_BIOS		; BIOS bank
	ld	hl,HCB_LOC + HCB_CONDEV	; console unit num in HCB
	rst	08			; do it
	ld	a,e			; put in A
	ld	(curcon),a		; save it
;
	; Get character unit count
	ld	b,BF_SYSGET		; HBIOS func: SYS GET
	ld	c,BF_SYSGET_CIOCNT	; HBIOS subfunc: CIO unit count
	rst	08			; E := unit count
	ld	a,e			; put in A
	ld	(ciocnt),a		; save it
;
	; Check for DSKY and set flag
	ld	b,BF_SYSGET		; HBIOS func: get
	ld	c,BF_SYSGET_DSKYCNT	; get DSKY count
	rst	08			; do it
	ld	a,e			; put in A
	ld	(dskyact),a		; save it
#endif

;
;=======================================================================
; Print Device List
;=======================================================================
;
#if (BIOS == BIOS_WBW)
;
	; We don't have a start mode for UNA.  So, the device display
	; will only occur when selected from the menu.
	ld	a,(startmode)		; get start mode
	cp	START_COLD		; cold start?
	call	z,prtall		; if so, display Device List.
;
#endif
;
;=======================================================================
; Boot Loader Banner
;=======================================================================
;
	call	nl2			; formatting
	ld	hl,str_banner		; display boot banner
	call	pstr			; do it
	ld	a,(bootmode)		; get app boot flag
	cp	BM_APPBOOT		; APP boot?
	ld	hl,str_appboot		; signal application boot mode
	call	z,pstr			; print if APP boot
	call	clrbuf			; zero fill the cmd buffer
;
;=======================================================================
; Front Panel Boot Setup
;=======================================================================
;
#if ((BIOS == BIOS_WBW) & FPSW_ENABLE)
;
	ld	b,BF_SYSGET		; HBIOS SysGet
	ld	c,BF_SYSGET_PANEL	; ... Panel swiches value
	rst	08			; do it
	jr	nz,nofp			; no switches, skip over
	ld	a,l			; put value in A
	ld	(switches),a		; save it
;
	call	nl			; formatting
	ld	hl,str_switches		; tag
	call	pstr			; display
	ld	a,(switches)		; get switches value
	call	prthexbyte		; display
;
	ld	a,(switches)		; get switches value
	and	SW_AUTO			; auto boot?
	call	nz,runfp		; process front panel
	jp	nz,prompt		; on failure, restart at prompt
;
nofp:
	; fall thru
;
#endif
;
;=======================================================================
; NVRAM Auto Boot Setup
;=======================================================================
;
#if (BIOS == BIOS_WBW)
;
nvrswitch:
	ld	bc,BC_SYSGET_SWITCH	; HBIOS SysGet NVRAM Switches
	ld	d,$FF			; get NVR Status - Is NVRam initialised
	rst	08
	cp	'W'			; is NV RAM fully inited.
	jr	nz,nonvrswitch		; NOT So - Skip the int from nvram
;
nvrsw_def:
	call	nl			; display message to indicate switches found
	ld	hl,str_nvswitches
	call	pstr
;
nvrsw_auto:
	ld	bc,BC_SYSGET_SWITCH	; HBIOS SysGet NVRAM Switches
	ld	d,NVSW_AUTOBOOT		; GET Autoboot switch
	rst	08
	ld	a,l
	and	ABOOT_AUTO		; Get the autoboot flag
;
; At this point, we know that NVR is valid and the ABOOT_AUTO bit has
; been tested.  If ABOOT_AUTO is not set, we can either go directly to
; Boot Loader command prompt (prompt) or try to process ROM config
; auto command line (nonvrswitch).  I have not decided what is
; best yet.  For now, we process ROM autoboot because it
; makes my testing easier.  :-)
;
	;;;jp	z,prompt		; Bypass ROM config auto cmd
	jr	z,nonvrswitch		; Proceed to ROM config autoboot
;
	ld	a,l			; the low order byte from SWITCHES
	and	ABOOT_TIMEOUT		; Mask out the Timeout
	ld	(acmd_to),a		; save auto cmd timeout in seconds
;
	call	acmd_wait		; do autocmd wait processing
	call	z,runnvr		; if Z set, process NVR switches
	jp	prompt			; if we return, do normal loader prompt
;
nonvrswitch:
	; no NVRAM switches found, or disabled, continue process from Build Config
#endif
;
;
;=======================================================================
; ROM Configuration Auto Boot Setup
;=======================================================================
;
#if (BOOT_TIMEOUT != -1)
	; Initialize auto command flag and timeout downcounter
	or	$FF			; auto cmd active value
	ld	(acmd_act),a		; set flag
	ld	a,BOOT_TIMEOUT		; boot timeout in secs
	ld	(acmd_to),a		; save auto cmd timeout in seconds
;
	call	acmd_wait		; do autocmd wait processing
	call	z,autocmd		; if Z set, do autocmd processing
#endif
;
	jp	prompt			; interactive loader prompt
;
;=======================================================================
; Auto Command Wait Processing
;=======================================================================
;
acmd_wait:
	call	nl2			; formatting
;
acmd_wait0:
	ld	hl,str_autoact1		; message part 1
	call	pstr			; display it
	ld	a,(acmd_to)		; remaining timeout in seconds
	call	prtdecb			; display it
	ld	hl,str_autoact2		; message part 2
	call	pstr			; display it
;
	ld	a,64			; 1/64 sub-seconds counter reload value
	ld	(acmd_to_64),a		; reload sub-seconds counter
;
acmd_wait1:
	; check for user escape/enter
	call	cst			; check for keyboard key
	jr	z,acmd_wait2		; no key, continue
	call	cin			; get key
	cp	cr			; enter key?
	jr	z,acmd_wait_z		; if so, ret immed with Z set
	cp	esc			; escape key?
	jr	nz,acmd_wait1		; loop if not
	or	$FF			; signal abort
	jr	acmd_wait_z		; and return
;
acmd_wait2:
	; check for auto cmd timeout and handle if so
	ld	a,(acmd_to)		; get seconds counter
	or	a			; test for zero
	jr	z,acmd_wait_z		; if done, ret with Z set
;
	ld	a,(acmd_to_64)		; get sub-seconds counter
	dec	a			; decrement counter
	ld	(acmd_to_64),a		; resave it
	jr	nz,acmd_wait3		; skip over seconds down count
;
	ld	a,(acmd_to)		; get seconds counter
	dec	a			; decrement counter
	ld	(acmd_to),a		; resave it
	jr	acmd_wait0		; and restart loop
;
acmd_wait3:
	ld	de,976			; 16us * 976 -> 1/64th of a second.
	call	vdelay			; 15.6ms delay, 64 in 1 second
	jr	acmd_wait1		; loop
;
acmd_wait_z:
	; clear the downcounter message from screen, then return
	push	af			; save flags
	ld	a,13			; start of line
	call	cout			; do it
	ld	a,' '			; space char
	ld	b,60			; send 60 of them
acmd_wait_z2:
	call	cout			; print space char
	djnz	acmd_wait_z2		; loop till done
	pop	af			; restore flags
	ret				; and return
;
;=======================================================================
; Boot Loader Prompt Processing
;=======================================================================
;
prompt:
	ld	hl,prompt		; restart address is here
	push	hl			; preset stack
;
	call	nl2			; formatting
	ld	hl,str_prompt		; display boot prompt "Boot [H=Help]:"
	call	pstr			; do it
	call	clrbuf			; zero fill the cmd buffer
;
	ld	c,DSKY_MSG_LDR_SEL	; boot select msg
	call	dsky_msg                ; show on DSKY
#if (DSKYENABLE)
	call	dsky_highlightallkeys
	call 	dsky_beep
	call 	dsky_l2on
#endif
;
	call	delay			; wait for prompt to be sent?
;
#if (BIOS == BIOS_WBW)
;
	call	flush		; flush all char units
;
  #if (AUTOCON)
	or	$ff			; initial value
	ld	(conpend),a		; ... for conpoll routine
  #endif
#endif
;
wtkey:
	; wait for a key or timeout
	call	cst			; check for keyboard key
	jr	nz,concmd		; if pending, do console command
	; NOTE Above is like a CALL, with a RET to reprompt: (manually pushed)
;
#if (DSKYENABLE)
	call	dsky_stat		; check DSKY for keypress
	jp	nz,dskycmd		; if pending, do DSKY command
#endif
;
#if (BIOS == BIOS_WBW)
  #if (AUTOCON)
	call	conpoll			; poll for console takeover
	jp	nz,docon		; if requested, takeover
  #endif
#endif
;
	jr	wtkey			; loop
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
; Flush queued data from all character units
;=======================================================================
;
; Prior to starting to poll for a console takeover request, we clean
; out pending data from all character units.  The active console
; is included.
;
#if (BIOS == BIOS_WBW)
;
flush:
	ld	a,(curcon)		; get active console unit
	push	af			; save it
	ld	c,0			; char unit index
;
flush1:
	ld	b,0			; loop max failsafe counter
	ld	a,c			; put char unit in A
	ld	(curcon),a		; and then make it cur con
;
flush2:
	call	cst			; char waiting?
	jr	z,flush3		; all done, do next unit
	call	cin			; get and discard char
	djnz	flush2			; loop max times
;
flush3:
	inc	c			; next char unit
	ld	a,(ciocnt)		; get char unit count
	cp	c			; unit > cnt?
	jr	c,flush_z		; done
	jr	flush1			; otherwise, do next char unit
;
flush_z:
	pop	af			; recover active console unit
	ld	(curcon),a		; and reset to original value
	ret				; done
;
#endif
;
;=======================================================================
; Poll character units for console takeover request
;=======================================================================
;
; Poll all character units in system for a console takeover request.
; A takeover request consists of pressing the <space> twice in a row.
; at the character unit that wants to be the console.  Return with ZF
; set if a console takeover was requested. If so, the requested console
; unit will be recorded in (newcon).
;
#if (BIOS == BIOS_WBW)
  #if (AUTOCON)
;
conpoll:
	; save active console unit
	ld	a,(curcon)
	ld	e,a			; save in E
;
	; loop through all char ports
	ld	a,(ciocnt)		; count of char units
	ld	b,a			; use for loop counter
	ld	c,0			; init unit num
;
conpoll1:
	ld	a,c			; next char unit to test
	cp	e			; is this the active console?
	jr	z,conpoll2		; if so, don't test, move on
	ld	(curcon),a		; make it current port
	call	cst			; char waiting?
	jr	z,conpoll2		; if no char, move on
	call	cin			; get char
	cp	' '			; space char?
	jr	z,conpoll1a		; if so, handle it
;
	; something other than a <space> was received, clear
	; the pending console
	or	$ff			; idle value
	ld	(conpend),a		; save it
	jr	conpoll2		; continue checking
;
conpoll1a:
	; a <space> char was typed.  check to see if we just saw a
	; <space> from this same unit.
	ld	a,(conpend)		; pending con unit to A
	cp	c			; compare to active unit
	jr	z,conpoll3		; if =, second <space>, take con
	ld	a,c			; if not, unit to A
	ld	(conpend),a		; and update pending console
;
conpoll2:
	inc	c			; next char unit
	djnz	conpoll1		; loop till done
	xor	a			; ret w/ Z for no takeover
	jr	conpoll4		; all done, no takeover
;
conpoll3:
	; record a new console request
	ld	a,(curcon)		; record the unit
	ld	(newcon),a		; ... as new console
	or	$ff			; ret w/ NZ for new con req
;
conpoll4:
	; restore active console and exit
	ld	a,e			; restore active
	ld	(curcon),a		; ... console
	ret				; done, NZ if new con request
;
  #endif
#endif
;
;=======================================================================
; Process a command line from buffer
;=======================================================================
;
concmd:
;
#if (DSKYENABLE)
	call	dsky_highlightkeysoff
	call 	dsky_l2off
#endif
;
	; Get a command line from console and handle it
	call	rdln			; get a line from the user
	ld	de,cmdbuf		; point to buffer
	jr	runcmd			; process command
;
autocmd:
	; Copy autocmd string to buffer and process it
	ld	hl,str_autoboot		; auto command prefix
	call	pstr			; show it
	ld	hl,acmd_buf		; auto cmd string
	call	pstr			; display it
	ld	hl,acmd_buf		; auto cmd string
	ld	de,cmdbuf		; cmd buffer adr
	ld	bc,acmd_len		; auto cmd length
	ldir				; copy to command line buffer
;
runcmd:
	; Process command line
	ld	de,cmdbuf		; point to start of buf
	call	skipws			; skip whitespace
	or	a			; check for null terminator
	;;;ret	z			; if empty line, just bail out
	jr	nz,runcmd0		; if char, process cmd line
;
	; if empty cmd line, use default
	ld	hl,defcmd_buf		; def cmd string
	ld	de,cmdbuf		; cmd buffer adr
	ld	bc,defcmd_len		; auto cmd length
	ldir				; copy to command line buffer
	ld	de,cmdbuf		; point to start of buf
	call	skipws			; skip whitespace
	or	a			; check for null terminator
	ret	z			; if empty line, bail out
;
runcmd0:
	ld	a,(de)			; get character
	call	upcase			; make upper case
;
	; Attempt built-in commands
	cp	'H'			; H = display help
	jp	z,help			; if so, do it
	cp	'?'			; '?' alias for help
	jp	z,help			; if so, do it
	;;;cp	'L'			; L = List ROM applications
	;;;jp	z,applst		; if so, do it
	;;;cp	'D'			; D = device inventory
	;;;jp	z,devlst		; if so, do it
	cp	'R'			; R = reboot system
	jp	z,reboot		; if so, do it
#if (BIOS == BIOS_WBW)
	;;;cp	'S'			; S = Slice Inventory
	;;;jp	z,slclst		; if so, do it
	;;;cp	'W'			; W = Rom WBW NVR Config Rom App
	;;;jp	z,nvrconfig		; if so, do it
	cp	'I'			; C = set console interface
	jp	z,setcon		; if so, do it
	cp	'V'			; V = diagnostic verbosity
	jp	z,setdl			; is so, do it
#endif
;
	; Attempt ROM application launch
	call	findcon			; find the application from console Key in A REG
	jp	z,romrun		; if match found, then run it
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
#if ((BIOS == BIOS_WBW) & FPSW_ENABLE)
;
;=======================================================================
; Process Front Panel switches
;=======================================================================
;
runfp:
	ld	a,(switches)		; get switches value
	and	SW_DISK			; disk boot?
	jr	nz,fp_diskboot		; handle disk boot
;
fp_romboot:
	; Handle FP ROM boot
	ld	a,(switches)		; get switches value
	and	SW_OPT			; isolate options bits
	ld	hl,fpapps		; rom apps cmd char list
	call	addhla			; point to the right one
	ld	a,(hl)			; get it
	jp	romboot			; do it
;
fpapps	.db	"MBFPCZNU"
;
fp_diskboot:
	; get count of disk units
	ld	b,BF_SYSGET		; HBIOS Get function
	ld	c,BF_SYSGET_DIOCNT	; HBIOS DIO Count sub fn
	rst	08			; call HBIOS
	ld	a,e			; count to A
	ld	(diskcnt),a		; save it
	or	a			; set flags
	ret	z			; bort if no disk units
	ld	a,(switches)		; get switches value
	and	SW_FLOP			; floppy switch bit
	jr	nz,fp_flopboot		; handle auto flop boot
	; fall thru for auto hd boot
;
fp_hdboot:
	; Find the first hd with media and boot to that unit using
	; the slice specified by the FP switches.
	ld	a,(diskcnt)		; get disk count
	ld	b,a			; init loop counter
	ld	c,0			; init disk index
fp_hdboot1:
	push	bc			; save loop control
	ld	b,BF_DIODEVICE		; HBIOS Disk Device func
	rst	08			; unit in C, do it
	bit	5,C			; high capacity disk?
	pop	bc			; restore loop control
	jr	z,fp_hdboot2		; if not, continue loop
	push	bc			; save loop control
	ld	b,BF_DIOMEDIA		; HBIOS Sense Media
	ld	e,1			; perform media discovery
	rst	08			; do it
	pop	bc			; restore loop control
	jr	z,fp_hdboot3		; if has media, go boot it
fp_hdboot2:
	inc	c			; else next disk
	djnz	fp_hdboot1		; loop thru all disks
	ret				; nothing works, abort
;
fp_hdboot3:
	ld	a,c			; disk unit to A
	ld	(bootunit),a		; save it
	ld	a,(switches)		; get switches value
	and	SW_OPT			; isolate slice value
	ld	(bootslice),a		; save it
	jp	diskboot		; do it
;
fp_flopboot:
	; Find the nth floppy drive and boot to that unit.  The
	; floppy number is based on the option switches.
	ld	a,(diskcnt)		; get disk count
	ld	b,a			; init loop counter
	ld	c,0			; init disk index
	ld	a,(switches)		; get switches value
	and	SW_OPT			; isolate option bits
	ld	e,a			; floppy unit down counter
	inc	e			; pre-increment for ZF check
fp_flopboot1:
	push	bc			; save loop control
	push	de			; save floppy down ctr
	ld	b,BF_DIODEVICE		; HBIOS Disk Device func
	rst	08			; unit in C, do it
	bit	7,c			; floppy device?
	pop	de			; restore loop control
	pop	bc			; restore floppy down ctr
	jr	z,fp_flopboot3		; if not floppy, skip
	dec	e			; decrement down ctr
	jr	z,fp_flopboot2		; if ctr expired, boot this unit
fp_flopboot3:
	inc	c			; else next disk
	djnz	fp_flopboot1		; loop thru all disks
	ret				; nothing works, abort
;
fp_flopboot2:
	ld	a,c			; disk unit to A
	ld	(bootunit),a		; save it
	xor	a		;	; zero accum
	ld	(bootslice),a		; floppy boot slice is always 0
	jp	diskboot		; do it
;
#endif
;
#if (BIOS == BIOS_WBW)
;
;=======================================================================
; Process NVR Switches
;=======================================================================
;
runnvr:
	ld	bc,BC_SYSGET_SWITCH	; HBIOS SysGet NVRAM Switches
	ld	d,NVSW_BOOTOPTS		; Read Boot options (disk/Rom) switch
	rst	08
	ld	a,h
	and	BOPTS_ROM		; Get the Boot Opts ROM Flag
	jr	nz,nvrsw_rom		; IF Set as ROM App BOOT, otherwise Disk
;
nvrsw_disk:
	ld	a,h			; (H contains the Disk Unit 0-127)
	ld	(bootunit),a		; copy the NVRam Unit and Slice
	ld	a,l			; (L contains the boot slice 0-255)
	ld	(bootslice),a		; directly into the selected boot
	jp	diskboot		; do it
;
nvrsw_rom:
	; Attempt ROM application launch
	ld	a,l			; Load the ROM app selection to A
	jp	romboot			; do it
;
#endif
;
;=======================================================================
; Process a DSKY command from key in A
;=======================================================================
;
#if (DSKYENABLE)
;
dskycmd:
;
	call	dsky_getkey		; get DSKY key
	ld	a,e			; put in A
	cp	$FF			; check for error
	ret	z			; abort if so
;
	push	af
	call	dsky_highlightkeysoff
	call 	dsky_l2off
	pop	af
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
	jp	z,romrun		; if match, run it
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
	ld	hl,str_help1		; load first help string
	call	pstr			; display it
	;;;ld	a,(bootmode)		; get boot mode
	;;;cp	BM_ROMBOOT		; ROM boot?
	;;;jr	nz,help1		; if not, skip str_help2
	;;;ld	hl,str_help2		; load second help string
	;;;call	pstr			; display it
;;;help1:
	call	applst			; list ROM applications
	ld	hl,str_help3		; load third help string
	call	pstr                    ; display it
	ret
;
; List ROM apps
;
applst:
	;;;ld	hl,str_applst
	;;;call	pstr
	;;;call	nl
	ld	ix,(ra_tbl_loc)
applst1:
	; check for end of table
	ld	a,(ix)
	or	(ix+1)
	ret	z
;
	ld	a,(ix+ra_attr)
	bit	7,a
	jr	nz,applst2
;
	;;;push	af

	call	nl
	ld	hl,str_leader
	call	pstr
	ld	a,(ix+ra_conkey)
	call	cout
	ld	hl,str_spacer
	call	pstr

	;;;ld	a,' '
	;;;call	cout
	;;;call	cout
	;;;pop	af
	;;;call	cout
	;;;ld	a,':'
	;;;call	cout
	;;;ld	a,' '
	;;;call	cout

	ld	l,(ix+ra_name)
	ld	h,(ix+ra_name+1)
	call	pstr
;
applst2:
	ld	bc,ra_entsiz
	add	ix,bc
	jr	applst1

	ret
;;;;
;;;; Device list
;;;;
;;;devlst:
;;;	jp	prtall			; do it
;;;;
;;;; Slice list
;;;;
;;;slclst:
;;;	ld	a,'S'			; "S"lice Inv App
;;;	jp	romcall			; Call a Rom App with Return
;;;;
;;;; RomWBW Config
;;;;
;;;nvrconfig:
;;;	ld	a,'W'			; "W" Rom WBW Configure App
;;;	jp	romcall			; Call a Rom App with Return
;
; Set console interface unit
;
#if (BIOS == BIOS_WBW)
;
setcon:
	; On entry DE is expected to be pointing to start
	; of command. Get unit number.
	call	findws			; skip command
	call	skipws			; and skip it
	call	isnum			; do we have a number?
	jp	nz,err_invcmd		; if not, invalid
	call	getnum			; parse number into A
	jp	c,err_nocon		; handle overflow error
;
	; Check against max char unit
	ld	hl,ciocnt
	cp	(hl)
	jp	nc,err_nocon		; handle invalid unit
	ld	(newcon),a		; save validated console
;
	; Get baud rate
	call	findws
	call	skipws			; skip whitespace
	call	isnum			; do we have a number?
	jp	nz,docon		; if no we don't change baudrate
	push	de			; move char ptr
	pop	ix			; ... to IX
	call	getnum32		; get 32-bit number
	jp	c,err_invcmd		; handle overflow
	ld	c,75			; Constant for baud rate encode
	call	encode			; encode into C:4-0
	jp	nz,err_invcmd		; handle encoding error
	ld	a,c			; move encoded value to A
	ld	(newspeed),a		; save validated baud rate
;
	; Get the current settings for chosen console
	ld	b,BF_CIOQUERY		; BIOS serial device query
	ld	a,(newcon)		; get device unit num
	ld	c,a			; ... and put in C
	rst	08			; call H/UBIOS, DE := line characteristics
	jp	nz,err_invcmd		; abort on error
;
	ld	a,d			; mask off current
	and	%11100000		; baud rate
	ld	hl,newspeed		; and load in new
	or	(hl)			; baud rate
	ld	d,a
;
	ld	hl,str_chspeed		; notify user
	call	pstr			; to change speed
	call	ldelay			; time for line to flush
;
	ld	b,BF_CIOINIT		; BIOS serial init
	ld	a,(newcon)		; get serial device unit
	ld	c,a			; ... into C
	rst	08			; call HBIOS
	jp	nz,err_invcmd		; handle error
;
	call	cin			; wait for char at new speed
;
	; Notify user, we're outta here....
docon:	ld	hl,str_newcon		; new console msg
	call	pstr			; print string on cur console
	ld	a,(newcon)		; restore new console unit
	call	prtdecb			; print unit num
;
	; Set console unit
	ld	(curcon),a		; update loader console unit
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
	ret
;
#endif
;
; Set RomWBW HBIOS Diagnostic Level
;
#if (BIOS == BIOS_WBW)
;
setdl:
	; On entry DE is expected to be pointing to start
	; of command
	call	findws			; skip command
	call	skipws			; and skip it
	or	a			; set flags to check for null
	jr	z,showdl		; no parm, just display
	call	isnum			; do we have a number?
	jp	nz,err_invcmd		; if not, invalid
	call	getnum			; parse number into A
	jp	c,err_invcmd		; handle overflow error
;
	; Set diagnostic level
	ld	b,BF_SYSPOKE		; HBIOS func: POKE
	ld	d,BID_BIOS		; BIOS bank
	ld	e,a			; diag level value
	ld	hl,HCB_LOC + HCB_DIAGLVL	; offset into HCB
	rst	08			; do it
	; Fall thru to display new value
;
showdl:
	; Display current diagnostic level
	ld	hl,str_diaglvl		; diag level tag
	call	pstr			; print it
	ld	b,BF_SYSPEEK		; HBIOS func: PEEK
	ld	d,BID_BIOS		; BIOS bank
	ld	hl,HCB_LOC + HCB_DIAGLVL	; offset into HCB
	rst	08			; do it, E := level value
	ld	a,e			; put in accum
	call	prtdecb			; print it
	ret				; done
;
#endif
;
; Restart system
;
reboot:
	ld	hl,str_reboot		; point to message
	call	pstr			; print it
	call	ldelay			; wait for message to display
;
#if (BIOS == BIOS_WBW)
;
	;ld	hl,msg_boot		; point to boot message
	;call	dsky_show		; display message
	ld	c,DSKY_MSG_LDR_BOOT	; point to boot message
	call	dsky_msg                ; display message
;
	; cold boot system
	ld	b,BF_SYSRESET		; system restart
	ld	c,BF_SYSRES_COLD	; cold start
	rst	08			; do it, no return
#endif
;
#if (BIOS == BIOS_UNA)
	; switch to rom bank 0 and jump to address 0
	ld	bc,$01FB		; UNA func = set bank
	ld	de,0			; ROM bank 0
	rst	08			; do it
	jp	0			; jump to restart address
#endif
;;;;
;;;;=======================================================================
;;;; Call a ROM Application (with return)
;;;; This is same as romrun but doesn't display load messages
;;;; Intended for Utility applications (part of RomWBW) not third part apps
;;;; these apps are on Help menu, hidden from Application List
;;;; Parameters A - The app to call.
;;;;=======================================================================
;;;;
;;;romcall:
;;;	call	findcon			; find the application based on A reg
;;;	ret	nz			; if not found then return to prompt
;;;;
;;;	call	appload			; Load ROM App into working memory
;;;;
;;;	ld	l,(ix+ra_ent)		; HL := app entry address
;;;	ld	h,(ix+ra_ent+1)		; IX register returned from findcon
;;;	jp	(hl)			; call to the routine.
;;;	;
;;;	; NOTE It is assumed the Rom App should perform a RET,
;;;	; returning control to the caller of this sub routine.
;
;=======================================================================
; Load and run a ROM application, IX=ROM app table entry
;=======================================================================
;
romrun:
;
	ld	a,(ix+ra_attr)		; get attributes
	bit	6,a			; quiet load?
	jr	z,romrun1		; if 0, do verbose load
;
	; Quiet run
	call	appload			; Load ROM App into working memory
	ld	l,(ix+ra_ent)		; HL := app entry address
	ld	h,(ix+ra_ent+1)		; ...
	jp	(hl)			; go
;
romrun1:
	; Verbose run, notify user
	ld	hl,str_load
	call	pstr
	ld	l,(ix+ra_name)
	ld	h,(ix+ra_name+1)
	call	pstr
;
	ld	c,DSKY_MSG_LDR_LOAD	; point to load message
	call	dsky_msg                ; display message
;
	call	pdot			; show progress
	call	appload			; Load ROM App into working memory
	call	pdot			; show progress
;
	ld	c,DSKY_MSG_LDR_GO	; point to go message
	call	dsky_msg                ; display message
;
	ld	l,(ix+ra_ent)		; HL := app entry address
	ld	h,(ix+ra_ent+1)		; ...
	call	pdot			; show progress
	jp	(hl)			; go
;
;=======================================================================
; Routine - Copy Rom App from Rom to it's running location
; param : IX - Pointer to the Rom App to copy into RAM
;=======================================================================
;
appload:
;
#if (BIOS == BIOS_WBW)
	ld	a,(ix+ra_bnk)		; get image source bank id
	cp	bid_cur			; special value?
	jr	nz,appload1		; if not, continue
	ld	a,(bid_ldr)		; else substitute
	jr	appload2		; and continue
appload1:
	add	a,BID_IMG0		; add to start of image banks
appload2:
	ld	e,(ix+ra_dest)		; DE := run dest adr
	ld	d,(ix+ra_dest+1)	; ...
	ld	l,(ix+ra_src)		; HL := image source adr
	ld	h,(ix+ra_src+1)		; ...
	ld	c,(ix+ra_siz)		; BC := image size
	ld	b,(ix+ra_siz+1)		; ...
;
	; Load into RAM
	push	af			; save bank id
	call	romload			; load from ROM
	pop	af			; restore bank id
;	
	; Record boot information
	ld	l,a			; L := source bank
	ld	de,$0000		; boot vol=0, slice=0
	ld	b,BF_SYSSET		; HBIOS func: system set
	ld	c,BF_SYSSET_BOOTINFO	; BBIOS subfunc: boot info
	rst	08			; do it
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
;
	; Copy image to running location
	ld	l,(ix+ra_src)		; HL := image source adr
	ld	h,(ix+ra_src+1)		; ...
	ld	e,(ix+ra_dest)		; DE := run dest adr
	ld	d,(ix+ra_dest+1)	; ...
	ld	c,(ix+ra_siz)		; BC := image size
	ld	b,(ix+ra_siz+1)		; ...
	ldir				; copy image
;
	; Switch back to user bank
	ld	bc,$01FB		; UNA func: set bank
	ld	de,(bid_ldr)		; select user bank
	rst	08			; do it
;
	; Record boot information
	ld	de,(bid_ldr)		; original bank
	ld	l,$01			; encoded boot slice/unit
	ld	bc,$01FC		; UNA func: set bootstrap hist
	rst	08			; call una
;
#endif
;
	ret

;
;=======================================================================
; Routine - Copy chunk of data from Rom to a RAM location, source
; chunk may span banks.  Source address must be <= 32768.
; param : HL=Source Adr, DE=Dest Adr, BC=Length, A=Source Bank
;=======================================================================
;
; loop:
; 
; CPYLEN = (32768 - SRCADR)
; if (CPYLEN >= LEN) then CPYLEN = LEN
; LEN = (LEN - CPYLEN)	; do it here to avoid saving CPYLEN
; 
; ; BnkCpy returns updated SRCADR, DSTADR
; call BnkCpy(SRCBNK:SRCADR, DSTBNK:DSTADR, CPYLEN)
; 
; if (SRCADR == 32768)
;   increment SRCBNK
;   SRCADR = 0
; 
; if (LEN == 0) then done
; 
; goto loop
;
#if (BIOS == BIOS_WBW)
;
romload:
	ld	(HB_SRCBNK),a		; setup for bnkcpy
	ld	a,BID_USR		; dest is user bank
	ld	(HB_DSTBNK),a		; setup for bnkcpy
;
romload1:
	; if LEN == 0, then done
	push	bc			; save BC
	ld	a,b			; test load length
	or	c			; ... for zero
	pop	bc			; restore BC
	ret	z			; if 0, abort
;
	ex	de,hl			; src adr to DE
	; HL=DSTADR, BC=LEN, DE=SRCADR
	push	hl			; save HL to use as CPYLEN
	; HL=DSTADR, BC=LEN, DE=SRCADR, TOS=DSTADR
;
	; CPYLEN = 32768 - SRCADR
	or	a			; clear CF
	ld	hl,32768
	sbc	hl,de			; CPYLEN (HL) = 32768 - SRCADR
	; HL=COPYLEN, BC=LEN, DE=SRCADR, TOS=DSTADR
;
	; if (CPYLEN >= LEN) then CPYLEN = LEN
	sbc	hl,bc			; CPYLEN - LEN
	jr	c,romload2
	push	bc			; CPYLEN = LEN
	pop	hl
	jr	romload3
romload2:
	adc	hl,bc			; restore CPYLEN
romload3:
	; HL=CPYLEN, BC=LEN, DE=SRCADR, TOS=DSTADR
;
	push	hl
	push	bc
	pop	hl
	pop	bc
	; HL=LEN, BC=CPYLEN, DE=SRCADR, TOS=DSTADR
;
	; LEN = LEN - CPYLEN
	or	a			; clear CF
	sbc	hl,bc			; LEN updated
;	
	ex	(sp),hl
	; HL=DSTADR, BC=CPYLEN, DE=SRCADR, TOS=LEN
	ex	de,hl
	; HL=SRCADR, BC=CPYLEN, DE=DSTADR, TOS=LEN
;
	; do the copy, HL/DE updated
	call	HB_BNKCPY
;
	; if (SRCADR == 32768), then [SRCBNK++, SRCADR=0]
	bit	7,h			; cheat to test if SRCADR >= 32768
	jr	z,romload4		; if not, nothing to do
	ld	hl,0			; reset SRCADR to 0
	ld	a,(HB_SRCBNK)	
	inc	a			; bump SRCBNK
	ld	(HB_SRCBNK),a
;
romload4:
	pop	bc			; get LEN back
;
	jr	romload1		; rinse and repeat
#endif
;
;=======================================================================
; Boot ROM Application
;=======================================================================
;
; Enter with ROM application menu selection (command) character in A
;
romboot:
	call	findcon			; Match the application base on console command in A
	jp	z,romrun		; if match application found then load it
	ret				; no match, just return to - prompt:
;
;=======================================================================
; Find App For Console Command
; Pass in A, the console command character
; Return IX pointer, and Z if found; NZ if not found
;=======================================================================
;
findcon:
	call	upcase			; force uppercase for matching
	ld	ix,(ra_tbl_loc)		; point to start of ROM app tbl
	ld	c,a			; save command char in C
findcon1:
	ld	a,(ix+ra_conkey)	; get match char
	cp	c			; compare
	ret	z			; if matched, return
	ld	de,ra_entsiz		; table entry size
	add	ix,de			; bump IX to next entry
	ld	a,(ix)			; check for end
	or	(ix+1)			; ... of table
	jr	nz,findcon1		; loop if still more table entries
	or	0ffh			; set NZ flag, signal not found
	ret				; no match, and return
;
;=======================================================================
; Boot disk unit/slice
;=======================================================================
;
diskboot:
;
	; Notify user
	ld	hl,str_boot1		; "Booting Disk Unit"
	call	pstr
	ld	a,(bootunit)
	call	prtdecb
	ld	hl,str_boot2		; "Slice"
	call	pstr
	ld	a,(bootslice)
	call	prtdecb
;
	;ld	hl,msg_load		; point to load message
	;call	dsky_show		; display message
	ld	c,DSKY_MSG_LDR_LOAD	; point to load message
	call	dsky_msg                ; display message
;
#if (BIOS == BIOS_WBW)
;
	; Get Extended information for the Device, and Slice
	ld	b,BF_EXTSLICE		; HBIOS func: SLICE CALC
	ld	a,(bootunit)		; passing boot unit
	ld	d,a
	ld	a,(bootslice)		; and slice
	ld	e,a
	rst	08			; do it
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
diskboot0:
	ld	a,c			; media id to A
	ld	(mediaid),a		; save media id
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
	jr	z,diskboot0		; slice 0, skip slice check
	ld	a,d			; disk type to A
	cp	$41			; IDE?
	jr	z,diskboot0		; if so, OK
	cp	$42			; PPIDE?
	jr	z,diskboot0		; if so, OK
	cp	$43			; SD?
	jr	z,diskboot0		; if so, OK
	cp	$44			; DSD?
	jr	z,diskboot0		; if so, OK
	jp	err_noslice		; no such slice, handle err
;
diskboot0:
	; Below is wrong.  It assumes we are booting from a hard
	; disk, but it could also be a RAM/ROM disk.  However, it is
	; not actually possible to boot from those, so not gonna
	; worry about this.
	ld	a,4			; assume legacy hard disk
	ld	(mediaid),a		; save media id
;
diskboot1:
	; Initialize working LBA value
	ld	hl,0			; zero HL
	ld	(lba),hl		; init
	ld	(lba+2),hl		; ... LBA
;
	; Set legacy sectors per slice
	ld	hl,16640		; legacy sectors per slice
	ld	(sps),hl		; save it
;
	; Check for hard disk
	ld	a,(mediaid)		; load media id
	cp	4			; legacy hard disk?
	jr	nz,diskboot8		; if not hd, no part table
;
	; Attempt to read MBR
	ld	de,0			; MBR is at
	ld	hl,0			; ... first sector
	ld	bc,bl_mbrsec		; read into MBR buffer
	ld	(dma),bc		; save
	ld	b,1			; one sector
	ld	a,(bootunit)		; get bootunit
	ld	c,a			; put in C
	call	diskread		; do it
	ret	nz			; abort on error
;
	; Check signature
	ld	hl,(bl_mbrsec+$1FE)	; get signature
	ld	a,l			; first byte
	cp	$55			; should be $55
	jr	nz,diskboot4		; if not, no part table
	ld	a,h			; second byte
	cp	$AA			; should be $AA
	jr	nz,diskboot4		; if not, no part table
;
	; Try to find our entry in part table and capture lba offset
	ld	b,4			; four entries in part table
	ld	hl,bl_mbrsec+$1BE+4	; offset of first entry part type
diskboot2:
	ld	a,(hl)			; get part type
	cp	$2E			; cp/m partition?
	jr	z,diskboot3		; cool, grab the lba offset
	ld	de,16			; part table entry size
	add	hl,de			; bump to next entry part type
	djnz	diskboot2		; loop thru table
	jr	diskboot4		; too bad, no cp/m partition
;
diskboot3:
	; Capture the starting LBA of the CP/M partition we found
	ld	de,4			; LBA is 4 bytes after part type
	add	hl,de			; point to it
	ld	de,lba			; loc to store lba offset
	ld	bc,4			; 4 bytes (32 bits)
	ldir				; copy it
	; If boot from partition, use new sectors per slice value
	ld	hl,16384		; new sectors per slice
	ld	(sps),hl		; save it
;
diskboot4:
	; Add slice offset
	ld	a,(bootslice)		; get boot slice, A is loop cnt
	ld	hl,(lba)		; set DE:HL
	ld	de,(lba+2)		; ... to starting LBA
	ld	bc,(sps)		; sectors per slice
diskboot5:
	or	a			; set flags to check loop ctr
	jr	z,diskboot7		; done if counter exhausted
	add	hl,bc			; add one slice to low word
	jr	nc,diskboot6		; check for carry
	inc	de			; if so, bump high word
diskboot6:
	dec	a			; dec loop downcounter
	jr	diskboot5		; and loop
;
#endif
;
diskboot7:
	ld	(lba),hl		; update lba, low word
	ld	(lba+2),de		; update lba, high word
;
diskboot8:
	; Note that we could be coming from diskboot1!
	ld	hl,str_ldsec		; display prefix "Sector Ox"
	call	pstr			; do it
	ld	hl,(lba)		; recover lba loword
	ld	de,(lba+2)		; recover lba hiword
	call	prthex32		; display starting sector
	call	pdot			; show progress
;
	; Read boot info sector, third sector
	ld	bc,2			; sector offset
	add	hl,bc			; add to LBA value low word
	jr	nc,diskboot9		; check for carry
	inc	de			; if so, bump high word
diskboot9:
	ld	bc,bl_infosec		; read buffer
	ld	(dma),bc		; save
	ld	a,(bootunit)		; disk unit to read
	ld	c,a			; put in C
	ld	b,1			; one sector
	call	diskread		; do it
	ret	nz			; abort on error
	call	pdot			; show progress
;
	; Check signature
	ld	de,(bb_sig)		; get signature read
	ld	a,$A5			; expected value of first byte
	cp	d			; compare
	jp	nz,err_sig		; handle error
	ld	a,$5A			; expected value of second byte
	cp	e			; compare
	jp	nz,err_sig		; handle error
	call	pdot			; show progress
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
	call	prthexword		; print it
	pop	hl			; restore string ptr
	call	pstr			; print
	push	hl			; save string ptr
	ld	bc,(bb_cpmend)		; get load end
	call	prthexword		; print it
	pop	hl			; restore string ptr
	call	pstr			; print
	push	hl			; save string ptr
	ld	bc,(bb_cpment)		; get load end
	call	prthexword		; print it
	pop	hl			; restore string ptr
	call	pstr			; print
;
	; Compute number of sectors to load
	ld	hl,(bb_cpmend)		; hl := end
	ld	de,(bb_cpmloc)		; de := start
	or	a			; clear carry
	sbc	hl,de			; hl := length to load
	jp	z,str_err_noboot	; can't load zero length
	jp	c,str_err_noboot	; can't load negative length
	; If load length is not a multiple of sector size (512)
	; we need to round up to get everything loaded!
	ld	de,511			; 1 less than sector size
	add	hl,de			; ... and roundup
	ld	a,h			; determine 512 byte sector count
	rra				; ... by dividing msb by two
	ld	(loadcnt),a		; ... and save it
	call	pdot			; show progress
;
	; Start OS load at sector 3
	ld	hl,(lba)		; low word of saved LBA
	ld	de,(lba+2)		; high word of saved LBA
	ld	bc,3			; offset for sector 3
	add	hl,bc			; apply it
	jr	nc,diskboot10		; check for carry
	inc	de			; bump high word if so
diskboot10:
	ld	bc,(bb_cpmloc)		; load address
	ld	(dma),bc		; and save it
	ld	a,(loadcnt)		; get sectors to read
	ld	b,a			; put in B
	ld	a,(bootunit)		; get boot disk unit
	ld	c,a			; put in C
	call	diskread		; read image
	ret	nz			; abort on error
	call	pdot			; show progress
;
#if (BIOS == BIOS_WBW)
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
;
#endif
;
#if (BIOS == BIOS_UNA)
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
;
#endif
;
	call	pdot			; show progress
;
	;ld	hl,msg_go		; point to go message
	;call	dsky_show		; display message
	ld	c,DSKY_MSG_LDR_GO	; point to go message
	call	dsky_msg                ; display message
;
	; Jump to entry vector
	ld	hl,(bb_cpment)		; get entry vector
	jp	(hl)			; and go there
;
;-----------------------------------------------------------------------
;
; Read disk sector(s)
; DE:HL is LBA, B is sector count, C is disk unit
;
diskread:
;
#if (BIOS == BIOS_UNA)
;
	; Seek to requested sector in DE:HL
	push	bc			; save unit and count
	ld	b,c			; unit to read in B
	ld	c,$41			; UNA func: set lba
	rst	08			; set lba
	pop	bc			; recover unit and count
	jp	nz,err_api		; handle error
;
	; Read sector(s) into buffer
	ld	l,b			; sectors to read
	ld	b,c			; unit to read in B
	ld	c,$42			; UNA func: read sectors
	ld	de,(dma)		; dest for read
	rst	08			; do read
	jp	nz,err_diskio		; handle error
	xor	a			; signal success
	ret				; and done
;
#endif
;
#if (BIOS == BIOS_WBW)
;
	; Seek to requested sector in DE:HL
	push	bc			; save unit & count
	set	7,d			; set LBA access flag
	ld	b,BF_DIOSEEK		; HBIOS func: seek
	rst	08			; do it
	pop	bc			; recover unit & count
	jp	nz,err_diskio		; handle error
;
	; Read sector(s) into buffer
	ld	e,b			; transfer count
	ld	b,BF_DIOREAD		; HBIOS func: disk read
	ld	hl,(dma)		; read into info sec buffer
	ld	d,BID_USR		; user bank
	rst	08			; do it
	jp	nz,err_diskio		; handle error
	xor	a			; signal success
	ret				; and done
;
#endif
;
; Built-in mini-loader for the Hardware Monitor.  The Hardware Monitor
; is imbeded in the ROM at the start of bank 3 (BID_IMG2).
; This bit of code just launches the monitor directly from that bank.
;
; Currently, only the S100 Z180 (PLT_SZ180) has a Hardware Monitor.
;
#if (BIOS == BIOS_WBW)
;
hwmon:
;;;  #if (PLATFORM == PLT_SZ180)
;;;	; Warn user that console is being directed to the S100 bus
;;;	; if the IOBYTE bit 0 is 0 (%xxxxxxx0).
;;;	in	a,($75)			; get IO byte
;;;	and	%00000001		; isolate console bit
;;;	jr	nz,hwmon1		; if 0, bypass msg
;;;	ld	hl,str_hwmoncon		; console msg string
;;;	call	pstr			; display it
;;;	jr	hwmon1			; do it
;;;;
;;;str_hwmoncon	.db	"\r\n\r\nConsole on Hardware Monitor",0
;;;  #endif
;;;;
;;;hwmon1:
	; Launch Hardware Monitor from ROM Bank 3
	call	ldelay			; wait for UART buf to empty
	;;;di				; suspend interrupts
	ld	a,HWMON_BNK + BID_IMG0	; hardware monitor bank offset by start of ROM APP banks
	ld	ix,HWMON_IMGLOC		; execution resumes here
	jp	HB_BNKCALL		; do it
;
str_hwmon	.db	"Hardware Monitor",0
;
#endif
;
;=======================================================================
; Utility functions
;=======================================================================
;
; Print string at HL on console, null terminated, HL incremented
;
pstr:
	push	af			; save AF
pstr1:
	ld	a,(hl)			; get next character
	inc	hl			; bump pointer regardless
	or	a			; set flags
	jr	z,pstr2			; done if null
	call	cout			; display character
	jr	pstr1			; loop till done
pstr2:
	pop	af			; restore AF
	ret				; return
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
	push	af
	ld	a,cr			; cr
	call	cout			; send it
	ld	a,lf			; lf
	call	cout			; send it and return
	pop	af
	ret
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
	cp	del			; del/rubout?
	jr	z,rdln_bs		; handle as backspace
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
	ld	hl,cmdbuf		; start of buffer
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
	or	a			; check for eol
	ret	z			; done if so
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
	or	a			; check for eol
	ret	z			; done if so
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
; Delay 16us (cpu speed compensated) including call/ret invocation
; Register A and flags destroyed
; No compensation for z180 memory wait states
; There is an overhead of 3ts per invocation
;   Impact of overhead diminishes as cpu speed increases
;
; cpu scaler (cpuscl) = (cpuhmz - 2) for 16us + 3ts delay
;   note: cpuscl must be >= 1!
;
; example: 8mhz cpu (delay goal is 16us)
;   loop = ((6 * 16) - 5) = 91ts
;   total cost = (91 + 40) = 131ts
;   actual delay = (131 / 8) = 16.375us
;
	; --- total cost = (loop cost + 40) ts -----------------+
delay:				; 17ts (from invoking call)	|
	ld	a,(cpuscl)	; 13ts				|
;								|
delay1:				;				|
	; --- loop = ((cpuscl * 16) - 5) ts ------------+	|
	dec	a		; 4ts			|	|
#if (BIOS == BIOS_WBW)	;			|	|
  #if (CPUFAM == CPU_Z180)	;			|	|
	or	a		; +4ts for z180		|	|
  #endif			;			|	|
#endif			;			|	|
	jr	nz,delay1	; 12ts (nz) / 7ts (z)	|	|
	; ----------------------------------------------+	|
;								|
	ret			; 10ts (return)			|
	;-------------------------------------------------------+
;
; Delay 16us * DE (cpu speed compensated)
; Register DE, A, and flags destroyed
; No compensation for z180 memory wait states
; There is a 27ts overhead for call/ret per invocation
;   Impact of overhead diminishes as DE and/or cpu speed increases
;
; cpu scaler (cpuscl) = (cpuhmz - 2) for 16us outer loop cost
;   note: cpuscl must be > 0!
;
; Example: 8MHz cpu, DE=6250 (delay goal is .1 sec or 100,000us)
;   inner loop = ((16 * 6) - 5) = 91ts
;   outer loop = ((91 + 37) * 6250) = 800,000ts
;   actual delay = ((800,000 + 27) / 8) = 100,003us
;
	; --- total cost = (outer loop + 27) ts ------------------------+
vdelay:				; 17ts (from invoking call)		|
;									|
	; --- outer loop = ((inner loop + 37) * de) ts ---------+	|
	ld	a,(cpuscl)	; 13ts				|	|
;								|	|
vdelay1:			;				|	|
	; --- inner loop = ((cpuscl * 16) - 5) ts ------+	|	|
#if (BIOS == BIOS_WBW)		;			|	|	|
  #if (CPUFAM == CPU_Z180)	;			|	|	|
	or	a		; +4ts for z180		|	|	|
  #endif			;			|	|	|
#endif				;			|	|	|
	dec	a		; 4ts			|	|	|
	jr	nz,vdelay1	; 12ts (nz) / 7ts (z)	|	|	|
	; ----------------------------------------------+	|	|
;								|	|
	dec	de		; 6ts				|	|
#if (BIOS == BIOS_WBW)		;				|	|	|
  #if (CPUFAM == CPU_Z180)	;				|	|
	or	a		; +4ts for z180			|	|
  #endif			;				|	|
#endif				;				|	|
	ld	a,d		; 4ts				|	|
	or	e		; 4ts				|	|
	jp	nz,vdelay	; 10ts				|	|
	;-------------------------------------------------------+	|
;									|
	ret			; 10ts (final return)			|
	;---------------------------------------------------------------+
;
; Delay about 0.5 seconds
; 500000us / 16us = 31250
;
ldelay:
	push	af
	push	de
	ld	de,31250
	call	vdelay
	pop	de
	pop	af
	ret
;
; Initialize delay scaler based on operating cpu speed
; HBIOS *must* be installed and available via rst 8!!!
; CPU scaler := max(1, (phimhz - 2))
;
delay_init:
#if (BIOS == BIOS_UNA)
	ld	c,$F8			; UNA bios get phi function
	rst	08			; returns speed in hz in de:hl
	ld	b,4			; divide mhz in de:hl by 100000h
delay_init0:
	srl	d			; ... to get approx cpu speed in
	rr	e			; ...mhz.  throw away hl, and
	djnz	delay_init0		; ...right shift de by 4.
	inc	e			; fix up for value truncation
	ld	a,e			; put in a
#else
	ld	b,BF_SYSGET		; HBIOS func=get sys info
	ld	c,BF_SYSGET_CPUINFO	; HBIOS subfunc=get cpu info
	rst	08			; call HBIOS, rst 08 not yet installed
	ld	a,l			; put speed in mhz in accum
#endif
	cp	3			; test for <= 2 (special handling)
	jr	c,delay_init1		; if <= 2, special processing
	sub	2			; adjust as required by delay functions
	jr	delay_init2		; and continue
delay_init1:
	ld	a,1			; use the min value of 1
delay_init2:
	ld	(cpuscl),a		; update cpu scaler value
	ret

#if (CPUMHZ < 3)
cpuscl	.db	1			; cpu scaler must be > 0
#else
cpuscl	.db	CPUMHZ - 2		; otherwise 2 less than phi mhz
#endif
;
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
; Short delay functions.  No clock speed compensation, so they
; will run longer on slower systems.  The number indicates the
; number of call/ret invocations.  A single call/ret is
; 27 t-states on a z80, 25 t-states on a z180.
;
;			; z80	z180
;			; ----	----
dly64:	call	dly32	; 1728	1600
dly32:	call	dly16	; 864	800
dly16:	call	dly8	; 432	400
dly8:	call	dly4	; 216	200
dly4:	call	dly2	; 108	100
dly2:	call	dly1	; 54	50
dly1:	ret		; 27	25
;
; Add hl,a
;
;   A register is destroyed!
;
addhla:
	add	a,l
	ld	l,a
	ret	nc
	inc	h
	ret
;
; Print the hex byte value in A
;
prthexbyte:
	push	af
	push	de
	call	hexascii
	ld	a,d
	call	cout
	ld	a,e
	call	cout
	pop	de
	pop	af
	ret
;
; Print the hex word value in BC
;
prthexword:
	push	af
	ld	a,b
	call	prthexbyte
	ld	a,c
	call	prthexbyte
	pop	af
	ret
;
; Print the hex dword value in DE:HL
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
; Convert binary value in A to ASCII hex characters in DE
;
hexascii:
	ld	d,a
	call	hexconv
	ld	e,a
	ld	a,d
	rlca
	rlca
	rlca
	rlca
	call	hexconv
	ld	d,a
	ret
;
; Convert low nibble of A to ASCII hex
;
hexconv:
	and	0Fh	     ; low nibble only
	add	a,90h
	daa
	adc	a,40h
	daa
	ret
;
#if (BIOS == BIOS_WBW)
;
; Get numeric chars and convert to 32-bit number returned in DE:HL
; IX points to start of char buffer
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
DIV32X8	.equ	div32x8
;
#include "encode.asm"	; baud rate encoding routine
;
encode	.equ	ENCODE
;
#endif
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
	ld	a,(curcon)		; get current console
	ld	c,a			; console unit to C
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
	ld	a,(curcon)		; get current console
	ld	c,a			; console unit to C
	ld	b,BF_CIOIN		; HBIOS func: input char
	rst	08			; HBIOS reads character
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
	ld	a,(curcon)		; get current console
	ld	c,a			; console unit to C
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
#if (BIOS == BIOS_WBW)
;
; Print list of all drives (WBW)
;
; Call the Rom App to perform this
;
prtall:
	ld	a,'D'			; "D"evice Inventory App
	jp	romboot			; Invoke the ROM App
;
#endif
;
#if (BIOS == BIOS_UNA)
;
; Print list of all drives (UNA)
;
; UNA has no place to put this in ROM, so it is done here.
;
prtall:
	ld	hl,str_devlst		; device list header string
	call	pstr			; display it
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
	call	prtdecb			; print it
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
	call	prtdecb			; print it
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
str_devlst	.db	"\r\n\r\nDisk Devices:",0
;
#endif

#if (DSKYENABLE)

;
;=======================================================================
; DSKY interface routines
;=======================================================================
;
dsky_stat:
	ld	b,BF_DSKYSTAT
	jr	dsky_hbcall
;
dsky_getkey:
	ld	b,BF_DSKYGETKEY
	jr	dsky_hbcall
;
dsky_show:
	ld	b,BF_DSKYSHOWSEG
	jr	dsky_hbcall
;
dsky_beep:
	ld	b,BF_DSKYBEEP
	jr	dsky_hbcall
;
dsky_l2on:
	ld	e,1
	jr	dsky_statled
dsky_l2off:
	ld	e,0
dsky_statled:
	ld	b,BF_DSKYSTATLED
	ld	d,1
	jr	dsky_hbcall
;
dsky_putled:
	ld	b,BF_DSKYKEYLEDS
	jr	dsky_hbcall
;
dsky_highlightallkeys:
	ld	hl,dsky_highlightallkeyleds
	jr 	dsky_putled
;
dsky_highlightkeysoff:
	ld	hl,dsky_highlightkeyledsoff
	jr 	dsky_putled
;
#endif
;
dsky_msg:
#if (BIOS == BIOS_WBW)
	ld	b,BF_DSKYMESSAGE
	jr	dsky_hbcall
;
dsky_hbcall:
	ld	a,(dskyact)
	or	a
	ret	z
	rst	08
#endif
	ret
;
;=======================================================================
; Error handlers
;=======================================================================
;
err_invcmd:
	ld	hl,str_err_invcmd
	jr	err
;
err_nodisk:
	ld	hl,str_err_nodisk
	jr	err
;
err_nomedia:
	ld	hl,str_err_nomedia
	jr	err
;
err_noslice:
	ld	hl,str_err_noslice
	jr	err
;
err_badslice:
	ld	hl,str_err_badslice
	jr	err
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
	call	pstr
	or	$ff			; signal error
	ret				; done
;
str_err_prefix	.db	bel,"\r\n\r\n*** ",0
str_err_invcmd	.db	"Invalid command",0
str_err_nodisk	.db	"Disk unit not available",0
str_err_nomedia	.db	"Media not present",0
str_err_noslice	.db	"Disk unit does not support slices",0
str_err_badslice .db	"Slice specified is illegal",0
str_err_nocon	.db	"Invalid character unit specification",0
str_err_diskio	.db	"Disk I/O failure",0
str_err_sig	.db	"No boot record",0
str_err_noboot	.db	"No bootable image",0
str_err_api	.db	"Unexpected hardware BIOS API failure",0
;
;=======================================================================
; Working data storage (initialized)
;=======================================================================
;
acmd_buf	.text	AUTO_CMD	; auto cmd string
		.db	0
acmd_len	.equ	$ - acmd_buf	; len of auto cmd
acmd_act	.dw	$00		; inactive by default
acmd_to		.db	BOOT_TIMEOUT	; auto cmd timeout -1 DISABLE, 0 IMMEDIATE
acmd_to_64	.db	64		; sub-second counter for acmd_to in 1/64s
;
defcmd_buf	.text	BOOT_DEFAULT	; default boot cmd
		.db	0
defcmd_len	.equ	$ - defcmd_buf	; len of def boot cmd
;
;=======================================================================
; Strings
;=======================================================================
;
str_banner	.db	PLATFORM_NAME
		.db	" Boot Loader",0
str_appboot	.db	" (App Boot)",0
str_autoboot	.db	"\rAutoBoot: ",0
str_autoact1	.db	"\rAutoBoot in ",0
str_autoact2	.db	" Seconds (<esc> aborts, <enter> now)... ",0
str_prompt	.db	"Boot [H=Help]: ",0
str_bs		.db	bs,' ',bs,0
str_leader	.db	"  ",0
str_spacer	.db	"           - ",0
str_reboot	.db	"\r\n\r\nRestarting System...",0
str_newcon	.db	"\r\n\r\n  Console on Unit #",0
str_chspeed	.db	"\r\n\r\n  Change speed now. Press a key to resume.",0
str_applst	.db	"\r\n\r\nROM Applications:",0
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
str_ldsec	.db	", Sector 0x",0
str_diaglvl	.db	"\r\n\r\nHBIOS Diagnostic Level: ",0
;
;
; Help text is broken into 3 pieces because an application mode boot
; does allow access to the ROM-hosted features.  The str_help2 portion
; is only displayed for a ROM boot.
;
str_help1:
		.db	"\r\n"
;;;		.db	"\r\n  L           - List ROM Applications"
		.db	"\r\n  <u>[.<s>]   - Boot from Disk <Unit>[.<Slice>]"
		.db	0
;;;;
;;;str_help2:
;;;#if (BIOS == BIOS_WBW)
;;;		.db	"\r\n  N           - Network Boot"
;;;#endif
;;;		.db	"\r\n  D           - Device Inventory"
;;;#if (BIOS == BIOS_WBW)
;;;		.db	"\r\n  S           - Slice Inventory"
;;;		.db	"\r\n  W           - RomWBW Configure"
;;;#endif
;;;		.db	0
;
str_help3:
#if (BIOS == BIOS_WBW)

		.db	"\r\n  I <u> [<b>] - Console Interface <Unit> [<Baud>]"
		.db	"\r\n  V [<v>]     - View/Set HBIOS Diagnostic [Verbosity>]"
#endif
		.db	"\r\n  R           - Reboot System"
		.db	0
;
;=======================================================================
; DSKY keypad led matrix masks
;=======================================================================
;
dsky_highlightallkeyleds	.db 	$3f,$3f,$3f,$3f,$00,$00,$00,$00
dsky_highlightkeyledsoff	.db 	$00,$00,$00,$00,$00,$00,$00,$00
;
;=======================================================================
; ROM Application Table
;=======================================================================
;
; Macro ra_ent:
;						WBW		UNA
; p1: Application name string adr		word (+0)	word (+0)
; p2: Application attributes			word (+2)	word (+2)
; p3: Console keyboard selection key		byte (+3)	byte (+3)
; p4: DSKY selection key			byte (+4)	byte (+4)
; p5: Application image bank			byte (+5)	word (+5)
; p6: Application image source address		word (+6)	word (+7)
; p7: Application image dest load address	word (+9)	word (+9)
; p8: Application image size			word (+10)	word (+11)
; p9: Application entry address			word (+12)	word (+13)
;
; Attributes bits:
;   7: Hidden menu entry
;   6: Quiet load
;
#if (BIOS == BIOS_WBW)
ra_name		.equ	0		; word ptr to asciiz
ra_attr		.equ	2		; byte
ra_conkey	.equ	3		; byte
ra_dskykey	.equ	4		; byte
ra_bnk		.equ	5		; byte
ra_src		.equ	6		; word ptr
ra_dest		.equ	8		; word ptr
ra_siz		.equ	10		; word
ra_ent		.equ	12		; word ptr
;
ra_entsiz	.equ	14		; table entry length
#endif
;
#if (BIOS == BIOS_UNA)			
ra_name		.equ	0		; word ptr to asciiz
ra_attr		.equ	2		; byte
ra_conkey	.equ	3		; byte
ra_dskykey	.equ	4		; byte
ra_bnk		.equ	5		; byte
ra_src		.equ	7		; word ptr
ra_dest		.equ	9		; word ptr
ra_siz		.equ	11		; word
ra_ent		.equ	13		; word ptr
;                                       
ra_entsiz	.equ	15		; table entry length
#endif
;
#define		ra_ent(p1,p2,p3,p4,p5,p6,p7,p8,p9) \
#defcont	.dw	p1 \
#defcont	.db	p2 \
#defcont	.db	p3 \
#if (DSKYENABLE)
#defcont	.db	p4 \
#else
#defcont	.db	$FF \
#endif
#if (BIOS == BIOS_WBW)
#defcont	.db	p5 \
#endif
#if (BIOS == BIOS_UNA)
#defcont	.dw	p5 \
#endif
#defcont	.dw	p6 \
#defcont	.dw	p7 \
#defcont	.dw	p8 \
#defcont	.dw	p9
;
; Note: The formatting of the following is critical. TASM does not pass
; macro arguments well. Ensure LAYOUT.INC holds the definitions for *_LOC,
; *_SIZ *_END and any code generated which does not include LAYOUT.INC is
; synced.
;
; Note: The loadable ROM images are placed in ROM banks starting with
; BID_IMG0.  The bank numbers below are an offset from BID_IMG0 because
; the actual bank id of BID_IMG0 varies per system.
;
; RomWBW supports a mechanism to load a complete
; new system dynamically as a runnable application (see appboot
; in hbios.asm).  In this case, the contents of BID_IMG0 will
; be pre-loaded into the currently executing ram bank thereby allowing
; those images to be dynamically loaded as well.  To support this
; concept, a pseudo-bank called bid_cur is used to specify the images
; normally found in BID_IMG0.  This special value will cause
; the associated image to be loaded from the currently executing bank
; which will be correct regardless of the load mode.  Images in other
; image banks (BID_IMG1).
;
#if (BIOS == BIOS_WBW)
;
ra_tbl:
;
;	Name		Attr	Key	Dsky	Bank		Src		Dest		Size		Entry
;	---------	------	------	-----	--------	-----		------- 	------- 	----------
ra_ent(str_dev,		$40,	'D',	$FF,	DEV_BNK,	DEV_IMGLOC,	DEV_LOC,	DEV_SIZ,	DEV_LOC)
ra_ent(str_slc,		$40,	'S',	$FF,	SLC_BNK,	SLC_IMGLOC,	SLC_LOC,	SLC_SIZ,	SLC_LOC)
ra_ent(str_nvr,		$40,	'W',	$FF,	NVR_BNK,	NVR_IMGLOC,	NVR_LOC,	NVR_SIZ,	NVR_LOC)
;;;#if (PLATFORM == PLT_SZ180)
ra_ent(str_hwmon,	$00,	'O',	$FF,	bid_cur,	$0000,		$0000,		$0000,		hwmon)
;;;#endif
ra_ent(str_mon,		$00,	'M',	KY_CL,	MON_BNK,	MON_IMGLOC,	MON_LOC,	MON_SIZ,	MON_SERIAL)
ra_ent(str_cpm22,	$00,	'C',	KY_BK,	CPM22_BNK,	CPM22_IMGLOC,	CPM_LOC,	CPM_SIZ,	CPM_ENT)
ra_ent(str_zsys,	$00,	'Z',	KY_FW,	ZSYS_BNK,	ZSYS_IMGLOC,	CPM_LOC,	CPM_SIZ,	CPM_ENT)
ra_ent(str_net,		$00,	'N',	$FF,	NET_BNK,	NET_IMGLOC,	NET_LOC,	NET_SIZ,	NET_LOC)
ra_ent(str_bas,		$00,	'B',	KY_DE,	BAS_BNK,	BAS_IMGLOC,	BAS_LOC,	BAS_SIZ,	BAS_LOC)
ra_ent(str_tbas,	$00,	'T',	KY_EN,	TBC_BNK,	TBC_IMGLOC,	TBC_LOC,	TBC_SIZ,	TBC_LOC)
ra_ent(str_fth,		$00,	'F',	KY_EX,	FTH_BNK,	FTH_IMGLOC,	FTH_LOC,	FTH_SIZ,	FTH_LOC)
ra_ent(str_play,	$00,	'P',	$FF,	GAM_BNK,	GAM_IMGLOC,	GAM_LOC,	GAM_SIZ,	GAM_LOC)
ra_ent(str_upd,		$00,	'X',	$FF,	UPD_BNK,	UPD_IMGLOC,	UPD_LOC,	UPD_SIZ,	UPD_LOC)
ra_ent(str_user,	$00,	'U',	$FF,	USR_BNK,	USR_IMGLOC,	USR_LOC,	USR_SIZ,	USR_LOC)
#if (DSKYENABLE)
ra_ent(str_dsky,	$80,	'Y',	KY_GO,	MON_BNK,	MON_IMGLOC,	MON_LOC,	MON_SIZ,	MON_DSKY)
#endif
ra_ent(str_egg,		$80,	'E',	$FF,	EGG_BNK,	EGG_IMGLOC,	EGG_LOC,	EGG_SIZ,	EGG_LOC)
;
		.dw	0		; table terminator
#endif
;
#if (BIOS == BIOS_UNA)
;
ra_tbl:
;
;	Name		Attr	Key	Dsky	Bank		Src		Dest		Size		Entry
;	---------	------	------	-----	--------	-----		------- 	------- 	----------
ra_ent(str_mon,		$00,	'M',	KY_CL,	MON_BNK,	MON_IMGLOC,	MON_LOC,	MON_SIZ,	MON_SERIAL)
ra_ent(str_cpm22,	$00,	'C',	KY_BK,	CPM22_BNK,	CPM22_IMGLOC,	CPM_LOC,	CPM_SIZ,	CPM_ENT)
ra_ent(str_zsys,	$00,	'Z',	KY_FW,	ZSYS_BNK,	ZSYS_IMGLOC,	CPM_LOC,	CPM_SIZ,	CPM_ENT)
#if (DSKYENABLE)
ra_ent(str_dsky,	$80,	'Y',	KY_GO,	bid_cur,	MON_IMGLOC,	MON_LOC,	MON_SIZ,	MON_DSKY)
#endif
;
		.dw	0		; table terminator
#endif
;
ra_tbl_app:
;
;	Name		Attr	Key	Dsky	Bank		Src		Dest		Size		Entry
;	---------	------	------	-----	--------	-----		------- 	------- 	----------
ra_ent(str_mon,		$00,	'M',	KY_CL,	bid_cur,	MON_IMGLOC,	MON_LOC,	MON_SIZ,	MON_SERIAL)
ra_ent(str_zsys,	$00,	'Z',	KY_FW,	bid_cur,	ZSYS_IMGLOC,	CPM_LOC,	CPM_SIZ,	CPM_ENT)
#if (DSKYENABLE)
ra_ent(str_dsky,	$80,	'Y',	KY_GO,	bid_cur,	MON_IMGLOC,	MON_LOC,	MON_SIZ,	MON_DSKY)
#endif
;
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
str_upd		.db	"XModem Flash Updater",0
str_user	.db	"User App",0
str_net		.db	"Network Boot",0
str_dev		.db	"Device Inventory",0
str_slc		.db	"Slice Inventory",0
str_nvr		.db	"RomWBW Configure",0
str_egg		.db	"Mandelbrot",0
str_blnk	.db	"",0
str_switches	.db	"FP Switches = 0x",0
str_nvswitches	.db	"NV Switches Found",0
newcon		.db	0
newspeed	.db	0
;
;=======================================================================
; Working data storage
;=======================================================================
;
		.fill	64,0		; 32 level stack
bl_stack	.equ	$		; ... top is here
;
#if (BIOS == BIOS_WBW)
bid_ldr		.db	0		; bank at startup
#endif
#if (BIOS == BIOS_UNA)
bid_ldr		.dw	0		; bank at startup
#endif
;
lba		.fill	4,0		; lba for load, dword
dma		.dw	0		; address for load
sps		.dw	0		; sectors per slice
mediaid		.db	0		; media id
;
bootmode	.db	0		; ROM, APP, or IMG boot
startmode	.db	0		; START_WARM or START_COLD
ra_tbl_loc	.dw	0		; points to active ra_tbl
bootunit	.db	0		; boot disk unit
bootslice	.db	0		; boot disk slice
loadcnt		.db	0		; num disk sectors to load
switches	.db	0		; front panel switches
diskcnt		.db	0		; disk unit count value
dskyact		.db	0		; DSKY active if != 0
;
#if (BIOS == BIOS_WBW)
curcon		.db	CIO_CONSOLE	; current console unit
ciocnt		.db	1		; count of char units
savcon		.db	0		; con save for conpoll
conpend		.db	$ff		; pending con unit (first <space> pressed)
#endif
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
;
;=======================================================================
; Disk buffers (uninitialized)
;=======================================================================
;
; Master Boot Record sector is read into area below.
; Note that this buffer is actually shared with bl_infosec
; buffer below.
;
bl_mbrsec	.equ	$
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
