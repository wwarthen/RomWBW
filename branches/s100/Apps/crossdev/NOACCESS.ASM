; noaccess.asm 7/19/2012 dwg - for 2.0.0.0 B22
; noaccess.asm 2/11/2012 dwg - make ident compliant
; noaccess.asm 2/11/2012 dwg - begin 1.6 enhancements
; noaccess.com 2/05/2012 dwg - adjust for new macros
;   access.asm 1/30/2012 dwg - use new do$start and do$end macros
;   access.asm 1/28/2012 dwg - assure file exists from within submit file

	maclib	portab
	maclib	globals
	maclib	cpmbdos
	maclib	printers
	maclib	banner
	maclib	applvers
	maclib	z80
	maclib	memory
	maclib	version
	maclib	cpmappl
	maclib	banner
	maclib	identity

	do$start


	jmp	around$bandata
argv	dw	prog,dat,prod,orig,ser,myname,0
prog	db	'NOACCESS.COM$'
	date
	serial
	product
	originator
	oriname
uuid	db	'260115A3-3463-48DE-B807-7D5F8FEE177B$'
around$bandata:

	sbanner	argv

	lda 80h
	cpi 0
	jnz	no$usage
	printf	'usage - noaccess <filename>'
	jmp do$exit
no$usage:

	memcpy	work$fcb,PRIFCB,32

	printf	'Checking: '
	memcpy PRIFCB,work$fcb,16

	mvi	a,'$'
	sta	PRIFCB+9
	print PRIFCB+1
	conout	'.'
	memcpy	PRIFCB,work$fcb,16
	mvi	a,'$'
	sta	PRIFCB+12
	print	PRIFCB+9
	print	crlf

	memcpy	PRIFCB,work$fcb,32
	mvi	c,FOPEN
	lxi	d,PRIFCB
	call	BDOS
	cpi 	255
	jz	done

	mvi	c,FDELETE
	lxi	d,del$fcb
	call	BDOS
	printf	'Submit file terminating due to presence of file$'
	jmp 	do$exit

done:
	printf	'File found, Submit is terminating'
do$exit:
	do$end

crlf	db	CR,LF,'$'

	newfcb	del$fcb,1,'$$$     SUB'

work$fcb ds	36

	end
