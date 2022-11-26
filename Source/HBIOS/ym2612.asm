;======================================================================
;	YM2612 sound driver
;
;	WRITTEN BY: PHIL SUMMERS
;======================================================================
;
; PRESENTLY THIS IS JUST A STUB TO MUTE OUTPUT
;
;======================================================================
; 
;======================================================================
;
THIS_DRV	.SET	DRV_ID_YM2612
;
YMSEL		.EQU	VGMBASE+00H		; Primary YM2162 11000000 a1=0 a0=0
YMDAT		.EQU	VGMBASE+01H		; Primary YM2162 11000001 a1=0 a0=1
YM2SEL		.EQU	VGMBASE+02H		; Secondary YM2162 11000010 a1=1 a0=0
YM2DAT		.EQU	VGMBASE+03H		; Secondary YM2162 11000011 a1=1 a0=1
;
;------------------------------------------------------------------------------
; YM2162 Mute
;------------------------------------------------------------------------------
;
YM2612_INIT:
		ld	hl,s1			; Start of register list to write

		ld	b,s2-s1
pt1:		call	set1			; [1]
		djnz	pt1

pt2:		ld	b,s3-s2
		call	set2			; [2]
		djnz	pt2

pt3:		ld	b,s4-s3
		call	set1			; [1]
		djnz	pt3

pt4:		ld	b,s5-s4
		call	set2			; [2]
		djnz	pt4

		ret

set1:		ld	a,(hl)			; YM2162 Register write
		inc	hl			; Register bank [1]
		out	(YMSEL),a
		ld	a,(hl)
		inc	hl
		out	(YMDAT),a
set1a:		in	a,(YMSEL)
		rlca
		jp	c,set1a
		ret

set2:		ld	a,(hl)			; YM2162 Register write
		inc	hl			; Register Bank [2]
		out	(YM2SEL),a
		ld	a,(hl)
		inc	hl
		out	(YM2DAT),a
set2a:		in	a,(YM2SEL)
		rlca
		jp	c,set2a
		ret

s1:		.db	$22,$00			; [1] lfo off

		.db	$27,$00			; [1] Disable independant Channel 3
		.db	$28,$00			; [1] note off ch 1
		.db	$28,$01			; [1] note off ch 2
		.db	$28,$02			; [1] note off ch 3
		.db	$28,$04			; [1] note off ch 4
		.db	$28,$05			; [1] note off ch 5
		.db	$28,$06			; [1] note off ch 6
		.db	$2b,$00			; [1] dac off

		.db	$b4,$00			; [1] sound off ch 1-3
		.db	$b5,$00	
		.db	$b6,$00	

s2:		.db	$b4,$00			; [2] sound off ch 4-6
		.db	$b5,$00			; [2] 
		.db	$b6,$00			; [2] 

s3:		.db	$40,$7f			; [1] ch 1-3 total level minimum
		.db	$41,$7f			; [1] 
		.db	$42,$7f			; [1] 
		.db	$44,$7f			; [1] 
		.db	$45,$7f			; [1] 
		.db	$46,$7f			; [1] 
		.db	$48,$7f			; [1] 
		.db	$49,$7f			; [1] 
		.db	$4a,$7f			; [1] 
		.db	$4c,$7f			; [1] 
		.db	$4d,$7f			; [1] 
		.db	$4e,$7f			; [1] 
s4:
		.db	$40,$7f			; [2] ch 4-6 total level minimum
		.db	$41,$7f			; [2]
		.db	$42,$7f			; [2]
		.db	$44,$7f			; [2]
		.db	$45,$7f			; [2]
		.db	$46,$7f			; [2]
		.db	$48,$7f			; [2]
		.db	$49,$7f			; [2]
		.db	$4a,$7f			; [2]
		.db	$4c,$7f			; [2]
		.db	$4d,$7f			; [2]
		.db	$4e,$7f			; [2]
