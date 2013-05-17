; terminal.asm  2/17/2012 dwg - review for release 1.5.1.0
; terminal.asm 12/26/2011 dwg - 

; Copyright (C) 2011-2012 Douglas Goodall Licensed under GPL Ver 3.
;
; This file is part of NuBiosDWG and is free software: you can
; redistribute it and/or modify it under the terms of the GNU
; General Public License as published by the Free Software Foundation,
; either version 3 of the License, or (at your option) any later version.
; This file is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; You should have received a copy of the GNU General Public License
; along with it.  If not, see <http://www.gnu.org/licenses/>.


; The termbind lib is the home of the macros that are the
; ; front end for access to library routines that implement 
; ; terminal specific functionality.
; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Table 4-11 VT52 Escape Sequences
;
; ESC A
; Cursor up.
;
; ESC B
; Cursor down.
;
; ESC C
; Cursor right.
;
; ESC D
; Cursor left.
;
; ESC F
; Enter graphics mode.
;
; ESC G
; Exit graphics mode.
;
; ESC H
; Cursor to home.
;
; ESC I
; Reverse line feed.
;
; ESC J
; Erase to end of screen.
;
; ESC K
; Erase to end of line.
;
; ESC Y Line Column
; Direct cursor address.
;
; ESC Z
; Identify.
;
; ESC =
																																						; Enter alternate keypad mode.
;
; ESC &gt;
; Exit alternate keypad mode.
;
; ESC &lt;
; Enter ANSI mode.
;
; ESC ^
; Enter auto print mode.
;
; ESC _
; Exit auto print mode.
;
; ESC W
; Enter printer controller mode.
;
; ESC X
; Exit printer controller mode.
;
; ESC ]
; Print screen.
;
; ESC V
; Print cursor line.


