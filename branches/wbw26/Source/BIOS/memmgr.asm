;==================================================================================================
;   MEMORY PAGE MANAGEMENT
;==================================================================================================
;
; PAGE THE REQUESTED 32K BLOCK OF RAM/ROM INTO THE LOWER 32K OF CPU ADDRESS SPACE.
; LOAD DESIRED PAGE INDEX INTO A AND CALL PGSEL.
;______________________________________________________________________________________________________________________
;

#IF ((PLATFORM == PLT_N8VEM) | (PLATFORM == PLT_ZETA))
PGSEL:
	OUT	(MPCL_ROM),A
	OUT	(MPCL_RAM),A
	RET

#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#IF (PLATFORM == PLT_N8)
PGSEL:
	BIT	7,A
	JR	Z,PGSEL_ROM
;
PGSEL_RAM:
	RES	7,A
	RLCA
	RLCA
	RLCA
	OUT0	(CPU_BBR),A
	LD	A,DEFACR | 80H
	OUT0	(ACR),A
	RET
;
PGSEL_ROM:
	OUT0	(RMAP),A
	XOR	A
	OUT0	(CPU_BBR),A
	LD	A,DEFACR
	OUT0	(ACR),A
	RET
;
#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#IF (PLATFORM == PLT_MK4)
PGSEL:
	RLCA
	RLCA
	RLCA
	OUT0	(CPU_BBR),A
	RET
#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; NOTE: S2I HAS NO BANKED MEMORY!
;       ALL FUNCTIONALITY IS NULLED OUT HERE.
;
#IF (PLATFORM == PLT_S2I)
PGSEL:
	RET
#ENDIF

;;;;;;;;;;;;;;;;;;;;
; EOF - MEMMGR.ASM ;
;;;;;;;;;;;;;;;;;;;;
