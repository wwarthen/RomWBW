begin.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
BDOS	equ	5
	extrn Croot_
	extrn _Uorg_, _Uend_
;
	public	lnprm, lntmp, lnsec
;	
;	The 3 "bss" statements below must remain in EXACTLY the same order,
;	with no intervening statements!
;
	bss	lnprm,4
	bss	lntmp,4
	bss	lnsec,4
;
	global	sbot,2
	global	errno_,2
	global	_mbot_,2
	dseg
	public	Sysvec_
Sysvec_:	dw	0
	dw	0
	dw	0
	dw	0
	public	$MEMRY
$MEMRY:	dw	0ffffh
;
fcb:	db	0,'???????????',0,0,0,0
	ds	16
	cseg
	public	.begin
	public	_exit_
.begin:
	lxi	h,_Uorg_
	lxi	b,_Uend_-_Uorg_
	mvi	e,0
clrbss:
	mov	m,e
	inx	h
	dcx	b
	mov	a,c
	ora	b
	jnz	clrbss
;
	LHLD	BDOS+1
	SPHL
	lxi	d,-2048
	dad	d		;set heap limit at 2K below stack
	shld	sbot
	lhld	$MEMRY
	shld	_mbot_
	CALL	Croot_
_exit_:
	mvi	c,17	;search for first (used to flush deblock buffer)
	lxi	d,fcb
	call	BDOS
	lxi	b,0
	call	BDOS
	JMP	_exit_
;
	end	.begin
mbegin.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
BDOS	equ	5
	extrn Croot_
	dseg
;	
;	The 3 "ds 4" statements below must remain in EXACTLY the same order,
;	with no intervening statements!
;
	public	lnprm, lntmp, lnsec
lnprm:	ds	4
lntmp:	ds	4
lnsec:	ds	4
;
	public	Sysvec_
Sysvec_:	dw	0
	dw	0
	dw	0
	dw	0
	public	$MEMRY
$MEMRY:	dw	-1
	public	sbot
sbot: dw	0
	public	errno_
errno_:	dw	0
;
fcb:	db	0,'???????????',0,0,0,0
	ds	16
	cseg
	public	.begin
	public	_exit_
.begin:
	LHLD	BDOS+1
	SPHL
	lxi	d,-2048
	dad	d		;set heap limit at 2K below stack
	shld	sbot
	CALL	Croot_
_exit_:
	mvi	c,17	;search for first (used to flush deblock buffer)
	lxi	d,fcb
	call	BDOS
	lxi	b,0
	call	BDOS
	JMP	_exit_
	end	.begin
rom.asm
;Copyright (C) 1983 by Manx Software Systems
; :ts=8
;
;	stksize should be set according to your program's needs
;
stksize	equ	1024
	bss	stack,stksize

	extrn	main_
	extrn	_Corg_, _Cend_
	extrn	_Dorg_, _Dend_
	extrn	_Uorg_, _Uend_
;	
;	The 3 "bss" statements below must remain in EXACTLY the same order,
;	with no intervening statements!
;
	public	lnprm, lntmp, lnsec
	bss	lnprm,4
	bss	lntmp,4
	bss	lnsec,4
;
	global	errno_,2
	dseg
	public	Sysvec_
Sysvec_:	dw	0
	dw	0
	dw	0
	dw	0
	public	$MEMRY
$MEMRY:	dw	0ffffh
	cseg
	public	.begin
.begin:
	di
	lxi	sp,stack+stksize
;
;	The loop below moves the initialized data from ROM to RAM.
;	If your program has no initialized data, or the initialized
;	data isn't modified, then delete this loop.
;
	lxi	h,_Cend_
	lxi	d,_Dorg_
	lxi	b,_Dend_-_Dorg_
	mov	a,h
	cmp	d
	jnz	movedata
	mov	a,l
	cmp	e
	jz	movedone
movedata:
;	If your processor is a Z80, then remove the comment from the
;	next line and comment out the next 8 lines.
;	db	237,176		;ldir
	mov	a,m
	stax	d
	inx	h
	inx	d
	dcx	b
	mov	a,c
	ora	b
	jnz	movedata
movedone:
;
	lxi	h,_Uorg_
	lxi	b,_Uend_-_Uorg_
	mvi	e,0
clrbss:
	mov	m,e
	inx	h
	dcx	b
	mov	a,c
	ora	b
	jnz	clrbss
;
	ei
				;no argc,argv in ROM system
	jmp	main_		;main shouldn't return in ROM based system
	end	.begin
csave.asm
;Copyright (C) 1981,1982,1984 by Manx Software Systems
; :ts=8
	extrn	.begin
	public	.chl
.chl:	PCHL
;
	public zsave,zret
zsave: POP H
	PUSH	B
	MOV	B,H
	MOV	C,L
	LXI	H,0
	DAD	SP
	XCHG
	DAD	SP
	SPHL
	PUSH	D
	DB	221,229,253,229	;push ix ; push iy
	mov	h,b
	mov	l,c
	call	.chl
;
zret:
	DB	253,225,221,225	; pop iy ; pop ix
cret:
	XCHG
	POP	H
	SPHL
	POP	B
	XCHG
	MOV	A,H
	ORA	L
	RET
;
	public csave,cret
csave:	POP H
	PUSH	B
	MOV	B,H
	MOV	C,L
	LXI	H,0
	DAD	SP
	XCHG
	DAD	SP
	SPHL
	PUSH	D
	lxi	h,cret
	push	h
	mov	h,b
	mov	l,c
	pchl
;
;	move - move BC bytes from (HL) to (DE), used for struct assignment
;
	public .move
.move:
	mov a,m
	stax d
	inx h
	inx d
	dcx b
	mov a,b
	ora c
	jnz .move
	ret
;
	public	.ARG1,.ARG2,.ARG3,.asave
;
.asave:		;support for assembly routines which must save IX and IY
	pop	d		;save return address
	lxi	h,2		;compute address of arguments
	dad	sp
	xra	a
	adi	3
	jpe	nopush
	DB 221,229,253,229	;push ix ; push iy
nopush:
	PUSH B
	push	d		;put return addr back
	lxi	d,.ARG1
	mvi	b,6
cpyloop:			;copy args to known place
	mov	a,m
	stax	d
	inx	h
	inx	d
	dcr	b
	jnz	cpyloop
	lxi	h,asmret
	xthl
	pchl
;
asmret:
	POP B
	xra	a
	adi	3
	jpe	nopop
	DB 253,225,221,225	; pop iy ; pop ix