s5:
#IF (0)
		.db	$2a,$00			; [1]	; dac value
 
		.db	$24,$00			; [1]	; timer A frequency
		.db	$25,$00			; [1]	; timer A frequency
		.db	$26,$00			; [1]	; time B frequency

		.db	$30,$00			; [1]	; ch 1-3 multiply & detune
		.db	$31,$00	                ; [1]
		.db	$32,$00	                ; [1]
		.db	$34,$00	                ; [1]
		.db	$35,$00	                ; [1]
		.db	$36,$00	                ; [1]
		.db	$38,$00	                ; [1]
		.db	$39,$00	                ; [1]
		.db	$3a,$00	                ; [1]
		.db	$3c,$00	                ; [1]
		.db	$3d,$00	                ; [1]
		.db	$3e,$00	                ; [1]
s6:
		.db	$30,$00			; [2] ch 4-6 multiply & detune
		.db	$31,$00			; [2]
		.db	$32,$00			; [2]
		.db	$34,$00			; [2]
		.db	$35,$00			; [2]
		.db	$36,$00			; [2]
		.db	$38,$00			; [2]
		.db	$39,$00			; [2]
		.db	$3a,$00			; [2]
		.db	$3c,$00			; [2]
		.db	$3d,$00			; [2]
		.db	$3e,$00			; [2]
s7:                             			
		.db	$50,$00	                ; [1] ch 1-3 attack rate and scaling
		.db	$51,$00	                ; [1]
		.db	$52,$00	                ; [1]
		.db	$54,$00	                ; [1]
		.db	$55,$00	                ; [1]
		.db	$56,$00	                ; [1]
		.db	$58,$00	                ; [1]
		.db	$59,$00	                ; [1]
		.db	$5a,$00	                ; [1]
		.db	$5c,$00	                ; [1]
		.db	$5d,$00	                ; [1]
		.db	$5e,$00	                ; [1]
s8:
		.db	$50,$00			; [2] ch 4-6 attack rate and scaling
		.db	$51,$00			; [2]
		.db	$52,$00			; [2]
		.db	$54,$00			; [2]
		.db	$55,$00			; [2]
		.db	$56,$00			; [2]
		.db	$58,$00			; [2]
		.db	$59,$00			; [2]
		.db	$5a,$00			; [2]
		.db	$5c,$00			; [2]
		.db	$5d,$00			; [2]
		.db	$5e,$00			; [2]
s9:
		.db	$60,$00	                ; [1] ch 1-3 decay rate and am enable
		.db	$61,$00	                ; [1]
		.db	$62,$00	                ; [1]
		.db	$64,$00	                ; [1]
		.db	$65,$00	                ; [1]
		.db	$66,$00	                ; [1]
		.db	$68,$00	                ; [1]
		.db	$69,$00	                ; [1]
		.db	$6a,$00	                ; [1]
		.db	$6c,$00	                ; [1]
		.db	$6d,$00	                ; [1]
		.db	$6e,$00	                ; [1]
s10:
		.db	$60,$00			; [2] ch 4-6 decay rate and am enable
		.db	$61,$00			; [2]
		.db	$62,$00			; [2]
		.db	$64,$00			; [2]
		.db	$65,$00			; [2]
		.db	$66,$00			; [2]
		.db	$68,$00			; [2]
		.db	$69,$00			; [2]
		.db	$6a,$00			; [2]
		.db	$6c,$00			; [2]
		.db	$6d,$00			; [2]
		.db	$6e,$00			; [2]
s11:
		.db	$70,$00	                ; [1] ch 1-3 sustain rate
		.db	$71,$00	                ; [1]
		.db	$72,$00	                ; [1]
		.db	$74,$00	                ; [1]
		.db	$75,$00	                ; [1]
		.db	$76,$00	                ; [1]
		.db	$78,$00	                ; [1]
		.db	$79,$00	                ; [1]
		.db	$7a,$00	                ; [1]
		.db	$7c,$00	                ; [1]
		.db	$7d,$00	                ; [1]
		.db	$7e,$00	                ; [1]
