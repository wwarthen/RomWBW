;
;  Size-optimized LZSA1 decompressor by spke & uniabis (67 bytes)
;
;  ver.00 by spke for LZSA 0.5.4 (23/04/2019, 69 bytes);
;  ver.01 by spke for LZSA 1.0.5 (24/07/2019, added support for backward decompression);
;  ver.02 by uniabis (30/07/2019, 68(-1) bytes, +3.2% speed);
;  ver.03 by spke for LZSA 1.0.7 (31/07/2019, small re-organization of macros);
;  ver.04 by spke (06/08/2019, 67(-1) bytes, -1.2% speed);
;  ver.05 by spke for LZSA 1.1.0 (25/09/2019, added full revision history)
;
;  The data must be compressed using the command line compressor by Emmanuel Marty
;  The compression is done as follows:
;
;  lzsa.exe -f1 -r <sourcefile> <outfile>
;
;  where option -r asks for the generation of raw (frame-less) data.
;
;  The decompression is done in the standard way:
;
;  ld hl,FirstByteOfCompressedData
;  ld de,FirstByteOfMemoryForDecompressedData
;  call DecompressLZSA1
;
;  Backward compression is also supported; you can compress files backward using:
;
;  lzsa.exe -f1 -r -b <sourcefile> <outfile>
;
;  and decompress the resulting files using:
;
;  ld hl,LastByteOfCompressedData
;  ld de,LastByteOfMemoryForDecompressedData
;  call DecompressLZSA1
;
;  (do not forget to uncomment the BACKWARD_DECOMPRESS option in the decompressor).
;
;  Of course, LZSA compression algorithms are (c) 2019 Emmanuel Marty,
;  see https://github.com/emmanuel-marty/lzsa for more information
;
;  Drop me an email if you have any comments/ideas/suggestions: zxintrospec@gmail.com
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.

;	DEFINE	BACKWARD_DECOMPRESS

	IFNDEF	BACKWARD_DECOMPRESS

		MACRO NEXT_HL
		inc hl
		ENDM

		MACRO ADD_OFFSET
		ex de,hl : add hl,de
		ENDM

		MACRO BLOCKCOPY
		ldir
		ENDM

	ELSE

		MACRO NEXT_HL
		dec hl
		ENDM

		MACRO ADD_OFFSET
		push hl : or a : sbc hl,de : pop de				; 11+4+15+10 = 40t / 5 bytes
		ENDM

		MACRO BLOCKCOPY
		lddr
		ENDM

	ENDIF

@DecompressLZSA1:
		ld b,0

		; first a byte token "O|LLL|MMMM" is read from the stream,
		; where LLL is the number of literals and MMMM is
		; a length of the match that follows after the literals
ReadToken:	ld a,(hl) : NEXT_HL : push af
		and #70 : jr z,NoLiterals

		rrca : rrca : rrca : rrca					; LLL<7 means 0..6 literals...
		cp #07 : call z,ReadLongBA					; LLL=7 means 7+ literals...

		ld c,a : BLOCKCOPY

		; next we read the low byte of the -offset
NoLiterals:	pop af : push de : ld e,(hl) : NEXT_HL : ld d,#FF
		; the top bit of token is set if
		; the offset contains the high byte as well
		or a : jp p,ShortOffset

LongOffset:	ld d,(hl) : NEXT_HL

		; last but not least, the match length is read
ShortOffset:	and #0F : add 3							; MMMM<15 means match lengths 0+3..14+3
		cp 15+3 : call z,ReadLongBA					; MMMM=15 means lengths 14+3+
		ld c,a

		ex (sp),hl							; BC = len, DE = -offset, HL = dest, SP -> [src]
		ADD_OFFSET							; BC = len, DE = dest, HL = dest+(-offset), SP -> [src]
		BLOCKCOPY							; BC = 0, DE = dest
		pop hl : jr ReadToken						; HL = src

		; a standard routine to read extended codes
		; into registers B (higher byte) and A (lower byte).
ReadLongBA:	add (hl) : NEXT_HL : ret nc

		; the codes are designed to overflow;
		; the overflow value 1 means read 1 extra byte
		; and overflow value 0 means read 2 extra bytes
.code1:		ld b,a : ld a,(hl) : NEXT_HL : ret nz
.code0:		ld c,a : ld b,(hl) : NEXT_HL

		; the two-byte match length equal to zero
		; designates the end-of-data marker
		or b : ld a,c : ret nz
		pop de : pop de : ret