nopop:
	mov a,h
	ora l
	RET
;
	dseg
.ARG1:	ds	2
.ARG2:	ds	2
.ARG3:	ds	2
	end
fmtcvt.asm
; Copyright (C) 1983 by Manx Software Systems
; :ts=8
	dseg
string:	ds	2
size:	dw	0
number:	ds	4
	cseg
	public	fmtcvt_
fmtcvt_:			;char *fmtcvt(ptr, base, buffer, size)
	push	b
	lxi	h,0
	shld	number
	shld	number+2
	lxi	h,10
	dad	sp
	mov	a,m
	sta	size
	mov	b,a		;save size for later
	dcx	h
	mov	d,m
	dcx	h
	mov	e,m
	dcx	h
	xchg
	mvi	m,0		;null terminate string
	shld	string
	xchg
	dcx	h
	mov	c,m		;C = base
	dcx	h
	mov	d,m
	dcx	h
	mov	e,m
	lxi	h,number
cpnum:
	ldax	d
	mov	m,a
	inx	d
	inx	h
	dcr	b
	jnz	cpnum

	mov	a,c
	ora	a
	jp	unsigned	; base < 0, means do signed conversion
	cma
	inr	a
	mov	c,a		;C = base
	lhld	size
	lxi	d,number-1
	dad	d
	mov	a,m
	ora	a
	push	psw
	jp	top
				;number is negative, so make it positive
		;note: carry is already cleared by 'ora' above
	lda	size
	mov	b,a
	lxi	h,number
ngloop:
	mvi	a,0
	sbb	m
	mov	m,a
	inx	h
	dcr	b
	jnz	ngloop
	jmp	top
unsigned:
	push	psw
top:
	lxi	h,number+3
	mvi	d,0
	mvi	a,4
outer:
	push	psw
	mov	e,m
	xchg
	mvi	b,8
inner:
	dad	h
	mov	a,h
	sub	c
	jc	zero
	mov	h,a
	inr	l
zero:
	dcr	b
	jnz	inner
	xchg
	mov	m,e
	dcx	h
	pop	psw
	dcr	a
	jnz	outer
;
	mov	e,d
	mvi	d,0
	lxi	h,digits
	dad	d
	mov	a,m
	lhld	string
	dcx	h
	shld	string
	mov	m,a
;
	lxi	h,number
	mvi	b,4
	xra	a
zcheck:
	cmp	m
	jnz	top
	inx	h
	dcr	b
	jnz	zcheck

	lhld	string
	pop	psw
	jp	notneg
	dcx	h
	mvi	m,'-'
notneg:
	pop	b
	ret
;
digits:	db	'0123456789abcdef'
	end
blkio.asm
; Copyright (C) 1982, 1983 by Manx Software Systems
; :ts=8
BDOS	equ	5
	extrn	errno_
	extrn	.asave,.ARG1,.ARG2,.ARG3
	public blkrd_
blkrd_:
	call	.asave
	mvi	c,33		;set function to read sequential
	jmp	rdwrt
;
	public	blkwr_
blkwr_:
	call	.asave
	mvi	c,34		;set function to write sequential
rdwrt:
	push	b
ioloop:
	lhld	.ARG2
	xchg
	lxi	h,128
	dad	d			;bump address to next sector
	shld	.ARG2
	mvi	c,26		;set DMA address
	call	BDOS
	pop	b
	push	b
	lhld	.ARG1
	xchg
	call	BDOS	;read or write sector
	ora	a
	jnz	ioerr
	lhld	.ARG1
	lxi	d,33
	dad	d
	inr	m
	jnz	nocarry
	inx	h
	inr	m
nocarry:
	lhld	.ARG3
	dcx	h
	shld	.ARG3
	mov	a,l
	ora	h
	jnz	ioloop
	pop	b		;pull function code from stack
	ret				;all done, return number remaining
;
ioerr:
	cpi	1
	jz	dontset
	cpi	4
	jz	dontset
	mov	l,a
	mvi	h,0
	shld	errno_
dontset:
	pop	b		;pull function code from stack
	lhld	.ARG3
	ret				;return number remaining
	end
bdos.asm
;Copyright (C) 1981,1982 by Manx Software Systems
; :ts=8
BASE	equ	0
BDOS	equ	5

	extrn	.ARG1,.ARG2,.ARG3,.asave
;
	public	bdoshl_
bdoshl_:
	call	.asave
	call	combdos
	xchg			;get back original hl value
	ret
;
	public	bdos_,CPM_
bdos_:
CPM_:
	call	.asave
combdos:
	lhld	.ARG1
	mov	b,h
	mov	c,l
	lhld	.ARG2
	xchg
	CALL	BDOS
	xchg		;save for bdoshl call
	mov	l,a
	xra	a		;set zero flag
	mov	h,a
	RET
	end
bios.asm
;Copyright (C) 1981,1982 by Manx Software Systems
BASE	equ	0
BDOS	equ	5

	extrn	.ARG1,.ARG2,.ARG3,.asave
;
	public	bios_
bios_:
	call	.asave
	call	combios
	mov	l,a
	mvi	h,0
	ret
;
	public	bioshl_
bioshl_:
	call	.asave
combios:
	lhld	.ARG1
	xchg
	lhld	BASE+1
	dcx	h
	dcx	h
	dcx	h
	dad	d
	dad	d
	dad	d
	xchg			;bios jump addr in DE

	lhld	.ARG2
	mov	b,h
	mov	c,l
	lhld	.ARG3
	xchg			;now arg3 in DE, and bios jump in HL
	pchl
	end
fcbinit.asm
;Copyright (C) 1981,1982 by Manx Software Systems
; :ts=8
	public	fcbinit_
fcbinit_:
	push	b
	lxi	h,4
	dad	sp
	mov	c,m		; BC contains name
	inx	h
	mov	b,m
	inx	h
	mov	e,m		; DE contains fcb address
	inx	h
	mov	d,m
;				clear name to blanks
	mov	l,e		;copy fcb address into HL
	mov	h,d
	mvi	m,0		;clear drive #
	inx	h
	mvi	a,11		;clear name and ext to blanks
clrlp:
	mvi	m,' '
	inx	h
	dcr	a
	jnz	clrlp
	mvi	a,4
zrlp:
	mvi	m,0
	inx	h
	dcr	a
	jnz	zrlp
	xchg			; now HL contains fcb addr
;
	mov	a,c
	ora	b
	jz	badname
skipbl:
	ldax	b
	cpi	' '
	jz	skip
	cpi	9
	jnz	skipdone