s12:
		.db	$70,$00			; [2] ch 4-6 sustain rate
		.db	$71,$00			; [2]
		.db	$72,$00			; [2]
		.db	$74,$00			; [2]
		.db	$75,$00			; [2]
		.db	$76,$00			; [2]
		.db	$78,$00			; [2]
		.db	$79,$00			; [2]
		.db	$7a,$00			; [2]
		.db	$7c,$00			; [2]
		.db	$7d,$00			; [2]
		.db	$7e,$00			; [2]
s13:
		.db	$80,$00	                ; [1] ch 1-3 release rate and sustain level
		.db	$81,$00	                ; [1]
		.db	$82,$00	                ; [1]
		.db	$84,$00	                ; [1]
		.db	$85,$00	                ; [1]
		.db	$86,$00	                ; [1]
		.db	$88,$00	                ; [1]
		.db	$89,$00	                ; [1]
		.db	$8a,$00	                ; [1]
		.db	$8c,$00	                ; [1]
		.db	$8d,$00	                ; [1]
		.db	$8e,$00	                ; [1]
s14:
		.db	$80,$00			; [2] ch 4-6 release rate and sustain level
		.db	$81,$00			; [2]
		.db	$82,$00			; [2]
		.db	$84,$00			; [2]
		.db	$85,$00			; [2]
		.db	$86,$00			; [2]
		.db	$88,$00			; [2]
		.db	$89,$00			; [2]
		.db	$8a,$00			; [2]
		.db	$8c,$00			; [2]
		.db	$8d,$00			; [2]
		.db	$8e,$00			; [2]
s15:
		.db	$90,$00	                ; [1] ch 1-3 ssg-eg
		.db	$91,$00	                ; [1]
		.db	$92,$00	                ; [1]
		.db	$94,$00	                ; [1]
		.db	$95,$00	                ; [1]
		.db	$96,$00	                ; [1]
		.db	$98,$00	                ; [1]
		.db	$99,$00	                ; [1]
		.db	$9a,$00	                ; [1]
		.db	$9c,$00	                ; [1]
		.db	$9d,$00	                ; [1]
		.db	$9e,$00	                ; [1]
s16:
		.db	$90,$00			; [2] ch 4-6 ssg-eg
		.db	$91,$00			; [2]
		.db	$92,$00			; [2]
		.db	$94,$00			; [2]
		.db	$95,$00			; [2]
		.db	$96,$00			; [2]
		.db	$98,$00			; [2]
		.db	$99,$00			; [2]
		.db	$9a,$00			; [2]
		.db	$9c,$00			; [2]
		.db	$9d,$00			; [2]
		.db	$9e,$00			; [2]
s17:
		.db	$a0,$00	                ; [1] ch 1-3 frequency
		.db	$a1,$00	                ; [1]
		.db	$a2,$00	                ; [1]
		.db	$a4,$00	                ; [1]
		.db	$a5,$00	                ; [1]
		.db	$a6,$00	                ; [1]
;		.db	$a8,$00	                ; [1] ch 3 special mode
;		.db	$a9,$00	                ; [1]
;		.db	$aa,$00	                ; [1]
;		.db	$ac,$00	                ; [1]
;		.db	$ad,$00	                ; [1]
;		.db	$ae,$00	                ; [1]
s18:
		.db	$a0,$00			; [2] ch 4-6 frequency
		.db	$a1,$00			; [2]
		.db	$a2,$00			; [2]
		.db	$a4,$00			; [2]
		.db	$a5,$00			; [2]
		.db	$a6,$00			; [2]
;		.db	$a8,$00			; [2] ch 3 special mode
;		.db	$a9,$00			; [2]
;		.db	$aa,$00			; [2]
;		.db	$ac,$00			; [2]
;		.db	$ad,$00			; [2]
;		.db	$ae,$00			; [2]
s19:
		.db	$b0,$00	                ; [1] ch 1-3 algorith + feedback
		.db	$b1,$00	                ; [1]
		.db	$b2,$00	                ; [1]
s20:
		.db	$b0,$00			; [2] ch 4-6 algorith + feedback
		.db	$b1,$00			; [2]
		.db	$b2,$00			; [2]
s21:
#ENDIF

