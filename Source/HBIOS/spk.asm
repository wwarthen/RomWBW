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
	CALL	SPK_BEEP		; PLAY A NOTE
	XOR	A
	RET
;
;SPK_BEEP:
;	PUSH	DE
;	PUSH	HL
;	LD	HL,400			; CYCLES OF TONE
;	;LD	B,%00000100		; D2 MAPPED TO Q0
;	;LD	A,DSRTC_RESET
;	LD	A,(RTCVAL)		; GET RTC PORT VALUE FROM SHADOW
;	OR	%00000100		; D2 MAPPED TO Q0
;	LD	B,A
;SPK_BEEP1:
;	LD	A,B
;	OUT	(RTCIO),A
;	XOR	%00000100
;	LD	B,A
;	LD	DE,17
;	CALL	VDELAY
;	DEC	HL
;	LD	A,H
;	OR	L
;	JR	NZ,SPK_BEEP1
;	POP	HL
;	POP	DE
;	RET

SPK_BEEP:
	LD	HL,SPK_NOTE_C8		; SELECT NOTE

	LD	A,(HL)			; LOAD 1ST ARG
	INC	HL			; IN DE
	LD	E,A
	LD	A,(HL)
	INC	HL
	LD	D,A

	LD	A,(HL)			; LOAD 2ND ARG
	INC	HL			; IN BC
	LD	C,A
	LD	A,(HL)	
	INC	HL
	LD	B,A
	PUSH	BC			; SETUP ARG IN HL
	POP	HL

	CALL	SPK_BEEPER		; PLAY 

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
;	STANDARD ONE SECOND TONE TABLES. FOR SPK_BEEPER, FIRST WORD LOADED INTO DE, SECOND INTO HL
;
;	EXCEL SPREADSHEET FOR CALCULATION CAN BE FOUND HERE:
;
;	https://www.retrobrewcomputers.org/lib/exe/fetch.php?media=boards:sbc:sbc_v2:sbc_v2-004:spk_beep_tuntbl.xlsx
;
SPK_TUNTBL:

#IF (CPUOSC=2000000)
	.DW $10, $6868 ; C0
	.DW $11, $628D ;  C
	.DW $12, $5D03 ; D0
	.DW $13, $57BF ;  D
	.DW $14, $52D7 ; E0
	.DW $15, $4E2B ; F0
	.DW $17, $49CD ;  F
	.DW $18, $45A3 ; G0
	.DW $19, $41B6 ;  G
	.DW $1B, $3E07 ; A0
	.DW $1D, $3A87 ;  A
	.DW $1E, $373E ; B0
	.DW $20, $3425 ; C1
	.DW $22, $3134 ;  C
	.DW $24, $2E6F ; D1
	.DW $26, $2BD3 ;  D
	.DW $29, $295C ; E1
	.DW $2B, $2708 ; F1
	.DW $2E, $24D5 ;  F
	.DW $31, $22C2 ; G1
	.DW $33, $20CE ;  G
	.DW $37, $1EF4 ; A1
	.DW $3A, $1D36 ;  A
	.DW $3D, $1B90 ; B1
	.DW $41, $1A02 ; C2
	.DW $45, $188B ;  C
	.DW $49, $1728 ; D2
	.DW $4D, $15DA ;  D
	.DW $52, $149E ; E2
	.DW $57, $1374 ; F2
	.DW $5C, $125B ;  F
	.DW $62, $1152 ; G2
	.DW $67, $1057 ;  G
	.DW $6E, $F6B ; A2
	.DW $74, $E8C ;  A
	.DW $7B, $DB9 ; B2
	.DW $82, $CF2 ; C3
	.DW $8A, $C36 ;  C
	.DW $92, $B85 ; D3
	.DW $9B, $ADE ;  D
	.DW $A4, $A40 ; E3
	.DW $AE, $9AB ; F3
	.DW $B9, $91E ;  F
	.DW $C4, $89A ; G3
	.DW $CF, $81C ;  G
	.DW $DC, $7A6 ; A3
	.DW $E9, $737 ;  A
	.DW $F6, $6CD ; B3
	.DW $105, $66A ; C4
	.DW $115, $60C ;  C
	.DW $125, $5B3 ; D4
	.DW $137, $560 ;  D
	.DW $149, $511 ; E4
	.DW $15D, $4C6 ; F4
	.DW $171, $480 ;  F
	.DW $188, $43E ; G4
	.DW $19F, $3FF ;  G
	.DW $1B8, $3C4 ; A4
	.DW $1D2, $38C ;  A
	.DW $1ED, $357 ; B4
	.DW $20B, $326 ; C5
	.DW $22A, $2F7 ;  C
	.DW $24B, $2CA ; D5
	.DW $26E, $2A1 ;  D
	.DW $293, $279 ; E5
	.DW $2BA, $254 ; F5
	.DW $2E3, $231 ;  F
	.DW $30F, $210 ; G5
	.DW $33E, $1F0 ;  G
	.DW $370, $1D3 ; A5
	.DW $3A4, $1B7 ;  A
	.DW $3DB, $19C ; B5
	.DW $416, $184 ; C6
	.DW $454, $16C ;  C
	.DW $496, $156 ; D6
	.DW $4DC, $141 ;  D
	.DW $526, $12D ; E6
	.DW $574, $11B ; F6
	.DW $5C7, $109 ;  F
	.DW $61F, $F9 ; G6
	.DW $67D, $E9 ;  G
	.DW $6E0, $DA ; A6
	.DW $748, $CC ;  A
	.DW $7B7, $BF ; B6
	.DW $82D, $B3 ; C7
	.DW $8A9, $A7 ;  C
	.DW $92D, $9C ; D7
	.DW $9B9, $91 ;  D
	.DW $A4D, $87 ; E7
	.DW $AE9, $7E ; F7
	.DW $B8F, $75 ;  F
	.DW $C3F, $6D ; G7
	.DW $CFA, $65 ;  G
	.DW $DC0, $5E ; A7
	.DW $E91, $57 ;  A
	.DW $F6F, $50 ; B7