skip:	inx	b
	jmp	skipbl
skipdone:
;
	push	b		;save address of name
	mvi	d,0		;init user #
userloop:
	ldax	b
	call	isdig
	jc	userdone
	sui	'0'
	mov	e,a
	mov	a,d
	add	a		;*2
	add	a		;*4
	add	a		;*8
	add	d		;*9
	add	d		;*10
	add	e		;add in digit
	mov	d,a
	inx	b
	jmp	userloop
userdone:
	cpi	'/'
	jnz	nouser
	inx	b
	pop	psw		;throw away saved address
	jmp	setuser
nouser:
	pop	b		;restore original address
	mvi	d,255		;set user # to default
setuser:
	inx	b
	ldax	b
	cpi	':'
	dcx	b
	mvi	a,0
	jnz	nodrive
;
	ldax	b
	ani	127
	cpi	'A'
	jc	badname
	cpi	'Z'+1
	jnc	lowerc
	sui	'A'-1
	jmp	setdrive
;
lowerc:
	cpi	'a'
	jc	badname
	cpi	'z'+1
	jnc	badname
	sui	'a'-1
setdrive:
	mov	m,a
	inx	b
	inx	b
nodrive:
	inx	h
;				move name in mapping to upper case
	mvi	e,8
nameskp:
	inr	e
namelp:
	ldax	b
	inx	b
	cpi	'.'
	jz	namedn
	ora	a
	jz	alldone
	dcr	e
	jz	nameskp
	call	toupper
	mov	m,a
	inx	h
	jmp	namelp
;
namedn:
	dcr	e
	mov	a,e
	add	l
	mov	l,a
	mov	a,h
	aci	0
	mov	h,a
;					move extension mapping to upper case
	mvi	e,3
extlp:
	ldax	b
	inx	b
	ora	a
	jz	alldone
	call	toupper
	mov	m,a
	inx	h
	dcr	e
	jnz	extlp
;
alldone:
	mvi	h,0
	mov	l,d		;return user # prefix
	mov	a,d
	ora	a
	pop	b
	ret
;
badname:
	lxi	h,-1
	mov	a,h
	ora	a
	pop	b
	ret
;
toupper:
	cpi	'*'
	jnz	nostar
	dcx	b		;back up so we see star again
	mvi	a,'?'		;and map into question
	ret
nostar:
	cpi	'a'
	rc
	cpi	'z'+1
	rnc
	sui	'a'-'A'
	ret
;
isdig:
	cpi	'0'
	rc
	cpi	'9'+1
	jnc	notdig
	ora	a
	ret
notdig:
	stc
	ret
;
	end
sbrk.asm
;Copyright (C) 1981,1982 by Manx Software Systems
;Copyright (C) 1983,1984 by Manx Software Systems
; :ts=8
	extrn	$MEMRY, sbot
;
; sbrk(size): return address of current top & bump by size bytes
;
	public	sbrk_
sbrk_:
	lxi	h,2
	dad	sp
	mov	e,m		; get size to allocate
	inx	h
	mov	d,m
	lhld	$MEMRY
	dad	d
	jc	sbrk.ov
	xchg		;save for compare
	lhld	sbot
	mov	a,l		;check for stack/heap overflow
	sub	e
	mov	a,h
	sbb	d
	jc	sbrk.ov
	lhld	$MEMRY	;get old value
	xchg
	shld	$MEMRY	;new value is good so save it away
	xchg		;return original value
	mov	a,h
	ora	l
	ret
; no space left!!
sbrk.ov:
	lxi	h,-1
	xra	a
	dcr	a
	ret
;
;
; rsvstk(size): reserve size bytes of stack space
;
	public	rsvstk_
rsvstk_:
	lxi	h,2
	dad	sp
	mov	a,l
	sub	m
	mov	e,a
	mov	a,h
	inx	h
	sbb	m
	mov	d,a
	xchg
	shld	sbot
	ret
	end
loader.asm
; Copyright (C) 1984 by Manx Software Systems
; :ts=8
;	The C routine execl() in exec.c knows that this function is
;	less than 70 bytes long.  If this code is changed, then execl
;	must be changed also.
;
;	This routine is copied into an automatic array and invoked
;	there by execl().  The code is self relocating and must
;	remain so.
;
bdos	equ	5
defdma	equ	80h
tpa	equ	100h
	public	ldr__		; ldr_(&fcb, ouser)
ldr__:
	pop	d		;throw away return
	pop	b		;set up fcb address
	lxi	d,9
	dad	d		;fix hl to point to head of loop
	lxi	d,tpa
;
;	bc = fcb address
;	de = tpa address
;	hl = address of this routine
;	old user # pushed onto stack
;
	push	h		;save loop address
	push	d
	push	b
	mvi	c,26
	call	bdos
	pop	d
	push	d
	mvi	c,20
	call	bdos
	pop	b		;restore fcb address
	pop	d		;and loading addr.
	lxi	h,80h
	dad	d		;bump loading addr
	xchg
	pop	h
	push	h		;restore loop address
	ora	a		;check if eof
	rz			;if not, return to top of loop
	pop	h		;throw away return addr
	pop	d		;get old user #
	mvi	c,32
	call	bdos		;restore user #
	lxi	d,defdma
	mvi	c,26
	call	bdos
	lhld	bdos+1
	sphl
	lxi	h,0
	push	h		;set for proper return from program
	jmp	tpa
	end
user.asm
; Copyright (C) 1983 by Manx Software Systems
; :ts=8
BDOS	equ	5
	extrn	.asave,.ARG1,.ARG2,.ARG3
	dseg
oldusr:	db	0
	cseg
	public getusr_
getusr_:
	call	.asave
	mvi	c,32
	mvi	e,255
	call	BDOS		;get current user #
	mov	l,a
	mvi	h,0
	ora	a
	ret
;
	public setusr_
setusr_:
	call	.asave
	mvi	c,32
	mvi	e,255
	call	BDOS
	sta	oldusr
	lda	.ARG1
	cpi	255
	rz
	mvi	c,32
	mov	e,a
	jmp	BDOS	;set new user number
;
	public	rstusr_
rstusr_:
	call	.asave
	mvi	c,32
	lda	oldusr
	mov	e,a
	jmp	BDOS	;restore old user number
	end
setjmp.asm
; Copyright (C) 1983 by Manx Software Systems
; :ts=8
	public	setjmp_
