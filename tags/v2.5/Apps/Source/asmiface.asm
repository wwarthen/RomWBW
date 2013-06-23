; asmiface.asm 6/4/2012 dwg - 

	extrn	.begin,.chl,.swt
	extrn	csave,cret,.move

	global	xrega_,1
	global	xregbc_,2
	global	xregde_,2
	global	xreghl_,2

	PUBLIC asmif_
asmif_:	lxi d,.2
	call csave

	LXI H,8-.2	; pick up 1st parm "function address"
	DAD SP
	MOV E,M
	INX H
	MOV D,M		
	xchg
	shld	callad+1

	LXI H,10-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M		; DE = parm
	xchg
	shld	xregbc_

	LXI H,12-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	xchg
	shld	xregde_

	LXI H,14-.2
	DAD SP
	MOV E,M
	INX H
	MOV D,M
	xchg
	shld	xreghl_

	lhld	xregbc_
	mov	b,h
	mov	c,l		; setup B&C
	lhld	xregde_
	xchg			; setup D&E
	lhld	xreghl_		; setup H&L

callad:	call	0e639h	; setlu

	sta	xrega_
	shld	xreghl_
	xchg	
	shld	xregde_
	mov	l,c
	mov	h,b
	shld	xregbc_
	RET		; HL has return value

.2 EQU 0
	END
