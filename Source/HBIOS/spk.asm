;
;======================================================================
; I/O BIT DRIVER FOR CONSOLE BELL FOR SBC V2 USING BIT 0 OF RTC DRIVER
;======================================================================
;
SPK_INIT:
	CALL	NEWLINE			; FORMATTING
	PRTS("SPK: IO=0x$")
	LD	A,RTCIO
	CALL	PRTHEXBYTE
	CALL	SPK_SETTBL
	CALL	SPK_BEEP		; PLAY A NOTE
	XOR	A
	RET
;
; SETUP THE SPEAKER NOTE TABLE ACCORDING TO THE CPU SPEED.
; FREQUENCY ACCURACY DECREASES AS CLOCK SPEED MULITPLIER INCREASES.
; 1MHZ ERROR MAY OCCUR IF CPU CLOCK IS UNDER. I.E 3.999 = 3MHZ 

SPK_SETTBL:
	LD	A,(CB_CPUMHZ)		; GET CPU SPEED. 
	LD	C,A

	LD	B,SPK_NOTCNT		; SET  NUMBER OF NOTES TO 
	LD	HL,SPK_TUNTBL+2		; ADJUST AND START POINT

SPK_SETTBL2:
	PUSH	HL
	LD	A,(HL)			; READ
	LD	E,A			; IN
	INC	HL			; THE
	LD	A,(HL)			; 1MHZ
	LD	D,A			; NOTE

	PUSH	BC
	LD	B,C
	LD	HL,0			; MULTIPLY
SPK_SETTBL1:				; 1MHZ NOTE
	ADD	HL,DE			; VALUE BY
	DJNZ	SPK_SETTBL1		; SYSTEM MHZ
	POP	BC
;
	LD	DE,30			; ADD OVEREAD
	ADD	HL,DE			; COMPENSATION
;
	POP	DE			; RECALL NOTE
	EX	DE,HL			; ADDRESS
;
	LD	(HL),E			; SAVE 		
	INC	HL			; THE
	LD	(HL),D			; NEW
	INC	HL			; NOTE
	INC	HL			; AND MOVE
	INC	HL			; TO NEXT

	DJNZ	SPK_SETTBL2		; NEXT NOTE
	RET

SPK_BEEP:
	LD	HL,SPK_NOTE_C8		; SELECT NOTE
;
	LD	A,(HL)			; LOAD 1ST ARG
	INC	HL			; IN DE
	LD	E,A
	LD	A,(HL)
	INC	HL
	LD	D,A
;
	LD	A,(HL)			; LOAD 2ND ARG
	INC	HL			; IN BC
	LD	C,A
	LD	A,(HL)	
	INC	HL
	LD	B,A
	PUSH	BC			; SETUP ARG IN HL
	POP	HL
;
	CALL	SPK_BEEPER		; PLAY 
;
	RET
;
;	The following SPK_BEEPER routine is a modification of code from 
;	"The Complete SPECTRUM ROM DISSASSEMBLY" by Dr Ian Logan & Dr Frank O’Hara
;
;	https://www.esocop.org/docs/CompleteSpectrumROMDisassemblyThe.pdf
;
;	DE 	Number of passes to make through the sound generation loop
;	HL 	Loop delay parameter
;
SPK_BEEPER:
	PUSH	IX
	DI 				; Disable the interrupt for the duration of a 'beep'.
	LD	A,L 			; Save L temporarily.
	SRL	L 			; Each '1' in the L register is to count 4 T states, but take INT (L/4) and count 16 T states instead.
	SRL	L
	CPL 				; Go back to the original value in L and find how many were lost by taking 3-(A mod 4).
	AND	$03
	LD	C,A
	LD	B,$00
	LD	IX,SPK_DLYADJ 		; The base address of the timing loop.
	ADD	IX,BC			; Alter the length of the timing loop. Use an earlier starting point for each '1' lost by taking INT (L/4).
	LD	A,(RTCVAL)		; Fetch the present border colour from BORDCR and move it to bits 2, 1 and 0 of the A register.
;
;	The HL register holds the 'length of the timing loop' with 16 T states being used for each '1' in the L register and 1024 T states for each '1' in the H register.
;
SPK_DLYADJ:
	NOP 				; Add 4 T states for each earlier entry point that is used.
	NOP
	NOP
	INC	B 			; The values in the B and C registers will come from the H and L registers - see below.
	INC	C
BE_H_L_LP:
	DEC	C			; The 'timing loop', i.e. BC*4 T states. (But note that at the half-cycle point, C will be equal to L+1.)
	JR	NZ,BE_H_L_LP
	LD	C,$3F
	DEC	B
	JP	NZ,BE_H_L_LP
;
;	The loudspeaker is now alternately activated and deactivated.
;
	XOR	%00000100		; Flip bit 2.
	OUT	(RTCIO),A		; Perform the 'OUT' operation, leaving other bits unchanged.
	LD	B,H			; Reset the B register.
	LD	C,A			; Save the A register.
	BIT	4,A 			; Jump if at the half-cycle point.
	JR	NZ,BE_AGAIN
;
;	After a full cycle the DE register pair is tested.
;
	LD	A,D			; Jump forward if the last complete pass has been made already.
	OR	E
	JR	Z,BE_END
	LD	A,C			; Fetch the saved value.
	LD	C,L			; Reset the C register.
	DEC	DE			; Decrease the pass counter.
	JP	(IX)			; Jump back to the required starting location of the loop.