setjmp_:
	lxi	h,2
	dad	sp
	mov	e,m		;get address of jump buffer
	inx	h
	mov	d,m
	dcx	h		;get SP value back
	xchg
	mov	m,e		;save SP value
	inx	h
	mov	m,d
	inx	h
	pop	d
	push	d
	mov	m,e		;save PC value
	inx	h
	mov	m,d
	inx	h
	mov	m,c		;save BC value
	inx	h
	mov	m,b
	xra	a
	adi	3
	jpe	setdone
	inx	h
	db	221,229		;push ix
	pop	d
	mov	m,e		;save IX value
	inx	h
	mov	m,d
	inx	h
	db	253,229		;push iy
	pop	d
	mov	m,e		;save IY value
	inx	h
	mov	m,d
setdone:
	lxi	h,0
	xra	a		;set zero flag
	ret
;
	public	longjmp_
longjmp_:
	lxi	h,2
	dad	sp
	mov	e,m		;get address of jump buffer
	inx	h
	mov	d,m
	inx	h
	mov	c,m		;get return value
	inx	h
	mov	b,m
	xchg
	mov	e,m		;get SP value
	inx	h
	mov	d,m
	inx	h
	xchg
	sphl			;switch to original stack
	xchg
	mov	e,m		;get PC value
	inx	h
	mov	d,m
	inx	h
	push	d		;save for return
	push	b		;save return value
	mov	c,m		;get BC value
	inx	h
	mov	b,m
	xra	a
	adi	3
	jpe	longdone
	inx	h
	mov	e,m		;get IX value
	inx	h
	mov	d,m
	inx	h
	push	d
	db	221,225		;pop ix
	mov	e,m		;get IY value
	inx	h
	mov	d,m
	push	d
	db	253,225		;pop iy
longdone:
	pop	h
	mov	a,l
	ora	h
	rnz
	inx	h		;force non-zero return
	inr	a		;set non-zero flag
	ret
	end
strcmp.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
	public strcmp_
strcmp_:
	lxi	h,5
	dad	sp
	push	b
	lxi	b,32767
	jmp	same
;
	public strncmp_
strncmp_:
	lxi	h,7
	dad	sp
	push	b
	mov	b,m
	dcx	h
	mov	c,m		;BC = len
	dcx	h
same:
	mov	d,m
	dcx	h
	mov	e,m		;DE = s2
	dcx	h
	mov	a,m
	dcx	h
	mov	l,m
	mov	h,a		;HL = s1
	xchg			;now DE=s1, HL=s2
cmploop:
	mov	a,b	;while (len) {
	ora	c
	jz	done
	ldax	d		;if (*s1-*s2) break
	sub	m
	jnz	done
	ldax	d		;if (*s1 == 0) break
	ora	a
	jz	done
	inx	d		;++s1
	inx	h		;++s2
	dcx	b		;--len
	jmp	cmploop	;}
done:
	pop	b
	mov	l,a
	sbb	a
	mov	h,a
	ora	l
	ret
	end
strcpy.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
	public strcpy_
strcpy_:
	lxi	h,5
	dad	sp
	mov	d,m
	dcx	h
	mov	e,m		;DE = s2
	dcx	h
	mov	a,m
	dcx	h
	mov	l,m
	mov	h,a		;HL = s1
	push	h		;save target for return
cpyloop:
	ldax	d		;while (*s1++ = *s2++) ;
	mov	m,a
	ora	a
	jz	done
	inx	d
	inx	h		;++s2
	jmp	cpyloop	;}
done:
	pop	h		;return target address
	mov	a,h
	ora	l
	ret
	end
strncpy.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
	public strncpy_
strncpy_:
	lxi	h,7
	dad	sp
	push	b
	mov	b,m
	dcx	h
	mov	c,m		;BC = len
	dcx	h
	mov	d,m
	dcx	h
	mov	e,m		;DE = s2
	dcx	h
	mov	a,m
	dcx	h
	mov	l,m
	mov	h,a		;HL = s1
	push	h		;save target for return
cpyloop:
	mov	a,b	;while (len) {
	ora	c
	jz	done
	ldax	d		;if (*s1 = *s2) ++s1
	mov	m,a
	ora	a
	jz	padding
	inx	d
padding:
	inx	h		;++s2
	dcx	b		;--len
	jmp	cpyloop	;}
done:
	pop	h		;return target address
	pop	b
	mov	a,h
	ora	l
	ret
	end
strcat.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
	public strcat_		;strcat(s1,s2)
strcat_:
	lxi	h,5
	dad	sp
	push	b
	lxi	b,32767
	jmp	same
;
	public strncat_		;strncat(s1,s2,len)
strncat_:
	lxi	h,7
	dad	sp
	push	b
	mov	b,m
	dcx	h
	mov	c,m		;BC = len
	dcx	h
same:
	mov	d,m
	dcx	h
	mov	e,m		;DE = s2
	dcx	h
	mov	a,m
	dcx	h
	mov	l,m
	mov	h,a		;HL = s1
	push	h		;save destination for return value
	xra	a
eloop:
	cmp	m		;while (*s1) ++s1;
	jz	cpyloop
	inx	h
	jmp	eloop	;}
cpyloop:			;while (len) {
	mov	a,b
	ora	c
	jz	done
	ldax	d			;if ((*s1 = *s2) == 0) break
	mov	m,a
	ora	a
	jz	done
	inx	d			;++s1
	inx	h			;++s2
	dcx	b			;--len
	jmp	cpyloop		;}
done:
	mov	m,a		;guarantee null termination
	pop	h
	pop	b
	mov	a,h
	ora	l
	ret
	end
index.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
	public index_
index_:
	lxi	h,2
	dad	sp
	mov	e,m		;DE = destination
	inx	h
	mov	d,m
	inx	h
	mov	l,m
	xchg		;e has char to look for
scan:
	mov	a,m
	cmp	e
	jz	foundit
	ora	a
	jz	noluck
	inx	h
	jmp	scan
;
noluck:
	lxi h,0
	xra a
	ret
;
foundit:
	mov a,h
	ora l
	ret
	end
rindex.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
	public rindex_
rindex_:
	push	b
	lxi	h,4
	dad	sp
	mov	e,m		;DE = destination
	inx	h
	mov	d,m
	inx	h
	mov	l,m
	xchg		;e has char to look for
	lxi	b,0
	xra	a
toend:
	cmp	m		;scan for end of string
	jz	scan
	inx	h
	inx	b
	jmp	toend

scan:
	mov	a,b
	ora	c
	jz	noluck
	dcx	b
	dcx	h
	mov	a,m
	cmp	e
	jnz	scan
	mov a,h
	ora l
	pop b
	ret
