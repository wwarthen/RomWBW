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

  #DEFINE EZ80_UTIL_INIT	XOR A \ LD B, 0 \ EZ80_FN
  #DEFINE EZ80_UTIL_EHL_TO_HL	XOR A \ LD B, 1 \ EZ80_FN
  #DEFINE EZ80_UTIL_HL_TO_EHL	XOR A \ LD B, 2 \ EZ80_FN
  #DEFINE EZ80_UTIL_SET_BUSTM 	XOR A \ LD B, 3 \ EZ80_FN
  #DEFINE EZ80_UTIL_SET_BUSFQ 	XOR A \ LD B, 4 \ EZ80_FN

  #DEFINE EZ80_RTC_INIT 	LD A, 1 \ LD B, 0 \ EZ80_FN
  #DEFINE EZ80_RTC_GET_TIME 	LD A, 1	\ LD B, 1 \ EZ80_FN
  #DEFINE EZ80_RTC_SET_TIME 	LD A, 1	\ LD B, 2 \ EZ80_FN

  #DEFINE EZ80_TMR_GET_TICKS	LD A, 2 \ LD B, 0 \ EZ80_FN
  #DEFINE EZ80_TMR_GET_SECONDS	LD A, 2 \ LD B, 1 \ EZ80_FN
  #DEFINE EZ80_TMR_SET_TICKS	LD A, 2 \ LD B, 2 \ EZ80_FN
  #DEFINE EZ80_TMR_SET_SECONDS	LD A, 2 \ LD B, 3 \ EZ80_FN
  #DEFINE EZ80_TMR_GET_FREQTICK	LD A, 2 \ LD B, 4 \ EZ80_FN
  #DEFINE EZ80_TMR_SET_FREQTICK	LD A, 2 \ LD B, 5 \ EZ80_FN

  #DEFINE EZ80_UART_IN		LD A, 3 \ LD B, 0 \ EZ80_FN
  #DEFINE EZ80_UART_OUT		LD A, 3 \ LD B, 1 \ EZ80_FN
  #DEFINE EZ80_UART_IN_STAT	LD A, 3 \ LD B, 2 \ EZ80_FN
  #DEFINE EZ80_UART_OUT_STAT	LD A, 3 \ LD B, 3 \ EZ80_FN
  #DEFINE EZ80_UART_CONFIG	LD A, 3 \ LD B, 4 \ EZ80_FN
  #DEFINE EZ80_UART_QUERY	LD A, 3 \ LD B, 5 \ EZ80_FN
  #DEFINE EZ80_UART_RESET	LD A, 3 \ LD B, 6 \ EZ80_FN

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