; ANSI
;   CSI = <esc>[
;   CSI n A		CUU - CUrsor Up, n cells
;   CSI n B		CUD - CUrsor Down, n cells
;   CSI n C		CUF - CUrsor Forward
;   CSI n D		CUB - CUrsor Back
;   CSI n E		CNL - Cursor Next Line
;   CSI n F		CPL - Cursor Previous Line
;   CSI n G		CHA - Cursor Horizontal Absolute
;   CSI n ; m H		CUP - Cursor Position,n = row, m = col (1rel)
;   CSI 0 J		ED - clear from cursor to EOS
;   CSI 1 J		ED - clear from cursor to BOS
;   CSI 2 J		ED - clear screen
;   CSI n K		EL - 0-clr-2eol,1-clr-to-bol,2-clr-line
;   CSI n S		SU - Scroll Up
;   CSI n T		SD - Scroll Down
;   CSI s		SCP - Save Cursor Position
;   CSI u		RCP - Restore Cursor Position
;   CSI n [;k] m	SGR - Select Graphic Rendition
;   CSI 0 m		SGR - Reset / Normal
;   CSI 1 m		SGR - Bright or Bold
;   CSI 3 m		SGR - italic on
;   CSI 4 m 		SGR - underline (single) on
;   CSI 5 m		SGR - blink slow
;   CSI 6 m		SGR - blink rapid
;   CSI 7 m		SGR - negative
;   CSI 8 m		SGR - Conceal
;   CSI 9 m		SGR - Crossed Out
;   CSI 10 m		SGR - Primary (default) Font
;   CSI 21 m		SGR - Bright Bold Off
;   CSI 22 m		SGR - Normal COlor or Intensity
;   CSI 23 m		SGR - Not Italic
;   CSI 24 m		SGR - Not underline
;   CSI 25 m		SGR - Not Blink
;   CSI 27 m		SGR - Image Positive
;   CSI 28 m		SGR - Reveal
;   CSI 29 m		SGR - Not Crossed Out
;   CSI 30 m 		SGR - Black	CSI 30 ; 1 m	(light black)
;   CSI 31 m		SGR - Red	CSI 31 ; 1 m	(light red)
;   CSI 32 m            SGR - Green     CSI 32 ; 1 m 	(light green)
;   CSI 33 m 		SGR - Yellow	CSI 33 ; 1 m	(light yellow)
;   CSI 34 m		SGR - Blue	CSI 34 ; 1 m 	(light blue)
;   CSI 35 m		SGR - Magenta	CSI 35 ; 1 m	(light magenta)
;   CSI 36 m		SGR - Cyan	CSI 36 ; 1 m	(light cyan)
;   CSI 37 m		SGR - White	CSI 37 ; 1 m 	(light white)
;   CSI 39 m		SGR - Set Default Text Color
;   CSI 40-47 m		SGR - Set Background Color
;   CSI 6 n		DSR - Device Status Report 
; VT100
; VT220
; WYSE
;   WY50 
;   ESC = r c		Set Cursor Position (see row codes) 
;   ESC *		Clear screen to nulls
;   ESC +		Clear screen to spaces

	maclib	portab
	maclib	std
	maclib	cpmbios
	maclib	cpmbdos
	maclib	bioshdr
	maclib	hbios
	maclib	cnfgdata

; enter with the number in de

	public	xprdec
xprdec:	lxi	h,dr
	dad	d
	dad	d
	dad	d
	dad	d
	xchg
	mvi	c,9
	call	5
	ret


	public	xcrtinit
xcrtinit:
	call	xgetsc
	lxi	h,termtype
	mov	a,m
	sta	ttyp
	ret



	public	xcrtclr
xcrtclr:
  lda ttyp
  cpi TERM$ANSI
  jnz xnotansi1
    mvi c,2 ! mvi e,27  ! call 5
    mvi c,2 ! mvi e,'[' ! call 5
    mvi c,2 ! mvi e,'2' ! call 5
    mvi c,2 ! mvi e,'J' ! call 5
    jmp xdone1
xnotansi1:
  cpi TERM$WYSE
  jnz xnotwyse1
    conout 27
    conout '+'
    jmp xdone1
xnotwyse1:
  cpi TERM$VT52
  jnz xdone
    conout 27
    conout 'H'	; Cursor to Hoe
    conout 27
    conout 'J'	; Erase to End of Screen
xdone1:
   ret


; h=line l=col
	public	xcrtlc
xcrtlc:
  lda ttyp
  cpi TERM$ANSI
  jz xisansi
  cpi TERM$WYSE
  jz xiswyse
  cpi TERM$VT52
  jz xisvt52
    ret
xiswyse:
  mov a,h
  sta templine
  mov a,l
  sta tempcol
  conout 27
  conout '='
  lda templine
  mov e,a
  mvi d,0
  lxi h,wy50row
  dad d
  dcx h
  mov e,m
  mvi c,2
  call BDOS
  ;
  lda tempcol
  mov e,a
  mvi d,0
  lxi h,wy50col
  dad d
  dcx h
  mov e,m
  mvi c,2
  call BDOS
  jmp xdone
  ;------->
xisansi:
  push h
  push h
    mvi c,2 ! mvi e,27  ! call 5
    mvi c,2 ! mvi e,'[' ! call 5
  pop h
    mov e,h
    mvi d,0
    call xprdec
    mvi c,2 ! mvi e,';' ! call 5
  pop h
    mov e,l
    mvi d,0
    call xprdec
    mvi c,2 ! mvi e,66h ! call 5
xdone:
    ret
xisvt52:
  push h
  push h
    conout 27
    conout 'Y'
  pop h
    mov a,h
    adi 32
    mov e,a
    mvi c,CWRITE
    call BDOS
  pop h
    mov a,l
    adi 32
    mov e,a
    mvi c,CWRITE
    call BDOS
  ret

	public	dr
dr	db	'0$  ','1$  ','2$  ','3$  ','4$  '
	db	'5$  ','6$  ','7$  ','8$  ','9$  '
	db	'10$ ','11$ ','12$ ','13$ ','14$ '
	db	'15$ ','16$ ','17$ ','18$ ','19$ '
	db	'20$ ','21$ ','22$ ','23$ ','24$ '
	db	'25$ ','26$ ','27$ ','28$ ','29$ '
	db	'30$ ','31$ ','32$ ','33$ ','34$ '
	db	'35$ ','36$ ','37$ ','38$ ','39$ '
	db	'40$ ','41$ ','42$ ','43$ ','44$ '
	db	'45$ ','46$ ','47$ ','48$ ','49$ '
	db	'50$ ','51$ ','52$ ','53$ ','54$ '
	db	'55$ ','56$ ','57$ ','58$ ','59$ '
	db	'60$ ','61$ ','62$ ','63$ ','64$ '
	db	'65$ ','66$ ','67$ ','68$ ','69$ '
	db	'70$ ','71$ ','72$ ','73$ ','74$ '
	db	'75$ ','76$ ','77$ ','78$ ','79$ '
	db	'80$ ','81$ ','82$ ','83$ ','84$ '
	db	'85$ ','86$ ','87$ ','88$ ','89$ '
	db	'90$ ','91$ ','92$ ','93$ ','94$ '
	db	'95$ ','96$ ','97$ ','99$ ','100$'

SINGLEQUOTE equ 0
RIGHTQUOTE  equ 0
LEFTQUOTE   equ 0

wy50row	db	' !"#$%&'
	db	39
	db	'()*+,-./01234567'

wy50col db	' !"#$%&'
	db	39
	db	'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_'
	db	96
	db	'abcdefghijklmno'

templine db 0
tempcol	 db 0
ttyp	db	0

	end	
 