noluck:
	lxi h,0
	xra a
	pop b
	ret
;
	end
strlen.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
	public strlen_
strlen_: LXI H,2
	DAD SP
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	LXI D,0
	XRA A
.stl:	CMP M
	JZ	.stlx
	INX D
	INX H
	JMP .stl
.stlx:	XCHG
	mov a,l
	ora h
	RET
	end
setmem.asm
;Copyright (C) 1983 by Manx Software Systems
	public setmem_
setmem_: push b
	lxi h,4
	dad sp
	mov e,m
	inx h
	mov d,m
	inx h
	mov c,m
	inx h
	mov b,m
	inx h
	mov l,m
	xchg
setloop:
	mov a,b
	ora c
	jz done
	mov m,e
	inx h
	dcx b
	jmp setloop
done: pop b
	ret
	end
movmem.asm
;Copyright (C) 1983 by Manx Software Systems
; :ts=8
	public movmem_		;movmem(src,dst,len)
movmem_:
	push	b
	lxi	h,9
	dad	sp
	mov	b,m			;BC=len
	dcx	h
	mov	c,m
	dcx	h
	mov	d,m			;DE=dst
	dcx	h
	mov	e,m
	dcx	h
	mov	a,m
	dcx	h
	mov	l,m			;HL=src
	mov	h,a
	cmp	d
	jc	movedown
	jnz	moveup
	mov	a,l
	cmp	e
	jc	movedown
	jz	done
moveup:				;src > dst
	dad	b
	xchg
	dad	b
	xra	a
	adi	3		;test if z80
	jpe	uploop		;not z80 use loop to move data
	xchg
	dcx	d
	dcx	h
	db	237,184		;lddr
	pop	b
	ret
;
uploop:			;HL=dst, DE=src
	dcx	d
	dcx	h
	ldax	d
	mov	m,a
	dcx	b
	mov	a,b
	ora	c
	jnz	uploop
	pop	b
	ret
;
movedown:			;src < dst
	xra	a
	adi	3		;test if z80
	jpe	downloop	;not z80 use loop to move data
	db	237,176		;ldir
	pop	b
	ret
;
downloop:
	mov	a,m
	stax	d
	inx	d
	inx	h
	dcx	b
	mov	a,b
	ora	c
	jnz	downloop
done:
	pop	b
	ret
	end
swapmem.asm
; Copyright (C) 1983 by Manx Software Systems
; :ts=8
	public	swapmem_	;swapmem(s1,s2,len)
swapmem_:
	lxi	h,7
	dad	sp
	push	b
	mov	b,m
	dcx	h
	mov	c,m		;BC = len
	dcx	h
	mov	d,m
	dcx	h
	mov	e,m		;DE = s2
	dcx	h
	mov	a,m
	dcx	h
	mov	l,m
	mov	h,a		;HL = s1

	mov	a,c
	ora	a
	jnz	bok
	dcr	b
bok:
	push	b
swaploop:
	mov	b,m
	ldax	d
	mov	m,a
	mov	a,b
	stax	d
	inx	h
	inx	d
	dcr	c
	jnz	swaploop
	pop	psw
	ora	a
	jz	done
	dcr	a
	push	psw
	jmp	swaploop
done:
	pop	b
	ret
	end
toupper.asm
;Copyright (C) 1981,1982 by Manx Software Systems
; :ts=8
	public toupper_
toupper_:
	lxi	h,2
	dad	sp
	mov	a,m
	cpi	'a'
	jc	skip
	cpi	'z'+1
	jnc	skip
	sui	'a'-'A'
skip:
	mov	l,a
	mvi	h,0
	ora	a
	ret
;
;
	public tolower_
;
tolower_:
	lxi	h,2
	dad	sp
	mov	a,m
	cpi	'A'
	jc	skip2
	cpi	'Z'+1
	jnc	skip2
	adi	'a'-'A'
skip2:
	mov	l,a
	mvi	h,0
	ora	a
	ret
	end
lsubs.asm
; Copyright (C) 1982, 1983, 1984 by Manx Software Systems
; :ts=8
	extrn	lnprm,lntmp,lnsec
;
	public	.llis		;load long immediate secondary
.llis:
	pop	d		;get return addr
	lxi	h,4		;size of long
	dad	d
	push	h		;put back correct return addr
	xchg
			;fall through into .llds
;
	public	.llds		;load long into secondary accum
.llds:
	lxi	d,lnsec
	jmp	lload
;
	public	.llip		;load long immediate primary
.llip:
	pop	d		;get return addr
	lxi	h,4		;size of long
	dad	d
	push	h		;put back correct return addr
	xchg
			;fall through into .lldp
;
	public .lldp		;load long into primary accum
.lldp:
	lxi	d,lnprm
lload:
	mov	a,m
	stax	d
	inx	d
	inx	h
	mov	a,m
	stax	d
	inx	d
	inx	h
	mov	a,m
	stax	d
	inx	d
	inx	h
	mov	a,m
	stax	d
	ret
;
	public .lst		;store long at addr in HL
.lst:
	lxi	d,lnprm
	ldax	d
	mov	m,a
	inx	h
	inx	d
	ldax	d
	mov	m,a
	inx	h
	inx	d
	ldax	d
	mov	m,a
	inx	h
	inx	d
	ldax	d
	mov	m,a
	ret
;
	public .lpsh		;push long onto the stack
.lpsh:				;from the primary accumulator
	pop	d		;get return address
	lxi	h,lnprm+3
	lhld	lnprm+2
	push	h
	lhld	lnprm
	push	h
	xchg
	pchl
;
	public	.lpop		;pop long into secondary accum
.lpop:
	pop	d		;get return address
	pop	h		;bytes 0 and 1
	shld	lnsec
	pop	h
	shld	lnsec+2
	xchg
	pchl
;
	public	.lswap		;exchange primary and secondary
.lswap:
	lhld	lnsec
	xchg
	lhld	lnprm
	shld	lnsec
	xchg
	shld	lnprm
	lhld	lnsec+2
	xchg
	lhld	lnprm+2
	shld	lnsec+2
	xchg
	shld	lnprm+2
	ret
;
	public	.lng		;negate primary
.lng:
	lxi	h,lnprm
negate:
	xra	a
	mvi	d,4
ngloop:
	mvi	a,0
	sbb	m
	mov	m,a
	inx	h
	dcr	d
	jnz	ngloop
	ret
;
	public	.ltst		;test if primary is zero
.ltst:
	lxi	h,lnprm
	mvi	d,4
