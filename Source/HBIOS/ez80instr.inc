;
;==================================================================================================
;   HELPER MACROS FOR TARGETING EZ80 CPU INSTRUCTIONS
;==================================================================================================

;
; EMIT PREFIX REQUIRED BY EZ80 TO ENSURE CORRECT 16 BIT IO OPERATION
;
#IF (CPUFAM == CPU_EZ80)
  #DEFINE EZ80_IO	.DB 	$49, $CF	; RST.L $08
  #DEFINE EZ80_FN 	.DB	$49, $D7	; RST.L $10
  #DEFINE EZ80_BNKSEL 	.DB	$49, $DF	; RST.L $18

  #DEFINE RET.L		.DB	$49 \ RET

  #DEFINE IN0_A(p)	.DB	$ED,$38,p
  #DEFINE IN0_B(p)	.DB	$ED,$00,p
  #DEFINE IN0_C(p)	.DB	$ED,$08,p
  #DEFINE IN0_D(p)	.DB	$ED,$10,p
  #DEFINE IN0_E(p)	.DB	$ED,$18,p
  #DEFINE IN0_H(p)	.DB	$ED,$20,p
  #DEFINE IN0_L(p)	.DB	$ED,$28,p

  #DEFINE OUT0_A(p)	.DB	$ED,$39,p
  #DEFINE OUT0_B(p)	.DB	$ED,$01,p
  #DEFINE OUT0_C(p)	.DB	$ED,$09,p
  #DEFINE OUT0_D(p)	.DB	$ED,$11,p
  #DEFINE OUT0_E(p)	.DB	$ED,$19,p
  #DEFINE OUT0_H(p)	.DB	$ED,$21,p
  #DEFINE OUT0_L(p)	.DB	$ED,$29,p

  #DEFINE LDHLMM.LIL(Mmn)	\
  #defcont \	.DB	$5B
  #defcont \	LD	HL, Mmn
  #defcont \	.DB	(Mmn >> 16) & $FF

  #DEFINE LDBCMM.LIL(Mmn)	\
  #defcont \	.DB	$5B
  #defcont \	LD	BC, Mmn
  #defcont \	.DB	(Mmn >> 16) & $FF

  #DEFINE SBCHLBC.LIL \
  #defcont \	.DB	$49
  #defcont \	SBC	HL, BC

IO_SEGMENT	.EQU		$FF		; THE UPPER 8-BIT ADDRESS FOR I/O

#ELSE
  #DEFINE EZ80_IO
#ENDIF