SPK_NOTE_C8:
	.DW $105A, $4A ; C8
	.DW $1152, $44 ;  C
	.DW $125A, $3F ; D8
	.DW $1372, $39 ;  D
	.DW $149A, $34 ; E8
	.DW $15D3, $30 ; F8
	.DW $171F, $2B ;  F
	.DW $187F, $27 ; G8
	.DW $19F4, $23 ;  G
	.DW $1B80, $20 ; A8
	.DW $1D22, $1C ;  A
	.DW $1EDE, $19 ; B8
#ENDIF
;
#IF (CPUOSC=4000000)
	.DW $10, $7757 ; C0
	.DW $11, $70A6 ;  C
	.DW $12, $6A51 ; D0
	.DW $13, $644C ;  D
	.DW $14, $5EB1 ; E0
	.DW $15, $595A ; F0
	.DW $17, $545C ;  F
	.DW $18, $4F9A ; G0
	.DW $19, $4B1E ;  G
	.DW $1B, $46E7 ; A0
	.DW $1D, $42E8 ;  A
	.DW $1E, $3F26 ; B0
	.DW $20, $3B9C ; C1
	.DW $22, $3840 ;  C
	.DW $24, $3516 ; D1
	.DW $26, $321A ;  D
	.DW $29, $2F49 ; E1
	.DW $2B, $2CA0 ; F1
	.DW $2E, $2A1C ;  F
	.DW $31, $27BE ; G1
	.DW $33, $2582 ;  G
	.DW $37, $2364 ; A1
	.DW $3A, $2166 ;  A
	.DW $3D, $1F84 ; B1
	.DW $41, $1DBE ; C2
	.DW $45, $1C11 ;  C
	.DW $49, $1A7C ; D2
	.DW $4D, $18FE ;  D
	.DW $52, $1795 ; E2
	.DW $57, $1640 ; F2
	.DW $5C, $14FF ;  F
	.DW $62, $13D0 ; G2
	.DW $67, $12B1 ;  G
	.DW $6E, $11A3 ; A2
	.DW $74, $10A4 ;  A
	.DW $7B, $FB3 ; B2
	.DW $82, $ED0 ; C3
	.DW $8A, $DF9 ;  C
	.DW $92, $D2F ; D3
	.DW $9B, $C70 ;  D
	.DW $A4, $BBB ; E3
	.DW $AE, $B11 ; F3
	.DW $B9, $A70 ;  F
	.DW $C4, $9D9 ; G3
	.DW $CF, $949 ;  G
	.DW $DC, $8C2 ; A3
	.DW $E9, $843 ;  A
	.DW $F6, $7CA ; B3
	.DW $105, $759 ; C4
	.DW $115, $6ED ;  C
	.DW $125, $688 ; D4
	.DW $137, $629 ;  D
	.DW $149, $5CE ; E4
	.DW $15D, $579 ; F4
	.DW $171, $529 ;  F
	.DW $188, $4DD ; G4
	.DW $19F, $495 ;  G
	.DW $1B8, $452 ; A4
	.DW $1D2, $412 ;  A
	.DW $1ED, $3D6 ; B4
	.DW $20B, $39D ; C5
	.DW $22A, $367 ;  C
	.DW $24B, $335 ; D5
	.DW $26E, $305 ;  D
	.DW $293, $2D8 ; E5
	.DW $2BA, $2AD ; F5
	.DW $2E3, $285 ;  F
	.DW $30F, $25F ; G5
	.DW $33E, $23B ;  G
	.DW $370, $21A ; A5
	.DW $3A4, $1FA ;  A
	.DW $3DB, $1DC ; B5
	.DW $416, $1BF ; C6
	.DW $454, $1A4 ;  C
	.DW $496, $18B ; D6
	.DW $4DC, $173 ;  D
	.DW $526, $15D ; E6
	.DW $574, $147 ; F6
	.DW $5C7, $133 ;  F
	.DW $61F, $120 ; G6
	.DW $67D, $10E ;  G
	.DW $6E0, $FE ; A6
	.DW $748, $EE ;  A
	.DW $7B7, $DF ; B6
	.DW $82D, $D0 ; C7
	.DW $8A9, $C3 ;  C
	.DW $92D, $B6 ; D7
	.DW $9B9, $AA ;  D
	.DW $A4D, $9F ; E7
	.DW $AE9, $94 ; F7
	.DW $B8F, $8A ;  F
	.DW $C3F, $81 ; G7
	.DW $CFA, $78 ;  G
	.DW $DC0, $70 ; A7
	.DW $E91, $68 ;  A
	.DW $F6F, $60 ; B7