tstlp:
	mov	a,m
	ora	a
	jnz	true
	inx	h
	dcr	d
	jnz	tstlp
	jmp	false
;
	public	.lcmp		;compare primary and secondary
;
			;return 0 if p == s
p.lt.s:			;return < 0 if p < s
	xra	a
	dcr	a
	pop	b
	ret
;
p.gt.s:			;	> 0 if p > s
	xra	a
	inr	a
	pop	b
	ret
;
.lcmp:
	push	b
	lxi	d,lnprm+3
	lxi	h,lnsec+3
	mov	a,m
	xri	80h
	mov	c,a
	ldax	d
	xri	80h
	cmp	c
	mvi	b,4
	jmp	pswchk

	public	.ulcmp
.ulcmp:
	push	b
	lxi	d,lnprm+3
	lxi	h,lnsec+3
	mvi	b,4
cmploop:
	ldax	d
	cmp	m
pswchk:
	jc	p.lt.s
	jnz	p.gt.s
	dcx	h
	dcx	d
	dcr	b
	jnz	cmploop
			;return 0 if p == s
	xra	a
	pop	b
	ret
;
	public .lad		;add secondary to primary
.lad:
			;DE is used as primary address
			;and HL is used as secondary address
	push	b
	lxi	d,lnprm
	lxi	h,lnsec
	xra	a	;clear carry
	mvi	b,4
adloop:
	ldax	d
	adc	m
	stax	d
	inx	h
	inx	d
	dcr	b
	jnz	adloop
	pop	b
	ret
;
	public	.lsb		;subtract secondary from primary
.lsb:
	push	b
	lxi	d,lnprm
	lxi	h,lnsec
	xra	a	;clear carry
	mvi	b,4
sbloop:
	ldax	d
	sbb	m
	stax	d
	inx	h
	inx	d
	dcr	b
	jnz	sbloop
	pop	b
	ret
;
	public	.lan		;and primary with secondary
.lan:
	push	b
	lxi	d,lnprm
	lxi	h,lnsec
	mvi	b,4
ndloop:
	ldax	d
	ana	m
	stax	d
	inx	h
	inx	d
	dcr	b
	jnz	ndloop
	pop	b
	ret
;
	public	.lor		;or primary with secondary
.lor:
	push	b
	lxi	d,lnprm
	lxi	h,lnsec
	mvi	b,4
orloop:
	ldax	d
	ora	m
	stax	d
	inx	h
	inx	d
	dcr	b
	jnz	orloop
	pop	b
	ret
;
	public	.lxr		;exclusive or primary with secondary
.lxr:
	push	b
	lxi	d,lnprm
	lxi	h,lnsec
	mvi	b,4
xrloop:
	ldax	d
	xra	m
	stax	d
	inx	h
	inx	d
	dcr	b
	jnz	xrloop
	pop	b
	ret
;
	public	.lcm		;complement primary
.lcm:
	lxi	h,lnprm
	mvi	d,4
cmloop:
	mov	a,m
	cma
	mov	m,a
	inx	h
	dcr	d
	jnz	cmloop
	ret
;
	public	.lls		;shift primary left by secondary
.lls:
	lda	lnsec
	ani	03fH		;restrict to 63 bits
	rz
	lhld	lnprm
	xchg
	lhld	lnprm+2		;DE has low word, HL has high word
lsloop:
	dad	h		;shift high word
	xchg
	dad	h		;shift low word
	xchg
	jnc	lsnc
	inr	l		;carry into high word
lsnc:
	dcr	a
	jnz	lsloop
	shld	lnprm+2		;put back high word
	xchg
	shld	lnprm
	ret
;
	public	.lur		;unsigned right shift primary by secondary bits
.lur:
	clc			;propogate 0 bit
	jmp	rs_sub
;
	public	.lrs		;right shift primary by secondary bits
.lrs:
	lda	lnprm+3
	ral		;set carry to MSB
rs_sub:
	push	psw
	lda	lnsec
	ani	03fH		;limit to 63 places
	jz	rsdone
	mov	d,a
rslp1:
	lxi	h,lnprm+3
	mvi	e,4
	pop	psw		;get correct carry setting
	push	psw
rslp2:
	mov	a,m
	rar
	mov	m,a
	dcx	h
	dcr	e
	jnz	rslp2
	dcr	d
	jnz	rslp1
rsdone:
	pop	psw
	ret
;
;
setup:
	lxi	h,3
	dad	d
	mov	c,m
	mov	a,c
	ora	a
	rp
	xchg
	jmp	negate		;force positive
;
	public	.ldv
.ldv:		;long divide	(primary = primary/secondary)
	push	b
	lxi	d,lnprm
	call	setup
	push	b
	lxi	d,lnsec
	call	setup
	mov	a,c
	pop	b		;get primary sign
	xra	c		;merge signs
	push	psw		;save for return
	call	dodivide
	pop	psw
	pop	b
	jm	.lng
	ret
;
	public	.lrm
.lrm:		;long remainder	(primary = primary%secondary)
	push	b
	lxi	d,lnprm
	call	setup
	mov	a,c
	ora	a
	push	psw
	lxi	d,lnsec
	call	setup
	call	dodivide
	lxi	d,lntmp
	lxi	h,lnprm
	mvi	b,4
remsave:
	ldax	d
	mov	m,a
	inx	d
	inx	h
	dcr	b
	jnz	remsave
	pop	psw
	pop	b
	jm	.lng
	ret
;
	public	.lud
.lud:		;unsigned long divide	(primary = primary/secondary)
	push	b
	call	dodivide
	pop	b
	ret
;
	public	.lum
.lum:		;long remainder	(primary = primary%secondary)
	push	b
	call	dodivide
	lxi	d,lntmp
	lxi	h,lnprm
	mvi	b,4
uremsave:
	ldax	d
	mov	m,a
	inx	d
	inx	h
	dcr	b
	jnz	uremsave
	pop	b
	ret
;
;
dodivide:
	mvi	b,4
	lxi	h,lntmp		;clear quotient buffer
	xra	a
quinit:
	mov	m,a
	inx	h
	dcr	b
	jnz	quinit

	mvi	a,32		;initialize loop counter
divloop:
	push	psw
	lxi	h,lnprm
	mvi	b,8
	ora	a		;clear carry
shlp:
	mov	a,m
	adc	a		;shift one bit to the left
	mov	m,a
	inx	h
	dcr	b
	jnz	shlp
	sbb	a
	ani	1
	mov	c,a

	mvi	b,4
	lxi	d,lntmp
	lxi	h,lnsec
	ora	a		;clear carry
