; banner.asm 9/5/2012 dwg - new version semantics - #.#.# (#)

	maclib	portab
	maclib	globals
	maclib	cpmbios
	maclib	cpmbdos
	maclib	bioshdr
	maclib	printers
	maclib	cpmappl
	maclib	applvers

	cseg


; entered with argv in hl
	public	x$banner
x$banner:
  	shld	argv
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xprog ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xvers ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xprod ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xorig ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xser  ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xnam  ! xchg


 	printf	'----------------------------------------'
 	print	crlf
	lhld xprog ! xchg ! mvi c,9 ! call BDOS
 	printf	' '
 	IF	A$MONTH LT 10
 	conout	' '
 	ENDIF
 	IF	A$DAY LT 10
 	conout	' '
 	ENDIF
 	lxi	h,A$MONTH
 	call	pr$d$word
 	conout	'/'
 	lxi	h,A$DAY
 	call	pr$d$word
 	conout	'/'
 	lxi	h,A$YEAR
 	call	pr$d$word
 	printf	'  '
 	printf	'Version '
 	lxi	h,A$RMJ
 	call	pr$d$word
 	conout	'.'
 	lxi	h,A$RMN
 	call	pr$d$word
 	conout	'.'
 	lxi	h,A$RUP
 	call	pr$d$word
 	printf	' ('
 	lxi	h,A$RTP
 	call	pr$d$word
	conout	')'
 	print	crlf
 	printf	'S/N '

	lhld xprod ! xchg ! mvi c,9 ! call BDOS

 	conout	'-'

	lhld xorig ! xchg ! mvi c,9 ! call BDOS

 	conout	'-'

; 	print	xser
	lhld xser ! xchg ! mvi c,9 ! call BDOS

 	printf	' '
;	printf	'All Rights Reserved'
 	printf	'Licensed under GPL3'
 	print	crlf
 	printf	'Copyright (C) 2011-12'

	lhld xnam ! xchg ! mvi c,9 ! call BDOS

 	print	crlf
 	printf	'----------------------------------------'
 	print	crlf

	ret


; entered with argv in hl
	public	x$sbanner
x$sbanner:
  	shld	argv
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xprog ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xvers ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xprod ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xorig ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xser  ! xchg
  	mov e,m ! inx h ! mov d,m ! inx h ! xchg ! shld xnam  ! xchg


; 	printf	'----------------------------------------'
; 	print	crlf
	lhld xprog ! xchg ! mvi c,9 ! call BDOS
 	printf	' '
 	IF	A$MONTH LT 10
 	conout	' '
 	ENDIF
 	IF	A$DAY LT 10
 	conout	' '
 	ENDIF
 	lxi	h,A$MONTH
 	call	pr$d$word
 	conout	'/'
 	lxi	h,A$DAY
 	call	pr$d$word
 	conout	'/'
	lxi	h,A$YEAR
 	call	pr$d$word
 	printf	'  '
 	printf	'Vers. '
 	lxi	h,A$RMJ
 	call	pr$d$word
 	conout	'.'
 	lxi	h,A$RMN
 	call	pr$d$word
 	conout	'.'
 	lxi	h,A$RUP
 	call	pr$d$word
 	printf	' ( '
 	lxi	h,A$RTP
 	call	pr$d$word
	printf	') '
	printf	'COPR Douglas Goodall Licensed w/GPLv3'


 	print	crlf

	ret


;----------------------------------------------------------------

argv	ds	2
;----------------
xprog	ds	2
xvers	ds	2
xprod	ds	2
xorig	ds	2
xser	ds	2
xnam	ds	2

crlf	db	CR,LF,'$'

	end

; eof - banner.asm
