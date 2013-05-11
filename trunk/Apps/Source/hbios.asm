; hbios.asm 7/19/2012 dwg - 

CFGVERS	equ	0

	public	xgetsc
xgetsc:
	enter
	mvi	b,0F0h
	mvi	c,CFGVERS
	lxi	d,8000h
  	db 	0cfh		;  rst 8
	lxi	h,8000h
	leave
	ret
	

	END