sublp:
	ldax	d
	sbb	m
	stax	d
	inx	d
	inx	h
	dcr	b
	jnz	sublp
	mov	a,c
	sbi	0
	jnz	zerobit
onebit:
	lxi	h,lnprm
	inr	m
	pop	psw
	dcr	a
	jnz	divloop
	ret
;
zerobit:
	pop	psw
	dcr	a
	jz	restore
	push	psw
	lxi	h,lnprm
	mvi	b,8
	ora	a		;clear carry
zshlp:
	mov	a,m
	adc	a		;shift one bit to the left
	mov	m,a
	inx	h
	dcr	b
	jnz	zshlp
	sbb	a
	mov	c,a

	mvi	b,4
	lxi	d,lntmp
	lxi	h,lnsec
	ora	a		;clear carry
daddlp:
	ldax	d
	adc	m
	stax	d
	inx	d
	inx	h
	dcr	b
	jnz	daddlp
	mov	a,c
	aci	0
	jnz	zerobit
	jmp	onebit
;
restore:			;fix up remainder if still negative
	mvi	b,4
	lxi	d,lntmp
	lxi	h,lnsec
	ora	a		;clear carry
resloop:
	ldax	d
	adc	m
	stax	d
	inx	d
	inx	h
	dcr	b
	jnz	resloop
	ret
;
;
	public	.lml
.lml:		;long multiply	(primary = primary * secondary)
	push	b
;
	lxi	h,lnprm
	mvi	b,4
	lxi	d,lntmp		;copy multiplier into work area
msav:
	mov	a,m
	stax	d
	mvi	m,0
	inx	h
	inx	d
	dcr	b
	jnz	msav
;
	mvi	a,32		;initialize loop counter
muloop:
	push	psw
	lxi	h,lnprm
	mvi	b,8
	ora	a		;clear carry
mshlp:
	mov	a,m
	adc	a		;shift one bit to the left
	mov	m,a
	inx	h
	dcr	b
	jnz	mshlp
	jnc	mnext

	mvi	b,4
	lxi	d,lnprm
	lxi	h,lnsec
	ora	a		;clear carry
maddlp:
	ldax	d
	adc	m
	stax	d
	inx	d
	inx	h
	dcr	b
	jnz	maddlp
;
mnext:
	pop	psw
	dcr	a
	jnz	muloop
	pop	b
	ret
;
;
	public .leq
.leq:
	call	.lcmp
	jz	true
false:
	lxi	h,0
	xra	a
	ret
;
	public .lne
.lne:
	call	.lcmp
	jz	false
true:
	lxi	h,1
	xra	a
	inr	a
	ret
;
	public .llt
.llt:
	call	.lcmp
	jm	true
	jmp	false
;
	public .lle
.lle:
	call	.lcmp
	jm	true
	jz	true
	jmp	false
;
	public .lge
.lge:
	call	.lcmp
	jm	false
	jmp	true
;
	public .lgt
.lgt:
	call	.lcmp
	jm	false
	jz	false
	jmp	true
;
	public .lul
.lul:
	call	.ulcmp
	jm	true
	jmp	false
;
	public .lue
.lue:
	call	.ulcmp
	jm	true
	jz	true
	jmp	false
;
	public .luf
.luf:
	call	.ulcmp
	jm	false
	jmp	true
;
	public .lug
.lug:
	call	.ulcmp
	jm	false
	jz	false
	jmp	true
;
	public	.utox
.utox:
	shld	lnprm
posconv:
	lxi	h,0
	shld	lnprm+2
	ret
;
	public	.itox
.itox:
	shld	lnprm
	mov	a,h
	ora	a
	jp	posconv
	lxi	h,-1
	shld	lnprm+2
	ret
;
	public	.xtoi
.xtoi:
	lhld	lnprm
	ret
	end
divide.asm
;Copyright (C) 1981,1982,1983 by Manx Software Systems
; :ts=8
	extrn	.ng
	public	.dv,.ud
.dv: 			; DE has dividend, HL has divisor
	mov	a,d
	xra	h		;check if signs differ
	push	psw	;and remember
	call	divsub	;use same routine as modulo
	xchg		;and swap results
	pop	psw
	jm	.ng		;negate result if signs of operands differ
	mov	a,l
	ora	h
	RET
;
.ud:
	CALL	.um	;use same routine as modulo
	XCHG		;and swap results
	mov	a,l
	ora	h
	RET
;
	public	.rm,.um
.rm:
	mov	a,d
	push	psw
	call	divsub
	pop	psw
	ora	a
	jm	.ng		;negate result if dividend was signed
	mov	a,h
	ora	l
	ret
;
divsub:
	mov	a,h
	ora	a
	jp	hlpos
	cma
	mov	h,a
	mov	a,l
	cma
	mov	l,a
	inx	h
hlpos:
	mov	a,d
	ora	a
	jp	.um
	cma
	mov	d,a
	mov	a,e
	cma
	mov	e,a
	inx	d
;			fall through into .um
;
.um:	push	b		;save for C
	mov	c,l
	mov	b,h
	lxi	h,0
	call	div16
	pop	b
	mov	a,l		;set flags for C
	ora	h
	ret
;
;	div16:  divides (hl,de) by bc
;		returns remainder in hl, quotient in de
	public	div16
div16:
	mov	a,c
	cma
	mov	c,a
	mov	a,b
	cma
	mov	b,a
	inx	b
	MVI	A,16	;iteration count
divloop:
	DAD	H		;shift hl left
	XCHG
	DAD	H		;shift de left
	XCHG
	JNC	nocy
	INR	L		;carry into high part
nocy:
	dad	b		;subtract divisor
	jc	setbit
	push	psw
	mov	a,l
	sub	c
	mov	l,a
	mov	a,h
	sbb	b
	mov	h,a
	pop	psw
	DCR	A		;count times thru
	JNZ	divloop
	ret
setbit:
	INR	E		;set quotient bit
	DCR	A		;count times thru
	JNZ	divloop
	ret
	end
shifts.asm
;Copyright (C) 1981,1982 by Manx Software Systems
;
	public .ml
.ml: PUSH B
	MOV	B,H
	MOV	C,L	
	LXI H,0		;CLEAR RESULT
	MVI A,16	;ITERATION COUNT
.mlp: DAD H		;SHIFT LEFT
	XCHG		; NOW SHIFT DE LEFT
	DAD H
	XCHG
	JNC .msk
	DAD B
