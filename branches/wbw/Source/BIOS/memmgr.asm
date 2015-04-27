;==================================================================================================
;   MEMORY BANK MANAGEMENT
;==================================================================================================
;
; SELECT THE REQUESTED 32K BANK OF RAM/ROM INTO THE LOWER 32K OF CPU ADDRESS SPACE.
; LOAD DESIRED BANK INDEX INTO A AND CALL BNKSEL.
;______________________________________________________________________________________________________________________
;

#IF ((PLATFORM == PLT_SBC) | (PLATFORM == PLT_ZETA))
BNKSEL:
	OUT	(MPCL_ROM),A
	OUT	(MPCL_RAM),A
	RET

#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ZETA SBC V2 USES 16K PAGES. ANY PAGE CAN BE MAPPED TO ONE OF FOUR BANKS:
; BANK_0: 0K - 16K; BANK_1: 16K - 32K; BANK_2: 32K - 48K; BANK_3: 48K - 64K
; THIS BNKSEL EMULATES SBC / ZETA BEHAVIOR BY SETTING BANK_0 and BANK_1 TO
; TWO CONSECUTIVE PAGES

#IF (PLATFORM == PLT_ZETA2)
BNKSEL:
	BIT	7,A
	JR	Z,BNKSEL_ROM             ; JUMP IF IT IS A ROM PAGE
        RES     7,A			; RAM PAGE REQUESTED: CLEAR ROM BIT
        ADD	A,16			; ADD 16 x 32K - RAM STARTS FROM 512K 
;
BNKSEL_ROM:
	RLCA				; TIMES 2 - GET 16K PAGE INSTEAD OF 32K
	OUT	(MPGSEL_0),A		; BANK_0: 0K - 16K
	INC	A
	OUT	(MPGSEL_1),A		; BANK_1: 16K - 32K
	RET
#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#IF (PLATFORM == PLT_N8)
BNKSEL:
	BIT	7,A
	JR	Z,BNKSEL_ROM
;
BNKSEL_RAM:
	RES	7,A
	RLCA
	RLCA
	RLCA
	OUT0	(Z180_BBR),A
	LD	A,N8_DEFACR | 80H
	OUT0	(N8_ACR),A
	RET
;
BNKSEL_ROM:
	OUT0	(N8_RMAP),A
	XOR	A
	OUT0	(Z180_BBR),A
	LD	A,N8_DEFACR
	OUT0	(N8_ACR),A
	RET
;
#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#IF (PLATFORM == PLT_MK4)
BNKSEL:
	RLCA
	RLCA
	RLCA
	OUT0	(Z180_BBR),A
	RET
#ENDIF

;;;;;;;;;;;;;;;;;;;;
; EOF - MEMMGR.ASM ;
;;;;;;;;;;;;;;;;;;;;
