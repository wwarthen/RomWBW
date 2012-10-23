	nlist
; Copyright (C) 1985 by Manx Software Systems, Inc.
; :ts=8
	ifndef	MODEL
MODEL	equ	0
	endif
	if	MODEL and 1
	largecode
FARPROC	equ 1
FPTRSIZE equ	4
	else
FPTRSIZE equ	2
	endif
	if	MODEL and 2
LONGPTR equ 1
	endif

;this macro to be used on returning
;restores bp and registers 
pret	macro
if havbp
	pop bp
endif
	ret
	endm

internal macro	pname
	public	pname
pname	proc
	endm

intrdef	macro	pname
	public	pname
ifdef FARPROC
	pname	label	far
else
	pname	label	near
endif
	endm

procdef	macro	pname, args
	public pname&_
ifdef	FARPROC
	_arg	= 6
	pname&_	proc	far
else
	_arg	= 4
	pname&_	proc	near
endif
ifnb <args>
	push bp
	mov bp,sp
	havbp = 1
	decll <args>
else
	havbp = 0
endif
	endm

entrdef	macro	pname, args
	public pname&_
ifdef	FARPROC
	_arg	= 6
	pname&_:
else
	_arg	= 4
	pname&_:
endif
ifnb <args>
if	havbp
	push	bp
	mov	bp,sp
else
	error must declare main proc with args, if entry has args
endif
	decll <args>
endif
	endm

;this macro equates 'aname' to arg on stack
decl	macro 	aname, type
;;'byte' or anything else
havtyp	= 0
ifidn	<type>,<byte>
	aname	equ	byte ptr _arg[bp]
	_arg = _arg + 2
	havtyp = 1
endif
ifidn	<type>,<dword>
	aname	equ dword ptr _arg[bp]
	_arg = _arg + 4
	havtyp = 1
endif
ifidn <type>,<cdouble>
	aname	equ qword ptr _arg[bp]
	_arg = _arg + 8
	havtyp = 1
endif
ifidn <type>, <ptr>
	ifdef LONGPTR
		aname	equ dword ptr _arg[bp]
		_arg = _arg + 4
	else
		aname equ	word ptr _arg[bp]
		_arg = _arg + 2
	endif
	havtyp = 1
endif
ifidn <type>, <fptr>
	ifdef FARPROC
		aname	equ dword ptr _arg[bp]
		_arg = _arg + 4
	else
		aname equ	word ptr _arg[bp]
		_arg = _arg + 2
	endif
	havtyp = 1
endif
ifidn <type>, <word>
	aname equ	word ptr _arg[bp]
	_arg = _arg + 2
	havtyp = 1
endif
ife	havtyp
	error -- type is unknown.
endif
	endm

;this macro loads an arg pointer into DEST, with optional SEGment
ldptr	macro	dest, argname, seg
ifdef	LONGPTR
	ifnb <seg>		;;get segment if specified
		ifidn <seg>,<es>
			les	dest,argname
		else
			ifidn <seg>,<ds>
				lds dest,argname
			else
				mov dest, word ptr argname
				mov seg, word ptr argname[2]
			endif
		endif
	else
		ifidn <dest>,<si>		;;si gets seg in ds
			lds	si, argname
		else
			ifidn <dest>,<di>	;;or, es:di
				les	di, argname
			else
				garbage error: no seg for long pointer
			endif
		endif
	endif
else
	mov dest, word ptr argname	;;get the pointer
ENDIF
	ENDM

decll	macro	list
	IRP	i,<list>
	decl i
	ENDM
	ENDM

pend	macro	pname
pname&_	endp
	endm

retptrm	macro	src,seg
mov	ax, word ptr src
ifdef	LONGPTR
	mov	dx, word ptr src+2
endif
	endm

retptrr	macro	src,seg
mov	ax,src
ifdef LONGPTR
	ifnb <seg>
		mov	dx, seg
	endif
endif
	endm

retnull	macro
ifdef LONGPTR
	sub	dx,dx
endif
	sub	ax,ax
 	endm

pushds	macro
	ifdef LONGPTR
	push	ds
	endif
	endm

popds	macro
	ifdef LONGPTR
	pop	ds
	endif
	endm

finish	macro
codeseg	ends
	endm

	list
codeseg	segment	byte public 'code'
	assume	cs:codeseg
