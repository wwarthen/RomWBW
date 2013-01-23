;==================================================================================================
;   MEMORY PAGE MANAGEMENT
;==================================================================================================
;
; PAGE THE REQUESTED 32K BLOCK OF RAM/ROM INTO THE LOWER 32K OF CPU ADDRESS SPACE.
; LOAD DESIRED PAGE INDEX INTO A AND CALL EITHER RAMPG OR ROMPG AS DESIRED.
; RAMPGZ AND ROMPGZ ARE SHORTCUTS TO PAGE IN THE RAM/ROM ZERO PAGE.
;______________________________________________________________________________________________________________________
;


;______________________________________________________________________________________________________________________;
; MACROS TO PERFORM RAM/ROM PAGE SELECTION INTO LOWER 32K OF MEMORY SPACE
;   PGRAM(P)   SELECT RAM PAGE P
;   PGRAMF(P)  SELECT RAM PAGE P, FAST VERSION ASSUMES CURRENT PAGE IS A RAM PAGE
;   PGROM(P)   SELECT ROM PAGE P
;   PGROMF(P)  SELECT ROM PAGE P, FAST VERSION ASSUMES CURRENT PAGE IS A ROM PAGE
;
;   REGISTER A IS DESTROYED
;______________________________________________________________________________________________________________________
;

#IF (PLATFORM == PLT_N8VEM)
RAMPGZ:			; SELECT RAM PAGE ZERO
	XOR	A
RAMPG:
	OR	80H	; TURN ON BIT 7 TO SELECT RAM PAGES
	JR	PGSEL

ROMPGZ:			; SELECT ROM PAGE ZERO
	XOR	A
ROMPG:
	AND	7FH	; TURN OFF BIT 7 TO SELECT ROM PAGES
	JR	PGSEL

PGSEL:
	OUT	(MPCL_ROM),A
	OUT	(MPCL_RAM),A
	RET
	
  #DEFINE PGRAM(P)	LD A,P | 80H \ OUT (MPCL_ROM),A \ OUT (MPCL_RAM),A
  #DEFINE PGRAMF(P)	LD A,P | 80H \ OUT (MPCL_RAM),A

  #DEFINE PGROM(P)	LD A,P & 7FH \ OUT (MPCL_ROM),A \ OUT (MPCL_RAM),A
  #DEFINE PGROMF(P)	LD A,P & 7FH \ OUT (MPCL_ROM),A

#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#IF (PLATFORM == PLT_ZETA)
RAMPGZ:			; SELECT RAM PAGE ZERO
	XOR	A
RAMPG:
	OR	80H	; TURN ON BIT 7 TO SELECT RAM PAGES
	JR	PGSEL

ROMPGZ:			; SELECT ROM PAGE ZERO
	XOR	A
ROMPG:
	AND	7FH	; TURN OFF BIT 7 TO SELECT ROM PAGES
	JR	PGSEL

PGSEL:
	OUT	(MPCL_ROM),A
	OUT	(MPCL_RAM),A
	RET

  #DEFINE PGRAM(P)	LD A,P | 80H \ OUT (MPCL_ROM),A \ OUT (MPCL_RAM),A
  #DEFINE PGRAMF(P)	LD A,P | 80H \ OUT (MPCL_RAM),A

  #DEFINE PGROM(P)	LD A,P & 7FH \ OUT (MPCL_ROM),A \ OUT (MPCL_RAM),A
  #DEFINE PGROMF(P)	LD A,P & 7FH \ OUT (MPCL_ROM),A

#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


#IF (PLATFORM == PLT_N8)
RAMPGZ:			; SELECT RAM PAGE ZERO
	XOR	A
RAMPG:
	RLCA
	RLCA
	RLCA
	OUT0	(CPU_BBR),A
	LD	A,DEFACR | 80H
	OUT0	(ACR),A
	RET
;a
ROMPGZ:			; SELECT ROM PAGE ZERO
	XOR	A
ROMPG:
	OUT0	(RMAP),A
	XOR	A
	OUT0	(CPU_BBR),A
	LD	A,DEFACR
	OUT0	(ACR),A
	RET

#DEFINE PGRAM(P)	LD A,P << 3 \ OUT0 (CPU_BBR),A \ LD A,DEFACR | 80H \ OUT0 (ACR),A
#DEFINE PGRAMF(P)	LD A,P << 3 \ OUT0 (CPU_BBR),A

#DEFINE PGROM(P)	LD A,P \ OUT0 (RMAP),A \ XOR A \ OUT0 (CPU_BBR),A \ LD A,DEFACR \ OUT0 (ACR),A
#DEFINE PGROMF(P)	LD A,P \ OUT0 (RMAP),A

#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#IF (PLATFORM == PLT_S2I)
RAMPGZ:			; SELECT RAM PAGE ZERO
	XOR	A
RAMPG:
	OR	80H	; TURN ON BIT 7 TO SELECT RAM PAGES
	JR	PGSEL

ROMPGZ:			; SELECT ROM PAGE ZERO
	XOR	A
ROMPG:
	AND	7FH	; TURN OFF BIT 7 TO SELECT ROM PAGES
	JR	PGSEL

PGSEL:
	OUT	(MPCL_ROM),A
	OUT	(MPCL_RAM),A
	RET
  #DEFINE PGRAM(P)	LD A,P | 80H \ OUT (MPCL_ROM),A \ OUT (MPCL_RAM),A
  #DEFINE PGRAMF(P)	LD A,P | 80H \ OUT (MPCL_RAM),A

  #DEFINE PGROM(P)	LD A,P & 7FH \ OUT (MPCL_ROM),A \ OUT (MPCL_RAM),A
  #DEFINE PGROMF(P)	LD A,P & 7FH \ OUT (MPCL_ROM),A

#ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#IF (PLATFORM == PLT_S100)
RAMPGZ:			; SELECT RAM PAGE ZERO
	XOR	A

RAMPG:
	OR	80H	; TURN ON BIT 7 TO SELECT RAM PAGES
	JR	PGSEL

ROMPGZ:			; SELECT ROM PAGE ZERO
	XOR	A

ROMPG:
	AND	7FH	; TURN OFF BIT 7 TO SELECT ROM PAGES
	JR	PGSEL

PGSEL:
	OUT	(MPCL_ROM),A
	OUT	(MPCL_RAM),A
	RET

  #DEFINE PGRAM(P)	LD A,P | 80H \ OUT (MPCL_ROM),A \ OUT (MPCL_RAM),A
  #DEFINE PGRAMF(P)	LD A,P | 80H \ OUT (MPCL_RAM),A

  #DEFINE PGROM(P)	LD A,P & 7FH \ OUT (MPCL_ROM),A \ OUT (MPCL_RAM),A
  #DEFINE PGROMF(P)	LD A,P & 7FH \ OUT (MPCL_ROM),A

#ENDIF

;;;;;;;;;;;;;;;;;;;;
; EOF - MEMMGR.ASM ;
;;;;;;;;;;;;;;;;;;;;