;
;	The parameters for the second half-cycle are set up.
;	
BE_AGAIN:
	LD	C,L			; Reset the C register.
	INC	C 			; Add 16 T states as this path is shorter.
	JP	(IX)			; Jump back.
BE_END:
	EI
	POP	IX
	RET
;
;	STANDARD ONE SECOND TONE TABLES AT 1MHZ (UNCOMPENSATED). FOR SPK_BEEPER, FIRST WORD LOADED INTO DE, SECOND INTO HL
;
;	EXCEL SPREADSHEET FOR CALCULATION CAN BE FOUND HERE:
;
;	https://www.retrobrewcomputers.org/lib/exe/fetch.php?media=boards:sbc:sbc_v2:sbc_v2-004:spk_beep_tuntbl.xlsx
;
SPK_TUNTBL:
	.DW $13, $191A ;  D
	.DW $14, $17B3 ; E0
	.DW $15, $165E ; F0
	.DW $17, $151E ;  F
	.DW $18, $13EE ; G0
	.DW $19, $12CF ;  G
	.DW $1B, $11C1 ; A0
	.DW $1D, $10C1 ;  A
	.DW $1E, $FD1 ; B0
	.DW $20, $EEE ; C1
	.DW $22, $E17 ;  C
	.DW $24, $D4D ; D1
	.DW $26, $C8E ;  D
	.DW $29, $BD9 ; E1
	.DW $2B, $B2F ; F1
	.DW $2E, $A8E ;  F
	.DW $31, $9F7 ; G1
	.DW $33, $968 ;  G
	.DW $37, $8E0 ; A1
	.DW $3A, $861 ;  A
	.DW $3D, $7E8 ; B1
	.DW $41, $777 ; C2
	.DW $45, $70B ;  C
	.DW $49, $6A6 ; D2
	.DW $4D, $647 ;  D
	.DW $52, $5EC ; E2
	.DW $57, $597 ; F2
	.DW $5C, $547 ;  F
	.DW $62, $4FB ; G2
	.DW $67, $4B3 ;  G
	.DW $6E, $470 ; A2
	.DW $74, $430 ;  A
	.DW $7B, $3F4 ; B2
	.DW $82, $3BB ; C3
	.DW $8A, $385 ;  C
	.DW $92, $353 ; D3
	.DW $9B, $323 ;  D
	.DW $A4, $2F6 ; E3
	.DW $AE, $2CB ; F3
	.DW $B9, $2A3 ;  F
	.DW $C4, $27D ; G3
	.DW $CF, $259 ;  G
	.DW $DC, $238 ; A3
	.DW $E9, $218 ;  A
	.DW $F6, $1FA ; B3
	.DW $105, $1DD ; C4
	.DW $115, $1C2 ;  C
	.DW $125, $1A9 ; D4
	.DW $137, $191 ;  D
	.DW $149, $17B ; E4
	.DW $15D, $165 ; F4
	.DW $171, $151 ;  F
	.DW $188, $13E ; G4
	.DW $19F, $12C ;  G
	.DW $1B8, $11C ; A4
	.DW $1D2, $10C ;  A
	.DW $1ED, $FD ; B4
	.DW $20B, $EE ; C5
	.DW $22A, $E1 ;  C
	.DW $24B, $D4 ; D5
	.DW $26E, $C8 ;  D
	.DW $293, $BD ; E5
	.DW $2BA, $B2 ; F5
	.DW $2E3, $A8 ;  F
	.DW $30F, $9F ; G5
	.DW $33E, $96 ;  G
	.DW $370, $8E ; A5
	.DW $3A4, $86 ;  A
	.DW $3DB, $7E ; B5
	.DW $416, $77 ; C6
	.DW $454, $70 ;  C
	.DW $496, $6A ; D6
	.DW $4DC, $64 ;  D
	.DW $526, $5E ; E6
	.DW $574, $59 ; F6
	.DW $5C7, $54 ;  F
	.DW $61F, $4F ; G6
	.DW $67D, $4B ;  G
	.DW $6E0, $47 ; A6
	.DW $748, $43 ;  A
	.DW $7B7, $3F ; B6
	.DW $82D, $3B ; C7
	.DW $8A9, $38 ;  C
	.DW $92D, $35 ; D7
	.DW $9B9, $32 ;  D
	.DW $A4D, $2F ; E7
	.DW $AE9, $2C ; F7
	.DW $B8F, $2A ;  F
	.DW $C3F, $27 ; G7
	.DW $CFA, $25 ;  G
	.DW $DC0, $23 ; A7
	.DW $E91, $21 ;  A
	.DW $F6F, $1F ; B7	
SPK_NOTE_C8:
	.DW $105A, $1D ; C8
	.DW $1152, $1C ;  C
	.DW $125A, $1A ; D8
	.DW $1372, $19 ;  D
	.DW $149A, $17 ; E8
	.DW $15D3, $16 ; F8
	.DW $171F, $15 ;  F
	.DW $187F, $13 ; G8
	.DW $19F4, $12 ;  G
	.DW $1B80, $11 ; A8
	.DW $1D22, $10 ;  A
	.DW $1EDE, $F ; B8

SPK_NOTCNT	.EQU	($-SPK_TUNTBL) / 4
