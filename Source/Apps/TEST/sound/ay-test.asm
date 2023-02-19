;*****************************************************************************
;*****************************************************************************
;**                                                                         **
;**	AY-3-8910 Sound Test Program                                        **
;**	Author: Wayne Warthen -- 10/8/2017                                  **
;**                                                                         **
;*****************************************************************************
;*****************************************************************************
;
;=============================================================================
; Constants Section
;=============================================================================
;
; Hardware port addresses
;
rsel	.equ	$9A		; Register seelection port address
rdat	.equ	$9B		; Register data port address
acr	.equ	$9C		; Aux control register port address
;
; CPU speed for delay scaling
;
cpuspd	.equ	4		; CPU speed in MHz
;
; BDOS invocation constants
;
bdos	.equ	$0005		; BDOS invocation vector
print	.equ	9		; BDOS print function number
conwrt	.equ	2		; BDOS console write char
;
;=============================================================================
; Code Section
;=============================================================================
;
	.org	$100
;
	ld	(stksav),sp	; save incoming stack frame
	ld	sp,stack	; setup our private stack
;
	ld	de,banner	; load banner string address
	ld	c,print		; BDOS print function number
	call	bdos		; do it
;
	ld	a,$FF		; SCG board activation value
	out	(acr),a		; write value to ACR
;
	xor	a		; zero accum
	ld	(chan),a	; init channel number
;
chloop:
	; Test each channel
	call	tstchan		; test the current channel
	ld	hl,chan		; point to channel number
	ld	a,(chan)	; get current channel
	inc	a		; bump to next
	ld	(chan),a	; save it
	cp	3		; end of channels?
	jr	nz,chloop	; loop if not done
;
	ld	de,crlf		; newline
	ld	c,print		; BDOS print function
	call	bdos		; do it
;
	ld	sp,(stksav)	; restore stack
;
	ret			; end of program
;
tstchan:
	; Display channel being tested
	ld	de,chmsg	; point to channel message
	ld	c,print		; BDOS print function number
	call	bdos		; do it
	ld	a,(chan)	; get current channel number
	add	a,'A'		; offset to print as alpha
	ld	e,a		; put in E
	ld	c,conwrt	; BDOS console out function number
	call	bdos		; do it
	ld	de,chmsg2	; point to channel message
	ld	c,print		; BDOS print function number
	call	bdos		; do it
;
	ld	hl,0		; initial pitch value
	ld	(pitch),hl	; save it
;
	; Setup mixer register
	ld	a,(chan)	; get channel num (0-2)
	inc	a		; adjust index (1-3)
	ld	b,a		; and use as loop counter
	xor	a		; clear accum
	scf			; set carry
mixloop:
	rla			; rotate bit
	djnz	mixloop		; loop based on channel num
	cpl			; invert bits
	and	$FF		; so only target bit is cleared
	push	af		; save value
	ld	a,7		; mixer register
	out	(rsel),a	; select it
	pop	af		; recover value
	out	(rdat),a	; and set register value
;
	; Set channel volume to max
	ld	a,(chan)	; get channel
	add	a,8		; adjust for start of vol regs
	out	(rsel),a	; select register
	ld	a,$0F		; max volume
	out	(rdat),a	; write it
;
pitloop:
	; Pitch loop
	ld	a,(chan)	; get channel
	sla	a		; A := channel pitch reg, 2 bytes per chan
	out	(rsel),a	; select low byte register
	push	af		; save register
	ld	a,l		; get low byte of pitch value
	out	(rdat),a	; and write it to register
	pop	af		; recover register index
	inc	a		; inc to high byte pitch register
	out	(rsel),a	; select high byte register
	ld	a,h		; get high byte of pitch value
	out	(rdat),a	; and write it to register
;
	; Delay
	ld	b,cpuspd	; cpu speed scalar
dlyloop:
	call	dly64		; arbitrary delay
	djnz	dlyloop		; loop based on cpu speed
;
	; Next pitch value
	ld	hl,(pitch)	; get current pitch
	inc	hl		; increment
	ld	(pitch),hl	; save new value
	ld	a,h		; get high byte
	;cp	16		; end of max range?
	cp	4		; end of max range?
	jr	nz,pitloop	; loop till done
;
	; Clean up
	call	clrpsg		; shut down psg
;
	ret			; done
;
; Clear PSG registers to default
;
clrpsg:
	ld	b,16		; loop for 18 registers
	ld	c,0		; init register index
clrpsg1:
	ld	a,c		; register num to accum
	out	(rsel),a	; select it
	xor	a		; clear accum
	out	(rdat),a	; and write to register
	inc	c		; next register
	djnz	clrpsg1		; loop through all registers
	ret			; return
;
; Program PSG registers from list at HL
;
setpsg:
	ld	a,(hl)		; get psg reg number
	inc	hl		; bump index
	cp	$FF		; check for end
	ret	z		; return if end marker $FF
	out	(rsel),a	; select psg register
	ld	a,(hl)		; get register value
	inc	hl		; bump index
	out	(rdat),a	; set register value
	jr	setpsg		; loop till done
;
; Short delay functions.  No clock speed compensation, so they
; will run longer on slower systems.  The number indicates the
; number of call/ret invocations.  A single call/ret is
; 27 t-states on a z80, 25 t-states on a z180
;
dly256:	call	dly128
dly128:	call	dly64
dly64:	call	dly32
dly32:	call	dly16
dly16:	call	dly8
dly8:	call	dly4
dly4:	call	dly2
dly2:	call	dly1
dly1:	ret
;
;=============================================================================
; Data Section
;=============================================================================
;
chan	.db	0		; active audio channel
pitch	.dw	0		; current pitch
;
banner	.text	"\r\nRetroBrew Computers SCG AY-3-8910 Sound Test\r\n"
	.text	"Set SCG board base I/O address to 0x98\r\n$"
chmsg	.text	"\r\nPlaying descending tones on channel $"
chmsg2	.text	"...$"
crlf	.text	"\r\n$"
;
stksav	.dw	0		; saved stack frame
	.fill	80,$FF		; 40 level private stack
stack	.equ	$		; start of stack
;
	.end