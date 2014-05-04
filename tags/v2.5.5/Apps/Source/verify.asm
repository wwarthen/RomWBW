; verify.asm 7/14/2012 dwg - 

	org	100h
start:
	lxi	sp,histack

	mvi	c,9
	lxi	d,sine
	call	BDOS

	jmp	histart

sine	db	'VERIFY.COM 7/14/2012 dwg - verify ROM w/rom.img$'

	org	08000h
histart:

;	Bank #	ROM/FILE-ADDR	MEM-ADDR	

;	0	00000-03FFF	0000-3FFF
;	0	04000-07FFF	4000-7FFF
;	1	08000-0BFFF	0000-3FFF
;	1	0C000-0FFFF	4000-7FFF
;	2	10000-13FFF	0000-3FFF
;	2	14000-17FFF	4000-7FFF
;	3	18000-1BFFF	0000-3FFF
;	3	1C000-1FFFF	4000-7FFF
;	4	20000-23FFF	0000-3FFF
;	4	24000-27FFF	4000-7FFF
;	5	28000-2BFFF	0000-3FFF	
;	5	2C000-2FFFF	4000-7FFF
;	6	30000-33FFF	0000-3FFF
;	6	30000-37FFF	4000-7FFF
;	7	38000-3BFFF	0000-3FFF
;	7	3C000-3FFFF	4000-7FFF


	mvi	c,0
	call	BDOS

rom$fcb	db	0,'ROM     IMG',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

	ds	256
histack:

	end	start
