;
;==================================================================================================
;   WRAPPER FOR ZCPR FOR N8VEM PROJECT
;   WAYNE WARTHEN - 2011-01-10
;==================================================================================================
;
; THE FOLLOWING MACROS DO THE HEAVY LIFTING TO MAKE THE ZCPR SOURCE
; COMPATIBLE WITH TASM
;
;#DEFINE	DS	.DS
;#DEFINE	ds	.ds
#DEFINE	DS	.FILL
#DEFINE	ds	.fill
#DEFINE	TITLE	.TITLE
#DEFINE	title	.title
#DEFINE	EQU	.EQU
#define equ	.equ
#DEFINE	NAME	\;
#DEFINE	PAGE	.PAGE
#DEFINE	page	.page
#DEFINE	CSEG	.CSEG
#DEFINE	ORG	.ORG
#DEFINE	org	.org
#DEFINE	END	.END
#DEFINE	IF	.IF
#DEFINE if	.if
#DEFINE	ELSE	.ELSE
#DEFINE	else	.else
#DEFINE	ENDIF	.ENDIF
#DEFINE endif	.endif
#DEFINE	DEFB	.DB
#DEFINE	defb	.db
#DEFINE	DEFW	.DW
#DEFINE	defw	.dw
#DEFINE	DEFL	.EQU
#DEFINE	defl	.equ
#DEFINE	DEFS	.DB
#DEFINE	defs	.db
#DEFINE	DW	.DW
#DEFINE	dw	.dw
#DEFINE	DB	.DB
#DEFINE	db	.db
#DEFINE	END	.END
#DEFINE	end	.end
;
;    Add some Z80 instructions
;
#ADDINSTR	JR	*	18   2 R1  1
#ADDINSTR	JRC	*	38   2 R1  1
#ADDINSTR	JRNC	*	30   2 R1  1
#ADDINSTR	JRZ	*	28   2 R1  1
#ADDINSTR	JRNZ	*	20   2 R1  1
#ADDINSTR	LDIR	""	B0ED 2 NOP 1
#ADDINSTR	DJNZ	*	10   2 R1  1
#ADDINSTR	LDED	*	5BED 4 NOP 1
#ADDINSTR	SDED	*	53ED 4 NOP 1
;
; NOW INCLUDE THE MAIN SOURCE
;
#INCLUDE "zcpr.asm"
;
	.FILL	((CPRLOC + 0800H) - $),055H
;
	.END