SPK_NOTE_C8:
	.DW $105A, $59 ; C8
	.DW $1152, $52 ;  C
	.DW $125A, $4C ; D8
	.DW $1372, $46 ;  D
	.DW $149A, $40 ; E8
	.DW $15D3, $3B ; F8
	.DW $171F, $36 ;  F
	.DW $187F, $31 ; G8
	.DW $19F4, $2D ;  G
	.DW $1B80, $29 ; A8
	.DW $1D22, $25 ;  A
	.DW $1EDE, $21 ; B8
#ENDIF
;
#IF (CPUOSC=6000000)
	.DW $10, $B311 ; C0
	.DW $11, $A908 ;  C
	.DW $12, $9F89 ; D0
	.DW $13, $9682 ;  D
	.DW $14, $8E19 ; E0
	.DW $15, $8616 ; F0
	.DW $17, $7E99 ;  F
	.DW $18, $7776 ; G0
	.DW $19, $70BC ;  G
	.DW $1B, $6A6A ; A0
	.DW $1D, $646B ;  A
	.DW $1E, $5EC9 ; B0
	.DW $20, $5979 ; C1
	.DW $22, $546F ;  C
	.DW $24, $4FB0 ; D1
	.DW $26, $4B37 ;  D
	.DW $29, $46FD ; E1
	.DW $2B, $4300 ; F1
	.DW $2E, $3F3A ;  F
	.DW $31, $3BAC ; G1
	.DW $33, $3852 ;  G
	.DW $37, $3526 ; A1
	.DW $3A, $3229 ;  A
	.DW $3D, $2F55 ; B1
	.DW $41, $2CAC ; C2
	.DW $45, $2A28 ;  C
	.DW $49, $27C9 ; D2
	.DW $4D, $258C ;  D
	.DW $52, $236E ; E2
	.DW $57, $2170 ; F2
	.DW $5C, $1F8E ;  F
	.DW $62, $1DC7 ; G2
	.DW $67, $1C19 ;  G
	.DW $6E, $1A84 ; A2
	.DW $74, $1905 ;  A
	.DW $7B, $179C ; B2
	.DW $82, $1647 ; C3
	.DW $8A, $1505 ;  C
	.DW $92, $13D5 ; D3
	.DW $9B, $12B7 ;  D
	.DW $A4, $11A8 ; E3
	.DW $AE, $10A9 ; F3
	.DW $B9, $FB8 ;  F
	.DW $C4, $ED4 ; G3
	.DW $CF, $DFD ;  G
	.DW $DC, $D33 ; A3
	.DW $E9, $C73 ;  A
	.DW $F6, $BBF ; B3
	.DW $105, $B14 ; C4
	.DW $115, $A73 ;  C
	.DW $125, $9DB ; D4
	.DW $137, $94C ;  D
	.DW $149, $8C5 ; E4
	.DW $15D, $845 ; F4
	.DW $171, $7CD ;  F
	.DW $188, $75B ; G4
	.DW $19F, $6EF ;  G
	.DW $1B8, $68A ; A4
	.DW $1D2, $62A ;  A
	.DW $1ED, $5D0 ; B4
	.DW $20B, $57B ; C5
	.DW $22A, $52A ;  C
	.DW $24B, $4DE ; D5
	.DW $26E, $497 ;  D
	.DW $293, $453 ; E5
	.DW $2BA, $413 ; F5
	.DW $2E3, $3D7 ;  F
	.DW $30F, $39E ; G5
	.DW $33E, $368 ;  G
	.DW $370, $336 ; A5
	.DW $3A4, $306 ;  A
	.DW $3DB, $2D9 ; B5
	.DW $416, $2AE ; C6
	.DW $454, $286 ;  C
	.DW $496, $260 ; D6
	.DW $4DC, $23C ;  D
	.DW $526, $21A ; E6
	.DW $574, $1FA ; F6
	.DW $5C7, $1DC ;  F
	.DW $61F, $1C0 ; G6
	.DW $67D, $1A5 ;  G
	.DW $6E0, $18C ; A6
	.DW $748, $174 ;  A
	.DW $7B7, $15D ; B6
	.DW $82D, $148 ; C7
	.DW $8A9, $134 ;  C
	.DW $92D, $121 ; D7
	.DW $9B9, $10F ;  D
	.DW $A4D, $FE ; E7
	.DW $AE9, $EE ; F7
	.DW $B8F, $DF ;  F
	.DW $C3F, $D1 ; G7
	.DW $CFA, $C3 ;  G
	.DW $DC0, $B7 ; A7
	.DW $E91, $AB ;  A
	.DW $F6F, $9F ; B7