.msk: DCR A		;COUNT TIMES THRU
	JNZ .mlp	;go thru 16 times
	POP	B
	mov a,l
	ora h
	RET
;
	public .rs
.rs:	XCHG
	mov a,e
	ani	31
	mov	e,a
	jz	setcc
	MOV A,H
	ORA H
	JP .arloop
;
.sign:	MOV	A,H
	STC
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	DCR E
	JNZ	.sign
	ora h
	ret
;
	public .ls
.ls:	XCHG
	mov a,e
	ani	31
	mov	e,a
	jz	setcc
lslp:
	DAD H
	DCR E
	JNZ	lslp
setcc:
	mov a,l
	ora h
	ret
;
	public .ur
.ur: XCHG
	mov a,e
	ani	31
	mov	e,a
	jz	setcc
.arloop:	MOV	A,H
	ORA	A
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	DCR E
	JNZ	.arloop
	ora h
	ret
;
	end
bitopr.asm
;Copyright (C) 1981,1982 by Manx Software Systems
	public .an
.an: MOV A,H
	ANA	D
	MOV	H,A
	MOV	A,L
	ANA	E
	MOV	L,A
	ora h
	RET
;
	public .cm
.cm:	MOV	A,H
	CMA
	MOV	H,A
	MOV	A,L
	CMA
	MOV	L,A
	ora h
	RET
;
	public .or
.or: MOV A,H
	ORA	D
	MOV	H,A
	MOV	A,L
	ORA	E
	MOV	L,A
	ora h
	RET
;
	public .xr
.xr: MOV A,H
	XRA	D
	MOV	H,A
	MOV	A,L
	XRA	E
	MOV	L,A
	ora h
	RET
	end
support.asm
;Copyright (C) 1981,1982 by Manx Software Systems
; Copyright (C) 1981  Thomas Fenwick
; :ts=8
	public .nt
.nt:	MOV	A,H
	ORA	L
	jz .true
	jmp .false
;
	public .eq,.ne
.eq: mov a,l
	sub e
	jnz .false
	mov a,h
	sub d
	jz .true
.false: lxi h,0
	xra a
	ret
;
.ne: mov a,l
	sub e
	jnz .true
	mov a,h
	sub d
	jz .false
.true: lxi h,1
	mov a,l
	ora h
	RET
;
	public .le,.ge
.ge:		; ge
	XCHG
.le:	mov a,h
	xra	d
	jm	.lediff	; signs differ
				; signs alike
	mov a,l
	sub e
	mov a,h
	sbb d
	cmc
	mvi a,0
	aci 0
	mov l,a
	mvi h,0
	ret
.lediff: mov a,d
	rlc
	ani 1
	mov l,a
	mvi h,0
	ret
;
	public .lt,.gt
.lt:
	XCHG
.gt:	mov a,h
	xra	d
	jm	.gtdiff	; signs differ
				; signs alike
	mov a,l
	sub e
	mov a,h
	sbb d
	mvi a,0
	aci 0
	mov l,a
	mvi h,0
	ret
.gtdiff: mov a,h
	rlc
	ani 1
	mov l,a
	mvi h,0
	ret
;
	public .ng
.ng:	MOV A,L
	CMA
	MOV L,A
	MOV A,H
	CMA
	MOV H,A
	INX H
	mov a,l
	ora h
	RET
;
	public .sb
.sb: XCHG
	mov a,l
	sub e
	mov l,a
	mov a,h
	sbb d
	mov h,a
	ora l
	ret
;
	public .swt
.swt:	xchg
	pop	h
	PUSH B
	MOV B,D
	MOV C,E
	MOV E,M
	INX H
	MOV D,M
swt.1: DCX D
	MOV A,D
	ORA A
	JM	swt.def
	INX H
	MOV A,C
	CMP M
	JZ	swt.3
	INX H
swt.2: INX H
	INX H
	JMP swt.1
swt.3: INX H
	MOV A,B
	CMP M
	JNZ swt.2
swt.def:	INX H
	MOV A,M
	INX H
	MOV H,M
	MOV L,A
	POP B
	PCHL
;
	public .ue,.uf
.uf:		; uge
	XCHG
.ue: mov a,l	; ule
	sub e
	mov a,h
	sbb d
	mvi a,0
	cmc
	aci 0
	mov l,a
	mvi h,0
	ret
;
	public .ug,.ul
.ul:		; ult
	XCHG
.ug: mov a,l
	sub e
	mov a,h
	sbb d
	mvi a,0
	aci 0
	mov l,a
	mvi h,0
	ret
;
	end
port.asm
;
;	Direct Port I/O Functions for AZTEC C II
;
;	Copyright (c) 1982 William C. Colley III
;
; I grant Manx Software Systems permission to incorporate these functions
; into the AZTEC C library subject only to the condition that my copyright
; notice remain in the source code.  WCC3.
;
; These functions allow AZTEC C II to get to the machine I/O ports.  They
; are more complicated than might be expected as they can't use the Z-80's
; "IN A,(C)" and "OUT (C),A" instructions and still remain 8080-compatible.
; Self-modifying code is also out of the question as that kills ROMability.
; I therefore go through the hassle of setting up temporary subroutines in
; RAM and calling them.
;
; The functions in the package are:
;
;	char in(p)			Returns contents of input port p.
;	char p;
;
;	out(p,c)			Sends character c to output port p.
;	char p, c;
;
		CSEG
		PUBLIC	in_, out_

;*****************************************************************************

in_:		LXI	H, 2		;Get port number from stack.
		DAD	SP
		MOV	H, M

		MVI	L, 0dbh		;Form input instruction of temporary
		SHLD	TMP		;  subroutine and set it up in core.

		LXI	H, TMP + 2	;Add return instruction to temporary
		MVI	M, 0c9h		;  subroutine in core.

		CALL	TMP		;Call temporary subroutine.

		MOV	L, A		;Return result.
		MVI	H, 0
		ORA	H
		RET

;*****************************************************************************

out_:		LXI	H, 4		;Get data and port number from stack.
		DAD	SP
		MOV	A, M
		DCX	H
		DCX	H
		MOV	H, M

		MVI	L, 0d3h		;Form output instruction of temporary
		SHLD	TMP		;  subroutine and set it up in core.

		LXI	H, TMP + 2	;Add return instruction to temporary
		MVI	M, 0c9h		;  subroutine in core.

		JMP	TMP		;Call temporary subroutine and return.

;*****************************************************************************

		DSEG

TMP:		DS	3		;Space for temporary subroutine.

;*****************************************************************************

		END