SPK_NOTE_C8:
	.DW $105A, $95 ; C8
	.DW $1152, $8B ;  C
	.DW $125A, $81 ; D8
	.DW $1372, $78 ;  D
	.DW $149A, $70 ; E8
	.DW $15D3, $68 ; F8
	.DW $171F, $60 ;  F
	.DW $187F, $59 ; G8
	.DW $19F4, $52 ;  G
	.DW $1B80, $4C ; A8
	.DW $1D22, $46 ;  A
	.DW $1EDE, $40 ; B8
#ENDIF
;
#IF (CPUOSC=8000000)
	.DW $10, $EECC ; C0
	.DW $11, $E16A ;  C
	.DW $12, $D4C1 ; D0
	.DW $13, $C8B7 ;  D
	.DW $14, $BD81 ; E0
	.DW $15, $B2D2 ; F0
	.DW $17, $A8D6 ;  F
	.DW $18, $9F52 ; G0
	.DW $19, $965A ;  G
	.DW $1B, $8DED ; A0
	.DW $1D, $85EF ;  A
	.DW $1E, $7E6B ; B0
	.DW $20, $7757 ; C1
	.DW $22, $709E ;  C
	.DW $24, $6A4A ; D1
	.DW $26, $6453 ;  D
	.DW $29, $5EB1 ; E1
	.DW $2B, $595F ; F1
	.DW $2E, $5457 ;  F
	.DW $31, $4F9A ; G1
	.DW $33, $4B22 ;  G
	.DW $37, $46E7 ; A1
	.DW $3A, $42EB ;  A
	.DW $3D, $3F26 ; B1
	.DW $41, $3B9A ; C2
	.DW $45, $3840 ;  C
	.DW $49, $3516 ; D2
	.DW $4D, $321A ;  D
	.DW $52, $2F48 ; E2
	.DW $57, $2C9F ; F2
	.DW $5C, $2A1C ;  F
	.DW $62, $27BE ; G2
	.DW $67, $2581 ;  G
	.DW $6E, $2364 ; A2
	.DW $74, $2166 ;  A
	.DW $7B, $1F85 ; B2
	.DW $82, $1DBE ; C3
	.DW $8A, $1C11 ;  C
	.DW $92, $1A7C ; D3
	.DW $9B, $18FE ;  D
	.DW $A4, $1795 ; E3
	.DW $AE, $1641 ; F3
	.DW $B9, $14FF ;  F
	.DW $C4, $13D0 ; G3
	.DW $CF, $12B1 ;  G
	.DW $DC, $11A3 ; A3
	.DW $E9, $10A4 ;  A
	.DW $F6, $FB3 ; B3
	.DW $105, $ED0 ; C4
	.DW $115, $DF9 ;  C
	.DW $125, $D2F ; D4
	.DW $137, $C70 ;  D
	.DW $149, $BBB ; E4
	.DW $15D, $B11 ; F4
	.DW $171, $A70 ;  F
	.DW $188, $9D9 ; G4
	.DW $19F, $949 ;  G
	.DW $1B8, $8C2 ; A4
	.DW $1D2, $843 ;  A
	.DW $1ED, $7CA ; B4
	.DW $20B, $759 ; C5
	.DW $22A, $6ED ;  C
	.DW $24B, $688 ; D5
	.DW $26E, $629 ;  D
	.DW $293, $5CE ; E5
	.DW $2BA, $579 ; F5
	.DW $2E3, $529 ;  F
	.DW $30F, $4DD ; G5
	.DW $33E, $495 ;  G
	.DW $370, $452 ; A5
	.DW $3A4, $412 ;  A
	.DW $3DB, $3D6 ; B5
	.DW $416, $39D ; C6
	.DW $454, $367 ;  C
	.DW $496, $335 ; D6
	.DW $4DC, $305 ;  D
	.DW $526, $2D8 ; E6
	.DW $574, $2AD ; F6
	.DW $5C7, $285 ;  F
	.DW $61F, $25F ; G6
	.DW $67D, $23B ;  G
	.DW $6E0, $21A ; A6
	.DW $748, $1FA ;  A
	.DW $7B7, $1DC ; B6
	.DW $82D, $1BF ; C7
	.DW $8A9, $1A4 ;  C
	.DW $92D, $18B ; D7
	.DW $9B9, $173 ;  D
	.DW $A4D, $15D ; E7
	.DW $AE9, $147 ; F7
	.DW $B8F, $133 ;  F
	.DW $C3F, $120 ; G7
	.DW $CFA, $10E ;  G
	.DW $DC0, $FE ; A7
	.DW $E91, $EE ;  A
	.DW $F6F, $DF ; B7
SPK_NOTE_C8:
	.DW $105A, $D0 ; C8
	.DW $1152, $C3 ;  C
	.DW $125A, $B6 ; D8
	.DW $1372, $AA ;  D
	.DW $149A, $9F ; E8
	.DW $15D3, $94 ; F8
	.DW $171F, $8A ;  F
	.DW $187F, $81 ; G8
	.DW $19F4, $78 ;  G
	.DW $1B80, $70 ; A8
	.DW $1D22, $68 ;  A
	.DW $1EDE, $60 ; B8
#ENDIF
;
#IF (CPUOSC=10000000)
	;.DW $10, $12A86 ; C0
	;.DW $11, $119CC ;  C
	;.DW $12, $109F9 ; D0
	.DW $13, $FAED ;  D
	.DW $14, $ECE9 ; E0
	.DW $15, $DF8E ; F0
	.DW $17, $D313 ;  F
	.DW $18, $C72E ; G0
	.DW $19, $BBF9 ;  G
	.DW $1B, $B170 ; A0
	.DW $1D, $A772 ;  A
	.DW $1E, $9E0E ; B0
	.DW $20, $9534 ; C1
	.DW $22, $8CCD ;  C
	.DW $24, $84E4 ; D1
	.DW $26, $7D6F ;  D
	.DW $29, $7665 ; E1
	.DW $2B, $6FBE ; F1
	.DW $2E, $6975 ;  F
	.DW $31, $6388 ; G1
	.DW $33, $5DF2 ;  G
	.DW $37, $58A9 ; A1
	.DW $3A, $53AD ;  A
	.DW $3D, $4EF8 ; B1
	.DW $41, $4A88 ; C2
	.DW $45, $4657 ;  C
	.DW $49, $4263 ; D2
	.DW $4D, $3EA8 ;  D
	.DW $52, $3B22 ; E2
	.DW $57, $37CE ; F2
	.DW $5C, $34AB ;  F
	.DW $62, $31B5 ; G2
	.DW $67, $2EE8 ;  G
	.DW $6E, $2C45 ; A2
	.DW $74, $29C7 ;  A
	.DW $7B, $276D ; B2
	.DW $82, $2535 ; C3
	.DW $8A, $231D ;  C
	.DW $92, $2123 ; D3
	.DW $9B, $1F45 ;  D
	.DW $A4, $1D82 ; E3
	.DW $AE, $1BD8 ; F3
	.DW $B9, $1A46 ;  F
	.DW $C4, $18CB ; G3
	.DW $CF, $1765 ;  G
	.DW $DC, $1613 ; A3
	.DW $E9, $14D4 ;  A
	.DW $F6, $13A7 ; B3
	.DW $105, $128B ; C4
	.DW $115, $117F ;  C
	.DW $125, $1082 ; D4
	.DW $137, $F93 ;  D
	.DW $149, $EB2 ; E4
	.DW $15D, $DDD ; F4
	.DW $171, $D14 ;  F
	.DW $188, $C56 ; G4
	.DW $19F, $BA3 ;  G
	.DW $1B8, $AFA ; A4
	.DW $1D2, $A5B ;  A
	.DW $1ED, $9C4 ; B4
	.DW $20B, $936 ; C5
	.DW $22A, $8B0 ;  C
	.DW $24B, $832 ; D5
	.DW $26E, $7BA ;  D
	.DW $293, $74A ; E5
	.DW $2BA, $6DF ; F5
	.DW $2E3, $67B ;  F
	.DW $30F, $61C ; G5
	.DW $33E, $5C2 ;  G
	.DW $370, $56E ; A5
	.DW $3A4, $51E ;  A
	.DW $3DB, $4D3 ; B5
	.DW $416, $48C ; C6
	.DW $454, $449 ;  C
	.DW $496, $40A ; D6
	.DW $4DC, $3CE ;  D
	.DW $526, $396 ; E6
	.DW $574, $360 ; F6
	.DW $5C7, $32E ;  F
	.DW $61F, $2FF ; G6
	.DW $67D, $2D2 ;  G
	.DW $6E0, $2A8 ; A6
	.DW $748, $280 ;  A
	.DW $7B7, $25A ; B6
	.DW $82D, $237 ; C7
	.DW $8A9, $215 ;  C
	.DW $92D, $1F6 ; D7
	.DW $9B9, $1D8 ;  D
	.DW $A4D, $1BC ; E7
	.DW $AE9, $1A1 ; F7
	.DW $B8F, $188 ;  F
	.DW $C3F, $170 ; G7
	.DW $CFA, $15A ;  G
	.DW $DC0, $145 ; A7
	.DW $E91, $131 ;  A
	.DW $F6F, $11E ; B7
SPK_NOTE_C8:
	.DW $105A, $10C ; C8
	.DW $1152, $FB ;  C
	.DW $125A, $EC ; D8
	.DW $1372, $DD ;  D
	.DW $149A, $CF ; E8
	.DW $15D3, $C1 ; F8
	.DW $171F, $B5 ;  F
	.DW $187F, $A9 ; G8
	.DW $19F4, $9E ;  G
	.DW $1B80, $93 ; A8
	.DW $1D22, $89 ;  A
	.DW $1EDE, $80 ; B8
#ENDIF
